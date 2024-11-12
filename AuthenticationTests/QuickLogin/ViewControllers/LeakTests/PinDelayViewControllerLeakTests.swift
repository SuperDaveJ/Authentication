//
//  PinDelayViewControllerLeakTests.swift
//  AuthenticationTests
//
//  Created by Daniel Simons on 9/20/19.
//  Copyright © 2019 Rahul Chidurala. All rights reserved.
//

import Nimble
import Quick

@testable import SpecLeaks
@testable import Authentication

/**
 Tests PinDelayViewController for memory leaks in init and viewDidLoad methods.
 */
class PinDelayViewControllerLeakTests: QuickSpec {
    
    override func spec() {
        describe("PinDelayViewController"){
            describe("viewDidLoad") {
                let vc = LeakTest {
                    let pinDelayVC = UIStoryboard(name: "QuickLoginFlow", bundle: Bundle(identifier: "com.paycom.Authentication")).instantiateViewController(withIdentifier: "storyboardPinDelayVC") as! PinDelayViewController
                    return pinDelayVC
                }
                
                it("must not leak"){
                    expect(vc).toNot(leak())
                }
            }
        }
    }
}
