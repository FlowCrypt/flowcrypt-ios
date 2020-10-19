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
    var connectButtonTitle: NSAttributedString { get }
    var connectButtonInsets: UIEdgeInsets { get }
    func title(for section: EmailProviderViewController.Section) -> InfoCellNode.Input
    func textFieldInput(for section: EmailProviderViewController.Section) -> TextFieldCellNode.Input?
    func stringFor(user: UserObject, for section: EmailProviderViewController.Section) -> NSAttributedString?
    func switchInput(isOn: Bool) -> SwitchCellNode.Input
    func shouldAddToolBar(for section: EmailProviderViewController.Section) -> Bool
    func pickerView(
        for: EmailProviderViewController.Section,
        delegate: UIPickerViewDelegate,
        dataSource: UIPickerViewDataSource
    ) -> UIPickerView?
}

struct EmailProviderViewDecorator: EmailProviderViewDecoratorType {
    var connectButtonTitle: NSAttributedString {
        "other_provider_connect"
            .localized
            .attributed(.bold(20), color: .white, alignment: .center)
    }

    let connectButtonInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 10)

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
        let context: TextFieldContext
        switch section {
        case let .account(part):
            context = textFieldAccountInput(for: part)
        case let .imap(part):
            context = textFieldImapInput(for: part)
        case let .smtp(part):
            context = textFieldSmtpInput(for: part)
        case let .other(part):
            context = textFieldOtherInput(for: part)
        case .connect:
            return nil
        }

        guard let placeholderString = context.placeholder else { assertionFailure(); return nil }

        return TextFieldCellNode.Input(
            placeholder: placeholderString.attributed(.medium(17), color: .lightGray),
            isSecureTextEntry: context.isSecure,
            insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16),
            backgroundColor: UIColor.colorFor(
                darkStyle: .darkGray,
                lightStyle: UIColor(white: 1, alpha: 1)
            ),
            keyboardType: context.keyboardType
        )
    }

    func stringFor(user: UserObject, for section: EmailProviderViewController.Section) -> NSAttributedString? {
        switch section {
        case let .account(part):
            return accountStringFor(user: user, part: part)
        case let .imap(part):
            return imapStringFor(user: user, part: part)
        case let .smtp(part):
            return smtpStringFor(user: user, part: part)
        default:
            return nil
        }
    }

    func pickerView(
        for section: EmailProviderViewController.Section,
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

    func shouldAddToolBar(for section: EmailProviderViewController.Section) -> Bool {
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

// MARK: - TextFieldContext for parts

extension EmailProviderViewDecorator {
    typealias TextFieldContext = (placeholder: String?, isSecure: Bool, keyboardType: UIKeyboardType)

    private func textFieldAccountInput(for part: EmailProviderViewController.AccountPart) -> TextFieldContext {
        let placeholder: String?
        var isSecure = false
        var keyboardType: UIKeyboardType = .default

        switch part {
        case .email:
            placeholder = "Email"
            keyboardType = .emailAddress
        case .password:
            placeholder = "Password"
            isSecure = true
        case .username:
            placeholder = "Username"
        case .title:
            placeholder = nil
        }

        return TextFieldContext(placeholder, isSecure, keyboardType)
    }

    private func textFieldImapInput(for part: EmailProviderViewController.ServerPart) -> TextFieldContext {
        let placeholder: String?
        var keyboardType: UIKeyboardType = .default

        switch part {
        case .port:
            placeholder = "IMAP port"
            keyboardType = .numberPad
        case .security:
            placeholder = "Security type"
        case .server:
            placeholder = "IMAP server"
        case .title:
            placeholder = nil
        }

        return TextFieldContext(placeholder, false, keyboardType)
    }

    private func textFieldSmtpInput(for part: EmailProviderViewController.ServerPart) -> TextFieldContext {
        let placeholder: String?
        var keyboardType: UIKeyboardType = .default

        switch part {
        case .port:
            placeholder = "SMTP port"
            keyboardType = .numberPad
        case .security:
            placeholder = "Security type"
        case .server:
            placeholder = "SMTP server"
        case .title:
            placeholder = nil
        }

        return TextFieldContext(placeholder, false, keyboardType)
    }

    private func textFieldOtherInput(for part: EmailProviderViewController.OtherSMTP) -> TextFieldContext {
        let placeholder: String?
        var isSecure = false

        switch part {
        case .name:
            placeholder = "SMTP username"
        case .password:
            isSecure = true
            placeholder = "SMTP password"
        case .title:
            placeholder = nil
        }

        return TextFieldContext(placeholder, isSecure, .default)
    }
}

// MARK: - String for parts

extension EmailProviderViewDecorator {
    private func accountStringFor(user: UserObject, part: EmailProviderViewController.AccountPart) -> NSAttributedString? {
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
    }

    private func imapStringFor(user: UserObject, part: EmailProviderViewController.ServerPart) -> NSAttributedString? {
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
    }

    private func smtpStringFor(user: UserObject, part: EmailProviderViewController.ServerPart) -> NSAttributedString? {
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
    }
}
