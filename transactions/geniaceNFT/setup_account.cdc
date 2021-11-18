import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import GeniaceNFT from "../../contracts/GeniaceNFT.cdc"

// This transaction configures an account to hold Kitty Items.

transaction {
    prepare(signer: AuthAccount) {
        // if the account doesn't already have a collection
        if signer.borrow<&GeniaceNFT.Collection>(from: GeniaceNFT.CollectionStoragePath) == nil {

            // create a new empty collection
            let collection <- GeniaceNFT.createEmptyCollection()
            
            // save it to the account
            signer.save(<-collection, to: GeniaceNFT.CollectionStoragePath)

            // create a public capability for the collection
            signer.link<&GeniaceNFT.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, GeniaceNFT.GeniaceNFTCollectionPublic}>(GeniaceNFT.CollectionPublicPath, target: GeniaceNFT.CollectionStoragePath)
        }
    }
}
