//
//  EnterpriseServerApiHelper.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 02/04/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct EnterpriseServerApiHelper {
    private enum Constants {
        /// -1001 - request timed out, -1003 - сannot resolve host, -1004 - can't connect to hosts
        /// -1005 - network connection lost, -1006 - dns lookup failed, -1007 - too many redirects
        /// -1008 - resource unavailable
        /// -1200 - SSL Error
        /// 400 - 599: Http error
        static let getToleratedNSErrorCodes = [-1001, -1003, -1004, -1005, -1006, -1007, -1008, -1200] + Array(400..<600)
        static let getActiveFesTimeout: TimeInterval = 4
        static let apiName = "EnterpriseServerApi"
    }

    private func constructUrlBase(emailDomain: String) -> String {
        guard !Bundle.shouldUseMockFesApi else {
            return "\(GeneralConstants.Mock.backendUrl)/fes" // mock
        }
        return "https://fes.\(emailDomain)" // live
    }

    private(set) var fesUrl: String?

    init(email: String) async throws {
        self.fesUrl = try await getActiveFesUrl(for: email)
    }

    private func getActiveFesUrl(for email: String) async throws -> String? {
        do {
            guard let userDomain = email.emailParts?.domain,
                  !EnterpriseServerApi.publicEmailProviderDomains.contains(userDomain) else {
                return nil
            }
            let urlBase = constructUrlBase(emailDomain: userDomain)
            let request = ApiCall.Request(
                apiName: Constants.apiName,
                url: "\(urlBase)/api/",
                timeout: Constants.getActiveFesTimeout,
                tolerateStatus: [404] // 404 tells the app that FES is disabled
            )
            let response = try await ApiCall.call(request)

            if response.status == 404 {
                return nil // FES is explicitly disabled
            }

            guard isExpectedFesServiceResponse(responseData: response.data) else {
                if Bundle.isEnterprise { // on enterprise build, FES is expected to be running
                    throw AppErr.general("Unpexpected response from FlowCrypt Enterprise Server")
                }
                return nil // on consumer installations, we only use FES if it returns as expected
            }

            return urlBase
        } catch {
            if await shouldTolerateWhenCallingOpportunistically(error) {
                return nil
            } else {
                throw error
            }
        }
    }

    private func isExpectedFesServiceResponse(responseData: Data) -> Bool {
        // "try?" because unsure what server is running there, want to test without failing
        guard let responseDictionary = try? responseData.toDict() else { return false }
        guard let service = responseDictionary["service"] as? String else { return false }
        return service == "enterprise-server"
    }

    private func shouldTolerateWhenCallingOpportunistically(_ error: Error) async -> Bool {
        if Bundle.isEnterprise {
            return false // FlowCrypt Enterprise Server (FES) required on enterprise bundle
        }
        // on consumer release, FES is called opportunistically - if it's there, it will be used
        // guards first - don't tolerate unknown / other errors. Only interested in network errors.
        guard let apiError = error as? ApiError else { return false }
        guard let nsError = apiError.internalError as NSError? else { return false }
        guard Constants.getToleratedNSErrorCodes.contains(nsError.code) else { return false }
        // when calling FES, we got some sort of network error. Could be FES down or internet down.
        if await doesTheInternetWork() {
            // we got network error from FES, but internet works. We are on consumer release.
            // we can assume that there is no FES running
            return true // tolerate the error
        } else {
            // we got network error from FES because internet actually doesn't work
            // throw original error so user can retry
            return false // do not tolerate the error
        }
    }

    private func doesTheInternetWork() async -> Bool {
        // this API is mentioned here:
        // https://www.chromium.org/chromium-os/chromiumos-design-docs/network-portal-detection
        let request = ApiCall.Request(
            apiName: "ConnectionTest",
            url: "https://client3.google.com/generate_204",
            timeout: Constants.getActiveFesTimeout
        )
        do {
            let response = try await ApiCall.call(request)
            return response.status == 204
        } catch {
            return false
        }
    }
}
