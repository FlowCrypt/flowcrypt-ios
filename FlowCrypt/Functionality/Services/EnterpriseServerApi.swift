//
//  EnterpriseServerApi.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 05.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Promises

protocol EnterpriseServerApiType {
    func getActiveFesUrl(for email: String) -> Promise<String?>
}

class EnterpriseServerApi: EnterpriseServerApiType {

    private enum Constants {
        static let getActiveFesTimeout: TimeInterval = 4

        static let serviceKey = "service"
        static let serviceNeededValue = "enterprise-server"
    }

    func getActiveFesUrl(for email: String) -> Promise<String?> {
        Promise<String?> { resolve, _ in
            guard let userDomain = email.recipientDomain,
                  !Configuration.excludedDomains.contains(userDomain) else {
                resolve(nil)
                return
            }
            let urlString = "https://fes.\(userDomain)/"
            let request = URLRequest.urlRequest(
                with: "\(urlString)api/",
                method: .get,
                body: nil
            )

            let response = try awaitPromise(URLSession.shared.call(request, tolerateStatus: [404]))
            guard response.status != 404,
                  let responseDictionary = try? response.data.toDict(),
                  let service = responseDictionary[Constants.serviceKey] as? String,
                  service == Constants.serviceNeededValue else {
                resolve(nil)
                return
            }

            resolve(urlString)
        }
        .timeout(Constants.getActiveFesTimeout)
        .recoverFromTimeOut(result: nil)
    }
}
