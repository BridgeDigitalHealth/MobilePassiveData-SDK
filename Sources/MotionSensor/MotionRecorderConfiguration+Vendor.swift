//
//  MotionRecorderConfiguration+Vendor.swift
//  
//

#if os(iOS)

import Foundation
import MobilePassiveData

extension MotionRecorderConfigurationObject : AsyncActionVendor {
    public func instantiateController(outputDirectory: URL, initialStepPath: String?, sectionIdentifier: String?) -> AsyncActionController? {
        MotionRecorder(configuration: self,
                       outputDirectory: outputDirectory,
                       initialStepPath: initialStepPath,
                       sectionIdentifier: sectionIdentifier)
    }
}

// TODO: syoung 01/14/2021 Create a Kotlin/Native model object and implement extensions.

#endif
