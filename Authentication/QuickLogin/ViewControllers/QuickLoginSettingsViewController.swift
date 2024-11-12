//
//  QuickLoginSettingsViewController.swift
//  Authentication
//
//  Created by Dave Johnson on 1/17/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

import Services
import Shared
import UIKit

public protocol QuickLoginSettingsCoordinationDelegate: CoordinationDelegate {
    func showQuickLoginSetup()
}

public class QuickLoginSettingsViewController: UITableViewController, GenericTableViewDataSourceDelegate {
    public var dataSource: GenericTableViewDataSource!
    public weak var coordinator: QuickLoginSettingsCoordinationDelegate?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView(animated: false)
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectRow(at: indexPath)
    }
    
    public override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        willDisplayFooterView(view, forSection: section)
    }
    
    private func setupTableView(animated: Bool) {
        registerTableViewCells()
        
        let quickLoginSettingsModel = QuickLoginSettingsModel(self)
        dataSource = generateDataSource(with: quickLoginSettingsModel.makeSections())
        tableView.dataSource = dataSource
        
        if animated {
            self.animateTableViewReload()
        }
    }
    
    private func generateDataSource(with sections: [GenericTableViewSection]) -> GenericTableViewDataSource {
        let filteredSections: [GenericTableViewSection] = filterSections(sections)
        let dataSource: GenericTableViewDataSource = GenericTableViewDataSource(with: filteredSections, for: self)
        
        return dataSource
    }
    
    public func didFinishQuickLoginSetup() {
        DispatchQueue.main.async { [weak self] in
            self?.setupTableView(animated: true)
        }
    }
}

// MARK: - QuickLoginDelegate
extension QuickLoginSettingsViewController: QuickLoginDelegate {
    public func presentQuickLogin(_ quickLoginSettingsModel: QuickLoginSettingsModel) {
        coordinator?.showQuickLoginSetup()
    }
    
    public func resetQuickLogin(_ quickLoginSettingsModel: QuickLoginSettingsModel, cancelAction: @escaping () -> Void) {
        let title = "Disable Quick Login?".localized
        let message = "Doing so will disable your ability to view any linked accounts and you will log in using your full credentials the next time you login.".localized

        let okAction = SimpleAlertAction(title: "OK".localized, style: .destructive) { [weak self] in
            guard let self = self else { return }
        
            AppDataReset.clearQuickLoginKeychain()
            Services.shared.auditService.recordInfo(.resetQuickLogin)
            
            self.setupTableView(animated: true)
        }
        
		let cancelAction = SimpleAlertAction(title: "Cancel".localized, action: cancelAction)
        
        Services.shared.simpleAlert.show(title: title, message: message, alertActions: [okAction, cancelAction])
    }
}

// MARK: - QuickLogin Helper functions
extension QuickLoginSettingsViewController {
    
    private func showError() {
        let alert = UIAlertController(
            title: "Error".localized,
            message: "Failed to setup Quick Login".localized,
            preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK".localized, style: .default) { [weak self] _ in
            self?.setupTableView(animated: true)
        }
        
        alert.addAction(okAction)
        
        present(alert, animated: true)
    }
}

// MARK: - Storyboarded
extension QuickLoginSettingsViewController: Storyboarded {
    public static var storyboardName: StoryboardName = .accountManagement
}
