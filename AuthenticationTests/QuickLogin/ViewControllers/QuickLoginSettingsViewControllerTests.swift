//
//  QuickLoginSettingsViewControllerTests.swift
//  AuthenticationTests
//
//  Created by Dave Johnson on 1/17/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

import Services
import Shared
import XCTest
@testable import Authentication

class QuickLoginSettingsViewControllerTests: XCTestCase {
    
    private var quickLoginSettingsViewController: QuickLoginSettingsViewControllerMock!
    private var mockQuickLoginSettingsCoordinator: MockQuickLoginSettingsCoordinator!
    
    override func setUp() {
        self.quickLoginSettingsViewController = QuickLoginSettingsViewControllerMock()
        self.mockQuickLoginSettingsCoordinator = MockQuickLoginSettingsCoordinator(controller: quickLoginSettingsViewController)
        self.quickLoginSettingsViewController.coordinator = mockQuickLoginSettingsCoordinator
    }
    
    override func tearDown() {
        self.quickLoginSettingsViewController = nil
        self.mockQuickLoginSettingsCoordinator = nil
    }

    func testSetupTableView() {
        let window = UIWindow()
        window.rootViewController = quickLoginSettingsViewController
        window.makeKeyAndVisible()
        
        XCTAssertNotNil(quickLoginSettingsViewController.dataSource)
    }
    
    func testResetQuickLogin() {
        let model = QuickLoginSettingsModel(quickLoginSettingsViewController)
        quickLoginSettingsViewController.presentWasCalled = false
        XCTAssertFalse(quickLoginSettingsViewController.presentWasCalled)
        quickLoginSettingsViewController.resetQuickLogin(QuickLoginSettingsModel(nil)) {
            
        }
        XCTAssertFalse(quickLoginSettingsViewController.presentWasCalled)
    }
    
    func testPresentQuickLogin() {
        guard let mockCoordinator = quickLoginSettingsViewController.coordinator as? QuickLoginSettingsCoordinationDelegateMock else {
            XCTFail("Failed to setup ql settings coordination delegate mock")
            return
        }
        
        XCTAssertFalse(mockCoordinator.quickLoginSetupCalled)
        let qlSettingsModel = QuickLoginSettingsModel(nil)
        quickLoginSettingsViewController.presentQuickLogin(qlSettingsModel)
        XCTAssertTrue(mockCoordinator.quickLoginSetupCalled)
    }
}

public class QuickLoginSettingsCoordinationDelegateMock: QuickLoginSettingsCoordinationDelegate {
    var quickLoginSetupCalled: Bool = false
    
    public func showQuickLoginSetup() {
        quickLoginSetupCalled = true
    }
}

public class QuickLoginSettingsViewControllerMock: QuickLoginSettingsViewController {
    var dismissWasCalled: Bool = false
    var presentWasCalled: Bool = false
    var presentQLCalled: Bool = false
    
    var _coordinator: QuickLoginSettingsCoordinationDelegateMock?
    
    override public weak var coordinator: QuickLoginSettingsCoordinationDelegate? {
        get {
            if self._coordinator == nil {
                self._coordinator = QuickLoginSettingsCoordinationDelegateMock()
            }
            
            return self._coordinator
        }
        
        set {
            
        }
        
    }
    
    public override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        self.dismissWasCalled = true
        super.dismiss(animated: flag, completion: completion)
    }
    
    public override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        self.presentWasCalled = true
    }
}
