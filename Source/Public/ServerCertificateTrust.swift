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
            .filter { trustData in
                trustData.matches(host: host)
            }
            .map { trustData in
                trustData.certificateKey
            }
        
        return verifyServerTrustWithPinnedKeys(trust, pinnedKeys)
    }
    
    private func publicKeyAssociatedWithServerTrust(_ serverTrust: SecTrust) -> SecKey? {
        let policy = SecPolicyCreateBasicX509()
        
        // leaf certificate
        let certificate: SecCertificate? = SecTrustGetCertificateAtIndex(serverTrust, 0)
        
        let certificatesCArray = [certificate] as CFArray
        var trust: SecTrust? = nil
        
        if SecTrustCreateWithCertificates(certificatesCArray, policy, &trust) != noErr {
            return nil
        }
        
        var key: SecKey? = nil
        if #available(iOS 14.0, *) {
            if let trust = trust {
                key = SecTrustCopyKey(trust)
            }
        } else {
            if let trust = trust {
                var result: SecTrustResultType = SecTrustResultType.invalid
                if SecTrustEvaluate(trust, &result) != noErr {
                    return nil
                }
            }
            
            if let trust = trust {
                key = SecTrustCopyPublicKey(trust)
            }
        }
        
        return key
    }
    
    
    func verifyServerTrustWithPinnedKeys(_ serverTrust: SecTrust, _ pinnedKeys: [SecKey]) -> Bool {
        guard SecTrustEvaluateWithError(serverTrust, nil) else {
            return false
        }
        
        guard !pinnedKeys.isEmpty else {
            return true
        }
        
        guard let publicKey = publicKeyAssociatedWithServerTrust(serverTrust) else {
            return false
        }
        
        return pinnedKeys.contains(publicKey)
    }
}
