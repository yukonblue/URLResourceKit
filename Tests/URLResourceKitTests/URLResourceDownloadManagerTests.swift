//
//  URLResourceDownloadManagerTests.swift
//  URLResourceKit
//
//  Created by yukonblue on 07/19/2022.
//

import Foundation
import Combine

import XCTest
@testable import URLResourceKit

// MARK: Test Download Task

class URLResourceDownloadManagerTests: XCTestCase {

    var cancellable: AnyCancellable!

    let validURL: URL! = URL(string: "https://www.hope4cheetahs.org/favicon-32x32.png")
    let invalidURL: URL! = URL(string: "https://abcdefghijklmnopqrstuvwxyz.abc")

    func testDownloadTaskSuccessful() throws {
        let task = URLResourceDownloadManager.shared.downloadTask(url: self.validURL)

        let progressReachedCompletionExpectation = XCTestExpectation(description: "Download task progress completed")
        let completionExpectation = XCTestExpectation(description: "Download task completed")

        self.cancellable = task.publisher.sink(receiveCompletion: { completion in
            completionExpectation.fulfill()
        }, receiveValue: { progress in
            switch progress {
            case .uninitiated:
                print("Task uninitiated ...")
                break
            case .waitingForResponse:
                print("Waiting for response ...")
                break
            case .downloading(let progress):
                print("Progress: \(progress.fractionCompleted)")
                if progress.fractionCompleted == 1.0 {
                    progressReachedCompletionExpectation.fulfill()
                }
                break
            case .completed(let destinationLocation):
                print("Download completed, destination: \(destinationLocation)")
                XCTAssertTrue(destinationLocation.isFileURL)
                progressReachedCompletionExpectation.fulfill()
            }
        })

        task.resume()

        wait(for: [progressReachedCompletionExpectation, completionExpectation], timeout: 5)
    }

    func testDownloadTaskErrorOnInvalidURL() throws {
        let task = URLResourceDownloadManager.shared.downloadTask(url: self.invalidURL)

        let errorExpectation = XCTestExpectation(description: "Download task errored")
        let inversedReceiveValueExpectation = XCTestExpectation(description: "Should have not received any values")
        inversedReceiveValueExpectation.isInverted = true

        self.cancellable = task.publisher.sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                break
            case .failure(let urlError):
                print(urlError)
                errorExpectation.fulfill()
            }
        }, receiveValue: { _ in
            let inversedReceiveValueExpectation = XCTestExpectation(description: "Should have not received any values")
            inversedReceiveValueExpectation.isInverted = true
        })

        task.resume()

        wait(for: [errorExpectation, inversedReceiveValueExpectation], timeout: 5)
    }
}

// MARK: Test Data Task

extension URLResourceDownloadManagerTests {

    func testDataTaskSuccessful() throws {
        try self._testDataTaskSuccessful(withURL: self.validURL, andExpectedNumbersOfBytesReceived: 7501)
    }

    func testDataTaskSuccessfulWithPlayItemsManifestPayload() throws {
        let url = URL(string: "https://raw.githubusercontent.com/yukonblue/HeartShip-Logo/main/README.md")!
        try self._testDataTaskSuccessful(withURL: url, andExpectedNumbersOfBytesReceived: 17)
    }

    func _testDataTaskSuccessful(withURL url: URL, andExpectedNumbersOfBytesReceived expectedNumberOfBytesReceived: Int) throws {
        let task = URLResourceDownloadManager.shared.dataTask(url: url, config: URLSessionConfiguration.ephemeral)

        let dataReceivedExpectation = XCTestExpectation(description: "Data task data received")
        let completionExpectation = XCTestExpectation(description: "Data task completed")

        dataReceivedExpectation.expectedFulfillmentCount = 1
        dataReceivedExpectation.assertForOverFulfill = true

        self.cancellable = task.publisher.sink(receiveCompletion: { completion in
            completionExpectation.fulfill()
        }, receiveValue: { progress in
            switch progress {
            case .uninitiated:
                print("Task uninitiated ...")
                break
            case .waitingForResponse:
                print("Waiting for response ...")
                break
            case .dataReceived(let data):
                print("Data received: \(data.count) bytes")
                dataReceivedExpectation.fulfill()
                XCTAssertEqual(data.count, expectedNumberOfBytesReceived) // Tests that the data downloaded has the expected number of bytes.
                break
            }
        })

        task.resume()

        wait(for: [dataReceivedExpectation, completionExpectation], timeout: 5)
    }

    func testDataTaskErrorOnInvalidURL() throws {
        let task = URLResourceDownloadManager.shared.dataTask(url: self.invalidURL)

        let errorExpectation = XCTestExpectation(description: "Data task errored")
        let inversedReceiveValueExpectation = XCTestExpectation(description: "Should have not received any values")
        inversedReceiveValueExpectation.isInverted = true

        self.cancellable = task.publisher.sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                break
            case .failure(let urlError):
                print(urlError)
                errorExpectation.fulfill()
            }
        }, receiveValue: { _ in
        })

        task.resume()

        wait(for: [errorExpectation], timeout: 5)
    }
}
