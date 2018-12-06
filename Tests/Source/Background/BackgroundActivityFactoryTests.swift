//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import UIKit
import XCTest
import WireTesting
@testable import WireTransport

class BackgroundActivityFactoryTests: XCTestCase {

    var factory: BackgroundActivityFactory!
    var activityManager: MockBackgroundActivityManager!

    override func setUp() {
        super.setUp()
        activityManager = MockBackgroundActivityManager()
        factory = BackgroundActivityFactory.shared
        factory.activityManager = activityManager
        factory.mainQueue = .global()
    }

    override func tearDown() {
        activityManager.reset()
        factory.reset()
        activityManager = nil
        factory = nil
        super.tearDown()
    }

    func testThatItCreatesActivity() {
        // WHEN
        let activity = factory.startBackgroundActivity(withName: "Activity 1")

        // THEN
        XCTAssertNotNil(activity)
        XCTAssertEqual(activity?.name, "Activity 1")
        XCTAssertTrue(factory.isActive)
        XCTAssertEqual(activityManager.numberOfTasks, 1)
    }

    func testThatItCreatesOnlyOneSystemTaskWithMultipleActivities() {
        // WHEN
        _ = factory.startBackgroundActivity(withName: "Activity 1")
        _ = factory.startBackgroundActivity(withName: "Activity 2")

        // THEN
        XCTAssertTrue(factory.isActive)
        XCTAssertEqual(activityManager.numberOfTasks, 1)
        XCTAssertEqual(factory.activities.count, 2)
    }

    func testThatItDoesNotCreateActivityIfTheAppIsBeingSuspended() {
        // GIVEN
        activityManager.triggerExpiration()

        // WHEN
        let activity = factory.startBackgroundActivity(withName: "Activity 1")

        // THEN
        XCTAssertNil(activity)
        XCTAssertNil(factory.currentBackgroundTask)
    }

    func testThatItRemovesTaskWhenItEnds() {
        // GIVEN
        let activity = factory.startBackgroundActivity(withName: "Activity 1")!

        // WHEN
        factory.endBackgroundActivity(activity)

        // THEN
        XCTAssertFalse(factory.isActive)
        XCTAssertTrue(factory.activities.isEmpty)
        XCTAssertEqual(activityManager.numberOfTasks, 0)
    }

    func testThatItDoesNotRemoveTaskWhenItEndsIfThereAreMoreTasks() {
        // GIVEN
        let activity1 = factory.startBackgroundActivity(withName: "Activity 1")!
        let activity2 = factory.startBackgroundActivity(withName: "Activity 2")!

        // WHEN
        factory.endBackgroundActivity(activity1)

        // THEN
        XCTAssertTrue(factory.isActive)
        XCTAssertEqual(factory.activities, [activity2])
        XCTAssertEqual(activityManager.numberOfTasks, 1)
    }

    func testThatItCallsExpirationHandlerOnCreatedActivities() {
        // GIVEN
        let expirationExpectation = expectation(description: "The expiration handler is called.")

        let activity = factory.startBackgroundActivity(withName: "Activity 1") {
            expirationExpectation.fulfill()
        }

        // WHEN
        XCTAssertNotNil(activity)
        activityManager.triggerExpiration()

        // THEN
        waitForExpectations(timeout: 0.5, handler: nil)
        XCTAssertFalse(factory.isActive)
        XCTAssertTrue(factory.activities.isEmpty)
        XCTAssertEqual(activityManager.numberOfTasks, 0)
    }    
}

// MARK: - Helpers

extension BackgroundActivityFactory {

    @objc func reset() {
        currentBackgroundTask = nil
        activities.removeAll()
        activityManager = nil
        mainQueue = .main
    }

}
