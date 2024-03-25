//
//  ENSideMenu.swift
//  SwiftSideMenu
//
//  Created by Evgeny on 24.07.14.
//  Copyright (c) 2014 Evgeny Nazarov. All rights reserved.
//

// swiftlint:disable file_length

import UIKit

public protocol ENSideMenuDelegate: AnyObject {
    func sideMenuWillOpen()
    func sideMenuWillClose()
    func sideMenuShouldOpenSideMenu() -> Bool
    func sideMenuDidOpen()
    func sideMenuDidClose()
}

public protocol ENSideMenuProtocol: AnyObject {
    var sideMenu: ENSideMenu? { get }
    func setContentViewController(_ contentViewController: UIViewController)
}

public enum ENSideMenuAnimation: Int {
    case none
    case `default`
}

/**
 The position of the side view on the screen.

 - Left:  Left side of the screen
 - Right: Right side of the screen
 */
public enum ENSideMenuPosition: Int {
    case left
    case right
}

public extension UIViewController {
    /**
     Get navigation button for side menu toggle
     */
    func getSideMenuNavButton() -> NavigationBarActionButton {
        return NavigationBarActionButton(
            imageSystemName: "line.3.horizontal",
            action: { [weak self] in
                self?.toggleSideMenuView()
            },
            accessibilityIdentifier: "aid-menu-btn"
        )
    }

    /**
     Changes current state of side menu view.
     */
    func toggleSideMenuView() {
        sideMenuController()?.sideMenu?.toggleMenu()
    }

    /**
     Hides the side menu view.
     */
    func hideSideMenuView() {
        sideMenuController()?.sideMenu?.hideSideMenu()
    }

    /**
     Shows the side menu view.
     */
    func showSideMenuView() {
        sideMenuController()?.sideMenu?.showSideMenu()
    }

    /**
     Returns a Boolean value indicating whether the side menu is showed.

     :returns: BOOL value
     */
    func isSideMenuOpen() -> Bool {
        let sieMenuOpen = sideMenuController()?.sideMenu?.isMenuOpen
        return sieMenuOpen!
    }

    /**
     * You must call this method from viewDidLayoutSubviews in your content view controlers
     * so it fixes size and position of the side menu when the screen rotates.
     * A convenient way to do it might be creating a subclass of UIViewController that does
     * precisely that and then subclassing your view controllers from it.
     */
    func fixSideMenuSize() {
        if let navController = navigationController as? ENSideMenuNavigationController {
            navController.sideMenu?.updateFrame()
        }
    }

    /**
     Returns a view controller containing a side menu

     :returns: A `UIViewController`responding to `ENSideMenuProtocol` protocol
     */
    func sideMenuController() -> ENSideMenuProtocol? {
        var iteration: UIViewController? = parent
        if iteration == nil {
            return topMostController()
        }
        repeat {
            if iteration is ENSideMenuProtocol {
                return iteration as? ENSideMenuProtocol
            } else if iteration?.parent != nil, iteration?.parent != iteration {
                iteration = iteration!.parent
            } else {
                iteration = nil
            }
        } while iteration != nil

        return iteration as? ENSideMenuProtocol
    }

    internal func topMostController() -> ENSideMenuProtocol? {
        var topController = UIApplication.shared.currentWindow?.rootViewController
        if let tabController = topController as? UITabBarController {
            topController = tabController.selectedViewController
        }
        var lastMenuProtocol: ENSideMenuProtocol?
        while topController?.presentedViewController != nil {
            if topController?.presentedViewController is ENSideMenuProtocol {
                lastMenuProtocol = topController?.presentedViewController as? ENSideMenuProtocol
            }
            topController = topController?.presentedViewController
        }

        if lastMenuProtocol != nil {
            return lastMenuProtocol
        } else {
            return topController as? ENSideMenuProtocol
        }
    }
}

open class ENSideMenu: NSObject, UIGestureRecognizerDelegate {
    /// The width of the side menu view. The default value is 160.
    open var menuWidth: CGFloat = 160.0 {
        didSet {
            needUpdateApperance = true
            updateSideMenuApperanceIfNeeded()
            updateFrame()
        }
    }

