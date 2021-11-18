import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import Geni from "../../contracts/Geni.cdc"
import GeniaceNFT from "../../contracts/GeniaceNFT.cdc"
import GeniaceMarketplace from "../../contracts/GeniaceMarketplace.cdc"

transaction(saleItemID: UInt64, saleItemPrice: UFix64) {

    let geniReceiver: Capability<&Geni.Vault{FungibleToken.Receiver}>
    let geniaceNFTProvider: Capability<&GeniaceNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
    let storefront: &GeniaceMarketplace.Storefront

    prepare(account: AuthAccount) {
        // We need a provider capability, but one is not provided by default so we create one if needed.
        let geniaceNFTCollectionProviderPrivatePath = /private/geniaceNFTCollectionProvider

        self.geniReceiver = account.getCapability<&Geni.Vault{FungibleToken.Receiver}>(/public/geniReceiver)!
        
        assert(self.geniReceiver.borrow() != nil, message: "Missing or mis-typed Geni token receiver")

        if !account.getCapability<&GeniaceNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(geniaceNFTCollectionProviderPrivatePath)!.check() {
            account.link<&GeniaceNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(geniaceNFTCollectionProviderPrivatePath, target: GeniaceNFT.CollectionStoragePath)
        }

        self.geniaceNFTProvider = account.getCapability<&GeniaceNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(geniaceNFTCollectionProviderPrivatePath)!
        
        assert(self.geniaceNFTProvider.borrow() != nil, message: "Missing or mis-typed GeniaceNFT.Collection provider")

        self.storefront = account.borrow<&GeniaceMarketplace.Storefront>(from: GeniaceMarketplace.StorefrontStoragePath)
            ?? panic("Missing or mis-typed GeniaceMarketplace Storefront")
    }

    execute {
        let saleCut = GeniaceMarketplace.SaleCut(
            receiver: self.geniReceiver,
            amount: saleItemPrice
        )
        self.storefront.createSaleOffer(
            nftProviderCapability: self.geniaceNFTProvider,
            nftType: Type<@GeniaceNFT.NFT>(),
            nftID: saleItemID,
            salePaymentVaultType: Type<@Geni.Vault>(),
            saleCuts: [saleCut]
        )
    }
}
