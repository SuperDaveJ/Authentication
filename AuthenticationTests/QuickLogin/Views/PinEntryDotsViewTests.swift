//
//  PinEntryDotsViewTests.swift
//  AuthenticationTests
//
//  Created by Dave Johnson on 1/17/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

import XCTest
@testable import Authentication

class PinEntryDotsViewTests: XCTestCase {

    var pinEntryDotsView: PinEntryDotsView!
    var mockPinEntryDotsViewDelegate: MockPinEntryDotsViewDelegate!
    
    override func setUp() {
        pinEntryDotsView = PinEntryDotsView(frame: .zero)
        mockPinEntryDotsViewDelegate = MockPinEntryDotsViewDelegate()
        pinEntryDotsView.delegate = mockPinEntryDotsViewDelegate
    }
    
    func testInsertTextValid() {
        
        pinEntryDotsView.insertText("1111")
        
        guard let mockDelegate = pinEntryDotsView.delegate as? MockPinEntryDotsViewDelegate else {
            XCTFail("PinEntryDotsView delegate must be MockPinEntryDotsViewDelegate")
            return
        }
        
        XCTAssertTrue(mockDelegate.isPinEntryKeyInputCalled)
    }
    
    func testInsertTextInvalid() {
        pinEntryDotsView.insertText("1\n")
        
        guard let mockDelegate = pinEntryDotsView.delegate as? MockPinEntryDotsViewDelegate else {
            XCTFail("PinEntryDotsView delegate must be MockPinEntryDotsViewDelegate")
            return
        }
        
        XCTAssertFalse(mockDelegate.isPinEntryKeyInputCalled)
    }
    
    func testInsertTextTooLong() {
        pinEntryDotsView.insertText("11111")
        
        guard let mockDelegate = pinEntryDotsView.delegate as? MockPinEntryDotsViewDelegate else {
            XCTFail("PinEntryDotsView delegate must be MockPinEntryDotsViewDelegate")
            return
        }
        
        XCTAssertFalse(mockDelegate.isPinEntryKeyInputCalled)
    }

}

class MockPinEntryDotsViewDelegate: PinEntryDotsViewDelegate {
    var isPinEntryKeyInputCalled: Bool = false
    
    func pinEntryKeyInput(_ sender: PinEntryDotsView, didChangeText text: String) {
        isPinEntryKeyInputCalled = true
    }
    
    func pinEntryKeyInputPinCount() -> Int {
        return 4
    }
    
    
}
