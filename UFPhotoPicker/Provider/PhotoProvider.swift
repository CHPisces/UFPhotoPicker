//
//  PhotoProvider.swift
//  iCameraApp
//
//  Created by 黄维平 on 2018/12/3.
//  Copyright © 2018 iCam. All rights reserved.
//

import UIKit
import Photos

@objc class PhotoProvider: NSObject {
    @objc enum PPResourceType: Int {
        case image
        case video
        case gif
    }

    typealias writeMeidaDataCompletionBlock = (Bool, String) -> Void

    typealias DeleteMediaDataCompletionBlock = (Bool, Error?) -> Void

    // 检查相册存取权限,如有必要则向系统申请
    @objc open class func checkAuthorizationStatus(_ handler: @escaping (PHAuthorizationStatus) -> Void) {
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()
        if authorizationStatus == .notDetermined {
            PHPhotoLibrary.requestAuthorization { (status) in
                handler(status)
            }
        } else {
             handler(authorizationStatus)
        }
    }

    @objc open class func challengePhotoAuthorization(succeedHanlde: @escaping () -> Void, failureHandle:@escaping () -> Void) {
        self.checkAuthorizationStatus { (status) in
            if status == .authorized {
                succeedHanlde()
            } else {
                failureHandle()
            }
        }
    }

     @objc open class func findLatestPhotoInAlbum(onlyVideo: Bool = false) -> String? {
        let options = PHFetchOptions.init()
        options.sortDescriptors = [NSSortDescriptor.init(key: "modificationDate", ascending: false)]
        let assetsFetchResults = onlyVideo ? PHAsset.fetchAssets(with: .video, options: options).firstObject : PHAsset.fetchAssets(with: options).firstObject
        return assetsFetchResults?.localIdentifier
    }

    class func writeMeidaDataToAlbm(withResource resource: Any?, type: PPResourceType = .image, completion:@escaping (Bool, String?) -> Void) {
        var completionInMainQueue: (Bool, String?) -> Void?
        completionInMainQueue = { (success, localIdentifier) -> Void in
            DispatchQueue.main.async(execute: {
                completion(success, localIdentifier)
            })
        }
        //写操作
        let writeOperation = { () -> Void in
            var mediaLocalIdentifier: String?
            requestAssetCollectionChange(assetOperation: { (collectionRequest) in
                var assetRequest: PHAssetChangeRequest?
                switch type {
                case .image:
                    if let image = resource as? UIImage {
                        assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                    } else if let url = resource as? URL {
                        assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                    } else {
                        completionInMainQueue(false, nil)
                        return
                    }

                case .video:
                    guard let url = resource as? URL else {
                        completionInMainQueue(false, nil)
                        return
                    }
                    assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)

                case .gif:
                    guard let url = resource as? URL else {
                        completionInMainQueue(false, nil)
                        return
                    }
                    assetRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
                }

                if let placeholder = assetRequest?.placeholderForCreatedAsset {
                    mediaLocalIdentifier = placeholder.localIdentifier
                    collectionRequest?.addAssets([placeholder] as NSArray)
                }
            }, completionHandler: {(success, error) in
                if mediaLocalIdentifier != nil && success {
                    print("[PhotoHelper]写数据成功")
                    completionInMainQueue(true, mediaLocalIdentifier)
                } else {
                    print("[PhotoHelper]写数据失败:\(String(describing: error?.localizedDescription))")
                    completionInMainQueue(false, nil)
                }
            })
        }

        self.challengePhotoAuthorization(succeedHanlde: writeOperation) {
            completion(false, nil)
        }
    }


    @objc class func deleteAlbumItem(withAsset asset: PHAsset, completion: @escaping DeleteMediaDataCompletionBlock) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets([asset] as NSFastEnumeration)
        }, completionHandler: completion)
    }

    class func fetchAssetCollection(WithTitle title: String) -> PHAssetCollection? {
        let result = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil) as PHFetchResult
        var resultCollection: PHAssetCollection?
        result.enumerateObjects({(collection, _, _) in
            if let localizedTitle = collection.localizedTitle as NSString? {
                if localizedTitle.contains(title) {
                    resultCollection = collection
                }
            }

        })
        return resultCollection
    }
}

