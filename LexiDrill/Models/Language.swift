 import Foundation
  import Combine

  // MARK: - Language

  enum Language: String, CaseIterable, Codable, Identifiable {
      case czech   = "cs"
      case english = "en"
      case spanish = "es"

      var id: String { rawValue }

      var displayName: String {
          switch self {
          case .czech:   return "CZ"
          case .english: return "EN"
          case .spanish: return "SP"
          }
      }
  }

  // MARK: - Manager

  class LanguageManager: ObservableObject {
      @Published var language: Language {
          didSet { UserDefaults.standard.set(language.rawValue, forKey: "appLanguage")
   }
      }

      init() {
          let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
          language = Language(rawValue: saved) ?? .english
      }

      var s: AppStrings { AppStrings(lang: language) }
  }

  // MARK: - Strings

  struct AppStrings {
      let lang: Language

      private func t(_ cs: String, _ en: String, _ es: String) -> String {
          switch lang {
          case .czech:   return cs
          case .english: return en
          case .spanish: return es
          }
      }

      // MARK: Tabs
      var libraryTab: String {
          t("Knihovna", "Library", "Biblioteca")
      }
      var statsTab: String {
          t("Statistiky", "Statistics", "Estadísticas")
      }

      // MARK: Library
      var importFile: String {
          t("Importovat soubor (.txt)", "Import file (.txt)", "Importar archivo
  (.txt)")
      }
      var pasteText: String {
          t("Vložit text", "Paste text", "Pegar texto")
      }
      var noLists: String {
          t("Žádné seznamy", "No lists", "Sin listas")
      }
      var emptyStateDesc: String {
          t(
              "Importuj .txt soubor nebo vlož text\nve formátu:\nslovo - překlad",
              "Import a .txt file or paste text\nin the format:\nword - translation",
              "Importa un archivo .txt o pega texto\nen el formato:\npalabra -
  traducción"
          )
      }
      var importFileButton: String {
          t("Importovat soubor", "Import file", "Importar archivo")
      }
      var importError: String {
          t("Chyba importu", "Import error", "Error de importación")
      }
      var rename: String {
          t("Přejmenovat", "Rename", "Renombrar")
      }
      var delete: String {
          t("Smazat", "Delete", "Eliminar")
      }
      var editBtn: String {
          t("Upravit", "Edit", "Editar")
      }
      var searchLists: String {
          t("Hledat seznamy…", "Search lists…", "Buscar listas…")
      }
      var completed: String {
          t("Dokončeno", "Completed", "Completado")
      }
      var noResults: String {
          t("Žádné výsledky", "No results", "Sin resultados")
      }
      var ok: String { "OK" }
      var pairs: String {
          t("páry", "pairs", "pares")
      }
      var accuracyLabel: String {
          t("úspěšnost", "accuracy", "precisión")
      }

      // MARK: Settings
      var settingsTitle: String {
          t("Nastavení", "Settings", "Configuración")
      }
      var quizDirection: String {
          t("Směr zkoušení", "Quiz direction", "Dirección del quiz")
      }
      var randomDir: String {
          t("Náhodně oba směry", "Random both directions", "Ambas direcciones")
      }
      var wordsPerBatch: String {
          t("Slovíček v sérii", "Words per round", "Palabras por ronda")
      }
      var correctInRow: String {
          t("Správně za sebou", "Correct in a row", "Correctas seguidas")
      }
      var correctInRowHint: String {
          t(
              "Kolikrát musíš odpovědět správně, než přejdeš k další sérii.",
              "How many times you need to answer correctly before advancing.",
              "Cuántas veces debes responder correctamente antes de avanzar."
          )
      }
      var roundSettings: String {
          t("Nastavení série", "Round settings", "Configuración de ronda")
      }
      var shuffleOrder: String {
          t("Zamíchat pořadí", "Shuffle order", "Mezclar orden")
      }
      var other: String {
          t("Další", "Other", "Otro")
      }
      var cancel: String {
          t("Zrušit", "Cancel", "Cancelar")
      }
      var start: String {
          t("Začít", "Start", "Empezar")
      }
      var statistics: String {
          t("Statistiky", "Statistics", "Estadísticas")
      }
      var totalSessions: String {
          t("Celkem sezení", "Total sessions", "Sesiones totales")
      }
      var totalAnswers: String {
          t("Celkem odpovědí", "Total answers", "Respuestas totales")
      }
      var correctLabel: String {
          t("Správně", "Correct", "Correctas")
      }
      var bestStreakLabel: String {
          t("Nejlepší série", "Best streak", "Mejor racha")
      }
      var wordPairs: String {
          t("slovních párů", "word pairs", "pares de palabras")
      }

      // MARK: Quiz
      var hintBtn: String {
          t("Napovědět", "Show hint", "Mostrar pista")
      }
      var translate: String {
          t("Přelož:", "Translate:", "Traduce:")
      }
      var yourAnswer: String {
          t("Tvoje odpověď", "Your answer", "Tu respuesta")
      }
      var check: String {
          t("Zkontrolovat", "Check", "Comprobar")
      }
      var correctAnswer: String {
          t("Správně!", "Correct!", "¡Correcto!")
      }
      var wrongAnswer: String {
          t("Chyba", "Wrong", "Error")
      }
      var yourAnswerWas: String {
          t("Tvoje odpověď:", "Your answer:", "Tu respuesta:")
      }
      var inRow: String {
          t("× v řadě!", "× in a row!", "× seguidas!")
      }
      var continueBtn: String {
          t("Pokračovat", "Continue", "Continuar")
      }
      var showResults: String {
          t("Zobrazit výsledky", "Show results", "Ver resultados")
      }
      var nextBatch: String {
          t("Další série →", "Next round →", "Siguiente ronda →")
      }
      var excellent: String {
          t("Výborně! 🎉", "Excellent! 🎉", "¡Excelente! 🎉")
      }
      var goodJob: String {
          t("Dobře! 👍", "Good! 👍", "¡Bien! 👍")
      }
      var tryAgain: String {
          t("Zkus to znovu 💪", "Try again 💪", "Inténtalo de nuevo 💪")
      }
      var sessionDone: String {
          t("Sezení dokončeno", "Session complete", "Sesión completada")
      }
      var successRate: String {
          t("Úspěšnost", "Accuracy", "Precisión")
      }
      var backToLibrary: String {
          t("Zpět do knihovny", "Back to library", "Volver a la biblioteca")
      }
      var quit: String {
          t("Ukončit", "Quit", "Salir")
      }

      func batchDone(_ n: Int) -> String {
          t("Série \(n) hotova!", "Round \(n) done!", "¡Ronda \(n) terminada!")
      }
      func prepareForBatch(_ cur: Int, _ total: Int) -> String {
          t(
              "Připrav se na sérii \(cur) z \(total)",
              "Get ready for round \(cur) of \(total)",
              "Prepárate para la ronda \(cur) de \(total)"
          )
      }
      func batchProgress(_ cur: Int, _ total: Int) -> String {
          t("Série \(cur) / \(total)", "Round \(cur) / \(total)", "Ronda \(cur) /
  \(total)")
      }
      func previewCount(_ n: Int) -> String {
          t("Náhled (\(n) párů)", "Preview (\(n) pairs)", "Vista previa (\(n) pares)")
      }
      func andMore(_ n: Int) -> String {
          t("… a dalších \(n)", "… and \(n) more", "… y \(n) más")
      }

      // MARK: Word editor
      var editWords: String {
          t("Upravit slovíčka", "Edit words", "Editar palabras")
      }
      var addWord: String {
          t("Přidat slovíčko", "Add word", "Añadir palabra")
      }
      var editWord: String {
          t("Upravit slovíčko", "Edit word", "Editar palabra")
      }
      var frontSide: String {
          t("Přední strana", "Front", "Anverso")
      }
      var backSide: String {
          t("Zadní strana", "Back", "Reverso")
      }
      var slashHint: String {
          t(
              "Tip: / odděluje více variant (např. \"big / large\") — správná je
  kterákoliv z nich.",
              "Tip: / separates multiple variants (e.g. \"big / large\") — any one is
  accepted.",
              "Tip: / separa variantes (p.ej. \"grande / largo\") — cualquiera es
  válida."
          )
      }
      var save: String {
          t("Uložit", "Save", "Guardar")
      }
      var done: String {
          t("Hotovo", "Done", "Listo")
      }

      // MARK: Paste Import
      var listName: String {
          t("Název seznamu", "List name", "Nombre de la lista")
      }
      var listNamePlaceholder: String {
          t("např. Angličtina lekce 1", "e.g. English lesson 1", "p.ej. Inglés lección
   1")
      }
      var formatHint: String {
          t(
              "Formát: každý řádek = **slovo - překlad**\nŘádky začínající # jsou
  komentáře.",
              "Format: each line = **word - translation**\nLines starting with # are
  comments.",
              "Formato: cada línea = **palabra - traducción**\nLas líneas que empiezan
   con # son comentarios."
          )
      }
      var help: String {
          t("Nápověda", "Help", "Ayuda")
      }
      var wordText: String {
          t("Text slovíček", "Word text", "Texto de palabras")
      }
      var importBtn: String {
          t("Importovat", "Import", "Importar")
      }
      var newList: String {
          t("Nový seznam", "New list", "Nueva lista")
      }

      // MARK: Stats View
      var studyStreakLabel: String {
          t("Série dnů", "Study streak", "Racha de días")
      }
      var overallAccuracy: String {
          t("Celková úspěšnost", "Overall accuracy", "Precisión general")
      }
      var weeklyActivity: String {
          t("Aktivita za 7 dní", "7-Day Activity", "Actividad semanal")
      }
      var hardestWords: String {
          t("Nejtěžší slovíčka", "Hardest Words", "Palabras difíciles")
      }
      var noStatsYet: String {
          t("Žádné statistiky", "No statistics yet", "Sin estadísticas aún")
      }
      var noStatsDesc: String {
          t(
              "Splň první cvičení a statistiky se začnou zobrazovat.",
              "Complete your first quiz and statistics will appear here.",
              "Completa tu primer quiz y aquí aparecerán las estadísticas."
          )
      }
      var attempts: String {
          t("pokusů", "attempts", "intentos")
      }
      var listsOverview: String {
          t("Přehled seznamů", "Lists overview", "Resumen de listas")
      }
      var trend: String {
          t("Trend", "Trend", "Tendencia")
      }

      func streakDays(_ n: Int) -> String {
          switch lang {
          case .czech:
              if n == 1 { return "1 den" }
              if n < 5  { return "\(n) dny" }
              return "\(n) dní"
          case .english:
              return "\(n) \(n == 1 ? "day" : "days")"
          case .spanish:
              return "\(n) \(n == 1 ? "día" : "días")"
          }
      }

      var dataLoadError: String {
          t(
              "Uložená data se nepodařilo načíst. Některé seznamy mohly být
  ztraceny.",
              "Failed to load saved data. Some lists may have been lost.",
              "No se pudieron cargar los datos. Algunas listas pueden haberse
  perdido."
          )
      }
      var dataLoadErrorTitle: String {
          t("Chyba dat", "Data Error", "Error de datos")
      }

      // MARK: Quiz Mode
      var settingsTab: String {
          t("Nastavení", "Settings", "Ajustes")
      }
      var dirFrontToBack: String {
          t("Přední → Zadní", "Front → Back", "Frente → Dorso")
      }
      var dirBackToFront: String {
          t("Zadní → Přední", "Back → Front", "Dorso → Frente")
      }
      var quizModeSection: String {
          t("Režim zkoušení", "Quiz mode", "Modo de quiz")
      }
      var modeTyping: String {
          t("Psaní", "Typing", "Escritura")
      }
      var modeFlashcard: String {
          t("Kartičky", "Flashcards", "Tarjetas")
      }
      var modeMultipleChoice: String {
          t("Kvíz", "Quiz", "Quiz")
      }
      var flashcardRevealBtn: String {
          t("Zobrazit odpověď", "Reveal answer", "Mostrar respuesta")
      }
      var flashcardKnow: String {
          t("Umím ✓", "Got it ✓", "Lo sé ✓")
      }
      var flashcardDontKnow: String {
          t("Neumím ✗", "Not yet ✗", "No sé ✗")
      }

      // MARK: SRS
      var studyModeSection: String {
          t("Režim učení", "Study mode", "Modo de estudio")
      }
      var studyModeClassic: String {
          t("Klasický", "Classic", "Clásico")
      }
      var studyModeSRS: String {
          t("Spaced Repetition", "Spaced Repetition", "Repetición espaciada")
      }
      var srsAgain: String {
          t("Znovu", "Again", "De nuevo")
      }
      var srsHard: String {
          t("Těžké", "Hard", "Difícil")
      }
      var srsGood: String {
          t("Dobře", "Good", "Bien")
      }
      var srsEasy: String {
          t("Lehké", "Easy", "Fácil")
      }
      func srsDueToday(_ n: Int) -> String {
          t(
              "\(n) slovíček ke zkoušení dnes",
              "\(n) card\(n == 1 ? "" : "s") due today",
              "\(n) tarjeta\(n == 1 ? "" : "s") pendiente\(n == 1 ? "" : "s")"
          )
      }

      // MARK: Review timing
      var lastStudiedToday: String {
          t("Dnes", "Today", "Hoy")
      }
      var lastStudiedYesterday: String {
          t("Včera", "Yesterday", "Ayer")
      }
      func lastStudiedDaysAgo(_ n: Int) -> String {
          t("Před \(n) dny", "\(n)d ago", "Hace \(n)d")
      }
      func dueNow(_ n: Int) -> String {
          t("\(n) ke zkoušení", "\(n) due", "\(n) pendientes")
      }
      func nextReviewIn(_ n: Int) -> String {
          switch lang {
          case .czech:
              return n == 1 ? "za 1 den" : n < 5 ? "za \(n) dny" : "za \(n) dní"
          case .english:
              return "in \(n) \(n == 1 ? "day" : "days")"
          case .spanish:
              return "en \(n) \(n == 1 ? "día" : "días")"
          }
      }

      // MARK: Study goal & notifications
      var studyGoalSection: String {
          t("Studijní cíl", "Study goal", "Meta de estudio")
      }
      var studyGoalLabel: String {
          t("Denní cíl", "Daily goal", "Meta diaria")
      }
      var noGoal: String {
          t("Bez cíle", "No goal", "Sin meta")
      }
      var reminderEnabled: String {
          t("Denní připomínka", "Daily reminder", "Recordatorio diario")
      }
      var reminderTime: String {
          t("Čas připomínky", "Reminder time", "Hora del recordatorio")
      }
      var minutes: String {
          t("min", "min", "min")
      }
      var notificationBody: String {
          t(
              "Čas na slovíčka! Procvič svůj seznam.",
              "Time to study! Review your word list.",
              "¡Hora de estudiar! Repasa tu lista."
          )
      }

      // MARK: Daily goal achievement
      var goalMetTitle: String {
          t("Denní cíl splněn!", "Daily Goal Complete!", "¡Meta diaria cumplida!")
      }
      func goalMetBody(_ minutes: Int) -> String {
          t(
              "Dnes jsi nastudoval/a \(minutes) min. Skvělá práce!",
              "You studied \(minutes) min today. Great work!",
              "Estudiaste \(minutes) min hoy. ¡Buen trabajo!"
          )
      }

      // MARK: Stats expandable sections
      var sessionHistoryTitle: String {
          t("Historie sezení", "Session History", "Historial de sesiones")
      }
      var accuracyBreakdown: String {
          t("Přesnost dle knihoven", "Accuracy by List", "Precisión por lista")
      }

      // MARK: Per-list statistics view
      var wordStatsTitle: String {
          t("Statistiky slov", "Word Statistics", "Estadísticas")
      }
      var perWordSection: String {
          t("Slovíčka", "Words", "Palabras")
      }
      var attemptsLabel: String {
          t("pokusů", "attempts", "intentos")
      }
      var dueLabel: String {
          t("ke zkoušení", "due now", "pendiente")
      }
      var notStudiedYet: String {
          t("Ještě nezkušeno", "Not studied yet", "Sin estudiar")
      }
      var deleteStatsBtn: String {
          t("Vymazat statistiky", "Clear Statistics", "Borrar estadísticas")
      }
      var deleteStatsConfirm: String {
          t("Vymazat statistiky?", "Clear Statistics?", "¿Borrar estadísticas?")
      }
      var deleteStatsDesc: String {
          t(
              "Tato akce smaže všechny výsledky pro tuto knihovnu. Nelze vrátit
  zpět.",
              "This will delete all results for this list. This cannot be undone.",
              "Esto borrará todos los resultados de esta lista. No se puede deshacer."
          )
      }

      // MARK: Wrong words offer
      var wrongWordsOfferTitle: String {
          t("Chybná slovíčka", "Mistakes", "Palabras incorrectas")
      }
      func wrongWordsOfferBody(_ n: Int) -> String {
          t(
              "Udělal/a jsi chybu u \(n) slovíček. Chceš je procvičit?",
              "You made \(n) mistake\(n == 1 ? "" : "s"). Review them?",
              "Cometiste \(n) error\(n == 1 ? "" : "es"). ¿Repasarlos?"
          )
      }
      var reviewWrongBtn: String {
          t("Procvičit chybná", "Review mistakes", "Repasar errores")
      }
      var skipToResultsBtn: String {
          t("Zobrazit výsledky", "See results", "Ver resultados")
      }

      // MARK: Welcome screen
      func welcomeGreeting(hour: Int) -> String {
          switch hour {
          case 5..<12:  return t("Dobré ráno", "Good morning", "Buenos días")
          case 12..<18: return t("Dobré odpoledne", "Good afternoon", "Buenas tardes")
          default:      return t("Dobrý večer", "Good evening", "Buenas noches")
          }
      }
      var welcomeLastSession: String {
          t("Poslední sezení", "Last session", "Última sesión")
      }
      var welcomeNoSession: String {
          t("Zatím žádné sezení", "No sessions yet", "Sin sesiones aún")
      }
      var tapToContinue: String {
          t("Klepnutím pokračujete", "Tap to continue", "Toca para continuar")
      }

      // MARK: Errors
      func errorFor(_ error: ParseError) -> String {
          switch error {
          case .emptyFile:
              return t("Soubor je prázdný.", "File is empty.", "El archivo está
  vacío.")
          case .noValidPairs:
              return t(
                  "Žádné platné páry nenalezeny. Používej formát: slovo - překlad",
                  "No valid pairs found. Use the format: word - translation",
                  "No se encontraron pares válidos. Usa el formato: palabra -
  traducción"
              )
          case .invalidEncoding:
              return t(
                  "Nelze přečíst soubor — zkuste uložit jako UTF-8.",
                  "Cannot read file — try saving as UTF-8.",
                  "No se puede leer el archivo — guárdalo como UTF-8."
              )
          case .fileTooLarge:
              return t(
                  "Soubor je příliš velký (max 5 MB).",
                  "File exceeds the 5 MB limit.",
                  "El archivo supera el límite de 5 MB."
              )
          }
      }
  }
