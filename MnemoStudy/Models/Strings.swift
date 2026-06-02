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
    var libraryEditCards: String  { t("Edit cards",      "Upravit kartičky", "Editar tarjetas") }
    var libraryMoveToFolder: String { t("Move to folder","Přesunout do složky","Mover a carpeta") }
    var libraryShare: String      { t("Share",           "Sdílet",           "Compartir") }
    var libraryStudy: String      { t("Study",           "Studovat",         "Estudiar") }
    var librarySRSDue: String     { t("due today",       "dnes ke zkoušení", "para hoy") }
    var reviewDue: String         { t("Review due",      "Procvičit splatné","Repasar pendientes") }
    var reviewDeckName: String    { t("Daily review",    "Denní opakování",  "Repaso diario") }
    var reviewCardsDue: String    { t("cards due for review", "karet ke zopakování", "tarjetas para repasar") }
    var emptyDeckTitle: String    { t("No cards yet",    "Zatím žádné kartičky", "Sin tarjetas") }
    var emptyDeckMsg: String      {
        t("This deck has no cards. Add or import some first.",
          "Tato knihovna nemá žádné kartičky. Nejprve nějaké přidejte nebo naimportujte.",
          "Este mazo no tiene tarjetas. Añade o importa algunas primero.")
    }
    var deleteDeckConfirm: String {
        t("Delete this deck? This can't be undone.",
          "Smazat tuto knihovnu? Tuto akci nelze vrátit.",
          "¿Eliminar este mazo? No se puede deshacer.")
    }
    var deleteFolderConfirm: String {
        t("Delete this folder? Decks inside will be moved out, not deleted.",
          "Smazat tuto složku? Knihovny uvnitř se přesunou ven, nesmažou se.",
          "¿Eliminar esta carpeta? Los mazos se moverán fuera, no se eliminarán.")
    }

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
    var studyYourAnswer: String      { t("Your answer:",     "Tvoje odpověď:",    "Tu respuesta:") }
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
    var libraryMoveOut: String       { t("Remove from folder","Vyjmout ze složky", "Quitar de la carpeta") }
    var libraryMoveToFolderTitle: String { t("Move to folder", "Přesunout do složky", "Mover a carpeta") }

    // MARK: - Common
    var commonOK: String             { t("OK",    "OK",     "OK") }
    var commonAdd: String            { t("Add",   "Přidat", "Añadir") }
    var commonClose: String          { t("Close", "Zavřít", "Cerrar") }

    // MARK: - Tabs (info + feedback)
    var tabInfo: String              { t("Info",     "Info",       "Info") }
    var tabFeedback: String          { t("Feedback", "Zpětná vazba","Opiniones") }

    // MARK: - Feedback
    var feedbackTitle: String        { t("Feedback", "Zpětná vazba", "Opiniones") }
    var feedbackHeader: String       { t("Help shape Mnemo Study", "Pomozte utvářet Mnemo Study", "Ayuda a mejorar Mnemo Study") }
    var feedbackIntro: String        {
        t("Which features would you like to see next? Your vote directly influences what we build.",
          "Které funkce byste chtěli příště? Váš hlas přímo ovlivňuje, co vytvoříme.",
          "¿Qué funciones te gustaría ver? Tu voto influye directamente en lo que creamos.")
    }
    var feedbackQuestion: String     { t("What would you like to see?", "Co byste si přáli?", "¿Qué te gustaría ver?") }
    var feedbackSyncDesc: String     { t("Keep decks & progress across all your devices", "Knihovny a pokrok na všech zařízeních", "Mazos y progreso en todos tus dispositivos") }
    var feedbackAudioDesc: String    { t("Hear native pronunciation for every card", "Nativní výslovnost u každé karty", "Pronunciación nativa en cada tarjeta") }
    var feedbackDecksDesc: String    { t("More languages, topics, and vocabulary sets", "Více jazyků, témat a sad slovíček", "Más idiomas, temas y vocabulario") }
    var feedbackWatchDesc: String    { t("5 quick cards on your wrist every morning", "5 rychlých karet na zápěstí každé ráno", "5 tarjetas rápidas en tu muñeca cada mañana") }
    var feedbackAIDesc: String       { t("Paste any text and generate cards automatically", "Vložte text a karty se vytvoří samy", "Pega texto y genera tarjetas automáticamente") }
    var feedbackSharingDesc: String  { t("Share your decks with friends via link", "Sdílejte knihovny s přáteli přes odkaz", "Comparte tus mazos con amigos por enlace") }
    var feedbackAudio: String        { t("Audio Pronunciation", "Výslovnost (audio)", "Pronunciación") }
    var feedbackSync: String         { t("iCloud Sync", "Synchronizace iCloud", "Sincronización iCloud") }
    var feedbackMoreDecks: String    { t("More Built-in Decks", "Více vestavěných knihoven", "Más mazos integrados") }
    var feedbackWatch: String        { t("Apple Watch App", "Aplikace pro Apple Watch", "App para Apple Watch") }
    var feedbackAI: String           { t("AI Card Generator", "AI generátor karet", "Generador de tarjetas con IA") }
    var feedbackSharing: String      { t("Deck Sharing", "Sdílení knihoven", "Compartir mazos") }
    var feedbackElse: String         { t("Anything else on your mind?", "Cokoliv dalšího?", "¿Algo más?") }
    var feedbackSend: String         { t("Send Feedback", "Odeslat zpětnou vazbu", "Enviar opinión") }
    var feedbackWriteDirect: String  { t("Write directly:", "Napište přímo:", "Escribe directamente:") }
    var feedbackRate: String         { t("Rate Mnemo Study on the App Store", "Ohodnoťte Mnemo Study v App Store", "Califica Mnemo Study en la App Store") }
    var feedbackThanks: String       { t("Thank you! 🙏", "Děkujeme! 🙏", "¡Gracias! 🙏") }
    var feedbackThanksBody: String   {
        t("Your feedback has been sent. We'll use it to prioritize upcoming features.",
          "Vaše zpětná vazba byla odeslána. Použijeme ji k určení priorit dalších funkcí.",
          "Tu opinión ha sido enviada. La usaremos para priorizar próximas funciones.")
    }

    // MARK: - Onboarding
    var onbContinue: String          { t("Continue", "Pokračovat", "Continuar") }
    var onbStart: String             { t("Get Started", "Začít", "Empezar") }
    var onbTagline: String           { t("Master any language,\none card at a time", "Zvládněte jakýkoliv jazyk,\nkartu po kartě", "Domina cualquier idioma,\nuna tarjeta a la vez") }
    var onbHowTitle: String          { t("How it works", "Jak to funguje", "Cómo funciona") }
    var onbTypingDesc: String        { t("Type the answer from memory", "Napište odpověď zpaměti", "Escribe la respuesta de memoria") }
    var onbShowDesc: String          { t("Reveal the answer, judge yourself", "Odkryjte odpověď, ohodnoťte se", "Revela la respuesta, evalúate") }
    var onbQuizDesc: String          { t("Pick from 4 options", "Vyberte ze 4 možností", "Elige entre 4 opciones") }
    var onbSRSTitle: String          { t("Spaced Repetition", "Opakování s rozestupy", "Repetición espaciada") }
    var onbSRSDesc: String           {
        t("Wrong answers get flagged automatically.\n\nEnable SRS in Settings to schedule each card for review at the perfect moment — right before you forget it.",
          "Špatné odpovědi se automaticky označí.\n\nZapněte SRS v Nastavení a každá karta se naplánuje k zopakování ve správný okamžik — těsně než ji zapomenete.",
          "Las respuestas incorrectas se marcan automáticamente.\n\nActiva SRS en Ajustes para programar cada tarjeta en el momento justo, antes de olvidarla.")
    }

    // MARK: - Notifications (motivational + funny, rotate)
    var notificationMessages: [String] {
        switch self {
        case .en: return [
            "Time to study! 📚",
            "Your brain called — it wants more words 🧠",
            "Keep that streak alive, champion! 🔥",
            "Plot twist: 5 minutes now = fluent later ✨",
            "Your flashcards miss you 🥺",
            "Future polyglot, your training awaits 🎯",
            "Don't let those words escape! 🏃💨",
            "A wild study session appeared! 🎮",
            "Procrastination level: expert. Let's fix that 😏",
            "New words won't learn themselves 🤷",
            "Brain gains incoming 💪🧠",
            "Tap. Learn. Flex. Repeat. 😎"
        ]
        case .cs: return [
            "Čas se učit! 📚",
            "Volal tvůj mozek — chce další slovíčka 🧠",
            "Udrž tu sérii, šampione! 🔥",
            "Zápletka: 5 minut teď = plynně později ✨",
            "Tvoje kartičky se ti stýská 🥺",
            "Budoucí polyglote, trénink čeká 🎯",
            "Nenech ta slovíčka utéct! 🏃💨",
            "Objevila se divoká lekce! 🎮",
            "Úroveň prokrastinace: expert. Pojďme to spravit 😏",
            "Slovíčka se sama nenaučí 🤷",
            "Mozkové svaly na cestě 💪🧠",
            "Ťukni. Nauč se. Zaválej. Opakuj. 😎"
        ]
        case .es: return [
            "¡Hora de estudiar! 📚",
            "Tu cerebro llamó — quiere más palabras 🧠",
            "¡Mantén la racha, campeón! 🔥",
            "Giro inesperado: 5 minutos hoy = fluidez mañana ✨",
            "Tus tarjetas te extrañan 🥺",
            "Futuro políglota, tu entrenamiento espera 🎯",
            "¡No dejes escapar esas palabras! 🏃💨",
            "¡Apareció una sesión salvaje! 🎮",
            "Nivel de procrastinación: experto. Vamos a arreglarlo 😏",
            "Las palabras no se aprenden solas 🤷",
            "Ganancias cerebrales en camino 💪🧠",
            "Toca. Aprende. Presume. Repite. 😎"
        ]
        }
    }

    // MARK: - Info / Help
    var infoTitle: String            { t("How it works", "Jak to funguje", "Cómo funciona") }

    var infoAppTitle: String         { t("Getting started", "Začínáme", "Primeros pasos") }
    var infoAppBody: String          {
        t("Mnemo Study helps you memorize anything using flashcards. Each card has a front (the prompt) and a back (the answer). Pick a deck, choose how you want to be tested, and start learning. Wrong answers are collected into a 'Wrong answers' deck pinned under the original so you can drill them until they stick.",
          "Mnemo Study vám pomáhá zapamatovat si cokoliv pomocí kartiček. Každá karta má přední stranu (otázku) a zadní (odpověď). Vyberte knihovnu, zvolte způsob zkoušení a začněte. Špatné odpovědi se sbírají do knihovny „Špatné odpovědi“ připnuté pod původní, abyste je mohli procvičovat, dokud je neumíte.",
          "Mnemo Study te ayuda a memorizar con tarjetas. Cada tarjeta tiene un anverso (la pregunta) y un reverso (la respuesta). Elige un mazo, elige cómo quieres practicar y empieza. Las respuestas incorrectas se recogen en un mazo de «Respuestas erróneas» fijado bajo el original para que las practiques hasta dominarlas.")
    }

    var infoModesTitle: String       { t("Study modes", "Způsoby zkoušení", "Modos de estudio") }
    var infoModesBody: String        {
        t("Typing — type the answer from memory.\nShow — reveal the answer and judge yourself.\nQuiz — pick the right answer from 4 options (needs at least 4 cards).\n\nQuick-start presets (Student, Casual, Traveler, Intensive) set everything up for you in one tap.",
          "Psaní — napište odpověď zpaměti.\nZobrazení — odkryjte odpověď a ohodnoťte se.\nKvíz — vyberte správnou odpověď ze 4 možností (potřebuje aspoň 4 karty).\n\nPresety (Student, Pohoda, Cestovatel, Intenzivní) vám vše nastaví jedním klepnutím.",
          "Escribir — escribe la respuesta de memoria.\nMostrar — revela la respuesta y evalúate.\nCuestionario — elige la respuesta correcta entre 4 opciones (mín. 4 tarjetas).\n\nLos preajustes (Estudiante, Casual, Viajero, Intensivo) lo configuran todo con un toque.")
    }

    var infoSRSTitle: String         { t("What is SRS?", "Co je SRS?", "¿Qué es SRS?") }
    var infoSRSBody: String          {
        t("SRS (Spaced Repetition System) schedules each card for review at the optimal moment — right before you would forget it. Cards you know well come back less often; cards you struggle with come back sooner. This is the most efficient way to move words into long-term memory. Enable it in Settings.",
          "SRS (systém opakování s rozestupy) plánuje každou kartu k zopakování v optimální okamžik — těsně předtím, než byste ji zapomněli. Karty, které umíte, se vracejí méně často; karty, se kterými bojujete, dříve. Je to nejefektivnější způsob, jak dostat slovíčka do dlouhodobé paměti. Zapnete ji v Nastavení.",
          "SRS (repetición espaciada) programa cada tarjeta para repasarla en el momento óptimo — justo antes de olvidarla. Las que dominas vuelven menos; las difíciles, antes. Es la forma más eficiente de llevar palabras a la memoria a largo plazo. Actívalo en Ajustes.")
    }

    var infoOurSRSTitle: String      { t("Our smart SRS", "Náš chytrý SRS", "Nuestro SRS inteligente") }
    var infoOurSRSBody: String       {
        t("Unlike other apps, you never have to rate yourself ('easy/hard'). Mnemo Study measures how quickly and accurately you answer — in the background — and figures out how well you know each card on its own. During your first 5 sessions it watches your pace and calibrates to YOU personally. A fast answer means 'easy' (longer interval); a slow or wrong one means 'review soon'. Word length is taken into account so longer words get more time.",
          "Na rozdíl od jiných aplikací se nikdy nemusíte sami hodnotit („snadné/těžké“). Mnemo Study na pozadí měří, jak rychle a správně odpovídáte, a samo pozná, jak dobře každou kartu umíte. Během prvních 5 sezení sleduje vaše tempo a kalibruje se přímo VÁM. Rychlá odpověď znamená „snadné“ (delší interval); pomalá nebo špatná znamená „brzy zopakovat“. Zohledňuje se i délka slova — delší slova dostanou víc času.",
          "A diferencia de otras apps, nunca tienes que evaluarte ('fácil/difícil'). Mnemo Study mide en segundo plano qué tan rápido y bien respondes, y deduce cuánto sabes cada tarjeta. Durante tus primeras 5 sesiones observa tu ritmo y se calibra a TI. Una respuesta rápida es 'fácil' (intervalo más largo); una lenta o incorrecta significa 'repasar pronto'. Se considera la longitud de la palabra.")
    }

    var infoImportTitle: String      { t("Adding & importing decks", "Přidávání a import knihoven", "Añadir e importar mazos") }
    var infoImportBody: String       {
        t("Create a deck with the + button and type or paste your cards. Or import a .txt file from Files, iCloud, or another app.\n\nFormat — one pair per line:\n  word - translation\n\nLines starting with # are ignored (use them as notes/headers). Empty lines are skipped.",
          "Vytvořte knihovnu tlačítkem + a napište nebo vložte karty. Nebo importujte soubor .txt ze Souborů, iCloudu či jiné aplikace.\n\nFormát — jeden pár na řádek:\n  slovo - překlad\n\nŘádky začínající # se ignorují (použijte je jako poznámky/nadpisy). Prázdné řádky se přeskakují.",
          "Crea un mazo con el botón + y escribe o pega tus tarjetas. O importa un archivo .txt desde Archivos, iCloud u otra app.\n\nFormato — un par por línea:\n  palabra - traducción\n\nLas líneas que empiezan por # se ignoran (úsalas como notas). Las líneas vacías se omiten.")
    }

    var infoEditTitle: String        { t("Editing decks", "Úprava knihoven", "Editar mazos") }
    var infoEditBody: String         {
        t("Long-press a deck for options: Rename, Edit cards (change individual cards one by one), Move to folder, Share, or Delete. Long-press a folder to rename or delete it. Folders are one level deep — move decks in and out freely.",
          "Podržte prst na knihovně pro možnosti: Přejmenovat, Upravit kartičky (měňte jednotlivé karty), Přesunout do složky, Sdílet nebo Smazat. Podržením složky ji přejmenujete či smažete. Složky jsou jednoúrovňové — knihovny můžete volně přesouvat dovnitř i ven.",
          "Mantén pulsado un mazo para ver opciones: Renombrar, Editar tarjetas (cambiar tarjetas una a una), Mover a carpeta, Compartir o Eliminar. Mantén pulsada una carpeta para renombrarla o eliminarla. Las carpetas son de un nivel — mueve mazos dentro y fuera libremente.")
    }

    var infoAnswersTitle: String     { t("How answers are checked", "Jak se kontrolují odpovědi", "Cómo se revisan las respuestas") }
    var infoAnswersBody: String      {
        t("Answers are case-insensitive: 'Hello', 'hello' and 'HELLO' all count.\n\nMultiple correct answers — separate them with a slash:\n  hello - ahoj / čau\nNow either 'ahoj' OR 'čau' is accepted.\n\nLeading/trailing spaces are ignored. You must type one full alternative exactly (no partial matches).",
          "Na velikosti písmen nezáleží: „Ahoj“, „ahoj“ i „AHOJ“ se počítají.\n\nVíce správných odpovědí — oddělte je lomítkem:\n  hello - ahoj / čau\nUznají se „ahoj“ NEBO „čau“.\n\nMezery na začátku a konci se ignorují. Musíte napsat přesně jednu celou variantu (ne částečnou shodu).",
          "No distingue mayúsculas: 'Hola', 'hola' y 'HOLA' valen.\n\nVarias respuestas correctas — sepáralas con una barra:\n  hello - hola / buenas\nSe acepta 'hola' O 'buenas'.\n\nLos espacios al inicio/final se ignoran. Debes escribir una alternativa completa exacta (sin coincidencias parciales).")
    }

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
