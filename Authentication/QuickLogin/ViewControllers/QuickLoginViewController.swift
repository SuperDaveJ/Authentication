//
//  ViewController.swift
//  pinEntryUI
//
//  Created by Dave Johnson on 1/10/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

import LocalAuthentication
import Shared
import Services
import UIKit

public protocol QuickLoginViewControllerSetupDelegate: class {
    func quickLoginViewControllerDidSetup(_ viewController: QuickLoginViewController?, withPin: Bool)
    func quickLoginViewControllerSetupLater(_ viewController: QuickLoginViewController)
}

public protocol QuickLoginViewControllerLoginDelegate: class {
    func quickLoginViewControllerLoginAsOtherUser(_ viewController: QuickLoginViewController)
    func quickLoginViewControllerLoginSuccess(_ viewController: QuickLoginViewController?, with jsonData: [String], completion: (() -> Void)?)
    func quickLoginViewControllerResetQuickLink(_ viewController: QuickLoginViewController)
    func quickLoginViewControllerDismissPinEntry(_ viewController: QuickLoginViewController)
}

public class QuickLoginViewController: UIViewController {
    
    var pinView: PinEntryView!
    var quickLoginMethod: QuickLoginMethod = .pin
    public var quickLoginScreenType: QuickLoginScreenType!

    var userName: String {
        get {
            return setupUserName()
        }
    }

    lazy var pinSetup = PinSetup()
    lazy var pinLogin = PinLogin()
    lazy var pinDelay = PinDelay()

    static var defaultPinDelay: Double {
        return Double(PinDelayViewController.defaultPinDelay) / 60.0
    }

    var localizedReason = ""
    let pinChain = KeychainFactory.shared.getPinKeychain()
    var attemptBioAuthForFirstAppearance = true
    var willEnterBackground = false
    var appDataReset = false
    var alertVC: UIAlertController?
    public var systemLoginType: SystemLoginType?

    var automaticLoginPref: Bool {
        return Defaults.standard.automaticAuthenticationEnabled
    }

    var savedQuickLoginMethodFromUserDefaults: QuickLoginMethod? = {
		guard let existingLoginMethodRawValue = Defaults.standard.loginMethod else {
			return nil
		}
		
        return QuickLoginMethod(rawValue: existingLoginMethodRawValue)
    }()

    public weak var loginDelegate: QuickLoginViewControllerLoginDelegate?
    public weak var setupDelegate: QuickLoginViewControllerSetupDelegate?
    fileprivate let biometricHelper = BiometricHelper()


    init(quickLoginType: QuickLoginScreenType) {
        super.init(nibName: nil, bundle: nil)
        self.quickLoginScreenType = quickLoginType
    }

    required init?(coder aDecoder: NSCoder) {
       super.init(coder: aDecoder)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear

        // UserDefaults isn't nil and has initialized a valued QuickLoginMethod Instance
        if let existingLoginMethodFromUserDefaults = savedQuickLoginMethodFromUserDefaults {
        //If the user turned off biometrics and the saved loginMethod does not equal Pin
        //that means the user needs to setup Quick Login again to validate using Pin or
        //go into settings and allow biometrics

            if biometricHelper.canEvaluatePolicy() == false && existingLoginMethodFromUserDefaults != .pin {
                quickLoginMethod = existingLoginMethodFromUserDefaults
                // Reset QL
            } else if existingLoginMethodFromUserDefaults == .pin {
                quickLoginMethod = .pin
            } else {
                quickLoginMethod = biometricHelper.getBiometricType()
            }
        } else {
            // Means we're in setup or we coming in from version prior to 2.3.0
            quickLoginMethod = biometricHelper.getBiometricType()
            if quickLoginScreenType == .login {
                Defaults.standard.loginMethod = self.quickLoginMethod.rawValue
                savedQuickLoginMethodFromUserDefaults = QuickLoginMethod(rawValue: self.quickLoginMethod.rawValue)
            }
        }

        resetView()

        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(attemptAuthentication), name: .alertsDidFinishPresenting, object: nil)

