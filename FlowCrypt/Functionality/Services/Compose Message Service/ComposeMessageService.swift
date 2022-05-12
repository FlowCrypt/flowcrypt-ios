//
//  ComposeMessageService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23.07.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptUI
import Foundation
import GoogleAPIClientForREST_Gmail
import FlowCryptCommon
import UIKit

typealias RecipientState = RecipientEmailsCellNode.Input.State

protocol CoreComposeMessageType {
    func composeEmail(msg: SendableMsg, fmt: MsgFmt) async throws -> CoreRes.ComposeEmail
    func encrypt(data: Data, pubKeys: [String]?, password: String?) async throws -> Data
    func encrypt(file: Data, name: String, pubKeys: [String]?) async throws -> Data
}

final class ComposeMessageService {

    private let messageGateway: MessageGateway
    private let passPhraseService: PassPhraseServiceType
    private let keyAndPassPhraseStorage: KeyAndPassPhraseStorageType
    private let keyMethods: KeyMethodsType
    private let storage: EncryptedStorageType
    private let localContactsProvider: LocalContactsProviderType
    private let core: CoreComposeMessageType & KeyParser
    private let enterpriseServer: EnterpriseServerApiType
    private let draftGateway: DraftGateway?
    private lazy var logger: Logger = Logger.nested(Self.self)

    private let sender: String

    private struct ReplyInfo: Encodable {
        let sender: String
        let recipient: [String]
        let subject: String
        let token: String
    }

    init(
        clientConfiguration: ClientConfiguration,
        encryptedStorage: EncryptedStorageType,
        messageGateway: MessageGateway,
        passPhraseService: PassPhraseServiceType,
        keyAndPassPhraseStorage: KeyAndPassPhraseStorageType,
        keyMethods: KeyMethodsType,
        draftGateway: DraftGateway? = nil,
        localContactsProvider: LocalContactsProviderType? = nil,
        enterpriseServer: EnterpriseServerApiType,
        sender: String,
        core: CoreComposeMessageType & KeyParser = Core.shared
    ) {
        self.messageGateway = messageGateway
        self.passPhraseService = passPhraseService
        self.keyAndPassPhraseStorage = keyAndPassPhraseStorage
        self.keyMethods = keyMethods
        self.draftGateway = draftGateway
        self.storage = encryptedStorage
        self.localContactsProvider = localContactsProvider ?? LocalContactsProvider(encryptedStorage: encryptedStorage)
        self.core = core
        self.enterpriseServer = enterpriseServer
        self.sender = sender
        self.logger = Logger.nested(in: Self.self, with: "ComposeMessageService")
    }

    private var onStateChanged: ((State) -> Void)?
    func onStateChanged(_ completion: ((State) -> Void)?) {
        self.onStateChanged = completion
    }

    func prepareSigningKey(viewController: UIViewController?) async throws -> Keypair? {
        // todo - sender email will differ from account email once
        //   https://github.com/FlowCrypt/flowcrypt-ios/issues/1298 is done
        let keys = try await keyAndPassPhraseStorage.getKeypairsWithPassPhrases(email: sender)
        guard var signingKey = try await keyMethods.chooseSenderSigningKey(keys: keys, senderEmail: sender) else {
            // todo - throw user error for missing signing key
            return nil
        }
        if signingKey.passphrase == nil {
            guard let vc = viewController else {
                throw AppErr.unexpected("missing UIViewController when promting for pass phrase for signing key")
            }
            signingKey.passphrase = try await self.requestMissingPassPhraseWithModal(for: signingKey, viewController: vc)
        }
        return signingKey
    }

