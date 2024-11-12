//
//  QuickLoginViewControllerLeakTests.swift
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
 Tests QuickLoginViewController for memory leaks in init and viewDidLoad methods.
 */
class QuickLoginViewControllerLeakTests: QuickSpec {
    
    override func spec() {
        describe("QuickLoginViewController Type: Login"){
            describe("viewDidLoad") {
                let vc = LeakTest {
                    let quickloginVC = QuickLoginViewController(quickLoginType: .login)
                    
                    return quickloginVC
                }
                
                it("must not leak"){
                    expect(vc).toNot(leak())
                }
            }
        }
        
        describe("QuickLoginViewController Type: Setup"){
            describe("viewDidLoad") {
                let vc = LeakTest {
                    let quickloginVC = QuickLoginViewController(quickLoginType: .setup(type: .setupLaterOptions))
                    
                    return quickloginVC
                }
                
                it("must not leak"){
                    expect(vc).toNot(leak())
                }
            }
        }
        
        describe("QuickLoginViewController Type: Setup"){
            describe("viewDidLoad") {
                let vc = LeakTest {
                    
                    let quickloginVC = UIStoryboard(name: "QuickLoginFlow", bundle: Bundle(identifier: "com.paycom.Authentication")).instantiateViewController(withIdentifier: "QuickLoginViewController") as! QuickLoginViewController
                    quickloginVC.quickLoginScreenType = .setup(type: .setupLaterOptions)
                    quickloginVC.systemLoginType = .ee
                    
                    return quickloginVC
                }
                
                it("must not leak"){
                    expect(vc).toNot(leak())
                }
            }
        }
    }
}
