# Mnemo Study — Kompletní specifikace (build 13)

Tento dokument popisuje vše co je implementováno — vizuál, logiku, strukturu — tak aby bylo možné app postavit přesně od nuly.

---

## 1. Základní info

| Položka | Hodnota |
|---|---|
| Název | Mnemo Study |
| Bundle ID | `com.jirifilipec.mnemoapp` |
| Verze | 1.0, build 13 |
| Platform | iOS, SwiftUI, dark mode only |
| Min. iOS | 16+ |
| Jazyk UI | EN / CS / ES (přepínání v nastavení) |
| Storage | UserDefaults (local only) |
| Monetizace | 3denní trial → paywall, produkt `com.jirifilipec.mnemoapp.pro` |

---

## 2. Architektura

**Pattern:** MVVM + SwiftUI  
**Soubory:**
```
MnemoStudy/
├── MnemoStudyApp.swift          — @main, splash/paywall logika
├── Models/
│   ├── Card.swift               — datový model karty
│   ├── Deck.swift               — datový model decku + složky
│   ├── StudyModels.swift        — StudyConfig, SessionItem, SessionResult, DeckStats, CardStats, SessionRecord
│   ├── AppSettings.swift        — AppLanguage enum, NotificationTime, AppSettings struct
│   ├── FileParser.swift         — parse/export .txt formátu
│   ├── SRSEngine.swift          — SM-2 algoritmus
│   └── BundledLibraryLoader.swift — načtení 25 bundled decků
├── ViewModels/
│   ├── LibraryViewModel.swift   — CRUD decků/složek, statistiky, persistence
│   ├── SettingsViewModel.swift  — nastavení, notifikace, trial check
│   └── StudyViewModel.swift     — queue logika, session stav
├── Views/
│   ├── SplashView.swift
│   ├── MainTabView.swift
│   ├── Components/
│   │   └── DesignSystem.swift   — barvy, AppBg, GlassCard, ProgressRing, TagBadge, PrimaryButton, AnswerFeedbackOverlay
│   ├── Library/
│   │   ├── LibraryView.swift    — seznam decků, DeckCardView, TempDeckCard, FolderSection
│   │   ├── DeckEditorView.swift
│   │   └── ImportView.swift
│   ├── Study/
│   │   ├── StudySettingsView.swift
│   │   ├── StudyView.swift
│   │   └── ResultsView.swift
│   ├── Statistics/
│   │   └── StatisticsView.swift — headlineStat, WeeklyChart
│   ├── Settings/
│   │   └── SettingsView.swift   — TimePickerSheet uvnitř
│   └── Paywall/
│       └── PaywallView.swift
└── Resources/
    └── BundledLibraries/
        ├── CZ-AJ/ (5 .txt souborů)
        ├── ES-AJ/ (5 .txt souborů)
        ├── FR-AJ/ (5 .txt souborů)
        ├── DE-AJ/ (5 .txt souborů)
        └── ZH-AJ/ (5 .txt souborů)
```

---

## 3. Vizuál (ZMRAŽEN — neměnit)

### Barvy
```swift
mnemoGreen   = Color(red: 0.48, green: 0.62, blue: 0.49)  // #7A9E7E sage zelená
mnemoGold    = Color(red: 0.83, green: 0.72, blue: 0.59)  // #D4B896 teplá zlatá
mnemoBg      = Color(red: 0.11, green: 0.13, blue: 0.12)  // tmavé pozadí
mnemoSurface = Color(red: 0.16, green: 0.18, blue: 0.17)  // povrch karet
```

### AppIcon + Logo
- Soubor: `Ikona Mnemo Study 1.2.png` — 3D zeleno-zlaté M s textem "MNEMO STUDY"
- Umístění originálu: `C:\Users\jufff\Desktop\Slozka\Mnemo Study\Ikona Mnemo Study 1.2.png`
- `AppIcon.appiconset/AppIcon.png` — 1024×1024 RGB (PIL resize, Lanczos)
- `MnemoLogo.imageset/MnemoLogo.png` — originální rozměr (1254×1254)

### AppBg (sdílené pozadí)
```swift
struct AppBg: View {
    var opacity: Double = 0.13
    var body: some View {
        Color.mnemoBg
            .ignoresSafeArea()
            .overlay(
                Image("MnemoLogo")
                    .resizable()
                    .scaledToFit()
                    .opacity(opacity)
                    .allowsHitTesting(false)
            )
    }
}
```
Používá se jako první item každého ZStacku ve VŠECH obrazovkách.  
SplashView používá `AppBg(opacity: 0.18)`.

