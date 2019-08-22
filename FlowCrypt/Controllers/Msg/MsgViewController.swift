//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import MBProgressHUD
import RealmSwift
import Promises

protocol MsgViewControllerDelegate: class {
    func movedOrUpdated(objMessage: MCOIMAPMessage)
}

final class MsgViewController: BaseViewController {
    private enum MessageAction {
        case delete, archive

        var text: String {
            switch self {
            case .delete: return Language.moved_to_trash
            case .archive: return Language.email_archived
            }
        }

        var error: String {
            switch self {
            case .delete: return Constants.ErrorTexts.Message.delete
            case .archive: return Constants.ErrorTexts.Message.archive
            }
        }
    }
    @IBOutlet var lblSender: UILabel!
    @IBOutlet var lblSubject: UILabel!
    @IBOutlet var lblTIme: UILabel!
    @IBOutlet var lblBody: UILabel!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var scrollViewContent: UIView!

    // TODO: Refactor due to https://github.com/FlowCrypt/flowcrypt-ios/issues/38
    private var btnInfo: UIButton!
    private var btnArchive: UIButton!
    private var btnTrash: UIButton!
    private var btnMail: UIButton!
    private var btnBack: UIButton!

    // TODO: Inject as a dependency
    private let imap = Imap.instance
    private let db: DataBaseService = RealmDataBaseService.shared

    var objMessage = MCOIMAPMessage()
    var bodyMessage: Data?
    var path = ""

