//
//  PinDelayViewController.swift
//  PaycomESS
//
//  Created by Dave Johnson on 2/19/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

import Services
import Shared
import UIKit

protocol PinDelayButtonPressDelegate: class {
    
    func pinDelayOtherUserButtonTapped(sender: PinDelayViewController, OtherUserButton: UIButton)
    func pinDelayResetQuickLinkButtonTapped(sender: PinDelayViewController, ResetQuickLinkButton: UIButton)
    func pinDelayScreenWasDismissed()
}

class PinDelayViewController: UIViewController {
    
    weak var delegate: PinDelayButtonPressDelegate?
    lazy var pinDelay = PinDelay()
    var pinView: PinEntryView!
    var delayTimeRemaining: Int = 0
    var pinDelayTimeElapsed: Int = 0
    var timer = Timer()
    static let defaultPinDelay: Int = 300 // Number of seconds to delay
    
    var isTimerRunning = false
    
    @IBOutlet weak var delayTimerText: UILabel!
    @IBAction func resetQuickLinkButton(_ sender: UIButton) {
        
        if (TrackingStateDB.getAutoTrackingState() || TrackingStateDB.getTrackingState()) {
            let alertTitle = NSLocalizedString("Are you sure you want to end the ongoing trip?", comment: "Localized kind: Are you sure you want to end the ongoing trip?")
            let alertMessage = NSLocalizedString("The trip that you are currently tracking will end. It will be uploaded to ESS the next time you log in.", comment: "Localized kind: The trip that you are currently tracking will end. It will be uploaded to ESS the next time you log in.")
            let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
           
            let okAction = UIAlertAction(title: NSLocalizedString("Continue", comment: "Localized kind: Continue"), style: .destructive) { (action) in
            
                NotificationCenter.default.post(name: Notification.Name.endTripOnResetQuickLogin, object: nil)
                self.delegate?.pinDelayResetQuickLinkButtonTapped(sender: self, ResetQuickLinkButton: sender)
            }
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Localized kind: Cancel"), style: .cancel, handler: nil)
            alert.addAction(okAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
            
        } else {
            
           delegate?.pinDelayResetQuickLinkButtonTapped(sender: self, ResetQuickLinkButton: sender)
        }
    }
    
    @IBOutlet weak var otherUserButton: UIButton!
    @IBAction func otherUserButton(_ sender: UIButton) {
        
        delegate?.pinDelayOtherUserButtonTapped(sender: self, OtherUserButton: sender)
    }

    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    @objc func appWillEnterForeground() {
        
        timer.invalidate()
        pinDelayTimeElapsed = Int(pinDelay.getRemainingSecondsOfDelay())
        delayTimeRemaining = Int(PinDelayViewController.defaultPinDelay - pinDelayTimeElapsed)
        
        runTimer()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Listen for entering foreground
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        
        pinDelayTimeElapsed = Int(pinDelay.getRemainingSecondsOfDelay())
        delayTimeRemaining = Int(PinDelayViewController.defaultPinDelay - pinDelayTimeElapsed)
        runTimer()
    }
    
    func runTimer() {
        
        timer = WeakTimer.scheduledTimer(timeInterval: 1, target: self, repeats: true) { [weak self] timer in
            guard let weakSelf = self else {
                timer.invalidate()
                return
            }
            
            if weakSelf.delayTimeRemaining < 1 {
                
                weakSelf.delegate?.pinDelayScreenWasDismissed()
                weakSelf.pinDelay.resetPinDelayTime()
                timer.invalidate()
                weakSelf.dismiss(animated: true, completion: nil)
                
            } else {
                weakSelf.delayTimeRemaining -= 1
                weakSelf.delayTimerText.text = weakSelf.timeString(time: TimeInterval(weakSelf.delayTimeRemaining))
            }
                                    
        }
        
        isTimerRunning = true
    }
    
    func timeString(time:TimeInterval) -> String {
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%01i:%02i", minutes, seconds) //TODO: i18n
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension PinDelayViewController: UIViewControllerTransitioningDelegate {
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        
        return DimmingPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
}
