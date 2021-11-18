import GeniaceAuction from "../../contracts/GeniaceAuction.cdc"

// This transaction craete a collection for auction items for an account.

transaction {
    prepare(acct: AuthAccount) {

        // If the account doesn't already have a Storefront
        if acct.borrow<&GeniaceAuction.AuctionCollection>(from: /storage/GeniaceAuction) == nil {

            // Create a new empty .Storefront
            let auctionCollection <- GeniaceAuction.createAuctionCollection() as! @GeniaceAuction.AuctionCollection
            
            // save it to the account
            acct.save(<-auctionCollection, to: /storage/GeniaceAuction)

            // create a public capability for the .Storefront
            acct.link<&GeniaceAuction.AuctionCollection{GeniaceAuction.AuctionPublic}>(/public/GeniaceAuction, target: /storage/GeniaceAuction)
        }
    }
}
