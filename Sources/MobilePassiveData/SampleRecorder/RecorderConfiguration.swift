//
//  RecorderConfiguration.swift
//  
//

import Foundation

/// `RecorderConfiguration` is used to configure a recorder. For example, recording accelerometer
/// data or video.
public protocol RecorderConfiguration : AsyncActionConfiguration {
    
    /// An identifier marking the step at which to stop the action. If `nil`, then the action will be
    /// stopped when the task is stopped.
    var stopStepIdentifier: String? { get }
    
    /// Whether or not the recorder requires background audio. 
    ///
    /// If `true` then background audio can be used to keep the recorder running if the screen is locked
    /// because of the idle timer turning off the device screen.
    ///
    /// If the app uses background audio, then the developer will need to turn `ON` the "Background Modes"
    /// under the "Capabilities" tab of the Xcode project, and will need to select "Audio, AirPlay, and
    /// Picture in Picture".
    var requiresBackgroundAudio: Bool { get }
}

/// Extends `RecorderConfiguration` for a recorder that might be restarted.
public protocol RestartableRecorderConfiguration : RecorderConfiguration {
    
    /// Should the file used in a previous run of a recording be deleted?
    var shouldDeletePrevious: Bool { get }
}

/// `JsonRecorderConfiguration` is used to configure a recorder to record JSON samples.
/// - seealso: `SampleRecorder`
public protocol JsonRecorderConfiguration : RecorderConfiguration {
    
    /// Should the logger use a dictionary as the root element?
    ///
    /// If `true` then the logger will open the file with the samples included in an array with the key
    /// of "items". If `false` then the file will use an array as the root elemenent and the samples will
    /// be added to that array. Default = `false`
    ///
    /// - example:
    ///
    /// If the log file uses a dictionary as the root element then
    /// ```
    ///    {
    ///    "startDate" : "2017-10-16T22:28:09.000-07:00",
    ///    "items"     : [
    ///                     {
    ///                     "uptime": 1234.56,
    ///                     "stepPath": "/Foo Task/sectionA/step1",
    ///                     "timestampDate": "2017-10-16T22:28:09.000-07:00",
    ///                     "timestamp": 0
    ///                     },
    ///                     // ... more samples ... //
    ///                 ]
    ///     }
    /// ```
    ///
    /// If the log file uses an array as the root element then
    /// ```
    ///    [
    ///     {
    ///     "uptime": 1234.56,
    ///     "stepPath": "/Foo Task/sectionA/step1",
    ///     "timestampDate": "2017-10-16T22:28:09.000-07:00",
    ///     "timestamp": 0
    ///     },
    ///     // ... more samples ... //
    ///     ]
    /// ```
    ///
    var usesRootDictionary: Bool { get }
}
