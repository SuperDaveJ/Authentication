//
//  LoginModel.swift
//  pinEntryUI
//
//  Created by Dave Johnson on 1/15/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

import Foundation
import Shared

public enum LoginScreenIcon {
    
    case Face
    case Touch
    case Pin

    var image: UIImage? {
        switch self {
        case .Face:
            return UIImage(named: "Face-ID_720")
        case .Touch:
            return UIImage(named: "Touch-ID_720")
        case .Pin:
            return nil
        }
    }

    var whiteImage: UIImage? {
        switch self {
        case .Face:
            return UIImage(named: "Face-ID-White_720")
        case .Touch:
            return UIImage(named: "Touch-ID-White_720")
        case .Pin:
            return nil
        }
    }
}

public struct LoginModel {
    var loginScreenWelcomeText: String = ""
    var loginScreenUsername: String = ""
    var loginScreenInstructionText: String = ""
    var loginScreenInstructionTextSwipe: String = ""
    var loginScreenIcon: LoginScreenIcon = .Touch
    var loginScreenOptionButton1: String = ""
    var loginScreenOptionButton1Swipe: String = ""
    var loginScreenOptionButton2: String = ""
    var loginScreenOptionButton3: String = ""
    var loginType: QuickLoginScreenType = .login
    var hasBiometricCapabilities: Bool = false
    var systemLoginType: SystemLoginType? = nil
    
    public init() { }
}



