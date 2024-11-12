//
//  PinEntryView.swift
//  pinEntryUI
//
//  Created by Dave Johnson on 1/10/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

import Services
import Shared
import UIKit

public enum QuickLoginMethod: String {
    case face = "face"
    case touch = "touch"
    case pin = "pin"
    
    func loginMethodForEvent() -> String {
        switch self {
        case .face:
            return "FACE"
        case .touch:
            return "FINGERPRINT"
        case .pin:
            return "PIN"
        }
    }
}

enum LastSwipe {
    case toPin
    case toBiometric
}

enum NumberOfPins: Int {
    case four = 4
    case six = 6
}

protocol PinEntryViewDelegate: class {
    func pinEntryView(_ sender: PinEntryView, didEnter pin: String)
    func pinEntryViewBiometricButtonWasTapped(_ sender: PinEntryView)
    func pinEntryViewSetUpLaterButtonWasTapped(_ sender: PinEntryView)
    func pinEntryViewResetQuickLinkButtonWasTapped(_ sender: PinEntryView)
    func pinEntryViewDidSwipeAwayFromPin(_ sender: PinEntryView)
    func pinEntryViewCancelButtonWasTapped(_ sender: PinEntryView)
}

class PinEntryView: UIView {
    // MARK: - Set Initial Variables
    let alternateOptions1Button: UIButton
    let alternateOptions2Button: UIButton
    let alternateOptions3Button: UIButton
    var setupOptionsStackView: UIStackView!
    
    var containerBottomViewConstraint: NSLayoutConstraint!
    var logoHeightConstraint: NSLayoutConstraint!
    var logoWidthConstraint: NSLayoutConstraint!
    var logoTopConstraint: NSLayoutConstraint!
    var pinScreenIDIconCenterConstraint: NSLayoutConstraint!
    var confirmationPINLabelConstraint: NSLayoutConstraint!
    var loginWelcomeBackLabelConstraint: NSLayoutConstraint!
    
    var pinEntryDotsViewCenterConstraint: NSLayoutConstraint = NSLayoutConstraint() {
        willSet { NSLayoutConstraint.deactivate([pinEntryDotsViewCenterConstraint]) }
        didSet { NSLayoutConstraint.activate([pinEntryDotsViewCenterConstraint]) }
    }
    
    var setupOptionsConstraints: [NSLayoutConstraint] = [] {
        willSet {
            NSLayoutConstraint.deactivate(setupOptionsConstraints)
        }
        didSet {
            NSLayoutConstraint.activate(setupOptionsConstraints)
        }
    }

    var loginType: QuickLoginScreenType = .login
    var loginModel = LoginModel()
    weak var delegate: PinEntryViewDelegate?
    var lastSwiped: LastSwipe = .toBiometric
    var numberOfPins: NumberOfPins = .four
    var toggle6Pin: Bool = false
    var pinDelay = PinDelay()
    var keyboardHeight: CGFloat?
    
    private var animationTime: Double = 0.33

    var updateInstructionLabel = ""{
        didSet {
            if updateInstructionLabel == NSLocalizedString("PIN Confirmed", comment: "Localized kind: PIN Confirmed") {
                authenticationTypeInstructionsLabel.isHidden = true
                alternateOptions2Button.isHidden = true
                confirmationPinLabel.text = updateInstructionLabel
            } else {
                authenticationTypeInstructionsLabel.isHidden = true
                confirmationPinLabel.isHidden = false
                confirmationPinLabel.text = updateInstructionLabel
            }
        }
    }
    
    // MARK: - Set Up Page Views
    let containerView: UIView = {
        var containerView = UIView(frame: .zero)
        containerView.backgroundColor = .clear
        containerView.translatesAutoresizingMaskIntoConstraints = false
        return containerView
    }()
    
    let pinScreenLogoView: UIImageView = {
        var pinScreenLogoView = UIImageView(frame: .zero)
        pinScreenLogoView.image = UIImage(named: "Paycom_Logo_Green")
        return pinScreenLogoView
    }()
    