    fileprivate var menuPosition: ENSideMenuPosition = .left
    fileprivate var blurStyle: UIBlurEffect.Style = .light
    ///  A Boolean value indicating whether the bouncing effect is enabled. The default value is TRUE.
    open var bouncingEnabled = true
    /// The duration of the slide animation. Used only when `bouncingEnabled` is FALSE.
    open var animationDuration = 0.4
    fileprivate let sideMenuContainerView = UIView()
    fileprivate(set) var menuViewController: UIViewController!
    fileprivate var animator: UIDynamicAnimator!
    fileprivate var sourceView: UIView!
    fileprivate var needUpdateApperance = false
    /// The delegate of the side menu
    open weak var delegate: ENSideMenuDelegate?
    fileprivate(set) var isMenuOpen = false
    /// A Boolean value indicating whether the left swipe is enabled.
    open var allowLeftSwipe = true
    /// A Boolean value indicating whether the right swipe is enabled.
    open var allowRightSwipe = true
    open var allowPanGesture = true
    fileprivate var panRecognizer: UIPanGestureRecognizer?

    /**
     Initializes an instance of a `ENSideMenu` object.

     :param: sourceView   The parent view of the side menu view.
     :param: menuPosition The position of the side menu view.

     :returns: An initialized `ENSideMenu` object, added to the specified view.
     */
    public init(sourceView: UIView, menuPosition: ENSideMenuPosition, blurStyle: UIBlurEffect.Style = .light) {
        super.init()
        self.sourceView = sourceView
        self.menuPosition = menuPosition
        self.blurStyle = blurStyle
        self.setupMenuView()

        animator = UIDynamicAnimator(referenceView: sourceView)
        animator.delegate = self

        self.panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(Self.handlePan(_:)))
        panRecognizer!.delegate = self
        sourceView.addGestureRecognizer(panRecognizer!)

