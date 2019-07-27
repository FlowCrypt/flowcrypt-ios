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
                self.renderMsgBody(decrypted.text, color: decrypted.replyType == CoreRes.ReplyType.encrypted ? Constants.green : UIColor.black)
            } else {
                let e = decryptErrBlock!.decryptErr!.error
                self.renderMsgBody("Dould not decrypt message:\n\(e.type)\n\n\(e.message)\n\n\(decryptErrBlock!.content)", color: UIColor.red)
            }
            self.markAsReadIfNotAlreadyMarked()
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

    func markAsReadIfNotAlreadyMarked() {
        if !self.objMessage.flags.isSuperset(of: MCOMessageFlag.seen) {
            self.objMessage.flags.formUnion(MCOMessageFlag.seen)
            let _ = Imap.instance.markAsRead(message: self.objMessage, folder: self.path) // async, do not await
        }
    }

    @IBAction func btnTrashTap(sender: AnyObject) {
        guard self.path != "[Gmail]/Trash" else { // todo - does not need to be here once trash btn is hidden
            self.showToast("Message is already in trash")
            return
        }
        self.async({
            let _ = try await(Imap.instance.moveMsg(msg: self.objMessage, folder: self.path, destFolder: "[Gmail]/Trash"))
        }, then: {
            self.onMsgUpdateSuccess(toast: Language.moved_to_trash)
        })
    }

    @IBAction func btnArchiveTap(sender: AnyObject) {
        self.objMessage.flags = MCOMessageFlag.deleted
        self.async({
            let _ = try await(Imap.instance.pushUpdatedMsgFlags(msg: self.objMessage, folder: self.path))
        }, then: {
            self.onMsgUpdateSuccess(toast: Language.email_archived)
        })
    }

    func onMsgUpdateSuccess(toast: String) {
        self.hideSpinner()
        if let d = self.delegate {
            d.movedOrUpdated(objMessage: self.objMessage)
        }
        self.showToast(toast)
        self.btnBackTap(sender: UIBarButtonItem())
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