    let loginBackgroundImageView: UIImageView = {
        var loginBackgroundImageView = UIImageView(frame: .zero)
        loginBackgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        loginBackgroundImageView.image = UIImage(named: "launch-X-white")
        loginBackgroundImageView.contentMode = UIView.ContentMode.scaleAspectFill
        return loginBackgroundImageView
    }()

    let loginWelcomeBackLabel: PaycomUILabel = {
        var loginWelcomeBackLabel = PaycomUILabel()
        loginWelcomeBackLabel.text = NSLocalizedString("Welcome back", comment: "Localized kind: Welcome back")
        loginWelcomeBackLabel.textColor = PaycomNamedColor.darkGrayAdaptive.color
        loginWelcomeBackLabel.font = UIFont.systemFont(ofSize: 20)
        return loginWelcomeBackLabel
    }()
    
    let authenticationTypeInstructionsLabel: UILabel = {
        var authenticationTypeInstructionsLabel = UILabel(frame: .zero)
        authenticationTypeInstructionsLabel.text = NSLocalizedString("Touch the Face ID® Button To Authenticate", comment: "Localized kind: Touch the Face ID® Button To Authenticate")
        authenticationTypeInstructionsLabel.textColor = PaycomNamedColor.darkGrayAdaptive.color
        authenticationTypeInstructionsLabel.textAlignment = .center
        authenticationTypeInstructionsLabel.font = UIFont.systemFont(ofSize: 20)
        authenticationTypeInstructionsLabel.adjustsFontSizeToFitWidth = true
        return authenticationTypeInstructionsLabel
    }()
    
    let pinScreenIDIconView: UIButton = {
        var pinScreenIDIconView = UIButton(frame: .zero)
        let image = UIImage(named: "Face-ID_720.png") as UIImage?
        pinScreenIDIconView.setImage(image, for: .normal)
        pinScreenIDIconView.addTarget(self, action: #selector(biometricAuthenticate), for: .touchUpInside)
        pinScreenIDIconView.isAccessibilityElement = true
        pinScreenIDIconView.accessibilityLabel = NSLocalizedString("Activate Face ID", comment: "Localized kind: Activate Face ID")
        return pinScreenIDIconView
    }()
    
    let confirmationPinLabel: UILabel = {
        var confirmationPinLabel = UILabel()
        confirmationPinLabel.text = NSLocalizedString("Confirm 4-digit PIN", comment: "Localized kind: Confirm 4-digit PIN")
        confirmationPinLabel.isAccessibilityElement = true
        confirmationPinLabel.textColor = .white
        confirmationPinLabel.textAlignment = .center
        confirmationPinLabel.isHidden = true 
        return confirmationPinLabel
    }()
    
    var pinDotsViewArray: [PinEntryDotView] = {
        var pinDotView: [PinEntryDotView] = []
        for i in 0..<4 {
            pinDotView.append(PinEntryDotView())
            pinDotView[i].widthAnchor.constraint(equalToConstant: 15).isActive = true
            pinDotView[i].heightAnchor.constraint(equalToConstant: 15).isActive = true
        }
        return pinDotView
    }()
    
    var pin4DotsViewArray: [PinEntryDotView] = {
        var pin4DotView: [PinEntryDotView] = []
        for i in 0..<4 {
            pin4DotView.append(PinEntryDotView())
            pin4DotView[i].widthAnchor.constraint(equalToConstant: 15).isActive = true
            pin4DotView[i].heightAnchor.constraint(equalToConstant: 15).isActive = true
        }
        return pin4DotView
    }()
    
    let pin6DotsViewArray: [PinEntryDotView] = {
        var pin6DotView: [PinEntryDotView] = []
        for i in 0..<6 {
            pin6DotView.append(PinEntryDotView())
            pin6DotView[i].widthAnchor.constraint(equalToConstant: 15).isActive = true
            pin6DotView[i].heightAnchor.constraint(equalToConstant: 15).isActive = true
        }
        return pin6DotView
    }()
    
    let pinDotsView: PinEntryDotsView = {
        var stackView = PinEntryDotsView(frame: .zero)
        stackView.axis = .horizontal
        stackView.spacing = 25
        return stackView
    }()
    
    let enterPinButton: UIButton = {
        var enterPinButton = UIButton(frame: .zero)
        enterPinButton.setTitle(NSLocalizedString("Enter PIN", comment: "Localized kind: Enter PIN"), for: .normal)
        enterPinButton.setTitleColor(.white, for: .normal)
        enterPinButton.titleLabel?.font = UIFont(name: "Helvetica", size: 14)
        enterPinButton.isHidden = true
        enterPinButton.addTarget(self, action: #selector(pinButtonAction), for: .touchUpInside)
        return enterPinButton
    }()

    let loginOptionsImage: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        imageView.image = UIImage(named: "Gear_icon_svg.svg")
        // to enable voiceover for settings
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = NSLocalizedString("Settings", comment: "Localized kind: Settings")
        return imageView
    }()
    
    let loginOptonsText: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = .white
        label.text = NSLocalizedString("Options", comment: "Localized kind: Options")
        return label
    }()
    
