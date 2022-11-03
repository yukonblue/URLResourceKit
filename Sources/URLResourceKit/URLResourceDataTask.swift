//
//  URLResourceDataTask.swift
//  URLResourceKit
//
//  Created by yukonblue on 07/22/2022.
//

import Foundation
import Combine

enum URLResourceDataTaskResponse {

    case uninitiated
    case waitingForResponse
    case dataReceived(data: Data)
}

class URLResourceDataTask: NSObject {

    private let session: URLSession
    private let url: URL
    private var data: Data
    private let dataTask: URLSessionDataTask

    typealias PublisherType = AnyPublisher<URLResourceDataTaskResponse, URLError>

    let subject: PassthroughSubject<PublisherType.Output, PublisherType.Failure>

    var taskIdentifier: Int {
        self.dataTask.taskIdentifier
    }

    var publisher: PublisherType {
        self.subject.eraseToAnyPublisher()
    }

    init(session: URLSession, url: URL) {
        self.session = session
        self.url = url
        self.data = Data()
        self.subject = PassthroughSubject<PublisherType.Output, PublisherType.Failure>()

        self.dataTask = session.dataTask(with: self.url)

        self.subject.send(.uninitiated)
    }

    func resume() {
        self.dataTask.delegate = self
        self.dataTask.resume()
        self.subject.send(.waitingForResponse)
    }
}

extension URLResourceDataTask: URLSessionDataDelegate {

    ///
    /// Tells the delegate that the data task has received some of the expected data.
    ///
    /// Parameters:
    ///   - session: The session containing the data task that provided data.
    ///   - dataTask: The data task that provided data.
    ///   - data: A data object containing the transferred data.
    ///
    /// Discussion:
    /// Because the data object parameter is often pieced together from a number of different data objects,
    /// whenever possible, use the `enumerateBytes(_:)` method to iterate through the data
    /// rather than using the bytes method (which flattens the data object into a single memory block).
    ///
    /// This delegate method may be called more than once, and each call provides only data received since the previous call.
    /// The app is responsible for accumulating this data if needed.
    ///
    /// https://developer.apple.com/documentation/foundation/urlsessiondatadelegate/1411528-urlsession
    ///
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive dataReceived: Data) {
        guard session == self.session, dataTask == self.dataTask else {
            return
        }

        self.data.append(dataReceived)
    }
}

extension URLResourceDataTask: URLSessionTaskDelegate {

    ///
    /// Tells the delegate that the task finished transferring data.
    ///
    /// Parameters:
    ///   - session: The session containing the task that has finished transferring data.
    ///   - task: The task that has finished transferring data.
    ///   - error: If an error occurred, an error object indicating how the transfer failed, otherwise NULL.
    ///
    /// Discussion:
    /// The only errors your delegate receives through the error parameter are client-side errors,
    /// such as being unable to resolve the hostname or connect to the host.
    /// To check for server-side errors, inspect the response property of the task parameter received by this callback.
    ///
    /// https://developer.apple.com/documentation/foundation/urlsessiontaskdelegate/1411610-urlsession
    ///
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard session == self.session, task == self.dataTask else {
            return
        }

        if let urlError: URLError = error as? URLError { // has error
            self.subject.send(completion: .failure(urlError))
        } else { // success
            self.subject.send(.dataReceived(data: self.data))
            self.subject.send(completion: .finished)
        }
    }
}
