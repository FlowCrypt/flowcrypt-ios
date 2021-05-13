//
//  ASSegmentedViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/9/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

// TODO: - ANTON - Move to FlowCryptUI
struct Segment {
    let viewController: UIViewController
    let title: NSAttributedString
}

struct SegmentStyle {
    static let `default` = SegmentStyle(
        height: 50,
        insets: UIEdgeInsets.side(8),
        tabTintColor: .main,
        lineColor: .white
    )
    let height: CGFloat
    let insets: UIEdgeInsets
    let tabTintColor: UIColor
    let lineColor: UIColor
}

// TODO: - Move to page tab based layout
final class SegmentedViewController: ASDKViewController<ASDisplayNode> {
    private var dataSource: [Segment] = []
    private var collectionNode = ASCollectionNode(
        collectionViewLayout: UICollectionViewFlowLayout()
    )
    private var style: SegmentStyle = .default
    private var segmentView = ASDisplayNode()
    private let backgroundBar = ASDisplayNode()

    init(
        dataSource: [Segment],
        style: SegmentStyle = .default
    ) {
        self.dataSource = dataSource
        self.style = style
        super.init(node: ASDisplayNode())
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        collectionNode.selectItem(
            at: IndexPath(row: 0, section: 0),
            animated: false,
            scrollPosition: .left
        )
        selectViewController(with: 0)
    }

    private func setup() {
        node.addSubnode(backgroundBar)
        node.addSubnode(collectionNode)
        node.addSubnode(segmentView)

        collectionNode.do {
            $0.backgroundColor = style.tabTintColor
            $0.view.contentInsetAdjustmentBehavior = .never
            $0.dataSource = self
            $0.delegate = self
        }
        backgroundBar.backgroundColor = style.tabTintColor
        segmentView.backgroundColor = .backgroundColor
        node.backgroundColor = .backgroundColor
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let calculatedWidth = dataSource
            .map(\.title)
            .map { $0.size().width }
            .reduce(0, +)
        let collectionWidth = calculatedWidth
            + CGFloat(dataSource.count + 1) * style.insets.width
        let originX = (view.frame.size.width - collectionWidth) / 2

        collectionNode.frame = CGRect(
            x: originX,
            y: 0,
            width: node.view.frame.width,
            height: style.height
        )
        backgroundBar.frame = CGRect(
            x: 0,
            y: 0,
            width: node.view.frame.width,
            height: style.height
        )
        segmentView.frame = CGRect(
            x: 0,
            y: style.height,
            width: node.view.frame.width,
            height: node.view.frame.height - style.height
        )
        segmentView.view.subviews.forEach {
            $0.frame = segmentView.bounds
        }
    }
}

// MARK: - ASCollectionDataSource

extension SegmentedViewController: ASCollectionDataSource, ASCollectionDelegate {
    func collectionNode(_: ASCollectionNode, numberOfItemsInSection _: Int) -> Int {
        dataSource.count
    }

    func collectionNode(_: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        { [weak self] in
            guard let self = self, let item = self.dataSource[safe: indexPath.row] else { return ASCellNode() }

            return SetupTitleNode(
                SetupTitleNode.Input(
                    title: item.title,
                    insets: UIEdgeInsets(top: 16, left: 8, bottom: 8, right: 8),
                    selectedLineColor: self.style.lineColor,
                    backgroundColor: .main
                )
            )
        }
    }

    func collectionNode(_: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        selectViewController(with: indexPath.row)
    }
}

// MARK: - Actions

extension SegmentedViewController {
    private func selectViewController(with index: Int) {
        guard let viewController = dataSource[safe: index]?.viewController else {
            return assertionFailure()
        }

        UIView.animate(
            withDuration: 0.2,
            animations: {
                self.segmentView.view.subviews.forEach { $0.alpha = 0 }
            },
            completion: { _ in
                self.segmentView.view.subviews.forEach { $0.removeFromSuperview() }

                self.children.forEach {
                    $0.removeFromParent()
                    $0.didMove(toParent: nil)
                }

                self.addChild(viewController)
                self.segmentView.view.addSubview(viewController.view)
                self.node.view.setNeedsLayout()
                viewController.view.alpha = 0
                UIView.animate(
                    withDuration: 0.2,
                    animations: {
                        viewController.view.alpha = 1
                    }, completion: { _ in
                        viewController.didMove(toParent: self)
                    }
                )
            }
        )
    }
}
