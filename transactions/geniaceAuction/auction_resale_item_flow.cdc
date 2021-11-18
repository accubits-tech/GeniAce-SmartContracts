import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"
import GeniaceNFT from "../../contracts/GeniaceNFT.cdc"
import GeniaceAuction from "../../contracts/GeniaceAuction.cdc"

transaction(
    saleItemID: UInt64,
    saleItemStartPrice: UFix64,
    minimumBidIncrement: UFix64,
    auctionLength: UFix64,
    auctionStartTime: UFix64,
    saleProfit: UFix64,
    instantBuyPrice: UFix64,
    sellerProfit: UFix64,
    royaltyAccount: Address,
    royaltyAmount: UFix64,
    platformAccount: Address,
    platformFee: UFix64
    ) {

    let flowReceiverSeller: Capability<&FlowToken.Vault{FungibleToken.Receiver}>
    let flowReceiverCreator: Capability<&FlowToken.Vault{FungibleToken.Receiver}>
    let flowReceiverPlatformOwner: Capability<&FlowToken.Vault{FungibleToken.Receiver}>
    let auctionCollection: &GeniaceAuction.AuctionCollection
    let NFTcollectionRef: &GeniaceNFT.Collection
    let NFTcollectionReceiver: Capability<&GeniaceNFT.Collection{NonFungibleToken.Receiver}>

    prepare(account: AuthAccount) {

        // borrow a reference to the signer's NFT collection
        self.NFTcollectionRef = account.borrow<&GeniaceNFT.Collection>(from: GeniaceNFT.CollectionStoragePath)
            ?? panic("Could not borrow a reference to the owner's collection")
        
        if !account.getCapability<&GeniaceNFT.Collection{NonFungibleToken.CollectionPublic}>(GeniaceNFT.CollectionPublicPath)!.check() {
            account.link<&GeniaceNFT.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, GeniaceNFT.GeniaceNFTCollectionPublic}>(GeniaceNFT.CollectionPublicPath, target: GeniaceNFT.CollectionStoragePath)
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
        

        self.flowReceiverSeller = account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
        self.flowReceiverCreator = getAccount(royaltyAccount).getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
        self.flowReceiverPlatformOwner = getAccount(platformAccount).getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
        
        assert(self.flowReceiverSeller.borrow() != nil, message: "Missing or mis-typed Flow token receiver")

    }

    execute {

         // withdraw the NFT from the owner's collection
        let nft <- self.NFTcollectionRef.withdraw(withdrawID: saleItemID) as! @GeniaceNFT.NFT


        let sellerCut = GeniaceAuction.SaleCut(
            receiver: self.flowReceiverSeller,
            percentage: sellerProfit
        )

        let royaltyCut = GeniaceAuction.SaleCut(
            receiver: self.flowReceiverCreator,
            percentage: royaltyAmount
        )

        let platformCut = GeniaceAuction.SaleCut(
            receiver: self.flowReceiverPlatformOwner,
            percentage: platformFee
        )


        self.auctionCollection.createAuction(
            token: <- nft,
            currencyType: Type<@FlowToken.Vault>(),
            minimumBidIncrement: minimumBidIncrement,
            auctionLength: auctionLength,
            auctionStartTime: auctionStartTime,
            startPrice: saleItemStartPrice,
            buyNowPrice: instantBuyPrice,
            collectionCap: self.NFTcollectionReceiver,
            saleCuts: [
                sellerCut,
                royaltyCut,
                platformCut
                ]
        )
    }
}