    let settingsButton: UIButton = {
        let settings = UIButton(frame: .zero)
        settings.setTitle("Settings".localized, for: .normal)
        settings.setTitleColor(PaycomNamedColor.darkGrayAdaptive.color, for: .normal)
        settings.setTitleColor(PaycomNamedColor.launchButtonHighlight.color, for: .highlighted)
        settings.titleLabel?.font = .systemFont(ofSize: 20)
        settings.isHidden = false
        settings.addTarget(self, action: #selector(showQuickLoginSettings), for: .touchUpInside)
        return settings
    }()
    
    let loginOptionsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = UIStackView.Distribution.equalSpacing
        stackView.alignment = UIStackView.Alignment.center
        stackView.spacing = 10
        return stackView
    }()

    // MARK: - Initialization Calls
    init(loginModel: LoginModel) {
        
        // Active if we add 6 PIN option
        if toggle6Pin {
            numberOfPins = .six
        }
        
        alternateOptions1Button = Self.makeQLSetupButtonOption()
        alternateOptions2Button = Self.makeQLSetupButtonOption()
        alternateOptions3Button = Self.makeQLSetupButtonOption()
        
        super.init(frame: .zero)
        self.loginModel = loginModel
        
        if loginModel.loginScreenIcon == .Touch {
            pinScreenIDIconView.isAccessibilityElement = true
            pinScreenIDIconView.accessibilityLabel = NSLocalizedString("Activate Touch ID", comment: "Localized kind: Activate Touch ID")
        }
        
        backgroundColor = UIColor.clear
        
        self.loginType = loginModel.loginType
        pinScreenIDIconView.setImage(loginModel.loginScreenIcon.image, for: .normal)
        
        // Set Initial Text
        authenticationTypeInstructionsLabel.text = loginModel.loginScreenInstructionText
        alternateOptions1Button.setTitle(loginModel.loginScreenOptionButton1, for: .normal)
        alternateOptions2Button.setTitle(loginModel.loginScreenOptionButton2, for: .normal)
        alternateOptions3Button.setTitle(loginModel.loginScreenOptionButton3, for: .normal)
        
        let tapPinDots = UITapGestureRecognizer(target: self, action: #selector(PinEntryView.pinDotsWhereTapped))
        pinDotsView.addGestureRecognizer(tapPinDots)
        
        setupOptions(for: loginType)

        pinDotsView.delegate = self

        // Add Container View
        addSubview(containerView)
        containerView.addSubview(loginBackgroundImageView)
        
        // Add Subviews
        pinDotsViewArray.forEach{pinDotsView.addArrangedSubview($0)}
        
        // Call to switch to 4 or 6 PIN (Not currently an option) 
        //togglePinDotCount()
        if !loginModel.hasBiometricCapabilities || loginModel.loginScreenIcon == .Pin {
            pinScreenIDIconView.isHidden = true
            pinDotsView.isHidden = false
        }
        
        setLayout()
        listenForKeyboardToRaise()
        setColorsForLoggingIntoSystem(loginModel.systemLoginType)
    }

    /// Sets the background image to indicate the given system, then changes colors/images to match that new background.
    private func setColorsForLoggingIntoSystem(_ systemLoginType: SystemLoginType?) {
        guard let systemLoginType = systemLoginType else { return }
        loginBackgroundImageView.image = UIImage(named: systemLoginType.rawValue)
        loginWelcomeBackLabel.textColor = .white
        authenticationTypeInstructionsLabel.textColor = .white
        pinScreenLogoView.image = UIImage(named: "Paycom_Logo_White")
        pinScreenLogoView.tintColor = PaycomNamedColor.paycomLogoWhite.color
        pinDotsViewArray.forEach { $0.dotColor = .white }
        pinScreenIDIconView.setImage(loginModel.loginScreenIcon.whiteImage, for: .normal)
    }
    
    func beginAnimation() {
        self.pinScreenIDIconView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        
        UIView.animate(withDuration: 0.5, delay:0, options: [.repeat, .autoreverse, .allowUserInteraction], animations: {
            self.pinScreenIDIconView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }, completion: nil)
    }
    
    func restartAnimation() {
        self.pinScreenIDIconView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        self.pinScreenIDIconView.layer.removeAllAnimations()
        
        UIView.animate(withDuration: 0.5, delay:0, options: [.repeat, .autoreverse, .allowUserInteraction, .beginFromCurrentState], animations: {
            self.pinScreenIDIconView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }, completion: nil)
    }
    
    func stopAnimation() {
        self.pinScreenIDIconView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        self.pinScreenIDIconView.layer.removeAllAnimations()
    }
    
    @objc func pinDotsWhereTapped() {
        pinDotsView.becomeFirstResponder()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        guard loginModel.hasBiometricCapabilities else { return }
        
        if let superView = superview {
            pinEntryDotsViewCenterConstraint = pinDotsView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor, constant: superView.frame.width)
            pinEntryDotsViewCenterConstraint.isActive = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if !loginModel.hasBiometricCapabilities || loginModel.loginScreenIcon == .Pin {
            pinEntryDotsViewCenterConstraint = pinDotsView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Update PIN dot count
    func togglePinDotCount() {
        toggle6Pin = !toggle6Pin
        
        if toggle6Pin {
            numberOfPins = .six
            pinDotsViewArray.forEach{pinDotsView.removeArrangedSubview($0)}
            pinDotsViewArray = pin6DotsViewArray
            pinDotsViewArray.forEach{pinDotsView.addArrangedSubview($0)}
        } else {
            numberOfPins = .four
            pinDotsViewArray.forEach{pinDotsView.removeArrangedSubview($0)}
            pinDotsViewArray = pin4DotsViewArray
            pinDotsViewArray.forEach{pinDotsView.addArrangedSubview($0)}
        }
    }
    
    func togglePinFailTimeDelayDisplay() {
        authenticationTypeInstructionsLabel.isHidden = true
        loginWelcomeBackLabel.isHidden = true
        pinDotsView.isHidden = true
        alternateOptions2Button.isHidden = true
        alternateOptions3Button.isHidden = true
        confirmationPinLabel.isHidden = true
        alternateOptions1Button.isHidden = true
        pinDotsView.isEnabled = false
        settingsButton.isHidden = true
        returnFullScreen()
    }
    
    // Swipe Gesture
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizer.Direction.left:
                if lastSwiped == .toBiometric {
                    switchToEntryMethod(sender: nil)
                    lastSwiped = .toPin
                }
                
            case UISwipeGestureRecognizer.Direction.right:
                if lastSwiped == .toPin {
                    switchToEntryMethod(sender: nil)
                    lastSwiped = .toBiometric
                }
                
            default:
                break
            }
        }
    }
    