        pinView.settingsButton.isHidden = quickLoginScreenType.isSetup
    }

    public func resetView(completion: (() -> Void)? = nil) {
        let loginModel = LoginViewModel.setupLoginPage(quickLoginMethod: quickLoginMethod, quickLoginType: quickLoginScreenType, username: userName, systemLoginType: self.systemLoginType)
        pinView = PinEntryView(loginModel: loginModel)

        pinView.delegate = self
        pinView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.removeAllSubviews()
        self.view.addSubview(pinView)
        completion?()

        NSLayoutConstraint.activate([
            pinView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            pinView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            pinView.topAnchor.constraint(equalTo: self.view.topAnchor),
            pinView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
            ])
        self.view.layoutIfNeeded()

        if let _ = loginModel.systemLoginType {
            localizedReason = biometricHelper.getBiometricTypeReason()
        }
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // This ensures that biometric auth isn't automatically attempted because of an observer
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    @objc func resetQuickLogin() {
        dismiss(animated: true, completion: nil)
        self.pinDelay.resetPinAttemptsAndTime()
        self.loginDelegate?.quickLoginViewControllerResetQuickLink(self)
    }

    @objc func didBecomeActive() {
        // make sure this view controller is on the screen
        willEnterBackground = false
        guard navigationController?.visibleViewController == self else { return }

        timeoutIfNeeded()
        attemptAuthentication()
    }

    private func timeoutIfNeeded() {
        if quickLoginScreenType.isSetup && SessionCheckDelay.shared.isSessionCheckDelayed() == false {
            self.presentTimeoutWarning()
        }
    }

    @objc private func attemptAuthentication(with notification: Notification? = nil) {
        guard !Services.shared.alertPresenter.isPresenting else { return }

        let didOpenAnotherApp = notification?.userInfo?[AlertUserInfoKey.didOpenAnotherApp] as? Bool ?? false

        // When leaving an app and coming back this makes sure that pinView has a keyboard showing
        if pinView.lastSwiped == .toPin || (quickLoginMethod == .pin && quickLoginScreenType == .login) {
            pinView.pinDotsWhereTapped()
        }

        if canLoginWithBiometric() && !didOpenAnotherApp {
            attemptBiometricAuth()
            attemptBioAuthForFirstAppearance = false
            QuickLoginViewLifecycleHelper.shared.alreadyPrompted = true
        }

        pinView.restartAnimation()
    }

    private func presentTimeoutWarning() {
        Services.shared.simpleAlert.showOK(
            title: "Session Expired".localized,
            message: "Your session expired due to inactivity. Please log in again.".localized) {
                self.dismiss(animated: true)
        }
    }

    private func canLoginWithBiometric() -> Bool {
        guard let existingLoginMethod = savedQuickLoginMethodFromUserDefaults else { return false }
        guard attemptBioAuthForFirstAppearance else { return false }
        guard automaticLoginPref else { return false }

        return existingLoginMethod != .pin
    }

    @objc func didEnterBackground() {
        willEnterBackground = true
        SessionCheckDelay.shared.waitFiveMinutes()

        let context = LAContext()
        context.invalidate()

        attemptBioAuthForFirstAppearance = true

        if self.presentedViewController == alertVC {
            alertVC?.dismiss(animated: false)
        }
		
		Services.shared.auditService.recordInfo(.movedToBackground, with: [EventDetailKey.from: "QuickLoginViewController"])
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func checkRemainingDelayTime() {
        if pinDelay.isPinEntryDelayed() {
             displayDelayPage()
        }
    }

    func displayDelayPage(){
        pinView.togglePinFailTimeDelayDisplay()
        self.performSegue(withIdentifier: "PinDelaySegue", sender: self)
    }

    override public func viewWillDisappear(_ animated: Bool) {
        pinView.stopAnimation()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Clear pin keychain and variables if pin doesn't exist
        if quickLoginMethod == .pin && Defaults.standard.hasSetUpQuickLogin {
            do {
                let pinChain = KeychainFactory.shared.getPinKeychain()
                try pinChain.loadData()
                showKeyboard()
            } catch KeychainError.itemNotFound {
                clearQuickLogin()
                showClearingKeychainAlert()
                return
            } catch { }
        }

        if mustBeSettingUpPin() {
            showKeyboard()
        }

        // Check if under time restriction for failed PIN attempt
        checkRemainingDelayTime()

        beginAnimation()

        guard let existingLoginMethodFromUserDefaults = savedQuickLoginMethodFromUserDefaults else { return }

        if biometricHelper.canEvaluatePolicy() == false && existingLoginMethodFromUserDefaults != .pin {
            presentPermissionsChangedAlert()
            pinView.returnFullScreen()
        } else if automaticLoginPref == true && (existingLoginMethodFromUserDefaults == .face || existingLoginMethodFromUserDefaults == .touch) {
            guard attemptBioAuthForFirstAppearance,
                QuickLoginViewLifecycleHelper.shared.alreadyPrompted == false
                else { return }

            guard self.willEnterBackground == false else { return }
            guard !Services.shared.alertPresenter.isPresenting else { return }

            self.attemptBiometricAuth()
            self.attemptBioAuthForFirstAppearance = false
            QuickLoginViewLifecycleHelper.shared.alreadyPrompted = true
        }
    }

    public func showKeyboard() {
        guard
            !Services.shared.alertPresenter.isPresenting,
            pinIsSetup() || mustBeSettingUpPin()
        else {
            return
        }

        pinView.pinDotsView.becomeFirstResponder()
    }

    public func beginAnimation() {
        pinView.beginAnimation()
    }

    private func presentPermissionsChangedAlert() {
        let deviceBiometricType = biometricHelper.deviceBiometryType()
        let message = String(format: "You will need to set up Quick Login again. If you wish to use %@ again, please adjust your permissions in your device settings.".localized, deviceBiometricType)
        let alertVC = UIAlertController(title: String(format: "%@ permissions have changed.".localized, deviceBiometricType), message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK".localized, style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.loginDelegate?.quickLoginViewControllerResetQuickLink(self)
        }
        alertVC.addAction(okAction)
        present(alertVC, animated: true)
    }

    private func pinIsSetup() -> Bool {
        return quickLoginMethod == .pin && Defaults.standard.hasSetUpQuickLogin
    }

    private func mustBeSettingUpPin() -> Bool {
        return !biometricHelper.canEvaluatePolicy() && quickLoginScreenType.isSetup
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }

    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PinDelaySegue", let pinDelayVC = segue.destination as? PinDelayViewController {
            pinDelayVC.delegate = self
        }
    }

    public func hidePinScreenIDIconView() {
        pinView.pinScreenIDIconView.isHidden = true
    }

    public func showPinScreenIDIconView() {
        pinView.pinScreenIDIconView.isHidden = false
    }

    fileprivate func attemptBiometricAuth() {
        if quickLoginScreenType == .login {
            attemptToLogInWithBiometric()
        } else if quickLoginScreenType.isSetup {
            attemptToSetUpBiometric()
        }
    }

    private func attemptToLogInWithBiometric() {
        guard savedQuickLoginMethodFromUserDefaults == .face || savedQuickLoginMethodFromUserDefaults == .touch else { return }
        
        self.pinView.stopAnimation()
        self.loadFromKeychainInBackground { [weak self] result in
            guard let self = self else { return }
            
            self.pinView.restartAnimation()
            switch result {
            case .success(let json):
                let loginMethod = self.savedQuickLoginMethodFromUserDefaults?.loginMethodForEvent() ?? "MANUAL"
                
                let eventDetails = [
                    EventDetailKey.system: self.systemLoginType?.toAppEventValue() ?? "undefined",
                    EventDetailKey.loginMethod: loginMethod
                ]
                
                Services.shared.auditService.recordInfo(.userLoggedIn, with: eventDetails)
                
                self.loginDelegate?.quickLoginViewControllerLoginSuccess(self, with: json, completion: nil)
            case .failure(KeychainError.itemNotFound):
                self.clearQuickLogin()
                self.showClearingKeychainAlert()
            case .failure(KeychainError.unexpectedItemData):
                self.clearQuickLogin()
                self.showClearingKeychainAlert()
            case .failure(KeychainError.unhandledError(let status)):
                if status == errSecUserCanceled {
                    self.presentAuthenticationCancelledAlert()
                } else {
                    // Don't delete keychain, because unsure what all could stop it
                    self.showUnknownAuthenticationAlert()
                }
            case .failure:
                // Don't delete keychain, because unsure what all could stop it
                self.showUnknownAuthenticationAlert()
            }
        }
    }
    
    private func loadFromKeychainInBackground(completion: @escaping (Result<[String], Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let json = try KeychainFactory.shared.getBiometricKeychain().loadJsonWith(reason: self.localizedReason)
                DispatchQueue.main.async {
                    completion(.success(json))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    private func attemptToSetUpBiometric() {
        let context = LAContext()
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: localizedReason, reply: { [weak self] (isAuthenticated, error) in
            guard let self = self else { return }
            if isAuthenticated {
				Defaults.standard.loginMethod = self.quickLoginMethod.rawValue
                QuickLoginViewLifecycleHelper.shared.alreadyPrompted = true
                self.setupDelegate?.quickLoginViewControllerDidSetup(self, withPin: false)
            } else {
                // If the user denided the app biometric capabilities this will appear when the biometric image is pressed
                self.presentInvalidatedBiometricAlert()
            }
        })
    }

    private func presentAuthenticationCancelledAlert() {
        let alertVC = UIAlertController(title: "Authentication Cancelled".localized, message: "Please touch the icon again.".localized, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK".localized, style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            // Restart bio animation on page
            self.pinView.restartAnimation()
        })

        alertVC.addAction(okAction)
        self.present(alertVC, animated: false)
    }

    private func presentInvalidatedBiometricAlert() {
        let message = "Your Face ID® or Touch ID® login has been invalidated and must be activated again. This may have been caused by denying permissions, removing fingerprints, or turning off Face ID®".localized
        let alertVC = UIAlertController(title: "Attention".localized,message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "Localized kind: OK"), style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            // Reset Stored Credentials so that next login will force set up of Quick Login again
            self.pinView.switchToEntryMethod(sender: nil)
            self.pinDelay.resetPinAttemptsAndTime()
        })

        alertVC.addAction(okAction)
        DispatchQueue.main.async {
            self.present(alertVC, animated: true)
        }
    }

    // MARK: - Helpers
    private func setupUserName() -> String {
        var usersName: String = "."

        if let userConfiguration = SettingsManager.shared.userConfiguration {
            usersName = ", \(userConfiguration.userDisplayName)."
        } else if let oldSavedUsername = Defaults.standard.userName {
            usersName = oldSavedUsername
        }
        return usersName
    }

    private func clearQuickLogin() {
        BackupRestore.resetApp()
    }

    fileprivate func showClearingKeychainAlert() {
        let message = "For security reasons, you must manually authenticate again.".localized
        let alertVC = UIAlertController(title: "Authentication Required".localized, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK".localized, style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            self.resetQuickLogin()
        })

        alertVC.addAction(okAction)
        self.alertVC = alertVC
        present(alertVC, animated: false)
    }

    private func showUnknownAuthenticationAlert() {
        let message = "Unknown authentication error. Please try again.".localized
        let alertVC = UIAlertController(title: "Authentication Error".localized, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK".localized, style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            // Restart bio animation on page
            self.pinView.restartAnimation()
        })

        alertVC.addAction(okAction)
        self.present(alertVC, animated: false)
    }
}

