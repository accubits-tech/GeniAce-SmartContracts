import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import Geni from "../../contracts/Geni.cdc"
import GeniaceNFT from "../../contracts/GeniaceNFT.cdc"
import GeniaceMarketplace from "../../contracts/GeniaceMarketplace.cdc"

transaction(saleOfferResourceID: UInt64, storefrontAddress: Address) {

    let paymentVault: @FungibleToken.Vault
    let geniaceNFTCollection: &GeniaceNFT.Collection{NonFungibleToken.Receiver}
    let storefront: &GeniaceMarketplace.Storefront{GeniaceMarketplace.StorefrontPublic}
    let saleOffer: &GeniaceMarketplace.SaleOffer{GeniaceMarketplace.SaleOfferPublic}

    prepare(account: AuthAccount) {
        self.storefront = getAccount(storefrontAddress)
            .getCapability<&GeniaceMarketplace.Storefront{GeniaceMarketplace.StorefrontPublic}>(
                GeniaceMarketplace.StorefrontPublicPath
            )!
            .borrow()
            ?? panic("Could not borrow Storefront from provided address")

        self.saleOffer = self.storefront.borrowSaleOffer(saleOfferResourceID: saleOfferResourceID)
            ?? panic("No Offer with that ID in Storefront")
        
        let price = self.saleOffer.getDetails().salePrice

        let mainGeniTokenVault = account.borrow<&Geni.Vault>(from: /storage/geniVault)
            ?? panic("Cannot borrow Geni token vault from account storage")
        
        self.paymentVault <- mainGeniTokenVault.withdraw(amount: price)

        self.geniaceNFTCollection = account.borrow<&GeniaceNFT.Collection{NonFungibleToken.Receiver}>(
            from: GeniaceNFT.CollectionStoragePath
        ) ?? panic("Cannot borrow GeniaceNFT collection receiver from account")
    }

    execute {
        let item <- self.saleOffer.accept(
            payment: <-self.paymentVault
        )

        self.geniaceNFTCollection.deposit(token: <-item)

        self.storefront.cleanup(saleOfferResourceID: saleOfferResourceID)
    }
}
