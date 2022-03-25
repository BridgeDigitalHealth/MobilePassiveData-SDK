// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MobilePassiveData",
    defaultLocalization: "en",
    platforms: [
        // Add support for all platforms starting from a specific version.
        .iOS(.v14),
        .macOS(.v11),
        .watchOS(.v7),
        .tvOS(.v14)
    ],
    products: [
        // MARK: Main Library
        .library(
            name: "MobilePassiveData",
            targets: ["MobilePassiveData"]),
        
        // MARK: Additional Libraries
        //
        // "Starting Spring 2019, all apps submitted to the App Store that access user data will
        //  be required to include a purpose string. If you're using external libraries or SDKs,
        //  they may reference APIs that require a purpose string. While your app might not use
        //  these APIs, a purpose string is still required. You can contact the developer of the
        //  library or SDK and request they release a version of their code that doesn't contain
        //  the APIs." - syoung 05/15/2019 Message from Apple's App Store Connect.
        //
        // As a consequence of this, any framework that relies upon motion sensors, GPS,
        // microphone, or camera must be embedded separately from the shared code that supports
        // using these sensors. Therefore, the `MobilePassiveData` target is included separately
        // from the libraries in this repo that rely upon these sensors.
        
        .library(
            name: "MotionSensor",
            targets: ["MotionSensor"]),
        .library(
            name: "AudioRecorder",
            targets: ["AudioRecorder"]),
        .library(
            name: "LocationAuthorization",
            targets: ["LocationAuthorization"]),
        .library(
            name: "WeatherRecorder",
            targets: ["WeatherRecorder"]),
        .library(
            name: "DistanceRecorder",
            targets: ["DistanceRecorder"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(name: "AssessmentModel",
                 url: "https://github.com/Sage-Bionetworks/AssessmentModelKMM.git",
                 from: "0.5.5"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        
        /// Main library.
        .target(name: "MobilePassiveData",
                dependencies: [
                    "ExceptionHandler",
                    .product(name: "AssessmentModel", package: "AssessmentModel"),
                ],
                resources: [
                    .process("Resources")
                ]),
        .testTarget(
            name: "MobilePassiveDataTests",
            dependencies: [
                "MobilePassiveData",
                "NSLocaleSwizzle",
                "SharedResourcesTests",
            ]),
        
        // Changes exceptions into errors so that the app doesn't crash. This is pulled into a
        // separate module b/c packages can have either Swift or Obj-c.
        .target(name: "ExceptionHandler",
                dependencies: []),
        
        // Supports recording audio using the microphone with a standardized permission and
        // recording structure. This library implements the recorder associated with the
        // `AudioRecorderConfiguration` defined in the base library for this package.
        //
        // Use of this library requires registering the `AudioRecorderAuthorization` adapter and
        // adding any privacy keys for using the microphone to the app `Info.Plist`.
        .target(name: "AudioRecorder",
                dependencies: [
                    "MobilePassiveData",
                ]),
        .testTarget(
            name: "AudioRecorderTests",
            dependencies: [
                "AudioRecorder",
                "SharedResourcesTests",
            ]),
        
        // Supports the use of `CoreMotion` with a standardized permission and recording structure.
        // This library implements the recorder associated with the `MotionRecorderConfiguration`
        // defined in the base library for this package.
        //
        // Use of this library requires registering the `MotionAuthorization` adapter and adding
        // any privacy keys for using motion sensors to the app `Info.Plist`.
        .target(name: "MotionSensor",
                dependencies: [
                    "MobilePassiveData",
                ]),
        .testTarget(
            name: "MotionSensorTests",
            dependencies: [
                "MotionSensor",
                "SharedResourcesTests",
            ]),
        
        // Location authorization adaptor for `CoreLocation`. This adaptor can be used for setting
        // up UI for requesting permissions prior to using them in background recorders.
        //
        // Use of this library requires registering the `LocationAuthorization` adapter and adding
        // appropriate privacy keys for using GPS to the app `Info.Plist`.
        .target(name: "LocationAuthorization",
                dependencies: [
                    "MobilePassiveData",
                ]),
        
        // This target pings the user's location and then uses that to query weather services for
        // current conditions.
        //
        // Use of this library requires adding appropriate privacy keys for using GPS to the
        // app `Info.Plist`.
        .target(name: "WeatherRecorder",
                dependencies: [
                    "MobilePassiveData",
                    "LocationAuthorization",
                ]),
        .testTarget(
            name: "WeatherRecorderTests",
            dependencies: [
                "WeatherRecorder",
                "SharedResourcesTests",
            ]),
        
        // Recorder for using `CoreLocation` and `CoreMotion` to record distances travelled.
        //
        // Use of this library requires adding appropriate privacy keys for using GPS and
        // motion sensors to the app `Info.Plist`.
        .target(name: "DistanceRecorder",
                dependencies: [
                    "MobilePassiveData",
                    "MotionSensor",
                    "LocationAuthorization",
                ]),
        
        // Unit test utilities.
        .target(name: "NSLocaleSwizzle",
                dependencies: [
                ]),
        .target(name: "SharedResourcesTests",
                path: "shared_resources/tests/",
                resources: [
                    .process("Json"),
                ]),
    ]
)

