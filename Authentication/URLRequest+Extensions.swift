//
//  URLRequest+Extensions.swift
//  Authentication
//
//  Created by Dave Johnson on 1/17/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

extension URLRequest {
    
    /**
     - Return bool: True if set, false if not
    */
    @discardableResult
    mutating func setBasicAuth(token: String) -> Bool {
        
        let basicAuthString = ":" + token
        let basicAuthData = basicAuthString.data(using: .utf8)
        if let basicAuthBase64String = basicAuthData?.base64EncodedString() {
            self.setValue("Basic \(basicAuthBase64String)", forHTTPHeaderField: "Authorization")
            return true
        } else {
            return false
        }
    }
}
