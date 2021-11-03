//
//  ShareViewController.swift
//  FlowCryptShareExtension
//
//  Created by Evgenii Kyivskyi on 11/3/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//
    

import UIKit
import Social

class ShareViewController: SLComposeServiceViewController {

    func some() {

    }

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }

}
