//
//  PHAssetCollectionExtension.swift
//  UFPhotoPicker
//
//  Created by 曹华 on 2018/11/28.
//  Copyright © 2018年 曹华. All rights reserved.
//

import Photos

extension PHAssetCollection {
    var imagesCount: Int {
        return PHAsset.fetchAssets(in: self, options: nil).count
    }
    
    func newestImage() -> PHAsset? {
        let images: PHFetchResult = PHAsset.fetchAssets(in: self, options: nil)
        if images.count > 0 {
            return images.lastObject
        }
        return nil
    }
}
