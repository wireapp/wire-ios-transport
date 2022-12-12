//
//  URLSessionMonitoring.swift
//  WireTransport-ios
//
//  Created by F on 09/12/2022.
//  Copyright © 2022 Wire. All rights reserved.
//

import Foundation
import Combine

public typealias URLSessionMonitoringDelegate = URLSessionTaskDelegate & URLSessionDataDelegate

public class URLSessionMonitoring: NSObject  {
    static var monitoringSubject: CurrentValueSubject<URLSessionMonitoringDelegate?, Never> = .init(nil)

    private var multicast: MulticastDelegate<URLSessionMonitoringDelegate>

    public static func register(_ delegate: URLSessionMonitoringDelegate) {
        self.monitoringSubject.value = delegate
    }

    private var cancellables = Set<AnyCancellable>()

    public override init() {
        self.multicast = .init()
        super.init()
        // forward calls to monitoringDelegate
        Self.monitoringSubject.sink(receiveValue: { [weak self] delegate in
            if let delegate = delegate {
                self?.multicast.add(delegate)
            } else if let oldValue = Self.monitoringSubject.value {
                self?.multicast.remove(oldValue)
            }
        }).store(in: &cancellables)
    }

    public convenience init(delegate: URLSessionMonitoringDelegate) {
        self.init()
        self.addDelegate(delegate)
    }

    public func addDelegate(_ delegate: URLSessionMonitoringDelegate) {
        self.multicast.add(delegate)
    }
}

extension URLSessionMonitoring: URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, willBeginDelayedRequest request: URLRequest, completionHandler: @escaping (URLSession.DelayedRequestDisposition, URLRequest?) -> Void) {
        multicast.call {
            $0.urlSession?(session, task: task, willBeginDelayedRequest: request, completionHandler: completionHandler)
        }
    }

    public func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        multicast.call {
            $0.urlSession?(session, taskIsWaitingForConnectivity: task)
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        multicast.call {
            $0.urlSession?(session, task: task, willPerformHTTPRedirection: response, newRequest: request, completionHandler: completionHandler)
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        multicast.call {
            $0.urlSession?(session, task: task, didReceive: challenge, completionHandler: completionHandler)
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        multicast.call {
            $0.urlSession?(session, task: task, needNewBodyStream: completionHandler)
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        multicast.call {
            $0.urlSession?(session, task: task, didSendBodyData: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        multicast.call {
            $0.urlSession?(session, task: task, didFinishCollecting: metrics)
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        multicast.call {
            $0.urlSession?(session, task: task, didCompleteWithError: error)
        }
    }

}

extension URLSessionMonitoring: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        multicast.call {
            $0.urlSession?(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
        }
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
        multicast.call {
            $0.urlSession?(session, dataTask: dataTask, didBecome: downloadTask)
        }
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome streamTask: URLSessionStreamTask) {
        multicast.call {
            $0.urlSession?(session, dataTask: dataTask, didBecome: streamTask)
        }
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        multicast.call {
            $0.urlSession?(session, dataTask: dataTask, didReceive: data)
        }
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        multicast.call {
            $0.urlSession?(session, dataTask: dataTask, willCacheResponse: proposedResponse, completionHandler: completionHandler)
        }
    }


}

// TODO: move to core or some common utils
class MulticastDelegate<T: Any>: NSObject {
    private let delegates = NSHashTable<AnyObject>(options: .weakMemory, capacity: 0)

    func add(_ delegate: T) {
        delegates.add(delegate as AnyObject)
    }

    func remove(_ delegate: T) {
        delegates.remove(delegate as AnyObject)
    }

    func call(_ function: @escaping (T) -> Void) {
        delegates.allObjects.forEach {
            function($0 as! T)
        }
    }
}
