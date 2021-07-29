//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

import Foundation
import XCTest
import WireTesting
@testable import WireTransport

final class ZMTaskIdentifierTests: ZMTBaseTest {
    func testThatItCanBeSerializedAndDeserializedFromAndToNSData() {
        // given
        let sut = ZMTaskIdentifier(identifier: 46, sessionIdentifier: "foreground-session")
        XCTAssertNotNil(sut)

        // when

        let data = NSKeyedArchiver.archivedData(withRootObject: sut)
        XCTAssertNotNil(data)

        // then
        let deserializedSut = NSKeyedUnarchiver.unarchiveObject(with: data) as? ZMTaskIdentifier
        XCTAssertNotNil(deserializedSut)
        XCTAssertEqual(deserializedSut, sut)
    }

    func testThatItCanBeInitializedFromDataAndReturnsTheCorrectData() {
        // given
        let sut = ZMTaskIdentifier(identifier: 42, sessionIdentifier: "foreground-session")
        XCTAssertNotNil(sut)

        // when
        let data = sut?.data
        XCTAssertNotNil(data)

        // then
        let deserializedSut = ZMTaskIdentifier.identifier(from: data)
        XCTAssertNotNil(deserializedSut)
        XCTAssertEqual(deserializedSut, sut)
    }
}
