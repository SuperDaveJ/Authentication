//
//  TokenMigration.swift
//  PaycomESS
//
//  Created by Dave Johnson on 1/17/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

import Foundation
import Shared
import Paycomfire
import Services

class TokenMigration {
    private let server: TokenMigrationServer
    
    var notificationRegistration: String {
        
        guard let token = Defaults.standard.firebaseToken else {
            return ""
        }
        
        return token
    }

    init(server: TokenMigrationServer = TokenMigrationServerAF()) {
        self.server = server
    }

    static func meetsMigrationCondition(credentials: LoginToken) -> Bool {
        return credentials.version == .v0
    }

    func migrate(oldToken: String, completion: @escaping (String?) -> Void) {
        self.getNewTokenFromNetwork(oldToken: oldToken) { success, result in
            if success, let result = result {
                completion(result.token)
            } else {
                completion(nil)
            }
        }
    }

    private func getNewTokenFromNetwork(oldToken: String, completion: @escaping (Bool, TokenMigrationResult?) -> Void) {
        
        let request = TokenMigrationRequest.init(baseUrl: PaycomUrls.shared.server_url,
                                                 token: oldToken,
                                                 deviceId: DeviceInfo.getDeviceId(),
                                                 notificationRegistration: notificationRegistration)

        server.migrate(request: request) { networkSuccess, json in
            if networkSuccess, let json = json {
                guard let accountJson = json["account"] as? [String : Any?],
                    let token = json["token"] as? String,
                    let userDisplayName = json["userDisplayName"] as? String else {
                        completion(false, nil)
                        return
                }

                completion(true, TokenMigrationResult(accountJSON: accountJson, token: token, userDisplayName: userDisplayName))
            } else {
                completion(false, nil)
            }
        }
    }

}

struct TokenMigrationResult {
    var accountJSON: [String: Any?]
    var token: String
    var userDisplayName: String?
}

