//
//  MotionRecorderConfiguration.swift
//  
//
//  Copyright © 2021-2022 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import Foundation
import JsonModel
import AssessmentModel

/// Additional configuration parameters required by the `MotionRecorder` defined in the
/// `MotionSensor` library.
public protocol MotionRecorderConfiguration : RestartableRecorderConfiguration {
    
    /// The `CoreMotion` device sensor types to include with this configuration. If `nil` then the
    /// `MotionRecorder` defaults will be used.
    var recorderTypes: Set<MotionRecorderType>? { get }
    
    /// The sampling frequency of the motion sensors. If `nil`, then `MotionRecorder` default
    /// frequency will be used.
    var frequency: Double? { get }
    
    /// Set the flag to `true` to encode the samples as a CSV file.
    var usesCSVEncoding : Bool?  { get }
}

extension MotionRecorderConfiguration {
    /// This recorder configuration requires `StandardPermissionType.motion`.
    /// - note: The use of this recorder requires adding “Privacy - Motion Usage Description” to the
    ///         application "info.plist" file.
    public var permissionTypes: [PermissionType] {
        #if os(iOS)
        return [.motion]
        #else
        return []
        #endif
    }
}

/// `MotionRecorderType` is used to enumerate the sensors and calculated measurements
/// that can be recorded by the `MotionRecorder`.
///
/// `MotionRecorder` records each sample from either the raw CoreMotion sensors
/// (accelerometer, gyro, and magnetometer) or the calculated vectors returned when requesting
/// `CMDeviceMotion` data updates. The `CMDeviceMotion` data is split into the components
/// enumerated by this enum into a single vector (sensor or calculated) per type.
///
/// By default, the requested types are are saved to a single logging file as instances of
/// `MotionRecord` structs.
///
/// Spliting the device motion into components in this manner stores the data in using a
/// consistent JSON schema that can represent the sensor data returned by both iOS and Android
/// devices. Thus, allowing research studies to target a broader audience. Additionally, this
/// schema allows for a single table to be used to store the data which can then be filtered
/// by type to perform calculations and DSP on the input sources.
///
public enum MotionRecorderType : String, Codable, StringEnumSet {
    
    /// Raw accelerometer reading. `CMAccelerometerData` accelerometer.
    /// - seealso: https://developer.apple.com/documentation/coremotion/getting_raw_accelerometer_events
    case accelerometer
    
    /// Raw gyroscope reading. `CMGyroData` rotationRate.
    /// - seealso: https://developer.apple.com/documentation/coremotion/getting_raw_gyroscope_events
    case gyro
    
    /// Raw magnetometer reading. `CMMagnetometerData` magneticField.
    /// - seealso: https://developer.apple.com/documentation/coremotion/cmmagnetometerdata
    case magnetometer
    
    /// Calculated orientation of the device using the gyro and magnetometer (if appropriate).
    ///
    /// This is included in the `CMDeviceMotion` data object.
    ///
    /// - note: If the `magneticField` is included in the configuration's list of desired
    /// recorder types then the reference frame is `.xMagneticNorthZVertical`. Otherwise,
    /// the motion recorder will use `.xArbitraryZVertical`.
    ///
    /// - seealso: https://developer.apple.com/documentation/coremotion/getting_processed_device_motion_data
    case attitude
    
    /// Calculated vector for the direction of gravity in the coordinates of the device.
    ///
    /// This is included in the `CMDeviceMotion` data object.
    ///
    /// - seealso: https://developer.apple.com/documentation/coremotion/getting_processed_device_motion_data
    case gravity
    
    /// The magnetic field vector with respect to the device for devices with a magnetometer.
    /// Note that this is the total magnetic field in the device's vicinity without device
    /// bias (Earth's magnetic field plus surrounding fields, without device bias),
    /// unlike `CMMagnetometerData` magneticField.
    ///
    /// This is included in the `CMDeviceMotion` data object.
    ///
    /// - note: If this recorder type is included in the configuration, then the attitude
    /// reference frame will be set to `.xMagneticNorthZVertical`. Otherwise, the magnetic
    /// field vector will be returned as `{ 0, 0, 0 }`.
    ///
    /// - seealso: https://developer.apple.com/documentation/coremotion/getting_processed_device_motion_data
    case magneticField
    
    /// The rotation rate of the device for devices with a gyro.
    ///
    /// This is included in the `CMDeviceMotion` data object.
    ///
    /// - seealso: https://developer.apple.com/documentation/coremotion/getting_processed_device_motion_data
    case rotationRate
    
    /// Calculated vector for the participant's acceleration in the coordinates of the device.
    /// This is the acceleration component after subtracting the gravity vector.
    ///
    /// This is included in the `CMDeviceMotion` data object.
    ///
    /// - seealso: https://developer.apple.com/documentation/coremotion/getting_processed_device_motion_data
    case userAcceleration
    
    /// A list of all the enum values.
    public static var all: Set<MotionRecorderType> {
        return [.accelerometer, .attitude, .gravity, .gyro, .magneticField, .magnetometer, .rotationRate, .userAcceleration]
    }
    
    /// List of the device motion types that are calculated from multiple sensors and returned
    /// by listening to device motion updates.
    ///
    /// - seealso: https://developer.apple.com/documentation/coremotion/getting_processed_device_motion_data
    public static var deviceMotionTypes: Set<MotionRecorderType> {
        return [.attitude, .gravity, .magneticField, .rotationRate, .userAcceleration]
    }
    
    /// List of the raw motion sensor types.
    public static var rawSensorTypes: Set<MotionRecorderType> {
        return [.accelerometer, .gyro, .magnetometer]
    }
}

extension MotionRecorderType : DocumentableStringEnum {
}
