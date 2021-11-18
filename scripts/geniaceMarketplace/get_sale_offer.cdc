import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import GeniaceMarketplace from "../../contracts/GeniaceMarketplace.cdc"
import GeniaceNFT from "../../contracts/GeniaceNFT.cdc"

pub struct SaleItem {
    pub let itemID: UInt64
    pub let owner: Address
    pub let price: UFix64

    init(itemID: UInt64, owner: Address, price: UFix64) {
        self.itemID = itemID
        self.owner = owner
        self.price = price
    }
}

pub fun main(address: Address, saleOfferResourceID: UInt64): SaleItem? {
    let account = getAccount(address)

    if let storefrontRef = account.getCapability<&GeniaceMarketplace.Storefront{GeniaceMarketplace.StorefrontPublic}>(GeniaceMarketplace.StorefrontPublicPath).borrow() {
        if let saleOffer = storefrontRef.borrowSaleOffer(saleOfferResourceID: saleOfferResourceID) {
            let details = saleOffer.getDetails()

            let itemID = details.nftID
            let itemPrice = details.salePrice

            if let collection = account.getCapability<&GeniaceNFT.Collection{NonFungibleToken.CollectionPublic, GeniaceNFT.GeniaceNFTCollectionPublic}>(GeniaceNFT.CollectionPublicPath).borrow() {
                if let item = collection.borrowGeniaceNFT(id: itemID) {
                    return SaleItem(itemID: itemID, owner: address, price: itemPrice)
                }
            }
        }
    }
        
    return nil
}
