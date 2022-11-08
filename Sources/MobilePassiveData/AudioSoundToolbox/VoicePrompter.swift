//
//  VoicePrompter.swift
//

import Foundation

#if canImport(AVFoundation)
import AVFoundation
#endif

#if canImport(UIKit)
import UIKit
#endif

/// A completion handler for the voice box.
public typealias VoicePrompterCompletionHandler = (_ text: String, _ finished: Bool) -> Void

/// `VoicePrompter` is used to "speak" text strings.
public protocol VoicePrompter {
    
    /// Is the voice box currently speaking?
    var isSpeaking: Bool { get }
    
    /// Command the voice box to speak the given text.
    /// - parameters:
    ///     - text: The text to speak.
    ///     - completion: The completion handler to call after the text has finished.
    func speak(text: String, completion: VoicePrompterCompletionHandler?)
    
    /// Command the voice box to stop speaking.
    func stopTalking()
}

#if canImport(AVFoundation)

/// `TextToSpeechSynthesizer` is a concrete implementation of the `VoicePrompter` protocol that
/// uses the `AVSpeechSynthesizer` to synthesize text to sound.
public final class TextToSpeechSynthesizer : NSObject, VoicePrompter {
    
    /// The text-to-speech synthesizer needs to be a singleton to allow crossing UI transition boundaries.
    public static let shared = TextToSpeechSynthesizer()
    
    /// The language code to use for the speech voice.
    public let languageCode: String
    
    /// A specific identifier for the `AVSpeechSynthesisVoice` to use.
    public let voiceIdentifier: String?
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    private var _completionHandlers: [String: VoicePrompterCompletionHandler] = [:]
    
    public init(languageCode: String = AVSpeechSynthesisVoice.currentLanguageCode(),
                voiceIdentifier: String? = nil) {
        self.languageCode = languageCode
        self.voiceIdentifier = voiceIdentifier ?? (
            // syoung 02/05/2021 in iOS 14.4, the enhanced voice which is default for the US is broken
            // so this is a work-around for that bug.
            (languageCode == "en-US") ? "com.apple.ttsbundle.siri_female_en-US_compact" : nil
        )
        super.init()
        self.speechSynthesizer.delegate = self
    }
    
    deinit {
        speechSynthesizer.stopSpeaking(at: .immediate)
        speechSynthesizer.delegate = nil
    }
    
    /// Is the voice box currently speaking? The default implementation will return `true` if the
    /// `AVSpeechSynthesizer` is speaking.
    public var isSpeaking: Bool {
        return speechSynthesizer.isSpeaking
    }

    /// Command the voice box to speak the given text. The default implementation will create an
    /// `AVSpeechUtterance` and call the speech synthesizer with the utterance.
    ///
    /// - parameters:
    ///     - text: The text to speak.
    ///     - completion: The completion handler to call after the text has finished.
    public func speak(text: String, completion: VoicePrompterCompletionHandler?) {
        if speechSynthesizer.isSpeaking {
            stopTalking()
        }
        
        #if canImport(UIKit) && !os(watchOS)
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: text)
        }
        #endif
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
    
        if let voiceId = self.voiceIdentifier, let voice = AVSpeechSynthesisVoice(identifier: voiceId) {
            utterance.voice = voice
        }
        else {
            utterance.voice = AVSpeechSynthesisVoice(language: self.languageCode)
        }
        
        _completionHandlers[text] = completion
        
        speechSynthesizer.speak(utterance)
    }

    /// Command the voice box to stop speaking.
    public func stopTalking() {
        speechSynthesizer.stopSpeaking(at: .word)
    }
}

extension TextToSpeechSynthesizer : AVSpeechSynthesizerDelegate {
    
    /// Called when the text is synthesizer is finished.
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        guard let handler = _completionHandlers[utterance.speechString] else { return }
        _completionHandlers[utterance.speechString] = nil
        handler(utterance.speechString, true)
    }
    
    /// Called when the text is synthesizer is cancelled.
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        guard let handler = _completionHandlers[utterance.speechString] else { return }
        _completionHandlers[utterance.speechString] = nil
        handler(utterance.speechString, false)
    }
}

#else

// TODO: syoung 12/18/2020 Support Text-to-Voice for platforms that do not support AVFoundation.
public final class TextToSpeechSynthesizer : NSObject, VoicePrompter {
    var isSpeaking: Bool { false }
    func speak(text: String, completion: VoiceBoxCompletionHandler?) {
        print("WARNING! VoiceBox is not supported on this platform.")
        completion?(text, false)
    }
    func stopTalking() {}
}

#endif


