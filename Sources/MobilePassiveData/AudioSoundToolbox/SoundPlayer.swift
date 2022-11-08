//
//  SoundPlayer.swift
//

import Foundation

#if canImport(AudioToolbox)
import AudioToolbox
#endif

/// `SoundFile` contains sound file URLs.
public struct SoundFile {
    
    /// The name of the sound.
    public let name: String
    
    /// The url for the sound (if any).
    public let url: URL?
    
    /// Initializer for initializing system library UISounds.
    /// - parameter name: The name of the sound. This is also the name of the .caf file for that sound in the library.
    public init(name: String) {
        self.name = name
        self.url = URL(string: "/System/Library/Audio/UISounds/\(name).caf")
    }
    
    /// Initializer for creating a sound with a custom URL.
    /// - parameter url: The url with the path to the sound file.
    public init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
    }
    
    /// The alarm sound.
    public static let alarm = SoundFile(name: "alarm")
    
    /// A short low-high beep sound.
    public static let short_low_high = SoundFile(name: "short_low_high")
    
    /// A short double-high beep sound.
    public static let short_double_high = SoundFile(name: "short_double_high")
    
    /// A short double-low beep sound.
    public static let short_double_low = SoundFile(name: "short_double_low")
    
    /// The "photo shutter" sound played when taking a picture.
    public static let photoShutter = SoundFile(name: "photoShutter")
    
    /// A key tap sound.
    public static let tock = SoundFile(name: "Tock")
    
    /// A key tap sound.
    public static let tink = SoundFile(name: "Tink")
    
    /// The lock screen sound.
    public static let lock = SoundFile(name: "lock")
}

/// `SoundPlayer` is a protocol for playing sounds intended to give the user UI feedback during
/// the running of a task.
public protocol SoundPlayer {
    
    /// Play the given sound.
    /// - parameter sound: The system sound to play.
    func playSound(_ sound: SoundFile)
}

/// `AudioFileSoundPlayer` is a concrete implementation of the `SoundPlayer` protocol that can be used
/// to play system sounds using `AudioServicesCreateSystemSoundID()`.
public final class AudioFileSoundPlayer : NSObject, SoundPlayer {

    /// Play the given sound.
    /// - parameter sound: The system sound to play.
    public func playSound(_ sound: SoundFile) {
        #if !canImport(AudioToolbox)
            // Playing sounds is not supported
            print("WARNING! AudioToolbox is not supported on this platform.")
        #else
            guard let url = sound.url else { return }
            var soundId: SystemSoundID = 0
            let status = AudioServicesCreateSystemSoundID(url as CFURL, &soundId)
            guard status == kAudioServicesNoError else {
                print("Failed to create the ping sound for \(url)")
                return
            }
            AudioServicesAddSystemSoundCompletion(soundId, nil, nil, { (soundId, clientData) -> Void in
                AudioServicesDisposeSystemSoundID(soundId)
            }, nil)
            AudioServicesPlaySystemSound(soundId)
        #endif
    }
    
    public func vibrateDevice() {
    #if !canImport(AudioToolbox)
        // Playing sounds is not supported
        print("WARNING! AudioToolbox is not supported on this platform.")
    #else
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    #endif
    }
}


