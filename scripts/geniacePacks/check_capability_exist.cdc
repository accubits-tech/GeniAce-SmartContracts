import GeniacePacks from "../../contracts/GeniacePacks.cdc"

pub fun main(capabilityHolder: Address, collectionOwner:Address): Bool {
  let holder = getAccount(capabilityHolder)
            .getCapability<&GeniacePacks.collectionCapabilityHolder{GeniacePacks.collectionCapabilityPublic}>(/public/collectionCapabilityHolderPublic)
            .borrow()!

  return  holder.isCapabilityExist(collectionOwner: collectionOwner)
  
}
