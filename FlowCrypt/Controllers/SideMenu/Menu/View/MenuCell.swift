//
//  MenuCell.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/13/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

final class MenuCell: UITableViewCell {
    enum Constants {
        static let imageSize = CGSize(width: 24, height: 24)
    }
    private let titleLabel = UILabel()
    private let menuImageView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    private func setup() {
        selectionStyle = .none
        contentView.addSubview(titleLabel)
        contentView.addSubview(menuImageView)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.attributedText = nil
        menuImageView.image = nil
    }

    func setup(with viewModel: FolderViewModel) -> Self {
        titleLabel.attributedText = viewModel.attributedTitle()
        menuImageView.image = viewModel.image
        setNeedsLayout()
        layoutIfNeeded()
        return self
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let y: CGFloat = 8
        let textSize = titleLabel.attributedText?.size() ?? .zero

        if menuImageView.image == nil {
            menuImageView.frame = .zero
            titleLabel.frame = CGRect(
                x: 16,
                y: y,
                width: textSize.width,
                height: textSize.height
            )
        } else {
            menuImageView.frame = CGRect(
                x: 16,
                y: y,
                width: Constants.imageSize.width,
                height: Constants.imageSize.height
            )

            titleLabel.frame = CGRect(
                x: menuImageView.frame.maxX + 8,
                y: y,
                width: textSize.width,
                height: textSize.height
            )
        } 
    }

}

