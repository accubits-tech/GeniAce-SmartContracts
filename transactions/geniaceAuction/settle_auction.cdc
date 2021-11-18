import GeniaceAuction from "../../contracts/GeniaceAuction.cdc"

// This transaction craete a collection for auction items for an account.

transaction(id: UInt64, marketplace: Address) {
    let auctionCap: Capability<&{GeniaceAuction.AuctionPublic}>

    prepare(account: AuthAccount) {

        let seller = getAccount(marketplace)
        self.auctionCap = seller.getCapability<&{GeniaceAuction.AuctionPublic}>(/public/GeniaceAuction)
        self.auctionCap.borrow()
            ??panic("Could not borrow a reference to the auction collection")
        
    }

    execute {
        self.auctionCap.borrow()!.settleAuction(id)
    }
}
