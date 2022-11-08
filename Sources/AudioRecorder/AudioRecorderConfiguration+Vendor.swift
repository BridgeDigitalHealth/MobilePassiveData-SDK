//
//  AudioRecorderConfiguration+Vendor.swift
//  
//

#if !os(tvOS)

import Foundation
import MobilePassiveData

extension AudioRecorderConfigurationObject : AsyncActionVendor {
    public func instantiateController(outputDirectory: URL, initialStepPath: String?, sectionIdentifier: String?) -> AsyncActionController? {
        AudioRecorder(configuration: self,
                       outputDirectory: outputDirectory,
                       initialStepPath: initialStepPath,
                       sectionIdentifier: sectionIdentifier)
    }
}

// TODO: syoung 01/14/2021 Create a Kotlin/Native model object and implement extensions.

#endif
