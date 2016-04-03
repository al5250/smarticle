//
//  ShareViewController.swift
//  shareURL
//
//  Created by Alexander Lin on 3/21/16.
//  Copyright © 2016 Alexander Lin. All rights reserved.
//

import UIKit
import Social

class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    override func didSelectPost() {
        if let item = extensionContext?.inputItems.first as? NSExtensionItem {
            if let itemProvider = item.attachments?.first as? NSItemProvider {
                if itemProvider.hasItemConformingToTypeIdentifier("public.url") {
                    itemProvider.loadItemForTypeIdentifier("public.url", options: nil, completionHandler: { (url, error) -> Void in
                        // get URL from Safari
                        if let shareURL = url as? NSURL {
                            // copies current URL to clipboard
                            UIPasteboard.generalPasteboard().string = "\(shareURL)"
                        }
                        self.extensionContext?.completeRequestReturningItems([], completionHandler:nil)
                    })
                }
            }
        }
    }
    
    override func configurationItems() -> [AnyObject]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }

}