    // Animate Screen Elements for view with keyboard raised
    func shrinkToPinScreen(_ keyboardHeight:CGFloat, duration time: Double) {
        if !pinDelay.isPinEntryDelayed() {
            NSLayoutConstraint.deactivate([
                self.containerBottomViewConstraint,
                self.logoWidthConstraint,
                self.logoHeightConstraint,
                self.logoTopConstraint,
                self.loginWelcomeBackLabelConstraint
            ])
            
            self.containerBottomViewConstraint =
                self.containerView.bottomAnchor.constraint(
                    equalTo: self.bottomAnchor,
                    constant: -keyboardHeight)
            
            self.logoHeightConstraint = self.pinScreenLogoView.heightAnchor.constraint(equalToConstant: 55)
            self.logoWidthConstraint = self.pinScreenLogoView.widthAnchor.constraint(equalToConstant: 214)
            self.logoTopConstraint = self.pinScreenLogoView.topAnchor.constraint(equalTo: self.containerView.safeTopAnchor, constant: 30)

            self.loginWelcomeBackLabelConstraint = loginWelcomeBackLabel.topAnchor.constraint(equalTo: pinDotsView.topAnchor, constant: -75)
            
            NSLayoutConstraint.activate([
                self.containerBottomViewConstraint,
                self.logoWidthConstraint,
                self.logoHeightConstraint,
                self.logoTopConstraint,
                self.loginWelcomeBackLabelConstraint
            ])
            
            UIView.animate(withDuration: time, animations: {
                self.layoutIfNeeded()
            })
        }
    }
    
