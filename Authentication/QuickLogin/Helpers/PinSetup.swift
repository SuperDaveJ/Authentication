//
//  PinSetup.swift
//  PaycomESS
//
//  Created by Dave Johnson on 1/17/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

import Foundation

enum PinSetupError: Error {
    case cantCompareToFirstPinEntry
    case invalidSecondPinEntry
}

class PinSetup: NSObject {
    private(set) var firstPinEntry: String?
    
    override init() { }
    
    /**
     Set the first pin using this method.
    */
    func enterFirst(_ pin: String) {
        self.firstPinEntry = pin
    }
    
    func resetFirst(){
        self.firstPinEntry = nil
    }
    
    /**
     If firstPin has been set and the second Pin is equal to it then the second pin will be successfully returned.
    */
    @discardableResult func enterSecond(_ pin: String) throws -> String {
        guard firstPinEntry != nil else { throw PinSetupError.cantCompareToFirstPinEntry }
        guard pin == firstPinEntry else { firstPinEntry = nil; throw PinSetupError.invalidSecondPinEntry }
        return pin
    }
}
