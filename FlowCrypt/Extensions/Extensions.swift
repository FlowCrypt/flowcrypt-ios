//
//  Extensions.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/30/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

// MARK: - Collection

extension Collection {
    subscript(safe index: Index) -> Iterator.Element? {
        indices.contains(index)
            ? self[index]
            : nil
    }

    var isNotEmpty: Bool { !isEmpty }
}

public extension MutableCollection {
    subscript(safe index: Index) -> Iterator.Element? {
        set {
            if indices.contains(index), let newValue = newValue {
                self[index] = newValue
            }
        }
        get {
            return indices.contains(index)
                ? self[index]
                : nil
        }
    }
}

// MARK: - UIView

extension UIView {
    func constraintsToEdges(to guide: UILayoutGuide) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            topAnchor.constraint(equalTo: guide.topAnchor),
            bottomAnchor.constraint(equalTo: guide.bottomAnchor),
        ])
    }

    func constrainToEdges(_ subview: UIView, insets: UIEdgeInsets = .zero) {
        subview.translatesAutoresizingMaskIntoConstraints = false

        let topContraint = NSLayoutConstraint(
            item: subview,
            attribute: .top,
            relatedBy: .equal,
            toItem: self,
            attribute: .top,
            multiplier: 1.0,
            constant: insets.top
        )

        let bottomConstraint = NSLayoutConstraint(
            item: subview,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: self,
            attribute: .bottom,
            multiplier: 1.0,
            constant: -insets.bottom
        )

        let leadingContraint = NSLayoutConstraint(
            item: subview,
            attribute: .leading,
            relatedBy: .equal,
            toItem: self,
            attribute: .leading,
            multiplier: 1.0,
            constant: insets.left
        )

        let trailingContraint = NSLayoutConstraint(
            item: subview,
            attribute: .trailing,
            relatedBy: .equal,
            toItem: self,
            attribute: .trailing,
            multiplier: 1.0,
            constant: -insets.right
        )

        addConstraints([
            topContraint,
            bottomConstraint,
            leadingContraint,
            trailingContraint,
        ])
    }

    func constrainToBorders(_ subview: UIView, insets: UIEdgeInsets = .zero) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        subview.leftAnchor.constraint(equalTo: leftAnchor, constant: insets.left).isActive = true
        subview.rightAnchor.constraint(equalTo: rightAnchor, constant: -insets.right).isActive = true
        subview.topAnchor.constraint(equalTo: topAnchor, constant: insets.top).isActive = true
        subview.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom).isActive = true
    }
}

// MARK: - ReusableView

protocol ReusableView: class {
    static var defaultReuseIdentifier: String { get }
}

extension ReusableView where Self: UIView {
    static var defaultReuseIdentifier: String {
        return String(describing: self)
    }
}

extension UITableViewCell: ReusableView {}

extension UICollectionViewCell: ReusableView {}

extension UICollectionView {
    func register<T: ReusableView>(cellType: T.Type = T.self, bundle: Bundle = Bundle.main) {
        let reuseIdentifier = cellType.defaultReuseIdentifier
        if bundle.path(forResource: reuseIdentifier, ofType: "nib") != nil {
            register(UINib(nibName: reuseIdentifier, bundle: bundle), forCellWithReuseIdentifier: reuseIdentifier)
        } else {
            register(cellType, forCellWithReuseIdentifier: reuseIdentifier)
        }
    }

    func dequeueReusableCell<T>(ofType cellType: T.Type = T.self, at indexPath: IndexPath) -> T where T: UICollectionViewCell {
        let reuseIdentifier = cellType.defaultReuseIdentifier
        guard let cell = dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(reuseIdentifier)")
        }
        return cell
    }
}

extension UITableView {
    func register<T: ReusableView>(cellType: T.Type = T.self, bundle: Bundle = Bundle.main) {
        let reuseIdentifier = cellType.defaultReuseIdentifier
        if bundle.path(forResource: reuseIdentifier, ofType: "nib") != nil {
            register(UINib(nibName: reuseIdentifier, bundle: bundle), forCellReuseIdentifier: reuseIdentifier)
        } else {
            register(cellType, forCellReuseIdentifier: reuseIdentifier)
        }
    }

    func dequeueReusableCell<T>(ofType cellType: T.Type = T.self, at indexPath: IndexPath) -> T where T: UITableViewCell {
        let reuseIdentifier = cellType.defaultReuseIdentifier
        guard let cell = dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(reuseIdentifier)")
        }
        return cell
    }
}

extension Array {
    func chunked(_ size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension UIEdgeInsets {
    static var side: (CGFloat) -> UIEdgeInsets {
        return { side in UIEdgeInsets(top: side, left: side, bottom: side, right: side)}
    }
}
