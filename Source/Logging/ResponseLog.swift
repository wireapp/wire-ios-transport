//
//  ResponseLog.swift
//  WireTransport-ios-tests
//
//  Created by F on 16/12/2022.
//  Copyright © 2022 Wire. All rights reserved.
//

import Foundation

struct ResponseLog: Codable {
    var endpoint: String?
    var status: Int

    init(_ response: HTTPURLResponse) {
        self.endpoint = response.url?.endpointRemoteLogDescription
        self.status = response.statusCode
    }
}
