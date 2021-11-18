import Geni from "../../contracts/Geni.cdc"

// This script returns the total amount of Kibble currently in existence.

pub fun main(): UFix64 {

    let supply = Geni.totalSupply

    log(supply)

    return supply
}