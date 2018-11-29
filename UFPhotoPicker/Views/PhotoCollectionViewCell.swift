//
//  PhotoCollectionViewCell.swift
//  UFPhotoPicker
//
//  Created by 曹华 on 2018/11/28.
//  Copyright © 2018年 曹华. All rights reserved.
//

import UIKit

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
    
    var representedAssetIdentifier: String!

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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil
        self.signBadgeImageView.image = nil
    }
}