        // Add right swipe gesture recognizer
        let rightSwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(Self.handleGesture(_:)))
        rightSwipeGestureRecognizer.delegate = self
        rightSwipeGestureRecognizer.direction = .right

        // Add left swipe gesture recognizer
        let leftSwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(Self.handleGesture(_:)))
        leftSwipeGestureRecognizer.delegate = self
        leftSwipeGestureRecognizer.direction = .left

        if menuPosition == .left {
            sourceView.addGestureRecognizer(rightSwipeGestureRecognizer)
            sideMenuContainerView.addGestureRecognizer(leftSwipeGestureRecognizer)
        } else {
            sideMenuContainerView.addGestureRecognizer(rightSwipeGestureRecognizer)
            sourceView.addGestureRecognizer(leftSwipeGestureRecognizer)
        }
    }

    /**
     Initializes an instance of a `ENSideMenu` object.

     :param: sourceView         The parent view of the side menu view.
     :param: menuViewController A menu view controller object which will be placed in the side menu view.
     :param: menuPosition       The position of the side menu view.

     :returns: An initialized `ENSideMenu` object, added to the specified view, containing the specified menu view controller.
     */
    public convenience init(
        sourceView: UIView,
        menuViewController: UIViewController,
        menuPosition: ENSideMenuPosition,
        blurStyle: UIBlurEffect.Style = .light
    ) {
        self.init(sourceView: sourceView, menuPosition: menuPosition, blurStyle: blurStyle)
        self.menuViewController = menuViewController
        menuViewController.view.frame = sideMenuContainerView.bounds
        menuViewController.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        sideMenuContainerView.addSubview(menuViewController.view)
    }

    /**
     Updates the frame of the side menu view.
     */
    func updateFrame() {
        let width = sourceView.frame.size.width
        let height = sourceView.frame.size.height
        let menuFrame = CGRect(
            x: (menuPosition == .left) ?
                isMenuOpen ? 0 : -menuWidth - 1.0 :
                isMenuOpen ? width - menuWidth : width + 1.0,
            y: sourceView.frame.origin.y,
            width: menuWidth,
            height: height
        )
        sideMenuContainerView.frame = menuFrame
    }

    fileprivate func setupMenuView() {

        // Configure side menu container
        updateFrame()

        let offset = menuPosition == .left ? 1.0 : -1.0

        sideMenuContainerView.backgroundColor = UIColor.clear
        sideMenuContainerView.clipsToBounds = false
        sideMenuContainerView.layer.masksToBounds = false
        sideMenuContainerView.layer.shadowOffset = CGSize(width: offset, height: offset)
        sideMenuContainerView.layer.shadowRadius = 1.0
        sideMenuContainerView.layer.shadowOpacity = 0.125
        sideMenuContainerView.layer.shadowPath = UIBezierPath(rect: sideMenuContainerView.bounds).cgPath

        sourceView.addSubview(sideMenuContainerView)

        if NSClassFromString("UIVisualEffectView") != nil {
            // Add blur view
            let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle)) as UIVisualEffectView
            visualEffectView.frame = sideMenuContainerView.bounds
            visualEffectView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            sideMenuContainerView.addSubview(visualEffectView)
        } else {
            // TODO: add blur for ios 7
        }
    }

    // swiftlint:disable:next function_body_length
    fileprivate func toggleMenu(_ shouldOpen: Bool) {
        if shouldOpen, delegate?.sideMenuShouldOpenSideMenu() == false {
            return
        }
        updateSideMenuApperanceIfNeeded()
        isMenuOpen = shouldOpen
        let width = sourceView.frame.size.width
        let height = sourceView.frame.size.height
        if bouncingEnabled {

            animator.removeAllBehaviors()

            var gravityDirectionX: CGFloat
            var pushMagnitude: CGFloat
            var boundaryPointX: CGFloat
            var boundaryPointY: CGFloat

            if menuPosition == .left {
                // Left side menu
                gravityDirectionX = shouldOpen ? 1 : -1
                pushMagnitude = shouldOpen ? 35 : -35
                boundaryPointX = shouldOpen ? menuWidth : -menuWidth - 2
                boundaryPointY = 25
            } else {
                // Right side menu
                gravityDirectionX = shouldOpen ? -1 : 1
                pushMagnitude = shouldOpen ? -35 : 35
                boundaryPointX = shouldOpen ? width - menuWidth : width + menuWidth + 2
                boundaryPointY = -25
            }

            let gravityBehavior = UIGravityBehavior(items: [sideMenuContainerView])
            gravityBehavior.gravityDirection = CGVector(dx: gravityDirectionX, dy: 0)
            animator.addBehavior(gravityBehavior)

            let collisionBehavior = UICollisionBehavior(items: [sideMenuContainerView])
            collisionBehavior.addBoundary(withIdentifier: "menuBoundary" as NSCopying, from: CGPoint(x: boundaryPointX, y: boundaryPointY),
                                          to: CGPoint(x: boundaryPointX, y: height))
            animator.addBehavior(collisionBehavior)

            let pushBehavior = UIPushBehavior(items: [sideMenuContainerView], mode: .instantaneous)
            pushBehavior.magnitude = pushMagnitude
            animator.addBehavior(pushBehavior)

            let menuViewBehavior = UIDynamicItemBehavior(items: [sideMenuContainerView])
            menuViewBehavior.elasticity = 0.25
            animator.addBehavior(menuViewBehavior)
        } else {
            var destFrame = if menuPosition == .left {
                CGRect(x: shouldOpen ? -2.0 : -menuWidth, y: 0, width: menuWidth, height: height)
            } else {
                CGRect(
                    x: shouldOpen ? width - menuWidth : width + 2.0,
                    y: 0,
                    width: menuWidth,
                    height: height
                )
            }

            UIView.animate(
                withDuration: animationDuration,
                animations: { [weak self] () in
                    self?.sideMenuContainerView.frame = destFrame
                },
                completion: { [weak self] _ in
                    guard let strongSelf = self else { return }
                    if strongSelf.isMenuOpen {
                        strongSelf.delegate?.sideMenuDidOpen()
                    } else {
                        strongSelf.delegate?.sideMenuDidClose()
                    }
                }
            )
        }

        if shouldOpen {
            delegate?.sideMenuWillOpen()
        } else {
            delegate?.sideMenuWillClose()
        }
    }

    open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {

        if delegate?.sideMenuShouldOpenSideMenu() == false {
            return false
        }

        if let swipeGestureRecognizer = gestureRecognizer as? UISwipeGestureRecognizer {
            if !allowLeftSwipe {
                if swipeGestureRecognizer.direction == .left {
                    return false
                }
            }

            if !allowRightSwipe {
                if swipeGestureRecognizer.direction == .right {
                    return false
                }
            }
        } else if gestureRecognizer.isEqual(panRecognizer) {
            if allowPanGesture == false {
                return false
            }
            animator.removeAllBehaviors()
            let touchPosition = gestureRecognizer.location(ofTouch: 0, in: sourceView)
            if menuPosition == .left {
                if isMenuOpen {
                    if touchPosition.x < menuWidth {
                        return true
                    }
                } else {
                    if touchPosition.x < 25 {
                        return true
                    }
                }
            } else {
                if isMenuOpen {
                    if touchPosition.x > sourceView.frame.width - menuWidth {
                        return true
                    }
                } else {
                    if touchPosition.x > sourceView.frame.width - 25 {
                        return true
                    }
                }
            }

            return false
        }
        return true
    }

    @objc func handleGesture(_ gesture: UISwipeGestureRecognizer) {
        toggleMenu((menuPosition == .right && gesture.direction == .left)
            || (menuPosition == .left && gesture.direction == .right))
    }

    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {

        let leftToRight = recognizer.velocity(in: recognizer.view).x > 0

        switch recognizer.state {
        case .began:

            break

        case .changed:

            let translation = recognizer.translation(in: sourceView).x
            let xPoint: CGFloat = sideMenuContainerView.center.x + translation + (menuPosition == .left ? 1 : -1) * menuWidth / 2

            if menuPosition == .left {
                if xPoint <= 0 || xPoint > sideMenuContainerView.frame.width {
                    return
                }
            } else {
                if xPoint <= sourceView.frame.size.width - menuWidth || xPoint >= sourceView.frame.size.width {
                    return
                }
            }

            sideMenuContainerView.center.x += translation
            recognizer.setTranslation(CGPoint.zero, in: sourceView)

        default:
            // swiftlint:disable:next line_length
            let shouldClose = menuPosition == .left ? !leftToRight && sideMenuContainerView.frame.maxX < menuWidth : leftToRight && sideMenuContainerView.frame.minX > (sourceView.frame.size.width - menuWidth)

            toggleMenu(!shouldClose)
        }
    }

    fileprivate func updateSideMenuApperanceIfNeeded() {
        if needUpdateApperance {
            var frame = sideMenuContainerView.frame
            frame.size.width = menuWidth
            sideMenuContainerView.frame = frame
            sideMenuContainerView.layer.shadowPath = UIBezierPath(rect: sideMenuContainerView.bounds).cgPath

            needUpdateApperance = false
        }
    }

    /**
     Toggles the state of the side menu.
     */
    open func toggleMenu() {
        if isMenuOpen {
            toggleMenu(false)
        } else {
            updateSideMenuApperanceIfNeeded()
            toggleMenu(true)
        }
    }

    /**
     Shows the side menu if the menu is hidden.
     */
    open func showSideMenu() {
        if !isMenuOpen {
            toggleMenu(true)
        }
    }

    /**
     Hides the side menu if the menu is showed.
     */
    open func hideSideMenu() {
        if isMenuOpen {
            toggleMenu(false)
        }
    }
}

extension ENSideMenu: UIDynamicAnimatorDelegate {
    public func dynamicAnimatorDidPause(_ animator: UIDynamicAnimator) {
        if isMenuOpen {
            delegate?.sideMenuDidOpen()
        } else {
            delegate?.sideMenuDidClose()
        }
    }
}
