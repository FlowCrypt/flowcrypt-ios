//
//  EmailProviderViewDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29/03/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import UIKit
import FlowCryptUI

protocol EmailProviderViewDecoratorType {
    func title(for section: EmailProviderViewController.Section) -> InfoCellNode.Input
    func textFieldInput(for section: EmailProviderViewController.Section) -> TextFieldCellNode.Input?
    func stringFor(user: UserObject, for section: EmailProviderViewController.Section) -> NSAttributedString?
    func switchInput(isOn: Bool) -> SwitchCellNode.Input
}

struct EmailProviderViewDecorator: EmailProviderViewDecoratorType {
    private var titleColor: UIColor {
        .colorFor(
            darkStyle: .white,
            lightStyle: .darkGray
        )
    }

    private var backgroundColor: UIColor {
        .colorFor(
            darkStyle: .backgroundColor,
            lightStyle: UIColor(white: 0.9, alpha: 1)
        )
    }

    func title(for section: EmailProviderViewController.Section) -> InfoCellNode.Input {
        let title: String = {
            switch section {
            case .account(.title): return "other_provider_account_title"
            case .imap(.title): return "other_provider_imap_title"
            case .smtp(.title): return "other_provider_smtp_title"
            case .other(.title): return "other_provider_other_smtp_title"
            default: assertionFailure(); return ""
            }
        }()

        return InfoCellNode.Input(
            attributedText: title
                .localized
                .attributed(.bold(17), color: titleColor),
            image: nil,
            insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16),
            backgroundColor: backgroundColor
        )
    }

    func switchInput(isOn: Bool) -> SwitchCellNode.Input {
        SwitchCellNode.Input(
            isOn: isOn,
            attributedText: "other_provider_other_smtp_title"
                .localized
                .attributed(.bold(17), color: titleColor),
            backgroundColor: backgroundColor
        )
    }

    func textFieldInput(for section: EmailProviderViewController.Section) -> TextFieldCellNode.Input? {
        let placeholder: String?
        var isSecure = false

        switch section {
        case let .account(part):
            switch part {
            case .email:
                placeholder = "Email"
            case .password:
                placeholder = "Password"
                isSecure = true
            case .username:
                placeholder = "Username"
            case .title:
                placeholder = nil
            }
        case let .imap(part):
            switch part {
            case .port:
                placeholder = "IMAP port"
            case .security:
                placeholder = "Security type"
            case .server:
                placeholder = "IMAP server"
            case .title:
                placeholder = nil
            }
        case let .smtp(part):
            switch part {
            case .port:
                placeholder = "SMTP port"
            case .security:
                placeholder = "Security type"
            case .server:
                placeholder = "SMTP server"
            case .title:
                placeholder = nil
            }
        case let .other(part):
            switch part {
            case .name:
                placeholder = "SMTP username"
            case .password:
                isSecure = true
                placeholder = "SMTP password"
            case .title:
                placeholder = nil
            }
        case .connect:
            return nil
        }

        guard let placeholderString = placeholder else { assertionFailure(); return nil }

        return TextFieldCellNode.Input(
            placeholder: placeholderString.attributed(.medium(17), color: .lightGray),
            isSecureTextEntry: isSecure,
            insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16),
            backgroundColor: UIColor.colorFor(
                darkStyle: .darkGray,
                lightStyle: UIColor(white: 1, alpha: 1))
        )
    }

    func stringFor(user: UserObject, for section: EmailProviderViewController.Section) -> NSAttributedString? {
        switch section {
        case let .account(part):
            switch part {
            case .email:
                guard user.email.isNotEmpty else { return nil }
                return user.email.attributed()
            case .username:
                guard user.name.isNotEmpty else { return nil }
                return user.name.attributed()
            case .password, .title:
                return nil
            }
        case let .imap(part):
            switch part {
            case .port:
                guard let port = user.imap?.port, port != UserObject.empty.imap?.port else {
                    return nil
                }
                return "\(port)".attributed()
            case .security:
                guard let connection = user.imap?.connectionType else {
                    return nil
                }
                return connection.attributed()
            case .server:
                guard let host = user.imap?.hostname, host.isNotEmpty else {
                    return nil
                }
                return host.attributed()
            case .title:
                return nil
            }
        case let .smtp(part):
            switch part {
            case .port:
                guard let port = user.smtp?.port, port != UserObject.empty.smtp?.port else {
                    return nil
                }
                return "\(port)".attributed()
            case .security:
                guard let connection = user.smtp?.connectionType else {
                    return nil
                }
                return connection.attributed()
            case .server:
                guard let host = user.smtp?.hostname, host.isNotEmpty else {
                    return nil
                }
                return host.attributed()
            case .title:
                return nil
            }
        default:
            return nil
        }
    }
}