// MARK:- photo helper
extension PhotoProvider {
    @objc open class func saveImageToAlbum(_ image: UIImage, completion:@escaping (Bool, String?) -> Void)  {
        self.writeMeidaDataToAlbm(withResource: image, completion:completion)
    }

    @objc open class func fetchAssetCollections(with type: PHAssetCollectionType = .smartAlbum, subtype: PHAssetCollectionSubtype = .albumRegular, options: PHFetchOptions? = nil) -> PHFetchResult<PHAssetCollection> {
        if options == nil {
            let tmpOptions = PHFetchOptions()
            tmpOptions.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
            return PHAssetCollection.fetchAssetCollections(with: type, subtype: subtype, options: tmpOptions)
        }
       return PHAssetCollection.fetchAssetCollections(with: type, subtype: subtype, options: options)
    }

    @objc open class  func  fetchAsset(in collection: PHAssetCollection) -> PHFetchResult<PHAsset>{
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        return PHAsset.fetchAssets(in: collection, options: options)
    }

    @objc open class func requestImageData(for asset: PHAsset, options: PHImageRequestOptions?, resultHandler: @escaping (Data?, String?, UIImage.Orientation, [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        // Prepare the options to pass when fetching the (photo, or video preview) image.
        if options == nil {
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.isNetworkAccessAllowed = false
            return PHImageManager.default().requestImageData(for: asset, options: options, resultHandler: resultHandler)
        }

        return PHImageManager.default().requestImageData(for: asset, options: options, resultHandler: resultHandler)
    }

    @objc open class func vaildPhotoAssetCollections(inFetchResult result: PHFetchResult<PHAssetCollection> = PhotoProvider.fetchAssetCollections() ,exceptEmptyAlbum: Bool = false) -> [PHAssetCollection] {
        let pointer = ObjCBool.init(false);
        var collections: [PHAssetCollection] = [];
        var cameraRollCollection: PHAssetCollection? = nil;
        var exceptionalSubtypes: [PHAssetCollectionSubtype] = [PHAssetCollectionSubtype.smartAlbumVideos,PHAssetCollectionSubtype.smartAlbumAllHidden,PHAssetCollectionSubtype.smartAlbumTimelapses,PHAssetCollectionSubtype.smartAlbumSlomoVideos]
        if #available(iOS 11.0, *) {
            exceptionalSubtypes .append(PHAssetCollectionSubtype.smartAlbumLivePhotos)
            exceptionalSubtypes .append(PHAssetCollectionSubtype.smartAlbumAnimated)
            exceptionalSubtypes .append(PHAssetCollectionSubtype.smartAlbumLongExposures)
        }

        result .enumerateObjects { (collection, idx, pointer) in
            guard (!exceptEmptyAlbum || collection.imagesCount > 0) && (collection.assetCollectionSubtype.rawValue < 1000) && !exceptionalSubtypes.contains(collection.assetCollectionSubtype) else {return}
                if collection.assetCollectionSubtype == .smartAlbumUserLibrary {
                    cameraRollCollection = collection
                } else {
                    collections .append(collection)
                }
        }

        if let cameraRollCollection = cameraRollCollection {
            collections.insert(cameraRollCollection , at: 0)
        }

       return collections
    }

    @objc open class func fetchThumbnail(withPhotoAsset asset: PHAsset, targetSize: CGSize =  CGSize(width: 200, height: 200), completion:@escaping (PHAsset, UIImage?) -> Void){
        DispatchQueue.global().async {
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.isSynchronous = true
            options.isNetworkAccessAllowed = false
            PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options, resultHandler: { image, _ in
                completion(asset,image)
            })
        }
    }
}

// MARK:- private methods
fileprivate extension PhotoProvider {
    class func requestAssetCollectionChange(assetOperation: @escaping (PHAssetCollectionChangeRequest?) -> Void, completionHandler: ((Bool, Error?) -> Swift.Void)? = nil ) {
        let library = PHPhotoLibrary.shared()
        library.performChanges({
            var collectionRequest: PHAssetCollectionChangeRequest?
            if let assetCollection = fetchAssetCollection(WithTitle: "UFPhotoPicker") {
                collectionRequest = PHAssetCollectionChangeRequest.init(for: assetCollection)
            } else {
                collectionRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: appName)
            }
            assetOperation(collectionRequest)
        }, completionHandler: completionHandler)
    }
}
