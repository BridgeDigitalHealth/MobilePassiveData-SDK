// Created 2/4/23
// swift-tools-version:5.0

import XCTest
@testable import MobilePassiveData

class SampleRecorderTests: XCTestCase {
    
    @MainActor func testMarkerPath() {
        
        let markers = Markers()
        
        markers.append(1, "1")
        markers.append(2, "2")
        markers.append(3, "3")
        markers.append(4, "4")
        markers.append(5, "5")
        markers.append(6, "6")
        
        let path3 = markers.stepPath(uptime: 3.2)
        XCTAssertEqual(path3, "3")

        let path6 = markers.stepPath(uptime: 6.2)
        XCTAssertEqual(path6, "6")

        let path0 = markers.stepPath(uptime: 0.2)
        XCTAssertNil(path0)
    }
}
