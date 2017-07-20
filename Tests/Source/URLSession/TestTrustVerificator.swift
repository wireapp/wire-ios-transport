//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import WireTransport

@objc public class TestTrustVerificator: NSObject, URLSessionDelegate {

    private var session: URLSession!
    private let callback: (Bool) -> Void

    public init(callback: @escaping (Bool) -> Void) {
        self.callback = callback
        super.init()
        session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let protectionSpace = challenge.protectionSpace
        guard protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else { return callback(false) }
        let trusted = verifyServerTrust(protectionSpace.serverTrust, protectionSpace.host)
        callback(trusted)
    }

    @objc(verifyURL:) public func verify(url: URL) {
        session.dataTask(with: url).resume()
    }

}
