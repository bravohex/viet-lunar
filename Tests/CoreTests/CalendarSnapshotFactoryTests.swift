import Foundation
import XCTest
@testable import VietLunarCore

final class CalendarSnapshotFactoryTests: XCTestCase {
    func testSnapshotBeforeVietnamMidnightUsesOneCoherentInstant() throws {
        let instant = try isoInstant("2004-04-19T16:59:59Z")
        let factory = CalendarSnapshotFactory(
            lunarEngine: LunarCalendarEngine(),
            clock: FixedClock(instant: instant)
        )

        let snapshot = try factory.makeSnapshot()

        XCTAssertEqual(snapshot.instant, instant)
        XCTAssertEqual(
            snapshot.solarDate,
            try SolarDate(validatingYear: 2004, month: 4, day: 19)
        )
        XCTAssertEqual(
            snapshot.lunarDate,
            try LunarDate(
                validatingYear: 2004,
                month: 3,
                day: 1,
                isLeapMonth: false
            )
        )
        XCTAssertEqual(snapshot.yearCanChi.description, "Giáp Thân")
        XCTAssertEqual(snapshot.monthCanChi.description, "Mậu Thìn")
        XCTAssertEqual(snapshot.dayCanChi.description, "Mậu Thìn")
        XCTAssertEqual(snapshot.hourCanChi.description, "Nhâm Tý")
    }

    func testSnapshotAtVietnamMidnightAdvancesAllDateDerivedValues() throws {
        let instant = try isoInstant("2004-04-19T17:00:00Z")
        let factory = CalendarSnapshotFactory(
            lunarEngine: LunarCalendarEngine(),
            clock: FixedClock(instant: instant)
        )

        let snapshot = try factory.makeSnapshot()

        XCTAssertEqual(
            snapshot.solarDate,
            try SolarDate(validatingYear: 2004, month: 4, day: 20)
        )
        XCTAssertEqual(snapshot.lunarDate.day, 2)
        XCTAssertEqual(snapshot.dayCanChi.description, "Kỷ Tỵ")
        XCTAssertEqual(snapshot.hourCanChi.description, "Giáp Tý")
    }

    func testSnapshotReadsClockExactlyOnce() throws {
        let firstInstant = try isoInstant("2004-04-19T16:59:59Z")
        let laterInstant = try isoInstant("2004-04-19T17:00:00Z")
        let clock = CountingClock(instants: [firstInstant, laterInstant])
        let factory = CalendarSnapshotFactory(
            lunarEngine: LunarCalendarEngine(),
            clock: clock
        )

        let snapshot = try factory.makeSnapshot()

        XCTAssertEqual(clock.readCount, 1)
        XCTAssertEqual(snapshot.instant, firstInstant)
        XCTAssertEqual(snapshot.solarDate.day, 19)
    }

    func testSnapshotHonorsStartOfZiHourPolicy() throws {
        let instant = try isoInstant("2004-04-19T16:00:00Z") // 23:00 UTC+7
        let factory = CalendarSnapshotFactory(
            lunarEngine: LunarCalendarEngine(),
            clock: FixedClock(instant: instant),
            boundaryPolicy: .startOfZiHour
        )

        let snapshot = try factory.makeSnapshot()

        XCTAssertEqual(snapshot.solarDate.day, 19)
        XCTAssertEqual(snapshot.lunarDate.day, 1)
        XCTAssertEqual(snapshot.dayCanChi.description, "Kỷ Tỵ")
        XCTAssertEqual(snapshot.hourCanChi.description, "Giáp Tý")
    }

    private func isoInstant(_ value: String) throws -> Date {
        try XCTUnwrap(ISO8601DateFormatter().date(from: value))
    }
}

private final class CountingClock: Clock, @unchecked Sendable {
    private let lock = NSLock()
    private let instants: [Date]
    private var index = 0

    init(instants: [Date]) {
        precondition(!instants.isEmpty)
        self.instants = instants
    }

    var readCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return index
    }

    func now() -> Date {
        lock.lock()
        defer { lock.unlock() }

        let instant = instants[min(index, instants.count - 1)]
        index += 1
        return instant
    }
}
