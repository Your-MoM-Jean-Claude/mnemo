import Foundation

// Central localization — add keys here, extend per language below.
extension AppLanguage {

    // MARK: - Tabs
    var tabLibrary: String     { t("Library",    "Knihovny",    "Biblioteca") }
    var tabStats: String       { t("Statistics", "Statistiky",  "Estadísticas") }
    var tabSettings: String    { t("Settings",   "Nastavení",   "Ajustes") }

    // MARK: - Splash
    var splashGreetingMorning: String  { t("Good morning",   "Dobré ráno",   "Buenos días") }
    var splashGreetingDay: String      { t("Good afternoon", "Dobrý den",    "Buenas tardes") }
    var splashGreetingEvening: String  { t("Good evening",   "Dobrý večer",  "Buenas noches") }
    var splashLastStudied: String      { t("Last studied",   "Naposledy",    "Último estudio") }
    var splashTapToContinue: String    { t("Tap to continue","Klepnutím pokračujte","Toca para continuar") }

    // MARK: - Library
    var libraryEmpty: String      { t("No decks yet",    "Žádné knihovny",   "Sin mazos") }
    var libraryAdd: String        { t("Add deck",        "Přidat knihovnu",  "Añadir mazo") }
    var libraryNewFolder: String  { t("New folder",      "Nová složka",      "Nueva carpeta") }
    var libraryImport: String     { t("Import from file","Importovat soubor","Importar archivo") }
    var librarySearch: String     { t("Search",          "Hledat",           "Buscar") }
    var libraryCards: String      { t("cards",           "karet",            "tarjetas") }
    var libraryTemporary: String  { t("Wrong answers",   "Špatné odpovědi",  "Respuestas erróneas") }
    var libraryDelete: String     { t("Delete",          "Smazat",           "Eliminar") }
    var libraryRename: String     { t("Rename",          "Přejmenovat",      "Renombrar") }
    var libraryMoveToFolder: String { t("Move to folder","Přesunout do složky","Mover a carpeta") }
    var libraryShare: String      { t("Share",           "Sdílet",           "Compartir") }
    var libraryStudy: String      { t("Study",           "Studovat",         "Estudiar") }
    var librarySRSDue: String     { t("due today",       "dnes ke zkoušení", "para hoy") }

    // MARK: - Deck editor
    var editorNewDeck: String     { t("New deck",        "Nová knihovna",    "Nuevo mazo") }
    var editorEditDeck: String    { t("Edit deck",       "Upravit knihovnu", "Editar mazo") }
    var editorDeckName: String    { t("Deck name",       "Název knihovny",   "Nombre del mazo") }
    var editorAddCard: String     { t("Add card",        "Přidat kartu",     "Añadir tarjeta") }
    var editorFront: String       { t("Front",           "Přední strana",    "Anverso") }
    var editorBack: String        { t("Back",            "Zadní strana",     "Reverso") }
    var editorFormatHint: String  {
        t("Format: word - translation / alternative",
          "Formát: slovo - překlad / alternativa",
          "Formato: palabra - traducción / alternativa")
    }
    var editorFormatHintTitle: String { t("Format guide", "Formát", "Formato") }
    var editorFormatHintBody: String  {
        t(
            "One pair per line:  front - back\nAlternatives: front - answer1 / answer2\nSkip a line or use # for comments\n\nExamples:\nhello - ahoj / čau\nrun - běžet / utíkat",
            "Jeden pár na řádek:  přední - zadní\nAlternativy: přední - odpověď1 / odpověď2\nPrázdný řádek nebo # = komentář\n\nPříklady:\nhello - ahoj / čau\nrun - běžet / utíkat",
            "Un par por línea:  frente - reverso\nAlternativas: frente - resp1 / resp2\nLínea vacía o # = comentario\n\nEjemplos:\nhello - hola / buenas\nrun - correr / huir"
        )
    }
    var editorCardsText: String   { t("Cards (one per line)", "Kartičky (jeden pár na řádek)", "Tarjetas (un par por línea)") }
    var editorCardCount: String   { t("cards", "karet", "tarjetas") }
    var editorSave: String        { t("Save",            "Uložit",           "Guardar") }
    var editorCancel: String      { t("Cancel",          "Zrušit",           "Cancelar") }
    var editorPaste: String       { t("Paste text",      "Vložit text",      "Pegar texto") }
    var editorPasteHint: String   {
        t("Paste your pairs (one per line):\nword - translation / alternative",
          "Vložte páry (jeden na řádek):\nslovo - překlad / alternativa",
          "Pega tus pares (uno por línea):\npalabra - traducción / alternativa")
    }

