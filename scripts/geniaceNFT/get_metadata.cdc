import GeniaceNFT from "../../contracts/GeniaceNFT.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"

// Print the NFTs owned by account 0x02.
pub fun main(account: Address, tokenId: UInt64): GeniaceNFT.Metadata? {
    // Get the public account object for account 0x02
    let nftOwner = getAccount(account)

    // Find the public Receiver capability for their Collection
    let capability = nftOwner.getCapability<&GeniaceNFT.Collection{NonFungibleToken.CollectionPublic, GeniaceNFT.GeniaceNFTCollectionPublic}>(GeniaceNFT.CollectionPublicPath)

    // borrow a reference from the capability
    let receiverRef = capability.borrow()
        ?? panic("Could not borrow the receiver reference")

    // Log the NFTs that they own as an array of IDs
    log("Account NFTs")
    log(receiverRef.getIDs())

    if let nft_ref = receiverRef.borrowGeniaceNFT(id: tokenId){
        log(nft_ref.metadata)
        return nft_ref.metadata
    }

    return nil
}
