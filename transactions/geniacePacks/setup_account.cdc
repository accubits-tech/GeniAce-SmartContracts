
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import GeniacePacks from "../../contracts/GeniacePacks.cdc"

transaction{
    prepare(signer: AuthAccount){
        if signer.borrow<&GeniacePacks.collectionCapabilityHolder>(from: /storage/collectionCapabilityHolder) == nil{

            signer.save(<- GeniacePacks.createCapabilityHolder(), to: /storage/collectionCapabilityHolder)

            signer.link<&GeniacePacks.collectionCapabilityHolder{GeniacePacks.collectionCapabilityPublic}>(/public/collectionCapabilityHolderPublic, target: /storage/collectionCapabilityHolder)
        }
    }
}