import AVFoundation
import NaturalLanguage

final class AudioPlayer {
    static let shared = AudioPlayer()
    private let synth = AVSpeechSynthesizer()

    func speak(_ text: String) {
        synth.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.88
        utterance.voice = AVSpeechSynthesisVoice(language: detectLanguage(text))
        synth.speak(utterance)
    }

    private func detectLanguage(_ text: String) -> String {
        let rec = NLLanguageRecognizer()
        rec.processString(text)
        switch rec.dominantLanguage {
        case .czech:              return "cs-CZ"
        case .spanish:            return "es-ES"
        case .french:             return "fr-FR"
        case .german:             return "de-DE"
        case .simplifiedChinese:  return "zh-CN"
        case .traditionalChinese: return "zh-TW"
        default:                  return "en-US"
        }
    }
}
