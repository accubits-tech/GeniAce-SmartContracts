import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import Geni from "../../contracts/Geni.cdc"
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

    let geniReceiverSeller: Capability<&Geni.Vault{FungibleToken.Receiver}>
    let geniReceiverCreator: Capability<&Geni.Vault{FungibleToken.Receiver}>
    let geniReceiverPlatformOwner: Capability<&Geni.Vault{FungibleToken.Receiver}>
    let geniaceNFTProvider: Capability<&GeniaceNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
    let storefront: &GeniaceMarketplace.Storefront

    prepare(account: AuthAccount) {
        // We need a provider capability, but one is not provided by default so we create one if needed.
        let geniaceNFTCollectionProviderPrivatePath = /private/geniaceNFTCollectionProvider

        self.geniReceiverSeller = account.getCapability<&Geni.Vault{FungibleToken.Receiver}>(/public/geniTokenReceiver)!
        self.geniReceiverCreator = getAccount(royaltyAccount).getCapability<&Geni.Vault{FungibleToken.Receiver}>(/public/geniTokenReceiver)!
        self.geniReceiverPlatformOwner = getAccount(platformAccount).getCapability<&Geni.Vault{FungibleToken.Receiver}>(/public/geniTokenReceiver)!
        
        assert(self.geniReceiverSeller.borrow() != nil, message: "Missing or mis-typed geni token receiver")

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
            receiver: self.geniReceiverSeller,
            amount: sellerProfit
        )

        let royaltyCut = GeniaceMarketplace.SaleCut(
            receiver: self.geniReceiverCreator,
            amount: royaltyAmount
        )

        let platformCut = GeniaceMarketplace.SaleCut(
            receiver: self.geniReceiverPlatformOwner,
            amount: platformFee
        )

        self.storefront.createSaleOffer(
            nftProviderCapability: self.geniaceNFTProvider,
            nftType: Type<@GeniaceNFT.NFT>(),
            nftID: saleItemID,
            salePaymentVaultType: Type<@Geni.Vault>(),
            saleCuts: [
                sellerCut,
                royaltyCut,
                platformCut
                ]
        )
    }
}