### Sdílené komponenty (DesignSystem.swift)
- **GlassCard** — `.background(.ultraThinMaterial)` + bílý gradient stroke 1pt, cornerRadius 18
- **ProgressRing** — kruhový progress, výchozí size 40, lineWidth 4, barva mnemoGreen
- **TagBadge** — capsule badge, výchozí barva mnemoGreen, caption2 semibold
- **PrimaryButton** — full-width, gradient (barva → barva.opacity(0.75)), cornerRadius 14, padding .vertical 16
- **AnswerFeedbackOverlay** — GlassCard, checkmark/xmark icon 44pt, správná odpověď pod špatnou

---

## 4. Datové modely

### Card
```swift
struct Card: Identifiable, Codable, Equatable {
    var id: UUID
    var front: String
    var back: String          // "hrnec / kvetinac" — lomítko odděluje alternativy
    var createdAt: Date
}
// backAlternatives: split by "/", trimmed
// isCorrect(_:): case-insensitive, exact match na kteroukoli alternativu
```

### Deck
```swift
struct Deck: Identifiable, Codable {
    var id: UUID
    var name: String
    var cards: [Card]
    var folderID: UUID?       // nil = standalone
    var createdAt: Date
    var lastStudied: Date?
    var isTemporary: Bool     // true = Wrong Answers deck
    var parentDeckID: UUID?   // nastaveno když isTemporary == true
    var sortOrder: Int
}
```

### DeckFolder
```swift
struct DeckFolder: Identifiable, Codable {
    var id: UUID
    var name: String
    var sortOrder: Int
    var createdAt: Date
}
```

### AppSettings
```swift
struct AppSettings: Codable {
    var language: AppLanguage = .en
    var dailyGoalMinutes: Int = 15
    var notifications: [NotificationTime] = []
    var srsEnabled: Bool = false
    var trialStartDate: Date = Date()
    static let trialDays = 3
}
enum AppLanguage: String, CaseIterable, Codable, Identifiable { case en, cs, es }
struct NotificationTime: Codable, Identifiable, Equatable { var id: UUID; var hour: Int; var minute: Int }
```

### StudyConfig
```swift
struct StudyConfig {
    var mode: StudyMode = .typing        // typing / show / quiz
    var direction: StudyDirection = .frontToBack  // frontToBack / backToFront / random
    var order: CardOrder = .random       // ascending / descending / random
    var sectionSize: Int = 10            // 2–20
    var requiredCorrect: Int = 2         // 1–5
}
```

### Statistiky
- `CardStats` — attempts, correct, consecutiveCorrect, lastAnswered, srsInterval, srsDueDate, srsEaseFactor
- `DeckStats` — deckID, sessions: [SessionRecord], cardStats: [UUID: CardStats]
- `SessionRecord` — id, date, duration, totalAnswered, totalCorrect, mode, deckID
- `SessionResult` — deckID, date, duration, mode, totalAnswered, totalCorrect, wrongCardIDs: Set<UUID>

---

## 5. Formát karet (.txt)

```
# Komentář (řádky s # jsou ignorovány, prázdné řádky také)
hello - ahoj / čau
run - běžet / utíkat
apple - jablko
```
- Oddělovač: ` - ` (mezera-pomlčka-mezera)
- Alternativy: `/` (lomítko)
- Export: `# NázevDecku\nfront - back\n...`

---

## 6. Obrazovky — detailní popis

### MnemoStudyApp (root)
- `@StateObject library = LibraryViewModel()`
- `@StateObject settings = SettingsViewModel()`
- `@State showSplash = true`
- `init()`: volá `BundledLibraryLoader.loadInto(lib)` — načte bundled decky jen pokud `library.decks.isEmpty`
- Zobrazuje: SplashView (showSplash=true) nebo MainTabView + `.fullScreenCover(!settings.isTrialActive)` → PaywallView
- `.preferredColorScheme(.dark)` globálně

