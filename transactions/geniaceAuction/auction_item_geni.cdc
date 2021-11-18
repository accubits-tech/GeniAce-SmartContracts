import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import Geni from "../../contracts/Geni.cdc"
import GeniaceNFT from "../../contracts/GeniaceNFT.cdc"
import GeniaceAuction from "../../contracts/GeniaceAuction.cdc"

transaction(
    saleItemID: UInt64,
    saleItemStartPrice: UFix64,
    minimumBidIncrement: UFix64,
    auctionLength: UFix64,
    auctionStartTime: UFix64,
    saleProfit: UFix64,
    instantBuyPrice: UFix64
    ) {

    let geniReceiver: Capability<&Geni.Vault{FungibleToken.Receiver}>
    let auctionCollection: &GeniaceAuction.AuctionCollection
    let NFTcollectionRef: &GeniaceNFT.Collection
    let NFTcollectionReceiver: Capability<&GeniaceNFT.Collection{NonFungibleToken.Receiver}>

    prepare(account: AuthAccount) {

        // borrow a reference to the signer's NFT collection
        self.NFTcollectionRef = account.borrow<&GeniaceNFT.Collection>(from: GeniaceNFT.CollectionStoragePath)
            ?? panic("Could not borrow a reference to the owner's collection")
        
        if !account.getCapability<&GeniaceNFT.Collection{NonFungibleToken.CollectionPublic}>(GeniaceNFT.CollectionPublicPath)!.check() {
            account.link<&GeniaceNFT.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver}>(GeniaceNFT.CollectionPublicPath, target: GeniaceNFT.CollectionStoragePath)
        }

        self.NFTcollectionReceiver = account.getCapability<&GeniaceNFT.Collection{NonFungibleToken.Receiver}>( GeniaceNFT.CollectionPublicPath)
             assert(self.NFTcollectionReceiver.borrow() != nil, message: "Missing or mis-typed GeniaceNFT.Collection provider")

        // borrow a reference to the signer's auction collection
         if account.borrow<&GeniaceAuction.AuctionCollection>(from: /storage/GeniaceAuction) == nil {

            // Create a new empty .Storefront
            let auctionCollection <- GeniaceAuction.createAuctionCollection() as! @GeniaceAuction.AuctionCollection
            
            // save it to the account
            account.save(<-auctionCollection, to: /storage/GeniaceAuction)

            // create a public capability for the .Storefront
            account.link<&GeniaceAuction.AuctionCollection{GeniaceAuction.AuctionPublic}>(/public/GeniaceAuction, target: /storage/GeniaceAuction)
        }
        
        self.auctionCollection = account.borrow<&GeniaceAuction.AuctionCollection>(from: /storage/GeniaceAuction)
            ?? panic("Could not borrow a reference to the auction collection")
        

        self.geniReceiver = account.getCapability<&Geni.Vault{FungibleToken.Receiver}>(/public/geniReceiver)!
        
        assert(self.geniReceiver.borrow() != nil, message: "Missing or mis-typed Geni receiver")

    }

    execute {

         // withdraw the NFT from the owner's collection
        let nft <- self.NFTcollectionRef.withdraw(withdrawID: saleItemID) as! @GeniaceNFT.NFT

        let saleCut = GeniaceAuction.SaleCut(
            receiver: self.geniReceiver,
            amount: saleProfit
        )
        self.auctionCollection.createAuction(
            token: <- nft,
            currencyType: Type<@Geni.Vault>(),
            minimumBidIncrement: minimumBidIncrement,
            auctionLength: auctionLength,
            auctionStartTime: auctionStartTime,
            startPrice: saleItemStartPrice,
            buyNowPrice: instantBuyPrice,
            collectionCap: self.NFTcollectionReceiver,
            saleCuts: [saleCut]
        )
    }
}
