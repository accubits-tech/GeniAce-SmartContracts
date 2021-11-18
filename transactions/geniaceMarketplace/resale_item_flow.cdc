import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"
import GeniaceNFT from "../../contracts/GeniaceNFT.cdc"
import GeniaceMarketplace from "../../contracts/GeniaceMarketplace.cdc"

transaction(
    saleItemID: UInt64,
    sellerProfit: UFix64,
    royaltyAccount: Address,
    royaltyAmount: UFix64,
    platformAccount: Address,
    platformFee: UFix64
    ) {

    let flowReceiverSeller: Capability<&FlowToken.Vault{FungibleToken.Receiver}>
    let flowReceiverCreator: Capability<&FlowToken.Vault{FungibleToken.Receiver}>
    let flowReceiverPlatformOwner: Capability<&FlowToken.Vault{FungibleToken.Receiver}>
    let geniaceNFTProvider: Capability<&GeniaceNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
    let storefront: &GeniaceMarketplace.Storefront

    prepare(account: AuthAccount) {
        // We need a provider capability, but one is not provided by default so we create one if needed.
        let geniaceNFTCollectionProviderPrivatePath = /private/geniaceNFTCollectionProvider

        self.flowReceiverSeller = account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
        self.flowReceiverCreator = getAccount(royaltyAccount).getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
        self.flowReceiverPlatformOwner = getAccount(platformAccount).getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
        
        assert(self.flowReceiverSeller.borrow() != nil, message: "Missing or mis-typed Flow token receiver")

        if !account.getCapability<&GeniaceNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(geniaceNFTCollectionProviderPrivatePath)!.check() {
            account.link<&GeniaceNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(geniaceNFTCollectionProviderPrivatePath, target: GeniaceNFT.CollectionStoragePath)
        }

        self.geniaceNFTProvider = account.getCapability<&GeniaceNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(geniaceNFTCollectionProviderPrivatePath)!
        
        assert(self.geniaceNFTProvider.borrow() != nil, message: "Missing or mis-typed GeniaceNFT.Collection provider")

        self.storefront = account.borrow<&GeniaceMarketplace.Storefront>(from: GeniaceMarketplace.StorefrontStoragePath)
            ?? panic("Missing or mis-typed GeniaceMarketplace Storefront")
    }

    execute {

        let sellerCut = GeniaceMarketplace.SaleCut(
            receiver: self.flowReceiverSeller,
            amount: sellerProfit
        )

        let royaltyCut = GeniaceMarketplace.SaleCut(
            receiver: self.flowReceiverCreator,
            amount: royaltyAmount
        )

        let platformCut = GeniaceMarketplace.SaleCut(
            receiver: self.flowReceiverPlatformOwner,
            amount: platformFee
        )

        self.storefront.createSaleOffer(
            nftProviderCapability: self.geniaceNFTProvider,
            nftType: Type<@GeniaceNFT.NFT>(),
            nftID: saleItemID,
            salePaymentVaultType: Type<@FlowToken.Vault>(),
            saleCuts: [
                sellerCut,
                royaltyCut,
                platformCut
                ]
        )
    }
}