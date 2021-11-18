import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import GeniaceNFT from "../../contracts/GeniaceNFT.cdc"
import GeniaceAuction from "../../contracts/GeniaceAuction.cdc"

// Transaction to make a bid in a marketplace for the given dropId and auctionId
transaction(marketplace: Address, auctionId: UInt64, bidAmount: UFix64) {
    // reference to the buyer's NFT collection where they
    // will store the bought NFT

    let vaultCap: Capability<&{FungibleToken.Receiver}>
    let collectionCap: Capability<&GeniaceNFT.Collection{NonFungibleToken.Receiver}>
    let auctionCap: Capability<&{GeniaceAuction.AuctionPublic}>
    let temporaryVault: @FungibleToken.Vault

    prepare(account: AuthAccount) {

        // get the references to the buyer's Vault and NFT Collection receiver
        var collectionCap = account.getCapability<&GeniaceNFT.Collection{NonFungibleToken.Receiver}>( GeniaceNFT.CollectionPublicPath)

        // if collection is not created yet we make it.
        if !collectionCap.check() {

            if account.borrow<&GeniaceNFT.Collection>(from: GeniaceNFT.CollectionStoragePath) == nil {

                // create a new empty collection
                let collection <- GeniaceNFT.createEmptyCollection()
                
                // save it to the account
                signer.save(<-collection, to: GeniaceNFT.CollectionStoragePath)

            }
            // create a public capability for the collection
            account.unlink(GeniaceNFT.CollectionPublicPath)
            account.link<&GeniaceNFT.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, GeniaceNFT.GeniaceNFTCollectionPublic}>(GeniaceNFT.CollectionPublicPath, target: GeniaceNFT.CollectionStoragePath)
        }

        self.collectionCap=collectionCap
        
        self.vaultCap = account.getCapability<&{FungibleToken.Receiver}>(/public/geniReceiver)
                   
        let vaultRef = account.borrow<&FungibleToken.Vault>(from: /storage/geniVault)
            ?? panic("Could not borrow owner's Vault reference")

        let seller = getAccount(marketplace)
        self.auctionCap = seller.getCapability<&{GeniaceAuction.AuctionPublic}>(/public/GeniaceAuction)
        
        let auctionStatus = self.auctionCap.borrow()!.getAuctionStatus(auctionId)
        //if your capability is the leader you only have to send in the difference
        var amountToPay = bidAmount
        
        if(auctionStatus.leader == account.address){
            amountToPay = bidAmount - auctionStatus.price
        }

        // withdraw tokens from the buyer's Vault
        self.temporaryVault <- vaultRef.withdraw(amount: amountToPay)
    }

    execute {
        self.auctionCap.borrow()!.placeBid(
            id: auctionId,
            bidTokens: <- self.temporaryVault,
            vaultCap: self.vaultCap,
            collectionCap: self.collectionCap
            )
    }
}
 
