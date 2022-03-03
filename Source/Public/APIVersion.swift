//
//  APIVersion.swift
//  WireTransport-ios
//
//  Created by Sun Bin Kim on 03.03.22.
//  Copyright © 2022 Wire. All rights reserved.
//

import Foundation

/// Represents the backend API versions supported by the client.
///
/// Remove versions to drop support, add versions to add support.
/// Any changes made here are considered breaking and the compiler
/// can then be used to ensure that changes can be accounted for.

@objc
public enum APIVersion: Int32, CaseIterable {
    case v0 = 0
}
