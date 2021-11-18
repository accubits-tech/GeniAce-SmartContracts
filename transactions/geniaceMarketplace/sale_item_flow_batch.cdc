import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"
import GeniaceNFT from "../../contracts/GeniaceNFT.cdc"
import GeniaceMarketplace from "../../contracts/GeniaceMarketplace.cdc"

transaction(saleItemIDs: [UInt64], saleItemPrice: UFix64) {

    let flowReceiver: Capability<&FlowToken.Vault{FungibleToken.Receiver}>
    let geniaceNFTProvider: Capability<&GeniaceNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
    let storefront: &GeniaceMarketplace.Storefront

    prepare(account: AuthAccount) {
        // We need a provider capability, but one is not provided by default so we create one if needed.
        let geniaceNFTCollectionProviderPrivatePath = /private/geniaceNFTCollectionProvider

        self.flowReceiver = account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
        
        assert(self.flowReceiver.borrow() != nil, message: "Missing or mis-typed Flow token receiver")

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
            receiver: self.flowReceiver,
            amount: saleItemPrice
        )

        for nft in saleItemIDs{
            self.storefront.createSaleOffer(
                nftProviderCapability: self.geniaceNFTProvider,
                nftType: Type<@GeniaceNFT.NFT>(),
                nftID: nft,
                salePaymentVaultType: Type<@FlowToken.Vault>(),
                saleCuts: [saleCut]
            )
        }
    }
}
