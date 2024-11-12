//
//  BiometricHelperMethods.swift
//  PaycomESS
//
//  Created by Dave Johnson on 1/17/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

import Authentication
import Foundation
import LocalAuthentication
import Services
import Shared

public class BiometricHelper {
    
    func getBiometricType() -> QuickLoginMethod {
        let context = LAContext()
        var error: NSError?
        let canEvalPolicy = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        if canEvalPolicy {
            if #available(iOS 11.0, *) {
                if context.biometryType == .faceID {
                    return .face
                } else if context.biometryType == .touchID {
                    return .touch
                }
            } else {
                return .touch
            }
        } else {
            return .pin
        }
        
        return .pin
    }
    
    func getBiometricTypeReason() -> String {
        let biometricType = getBiometricType()
        var systemQuickLoginTypeString = ""
        
        switch biometricType {
        case .face:
            systemQuickLoginTypeString =  "Face ID"
        case .touch:
            systemQuickLoginTypeString = "Touch ID"
        case .pin:
            systemQuickLoginTypeString = "a Pin"
        }
        
        let output = "Log in to the Paycom app using \(systemQuickLoginTypeString)®"
        let localizedComment = "Localized kind: \(output)"
        
        return NSLocalizedString(output, comment: localizedComment)
    }
    
    func canEvaluatePolicy() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    func deviceBiometryType() -> String {
        
		guard let loginMethodString = Defaults.standard.loginMethod, let existingLoginMethodFromUserDefaults = QuickLoginMethod(rawValue: loginMethodString) else {
			return NSLocalizedString("PIN", comment: "Localized kind: PIN")
		}
        
        if #available(iOS 11.0, *) {
            switch existingLoginMethodFromUserDefaults {
            case .face:
                return NSLocalizedString("Face ID®", comment: "Localized kind: Face ID®")
            case .touch:
                return NSLocalizedString("Touch ID®", comment: "Localized kind: Touch ID®")
            default:
                return NSLocalizedString("PIN", comment: "Localized kind: PIN")
            }
        } else {
            return NSLocalizedString("Touch ID®", comment: "Localized kind: Touch ID®")
        }
    }
}






















