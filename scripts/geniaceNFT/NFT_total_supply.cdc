
import GeniaceNFT from "..../contracts/GeniaceNFT.cdc"
// import GeniaceNFT from "0xGeniaceNFT"

// Get the current supply of Geniace NFT
pub fun main(): UInt64{
    return GeniaceNFT.totalSupply;
}