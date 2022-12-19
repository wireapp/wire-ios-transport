//
//  RequestLogTests.swift
//  WireTransport-ios-tests
//
//  Created by F on 16/12/2022.
//  Copyright © 2022 Wire. All rights reserved.
//

import Foundation
import XCTest
@testable import WireTransport

class RequestLogTests: XCTestCase {

    func testParsingEndpoint() throws {
        let request = NSURLRequest(url: URL(string: "https://prod-nginz-https.wire.com/v2/access")!)
        let sut: RequestLog = .init(request)
        XCTAssertEqual(sut.endpoint, "prod-nginz-https.wire.com/v2/acc***")
        XCTAssertEqual(sut.method, "GET")
    }

    func testParsingEndpointWithQueryParams() throws {
        let request = NSURLRequest(url: URL(string: "https://prod-nginz-https.wire.com/v2/notifications?size=500&since=05b4637f-7c5a-11ed-8001-aafb9b836561&client=e00079bf207cf4e6")!)
        let sut: RequestLog = .init(request)
        XCTAssertEqual(sut.endpoint, "prod-nginz-https.wire.com/v2/not***?size=***&since=05b***&client=e00***")
    }

    func testAuthorizationHeaderValueIsRedacted() throws {
        let request = NSMutableURLRequest(url: URL(string: "https://prod-nginz-https.wire.com/push/tokens")!)
        request.addValue("Bearer wertrtetetr42343242432456789p", forHTTPHeaderField: "Authorization")
        let sut: RequestLog = .init(request)
        XCTAssertEqual(sut.headers["Authorization"], "*******")
    }

}

