//
//  SetupImapViewDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29/03/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptUI
import UIKit

struct SetupImapViewDecorator {
    var connectButtonTitle: NSAttributedString {
        "other_provider_connect"
            .localized
            .attributed(.bold(20), color: .white, alignment: .center)
    }

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

    func title(for section: SetupImapViewController.Section) -> InfoCellNode.Input {
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

    // swiftlint:disable cyclomatic_complexity function_body_length
    func textFieldInput(for section: SetupImapViewController.Section) -> TextFieldCellNode.Input? {
        let placeholder: String?
        var isSecure = false
        var keyboardType: UIKeyboardType = .default
        var accessibilityIdentifier: String?

        switch section {
        case let .account(part):
            switch part {
            case .email:
                placeholder = "setup_imap_email".localized
                keyboardType = .emailAddress
                accessibilityIdentifier = "aid-email-textfield"
            case .password:
                placeholder = "setup_imap_password".localized
                isSecure = true
                accessibilityIdentifier = "aid-password-textfield"
            case .username:
                placeholder = "setup_imap_username".localized
            case .title:
                placeholder = nil
            }

        // IMAP
        case let .imap(part):
            switch part {
            case .port:
                placeholder = "setup_imap_port".localized
                keyboardType = .numberPad
                accessibilityIdentifier = "IMAP port"
            case .security:
                placeholder = "setup_imap_security_type".localized
                accessibilityIdentifier = "IMAP type"
            case .server:
                placeholder = "setup_imap_server".localized
            case .title:
                placeholder = nil
            }

        // SMTP
        case let .smtp(part):
            switch part {
            case .port:
                placeholder = "setup_imap_smptp_port".localized
                keyboardType = .numberPad
                accessibilityIdentifier = "SMTP port"
            case .security:
                placeholder = "setup_imap_security_type".localized
                accessibilityIdentifier = "SMTP type"
            case .server:
                placeholder = "setup_imap_smtp_server".localized
            case .title:
                placeholder = nil
            }

        // OTHER
        case let .other(part):
            switch part {
            case .name:
                placeholder = "setup_imap_smtp_username".localized
            case .password:
                isSecure = true
                placeholder = "setup_imap_smtp_password".localized
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
                lightStyle: UIColor(white: 1, alpha: 1)
            ),
            keyboardType: keyboardType,
            accessibilityIdentifier: accessibilityIdentifier
        )
    }

    // swiftlint:enable cyclomatic_complexity function_body_length

    // swiftlint:disable cyclomatic_complexity function_body_length
    func stringFor(user: User, for section: SetupImapViewController.Section) -> NSAttributedString? {
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
                guard let port = user.imap?.port, port != User.empty.imap?.port else {
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
                guard let port = user.smtp?.port, port != User.empty.smtp?.port else {
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

    // swiftlint:enable cyclomatic_complexity function_body_length

    func pickerView(
        for section: SetupImapViewController.Section,
        delegate: UIPickerViewDelegate,
        dataSource: UIPickerViewDataSource
    ) -> UIPickerView? {
        switch section {
        case .imap(.security), .smtp(.security):
            let picker = UIPickerView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 200))
            picker.delegate = delegate
            picker.dataSource = dataSource
            return picker
        default:
            return nil
        }
    }

    func shouldAddToolBar(for section: SetupImapViewController.Section) -> Bool {
        switch section {
        case .imap(.security),
             .smtp(.security),
             .imap(.port),
             .smtp(.port):
            return true
        default:
            return false
        }
    }
}
