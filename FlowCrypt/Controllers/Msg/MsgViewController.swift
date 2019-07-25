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
    var delegate: MsgViewControllerDelegate!

    override func viewDidLoad() {
        super.viewDidLoad()

        if objMessage.header.sender.mailbox != nil {
            self.lblSender.text = objMessage.header.sender.mailbox
        } else {
            self.lblSender.text = "Empty"
        }
        if objMessage.header.subject != nil {
            self.lblSubject.text = objMessage.header.subject
        } else {
            self.lblSubject.text = "No subject"
        }

        self.lblTIme.text = Constants.inboxDateFormatter.string(from: objMessage.header.date)
        self.showSpinner(Language.loading, isUserInteractionEnabled: true)
        Promise<Void> {
            let mime = try await(EmailProvider.sharedInstance.fetchMessageBody(message: self.objMessage, folder: self.path))
            self.bodyMessage = mime
            self.hideSpinner()
            let realm = try Realm()
            let keys = PrvKeyInfo.from(realm: realm.objects(KeyInfo.self))
            let decrypted = try Core.parseDecryptMsg(encrypted: mime, keys: keys, msgPwd: nil, isEmail: true)
            DispatchQueue.main.async {
                let decryptErrBlock = decrypted.blocks.first(where: { $0.decryptErr != nil })
                guard decryptErrBlock == nil else {
                    let e = decryptErrBlock!.decryptErr!.error
                    self.lblBody.text = "Dould not decrypt message: \(e.type)\n\n\(e.message)\n\n\(decryptErrBlock!.content)"
                    self.lblBody.textColor = UIColor.red
                    return
                }
                self.lblBody.text = decrypted.text;
                self.lblBody.textColor = UIColor(red:0.19, green:0.64, blue:0.09, alpha:1.0)
                self.markAsRead()
            }
        }.catch { error in
            self.showErrAlert("\(Language.could_not_open_message)\n\n\(error)")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
