//
//  PhotoCollectionViewCell.swift
//  UFPhotoPicker
//
//  Created by 曹华 on 2018/11/28.
//  Copyright © 2018年 曹华. All rights reserved.
//

import UIKit
import Photos

let PhotoCellIdentifier = "PhotoCellIdentifier"


class PhotoCollectionViewCell: UICollectionViewCell {

    lazy var imageView: UIImageView = {
        let imageView = UIImageView.init(frame: self.contentView.bounds)
        imageView.contentMode = .scaleToFill
        imageView.clipsToBounds = true
        self.contentView.addSubview(imageView)
        return imageView
    }()

    lazy var signBadgeImageView: UIImageView = {
        let signBadgeImageView = UIImageView.init(frame: CGRect(x: 10, y: 10, width: 30, height: 30))
        signBadgeImageView.contentMode = .scaleAspectFit
        self.contentView.insertSubview(signBadgeImageView, aboveSubview: self.imageView)
        return signBadgeImageView
    }()

    lazy var selectedBgView: UIView = {
        let selectedBgView = UIView(frame: self.contentView.bounds)
        selectedBgView.isHidden = true
        selectedBgView.backgroundColor = UIColor(hexColor: "#1F1F22", alpha: 0.8)
        self.contentView.insertSubview(selectedBgView, aboveSubview: self.imageView)
        return selectedBgView
    }()

    lazy var badgeNumberLabel: UILabel = {
        let badgeNumberLabel = UILabel()
        badgeNumberLabel.textAlignment = .center
        badgeNumberLabel.font = UIFont.systemFont(ofSize: 26)
        badgeNumberLabel.textColor = .white
        self.selectedBgView.addSubview(badgeNumberLabel)
        badgeNumberLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(11 * UI.ScreenScale)
            make.top.equalToSuperview().offset(7 * UI.ScreenScale)
        }
        return badgeNumberLabel
    }()

    lazy var deleteIconView: UIImageView = {
        let deleteIconView = UIImageView(image: UIImage.init(named: "album_photo_selection_delete"))
        deleteIconView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(deleteItem))
        deleteIconView.addGestureRecognizer(tap)
        self.selectedBgView.addSubview(deleteIconView)
        deleteIconView.snp.makeConstraints { (make) in
            make.width.height.equalTo(24)
            make.bottom.equalToSuperview().offset(-7 * UI.ScreenScale)
            make.right.equalToSuperview().offset(-7 * UI.ScreenScale)
        }
        return deleteIconView
    }()
    
    weak var asset: PHAsset?

    var badgeNumber: Int = 0 {
        didSet {
            self.selectedBgView.isHidden = badgeNumber <= 0
            self.badgeNumberLabel.text = "\(badgeNumber)"
            self.deleteIconView.isHidden = badgeNumber <= 0
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        self.init()
    }

    var thumbnailImage: UIImage! {
        didSet {
            self.imageView.contentMode = .scaleAspectFill
            self.imageView.image = thumbnailImage
        }
    }
    var signBadgeImage: UIImage! {
        didSet {
            self.signBadgeImageView.image = signBadgeImage
        }
    }

    @objc func deleteItem(){
        if let asset = self.asset {
            NotificationCenter.default.post(name: NSNotification.Name.init("PhotoSelectionDidRemoveItemNotification"), object: asset)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil
        self.signBadgeImageView.image = nil
        self.badgeNumber = 0
    }
}

