//
//  RemoteLogger.swift
//  WireTransport-ios
//
//  Created by F on 09/12/2022.
//  Copyright © 2022 Wire. All rights reserved.
//

import Foundation
import Combine


public protocol RemoteLogger {
    func log(message: String, error: Error?, attributes: [String: Encodable]?)
}

extension RemoteLogger {
    func log(message: String, error: Error?, attributes: [String: Encodable]?) {
        RemoteMonitoring.remoteLogger?.log(message: message, error: error, attributes: attributes)
    }
}

public class RemoteMonitoring: NSObject  {
    public static var remoteLogger: RemoteLogger?

    @objc func log(_ message: String, error: Error? = nil) {
        Self.remoteLogger?.log(message: message, error: nil, attributes: nil)
    }
}
