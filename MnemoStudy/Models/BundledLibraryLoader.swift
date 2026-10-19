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

    /// Reads and parses the bundled .txt files. Pure — touches no view model, so
    /// it can run off the main actor. Parsing all 25 files used to happen inside
    /// `App.init()` on the main thread, before the first frame was drawn.
    static func buildContent(startingSortOrder: Int = 0) -> (decks: [Deck], folders: [DeckFolder]) {
        var folderMap: [String: DeckFolder] = [:]
        var folderOrder: [DeckFolder] = []
        var loaded: [Deck] = []

        for entry in all {
            guard let url = Bundle.main.url(forResource: entry.fileName, withExtension: "txt"),
                  let cards = try? FileParser.parse(url: url) else { continue }

            // Create the folder only once its content is known to have loaded —
            // otherwise a missing resource left an empty folder behind.
            if folderMap[entry.folderName] == nil {
                let folder = DeckFolder(name: entry.folderName, sortOrder: folderMap.count)
                folderMap[entry.folderName] = folder
                folderOrder.append(folder)
            }

            var deck = Deck(name: entry.deckName, cards: cards)
            deck.folderID  = folderMap[entry.folderName]?.id
            deck.sortOrder = startingSortOrder + loaded.count
            deck.isBundled = true
            loaded.append(deck)
        }
        return (loaded, folderOrder)
    }

    /// Seeds the built-in starter decks.
    ///
    /// Two guards matter here. `hasStoredLibrary` checks for saved bytes rather
    /// than a decoded array, so a library we merely failed to read is never
    /// mistaken for a new install and overwritten. And the seed is saved with
    /// `pushToCloud: false` — pushing it stamped a fresh sync timestamp over a
    /// real iCloud library that simply had not downloaded yet.
    @discardableResult
    static func apply(_ content: (decks: [Deck], folders: [DeckFolder]),
                      to library: LibraryViewModel,
                      force: Bool = false) -> Bool {
        if !force {
            guard library.decks.isEmpty, !library.hasStoredLibrary else { return false }
        }
        guard !content.decks.isEmpty else { return false }

        // Reuse a folder that already carries the same name (Restore runs into
        // this), remapping the incoming decks onto it — otherwise they would
        // point at a folder that was never added and show up as standalone.
        var idMap: [UUID: UUID] = [:]
        for folder in content.folders {
            if let existing = library.folders.first(where: { $0.name == folder.name }) {
                idMap[folder.id] = existing.id
            } else {
                library.folders.append(folder)
                idMap[folder.id] = folder.id
            }
        }

        let base = library.decks.count
        for (offset, deck) in content.decks.enumerated() {
            var d = deck
            if let old = d.folderID { d.folderID = idMap[old] ?? old }
            d.sortOrder = base + offset
            library.decks.append(d)
        }
        library.save(pushToCloud: force)
        return true
    }

    @discardableResult
    static func loadInto(_ library: LibraryViewModel, force: Bool = false) -> Bool {
        if !force {
            guard library.decks.isEmpty, !library.hasStoredLibrary else { return false }
        }
        return apply(buildContent(startingSortOrder: library.decks.count), to: library, force: force)
    }
}
