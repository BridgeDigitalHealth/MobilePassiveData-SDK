//
//  AudioRecorderConfiguration.swift
//  
//

import Foundation

public protocol AudioRecorderConfiguration : RecorderConfiguration {
    /// Should the audio recording be saved? Default = `false`.
    ///
    /// If `true` then the audio file used to measure meter levels is saved with the results.
    /// Otherwise, the audio file recorded is assumed to be a temporary file and should be deleted
    /// when the recording stops.
    var saveAudioFile: Bool? { get }
}
