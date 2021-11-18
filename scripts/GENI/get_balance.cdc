// This script returns the balance of an account's Geni vault.
//
// Parameters:
// - address: The address of the account holding the Geni vault.
//
// This script will fail if they account does not have an Geni vault. 
// To check if an account has a vault or initialize a new vault, 

import FungibleToken from "../../contracts/FungibleToken.cdc"
import Geni from "../../contracts/Geni.cdc"

pub fun main(address: Address): UFix64 {
    let account = getAccount(address)

    let geniReceiver = account.getCapability<&Geni.Vault{FungibleToken.Receiver}>(/public/geniReceiver)!
        
        assert(geniReceiver.borrow() != nil, message: "Missing or mis-typed Geni token receiver")

    let vaultRef = account.getCapability(/public/geniBalance)!
        .borrow<&Geni.Vault{FungibleToken.Balance}>()
        ?? panic("Could not borrow Balance reference to the Vault")

    return vaultRef.balance
}
