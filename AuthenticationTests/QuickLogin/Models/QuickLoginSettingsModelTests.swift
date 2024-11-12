//
//  QuickLoginSettingsModelTests.swift
//  AuthenticationTests
//
//  Created by Dave Johnson on 1/17/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

import Services
import Shared
import XCTest

@testable import Authentication

class QuickLoginSettingsModelTests: XCTestCase {

    var qlDelegate: QuickLoginDelegateMock!
    var qlSettingsModel: QuickLoginSettingsModel!
    
    override func setUp() {
        qlDelegate = QuickLoginDelegateMock()
        qlSettingsModel = QuickLoginSettingsModel(qlDelegate)
    }
    
    func testMakeSections() {
        let sections = qlSettingsModel.makeSections()
        XCTAssertEqual(sections.count, 3)
    }
    
    func testQLSwitchAction() {
        let aSwitch = UISwitch()
        aSwitch.isOn = false
        
        qlSettingsModel.qlSwitchAction(switchControl: aSwitch)
        XCTAssertFalse(qlDelegate.presentQLCalled)
        XCTAssertTrue(qlDelegate.resetQLCalled)
        
        qlDelegate.presentQLCalled = false
        qlDelegate.resetQLCalled = false
        
        aSwitch.isOn = true
        
        qlSettingsModel.qlSwitchAction(switchControl: aSwitch)
        XCTAssertTrue(qlDelegate.presentQLCalled)
        XCTAssertFalse(qlDelegate.resetQLCalled)
    }
    
    func testAutoAuthAction() {
        let aSwitch = UISwitch()
        aSwitch.isOn = false
        
        qlSettingsModel.autoAuthAction(switchControl: aSwitch)
        
        XCTAssertEqual(Defaults.standard.automaticAuthenticationEnabled, aSwitch.isOn)
        
        aSwitch.isOn = true
        
        qlSettingsModel.autoAuthAction(switchControl: aSwitch)
        XCTAssertEqual(Defaults.standard.automaticAuthenticationEnabled, aSwitch.isOn)

    }
}

class QuickLoginDelegateMock: QuickLoginDelegate {
    
    var presentQLCalled: Bool = false
    var resetQLCalled: Bool = false
    
    func presentQuickLogin(_ quickLoginSettingsModel: QuickLoginSettingsModel) {
        presentQLCalled = true
    }
    
    func resetQuickLogin(_ quickLoginSettingsModel: QuickLoginSettingsModel, cancelAction: @escaping () -> Void) {
        resetQLCalled = true

    }
    
}
