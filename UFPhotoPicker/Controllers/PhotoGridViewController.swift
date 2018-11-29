//
//  PhotoGridViewController.swift
//  UFPhotoPicker
//
//  Created by 曹华 on 2018/11/28.
//  Copyright © 2018年 曹华. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

protocol photoPickerDelegate {
    func selectImageComplete(image: UIImage)
}

private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}

class PhotoGridViewController: UIViewController {

    var itemsPerRow = 4
    var fetchResult: PHFetchResult<PHAsset>!
    var assetCollection: PHAssetCollection!
    var collectionView: UICollectionView!
    var topView: UIView!

    var albumTitle = "PHOTO"
    var closeButton: UIButton!
    var albumButton: UIButton!
    var cameraButton: UIButton!

    var delegate: photoPickerDelegate? = nil

    fileprivate let imageManager = PHCachingImageManager()
    fileprivate var thumbnailSize: CGSize!
    fileprivate var previousPreheatRect = CGRect.zero

    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()

        if fetchResult == nil {
            let allPhotosOptions = PHFetchOptions()
            allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchResult = PHAsset.fetchAssets(with: allPhotosOptions)
        } else {
            resetCachedAssets()
        }

        self.configLayout()
        self.view.insertSubview(self.albumVC.view, belowSubview: self.albumButton)

        PHPhotoLibrary.shared().register(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCachedAssets()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        collectionView?.frame.size = size
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    lazy var albumBgView: UIView = {
        let albumBgView = UIView.init(frame: self.view.bounds)
        albumBgView.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        let tapGes = UITapGestureRecognizer.init(target: self, action: #selector(hiddenAlbum))
        albumBgView.addGestureRecognizer(tapGes)
        self.view.insertSubview(albumBgView, belowSubview: self.albumVC.view)
        return albumBgView
    }()

    @objc private func hiddenAlbum() {
        self.popupAlbum(albumButton: self.albumButton)
    }

    private func setupUI() {
        self.view.backgroundColor = .white

        //topView
        topView = UIView.init(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 44))
        topView.backgroundColor = .white
        self.view.addSubview(topView)

        let titleLabel = UILabel.init()
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.text = albumTitle
        topView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.left.right.lessThanOrEqualToSuperview()
        }

        //closeButton
        closeButton = UIButton(type: .custom)
        closeButton.setBackgroundImage(UIImage(named: "album_button_bg"), for: .normal)
        closeButton.setImage(UIImage(named: "album_close"), for: .normal)
        closeButton.addTarget(self, action: #selector(closeAlbum), for: .touchUpInside)
        self.view.addSubview(closeButton)

        //cameraButton
        cameraButton = UIButton(type: .custom)
        cameraButton.setBackgroundImage(UIImage(named: "album_button_bg"), for: .normal)
        cameraButton.setImage(UIImage(named: "album_camera"), for: .normal)
        cameraButton.addTarget(self, action: #selector(enterCamera), for: .touchUpInside)
        self.view.addSubview(cameraButton)

        //albumButton
        albumButton = UIButton(type: .custom)
        albumButton.semanticContentAttribute = .forceRightToLeft
        albumButton.setBackgroundImage(UIImage(named: "album_album_bg"), for: .normal)
        albumButton.setImage(UIImage(named: "album_album_arrow"), for: .normal)
        albumButton.setTitleColor(.black, for: .normal)
        albumButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        albumButton.addTarget(self, action: #selector(popupAlbum), for: .touchUpInside)
        albumButton.setTitle("Album ", for: .normal)
        self.view.addSubview(albumButton)

        closeButton.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().offset(-25)
            make.left.equalToSuperview().offset(16)
            make.width.height.equalTo(55)
        }
        cameraButton.snp.makeConstraints { (make) in
            make.centerY.height.equalTo(closeButton)
            make.right.equalToSuperview().offset(-16)
            make.width.height.equalTo(closeButton)
        }
        albumButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.height.equalTo(closeButton)
            make.height.equalTo(closeButton)
            make.width.equalTo(114)
        }
    }

    private func configLayout() {

        let lineSpacing = 1
        let interSpacing = 1
        let width = self.view.bounds.width
        let scale = UIScreen.main.scale
        let cellWidth: CGFloat = (width - CGFloat(((itemsPerRow - 1) * interSpacing))) / CGFloat(itemsPerRow)
        thumbnailSize = CGSize(width: cellWidth * scale, height: cellWidth * scale)

        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize.init(width: cellWidth, height: cellWidth)
        layout.minimumInteritemSpacing = CGFloat(interSpacing)
        layout.minimumLineSpacing = CGFloat(lineSpacing)

        collectionView = UICollectionView.init(frame: CGRect(x: 0, y: topView.bounds.height, width: self.view.bounds.width, height: self.view.bounds.height - topView.bounds.height), collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: PhotoCellIdentifier)
        self.view.insertSubview(collectionView, belowSubview: closeButton)

//        if forceTouchAvailable() {
//            self.registerForPreviewing(with: self as! UIViewControllerPreviewingDelegate, sourceView: collectionView)
//        }

    }

    func forceTouchAvailable() -> Bool {
        if #available(iOS 9.0, *) {
            return traitCollection.forceTouchCapability == .available
        } else {
            return false
        }
    }

