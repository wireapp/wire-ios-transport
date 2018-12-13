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

import Foundation

class ServerCertificateTrust: NSObject, BackendTrustProvider {
    let trustData: [TrustData]
    
    init(trustData: [TrustData]) {
        self.trustData = trustData
    }
    
    public func verifyServerTrust(trust: SecTrust, host: String?) -> Bool {
        guard let host = host else { return false }
        let pinnedKeys = trustData
            .lazy
            .filter { trust in
                trust.matches(host: host)
            }
            .compactMap { trust in
                trust.certificateKey
            }
            .prefix(1)
        
        return verifyServerTrustWithPinnedKeys(trust, Array(pinnedKeys))
    }

}
