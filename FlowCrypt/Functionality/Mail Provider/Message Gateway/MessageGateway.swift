//
//  MessageSender.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 04.11.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Combine
import Foundation

protocol MessageGateway {
    func sendMail(mime: Data) -> Future<Void, Error>
}