    // Animate Screen Elements for view with keyboard lowered
    func returnFullScreen() {
        NSLayoutConstraint.deactivate([
            self.containerBottomViewConstraint,
            self.logoWidthConstraint,
            self.logoHeightConstraint,
            self.logoTopConstraint,
            self.loginWelcomeBackLabelConstraint
        ])
        
        self.containerBottomViewConstraint = self.containerView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0)
        
        self.logoHeightConstraint = self.pinScreenLogoView.heightAnchor.constraint(equalToConstant: 80)
        self.logoWidthConstraint = self.pinScreenLogoView.widthAnchor.constraint(equalToConstant: 294)
        self.logoTopConstraint = self.pinScreenLogoView.topAnchor.constraint(equalTo: self.containerView.safeTopAnchor, constant: 8)
        
        self.loginWelcomeBackLabelConstraint = loginWelcomeBackLabel.topAnchor.constraint(equalTo: pinDotsView.topAnchor, constant: -175)
        
        NSLayoutConstraint.activate([
            self.containerBottomViewConstraint,
            self.logoWidthConstraint,
            self.logoHeightConstraint,
            self.logoTopConstraint,
            self.loginWelcomeBackLabelConstraint
        ])
        
        UIView.animate(withDuration: animationTime, animations: {
            self.layoutIfNeeded()
        })
    }
    
    func returnAfterDelay() {
        authenticationTypeInstructionsLabel.isHidden = false
        loginWelcomeBackLabel.isHidden = false
        pinDotsView.isHidden = false
        confirmationPinLabel.isHidden = true
        pinDotsView.isEnabled = true
        settingsButton.isHidden = false
        pinDotsView.becomeFirstResponder()
    }
    
    func turnOffPins() {
        pinDotsView.clear()
    }
    
    func invalidPin() {
        pinDotsView.shake()
    }
    
    func validPin() {
        removeGesture()
        enterPinButton.isHidden = true
        pinDotsView.resignFirstResponder()
        pinDotsView.isHidden = true
        returnFullScreen()
        settingsButton.isHidden = true
    }
    
    // Gesture Recognizer Calls
    func addSwipeGestures() {
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeRight.direction = UISwipeGestureRecognizer.Direction.right
        self.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeLeft.direction = UISwipeGestureRecognizer.Direction.left
        self.addGestureRecognizer(swipeLeft)
    }
    
    func removeGesture() {
        for recognizer in self.gestureRecognizers ?? [] {
            self.removeGestureRecognizer(recognizer)
        }
    }
    
    
    // Toggle PIN Dot on/off
    func togglePinDotViews(toMatch text: String) {
        let needToBeToggled = pinDotsViewArray.enumerated().filter { index, pin in
            let shouldBeOn = index < text.count
            let isOn = pin.isActive
            return shouldBeOn != isOn
        }
        needToBeToggled.forEach { $1.isActive.toggle() }
    }
    
    // Listen for Keyboard
    func listenForKeyboardToRaise(){
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
    }

    private func setLayout() {
        let views: [UIView] = [
            confirmationPinLabel,
            pinDotsView,
            pinScreenLogoView,
            pinScreenIDIconView,
            authenticationTypeInstructionsLabel,
            settingsButton,
            loginWelcomeBackLabel,
            enterPinButton,
            loginOptionsStackView
        ]
        
        views.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        views.forEach { containerView.addSubview($0) }
        
        containerBottomViewConstraint = containerView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        
        logoHeightConstraint = pinScreenLogoView.heightAnchor.constraint(equalToConstant: 80)
        logoWidthConstraint = pinScreenLogoView.widthAnchor.constraint(equalToConstant: 294)
        logoTopConstraint = pinScreenLogoView.topAnchor.constraint(equalTo: containerView.safeTopAnchor, constant: 8)
        
        pinScreenIDIconCenterConstraint = pinScreenIDIconView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
        
        confirmationPINLabelConstraint = confirmationPinLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
        
        loginWelcomeBackLabelConstraint = loginWelcomeBackLabel.topAnchor.constraint(equalTo: pinDotsView.topAnchor, constant: -175)
        loginOptionsStackView.addArrangedSubview(settingsButton)
        
        if loginType.isSetup {
            setupOptionsConstraints = [
                setupOptionsStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -25),
                setupOptionsStackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                setupOptionsStackView.topAnchor.constraint(greaterThanOrEqualTo: pinDotsView.bottomAnchor, constant: 25),
            ]
            
            containerView.bringSubviewToFront(setupOptionsStackView)
        }

        let pinDotsViewCenterYConstraint = pinDotsView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: 30)
        pinDotsViewCenterYConstraint.priority = .defaultLow
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: self.topAnchor),
            containerBottomViewConstraint,
            
            loginBackgroundImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            loginBackgroundImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            loginBackgroundImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            loginBackgroundImageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            logoWidthConstraint,
            logoHeightConstraint,
            logoTopConstraint,
            pinScreenLogoView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            pinScreenIDIconCenterConstraint,
            pinScreenIDIconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            pinScreenIDIconView.widthAnchor.constraint(equalToConstant: 64),
            pinScreenIDIconView.heightAnchor.constraint(equalToConstant: 64),
            
            confirmationPinLabel.heightAnchor.constraint(equalToConstant: 64),
            confirmationPinLabel.bottomAnchor.constraint(equalTo: pinDotsView.topAnchor),
            confirmationPINLabelConstraint,
            
            loginWelcomeBackLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            loginWelcomeBackLabelConstraint,
            
            authenticationTypeInstructionsLabel.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.85),
            authenticationTypeInstructionsLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            authenticationTypeInstructionsLabel.topAnchor.constraint(equalTo: loginWelcomeBackLabel.bottomAnchor, constant: 10),

            loginOptionsStackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            loginOptionsStackView.widthAnchor.constraint(equalTo: self.widthAnchor),
            loginOptionsStackView.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -55),
            
            pinDotsViewCenterYConstraint,
            
            enterPinButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            enterPinButton.topAnchor.constraint(equalTo: pinDotsView.bottomAnchor, constant: 15),
        ])
    }
    
    // Switch Method of Entry between PIN and Biometric
    @objc func switchToEntryMethod(sender: AnyObject?) {
        NSLayoutConstraint.deactivate([self.pinEntryDotsViewCenterConstraint, self.pinScreenIDIconCenterConstraint])
        
        if lastSwiped == .toPin { // Go to Biometric Option
            removeGesture()
            addSwipeGestures()
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
            
            authenticationTypeInstructionsLabel.text = loginModel.loginScreenInstructionText
            authenticationTypeInstructionsLabel.isHidden = false
            alternateOptions1Button.setTitle(loginModel.loginScreenOptionButton1, for: .normal)
            confirmationPinLabel.isHidden = true
            
            pinDotsView.resignFirstResponder()
            
            // Reset PIN Attempts
            turnOffPins()
            delegate?.pinEntryViewDidSwipeAwayFromPin(self)
            
            pinEntryDotsViewCenterConstraint = pinDotsView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor, constant: self.frame.width)
            pinScreenIDIconCenterConstraint = pinScreenIDIconView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
            
            lastSwiped = .toBiometric
            returnFullScreen()
        } else { // Go to Pin Option
            listenForKeyboardToRaise()
            
            if numberOfPins == .four{
                authenticationTypeInstructionsLabel.text = loginModel.loginScreenInstructionTextSwipe
            } else {
                authenticationTypeInstructionsLabel.text = NSLocalizedString("Please choose a 6-digit PIN", comment: "Localized kind: Please choose a 6-digit PIN")
            }
            
            alternateOptions1Button.setTitle(loginModel.loginScreenOptionButton1Swipe, for: .normal)
            
            pinDotsView.becomeFirstResponder()
            
            pinEntryDotsViewCenterConstraint = pinDotsView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
            pinScreenIDIconCenterConstraint = pinScreenIDIconView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor, constant: -self.frame.width)
            
            lastSwiped = .toPin
        }
        
        enterPinButton.isHidden = true
        NSLayoutConstraint.activate([self.pinEntryDotsViewCenterConstraint, self.pinScreenIDIconCenterConstraint])
        UIView.animate(withDuration: animationTime, animations: {
            self.layoutIfNeeded()
        })
        
        // to shift the accessibility focus to the first element of the view : Voice-over
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: nil)
    }
    
    // Raise Numeric Keypad for PIN Entry
    @objc func pinButtonAction(sender: UIButton!) {
        enterPinButton.isHidden = true
        pinDotsView.becomeFirstResponder()
    }
    
    // Lower Numeric Keypad
    @objc func removeKeypad() {
        enterPinButton.isHidden = false
        pinDotsView.resignFirstResponder()
        returnFullScreen()
    }
    
    // Capture keyboard motion for animation purposes
    @objc func keyboardWillShow(_ notification: Notification) {
        if !pinDotsView.isFirstResponder {
            return
        }

        if let animationTime = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            self.animationTime = animationTime
            let keyboardRectangle = keyboardFrame.cgRectValue
            self.keyboardHeight = keyboardRectangle.height
            shrinkToPinScreen(self.keyboardHeight!, duration: self.animationTime)
        }
    }
    
    @objc func showQuickLoginSettings(sender: UIButton!) {
        endEditing(true)
        returnFullScreen()
        delegate?.pinEntryViewCancelButtonWasTapped(self)
    }
    
    // Reset QuickLink Settings
    @objc func resetQuickLinkSettings() {
        delegate?.pinEntryViewResetQuickLinkButtonWasTapped(self)
    }
    
    // Set Up QuickLink Later
    @objc func setUpLater() {
        guard let system = loginModel.systemLoginType?.system else {
            assertionFailure("Attempted to get current system, but found nil")
            return
        }

        guard case QuickLoginScreenType.setup(let type) = loginType else {
            assertionFailure("loginType was not QuickLoginScreenType.setup")
            return
        }
        
        let eventType: EventType
        
        switch type {
        case .remindMeLaterOptions:
            eventType = .remindMeLaterTapped
        case .setupLaterOptions:
            eventType = .setupLaterTapped
        }
        
        let eventDetails = [
            EventDetailKey.system: system.rawValue,
            EventDetailKey.qlSetupType: type.rawValue
        ]

        Services.shared.auditService.recordInfo(eventType, with: eventDetails)
        
        delegate?.pinEntryViewSetUpLaterButtonWasTapped(self)
    }
    
    @objc func dontAskAgain() {
        guard let system = loginModel.systemLoginType?.system else {
            assertionFailure("Attempted to get current system, but found nil")
            return
        }
        
        UserDefaults.standard.setHasOptedDontRemindQLSetup(for: system, as: true)
        
        let eventDetails = [
            EventDetailKey.system: system.rawValue
        ]

        Services.shared.auditService.recordInfo(.dontAskAgainTapped, with: eventDetails)
 
        delegate?.pinEntryViewSetUpLaterButtonWasTapped(self)
    }
    
    // Biometric Authenticate
    @objc func biometricAuthenticate() {
        delegate?.pinEntryViewBiometricButtonWasTapped(self)
    }
}

