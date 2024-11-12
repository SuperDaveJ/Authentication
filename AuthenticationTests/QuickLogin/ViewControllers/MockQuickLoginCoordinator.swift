//
//  MockQuickLoginCoordinator.swift
//  AuthenticationTests
//
//  Created by Dave Johnson on 1/17/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

@testable import Authentication
import XCTest

class MockQuickLoginSettingsCoordinator: QuickLoginSettingsCoordinationDelegate {
    
    var controller: QuickLoginSettingsViewControllerMock
    var expectation: XCTestExpectation?
    
    init(controller: QuickLoginSettingsViewControllerMock) {
        self.controller = controller
    }
    
    func showQuickLoginSetup() {
        self.expectation?.fulfill()
    }
}
