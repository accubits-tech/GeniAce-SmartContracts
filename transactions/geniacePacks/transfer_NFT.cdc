import GeniacePacks from "../../contracts/GeniacePacks.cdc"
import GeniaceNFT from "../../contracts/GeniaceNFT.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"

transaction(collectionOwner: Address, tokenRecipient: Address, withdrawID: UInt64){
    prepare(signer: AuthAccount){

        let holder = signer.borrow<&GeniacePacks.collectionCapabilityHolder>(from: /storage/collectionCapabilityHolder)!  

        // borrow a public reference to the receivers collection
        let depositRef = getAccount(tokenRecipient).getCapability(GeniaceNFT.CollectionPublicPath)!.borrow<&{NonFungibleToken.CollectionPublic}>()!

        // withdraw the NFT from the owner's collection
        let nft <- holder.getCollectionCapability(collectionOwner: collectionOwner).withdraw(withdrawID: withdrawID)

        // Deposit the NFT in the recipient's collection
        depositRef.deposit(token: <-nft)
        
    }
}
