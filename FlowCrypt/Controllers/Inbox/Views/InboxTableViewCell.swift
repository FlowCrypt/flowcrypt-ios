//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

final class InboxTableViewCell: UITableViewCell {

    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!

    // TODO: Refactor due to https://github.com/FlowCrypt/flowcrypt-ios/issues/38

    var message: MCOIMAPMessage? {
        didSet {
            guard let message = message else { return }
            emailLabel.text = message.header.sender.mailbox ?? "Empty"
            messageLabel.text = message.header.subject ?? "No subject"
            dateLabel.text = Constants.convertDate(date: message.header.date)
            if message.flags.rawValue == 0 {
                emailLabel.font = Constants.unreadMessageFont
                emailLabel.textColor = Constants.unreadMessageTextColor
                messageLabel.font = Constants.unreadMessageFont
                messageLabel.textColor = Constants.unreadMessageTextColor
                dateLabel.font = Constants.unreadDateFont
                dateLabel.textColor = Constants.unreadDateTextColor
            } else {
                emailLabel.font = Constants.readMessageFont
                emailLabel.textColor = Constants.readMessageTextColor
                messageLabel.font = Constants.readMessageFont
                messageLabel.textColor = Constants.readMessageTextColor
                dateLabel.font = Constants.readDateFont
                dateLabel.textColor = Constants.readDateTextColor
            }
        }
    } 
}
