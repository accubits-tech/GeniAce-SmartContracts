import FungibleToken from "../../contracts/FungibleToken.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"

transaction {

  prepare(signer: AuthAccount) {

    // It's OK if the account already has a Vault, but we don't want to replace it
    if(signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) != nil) {
      return
    }
    
    // Create a new FlowToken Vault and put it in storage
    signer.save(<-FlowToken.createEmptyVault(), to: /storage/flowTokenVault)

    // Create a public capability to the Vault that only exposes
    // the deposit function through the Receiver interface
    signer.link<&FlowToken.Vault{FungibleToken.Receiver}>(
      /public/flowTokenReceiver,
      target: /storage/flowTokenVault
    )

    // Create a public capability to the Vault that only exposes
    // the balance field through the Balance interface
    signer.link<&FlowToken.Vault{FungibleToken.Balance}>(
      /public/fusdBalance,
      target: /storage/flowTokenVault
    )
  }
}
