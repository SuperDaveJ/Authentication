//
//  QuickLoginHelper.swift
//  PaycomESS
//
//  Created by Dave Johnson on 1/17/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

import Foundation
import Shared
import Services

public enum QuickLoginError: Error {
    case loginMethodInvalid
}

public enum TokenLoginError: Error {
    /// Error pulling the needed info from the keychain data
    case keychainError
    /// Error retrieving new token from endpoint or saving it back to the keychain
    case tokenMigrationFailed
}

public class QuickLoginHelper {

    private let bioHelper = BiometricHelper()

    private var savedQuickLoginMethodFromUserDefaults: QuickLoginMethod? {
		guard let existingLoginMethodRawValue = Defaults.standard.loginMethod else {
			return nil
		}

        return QuickLoginMethod(rawValue: existingLoginMethodRawValue)
    }

    public init() {}

    public func loginMethod() throws -> QuickLoginMethod {
        guard bioHelper.canEvaluatePolicy() == true || savedQuickLoginMethodFromUserDefaults == .pin,
            let existingLoginMethodFromUserDefaults = savedQuickLoginMethodFromUserDefaults else { throw QuickLoginError.loginMethodInvalid }

        return existingLoginMethodFromUserDefaults
    }

    /// This method is called once we've received a new refresh token and access token from the AccountMeshAuthService.
    public func saveLoginToken(_ loginToken: LoginToken) {
        let loginChain = KeychainFactory.shared.getBiometricKeychain()

        do {
            let loginMethod = try self.loginMethod()
            let withPin = loginMethod == .pin

            // Persist the updated login token in the Keychain
            try loginChain.save(codableModel: loginToken, requiresBiometricOrPINAuthentication: !withPin)
            Defaults.standard.hasSetUpQuickLogin = true
            
            Services.shared.auditService.recordInfo(.loginTokenSaved)
            
        } catch let error as QuickLoginError {
            Defaults.standard.hasSetUpQuickLogin = false
            
            error.record(.quickLoginError)
            assertionFailure("Failed to persist new login token, loginMethodInvalid: \(error.localizedDescription)")
        } catch KeychainError.unhandledError(status: let status) {
            Defaults.standard.hasSetUpQuickLogin = false
            
            Services.shared.auditService.recordError(.keyChainItemFailure, with: [EventDetailKey.status: "\(status)"])
            assertionFailure("Failed to persist new login token, status: \(status)")
        } catch {
            Defaults.standard.hasSetUpQuickLogin = false

            error.record(.unknownError)
            assertionFailure("Failed to persist new login token, unknown error: \(error.localizedDescription)")
        }
    }

    public func ifNecessaryAttemptFirstMigration(with loginToken: LoginToken, andThenCall completion: @escaping (Result<LoginToken, TokenLoginError>) -> Void) {
        
        let newBaseUrl = PaycomUrls.shared.updateServerUrl(loginToken.baseUrl)

        if TokenMigration.meetsMigrationCondition(credentials: loginToken) {
            guard let token = loginToken.token else {
                completion(.failure(.keychainError))
                return
            }
            let tokenMigration = TokenMigration()
            
            Services.shared.auditService.recordInfo(.tokenMigration, with: [EventDetailKey.targetURL: loginToken.baseUrl])
            
            tokenMigration.migrate(oldToken: token) { newToken in
                if let newToken = newToken {
                    let newLoginToken = LoginToken(baseUrl: newBaseUrl, token: newToken, version: .v1)
                    
                    self.saveLoginToken(newLoginToken)
                    
                    TokenTimerService.shared.beginSession(token: newToken)
                    completion(.success(newLoginToken))
                } else {
                    completion(.failure(.tokenMigrationFailed))
                }
            }
        } else {
            TokenTimerService.shared.beginSession()
            completion(.success(loginToken))
        }

    }
}