    @MainActor
    internal func requestMissingPassPhraseWithModal(for signingKey: Keypair, viewController: UIViewController) async throws -> String {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            let alert = AlertsFactory.makePassPhraseAlert(
                onCancel: {
                    return continuation.resume(throwing: ComposeMessageError.passPhraseRequired)
                },
                onCompletion: { [weak self] passPhrase in
                    guard let self = self else {
                        return continuation.resume(throwing: AppErr.nilSelf)
                    }
                    Task<Void, Never> {
                        do {
                            let matched = try await self.handlePassPhraseEntry(passPhrase, for: signingKey)
                            if matched {
                                return continuation.resume(returning: passPhrase)
                            } else {
                                throw ComposeMessageError.passPhraseNoMatch
                            }
                        } catch {
                            return continuation.resume(throwing: error)
                        }
                    }
                }
            )
            viewController.present(alert, animated: true, completion: nil)
        }
    }

    func handlePassPhraseEntry(_ passPhrase: String, for signingKey: Keypair) async throws -> Bool {
        // since pass phrase was entered (an inconvenient thing for user to do),
        //  let's find all keys that match and save the pass phrase for all
        let allKeys = try await keyAndPassPhraseStorage.getKeypairsWithPassPhrases(email: sender)
        guard allKeys.isNotEmpty else {
            throw KeypairError.noAccountKeysAvailable
        }
        let matchingKeys = try await keyMethods.filterByPassPhraseMatch(keys: allKeys, passPhrase: passPhrase)
        // save passphrase for all matching keys
        try passPhraseService.savePassPhrasesInMemory(
            for: sender,
            passPhrase,
            privateKeys: matchingKeys
        )
        // now figure out if the pass phrase also matched the signing prv itself
        let matched = matchingKeys.first(where: { $0.allFingerprints.first == signingKey.primaryFingerprint })
        return matched != nil// true if the pass phrase matched signing key
    }

    // MARK: - Validation
    func validateAndProduceSendableMsg(
        input: ComposeMessageInput,
        contextToSend: ComposeMessageContext,
        includeAttachments: Bool = true,
        // todo - throw Error on missing pass phrase then catch it in VC
        //   instead of passing VC it here
        vcForPassPhraseModal: UIViewController? = nil
    ) async throws -> SendableMsg {
        onStateChanged?(.validatingMessage)

        let recipients = contextToSend.recipients
        guard recipients.isNotEmpty else {
            throw MessageValidationError.emptyRecipient
        }

        let emails = recipients.map(\.email)
        let emptyEmails = emails.filter { !$0.hasContent }

        guard emails.isNotEmpty, emptyEmails.isEmpty else {
            throw MessageValidationError.emptyRecipient
        }

        guard emails.filter({ !$0.isValidEmail }).isEmpty else {
            throw MessageValidationError.invalidEmailRecipient
        }

        guard input.isQuote || contextToSend.subject?.hasContent ?? false else {
            throw MessageValidationError.emptySubject
        }

        guard let text = contextToSend.message, text.hasContent else {
            throw MessageValidationError.emptyMessage
        }

        let subject = contextToSend.subject ?? "(no subject)"

        // todo - need to use account email here instead of sender
        //   once sendAs aliases are implemented (we pull keys by account email,
        //   and then later prioritize / filter by sender email which may be different)
        // https://github.com/FlowCrypt/flowcrypt-ios/issues/1298
        let senderKeys = try await keyMethods.chooseSenderEncryptionKeys(
            keys: try await keyAndPassPhraseStorage.getKeypairsWithPassPhrases(email: sender),
            senderEmail: sender
        )

        guard senderKeys.isNotEmpty else {
            throw MessageValidationError.noUsableAccountKeys
        }

        let sendableAttachments: [SendableMsg.Attachment] = includeAttachments
                ? contextToSend.attachments.map { $0.toSendableMsgAttachment() }
                : []

        let recipientsWithPubKeys = try await getRecipientKeys(for: recipients)
        let validPubKeys = try validate(
            recipients: recipientsWithPubKeys,
            hasMessagePassword: contextToSend.hasMessagePassword
        )
        let replyToMimeMsg = input.replyToMime
            .flatMap { String(data: $0, encoding: .utf8) }

        if let password = contextToSend.messagePassword, password.isNotEmpty {
            if subject.lowercased().contains(password.lowercased()) {
                throw MessageValidationError.subjectContainsPassword
            }

            let allAvailablePassPhrases = try passPhraseService.getPassPhrases(for: sender).map(\.value)
            if allAvailablePassPhrases.contains(password) {
                throw MessageValidationError.notUniquePassword
            }
        }

        let signingPrv = try await prepareSigningKey(viewController: vcForPassPhraseModal)

        return SendableMsg(
            text: text,
            html: nil,
            to: contextToSend.recipientEmails(type: .to),
            cc: contextToSend.recipientEmails(type: .cc),
            bcc: contextToSend.recipientEmails(type: .bcc),
            from: sender,
            subject: subject,
            replyToMimeMsg: replyToMimeMsg,
            atts: sendableAttachments,
            pubKeys: senderKeys.map { $0.public } + validPubKeys,
            signingPrv: signingPrv,
            password: contextToSend.messagePassword
        )
    }

    private func getRecipientKeys(for composeRecipients: [ComposeMessageRecipient]) async throws -> [RecipientWithSortedPubKeys] {
        let recipients = composeRecipients.map(Recipient.init)
        var recipientsWithKeys: [RecipientWithSortedPubKeys] = []
        for recipient in recipients {
            let armoredPubkeys = try localContactsProvider.retrievePubKeys(for: recipient.email).joined(separator: "\n")
            let parsed = try await self.core.parseKeys(armoredOrBinary: armoredPubkeys.data())
            recipientsWithKeys.append(
                RecipientWithSortedPubKeys(recipient, keyDetails: parsed.keyDetails)
            )
        }
        return recipientsWithKeys
    }

    private func validate(recipients: [RecipientWithSortedPubKeys],
                          hasMessagePassword: Bool) throws -> [String] {
        func contains(keyState: PubKeyState) -> Bool {
            recipients.first(where: { $0.keyState == keyState }) != nil
        }

        logger.logDebug("validate recipients: \(recipients)")
        logger.logDebug("validate recipient keyStates: \(recipients.map(\.keyState))")

        guard hasMessagePassword || !contains(keyState: .empty) else {
            throw MessageValidationError.noPubRecipients
        }

        guard !contains(keyState: .expired) else {
            throw MessageValidationError.expiredKeyRecipients
        }
        guard !contains(keyState: .revoked) else {
            throw MessageValidationError.revokedKeyRecipients
        }

        return recipients.flatMap(\.activePubKeys).map(\.armored)
    }

    // MARK: - Drafts
    private var draft: GTLRGmail_Draft?
    func encryptAndSaveDraft(message: SendableMsg, threadId: String?) async throws {
        do {
            let r = try await core.composeEmail(
                msg: message,
                fmt: .encryptInline
            )
            draft = try await draftGateway?.saveDraft(input: MessageGatewayInput(mime: r.mimeEncoded, threadId: threadId), draft: draft)
        } catch {
            throw ComposeMessageError.gatewayError(error)
        }
    }

    // MARK: - Encrypt and Send
    func encryptAndSend(message: SendableMsg, threadId: String?) async throws {
        do {
            onStateChanged?(.startComposing)

            let hasPassword = (message.password ?? "").isNotEmpty
            let composedEmail: CoreRes.ComposeEmail

            if hasPassword {
                composedEmail = try await composePasswordMessage(from: message)
            } else {
                composedEmail = try await core.composeEmail(
                    msg: message,
                    fmt: .encryptInline
                )
            }

            let input = MessageGatewayInput(
                mime: composedEmail.mimeEncoded,
                threadId: threadId
            )

            try await messageGateway.sendMail(
                input: input,
                progressHandler: { [weak self] progress in
                    let progressToShow = hasPassword ? 0.5 + progress / 2 : progress
                    self?.onStateChanged?(.progressChanged(progressToShow))
                }
            )

            // cleaning any draft saved/created/fetched during editing
            if let draftId = draft?.identifier {
                await draftGateway?.deleteDraft(with: draftId)
            }

            onStateChanged?(.messageSent)
        } catch {
            throw ComposeMessageError.gatewayError(error)
        }
    }
}

