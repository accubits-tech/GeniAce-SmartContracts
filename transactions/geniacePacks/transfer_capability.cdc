import GeniacePacks from "../../contracts/GeniacePacks.cdc"
import GeniaceNFT from "../../contracts/GeniaceNFT.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"

transaction(capabilityHolder: Address){
    prepare(signer: AuthAccount){
        let geniaceNFTCollectionProviderPrivatePath = /private/geniaceNFTCollectionProvider
        
        let holder = getAccount(capabilityHolder)
            .getCapability<&GeniacePacks.collectionCapabilityHolder{GeniacePacks.collectionCapabilityPublic}>(/public/collectionCapabilityHolderPublic)
            .borrow()!

        if !signer.getCapability<&GeniaceNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(geniaceNFTCollectionProviderPrivatePath)!.check() {
            signer.link<&GeniaceNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(geniaceNFTCollectionProviderPrivatePath, target: GeniaceNFT.CollectionStoragePath)
        }

        let capability = signer.getCapability<&GeniaceNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(geniaceNFTCollectionProviderPrivatePath)
        holder.setCollectionCapability(collectionOwner: signer.address, capability: capability)
    }
}