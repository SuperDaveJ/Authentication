//
//  LoginToken.swift
//  PaycomESS
//
//  Created by Dave Johnson on 1/17/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

import Services
import Shared

/// Representation of a quick login setup persisted in the keychain
public struct LoginToken: Codable {
    public var baseUrl: String
    public var token: String?
    public var version: Version
    public var refreshToken: String?
    public var accessToken: String?

    /// Initializer for legacy quick login token. Necessary for intermediate migration to OAuth.
    public init(baseUrl: String, token: String, version: Version) {
        self.baseUrl = baseUrl
        self.token = token
        self.version = version
    }
    
    /// Initializer for OAuth quick login token.
    public init(auth: AccountMeshAuthSuccess) {
        self.baseUrl = auth.userHost
        self.token = nil
        self.version = .v2
        self.refreshToken = auth.refreshToken
        self.accessToken = auth.accessToken
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: LoginToken.CodingKeys.self)
        self.baseUrl = try container.decode(String.self, forKey: .baseUrl)
        self.token = try? container.decode(String.self, forKey: .token)
        self.version = (try? container.decode(Version.self, forKey: .version)) ?? .v0
        self.refreshToken = try? container.decode(String.self, forKey: .refreshToken)
        self.accessToken = try? container.decode(String.self, forKey: .accessToken)
    }
    
    public mutating func update(with auth: AccountMeshAuthSuccess) {
        self.baseUrl = auth.userHost
        self.version = .v2
        self.refreshToken = auth.refreshToken
        self.accessToken = auth.accessToken
        
        Services.shared.auditService.recordInfo(.updateLoginToken, with: [EventDetailKey.value: Version.v2.rawValue])
    }
}

// MARK: - Version
extension LoginToken {
    public enum Version: String, Codable {
        /// LoginToken supported by app versions lower than 4.0.
        /// These tokens contain the baseUrl and token values.
        /// The `TokenMigration` class can convert these to v1 tokens.
        case v0 = "V0"
        /// LoginToken supported by app versions from 4.0 to 5.0.
        /// These tokens contain the baseUrl, token, and version values.
        /// The `AccountMeshAuthService` class can convert these to v2 tokens.
        /// This is sometimes referred to as a legacy quick login token or a pre-mesh quick login token.
        case v1 = "V1"
        /// LoginToken supported by app versions greater than 5.0.
        /// These tokens contain the baseUrl, version, refreshToken, and accessToken values.
        /// This is sometimes referred to as an OAuth quick login token or a mesh quick login token.
        case v2 = "V2"
    }
}
