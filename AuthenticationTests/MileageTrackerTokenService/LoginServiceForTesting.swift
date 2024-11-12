//
//  LoginService.swift
//  PaycomESS
//
//  Created by Dave Johnson on 1/17/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

import UIKit
import Shared

enum LoginRequestState {
    case success
    case error
}

class Credentials {
    
    var username: String
    var password: String
    var ssn: String
    
    private var cookies: [HTTPCookie]?
    
    init(username: String, password: String, ssn: String) {
        
        self.username = username.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? username
        self.password = password.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? password
        self.ssn = ssn.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ssn
    }
    
    func setCookies(cookies: [HTTPCookie]) {
        
        self.cookies = cookies
    }
    
    func getCookies() -> [HTTPCookie]? {
        
        return cookies
    }
    
}

enum LoginError: Error {
    case invalidUsername
    case invalidPassword
    case invalidSsn
}

class PaycomUrls {
    static func getLoginUrl(baseUrl: String!) -> String? {
        
        if(baseUrl.isEmpty) {
            return nil
        } else {
            let baseUrlTrimmed = baseUrl.trimmingCharacters(in: .init(charactersIn: "/"))
            return baseUrlTrimmed + "/web.php/wrapper/login"
        }
    }

}