// MARK: - PinEntryViewDelegate
extension QuickLoginViewController: PinEntryViewDelegate {

    func pinEntryViewDidSwipeAwayFromPin(_ sender: PinEntryView) {
        pinSetup.resetFirst()
    }

    func pinEntryViewSetUpLaterButtonWasTapped(_ sender: PinEntryView) {
        sender.pinDotsView.resignFirstResponder()
        self.setupDelegate?.quickLoginViewControllerSetupLater(self)
    }

    func pinEntryViewCancelButtonWasTapped(_ sender: PinEntryView) {
        self.loginDelegate?.quickLoginViewControllerDismissPinEntry(self)
    }

    func pinEntryViewResetQuickLinkButtonWasTapped(_ sender: PinEntryView) {
        let title = "Are you sure you want to reset your Quick Login?".localized
        let message = "You will need to log in using your full credentials to set it up again.".localized
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK".localized, style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.pinDelay.resetPinAttemptsAndTime()
            self.loginDelegate?.quickLoginViewControllerResetQuickLink(self)
        }
        let cancelAction = UIAlertAction(title: "Cancel".localized, style: .default) { [weak self] _ in
            guard let self = self else { return }
            if self.quickLoginMethod == .pin {
                sender.pinDotsView.becomeFirstResponder()
            }
        }

