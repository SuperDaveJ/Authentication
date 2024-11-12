//
//  QuickLoginViewControllerTests.swift
//  AuthenticationTests
//
//  Created by Dave Johnson on 1/17/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

@testable import Services
import Shared
import XCTest

@testable import Authentication

class QuickLoginViewControllerTests: XCTestCase {

    func testSetupUserName() {
        let displayNameString = "Some Display Name"

        SettingsManager.shared.userConfiguration = UserConfiguration(
            defaultAccountURLString: "",
            priorityRedirectURLString: "",
            singleEmployeeAccountURLString: "",
            singleManagerAccountURLString: "",
            multipleEmployeeAccountsURLString: "",
            multipleManagerAccountsURLString: "",
            addManagerAccountsURLString: "",
            manageAccountsURLString: "",
            managePreferredEmployeeAccountURLString: "",
            managePreferredManagerAccountURLString: "",
            managerContactUsURLString: "",
            managerHelpPDFURLString: "",
            mileageTrackerAccounts: [],
            userDisplayName: displayNameString)

        let quickLoginVC = QuickLoginViewController(quickLoginType: .login)

        Defaults.standard.userName = SettingsManager.shared.userConfiguration?.userDisplayName
        let expected = quickLoginVC.userName
        let actual = ", \(displayNameString)."
        
        XCTAssertEqual(expected, actual)

    }
    
    func testDidBecomeActive() {
        let quickLoginVC = QuickLoginViewController(quickLoginType: .login)
        
        let navVC = UINavigationController()
        navVC.setViewControllers([quickLoginVC], animated: false)
        let window = UIWindow()
        window.rootViewController = navVC
        window.makeKeyAndVisible()
        
        quickLoginVC.viewDidLoad()
        let mockPinView = MockPinView(loginModel: LoginModel())
        quickLoginVC.pinView = mockPinView
        
        Services.shared.alertPresenter = AlertPresenter()

        quickLoginVC.didBecomeActive()
        
        XCTAssertTrue(mockPinView.isRestartAnimationCalled)
    }
}

class MockPinView: PinEntryView {
    var isRestartAnimationCalled: Bool = false
    
    override func restartAnimation() {
        isRestartAnimationCalled = true
    }
}
