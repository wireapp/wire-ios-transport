//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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


final class ProxySettings: NSObject, ProxySettingsProvider, Codable {

    let host: String
    let port: Int
    let needsAuthentication: Bool

    init(host: String,
         port: Int,
         needsAuthentication: Bool = false) {
        self.host = host
        self.port = port
        self.needsAuthentication = needsAuthentication
        
        super.init()
    }

    func socks5Settings(proxyUsername: String?, proxyPassword: String?) -> NSDictionary {
        var proxyDictionary: [AnyHashable : Any] = [
            "SOCKSEnable" : 1,
            "SOCKSProxy": host,
            "SOCKSPort": port,
            kCFProxyTypeKey: kCFProxyTypeSOCKS,
            kCFStreamPropertySOCKSVersion: kCFStreamSocketSOCKSVersion5,
        ]

        if let username = proxyUsername, let password = proxyPassword, needsAuthentication {
            proxyDictionary[kCFStreamPropertySOCKSUser] = username
            proxyDictionary[kCFStreamPropertySOCKSPassword] = password
        }
        return NSDictionary(dictionary: proxyDictionary)
    }
}

public class ProxyCredentials: NSObject {
    public var username: String
    public var password: String
    public var proxy: ProxySettingsProvider


    init(proxy: ProxySettingsProvider, username: String, password: String) {
        self.username = username
        self.password = password
        self.proxy = proxy
    }

    @objc(initWithUsername:password:forProxy:)
    public convenience init?(username: String?, password: String?, proxy: ProxySettingsProvider) {
        guard let username = username, let password = password else {
            return nil
        }
        self.init(proxy: proxy, username: username, password: password)
    }

    public func persist() {
        guard let usernameData = username.data(using: .utf8),
              let passwordData = password.data(using: .utf8) else { return }
        do {
            try Keychain.storeItem(UsernameKeychainItem(proxyHost: proxy.host), value: usernameData)
            try Keychain.storeItem(PasswordKeychainItem(proxyHost: proxy.host), value: passwordData)
        } catch {
            Logging.backendEnvironment.error("could not save proxy credentials, \(error.localizedDescription)")
        }
    }

    public static func retrieve(for proxy: ProxySettingsProvider) -> ProxyCredentials? {
        guard let usernameData = try? Keychain.fetchItem(UsernameKeychainItem(proxyHost: proxy.host)),
              let passwordData = try? Keychain.fetchItem(PasswordKeychainItem(proxyHost: proxy.host)),
              let username = String(data: usernameData, encoding: .utf8),
              let password = String(data: passwordData, encoding: .utf8) else {
            return nil
        }

        return ProxyCredentials(username: username,
                                password: password,
                                proxy: proxy)
    }


    struct UsernameKeychainItem: KeychainItem {

        // MARK: - Properties

        private let itemIdentifier: String

        // MARK: - Life cycle

        init(proxyHost: String) {
            self.init(itemIdentifier: "\(proxyHost)-proxy-username")
        }

        private init(itemIdentifier: String) {
            self.itemIdentifier = itemIdentifier
        }

        // MARK: - Methods

        var queryForGettingValue: [CFString: Any] {
            [
                kSecClass: kSecClassIdentity,
                kSecAttrAccount: itemIdentifier,
                kSecReturnData: true
            ]
        }

        func queryForSetting(value: Data) -> [CFString: Any] {
            [
                kSecClass: kSecClassIdentity,
                kSecAttrAccount: itemIdentifier,
                kSecValueData: value
            ]
        }

    }

    struct PasswordKeychainItem: KeychainItem {

        // MARK: - Properties

        private let itemIdentifier: String

        // MARK: - Life cycle

        init(proxyHost: String) {
            self.init(itemIdentifier: "\(proxyHost)-proxy-password")
        }

        private init(itemIdentifier: String) {
            self.itemIdentifier = itemIdentifier
        }

        // MARK: - Methods

        var queryForGettingValue: [CFString: Any] {
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: itemIdentifier,
                kSecReturnData: true
            ]
        }

        func queryForSetting(value: Data) -> [CFString: Any] {
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: itemIdentifier,
                kSecValueData: value
            ]
        }

    }
}