        alertVC.addAction(cancelAction)
        alertVC.addAction(okAction)
        self.view.endEditing(true)
        present(alertVC, animated: true)
    }

    func pinEntryViewBiometricButtonWasTapped(_ sender: PinEntryView) {
        attemptBiometricAuth()
        self.attemptBioAuthForFirstAppearance = false
    }

    func pinEntryView(_ sender: PinEntryView, didEnter pin: String) {
		
        // I.e. the user is logging in as opposed to setting up QuickLogin.
        if pinView.loginType == .login {
            attemptToLogUserIn(sender: sender, pin: pin)
        } else if pinView.loginType.isSetup {
            attemptToSetUpAndSavePin(sender: sender, pin: pin)
        }
    }

    private func attemptToLogUserIn(sender: PinEntryView, pin: String) {
        let pinChain = KeychainFactory.shared.getPinKeychain()

        do {
            try pinLogin.enteredPinMatchesSavedPin(pin)

            sender.validPin()
            sender.updateInstructionLabel = "PIN Confirmed".localized
            sender.loginWelcomeBackLabel.fadeOut()

            // reason doesn't matter for PIN logins
            let data = try KeychainFactory.shared.getBiometricKeychain().loadJsonWith(reason: "")
            
            let eventDetails = [
                EventDetailKey.system: self.systemLoginType?.toAppEventValue() ?? "undefined",
                EventDetailKey.loginMethod: QuickLoginMethod.pin.rawValue
            ]

            Services.shared.auditService.recordInfo(.userLoggedIn, with: eventDetails)
            
            self.loginDelegate?.quickLoginViewControllerLoginSuccess(self, with: data, completion: nil)
        } catch PinLoginError.incorrectPin {
            sender.invalidPin()
			Services.shared.auditService.recordError(.incorrectPin)
			
        } catch PinLoginError.warnAboutReset {
            presentResetWarning()
			Services.shared.auditService.recordError(.pinAttemptsWarn)
			
        } catch PinLoginError.exceededNumberOfLoginAttempts {
            do {
                try pinChain.deleteItem()
            } catch {
                error.record(.keyChainItemFailure)
            }

            sender.updateInstructionLabel = "PIN Failed. Too Many Attempts".localized
            sender.alternateOptions1Button.isHidden = true
            presentExceededNumberOfLoginAttemptsAlert()
			Services.shared.auditService.recordError(.pinAttemptsExceeded)
			
        } catch PinLoginError.exceededInitialLoginAttemptLimit {
            pinDelay.waitFiveMinutes()
            displayDelayPage()
			Services.shared.auditService.recordError(.pinAttemptsExceededInitial)
			
        } catch let error {
            presentGenericInvalidPinError()
			error.record(.unknownError)
        }
    }

    private func attemptToSetUpAndSavePin(sender: PinEntryView, pin: String) {
        let pinChain = KeychainFactory.shared.getPinKeychain()

        if pinSetup.firstPinEntry == nil {
            pinSetup.enterFirst(pin)
            sender.updateInstructionLabel = String(format: "Confirm %d-digit PIN".localized, pinView.numberOfPins.rawValue)
        } else {
            do {
                try pinSetup.enterSecond(pin)
                // Pins Match ... Handle Authorization
                sender.updateInstructionLabel = "PIN Confirmed".localized
                sender.loginWelcomeBackLabel.fadeOut()
                sender.alternateOptions1Button.isHidden = true
                sender.pinDotsView.resignFirstResponder()

                do {
                    try pinChain.save(string: pin)
                } catch {
                    presentErrorSavingPinAlert()
                    error.record(.pinSaveError)
                }
                
				Defaults.standard.loginMethod = QuickLoginMethod.pin.rawValue
                self.setupDelegate?.quickLoginViewControllerDidSetup(self, withPin: true)
            } catch {
                sender.invalidPin()
                sender.updateInstructionLabel = "PINs did not match. Enter PIN again.".localized
            }
        }
    }

    private func presentResetWarning() {
        pinDelay.waitFiveMinutes()
        pinView.togglePinFailTimeDelayDisplay()
        pinView.endEditing(true)

        let pinDelayTimeElapsed = pinDelay.getRemainingDelayTime()
        let timeRemaining = Int(QuickLoginViewController.defaultPinDelay - pinDelayTimeElapsed) + 1
        let timeText = timeRemaining < 2 ? "minute".localized : "minutes".localized
        let messagePart1 = "For your security, any additional PIN failures will reset your Quick Login.".localized
        let messagePart2 = "Please wait".localized
        let messagePart3 = "and try again.".localized
        let alertVC = UIAlertController(
            title: "Security Alert".localized,
            message: "\(messagePart1) \(messagePart2) \(timeRemaining) \(timeText) \(messagePart3)",
            preferredStyle: .alert
        )

        let okAlertButton = UIAlertAction(title: "OK".localized, style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            self.displayDelayPage()
        })

        alertVC.addAction(okAlertButton)
        present(alertVC, animated: true, completion: nil)
    }

    private func presentExceededNumberOfLoginAttemptsAlert() {
        let message = "Please login and set your Quick Login credentials again.".localized
        let alertVC = UIAlertController(title: "Too Many Pin Attempts".localized, message: message, preferredStyle: .alert)
        let okAlertButton = UIAlertAction(title: "OK".localized, style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            AppDataReset.resetQuickLogin()
            self.loginDelegate?.quickLoginViewControllerResetQuickLink(self)
            self.dismiss(animated: false, completion: nil)
        })

        alertVC.addAction(okAlertButton)
        //presenting it from rootviewcontroller to avoid background color discrepancy during keyboard dismissal
        if let alertWindow = UIApplication.shared.windows.last {
            alertWindow.rootViewController?.present(alertVC, animated: true, completion: nil)
        } else {
            present(alertVC, animated: true, completion: nil)
        }
    }

    private func presentGenericInvalidPinError() {
        guard Services.shared.connectivityManager.isConnected() else {
            Services.shared.connectivityManager.presentConnectionAlertIfNeeded()
            return
        }

        let message = "Please contact Paycom if this error keeps occurring.".localized
        let alertVC = UIAlertController(title: "Invalid PIN".localized, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK".localized, style: .default, handler: nil)
        alertVC.addAction(okAction)
        self.present(alertVC, animated: true)
    }

    private func presentErrorSavingPinAlert() {
        let message = "There was a problem saving your PIN. Please contact Paycom if this error keeps occurring.".localized
        let alertVC = UIAlertController(title: "PIN Error".localized, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK".localized, style: .default, handler: nil)
        alertVC.addAction(okAction)
        self.present(alertVC, animated: true)
    }
}

extension QuickLoginViewController: PinDelayButtonPressDelegate {
    func pinDelayScreenWasDismissed() {
        pinView.returnAfterDelay()
    }

    func pinDelayOtherUserButtonTapped(sender: PinDelayViewController, OtherUserButton: UIButton) {
        sender.dismiss(animated: true, completion: nil)
        self.loginDelegate?.quickLoginViewControllerLoginAsOtherUser(self)
    }

    func pinDelayResetQuickLinkButtonTapped(sender: PinDelayViewController, ResetQuickLinkButton: UIButton) {
        self.loginDelegate?.quickLoginViewControllerResetQuickLink(self)
        sender.dismiss(animated: false, completion: nil)
    }
}

extension QuickLoginViewController: Storyboarded {
    public static let storyboardName: StoryboardName = .quickLogin
}
