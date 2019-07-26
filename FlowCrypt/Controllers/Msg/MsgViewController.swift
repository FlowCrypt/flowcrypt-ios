//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import MBProgressHUD
import RealmSwift
import Promises

protocol MsgViewControllerDelegate {
    func movedOrDeleted(objMessage: MCOIMAPMessage)
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
        let start = DispatchTime.now()
        self.lblSender.text = objMessage.header.sender.mailbox ?? "(unknown sender)"
        self.lblSubject.text = objMessage.header.subject ?? "(no subject)"
        self.lblBody.numberOfLines = 0

        self.lblTIme.text = Constants.inboxDateFormatter.string(from: objMessage.header.date)
        self.showSpinner(Language.loading, isUserInteractionEnabled: true)
        Promise<Void> {
            let mime = try await(EmailProvider.sharedInstance.fetchMessageBody(message: self.objMessage, folder: self.path))
            print("Msg loaded after \(start.millisecondsSince()) ms")
            self.bodyMessage = mime
            self.hideSpinner()
            let realm = try Realm()
            let keys = PrvKeyInfo.from(realm: realm.objects(KeyInfo.self))
            let decrypted = try Core.parseDecryptMsg(encrypted: mime, keys: keys, msgPwd: nil, isEmail: true)
            DispatchQueue.main.async {
                let decryptErrBlock = decrypted.blocks.first(where: { $0.decryptErr != nil })
                print("Fully rendered after \(start.millisecondsSince()) ms")
                if decryptErrBlock == nil {
                    self.renderMsgBody(decrypted.text, color: Constants.green)
                } else {
                    let e = decryptErrBlock!.decryptErr!.error
                    self.renderMsgBody("Dould not decrypt message:\n\(e.type)\n\n\(e.message)\n\n\(decryptErrBlock!.content)", color: UIColor.red)
                }
                self.markAsRead()
            }
        }.catch { error in
            self.showErrAlert("\(Language.could_not_open_message)\n\n\(error)")
        }
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
        EmailProvider.sharedInstance.markAsRead(message: self.objMessage, folder: self.path) // async, do not await
    }

    @IBAction func btnTrashTap(sender: AnyObject) {
        let spinnerActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinnerActivity.label.text = "Loading"
        spinnerActivity.isUserInteractionEnabled = false
        if self.path != "[Gmail]/Trash" {
            EmailProvider.sharedInstance.markAsTrashMessage(message: self.objMessage, folder: self.path, destFolder: "[Gmail]/Trash") { (error) in
                spinnerActivity.hide(animated: true)
                if error == nil {
                    if let d = self.delegate {
                        d.movedOrDeleted(objMessage: self.objMessage)
                    }
                    self.successEmailAlert(message: Language.moved_to_trash)
                }
            }
        } else {
            self.objMessage.flags = MCOMessageFlag.deleted
            EmailProvider.sharedInstance.deleteMessage(message: self.objMessage, folder: self.path, callback: { (error) in
                if error == nil {
                    if let d = self.delegate {
                        d.movedOrDeleted(objMessage: self.objMessage)
                    }
                    EmailProvider.sharedInstance.expungeToDelete(folder: self.path, callback: { (error1) in
                        if error1 == nil {
                            spinnerActivity.hide(animated: true)
                            self.successEmailAlert(message: Language.email_deleted)
                        }
                    })
                } else {
                    spinnerActivity.hide(animated: true)
                }
            })
        }
    }

    @IBAction func btnArchiveTap(sender: AnyObject) {
        let spinnerActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinnerActivity.label.text = "Loading"
        spinnerActivity.isUserInteractionEnabled = false
        self.objMessage.flags = MCOMessageFlag.deleted
        EmailProvider.sharedInstance.deleteMessage(message: self.objMessage, folder: self.path, callback: { (error) in
            spinnerActivity.hide(animated: true)
            if error == nil {
                if let d = self.delegate {
                    d.movedOrDeleted(objMessage: self.objMessage)
                }
                self.successEmailAlert(message: Language.email_archived)
            }
        })
    }

    @IBAction func btnReplyTap(sender: UIButton) {
        let replyVc = self.instantiate(viewController: ComposeViewController.self)
        replyVc.isReply = true
        replyVc.replyToSubject = self.objMessage.header.subject
        replyVc.replyToRecipient = self.objMessage.header.from
        replyVc.replyToMime = self.bodyMessage
        self.navigationController?.pushViewController(replyVc, animated: true)
    }

    func successEmailAlert(message: String!) {
        UIApplication.shared.keyWindow?.rootViewController?.view.makeToast(message)
        self.btnBackTap(sender: UIBarButtonItem())
    }
}
