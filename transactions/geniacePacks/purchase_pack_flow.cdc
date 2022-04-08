import FungibleToken from "../../contracts/FungibleToken.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"
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
    let sellerFlowReceiver: Capability<&FlowToken.Vault{FungibleToken.Receiver}>
    let platformFlowReceiver: Capability<&FlowToken.Vault{FungibleToken.Receiver}>

    prepare(account: AuthAccount) {

        let vaultRef = account.borrow<&FungibleToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow owner's Vault reference")
        
        self.sellerFlowReceiver = getAccount(sellerAddress).getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
        assert(self.sellerFlowReceiver.borrow() != nil, message: "Missing or mis-typed Flow token receiver")
        
        self.platformFlowReceiver = getAccount(platformAddress).getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
        assert(self.platformFlowReceiver.borrow() != nil, message: "Missing or mis-typed Flow token receiver")

        // withdraw tokens from the buyer's Vault
        self.tempVault <- vaultRef.withdraw(amount: price)
        self.buyerAddress = account.address

    }

    execute {

        let sellerSaleCut = GeniaceAuction.SaleCut(
            receiver: self.sellerFlowReceiver,
            percentage: sellerCommision
        )

        let platformSaleCut = GeniaceAuction.SaleCut(
            receiver: self.platformFlowReceiver,
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