### SplashView
- Parametry: `lastDeck: (deck: Deck, accuracy: Double)?`, `lang: AppLanguage`, `onDismiss: () -> Void`
- Pozadí: `AppBg(opacity: 0.18)`
- Animace: logo (scale 0.7→1.0, opacity 0→1, spring 0.8s) + content (opacity 0→1, easeOut 0.6s, delay 0.3s)
- Foreground logo: `Image("MnemoLogo")`, frame width 120, RoundedRectangle cornerRadius 26, shadow mnemoGreen.opacity(0.4) radius 24
- Greeting: dobré ráno (5–12h) / dobrý den (12–18h) / dobrý večer (ostatní), font 28pt bold rounded, barva mnemoGold
- Last studied: pokud existuje — GlassCard s názvem decku + accuracy v LinearGradient (mnemoGreen→mnemoGold), font 36pt bold
- Footer: "Tap to continue" caption, "© 2025 Jiří Filipec" caption2
- Tap anywhere → onDismiss(); timeout 7s → auto dismiss

### MainTabView
- Čistý TabView, 3 taby: Library (books.vertical.fill) / Statistics (chart.bar.fill) / Settings (gearshape.fill)
- `.tint(.mnemoGreen)`
- Každý tab má vlastní AppBg()

### LibraryView
- NavigationStack > ZStack > AppBg() + ScrollView
- navigationTitle "Mnemo Study", .large
- Toolbar: Menu (+) s items: Add deck / New folder / Import
- LazyVStack spacing 12, padding 16
- Standalone decky (folderID == nil, !isTemporary) → deckSection
- Složky (FolderSection) — defaultně ZAVŘENÉ (isExpanded = false)
- Searchable (prompt: lang.librarySearch)
- Sheets: `sheet(item: $selectedDeck)` → StudySettingsView; `sheet(item: $editingDeck)` → DeckEditorView; `sheet(isPresented: $showNewDeck)` → DeckEditorView(deck: nil); `sheet(isPresented: $showImport)` → ImportView
- Alerts: New folder (TextField), Import error

**DeckCardView** (Button):
- HStack: ProgressRing(size 46, lineWidth 4) + VStack(name headline white, count caption secondary, SRS TagBadge gold) + Spacer + chevron.right
- .padding(16).glassCard()
- contextMenu: Rename / Share (ShareLink) / Delete (destructive)

**TempDeckCard**:
- HStack: exclamationmark.triangle.fill (orange) + VStack(libraryTemporary orange semibold, count caption2) + chevron
- background orange.opacity(0.08), stroke orange.opacity(0.25), cornerRadius 12

**FolderSection**:
- Toggle header button: folder.fill (mnemoGold) + název + počet decků + chevron up/down
- .glassCard() na headeru
- contextMenu na headeru: Delete folder (destructive)
- Decky uvnitř: DeckCardView s .padding(.leading, 12)

### StudySettingsView
- Sheet (modal), NavigationStack > ZStack > AppBg() + ScrollView
- navigationTitle: lang.settingsStudyTitle, .inline
- Cancel button v toolbaru
- Deck summary card (GlassCard): název decku + počet karet + ProgressRing(size 48)
- Pickers (segmented): Mode (typing/show/quiz) / Direction (f→b, b→f, random) / Order (asc/desc/random)
- Slider Section size: `in: 2...max(2.0, min(20.0, Double(deck.cards.count)))`, tint mnemoGreen
- Slider Required correct: `in: 1...5`, tint mnemoGold
- Quiz disabled pokud deck.cards.count < 4
- Start button (PrimaryButton mnemoGreen) → vytvoří StudyConfig, `showStudy = true`
- `studyConfig = StudyConfig()` — NON-OPTIONAL, inicializován s defaulty
- `.fullScreenCover(isPresented: $showStudy) { StudyView(deck: deck, config: studyConfig) }`
- `.onAppear { sectionSize = max(2, min(10, deck.cards.count)) }`

### StudyView
- fullScreenCover (modal), ZStack > AppBg() + VStack
- Top bar: X button (dismiss) + "completed/total" caption + Color.clear (balance)
- Progress bar: GeometryReader, Capsule gradient (mnemoGreen→mnemoGold), height 4, animace spring 0.4s
- Card content podle mode: typing / show / quiz
- Inline feedback: Color.black.opacity(0.4) + AnswerFeedbackOverlay, tap → vm.advanceAfterResult()
- `.onChange(of: vm.isSessionFinished) { if $0 { showResults = true } }`
- `.fullScreenCover(isPresented: $showResults) { ResultsView(...).onDisappear { library.recordSession(...); dismiss() } }`

