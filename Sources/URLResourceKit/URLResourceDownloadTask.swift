//
//  URLResourceDownloadTask.swift
//  URLResourceKit
//
//  Created by yukonblue on 07/22/2022.
//

import Foundation
import Combine

enum URLResourceDownloadTaskProgress {

    case uninitiated
    case waitingForResponse
    case downloading(progress: Progress)
    case completed(destinationLocation: URL)
}

class URLResourceDownloadTask: NSObject {

    private let session: URLSession
    private let url: URL

    private let downloadTask: URLSessionDownloadTask

    typealias PublisherType = AnyPublisher<URLResourceDownloadTaskProgress, URLError>

    fileprivate let subject: PassthroughSubject<PublisherType.Output, PublisherType.Failure>

    var taskIdentifier: Int {
        self.downloadTask.taskIdentifier
    }
    
    var publisher: PublisherType {
        self.subject.eraseToAnyPublisher()
    }

    init(session: URLSession, url: URL) {
        self.session = session
        self.url = url

        self.subject = PassthroughSubject<PublisherType.Output, PublisherType.Failure>()

        self.downloadTask = session.downloadTask(with: self.url)

        self.subject.send(.uninitiated)
    }

    func resume() {
        self.downloadTask.delegate = self
        self.downloadTask.resume()
        self.subject.send(.waitingForResponse)
    }
}

extension URLResourceDownloadTask: URLSessionDownloadDelegate {

    /// Tells the delegate that a download task has finished downloading.
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard session == self.session, downloadTask == self.downloadTask else {
            return
        }

        subject.send(.completed(destinationLocation: location))
        subject.send(completion: .finished)
    }

    /// Periodically informs the delegate about the download’s progress.
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard session == self.session, downloadTask == self.downloadTask else {
            return
        }

        #if false
        // This is not very accurate ..
        subject.send(.downloading(progress: downloadTask.progress))
        #else
        let progress = Progress(totalUnitCount: downloadTask.countOfBytesExpectedToReceive)
        progress.completedUnitCount = downloadTask.countOfBytesReceived
        subject.send(.downloading(progress: progress))
        #endif
    }
}

extension URLResourceDownloadTask: URLSessionTaskDelegate {

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard session == self.session, downloadTask == self.downloadTask else {
            return
        }

        if let urlError: URLError = error as? URLError {
            subject.send(completion: .failure(urlError))
        }
    }
}
