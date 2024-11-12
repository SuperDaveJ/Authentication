//
//  PinLogin.swift
//  PaycomESS
//
//  Created by Dave Johnson on 1/17/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

import Foundation
import Services
import Shared

enum PinLoginError: Error {
    case exceededNumberOfLoginAttempts
    case exceededInitialLoginAttemptLimit
    case incorrectPin
    case cantGetSavedPin
    case warnAboutReset
}

class PinLogin: NSObject {
    
    private var numberOfAttempts = 0
    private var pinChain = KeychainFactory.shared.getPinKeychain()
    private var correctPin: String?
    private var loginAttemptsLimit = 9
    private var pinDelay = PinDelay()
    
    override init() {
        correctPin = try? pinChain.loadData()
    }
    
    @discardableResult func enteredPinMatchesSavedPin(_ enteredPin: String) throws -> String {
        
        // Check that we were able to get a valid pin from the keychain
        guard correctPin != nil, let correctPin = correctPin else { throw PinLoginError.cantGetSavedPin }

        numberOfAttempts = Defaults.standard.pinAttemptNumber
        
        guard correctPin == enteredPin else {
            numberOfAttempts += 1
            Defaults.standard.pinAttemptNumber = numberOfAttempts
            
            // MARK: -  Brute force PIN Protection
            guard numberOfAttempts != 3, numberOfAttempts != 6 else {				
				throw PinLoginError.exceededInitialLoginAttemptLimit
			}
			
            guard numberOfAttempts < loginAttemptsLimit else {
				numberOfAttempts = 0
				throw PinLoginError.exceededNumberOfLoginAttempts
			}
			
            guard numberOfAttempts < loginAttemptsLimit-1 else {
				throw PinLoginError.warnAboutReset
			}
						
            throw PinLoginError.incorrectPin
        }
        
        // Reset Attempt Number
        pinDelay.resetPinAttemptsAndTime()

        return enteredPin
    }
    
}
