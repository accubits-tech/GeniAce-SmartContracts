import FungibleToken from "../../contracts/FungibleToken.cdc"
import Geni from "../../contracts/Geni.cdc"
import GeniaceAuction from "../../contracts/GeniaceAuction.cdc"
import GeniacePacks from "../../contracts/GeniacePacks.cdc"

transaction(
        collectionName: String,
        tier: String,
        packIDs: [String],
        price: UFix64,
        sellerAddress: Address,
        sellerCommission: UFix64,
        platformAddress: Address,
        platformCommission: UFix64
    ) {

    let tempVault: @FungibleToken.Vault
    let buyerAddress: Address
    let sellerGeniReceiver: Capability<&Geni.Vault{FungibleToken.Receiver}>
    let platformGeniReceiver: Capability<&Geni.Vault{FungibleToken.Receiver}>

    prepare(account: AuthAccount) {

        let vaultRef = account.borrow<&Geni.Vault>(from: /storage/geniVault)
            ?? panic("Cannot borrow Geni token vault from account storage")
        
        self.sellerGeniReceiver = getAccount(sellerAddress).getCapability<&Geni.Vault{FungibleToken.Receiver}>(/public/geniTokenReceiver)!
        assert(self.sellerFlowReceiver.borrow() != nil, message: "Missing or mis-typed Geni token receiver")
        
        self.platformGeniReceiver = getAccount(platformAddress).getCapability<&Geni.Vault{FungibleToken.Receiver}>(/public/geniTokenReceiver)!
        assert(self.platformFlowReceiver.borrow() != nil, message: "Missing or mis-typed Geni token receiver")
        
        // withdraw tokens from the buyer's Vault
        self.tempVault <- vaultRef.withdraw(amount: price)
        self.buyerAddress = account.address

    }

    execute {

         let sellerSaleCut = GeniaceAuction.SaleCut(
            receiver: self.sellerGeniReceiver,
            percentage: sellerCommision
        )

        let platformSaleCut = GeniaceAuction.SaleCut(
            receiver: self.platformGeniReceiver,
            percentage: platformCommission
        )

        GeniacePacks.purchase(
            collectionName: collectionName,
            tier: tier,
            paymentVaultType: Type<@FlowToken.Vault>(),
            packIDs: packIDs,
            price: price,
            buyerAddress: self.buyerAddress,
            paymentVault: <- self.tempVault, 
            saleCuts: [sellerSaleCut, platformSaleCut]
        )
    }
}
