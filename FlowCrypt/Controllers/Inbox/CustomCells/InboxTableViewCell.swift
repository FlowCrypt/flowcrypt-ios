//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

class InboxTableViewCell: UITableViewCell {

    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    var message: MCOIMAPMessage! {
        didSet {
            if message.header.sender.mailbox != nil {
                self.emailLabel.text = message.header.sender.mailbox
            } else {
                self.emailLabel.text = "Empty"
            }
            if message.header.subject != nil {
                self.messageLabel.text = message.header.subject
            } else {
                self.messageLabel.text = "No subject"
            }
            self.dateLabel.text = Constants.inboxDateFormatter.string(from: message.header.date)
            if message.flags.rawValue == 0 {
                self.emailLabel.font = Constants.unreadMessageFont
                self.emailLabel.textColor = Constants.unreadMessageTextColor
                self.messageLabel.font = Constants.unreadMessageFont
                self.messageLabel.textColor = Constants.unreadMessageTextColor
                self.dateLabel.font = Constants.unreadDateFont
                self.dateLabel.textColor = Constants.unreadDateTextColor
            } else {
                self.emailLabel.font = Constants.readMessageFont
                self.emailLabel.textColor = Constants.readMessageTextColor
                self.messageLabel.font = Constants.readMessageFont
                self.messageLabel.textColor = Constants.readMessageTextColor
                self.dateLabel.font = Constants.readDateFont
                self.dateLabel.textColor = Constants.readDateTextColor
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
}
