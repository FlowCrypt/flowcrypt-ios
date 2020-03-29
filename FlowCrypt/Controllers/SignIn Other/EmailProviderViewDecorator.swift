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
        switch section {
        case .account(.title): return "other_provider_account_title".attributed()
        case .imap(.title): return "other_provider_imap_title".attributed()
        case .smtp(.title): return "other_provider_smtp_title".attributed()
        case .other(.title): return "other_provider_other_smtp_title".attributed()
        default: assertionFailure(); return "".attributed()
        }
    }
}

