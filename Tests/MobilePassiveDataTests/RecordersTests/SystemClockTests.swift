//
//  SystemClockTests.swift
//


import XCTest
@testable import MobilePassiveData

class SystemClockTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSleepOffset_BeforeSleep() async {
        let start: TimeInterval = -10 * 60
        let date = Date().addingTimeInterval(start)
        let clockTime = SystemClock.uptime()
        let systemTime = ProcessInfo.processInfo.systemUptime
        
        let clock = SystemClock(clock: clockTime, system: systemTime, date: date)
        
        let sleepOffset: TimeInterval = 5 * 60
        let wakeAt: TimeInterval = 8 * 60
        let wakeClock = clockTime + wakeAt
        let wakeSystem = systemTime + wakeAt - sleepOffset
        await clock.addTimeMarkers(wakeClock, wakeSystem)
        
        let offset: TimeInterval = 60
        let testTimeExpected = clockTime + offset
        let testTime = systemTime + offset
        let testTimeActual = await clock.relativeUptime(to: testTime)
        XCTAssertEqual(testTimeExpected, testTimeActual, accuracy:0.0001)
        
        let zeroTimeActual = await clock.zeroRelativeTime(to: testTime)
        let zeroTimeEspected = testTimeActual - clockTime
        XCTAssertEqual(zeroTimeEspected, zeroTimeActual, accuracy:0.0001)
    }
    
    func testSleepOffset_BeforeStart() async {
        let start: TimeInterval = -10 * 60
        let date = Date().addingTimeInterval(start)
        let clockTime = SystemClock.uptime()
        let systemTime = ProcessInfo.processInfo.systemUptime
        
        let clock = SystemClock(clock: clockTime, system: systemTime, date: date)
        
        let sleepOffset: TimeInterval = 5 * 60
        let wakeAt: TimeInterval = 8 * 60
        let wakeClock = clockTime + wakeAt
        let wakeSystem = systemTime + wakeAt - sleepOffset
        await clock.addTimeMarkers(wakeClock, wakeSystem)
        
        let offset: TimeInterval = -60
        let testTimeExpected = clockTime + offset
        let testTime = systemTime + offset
        let testTimeActual = await clock.relativeUptime(to: testTime)
        XCTAssertEqual(testTimeExpected, testTimeActual, accuracy:0.0001)
        
        let zeroTimeActual = await clock.zeroRelativeTime(to: testTime)
        let zeroTimeEspected = testTimeActual - clockTime
        XCTAssertEqual(zeroTimeEspected, zeroTimeActual, accuracy:0.0001)
    }
    
    func testSleepOffset_AfterSleep() async {
        
        let start: TimeInterval = -10 * 60
        let date = Date().addingTimeInterval(start)
        let clockTime = SystemClock.uptime()
        let systemTime = ProcessInfo.processInfo.systemUptime
        
        let clock = SystemClock(clock: clockTime, system: systemTime, date: date)
        
        let sleepOffset: TimeInterval = 5 * 60
        let wakeAt: TimeInterval = 8 * 60
        let wakeClock = clockTime + wakeAt
        let wakeSystem = systemTime + wakeAt - sleepOffset
        await clock.addTimeMarkers(wakeClock, wakeSystem)
        
        let offsetAfter: TimeInterval = 10 * 60
        let testTimeExpected = clockTime + offsetAfter
        let testTime = systemTime + offsetAfter - sleepOffset
        let testTimeActual = await clock.relativeUptime(to: testTime)
        XCTAssertEqual(testTimeExpected, testTimeActual, accuracy:0.0001)
        
        let zeroTimeActual = await clock.zeroRelativeTime(to: testTime)
        let zeroTimeEspected = testTimeActual - clockTime
        XCTAssertEqual(zeroTimeEspected, zeroTimeActual, accuracy:0.0001)
    }
    
    func testSleepOffset_AfterSleepX2() async {
        
        let start: TimeInterval = -10 * 60
        let date = Date().addingTimeInterval(start)
        let clockTime = SystemClock.uptime()
        let systemTime = ProcessInfo.processInfo.systemUptime
        
        let clock = SystemClock(clock: clockTime, system: systemTime, date: date)
        
        let sleepOffset1: TimeInterval = 5 * 60
        let wakeAt1: TimeInterval = 8 * 60
        let wakeClock1 = clockTime + wakeAt1
        let wakeSystem1 = systemTime + wakeAt1 - sleepOffset1
        await clock.addTimeMarkers(wakeClock1, wakeSystem1)
        
        let sleepOffset2: TimeInterval = 2 * 60
        let wakeAt2: TimeInterval = 3 * 60
        let wakeClock2 = wakeClock1 + wakeAt2
        let wakeSystem2 = wakeSystem1 + wakeAt2 - sleepOffset2
        await clock.addTimeMarkers(wakeClock2, wakeSystem2)
        
        let offsetAfter: TimeInterval = 10 * 60
        let testTimeExpected = wakeClock2 + offsetAfter
        let testTime = wakeSystem2 + offsetAfter
        let testTimeActual = await clock.relativeUptime(to: testTime)
        XCTAssertEqual(testTimeExpected, testTimeActual, accuracy:0.0001)
        
        let zeroTimeActual = await clock.zeroRelativeTime(to: testTime)
        let zeroTimeEspected = testTimeActual - clockTime
        XCTAssertEqual(zeroTimeEspected, zeroTimeActual, accuracy:0.0001)
    }
}