extension PinEntryView: PinEntryDotsViewDelegate {

    func pinEntryKeyInput(_ sender: PinEntryDotsView, didChangeText text: String) {
        togglePinDotViews(toMatch: text)
        guard text.count == numberOfPins.rawValue else { return }

        let when = DispatchTime.now() + 0.3
        DispatchQueue.main.asyncAfter(deadline: when) {

            self.turnOffPins()
            self.delegate?.pinEntryView(self, didEnter: text)

            UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: UIAccessibility.Notification.screenChanged)
        }
    }

    func pinEntryKeyInputPinCount() -> Int {
        return numberOfPins.rawValue
    }
}

// MARK: - Setup Options
extension PinEntryView {
    private func setupOptions(for type: QuickLoginScreenType) {
        switch type {
        case .login:
            setupLoginOptions()
        case .setup(let type):
            setupQLOptions(for: type)
        }
    }
    
    private func setupLoginOptions() {
        loginWelcomeBackLabel.text = loginModel.loginScreenWelcomeText
        if numberOfPins == .six {
            authenticationTypeInstructionsLabel.text = "Please enter your 6-digit PIN to login".localized
        }
    }
    
    private func setupQLOptions(for setupType: QuickLoginScreenType.SetupType) {
        setupOptionsStackView = makeQLSetupOptionsStackView()
        
        containerView.addSubview(setupOptionsStackView)
        
        loginWelcomeBackLabel.isHidden = true
        
        alternateOptions1Button.addTarget(self, action: #selector(switchToEntryMethod), for: .touchUpInside)
        alternateOptions2Button.addTarget(self, action: #selector(setUpLater), for: .touchUpInside)
        
        setupOptionsStackView.addArrangedSubviews([
            alternateOptions1Button,
            alternateOptions2Button
        ])
        
        if loginModel.hasBiometricCapabilities {
            addSwipeGestures()
        }
        
        if setupType == .remindMeLaterOptions {
            alternateOptions3Button.addTarget(self, action: #selector(dontAskAgain), for: .touchUpInside)
            setupOptionsStackView.addArrangedSubview(alternateOptions3Button)
        }
    }
    
    private func makeQLSetupOptionsStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = UIStackView.Distribution.equalSpacing
        stackView.alignment = UIStackView.Alignment.center
        stackView.spacing = 20
        
        return stackView
    }
    
    private static func makeQLSetupButtonOption() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }
}
