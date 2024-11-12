//
//  CredentialsTests.swift
//  AuthenticationTests
//
//  Created by Dave Johnson on 1/17/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

import XCTest
import Foundation

@testable import Authentication

class CredentialsTests: XCTestCase {
    
    func testCreate() {
        let credential = Credentials(username: "testuser", password: "testpass", ssn: "111223333")
        XCTAssertEqual(credential.username, "testuser")
        XCTAssertEqual(credential.password, "testpass")
        XCTAssertEqual(credential.ssn, "111223333")
    }
}
