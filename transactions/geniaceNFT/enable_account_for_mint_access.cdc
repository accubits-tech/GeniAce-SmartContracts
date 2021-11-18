// ----------------
// We need to init Capability Holder on Account 0x02 and expose it for public use
// ----------------

import GeniaceNFT from "../../contracts/GeniaceNFT.cdc"

transaction{
    prepare(signer: AuthAccount){
        signer.save(GeniaceNFT.NFTMintCapabilityHolder(), to: /storage/minterCapabilityHolder)
        signer.link<&GeniaceNFT.NFTMintCapabilityHolder>(/public/minterHolder, target: /storage/minterCapabilityHolder)
    }
}
 