//
//  QuickLoginScreenType.swift
//  Authentication
//
//  Created by Dave Johnson on 1/17/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

import Foundation

public enum QuickLoginScreenType: Equatable {
    case login
    case setup(type: SetupType)
    
    public enum SetupType: String, Equatable {
        case setupLaterOptions // Shows Set Up Later
        case remindMeLaterOptions // Shows Remind Me later,
    }
    
    public var isSetup: Bool {
        switch self {
        case .setup(type: .setupLaterOptions), .setup(type: .remindMeLaterOptions):
            return true
        case .login:
            return false
        }
    }
}
