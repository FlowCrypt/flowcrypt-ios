//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import MBProgressHUD
import RealmSwift
import Promises

protocol MsgViewControllerDelegate {
    func movedOrUpdated(objMessage: MCOIMAPMessage)
}

class MsgViewController: BaseViewController {

    var objMessage = MCOIMAPMessage()
    var bodyMessage: Data?
    var path = ""
    @IBOutlet var lblSender: UILabel!
    @IBOutlet var lblSubject: UILabel!
    @IBOutlet var lblTIme: UILabel!
    @IBOutlet var lblBody: UILabel!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var scrollViewContent: UIView!

    var delegate: MsgViewControllerDelegate!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.lblSender.text = objMessage.header.sender.mailbox ?? "(unknown sender)"
        self.lblSubject.text = objMessage.header.subject ?? "(no subject)"
        self.lblBody.numberOfLines = 0
        self.lblTIme.text = Constants.inboxDateFormatter.string(from: objMessage.header.date)
        self.showSpinner(Language.loading, isUserInteractionEnabled: true)
        if self.path == "[Gmail]/Trash" {
            // self.btnTrash.isHidden = true; // todo - hide the trash btn
        }
        self.async({ () -> CoreRes.ParseDecryptMsg in
            let mime = try await(Imap.instance.fetchMsg(message: self.objMessage, folder: self.path))
            self.bodyMessage = mime
            self.hideSpinner()
            let realm = try Realm()
            let keys = PrvKeyInfo.from(realm: realm.objects(KeyInfo.self))
            let decrypted = try Core.parseDecryptMsg(encrypted: mime, keys: keys, msgPwd: nil, isEmail: true)
            return decrypted
        }, then: { decrypted in
            let decryptErrBlock = decrypted.blocks.first(where: { $0.decryptErr != nil })
            if decryptErrBlock == nil {
                self.renderMsgBody(decrypted.text, color: Constants.green)
            } else {
                let e = decryptErrBlock!.decryptErr!.error
                self.renderMsgBody("Dould not decrypt message:\n\(e.type)\n\n\(e.message)\n\n\(decryptErrBlock!.content)", color: UIColor.red)
            }
            self.markAsRead()
        }, fail: Language.could_not_open_message)
    }

    func renderMsgBody(_ text: String, color: UIColor = UIColor.black) {
        self.lblBody.text = text
        self.lblBody.textColor = color
        self.lblBody.sizeToFit()
        self.scrollView.contentSize = self.scrollViewContent.frame.size;
    }

    @IBAction func btnBackTap(sender: AnyObject) {
        _ = self.navigationController?.popViewController(animated: true)
    }

    func markAsRead() {
        if self.objMessage.flags.rawValue == 0 {
            self.objMessage.flags = MCOMessageFlag.seen
        }
        let _ = Imap.instance.markAsRead(message: self.objMessage, folder: self.path) // async, do not await
    }

    @IBAction func btnTrashTap(sender: AnyObject) {
        guard self.path != "[Gmail]/Trash" else {
            // todo - does not need to be here once trash btn is hidden
            self.showToast("Message is already in trash")
            return
        }
        self.showSpinner("Moving to Trash")
        print("trash tapped")
        self.renderResult(
            for: Imap.instance.moveMsg(msg: self.objMessage, folder: self.path, destFolder: "[Gmail]/Trash"), 
            successAlert: Language.moved_to_trash
        )
    }

    @IBAction func btnArchiveTap(sender: AnyObject) {
        self.showSpinner("Archiving")
        self.objMessage.flags = MCOMessageFlag.deleted
        print("archiving")
        self.renderResult(
            for: Imap.instance.pushUpdatedMsgFlags(msg: self.objMessage, folder: self.path),
            successAlert: Language.email_archived
        )
    }

    func renderResult(for promise: Promise<VOID>, successAlert: String) {
        print("render result")
        promise.then(on: .main) { _ in
            print("promise then")
            self.hideSpinner()
            if let d = self.delegate {
                d.movedOrUpdated(objMessage: self.objMessage)
            }
            self.showToast(successAlert)
            self.btnBackTap(sender: UIBarButtonItem())
        }.catch { error in
            print("prom catch")
            self.showErrAlert("\(Language.action_failed)\n\n\(error)")
        }
    }

    @IBAction func btnReplyTap(sender: UIButton) {
        let replyVc = self.instantiate(viewController: ComposeViewController.self)
        replyVc.isReply = true
        replyVc.replyToSubject = self.objMessage.header.subject
        replyVc.replyToRecipient = self.objMessage.header.from
        replyVc.replyToMime = self.bodyMessage
        self.navigationController?.pushViewController(replyVc, animated: true)
    }

}
