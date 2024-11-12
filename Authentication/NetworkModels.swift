//
//  NetworkModels.swift
//  Authentication
//
//  Created by Dave Johnson on 1/17/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

typealias NetworkResultJson = NetworkResult<[String: Any?]>

enum NetworkResult<T> {
    case success(result: T, httpCode: Int?)
    case error(error: NetworkError)
}

enum NetworkError: Error {
    case error(message: String)
    case jsonError(message: String)
}
