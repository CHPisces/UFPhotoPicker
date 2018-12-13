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
    func selectImageComplete(photoPicker: UIViewController,resultImage: UIImage,userInfo:[String : Any])
    func enterCamera(photoPicker: UIViewController)
}

private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}

class PhotoGridViewController: UIViewController {

    @objc var puzzleChangeImage = false
    @objc var userInfo: [String : Any] = [:]

    var albumOriginY: CGFloat = 232.0 / 667 * UI.ScreenHeight
    var itemsPerRow = 4
    var fetchResult: PHFetchResult<PHAsset>?
    var assetCollection: PHAssetCollection?
    var collectionView: UICollectionView?
    var topView: UIView?
    var titleLabel: UILabel?
    var scrollIdxHistory = 0 //记录在上次刷新数据后滚到的最远距离

    fileprivate var closeButton = UIButton()
    fileprivate var albumButton = UIButton()
    fileprivate var cameraButton = UIButton()

    var delegate: photoPickerDelegate? = nil

    fileprivate let imageManager = PHCachingImageManager()
    fileprivate var thumbnailSize: CGSize?
    fileprivate var previousPreheatRect = CGRect.zero

    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupUI()
        self.configLayout()
        self.view.insertSubview(self.albumVC.view, belowSubview: self.albumButton)

        UIApplication.shared.requestAccessToPhotos(success: {
            DispatchQueue.main.async {
                if self.fetchResult == nil , let defaultAlbum = self.albumVC.defaultAlbum {
                    self.loadAlbumData(collection: defaultAlbum)
                } else {
                    self.resetCachedAssets()
                }
            }
        }) {

        }

        PHPhotoLibrary.shared().register(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.requestAccessToPhotos(success: {

        }) {
            let alertController = UIAlertController(title: "提醒", message: "请开启相册权限", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "确认", style: .default, handler: { action in
                PHPhotoLibrary.guideToSetting()
            })
            let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: {action in
                self.closeAlbum()
            })
            alertController.addAction(okAction)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
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
        albumBgView.backgroundColor = UIColor(hexColor: "#242424").withAlphaComponent(0.5)
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
        let topView = UIView.init(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 44 + UI.SafeTopHeight))
        topView.backgroundColor = .white
        self.view.addSubview(topView)
        let taptap = UITapGestureRecognizer(target: self, action: #selector(scrollToTop))
        taptap.numberOfTapsRequired = 2
        topView.addGestureRecognizer(taptap)
        self.topView = topView

        let titleLabel = UILabel.init()
        titleLabel.textColor = UIColor(hexColor: "#1F1F22")
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.text = L("Album")
        topView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(UI.SafeTopHeight * 0.7)
            make.left.right.lessThanOrEqualToSuperview()
        }
        self.titleLabel = titleLabel

        //closeButton
        closeButton = UIButton.init(type: .custom)
        closeButton.setBackgroundImage(UIImage(named: "album_button_bg"), for: .normal)
        closeButton.setImage(UIImage(named: "album_close"), for: .normal)
        closeButton.addTarget(self, action: #selector(closeAlbum), for: .touchUpInside)
        self.view.addSubview(closeButton)

        //cameraButton
        cameraButton = UIButton.init(type: .custom)
        cameraButton.setBackgroundImage(UIImage(named: "album_button_bg"), for: .normal)
        cameraButton.setImage(UIImage(named: "album_camera"), for: .normal)
        cameraButton.addTarget(self, action: #selector(enterCamera), for: .touchUpInside)
        self.view.addSubview(cameraButton)

        //albumButton
        albumButton = UIButton.init(type: .custom)
        albumButton.semanticContentAttribute = .forceRightToLeft
        albumButton.setBackgroundImage(UIImage(named: "album_album_bg"), for: .normal)
        albumButton.setImage(UIImage(named: "album_album_arrow"), for: .normal)
        albumButton.setTitleColor(.black, for: .normal)
        albumButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        albumButton.addTarget(self, action: #selector(popupAlbum), for: .touchUpInside)
        albumButton.setTitle(L("Album") + " ", for: .normal)
        self.view.addSubview(albumButton)

        closeButton.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().offset(-23 - UI.SafeBottomHeight * 0.5)
            make.left.equalToSuperview().offset(16)
            make.width.equalTo(57)
            make.height.equalTo(57)
        }
        cameraButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(closeButton)
            make.right.equalToSuperview().offset(-16)
            make.width.height.equalTo(closeButton)
        }
        albumButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(closeButton)
            make.height.equalTo(55)
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

        let collectionView = UICollectionView.init(frame: CGRect(x: 0, y: topView?.frame.maxY ?? 0, width: self.view.bounds.width, height: self.view.bounds.height - (topView?.frame.maxY ?? 0)), collectionViewLayout: layout)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 105, right: 0)
        collectionView.backgroundColor = .white
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: PhotoCellIdentifier)
        self.view.insertSubview(collectionView, belowSubview: closeButton)
        self.collectionView = collectionView

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
        albumVC.view.frame = CGRect(x: 0, y: self.view.bounds.height, width: self.view.bounds.width, height: self.view.bounds.height - albumOriginY)
        albumVC.tableView.contentInset = UIEdgeInsets(top: 11, left: 0, bottom: 0, right: 0)
        albumVC.delegate = self
        return albumVC
    }()

    @objc private func closeAlbum() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc private func popupAlbum(albumButton: UIButton) {
        //创建动画
        let anim = CABasicAnimation()
        anim.keyPath = "transform.rotation"
        anim.duration = 0.3

        if albumButton.isSelected {
            anim.toValue = 0
            UIView.animate(withDuration: 0.3) {
                self.albumVC.view.frame = CGRect(x: 0, y: self.view.bounds.height, width: self.view.bounds.width, height: self.view.bounds.height - self.albumOriginY)
                self.albumBgView.isHidden = true
            }
        }else{
            UIView.animate(withDuration: 0.3) {
                self.albumVC.view.frame = CGRect(x: 0, y: self.albumOriginY, width: self.view.bounds.width, height: self.view.bounds.height - self.albumOriginY)
                self.albumBgView.isHidden = false
            }
            anim.toValue = Double.pi
        }

        anim.isRemovedOnCompletion = false
        anim.fillMode = CAMediaTimingFillMode.forwards
        albumButton.imageView?.layer.add(anim, forKey: nil)

        albumButton.isSelected = !albumButton.isSelected
    }

    //MARK:enterCamera
    @objc private func enterCamera() {

    }
}

