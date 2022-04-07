//
//  OrganisationalRulesService.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 18.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import Foundation

protocol ClientConfigurationServiceType {
    var configuration: ClientConfiguration { get async throws }
}

final class ClientConfigurationService: ClientConfigurationServiceType {
    private lazy var logger = Logger.nested(Self.self)

    private let server: EnterpriseServerApiType
    private let local: LocalClientConfigurationType

    private var didFetch = false

    var configuration: ClientConfiguration {
        get async throws {
            if !didFetch { await fetch() }

            guard let raw = try local.load(for: server.email) else {
                throw AppErr.unexpected("There should not be a user without OrganisationalRules")
            }

            return ClientConfiguration(raw: raw)
        }
    }

    init(
        server: EnterpriseServerApiType,
        local: LocalClientConfigurationType
    ) {
        self.server = server
        self.local = local
    }

    private func fetch() async {
        do {
            let raw = try await server.getClientConfiguration()
            try await local.save(
                for: server.email,
                raw: raw,
                fesUrl: server.fesUrl
            )
            didFetch = true
        } catch {
            logger.logError("Client configuration fetch failed: \(error.errorMessage)")
        }
    }
}
