//
//  ContactKeyDetailDecorator.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 13/10/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//
    
import FlowCryptUI
import Foundation

protocol ContactKeyDetailDecoratorType {
    var title: String { get }
    func attributedTitle(for contactKeyPart: ContactKeyDetailViewController.Part) -> NSAttributedString
}

struct ContactKeyDetailDecorator: ContactKeyDetailDecoratorType {
    let title = "contact_key_detail_screen_title".localized

    func attributedTitle(for contactKeyPart: ContactKeyDetailViewController.Part) -> NSAttributedString {
        let title: String
        switch contactKeyPart {
        case .key: title = "contact_key_pub".localized
        case .signature: title = "contact_key_signature".localized
        case .created: title = "contact_key_created".localized
        case .checked: title = "contact_key_fetched".localized
        case .expire: title = "contact_key_expires".localized
        case .longids: title = "contact_key_longids".localized
        case .fingerprints: title = "contact_key_fingerprints".localized
        case .algo: title = "contact_key_algo".localized
        }

        return title.attributed(.bold(16))
    }
}
