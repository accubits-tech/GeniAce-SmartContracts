import GeniaceAuction from "../../contracts/GeniaceAuction.cdc"

// Print the NFTs owned by account 0x02.
pub fun main(account: Address): {UInt64: GeniaceAuction.AuctionStatus} {

    let seller = getAccount(account)
    let auctionCap = seller.getCapability<&{GeniaceAuction.AuctionPublic}>(/public/GeniaceAuction)
    let auctionStatus=auctionCap.borrow()!.getAuctionStatuses()

    return auctionStatus
}