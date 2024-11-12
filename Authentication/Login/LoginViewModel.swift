//
//  LoginViewModel.swift
//  pinEntryUI
//
//  Created by Dave Johnson on 1/17/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

import Foundation
import Shared

public struct LoginViewModel {
    
    public enum Strings: String {
        case choose4DigitPin = "Please choose a 4-digit PIN"
        case createPinInstead = "Create a PIN instead"
        case doNotAskAgain = "Do not ask again"
        case enter4DigitPinToLogin = "Please enter your 4-digit PIN to login"
        case loginAsOtherUser = "Login as Other User"
        case loginFullCredentials = "You will need to log in using your full credentials to set it up again."
        case loginHelp = "Login Help"
        case loginTips = "Login Tips"
        case recoverUsername = "Recover Username"
        case remindMeLater = "Remind me later"
        case resetPassword = "Reset Password"
        case resetQuickLogin = "Reset Quick Login"
        case resetQuickLoginQuestion = "Are you sure you want to reset your Quick Login?"
        case setupLater = "Set Up Later"
        case tapFaceID = "Tap the Face ID® icon to login"
        case tapIconForFaceID = "Tap the icon to use Face ID®"
        case tapIconForTouchID = "Tap the icon to use Touch ID®"
        case tapTouchID = "Tap the Touch ID® icon to login"
        case useFaceID = "Use Face ID® Instead"
        case useTouchID = "Use Touch ID® Instead"
        case welcomeBack = "Welcome Back"
    }
    
    static func setupLoginPage(quickLoginMethod: QuickLoginMethod, quickLoginType: QuickLoginScreenType, username: String, systemLoginType: SystemLoginType?) -> LoginModel {
        
        var loginModel = LoginModel()
        loginModel.loginType = quickLoginType
        loginModel.loginScreenUsername = username
        loginModel.hasBiometricCapabilities = BiometricHelper().canEvaluatePolicy()
        loginModel.systemLoginType = systemLoginType
        
        switch quickLoginType {
        case .login:
            let localWelcome = Strings.welcomeBack.localized
            loginModel.loginScreenWelcomeText = "\(localWelcome)\(username)"
            loginModel.loginScreenOptionButton1 = Strings.loginAsOtherUser.localized
            loginModel.loginScreenOptionButton2 = Strings.resetQuickLogin.localized
            break
            
        case .setup(let setupType):
            //loginWelcomeBackLabel.isHidden = true
            
            if quickLoginMethod == .face {
                loginModel.loginScreenOptionButton1Swipe = Strings.useFaceID.localized
                loginModel.loginScreenInstructionTextSwipe = Strings.choose4DigitPin.localized
                loginModel.loginScreenOptionButton1 = Strings.createPinInstead.localized
                
            } else if quickLoginMethod == .touch {
                loginModel.loginScreenOptionButton1Swipe = Strings.useTouchID.localized
                loginModel.loginScreenInstructionTextSwipe = Strings.choose4DigitPin.localized
                loginModel.loginScreenOptionButton1 = Strings.createPinInstead.localized
            } else if quickLoginMethod == .pin {
                loginModel.loginScreenOptionButton1Swipe = ""
                loginModel.loginScreenInstructionTextSwipe = ""
                loginModel.loginScreenOptionButton1 = ""
            }
            
            switch setupType {
            case .remindMeLaterOptions:
                loginModel.loginScreenOptionButton2 = Strings.remindMeLater.localized
                loginModel.loginScreenOptionButton3 = Strings.doNotAskAgain.localized
            case .setupLaterOptions:
                loginModel.loginScreenOptionButton2 = Strings.setupLater.localized
            }
            
            break
        }
        
        // Set Page for login method (Face, Touch, PIN)
        
        switch quickLoginMethod {
        case .face:
            loginModel.loginScreenIcon = .Face
            //enterPinButton.isHidden = true
            if quickLoginType == .login {
                loginModel.loginScreenInstructionText = Strings.tapFaceID.localized
            } else {
                loginModel.loginScreenInstructionText = Strings.tapIconForFaceID.localized
            }
            
            break
            
        case .touch:
            loginModel.loginScreenIcon = .Touch
            //pinStackView.isHidden = true
            //enterPinButton.isHidden = true
            if quickLoginType == .login {
                loginModel.loginScreenInstructionText =  Strings.tapTouchID.localized
            } else {
                loginModel.loginScreenInstructionText =  Strings.tapIconForTouchID.localized
            }
            
            break
            
        case .pin:
            //pinScreenIDIconView.isHidden = true
            //pinStackView.isHidden = false
            loginModel.loginScreenIcon = .Pin
            if quickLoginType == .login {
                loginModel.loginScreenInstructionText =  Strings.enter4DigitPinToLogin.localized
            } else {
                loginModel.loginScreenInstructionText =  Strings.choose4DigitPin.localized
            }
            break
        }
        return loginModel
    }
}