// MARK: - Message password
extension ComposeMessageService {
    private func composePasswordMessage(from message: SendableMsg) async throws -> CoreRes.ComposeEmail {
        let messageUrl = try await prepareAndUploadPwdEncryptedMsg(message: message)
        let messageBody = createMessageBodyWithPasswordLink(sender: message.from, url: messageUrl)

        let encryptedBodyAttachment = try await encryptBodyWithoutAttachments(message: message)
        let encryptedAttachments = try await encryptAttachments(message: message)

        let sendableMsg = message.copy(
            body: messageBody,
            atts: [encryptedBodyAttachment] + encryptedAttachments,
            pubKeys: nil
        )

        return try await core.composeEmail(msg: sendableMsg, fmt: .plain)
    }

    private func encryptBodyWithoutAttachments(message: SendableMsg) async throws -> SendableMsg.Attachment {
        let pubEncryptedNoAttachments = try await core.encrypt(
            data: message.text.data(),
            pubKeys: message.pubKeys,
            password: nil
        )

        return SendableMsg.Attachment(
            name: "encrypted.asc",
            type: "application/pgp-encrypted",
            base64: pubEncryptedNoAttachments.base64EncodedString()
        )
    }

    private func encryptAttachments(message: SendableMsg) async throws -> [SendableMsg.Attachment] {
        var encryptedAttachments: [SendableMsg.Attachment] = []

        for attachment in message.atts {
            guard let data = Data(base64Encoded: attachment.base64) else { continue }

            let encryptedFile = try await core.encrypt(
                file: data,
                name: attachment.name,
                pubKeys: message.pubKeys
            )
            let encryptedAttachment = SendableMsg.Attachment(
                name: "\(attachment.name).pgp",
                type: "application/pgp-encrypted",
                base64: encryptedFile.base64EncodedString()
            )
            encryptedAttachments.append(encryptedAttachment)
        }

        return encryptedAttachments
    }