    lazy var albumVC:AlbumViewController = {
        let albumVC = AlbumViewController.init(style: .plain)
        albumVC.view.frame = CGRect(x: 0, y: self.view.bounds.height, width: self.view.bounds.width, height: self.view.bounds.height - 232)
        albumVC.tableView.contentInset = UIEdgeInsets(top: 11, left: 0, bottom: 0, right: 0)
        albumVC.delegate = self
        return albumVC
    }()

    @objc private func closeAlbum() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc private func popupAlbum(albumButton: UIButton) {
        if albumButton.isSelected {
            UIView.animate(withDuration: 0.3) {
                self.albumVC.view.frame = CGRect(x: 0, y: self.view.bounds.height, width: self.view.bounds.width, height: self.view.bounds.height - 232)
                self.albumBgView.isHidden = true
            }
        }else{
            UIView.animate(withDuration: 0.3) {
                self.albumVC.view.frame = CGRect(x: 0, y: 232, width: self.view.bounds.width, height: self.view.bounds.height - 232)
                self.albumBgView.isHidden = false
            }
        }
        albumButton.isSelected = !albumButton.isSelected
    }

    @objc private func enterCamera() {

    }
}

// MARK: UICollectionView
extension PhotoGridViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let asset = fetchResult.object(at: indexPath.item)

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCellIdentifier, for: indexPath) as? PhotoCollectionViewCell else {
            fatalError("unexpected cell in collection view")
        }

        if #available(iOS 9.1, *) {
            if asset.mediaSubtypes.contains(.photoLive) {
                cell.signBadgeImage = PHLivePhotoView.livePhotoBadgeImage(options: .overContent)
            }
        } else {
            // Fallback on earlier versions
        }

        cell.representedAssetIdentifier = asset.localIdentifier
        imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
            if cell.representedAssetIdentifier == asset.localIdentifier {
                cell.thumbnailImage = image
            }
        })

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset: PHAsset = fetchResult.object(at: indexPath.item)
        self.loadPhoto(asset: asset)
    }

    // Mark: Methods
    func loadPhoto(asset: PHAsset) {
        // Prepare the options to pass when fetching the (photo, or video preview) image.
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = false

        PHImageManager.default().requestImageData(for: asset, options: options) { (imageData, dataUTI, orientation, info) in
            let image = UIImage(data: imageData!)
            if image != nil && self.delegate != nil {
                self.delegate?.selectImageComplete(image: image!)
            }
        }
    }

    // MARK: UIScrollView
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }

    // MARK: Asset Caching
    func resetCachedAssets() {
        imageManager.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }

    func updateCachedAssets() {
        // Update only if the view is visible.
        guard isViewLoaded && view.window != nil else { return }

        // The preheat window is twice the height of the visible rect.
        let visibleRect = CGRect(origin: collectionView!.contentOffset, size: collectionView!.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)

        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }

        // Compute the assets to start caching and to stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }

        // Update the assets the PHCachingImageManager is caching.
        imageManager.startCachingImages(for: addedAssets,
                                        targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        imageManager.stopCachingImages(for: removedAssets,
                                       targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)

        // Store the preheat rect to compare against in the future.
        previousPreheatRect = preheatRect
    }

    fileprivate func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: old.maxY,
                                 width: new.width, height: new.maxY - old.maxY)]
            }
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY,
                                 width: new.width, height: old.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY,
                                   width: new.width, height: old.maxY - new.maxY)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: old.minY,
                                   width: new.width, height: new.minY - old.minY)]
            }
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }
}

// MARK: albumDelegate
extension PhotoGridViewController: albumDelegate {
    func selectAlbum(fetchResult: PHFetchResult<PHAsset>!) {
        self.fetchResult = fetchResult
        self.collectionView.reloadData()

        self.popupAlbum(albumButton: self.albumButton)
    }
}

//!!!!: 3D Touch
//extension PhotoGridViewController: UIViewControllerPreviewingDelegate {
//    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
//        let indexPath: IndexPath? = collectionView.indexPathForItem(at: location)
//        if indexPath == nil {
//            return nil
//        }
//        var cell: UICollectionViewCell? = nil
//        if let aPath = indexPath {
//            cell = collectionView.cellForItem(at: aPath)
//        }
//        if (cell is PhotoCollectionViewCell) {
//            return nil
//        }
//    }
//
//    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
//
//    }
//}

// MARK: PHPhotoLibraryChangeObserver
extension PhotoGridViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        guard let changes = changeInstance.changeDetails(for: fetchResult) else {
            return
        }
        
        DispatchQueue.main.sync {
            self.fetchResult = changes.fetchResultAfterChanges
            if changes.hasIncrementalChanges {
                guard let collectionView = self.collectionView else { fatalError() }
                collectionView.performBatchUpdates({
                    
                    if let removed = changes.removedIndexes, removed.count > 0 {
                        collectionView.deleteItems(at: removed.map({ IndexPath(item: $0, section: 0) }))
                    }
                    if let inserted = changes.insertedIndexes, inserted.count > 0 {
                        collectionView.insertItems(at: inserted.map({ IndexPath(item: $0, section: 0) }))
                    }
                    if let changed = changes.changedIndexes, changed.count > 0 {
                        collectionView.reloadItems(at: changed.map({ IndexPath(item: $0, section: 0) }))
                    }
                    
                    changes.enumerateMoves { fromIndex, toIndex in
                        collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                                to: IndexPath(item: toIndex, section: 0))
                    }
                })
            } else {
                self.collectionView!.reloadData()
            }
            self.resetCachedAssets()
        }
    }
}