**Typing mode**: front text 32pt bold rounded + TextField (plain, mnemoSurface bg, cornerRadius 14) + PrimaryButton "Check"

**Show mode**: front text 32pt + HStack(Don't know red.opacity(0.7) / Know mnemoGreen) — each full-width, cornerRadius 14

**Quiz mode**: front text 28pt + VStack 4 options (Button, mnemoSurface bg + white.opacity(0.1) stroke, cornerRadius 14)

### StudyViewModel (logika)
- `buildQueue()`: shuffle/sort cards, `pendingCards = Array(cards.dropFirst(sectionSize))`, `queue = initial.map SessionItem`
- `nextItem()`: dekrementuje showAfter countery, vrací první kde showAfter==0 && !isComplete
- Správná odpověď: correctCount++; pokud >= requiredCorrect → isComplete=true, completedCount++, načti další z pendingCards
- Špatná odpověď: wrongCardIDs.insert, correctCount=0, showAfter = random(3...5)
- Session finish: `remaining.filter { !isComplete }.isEmpty` → isSessionFinished = true
- Quiz options: 3 náhodní + správný, shuffle

### ResultsView
- fullScreenCover, ZStack > AppBg()
- ProgressRing(size 120, lineWidth 10) s accuracy % overlay
- Deck name + "Session results"
- Stats row (GlassCard): Answered / Correct / Time (m+s nebo jen s)
- Wrong deck notice: exclamationmark.triangle.fill orange + text
- PrimaryButton "Done" → dismiss

### StatisticsView
- NavigationStack > ZStack > AppBg() + ScrollView (nebo empty text)
- 3 headline stats (GlassCard each): streak (flame.fill orange) / accuracy (target mnemoGreen) / sessions (book.fill mnemoGold)
- Expandable: per-deck accuracy list, session history grouped by date
- WeeklyChart: last 7 days bar chart, barvy mnemoGreen + mnemoGreen.opacity(0.4), výška max 60pt

### SettingsView
- NavigationStack > ZStack > AppBg() + ScrollView
- Cards (GlassCard + padding 16): Daily goal slider (5–120 min, step 5, tint mnemoGreen) / Notifications (až 3, picker sheet) / Language (segmented picker) / SRS toggle + description / File formats info / Version footer
- TimePickerSheet: .presentationDetents([.medium]), wheel pickers pro hodiny (0–23) a minuty (0,5,10,...,55)

### PaywallView
- fullScreenCover, ZStack > AppBg()
- Logo: Image("MnemoLogo") width 80, cornerRadius 18
- Title: LinearGradient (mnemoGreen→mnemoGold)
- 4 feature rows (GlassCard)
- StoreKit product price + Unlock button + Restore button
- ProductID: `com.jirifilipec.mnemoapp.pro`
- Purchase: marks `settings.settings.trialStartDate = .distantPast`

### DeckEditorView
- Sheet, NavigationStack > ZStack > AppBg() + ScrollView
- TextField pro název
- Format hint card (green.opacity(0.08) bg, stroke green.opacity(0.2))
- TextEditor (min height 260, monospaced, mnemoSurface bg, padding 4)
- Live card count z FileParser
- Save: parsuje text, updateDeck nebo append+save

### ImportView
- Sheet, NavigationStack > ZStack > AppBg()
- Format info card
- Optional deck name TextField
- "Choose file" PrimaryButton → .fileImporter (plainText)
- Po importu: dismiss pokud bez chyby

---

## 7. Business logika

### Trial systém
- `trialStartDate` uložen v UserDefaults při první instalaci (default = Date())
- `isTrialActive = Calendar.dateComponents([.day], from: trialStartDate, to: Date()).day ?? 0 < 3`
- Pokud `!isTrialActive` → `.fullScreenCover(.constant(true))` → PaywallView (non-dismissable)

### Wrong Answers deck
- Po každé session kde jsou špatné odpovědi: vytvoří nebo aktualizuje tmp deck
- `isTemporary = true`, `parentDeckID = parentID`
- Vizuálně připnut pod rodičem (oranžový TempDeckCard)
- Karta zmizí po `consecutiveCorrect >= 3`
- Prázdný tmp deck → auto smazání

### SRS (Spaced Repetition) — volitelný
- SM-2 algoritmus: `newEF = max(1.3, EF + 0.1 - (5-q)(0.08 + (5-q)×0.02))`
- Interval: 1 → 3 → 7 → int(interval × EF) dnů
- Špatná odpověď: interval reset na 1, consecutiveCorrect = 0
- `isDue = srsDueDate == nil || srsDueDate <= Date()`
- TagBadge "X due today" na DeckCardView pokud srsEnabled && dueCount > 0

### Persistence (UserDefaults)
- Klíče: `ms_decks`, `ms_folders`, `ms_stats`, `appSettings`
- JSON encode/decode, save() po každé mutaci

### Notifikace
- Až 3 denní připomínky (UNCalendarNotificationTrigger, repeating)
- Requestuje oprávnění při přidání první připomínky

---

## 8. Bundled knihovny

5 jazyků × 5 kategorií = 25 decků, načteny pouze pokud `library.decks.isEmpty`.  
Složky (FolderSection) v LibraryView:

| Složka | Decky |
|---|---|
| CZ → AJ | Pozdravy, Slovesa, Přídavná jména, Podstatná jména, Fráze |
| ES → AJ | Saludos, Verbos, Adjetivos, Sustantivos, Frases |
| FR → AJ | Salutations, Verbes, Adjectifs, Noms, Phrases |
| DE → AJ | Begrüßungen, Verben, Adjektive, Nomen, Phrasen |
| ZH → AJ | 问候 Pozdravy, 动词 Slovesa, 形容词 Přídavná jména, 名词 Podstatná jména, 短语 Fráze |

Soubory: `Resources/BundledLibraries/{LANG}/{LANG}_{N}_{Název}.txt`

---

## 9. Build & Deploy

### GitHub Actions (`.github/workflows/main.yml`)
- Trigger: `workflow_dispatch` (manuální)
- Runner: `macos-26`
- Steps:
  1. `fix_icon.py` — odstraní alpha kanál z AppIcon.png (pure Python, bez PIL)
  2. `sips --resampleHeightWidth 1024 1024` — resize na 1024×1024
  3. Install certificate (Distribution .p12 z base64 secret)
  4. Install provisioning profile (UUID detection z mobileprovision)
  5. Install ASC key (.p8)
  6. `xcodebuild archive` — scheme MnemoStudy, Release, generic/platform=iOS
  7. PlistBuddy: `ITSAppUsesNonExemptEncryption = false`
  8. `xcodebuild -exportArchive` — ExportOptions.plist (app-store, teamID, provisioningProfiles)
  9. `xcrun altool --upload-app` — upload na App Store Connect

### GitHub Secrets potřebné
- `DISTRIBUTION_CERTIFICATE_BASE64`
- `CERTIFICATE_PASSWORD`
- `KEYCHAIN_PASSWORD`
- `PROVISIONING_PROFILE_BASE64`
- `ASC_API_KEY_BASE64`
- `ASC_KEY_ID`
- `ASC_ISSUER_ID`
- `APPLE_TEAM_ID`

### Xcode projekt
- `MnemoStudy.xcodeproj` (bez project.yml/XcodeGen)
- Bundle ID: `com.jirifilipec.mnemoapp`
- `CURRENT_PROJECT_VERSION` = build číslo (bump před každým uploaden)
- `MARKETING_VERSION` = 1.0

---

## 10. Lokalizace (Strings.swift)

Všechny UI stringy v `AppLanguage` extension (Strings.swift).  
Pattern: `var key: String { t("EN", "CS", "ES") }`  
Greeting helper: hodiny 5–12 ráno / 12–18 den / ostatní večer.

---

## 11. Opravené bugy (přehled)

| Build | Bug | Fix |
|---|---|---|
| 9 | MainTabView ZStack bez frame → layout rozbitý do stran | Odstraněn ZStack, AppBg přesunut do každého view |
| 12 | AppBg scaledToFill bez frame → přetékání | scaledToFit + Color.overlay |
| 13 | `sheet(isPresented:)+if let` → prázdný sheet (study se nespustilo) | `sheet(item:)` pro selectedDeck a editingDeck |
| 13 | Slider `2...min(20,0)` crash na prázdném decku | `max(2.0, min(20.0, count))` |
| 13 | Složky defaultně otevřené | `isExpanded = false` |
| 13 | `studyConfig: StudyConfig?` timing race v fullScreenCover | non-optional `= StudyConfig()` |
