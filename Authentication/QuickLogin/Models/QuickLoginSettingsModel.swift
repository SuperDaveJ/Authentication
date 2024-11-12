//
//  QuickLoginSettingsModel.swift
//  Authentication
//
//  Created by Dave Johnson on 1/17/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

import Foundation
import Services
import Shared

public protocol QuickLoginDelegate: class {
    func presentQuickLogin(_ quickLoginSettingsModel: QuickLoginSettingsModel)
    func resetQuickLogin(_ quickLoginSettingsModel: QuickLoginSettingsModel, cancelAction: @escaping () -> Void)
}

public struct QuickLoginSettingsModel: GenericTableModel {
    private weak var delegate: QuickLoginDelegate?
    
    public init(_ delegate: QuickLoginDelegate?) {
        self.delegate = delegate
    }
    
    public func qlSwitchAction(switchControl: UISwitch) {
                
        if switchControl.isOn {
            self.delegate?.presentQuickLogin(self)
        } else {
            self.delegate?.resetQuickLogin(self) {
                switchControl.setOn(true, animated: true) // if they cancel, then change the status back to being selected
            }
        }
        
        Services.shared.auditService.recordInfo(.quickLoginToggled, with: [EventDetailKey.enabled: switchControl.isOn.toString()])
    }
    
    public func autoAuthAction(switchControl: UISwitch) {
        Services.shared.auditService.recordInfo(.autoAuthWasChanged, with: [EventDetailKey.value: switchControl.isOn.toString()])
        Defaults.standard.automaticAuthenticationEnabled = switchControl.isOn
    }
    
    public func makeSections() -> [GenericTableViewSection] {
        let sections: [GenericTableViewSection] = [
            BasicTableViewSection(
                title: nil,
                footer: "Use your face, finger print, or a PIN to log in to the Paycom app".localized,
                condition: true,
                cellData: [
                    GenericCellType.toggle(
                        text: "Quick Login".localized,
                        isSelected: Defaults.standard.hasSetUpQuickLogin,
                        action: qlSwitchAction)
                ],
                textAlignment: .left),
            BasicTableViewSection(
                title: nil,
                footer: "Allow device to attempt Face/Touch authentication automatically when logging in.".localized,
                condition: Defaults.standard.hasSetUpQuickLogin,
                cellData: [
                    GenericCellType.toggle(
                        text: "Automatic Authentication".localized,
                        isSelected: Defaults.standard.automaticAuthenticationEnabled,
                        action: autoAuthAction)
                ],
                textAlignment: .left),
            AppVersionTableViewSection.default
        ]
        
        return sections
    }
}
