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

struct RequestLog: Codable {
    var method: String?
    var endpoint: String?
    var headers: [String: String]

    init(_ request: NSURLRequest) {
        self.endpoint = request.url?.endpointRemoteLogDescription

        var filteredHeaders = request.allHTTPHeaderFields?.filter { Self.authorizedHeaderFields.contains($0.key) } ?? [:]

        let notLoggedValues = ["Sec-WebSocket-key", "Authorization", "sec-websocket-accept", "Set-cookie"]

        for value in notLoggedValues where filteredHeaders[value] != nil {
            filteredHeaders[value] = "*******"
        }
        self.headers = filteredHeaders
    }

    static let authorizedHeaderFields = ["Accept",
                                         "Accept-Charset",
                                         "Authorization",
                                         "Set-cookie",
                                         "Access-Control-Expose-Headers",
                                         "Date",
                                         "Location",
                                         "Request id",
                                         "Strict-Transport-Security",
                                         "Vary",
                                         "Accept-ranges",
                                         "Age",
                                         "Connection",
                                         "Content-Length",
                                         "Content-Type",
                                         "Date",
                                         "Etag",
                                         "Last-Modified",
                                         "Server",
                                         "Via",
                                         "X-Amz-Cf-Id",
                                         "A-Amz-Cf-Pop",
                                         "X-Amz-Meta-User",
                                         "X-cache",
                                         "Sec-WebSocket-key",
                                         "sec-websocket-accept"]




}

extension URL {
    var endpointRemoteLogDescription: String {
        let visibleCharactersCount = 3

        var components = URLComponents(string: self.absoluteString)

        var pathComponents: [String] = components?.path.components(separatedBy: "/") ?? []
        pathComponents.enumerated().forEach { item in
            pathComponents[item.offset] = item.element.truncated(visibleCharactersCount)
        }

        var queryComponents = components?.queryItems ?? []
        queryComponents.enumerated().forEach { item in
            var redactedItem = item.element
            redactedItem.value = redactedItem.value?.redactedAndTruncated(visibleCharactersCount)
            queryComponents[item.offset] = redactedItem
        }

        components?.path = pathComponents.joined(separator: "/")
        components?.queryItems = queryComponents

        var endpoint = [components?.host, components?.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))]
            .compactMap { $0 }
            .filter({ !$0.isEmpty })
            .joined(separator: "/")
        endpoint.append(components?.query !=  nil ? "?\(components!.query!)" : "")
        return endpoint
    }
}

extension String {
    var redacted: String {
        return "*".times(self.count)
    }

    func times(_ number: Int) -> String {
        var newString = ""
        for _ in 0..<number {
            newString += self
        }
        return newString
    }

    func redactedAndTruncated(_ maxVisibleCharacters: Int) -> String {
        if self.count <= maxVisibleCharacters {
            return "*".times(self.count)
        }
        return truncated(maxVisibleCharacters)
    }

    func truncated(_ maxVisibleCharacters: Int) -> String {
        var fillCount = max(self.count - maxVisibleCharacters, 0)
        if fillCount > maxVisibleCharacters {
            fillCount = maxVisibleCharacters
        }
        let newString = String(self.prefix(maxVisibleCharacters))
        return newString + "*".times(fillCount)
    }
}
