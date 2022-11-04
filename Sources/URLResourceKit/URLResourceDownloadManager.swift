//
//  URLResourceDownloadManager.swift
//  URLResourceKit
//
//  Created by yukonblue on 07/19/2022.
//

import Foundation

public class URLResourceDownloadManager {

    public static let shared = URLResourceDownloadManager()

    private lazy var session: URLSession = URLSession(configuration: URLSessionConfiguration.default,
                                                      delegate: nil,
                                                      delegateQueue: nil)

    public func downloadTask(url: URL) -> URLResourceDownloadTask {
        URLResourceDownloadTask(session: self.session, url: url)
    }

    public func dataTask(url: URL, config: URLSessionConfiguration = URLSessionConfiguration.default) -> URLResourceDataTask {
        URLResourceDataTask(session: URLSession(configuration: config,
                                                delegate: nil,
                                                delegateQueue: nil),
                            url: url)
    }
}