    // MARK: - Import
    var importTitle: String       { t("Import",          "Import",           "Importar") }
    var importSupported: String   {
        t("Supported format: .txt with \"front - back\" per line",
          "Podporovaný formát: .txt s \"přední - zadní\" na každém řádku",
          "Formato admitido: .txt con \"anverso - reverso\" por línea")
    }
    var importChooseFile: String  { t("Choose file",     "Vybrat soubor",    "Elegir archivo") }
    var importError: String       { t("Import failed",   "Chyba importu",    "Error al importar") }

    // MARK: - Study settings
    var settingsStudyTitle: String   { t("Study settings",  "Nastavení studia",  "Configuración") }
    var settingsDirection: String    { t("Direction",        "Směr",              "Dirección") }
    var settingsFrontToBack: String  { t("Front → Back",     "Přední → Zadní",    "Frente → Atrás") }
    var settingsBackToFront: String  { t("Back → Front",     "Zadní → Přední",    "Atrás → Frente") }
    var settingsRandom: String       { t("Random",           "Náhodně",           "Aleatorio") }
    var settingsSectionSize: String  { t("Section size",     "Velikost sekce",    "Tamaño de sección") }
    var settingsRequired: String     { t("Required correct", "Počet správných",   "Correctas requeridas") }
    var settingsMode: String         { t("Study mode",       "Způsob zkoušení",   "Modo de estudio") }
    var settingsModeTyping: String   { t("Typing",           "Psaní",             "Escribir") }
    var settingsModeShow: String     { t("Show",             "Zobrazení",         "Mostrar") }
    var settingsModeQuiz: String     { t("Quiz",             "Kvíz",              "Cuestionario") }
    var settingsOrder: String        { t("Card order",       "Pořadí karet",      "Orden de tarjetas") }
    var settingsOrderAsc: String     { t("Ascending",        "Vzestupně",         "Ascendente") }
    var settingsOrderDesc: String    { t("Descending",       "Sestupně",          "Descendente") }
    var settingsStart: String        { t("Start",            "Začít",             "Iniciar") }

    // MARK: - Study view
    var studyCardOf: String          { t("of",               "z",                 "de") }
    var studyTypeAnswer: String      { t("Type the answer",  "Napište odpověď",   "Escribe la respuesta") }
    var studyCheck: String           { t("Check",            "Zkontrolovat",      "Comprobar") }
    var studyKnow: String            { t("I know it",        "Znám",              "Lo sé") }
    var studyDontKnow: String        { t("Don't know",       "Neznám",            "No lo sé") }
    var studyCorrect: String         { t("Correct!",         "Správně!",          "¡Correcto!") }
    var studyWrong: String           { t("Wrong",            "Špatně",            "Incorrecto") }
    var studyCorrectAnswer: String   { t("Correct answer:",  "Správná odpověď:",  "Respuesta correcta:") }
    var studyFinish: String          { t("Finish",           "Dokončit",          "Finalizar") }
    var studyReveal: String          { t("Reveal answer",    "Odkrýt odpověď",    "Revelar respuesta") }

    // MARK: - Results
    var resultsTitle: String         { t("Session results",  "Výsledky sezení",   "Resultados") }
    var resultsAccuracy: String      { t("Accuracy",         "Úspěšnost",         "Precisión") }
    var resultsAnswered: String      { t("Answered",         "Zodpovězeno",       "Respondidas") }
    var resultsTime: String          { t("Time",             "Čas",               "Tiempo") }
    var resultsDone: String          { t("Done",             "Hotovo",            "Listo") }
    var resultsStudyAgain: String    { t("Study again",      "Znovu studovat",    "Estudiar de nuevo") }
    var resultsWrongCreated: String  {
        t("A \"Wrong answers\" deck has been created.",
          "Byla vytvořena knihovna se špatnými odpověďmi.",
          "Se creó un mazo de respuestas incorrectas.")
    }

