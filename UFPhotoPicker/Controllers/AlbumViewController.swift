//
//  AlbumViewController.swift
//  UFPhotoPicker
//
//  Created by 曹华 on 2018/11/28.
//  Copyright © 2018年 曹华. All rights reserved.
//

import UIKit
import Photos

protocol albumDelegate {
    func selectAlbum(fetchResult: PHFetchResult<PHAsset>!)
}

class AlbumViewController: UITableViewController {

    var delegate: albumDelegate? = nil
    
    // MARK: Properties
    var smartAlbums: PHFetchResult<PHAssetCollection>!
    var nonEmptySmartAlbums: [PHAssetCollection] = []

    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        PHPhotoLibrary.checkAuthorizationStatus(completionHandler: { status in
            if !status {
                // not authorized => add a lock view
                let lockView: AuthLockView = AuthLockView.init(frame: self.view.bounds)
                if let topView = self.navigationController?.view {
                    lockView.frame = topView.frame
                    lockView.delegate = self
                    lockView.title = "Please allow to access your Photos"
                    lockView.detail = "Without this, UFOTO can't read your photos and save edited photos to camera roll."
                    lockView.buttonTitle = "Enable Photos Access"
                    topView.addSubview(lockView)
                }
            }
        })

        smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
        nonEmptySmartAlbums = updatedNonEmptyAlbums()

        self.tableView.separatorStyle = .none
        self.tableView.rowHeight = 78
        self.tableView.register(AlbumTableViewCell.self, forCellReuseIdentifier: AlbumCellIdentifier)
        
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
}

// MARK: Fileprivate Method
fileprivate extension AlbumViewController {
    
    func getThumnail(asset: PHAsset) -> UIImage? {
        var thumnail: UIImage?
        DispatchQueue.global().sync {
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.isSynchronous = true
            options.isNetworkAccessAllowed = false
            PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 200, height: 200), contentMode: .aspectFit, options: options, resultHandler: { image, _ in
                if let image = image {
                    thumnail = image
                }
            })
        }
        return thumnail
    }
    
    // PHCollection => (PHCollectionList, PHAssetCollection)
    func flattenCollectionList(_ list: PHCollectionList) -> [PHAssetCollection] {
        
        var assetCollections: [PHAssetCollection] = []
        let tempCollections = PHCollectionList.fetchCollections(in: list, options: nil)
        
        tempCollections.enumerateObjects({ [weak self] (collection, start, stop) in
            if let assetCollection = collection as? PHAssetCollection {
                assetCollections.append(assetCollection)
            } else if let collectionList = collection as? PHCollectionList {
                assetCollections.append(contentsOf: self!.flattenCollectionList(collectionList))
            }
        })
        return assetCollections
    }
    
    func updatedNonEmptyAlbums() -> [PHAssetCollection] {
        var curNonEmptyAlbums: [PHAssetCollection] = []
        
        smartAlbums.enumerateObjects({ (collection, start, stop) in
            if collection.imagesCount > 0 {
                curNonEmptyAlbums.append(collection)
            }
        })
        
        return curNonEmptyAlbums
    }
}

// MARK: UITableViewDataSource
extension AlbumViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nonEmptySmartAlbums.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: AlbumTableViewCell = tableView.dequeueReusableCell(withIdentifier: AlbumCellIdentifier, for: indexPath) as! AlbumTableViewCell
        
        cell.thumnail = nil

        let collection = nonEmptySmartAlbums[indexPath.row]
        cell.title = collection.localizedTitle
        cell.count = collection.imagesCount
        if let firstImage = collection.newestImage() {
            cell.thumnail = getThumnail(asset: firstImage)
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var selectFetchResult: PHFetchResult<PHAsset>!

        var collection: PHCollection
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        collection = nonEmptySmartAlbums[indexPath.row]
        selectFetchResult = PHAsset.fetchAssets(in: collection as! PHAssetCollection, options: options)

        if delegate != nil {
            delegate?.selectAlbum(fetchResult: selectFetchResult)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: AuthLockViewDelegates
extension AlbumViewController: AuthLockViewDelegate {
    
    func toSetting() {
        PHPhotoLibrary.guideToSetting()
    }
}

// MARK: PHPhotoLibraryChangeObserver
extension AlbumViewController: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        if let changeDetails = changeInstance.changeDetails(for: smartAlbums) {
            smartAlbums = changeDetails.fetchResultAfterChanges
            nonEmptySmartAlbums = updatedNonEmptyAlbums()
        }
        
        DispatchQueue.main.async {
           self.tableView.reloadData()
        }
    }
}
