//
//  TokenMigrationServer.swift
//  PaycomESS
//
//  Created by Dave Johnson on 1/17/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

import Foundation
import Paycomfire
import Services

struct TokenMigrationRequest {
    var baseUrl: String
    var token: String
    var deviceId: String
    var notificationRegistration: String
}

protocol TokenMigrationServer {
    func migrate(request: TokenMigrationRequest, completion: @escaping (Bool, [String : Any?]?) -> Void)
}

class TokenMigrationServerAF: TokenMigrationServer {

    func migrate(request: TokenMigrationRequest, completion: @escaping (Bool, [String : Any?]?) -> Void) {
        let baseUrl = request.baseUrl.trimmingCharacters(in: .init(charactersIn: "/"))
        let fullUrl = baseUrl + "/ee/web.php/quick-login/token-migration"
        guard let url = URL(string: fullUrl) else { completion(false, nil); return }

        let headers = [
            "Content-Type": "application/x-www-form-urlencoded"
        ]

        let parameters = [
            "token": request.token,
            "deviceId": request.deviceId,
            "notificationRegistration": request.notificationRegistration
        ]

        Paycomfire.shared.request(url, method: HTTPMethod.post, parameters: parameters, encoding: URLEncoding.default, headers: headers).responseJSON { (responseData) in

            switch responseData.result {
            case .success(let value):
                let json = value as? [String: Any?] ?? [String: Any?]()
                completion(true, json)
            case .failure(let error):
                completion(false, nil)
                error.record(.tokenMigrationError)
            }
        }
    }
}
