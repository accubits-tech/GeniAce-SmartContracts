import GeniaceAuction from "../../contracts/GeniaceAuction.cdc"

// This transaction craete a collection for auction items for an account.

transaction(id: UInt64) {
    let auctionCollection: &GeniaceAuction.AuctionCollection

    prepare(account: AuthAccount) {

         // borrow a reference to the signer's auction collection
        self.auctionCollection = account.borrow<&GeniaceAuction.AuctionCollection>(from: /storage/GeniaceAuction)
            ?? panic("Could not borrow a reference to the auction collection")
    }

    execute {
        self.auctionCollection.cancelAuction(id)
    }
}
