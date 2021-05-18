//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

@available(iOSApplicationExtension 13.0, iOS 13.0, *)
@objcMembers
class NativePushChannel: NSObject, PushChannelType {

    var clientID: String?
    var accessToken: AccessToken? {
        didSet {
            establishConnection()
        }
    }

    var keepOpen: Bool = false
    let environement: BackendEnvironment
    var session: URLSession?
    var websocketTask: URLSessionWebSocketTask?
    var consumer: ZMPushChannelConsumer?
    var pingTimer: Timer?
    var groupQueue: ZMSGroupQueue?

    var canOpenConnection: Bool {
        return accessToken != nil && clientID != nil && keepOpen
    }

    init(environment: BackendEnvironment) {
        self.environement = environment

        super.init()
        
        self.session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: .main)
    }

    func closeAndRemoveConsumer() {
        consumer = nil
        websocketTask?.cancel()
    }

    func attemptToOpenPushChannelConnection() {
        guard canOpenConnection else {
            return
        }

        establishConnection()
    }

    func reachabilityDidChange(_ reachability: ZMReachability) {

    }

    func setPushChannelConsumer(_ consumer: ZMPushChannelConsumer?, groupQueue: ZMSGroupQueue) {
        self.groupQueue = groupQueue
        self.consumer = consumer

        if consumer == nil {
            closeAndRemoveConsumer()
        } else {
            attemptToOpenPushChannelConnection()
        }
    }

    func establishConnection() {
        guard websocketTask == nil,
              let accessToken = accessToken,
              let websocketURL = websocketURL else {
            return
        }

        var connectionRequest = URLRequest(url: websocketURL)
        connectionRequest.setValue("\(accessToken.type) \(accessToken.token)", forHTTPHeaderField: "Authorization")

        websocketTask = session?.webSocketTask(with: connectionRequest)
        websocketTask?.resume()
    }

    var websocketURL: URL? {
        let url = environement.backendWSURL.appendingPathComponent("/await")
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = [URLQueryItem(name: "client", value: clientID)]

        return urlComponents?.url
    }


    func listen() {
        websocketTask?.receive(completionHandler: { [weak self] (result) in
            switch result {
            case.failure(let error):
                Logging.pushChannel.debug("Failed to receive message \(error)")
            case .success(let message):
                switch message {
                case .data(let data):
                    if let transportData = try? JSONSerialization.jsonObject(with: data, options: []) as? ZMTransportData {
                        self?.groupQueue?.performGroupedBlock({
                            self?.consumer?.pushChannelDidReceive(transportData)
                        })
                    }
                case .string(_):
                    break
                @unknown default:
                    break
                }
            }

            self?.listen()
        })
    }

    func startPingTimer() {
        let timer = Timer(timeInterval: 30, repeats: true) { [weak self] (_) in
            Logging.pushChannel.debug("Sending ping")
            self?.websocketTask?.sendPing(pongReceiveHandler: { error in
                if let error = error {
                    Logging.pushChannel.debug("Failed to send ping: \(error)")
                }
            })
        }

        self.pingTimer = timer
        RunLoop.main.add(timer, forMode: .default)
    }

}

@available(iOSApplicationExtension 13.0, iOS 13.0, *)
extension NativePushChannel: URLSessionWebSocketDelegate {

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        Logging.pushChannel.debug("Push channel did open with protocol \(`protocol` ?? "n/a")")

        listen()
        startPingTimer()

        groupQueue?.performGroupedBlock({
            self.consumer?.pushChannelDidOpen(with: nil)
        })

    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        Logging.pushChannel.debug("Push channel did close with code \(closeCode), reason: \(reason ?? Data())")

        websocketTask = nil
        pingTimer = nil

        groupQueue?.performGroupedBlock {
            self.consumer?.pushChannelDidClose(with: nil, error: nil)
        }

    }
}