    // MARK: - Statistics
    var statsStreak: String          { t("Day streak",       "Série dní",         "Racha") }
    var statsAccuracy: String        { t("Accuracy",         "Úspěšnost",         "Precisión") }
    var statsSessions: String        { t("Sessions",         "Sezení",            "Sesiones") }
    var statsAllDecks: String        { t("All decks",        "Všechny knihovny",  "Todos los mazos") }
    var statsSessionHistory: String  { t("Session history",  "Historie sezení",   "Historial") }
    var statsToday: String           { t("Today",            "Dnes",              "Hoy") }
    var statsNoData: String          { t("No study sessions yet.", "Zatím žádná sezení.", "Sin sesiones aún.") }

    // MARK: - Settings
    var settingsDailyGoal: String    { t("Daily goal",       "Denní cíl",         "Meta diaria") }
    var settingsMinutes: String      { t("min",              "min",               "min") }
    var settingsNotifications: String{ t("Reminders",        "Připomínky",        "Recordatorios") }
    var settingsAddReminder: String  { t("Add reminder",     "Přidat připomínku", "Añadir recordatorio") }
    var settingsLanguage: String     { t("Language",         "Jazyk",             "Idioma") }
    var settingsSRS: String          { t("Spaced Repetition (SRS)", "Opakování se rozestupy (SRS)", "Repetición espaciada (SRS)") }
    var settingsSRSDesc: String      {
        t("SRS schedules each card for review at the optimal time — right before you forget it. Cards answered correctly appear less often; wrong answers sooner.",
          "SRS naplánuje každou kartu k zopakování ve správný čas — těsně před tím, než zapomenete. Správné odpovědi se zobrazují méně, špatné dříve.",
          "SRS programa cada tarjeta para revisarla en el momento óptimo. Las respuestas correctas aparecen menos; las incorrectas, antes.")
    }
    var settingsVersion: String      { t("Version",          "Verze",             "Versión") }
    var settingsFileFormats: String  { t("Supported file formats", "Podporované formáty souborů", "Formatos admitidos") }
    var settingsFileFormatsDesc: String {
        t("Import .txt files with one pair per line:\nword - translation / alternative\n\nLines starting with # are ignored (comments).",
          "Importujte .txt soubory s jedním párem na řádek:\nslovo - překlad / alternativa\n\nŘádky začínající # jsou ignorovány (komentáře).",
          "Importa archivos .txt con un par por línea:\npalabra - traducción / alternativa\n\nLas líneas que empiezan por # se ignoran.")
    }

    // MARK: - Paywall
    var paywallTitle: String         { t("Mnemo Study Pro",  "Mnemo Study Pro",   "Mnemo Study Pro") }
    var paywallSubtitle: String      {
        t("Your free trial has ended. Unlock full access to continue.",
          "Vaše zkušební doba skončila. Odemkněte plný přístup.",
          "Tu período de prueba ha terminado. Desbloquea el acceso completo.")
    }
    var paywallFeature1: String      { t("Unlimited decks & cards",      "Neomezené knihovny a karty",   "Mazos y tarjetas ilimitados") }
    var paywallFeature2: String      { t("All study modes",              "Všechny způsoby zkoušení",     "Todos los modos de estudio") }
    var paywallFeature3: String      { t("Spaced repetition (SRS)",      "Opakování se rozestupy",       "Repetición espaciada") }
    var paywallFeature4: String      { t("Statistics & progress",        "Statistiky a pokrok",          "Estadísticas y progreso") }
    var paywallPurchase: String      { t("Unlock",                       "Odemknout",                    "Desbloquear") }
    var paywallRestore: String       { t("Restore purchase",             "Obnovit nákup",                "Restaurar compra") }
    var paywallCancelAnytime: String { t("Cancel anytime",               "Zrušit kdykoliv",              "Cancela cuando quieras") }

    // MARK: - Folder
    var folderName: String           { t("Folder name",      "Název složky",      "Nombre de carpeta") }
    var folderCreate: String         { t("Create folder",    "Vytvořit složku",   "Crear carpeta") }

    // MARK: - Common
    var commonOK: String             { t("OK",    "OK",     "OK") }
    var commonAdd: String            { t("Add",   "Přidat", "Añadir") }

    // MARK: - Greeting helper
    var currentGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return splashGreetingMorning
        case 12..<18: return splashGreetingDay
        default:      return splashGreetingEvening
        }
    }

    // MARK: - Private helper
    private func t(_ en: String, _ cs: String, _ es: String) -> String {
        switch self {
        case .en: return en
        case .cs: return cs
        case .es: return es
        }
    }
}
