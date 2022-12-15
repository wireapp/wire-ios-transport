//
//  RemoteLogger.swift
//  WireTransport-ios
//
//  Created by F on 09/12/2022.
//  Copyright © 2022 Wire. All rights reserved.
//

import Foundation

public protocol RemoteLogger {
    func log(message: String, error: Error?, attributes: [String: Encodable]?, level: RemoteMonitoring.Level)
}

extension RemoteLogger {
    func log(message: String, error: Error? = nil, attributes: [String: Encodable]? = nil, level: RemoteMonitoring.Level = .debug) {
        RemoteMonitoring.remoteLogger?.log(message: message, error: error, attributes: attributes, level: level)
    }
}

public class RemoteMonitoring: NSObject  {
    @objc public enum Level : Int {
        case debug
        case info
        case notice
        case warn
        case error
        case critical
    }

    var level: Level

    @objc init(level: Level) {
        self.level = level
    }

    public static var remoteLogger: RemoteLogger?

    @objc func log(_ message: String, error: Error? = nil) {
        Self.remoteLogger?.log(message: message, error: nil, attributes: nil, level: level)
    }
}