    private func prepareAndUploadPwdEncryptedMsg(message: SendableMsg) async throws -> String {
        let replyToken = try await enterpriseServer.getReplyToken()

        let bodyWithReplyToken = try getPwdMsgBodyWithReplyToken(
            message: message,
            replyToken: replyToken
        )
        let msgWithReplyToken = message.copy(
            body: bodyWithReplyToken,
            atts: message.atts,
            pubKeys: nil
        )
        let pgpMimeWithAttachments = try await core.composeEmail(
            msg: msgWithReplyToken,
            fmt: .plain
        ).mimeEncoded

        let pwdEncryptedWithAttachments = try await core.encrypt(
            data: pgpMimeWithAttachments,
            pubKeys: [],
            password: message.password
        )
        let details = MessageUploadDetails(from: msgWithReplyToken, replyToken: replyToken)

        return try await enterpriseServer.upload(
            message: pwdEncryptedWithAttachments,
            details: details,
            progressHandler: { [weak self] progress in
                self?.onStateChanged?(.progressChanged(progress / 2))
            }
        )
    }

    private func getPwdMsgBodyWithReplyToken(message: SendableMsg, replyToken: String) throws -> SendableMsgBody {
        let replyInfoDiv = try createReplyInfoDiv(for: message, replyToken: replyToken)

        let text = [message.text, "/n/n", replyInfoDiv].joined()
        let html = [message.text, "<br><br>", replyInfoDiv].joined()

        return SendableMsgBody(text: text, html: html)
    }

    private func createReplyInfoDiv(for message: SendableMsg, replyToken: String) throws -> String {
        let replyInfo = ReplyInfo(
            sender: message.from,
            recipient: message.to,
            subject: message.subject,
            token: replyToken
        )
        let replyInfoJsonString = try replyInfo.toJsonData().base64EncodedString()
        return "<div style=\"display: none\" class=\"cryptup_reply\" cryptup-data=\"\(replyInfoJsonString)\"></div>"
    }

    // TODO: - Anton - compose_password_link
    private func createMessageBodyWithPasswordLink(sender: String, url: String) -> SendableMsgBody {
        let text = "compose_password_link".localizeWithArguments(sender, url)
        let aStyle = "padding: 2px 6px; background: #2199e8; color: #fff; display: inline-block; text-decoration: none;"
        let html = """
        \(sender) has sent you a password-encrypted email <a href="\(url)" style="\(aStyle)">Click here to Open Message</a>
        <br><br>
        Alternatively copy and paste the following link: \(url)
        """

        return SendableMsgBody(text: text, html: html)
    }

    func isMessagePasswordStrong(pwd: String) -> Bool {
        let minLength = 8

        // currently password-protected messages are supported only with FES on iOS
        // guard enterpriseServer.isFesUsed else {
        //     // consumers - just 8 chars requirement
        //     return pwd.count >= minLength
        // }

        // enterprise FES - use common corporate password rules
        let predicate = NSPredicate(
            format: "SELF MATCHES %@ ", [
                "(?=.*[a-z])", // 1 lowercase character
                "(?=.*[A-Z])", // 1 uppercase character
                "(?=.*[0-9])", // 1 number
                "(?=.*[\\-@$#!%*?&_,;:'()\"])", // 1 special symbol
                ".{\(minLength),}$" // minimum 8 characters
            ].joined()
        )

        return predicate.evaluate(with: pwd)
    }
}
