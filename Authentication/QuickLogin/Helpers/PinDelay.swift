//
//  PinDelay.swift
//  PaycomESS
//
//  Created by Dave Johnson on 2/15/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

import Foundation
import Services
import Shared
import UIKit

class PinDelay: NSObject {
    
    func isPinEntryDelayed() -> Bool {
        
        let timeDelayed = getRemainingDelayTime()
        if timeDelayed < QuickLoginViewController.defaultPinDelay && timeDelayed > 0 {
            return true
        }
        return false
    }

    func waitFiveMinutes() {
        let currentTime = NSDate().timeIntervalSince1970
        Defaults.standard.failedAttemptTime = currentTime
    }
    
    func getRemainingDelayTime() -> Double {
        
        let failedAttemptTime = Defaults.standard.failedAttemptTime ?? 0
        let currentTime = NSDate().timeIntervalSince1970
        let remainingDelayTime = failedAttemptTime > 0 ? ((currentTime - failedAttemptTime)/60) : 0.0
        return remainingDelayTime
    }
    
    func getRemainingSecondsOfDelay() -> Double {
        
        let failedAttemptTime = Defaults.standard.failedAttemptTime ?? 0
        let currentTime = NSDate().timeIntervalSince1970
        let getRemainingSecondsOfDelay = failedAttemptTime > 0 ? (currentTime - failedAttemptTime) : 0.0
        return getRemainingSecondsOfDelay
    }
    
    func resetPinAttemptsAndTime() {
        Defaults.standard.pinAttemptNumber = 0
        Defaults.standard.failedAttemptTime = nil
    }
    
    func resetPinDelayTime() {
        Defaults.standard.failedAttemptTime = nil
    }
}