    weak var delegate: MsgViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        showSpinner(Language.loading, isUserInteractionEnabled: true)
        fetchMessage()
    }

    private func setupUI() {
        lblSender.text = objMessage.header.sender.mailbox ?? "(unknown sender)"
        lblSubject.text = objMessage.header.subject ?? "(no subject)"
        lblBody.numberOfLines = 0
        lblTIme.text = Constants.convertDate(date: objMessage.header.date)
    }

    private func setupNavigationBar() {
        btnInfo = UIButton(type: .system)
        btnInfo.setImage(UIImage(named: "help_icn")!, for: .normal)
        btnInfo.imageEdgeInsets = Constants.rightUiBarButtonItemImageInsets
        btnInfo.frame = Constants.uiBarButtonItemFrame
        btnInfo.addTarget(self, action: #selector(btnInfoTap), for: .touchUpInside)
        
        btnArchive = UIButton(type: .system)
        btnArchive.setImage(UIImage(named: "archive")!, for: .normal)
        btnArchive.imageEdgeInsets = Constants.rightUiBarButtonItemImageInsets
        btnArchive.frame = Constants.uiBarButtonItemFrame
        btnArchive.addTarget(self, action: #selector(btnArchiveTap), for: .touchUpInside)

        btnTrash = UIButton(type: .system)
        btnTrash.setImage(UIImage(named: "trash")!, for: .normal)
        btnTrash.imageEdgeInsets = Constants.rightUiBarButtonItemImageInsets
        btnTrash.frame = Constants.uiBarButtonItemFrame
        btnTrash.addTarget(self, action: #selector(btnTrashTap), for: .touchUpInside)
        
        btnMail = UIButton(type: .system)
        btnMail.setImage(UIImage(named: "mail")!, for: .normal)
        btnMail.imageEdgeInsets = Constants.rightUiBarButtonItemImageInsets
        btnMail.frame = Constants.uiBarButtonItemFrame
        btnMail.addTarget(self, action: #selector(btnMailTap), for: .touchUpInside)
        
        let stackView = UIStackView(arrangedSubviews: [btnInfo, btnArchive, btnTrash, btnMail])
        stackView.distribution = .equalSpacing
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 15
        
        if self.path == MailDestination.Gmail.trash.path {
            btnTrash.isHidden = true
        }
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stackView)
        
        btnBack = UIButton(type: .system)
        btnBack.setImage(UIImage(named: "arrow-left-c"), for: .normal)
        btnBack.imageEdgeInsets = Constants.leftUiBarButtonItemImageInsets
        btnBack.frame = Constants.uiBarButtonItemFrame
        btnBack.addTarget(self, action: #selector(btnBackTap), for: .touchUpInside)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: btnBack)
    }
    
    private func renderMsgBody(_ text: String, color: UIColor = UIColor.black) {
        lblBody.text = text
        lblBody.textColor = color
        lblBody.sizeToFit()
        scrollView.contentSize = scrollViewContent.frame.size
    }
}

// MARK: - Message
extension MsgViewController {
    private func fetchMessage() {
        imap.fetchMsg(message: objMessage, folder: path)
            .then { [weak self] data -> Promise<CoreRes.ParseDecryptMsg> in
                guard let self = self else { return Promise(ImapError.general) }
                self.bodyMessage = data
                return self.db.save(message: data, isEmail: true)
            }
            .then(on: .main) { [weak self] message in
                guard let self = self else { return }
                self.handleDecryptedMessage(message)
            }
            .catch(on: .main) { [weak self] error in
                self?.hideSpinner()
                self?.showAlert(error: error, message: Language.could_not_open_message)
            }
    }

    private func handleDecryptedMessage(_ decrypted: CoreRes.ParseDecryptMsg) {
        let errorBlocks = decrypted.blocks.compactMap { $0.decryptErr }

        if errorBlocks.isEmpty {
            renderMsgBody(
                decrypted.text,
                color: decrypted.replyType == CoreRes.ReplyType.encrypted ? Constants.green : UIColor.black
            )
        } else if let error = errorBlocks.first?.error {
            let text = decrypted.blocks.first?.content ?? ""
            renderMsgBody(
                "Dould not decrypt message:\n\(error.type)\n\n\(error.message)\n\n\(text)",
                color: .red
            )
        }
        markAsReadIfNotAlreadyMarked()
        hideSpinner()
    }

    private func markAsReadIfNotAlreadyMarked() {
        if !objMessage.flags.isSuperset(of: MCOMessageFlag.seen) {
            self.objMessage.flags.formUnion(MCOMessageFlag.seen)
            Imap.instance.markAsRead(message: self.objMessage, folder: self.path) // async call not awaited on purpose
        }
    }

    private func handleSuccesMessage(operation: MessageAction) {
        hideSpinner()
        delegate?.movedOrUpdated(objMessage: objMessage)
        showToast(operation.text)
        navigationController?.popViewController(animated: true)
    }

    private func handleErrorOnMessage(operation: MessageAction) {
        hideSpinner()
        showToast(operation.error)
    }
}

// MARK: - Handle Actions
extension MsgViewController {
    @objc private func btnInfoTap() {
        #warning("ToDo")
    }

    @objc private func btnMailTap() {
        #warning("ToDo")
    }

    @objc private func btnTrashTap() {
        showSpinner()
        imap.moveMsg(msg: objMessage, folder: path, destFolder: MailDestination.Gmail.trash.path)
            .then(on: .main) { [weak self] _ in
                self?.handleSuccesMessage(operation: .delete)
            }
            .catch(on: .main) { [weak self] error in
                self?.handleErrorOnMessage(operation: .delete)
            }
    }

    @objc private func btnArchiveTap() {
        showSpinner()
        objMessage.flags = MCOMessageFlag.deleted

        imap.pushUpdatedMsgFlags(msg: objMessage, folder: path)
            .then(on: .main) { [weak self] _ in
                self?.handleSuccesMessage(operation: .archive)
            }
            .catch(on: .main) { [weak self] error in
                self?.handleErrorOnMessage(operation: .archive)
            }
    }

    @objc private func btnBackTap() {
        navigationController?.popViewController(animated: true)
    }

    @IBAction private func btnReplyTap(sender: UIButton) {
        let replyVc = instantiate(viewController: ComposeViewController.self)
        replyVc.isReply = true
        replyVc.replyToSubject = objMessage.header.subject
        replyVc.replyToRecipient = objMessage.header.from
        replyVc.replyToMime = bodyMessage

        navigationController?.pushViewController(replyVc, animated: true)
    }
}
