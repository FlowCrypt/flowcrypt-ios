//
//  BlurViewController.swift
//  FlowCrypt
//
//  Created by Parag Dulam on 24/10/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//
import Foundation
import UIKit

final class BlurViewController: UIViewController {
    private var blurView: UIVisualEffectView!

    init(blurStyle: UIBlurEffect.Style) {
        let blurEffect = UIBlurEffect(style: blurStyle)
        self.blurView = UIVisualEffectView(effect: blurEffect)
        super.init(nibName: nil, bundle: nil)
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func loadView() {
        view = blurView
    }
}

protocol BlursTopView: AnyObject {
    var blurViewController: BlurViewController? { get set }
    func coverTopViewWithBlurView()
    func isBlurViewShowing() -> Bool
    func removeBlurView()
}

extension BlursTopView {
    func coverTopViewWithBlurView() {
        self.blurViewController = BlurViewController(blurStyle: .dark)
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let blurView = self.blurViewController?.view {
            blurView.frame = appDelegate.window.bounds
            appDelegate.window.addSubview(blurView)
        }
    }
    func isBlurViewShowing() -> Bool {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let blurView = self.blurViewController?.view {
            return blurView.isDescendant(of: appDelegate.window)
        }
        return false
    }
    func removeBlurView() {
        if let blurView = self.blurViewController?.view {
            blurView.removeFromSuperview()
        }
    }
}
