//
//  UIViewController+Spinner.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 25/10/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import MBProgressHUD
import UIKit

extension UIViewController {
    var currentProgressHUD: MBProgressHUD {
        MBProgressHUD.forView(view) ?? MBProgressHUD.showAdded(to: view, animated: true)
    }

    @MainActor
    func showSpinner(_ message: String = "loading_title".localized, isUserInteractionEnabled: Bool = false) {
        guard self.view.subviews.first(where: { $0 is MBProgressHUD }) == nil else {
            // hud is already shown
            return
        }
        self.view.isUserInteractionEnabled = isUserInteractionEnabled

        let spinner = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinner.label.text = message
        spinner.isUserInteractionEnabled = isUserInteractionEnabled
        spinner.accessibilityIdentifier = "loadingSpinner"
    }

    @MainActor
    func updateSpinner(label: String = "compose_uploading".localized,
                       progress: Float? = nil,
                       systemImageName: String? = nil) {
        if let progress = progress {
            if progress >= 1, let imageName = systemImageName {
                self.updateSpinner(label: "compose_sent".localized,
                                   systemImageName: imageName)
            } else {
                self.showProgressHUD(progress: progress, label: label)
            }
        } else if let imageName = systemImageName {
            self.showProgressHUDWithCustomImage(imageName: imageName, label: label)
        } else {
            self.currentProgressHUD.mode = .indeterminate
            self.currentProgressHUD.label.text = label
        }
    }

    @MainActor
    func hideSpinner() {
        self.view.subviews
            .compactMap { $0 as? MBProgressHUD }
            .forEach { $0.hide(animated: true) }
        self.view.isUserInteractionEnabled = true
    }
}

extension UIViewController {
    private func showProgressHUD(progress: Float, label: String) {
        let percent = Int(progress * 100)
        currentProgressHUD.label.text = "\(label) \(percent)%"
        currentProgressHUD.progress = progress
        currentProgressHUD.mode = .annularDeterminate
    }

    private func showProgressHUDWithCustomImage(imageName: String, label: String) {
        let configuration = UIImage.SymbolConfiguration(pointSize: 36)
        let imageView = UIImageView(image: .init(systemName: imageName, withConfiguration: configuration))
        currentProgressHUD.minSize = CGSize(width: 150, height: 90)
        currentProgressHUD.customView = imageView
        currentProgressHUD.mode = .customView
        currentProgressHUD.label.text = label
    }
}
