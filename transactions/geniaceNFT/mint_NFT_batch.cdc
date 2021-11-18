
import GeniaceNFT from "../../contracts/GeniaceNFT.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"

// This transaction allows the Minter account to mint an NFT
// and deposit it into its collection.

transaction( 
    recipient: Address, 
    name: String,
    description: String,
    celebrityName: String,
    artist: String,
    rarity: UInt8,
    imageUrl: String,
    data: {String: String},
    batchSize: Int
    ){

    // local variable for storing the minter reference
    let minter: &GeniaceNFT.NFTMinter

    prepare(signer: AuthAccount) {
        // borrow a reference to the NFTMinter resource in storage
        self.minter = signer.borrow<&GeniaceNFT.NFTMinter>(from: GeniaceNFT.MinterStoragePath)
            ?? panic("Could not borrow a reference to the NFT minter")
    }

    execute {
        // get the public account object for the recipient
        let recipient = getAccount(recipient)

        fun getRarity(type: UInt8): GeniaceNFT.Rarity {
        switch(GeniaceNFT.Rarity(rawValue: type)){
            case GeniaceNFT.Rarity.Collectible: return GeniaceNFT.Rarity.Collectible;
            case GeniaceNFT.Rarity.Rare: return GeniaceNFT.Rarity.Rare;
            case GeniaceNFT.Rarity.UltraRare: return GeniaceNFT.Rarity.UltraRare;
            default: return GeniaceNFT.Rarity.Collectible
            }
        }

        // borrow the recipient's public NFT collection reference
        let receiver = recipient
            .getCapability(GeniaceNFT.CollectionPublicPath)!
            .borrow<&{NonFungibleToken.CollectionPublic}>()
            ?? panic("Could not get receiver reference to the NFT Collection")
        // Use the minter reference to mint an NFT, which deposits
        // the NFT into the collection that is sent as a parameter.

        var editionNumber = 1

        while editionNumber <= batchSize {


            self.minter.mintNFT( recipient: receiver, _metadata: GeniaceNFT.Metadata(
            name: name.concat(" #").concat(editionNumber.toString()),
            description: description,
            celebrityName: celebrityName,
            artist: artist,
            rarity: getRarity(type: rarity),
            imageUrl: imageUrl,
            data: data

        ))
            editionNumber = editionNumber + 1
        }

        log("NFT Minted and deposited")
    }
}
