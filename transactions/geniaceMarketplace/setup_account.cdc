import GeniaceMarketplace from "../../contracts/GeniaceMarketplace.cdc"

// This transaction installs the Storefront ressource in an account.

transaction {
    prepare(acct: AuthAccount) {

        // If the account doesn't already have a Storefront
        if acct.borrow<&GeniaceMarketplace.Storefront>(from: GeniaceMarketplace.StorefrontStoragePath) == nil {

            // Create a new empty .Storefront
            let storefront <- GeniaceMarketplace.createStorefront() as! @GeniaceMarketplace.Storefront
            
            // save it to the account
            acct.save(<-storefront, to: GeniaceMarketplace.StorefrontStoragePath)

            // create a public capability for the .Storefront
            acct.link<&GeniaceMarketplace.Storefront{GeniaceMarketplace.StorefrontPublic}>(GeniaceMarketplace.StorefrontPublicPath, target: GeniaceMarketplace.StorefrontStoragePath)
        }
    }
}
