import FungibleToken from "../../contracts/FungibleToken.cdc"
import Geni from "../../contracts/Geni.cdc"

// This transaction is a template for a transaction
// to add a Vault resource to their account
// so that they can use the Geni

transaction {

    prepare(signer: AuthAccount) {

        if signer.borrow<&Geni.Vault>(from: Geni.VaultStoragePath) == nil {
            // Create a new Geni Vault and put it in storage
            signer.save(<-Geni.createEmptyVault(), to: Geni.VaultStoragePath)

            // Create a public capability to the Vault that only exposes
            // the deposit function through the Receiver interface
            signer.link<&Geni.Vault{FungibleToken.Receiver}>(
                Geni.ReceiverPublicPath,
                target: Geni.VaultStoragePath
            )

            // Create a public capability to the Vault that only exposes
            // the balance field through the Balance interface
            signer.link<&Geni.Vault{FungibleToken.Balance}>(
                Geni.BalancePublicPath,
                target: Geni.VaultStoragePath
            )
        }
    }
}
