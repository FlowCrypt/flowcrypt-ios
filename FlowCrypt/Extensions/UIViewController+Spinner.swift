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
    func showSpinner(_ message: String = "loading_title".localized, isUserInteractionEnabled: Bool = false) {
        DispatchQueue.main.async {
            guard self.view.subviews.first(where: { $0 is MBProgressHUD }) == nil else {
                // hud is already shown
                return
            }
            self.view.isUserInteractionEnabled = isUserInteractionEnabled

            let spinner = MBProgressHUD.showAdded(to: self.view, animated: true)
            spinner.label.text = message
            spinner.isUserInteractionEnabled = isUserInteractionEnabled
        }
    }

    func updateSpinner(label: String = "compose_uploading".localized,
                       progress: Float? = nil,
                       systemImageName: String? = nil) {
        DispatchQueue.main.async {
            if let progress = progress {
                if progress >= 1 {
                    self.updateSpinner(label: "compose_sent".localized,
                                       systemImageName: "checkmark.circle")
                } else {
                    self.showProgressHUD(progress: progress, label: label)
                }
            } else if let imageName = systemImageName {
                self.showProgressHUDWithCustomImage(imageName: imageName, label: label)
            }

        }
    }

    func hideSpinner() {
        DispatchQueue.main.async {
            self.view.subviews
                .compactMap { $0 as? MBProgressHUD }
                .forEach { $0.hide(animated: true) }
            self.view.isUserInteractionEnabled = true
        }
    }
}

extension UIViewController {
    private func showProgressHUD(progress: Float, label: String) {
        guard let hud = MBProgressHUD.forView(view) else { return }

        let percent = Int(progress * 100)
        hud.label.text = "\(label) \(percent)%"
        hud.progress = progress
        hud.mode = .annularDeterminate
    }

    private func showProgressHUDWithCustomImage(imageName: String, label: String) {
        guard let hud = MBProgressHUD.forView(view) else { return }

        let configuration = UIImage.SymbolConfiguration(pointSize: 36)
        let imageView = UIImageView(image: .init(systemName: imageName, withConfiguration: configuration))
        hud.minSize = CGSize(width: 150, height: 90)
        hud.customView = imageView
        hud.mode = .customView
        hud.label.text = label
    }
}