// MARK: albumDelegate
extension PhotoGridViewController: albumDelegate {
    func selectAlbum(collection: PHCollection) {
        UIView.animate(withDuration: 0.3, animations: {
            self.collectionView?.alpha = 0
        }) { (_) in
            self.loadAlbumData(collection: collection)
            self.collectionView?.alpha = 1
        }

        self.popupAlbum(albumButton: self.albumButton)
    }

    func loadAlbumData(collection: PHCollection) {
        self.fetchResult = PhotoProvider.fetchAsset(in: collection as! PHAssetCollection)
        self.titleLabel?.text = collection.localizedTitle ?? L("Album")
        self.reloadPhotoData()
    }
}

// MARK: UICollectionView
extension PhotoGridViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.fetchResult?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let asset = self.fetchResult?.object(at: indexPath.item) else {
            return UICollectionViewCell()
        }

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCellIdentifier, for: indexPath) as? PhotoCollectionViewCell else {
            return UICollectionViewCell()
        }

        if #available(iOS 9.1, *) {
            if asset.mediaSubtypes.contains(.photoLive) {
                cell.signBadgeImage = PHLivePhotoView.livePhotoBadgeImage(options: .overContent)
            }
        }

        cell.representedAssetIdentifier = asset.localIdentifier

        imageManager.requestImage(for: asset, targetSize: thumbnailSize ?? .zero, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
            if cell.representedAssetIdentifier == asset.localIdentifier {
                cell.thumbnailImage = image
            }
        })

        if scrollIdxHistory <= indexPath.item {
            animateCell(cell, deadline: DispatchTime.now() + .milliseconds((indexPath.item - scrollIdxHistory) * 100))
            scrollIdxHistory = indexPath.item
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let asset: PHAsset = self.fetchResult?.object(at: indexPath.item) else {
            return
        }

        self.loadPhoto(asset: asset)
    }

    func reloadPhotoData() {
        scrollIdxHistory = 0
        self.collectionView!.reloadData()
        scrollIdxHistory = self.collectionView?.visibleCells.count ?? 0
        self.scrollToTop()
    }

    // Mark: Methods
    func loadPhoto(asset: PHAsset) {
        _ = PhotoProvider.requestImageData(for: asset, options: nil) { (imageData, dataUTI, orientation, info) in
            let image = UIImage(data: imageData!)
            self.selectImageComplete(image)
        }
    }

    // MARK: selectImageComplete
    func selectImageComplete(_ image: UIImage?) {
        DispatchQueue.main.async(execute: {
            if self.puzzleChangeImage {

                self.dismiss(animated: true)
                return
            }
            let identifier = self.userInfo["identifier"] as? String
            if (identifier == "challenge") {

                self.dismiss(animated: true)
                return
            }
        })
    }

    // MARK:- cell动画
    private func animateCell(_ cell: UICollectionViewCell, deadline: DispatchTime) {
        cell.alpha = 0
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            UIView.animate(withDuration: 0.6) {
                cell.alpha = 1
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if scrollIdxHistory < indexPath.item {
            animateCell(cell, deadline: DispatchTime.now() + .milliseconds((indexPath.item - scrollIdxHistory) * 100))
            scrollIdxHistory = indexPath.item;
        }
    }

    @objc fileprivate func scrollToTop() {
        if self.collectionView?.numberOfItems(inSection: 0) ?? 0 > 0 {
            self.collectionView?.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
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
        guard let fetchResult = self.fetchResult, let collectionView = self.collectionView else { return }

        // The preheat window is twice the height of the visible rect.
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)

        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }

        // Compute the assets to start caching and to stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in collectionView.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in collectionView.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }

        // Update the assets the PHCachingImageManager is caching.
        imageManager.startCachingImages(for: addedAssets,
                                        targetSize: thumbnailSize ?? .zero, contentMode: .aspectFill, options: nil)
        imageManager.stopCachingImages(for: removedAssets,
                                       targetSize: thumbnailSize ?? .zero, contentMode: .aspectFill, options: nil)

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

// MARK: PHPhotoLibraryChangeObserver
extension PhotoGridViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let fetchResult = self.fetchResult , let changes = changeInstance.changeDetails(for: fetchResult) else {
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
                self.reloadPhotoData()
            }
            self.resetCachedAssets()
        }
    }
}
