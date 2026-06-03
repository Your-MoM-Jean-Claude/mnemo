import Foundation

struct BundledLibraryLoader {

    struct BundledDeck {
        let fileName: String
        let folderName: String
        let deckName: String
    }

    static let all: [BundledDeck] = [
        // CZ → AJ
        BundledDeck(fileName: "CZ-AJ_1_Pozdravy",         folderName: "CZ → AJ", deckName: "Pozdravy"),
        BundledDeck(fileName: "CZ-AJ_2_Slovesa",           folderName: "CZ → AJ", deckName: "Slovesa"),
        BundledDeck(fileName: "CZ-AJ_3_Pridavna_jmena",    folderName: "CZ → AJ", deckName: "Přídavná jména"),
        BundledDeck(fileName: "CZ-AJ_4_Podstatna_jmena",   folderName: "CZ → AJ", deckName: "Podstatná jména"),
        BundledDeck(fileName: "CZ-AJ_5_Fraze",             folderName: "CZ → AJ", deckName: "Fráze"),
        // ES → AJ
        BundledDeck(fileName: "ES-AJ_1_Saludos",           folderName: "ES → AJ", deckName: "Saludos"),
        BundledDeck(fileName: "ES-AJ_2_Verbos",            folderName: "ES → AJ", deckName: "Verbos"),
        BundledDeck(fileName: "ES-AJ_3_Adjetivos",         folderName: "ES → AJ", deckName: "Adjetivos"),
        BundledDeck(fileName: "ES-AJ_4_Sustantivos",       folderName: "ES → AJ", deckName: "Sustantivos"),
        BundledDeck(fileName: "ES-AJ_5_Frases",            folderName: "ES → AJ", deckName: "Frases"),
        // FR → AJ
        BundledDeck(fileName: "FR-AJ_1_Salutations",       folderName: "FR → AJ", deckName: "Salutations"),
        BundledDeck(fileName: "FR-AJ_2_Verbes",            folderName: "FR → AJ", deckName: "Verbes"),
        BundledDeck(fileName: "FR-AJ_3_Adjectifs",         folderName: "FR → AJ", deckName: "Adjectifs"),
        BundledDeck(fileName: "FR-AJ_4_Noms",              folderName: "FR → AJ", deckName: "Noms"),
        BundledDeck(fileName: "FR-AJ_5_Phrases",           folderName: "FR → AJ", deckName: "Phrases"),
        // DE → AJ
        BundledDeck(fileName: "DE-AJ_1_Begruessungen",     folderName: "DE → AJ", deckName: "Begrüßungen"),
        BundledDeck(fileName: "DE-AJ_2_Verben",            folderName: "DE → AJ", deckName: "Verben"),
        BundledDeck(fileName: "DE-AJ_3_Adjektive",         folderName: "DE → AJ", deckName: "Adjektive"),
        BundledDeck(fileName: "DE-AJ_4_Nomen",             folderName: "DE → AJ", deckName: "Nomen"),
        BundledDeck(fileName: "DE-AJ_5_Phrasen",           folderName: "DE → AJ", deckName: "Phrasen"),
        // ZH → AJ
        BundledDeck(fileName: "ZH-AJ_1_Pozdravy",         folderName: "ZH → AJ", deckName: "问候 Pozdravy"),
        BundledDeck(fileName: "ZH-AJ_2_Slovesa",           folderName: "ZH → AJ", deckName: "动词 Slovesa"),
        BundledDeck(fileName: "ZH-AJ_3_Pridavna_jmena",    folderName: "ZH → AJ", deckName: "形容词 Přídavná jména"),
        BundledDeck(fileName: "ZH-AJ_4_Podstatna_jmena",   folderName: "ZH → AJ", deckName: "名词 Podstatná jména"),
        BundledDeck(fileName: "ZH-AJ_5_Fraze",             folderName: "ZH → AJ", deckName: "短语 Fráze"),
    ]

    static func loadInto(_ library: LibraryViewModel) {
        guard library.decks.isEmpty else { return }

        var folderMap: [String: UUID] = [:]

        for entry in all {
            // Create folder once
            if folderMap[entry.folderName] == nil {
                let folder = DeckFolder(name: entry.folderName, sortOrder: folderMap.count)
                library.folders.append(folder)
                folderMap[entry.folderName] = folder.id
            }
            let folderID = folderMap[entry.folderName]

            guard let url = Bundle.main.url(forResource: entry.fileName, withExtension: "txt"),
                  let cards = try? FileParser.parse(url: url) else { continue }

            var deck = Deck(name: entry.deckName, cards: cards)
            deck.folderID  = folderID
            deck.sortOrder = library.decks.count
            deck.isBundled = true
            library.decks.append(deck)
        }

        library.save()
    }
}
