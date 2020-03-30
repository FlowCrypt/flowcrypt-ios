//
//  EmailProviderViewDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29/03/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol EmailProviderViewDecoratorType {
    func title(for section: EmailProviderViewController.Section) -> NSAttributedString
}

struct EmailProviderViewDecorator: EmailProviderViewDecoratorType {
    func title(for section: EmailProviderViewController.Section) -> NSAttributedString {
        let title: String = {
            switch section {
            case .account(.title): return "other_provider_account_title"
            case .imap(.title): return "other_provider_imap_title"
            case .smtp(.title): return "other_provider_smtp_title"
            case .other(.title): return "other_provider_other_smtp_title"
            default: assertionFailure(); return ""
            }
        }()

        return title.localized.attributed(.medium(17), color: .red)
    }
}

