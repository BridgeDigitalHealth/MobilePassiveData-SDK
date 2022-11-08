//
//  DistanceRecorderConfiguration+Vendor.swift
//  
//

#if os(iOS)

import Foundation
import MobilePassiveData

extension DistanceRecorderConfigurationObject : AsyncActionVendor {
    public func instantiateController(outputDirectory: URL, initialStepPath: String?, sectionIdentifier: String?) -> AsyncActionController? {
        DistanceRecorder(configuration: self,
                         outputDirectory: outputDirectory,
                         initialStepPath: initialStepPath,
                         sectionIdentifier: sectionIdentifier)
    }
}

// TODO: syoung 01/14/2021 Create a Kotlin/Native model object and implement extensions.

#endif
