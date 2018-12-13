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
    func selectAlbum(collection: PHCollection)
}

class AlbumViewController: UITableViewController {

    var delegate: albumDelegate? = nil

    // MARK: Properties
    var allAlbums: PHFetchResult<PHAssetCollection>!
    var nonEmptyAllAlbums: [PHAssetCollection] = []
    lazy var defaultAlbum: PHAssetCollection? = {
        if nonEmptyAllAlbums.count > 0 {
            return nonEmptyAllAlbums.first
        }

        PhotoProvider.challengePhotoAuthorization(succeedHanlde: {
            self.fetchAlbumList()
        }, failureHandle: {

        })

        return nonEmptyAllAlbums.count > 0 ? nonEmptyAllAlbums.first:nil
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.setupUI()
        self.photoAuthorization()
        self.fetchAlbumList()
    }

    func photoAuthorization() {
        PhotoProvider.checkAuthorizationStatus { (status) in
            if status != .authorized {
                NSLog("用户未给予相册权限")
            }
        }
    }

    func setupUI() {
        self.tableView.backgroundColor = .white
        self.tableView.separatorStyle = .none
        self.tableView.rowHeight = 78
        self.tableView.register(AlbumTableViewCell.self, forCellReuseIdentifier: AlbumCellIdentifier)
    }

    func fetchAlbumList() {
        allAlbums =  PhotoProvider.fetchAssetCollections()
        nonEmptyAllAlbums = PhotoProvider.vaildPhotoAssetCollections(inFetchResult: allAlbums, exceptEmptyAlbum: true)
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

        allAlbums.enumerateObjects({ (collection, start, stop) in
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
        return nonEmptyAllAlbums.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: AlbumTableViewCell = tableView.dequeueReusableCell(withIdentifier: AlbumCellIdentifier, for: indexPath) as! AlbumTableViewCell

        cell.thumnail = nil

        let collection = nonEmptyAllAlbums[indexPath.row]
        cell.title = collection.localizedTitle
        cell.count = collection.imagesCount
        if let firstImage = collection.newestImage() {
            cell.thumnail = getThumnail(asset: firstImage)
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        var collection: PHCollection

        collection = nonEmptyAllAlbums[indexPath.row]

        if delegate != nil {
            delegate?.selectAlbum(collection: collection)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: PHPhotoLibraryChangeObserver
extension AlbumViewController: PHPhotoLibraryChangeObserver {

    func photoLibraryDidChange(_ changeInstance: PHChange) {

        if let changeDetails = changeInstance.changeDetails(for: allAlbums) {
            allAlbums = changeDetails.fetchResultAfterChanges
            nonEmptyAllAlbums = updatedNonEmptyAlbums()
        }

        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}
