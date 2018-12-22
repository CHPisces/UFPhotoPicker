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
    func selectedAssetDidChanged(_ assets: [PHAsset])
    func enterCamera(photoPicker: UIViewController)
}

private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}

@objcMembers
class PhotoGridViewController: UIViewController {

    var isColleageMode = false
    var maxSeletedNumber = 1
    var puzzleChangeImage = false
    var userInfo: [String : Any] = [:]
    var selectedAssetsArray: [PHAsset] = []
    var albumViewHeight: CGFloat =  435.0 / 667 * UI.ScreenHeight
    var itemsPerRow = 4
    var fetchResult: PHFetchResult<PHAsset>?
    var assetCollection: PHAssetCollection?
    var collectionView: UICollectionView?
    var topView: UIView?
    var titleLabel: UILabel?
    var scrollIdxHistory = 0 //记录在上次刷新数据后滚到的最远距离
    fileprivate var imageRequestId: PHImageRequestID?

    fileprivate var closeButton = ICHighlightButton()
    fileprivate var albumButton = ICHighlightButton()
    fileprivate var cameraButton = ICHighlightButton()

    var delegate: photoPickerDelegate? = nil

    fileprivate lazy var imageManager = PHCachingImageManager()
    fileprivate var thumbnailSize: CGSize?
    fileprivate var previousPreheatRect = CGRect.zero

    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupUI()
        self.configLayout()

        UIApplication.shared.requestAccessToPhotos(success: {
            DispatchQueue.main.async {
                if self.fetchResult == nil, let defaultAlbum = self.albumVC.defaultAlbum {
                    self.loadAlbumData(collection: defaultAlbum)
                    PHPhotoLibrary.shared().register(self)
                } else {
                    self.resetCachedAssets()
                }
                PhotoProvider.register(self)
            }
        }, andFailure: nil)
    }

    convenience init(withColleageMode colleageMode: Bool) {
        self.init()
        self.isColleageMode = colleageMode
        imageManager.allowsCachingHighQualityImages = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCachedAssets()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let imageReqID = imageRequestId, imageReqID > 0 {
            PHImageManager.default().cancelImageRequest(imageReqID)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        collectionView?.frame.size = size
    }

    deinit {
        PhotoProvider.unregisterChangeObserver(self)
        NotificationCenter.default.removeObserver(self)
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
        self.popupAlbum()
    }

    private func setupUI() {
        self.view.backgroundColor = UIColor(hexColor: "#29292C")

        let labelTextColor: UIColor =  .white

        //topView
        let topView = UIView.init(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 52 + UI.SafeTopHeight))
        topView.backgroundColor = UIColor(hexColor: "#1F1F22")
        self.view.addSubview(topView)
        let taptap = UITapGestureRecognizer(target: self, action: #selector(scrollToTop))
        taptap.delegate = self
        taptap.numberOfTapsRequired = 2
        topView.addGestureRecognizer(taptap)
        self.topView = topView

        let titleLabel = UILabel.init()
        titleLabel.textColor = labelTextColor
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.text = L("Album")
        topView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(UI.SafeTopHeight * 0.6)
            make.width.equalTo(200)
        }
        self.titleLabel = titleLabel

        if self.isColleageMode {
            closeButton = ICHighlightButton.init(textColor: nil, highlightStyle: .totalNormal, zoomStyle: .out)
            closeButton.setImage(UIImage(named: "home_normal"), for: .normal)
            closeButton.addTarget(self, action: #selector(closeAlbum), for: .touchUpInside)
            topView.addSubview(closeButton)

            albumButton = ICHighlightButton.init(textColor: nil, highlightStyle: .totalNormal, zoomStyle: .out)
            albumButton.setTitleColor(.white, for: .normal)
            albumButton.setTitleColor(.lightGray, for: .highlighted)
            albumButton.titleLabel?.textAlignment = .right
            albumButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            albumButton.addTarget(self, action: #selector(popupAlbum), for: .touchUpInside)
            albumButton.setTitle(L("Album") + " ", for: .normal)
            topView.addSubview(albumButton)

            closeButton.snp.makeConstraints { (make) in
                make.centerY.equalTo(titleLabel)
                make.left.equalToSuperview().offset(13)
                make.width.height.equalTo(40)
            }

            albumButton.snp.makeConstraints { (make) in
                make.right.equalToSuperview().offset(-13)
                make.centerY.equalTo(titleLabel)
                make.width.equalTo(albumButton.titleLabel?.estimatedWidth(withMaxWidth: 100) ?? 0)
            }
            closeButton.setEnlargeEdge(10)
            albumButton.setEnlargeEdge(10)
            return
        }

        //closeButton
        closeButton = ICHighlightButton.init(textColor: nil, highlightStyle: .imageNormal, zoomStyle: .out)
        closeButton.setBackgroundImage(UIImage(named: "album_button_bg"), for: .normal)
        closeButton.setImage(UIImage(named: "album_close"), for: .normal)
        closeButton.addTarget(self, action: #selector(closeAlbum), for: .touchUpInside)
        self.view.addSubview(closeButton)

        //cameraButton
        cameraButton = ICHighlightButton.init(textColor: nil, highlightStyle: .imageNormal, zoomStyle: .out)
        cameraButton.setBackgroundImage(UIImage(named: "album_button_bg"), for: .normal)
        cameraButton.setImage(UIImage(named: "album_camera"), for: .normal)
        cameraButton.addTarget(self, action: #selector(enterCamera), for: .touchUpInside)
        self.view.addSubview(cameraButton)

        //albumButton
        albumButton = ICHighlightButton.init(textColor: nil, highlightStyle: .imageNormal, zoomStyle: .out)
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
        let scale = min(2, UIScreen.main.scale)
        let cellWidth: CGFloat = (width - CGFloat(((itemsPerRow - 1) * interSpacing))) / CGFloat(itemsPerRow)
        thumbnailSize = CGSize(width: cellWidth * scale, height: cellWidth * scale)

        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize.init(width: cellWidth, height: cellWidth)
        layout.minimumInteritemSpacing = CGFloat(interSpacing)
        layout.minimumLineSpacing = CGFloat(lineSpacing)

        let collectionView = UICollectionView.init(frame: CGRect(x: 0, y: topView?.frame.maxY ?? 0, width: self.view.bounds.width, height: self.view.bounds.height - (topView?.frame.maxY ?? 0)), collectionViewLayout: layout)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom:self.isColleageMode ? (150 + (Dev.IsIPhoneX ? 34:0)):105, right: 0)
        collectionView.backgroundColor = UIColor(hexColor: "#29292C")
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsMultipleSelection = self.isColleageMode
        collectionView.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: PhotoCellIdentifier)
        self.view.insertSubview(collectionView, belowSubview: topView ?? closeButton)
        self.collectionView = collectionView
        if self.isColleageMode {
            self.view.insertSubview(self.albumVC.view, belowSubview: topView ?? collectionView)
        } else {
            self.view.insertSubview(self.albumVC.view, belowSubview: albumButton)
        }
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
        albumVC.isDarkStyle = true
        albumVC.view.frame = CGRect(x: 0, y: self.isColleageMode ? -albumViewHeight:self.view.bounds.height, width: self.view.bounds.width, height:albumViewHeight)
        albumVC.tableView.contentInset = UIEdgeInsets(top: 11, left: 0, bottom: 0, right: 0)
        albumVC.delegate = self
        return albumVC
    }()

    @objc private func closeAlbum() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func updateSelectedAssets(_ assets: [PHAsset]) {
        self.selectedAssetsArray = assets
        self.updateVisibleCellsStatus()
    }

    @objc private func popupAlbum() {
        if self.isColleageMode {
            UIView.animate(withDuration: 0.3) {
                self.albumVC.view.frame = CGRect(x: 0, y: self.albumButton.isSelected ? (-self.albumViewHeight):self.topView?.frame.maxY ?? 0, width: self.view.bounds.width, height:self.albumViewHeight)
            }

            albumButton.isSelected = !albumButton.isSelected
            self.albumBgView.isHidden = !albumButton.isSelected
            return
        }

        //创建动画
        let anim = CABasicAnimation()
        anim.keyPath = "transform.rotation"
        anim.duration = 0.3

        if albumButton.isSelected {
            anim.toValue = 0
            UIView.animate(withDuration: 0.3) {
                self.albumVC.view.frame = CGRect(x: 0, y: self.view.bounds.height, width: self.view.bounds.width, height:self.albumViewHeight)
                self.albumBgView.isHidden = true
            }
        }else{
            UIView.animate(withDuration: 0.3) {
                self.albumVC.view.frame = CGRect(x: 0, y:  self.view.frame.height - self.albumViewHeight, width: self.view.bounds.width, height:self.albumViewHeight)
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

        self.popupAlbum()
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
        guard let fetchResult = self.fetchResult else { return UICollectionViewCell() }
        guard indexPath.item < fetchResult.count else {
            return UICollectionViewCell()
        }

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCellIdentifier, for: indexPath) as? PhotoCollectionViewCell else {
            return UICollectionViewCell()
        }

        let asset = fetchResult[fetchResult.count - indexPath.item - 1]

        if #available(iOS 9.1, *) {
            if asset.mediaSubtypes.contains(.photoLive) {
                cell.signBadgeImage = PHLivePhotoView.livePhotoBadgeImage(options: .overContent)
            }
        }

        cell.asset = asset

        if self.selectedAssetsArray.count > 0, let representedAssetIdentifier = cell.asset?.localIdentifier {
            cell.badgeNumber = self.selectedAssetsArray.filter({ (asset) -> Bool in
                return representedAssetIdentifier == asset.localIdentifier
            }).count
        }

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true

        imageManager.requestImage(for: asset, targetSize:  thumbnailSize ?? .zero, contentMode: .aspectFill, options: options) { (image, _) in
            if cell.asset?.localIdentifier == asset.localIdentifier {
                cell.thumbnailImage = image
            }
        }

        if scrollIdxHistory <= indexPath.item {
            animateCell(cell, deadline: DispatchTime.now() + .milliseconds((indexPath.item - scrollIdxHistory) * 100))
            scrollIdxHistory = indexPath.item
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if self.isColleageMode {
            guard let fetchResult = self.fetchResult, indexPath.item < fetchResult.count else { return false}
            guard self.selectedAssetsArray.count < maxSeletedNumber else {

                return false
            }

            let asset = fetchResult[fetchResult.count - indexPath.item - 1]
            self.selectedAssetsArray.append(asset)
            self.updateVisibleCellsStatus()
            NotificationCenter.default.post(name: Notification.Name(rawValue: "DNImageSelectionChangeNotification"), object: self, userInfo: ["items": self.selectedAssetsArray])
            return false
        }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let fetchResult = self.fetchResult, indexPath.item < fetchResult.count else { return }

        let asset = fetchResult[fetchResult.count - indexPath.item - 1]

        self.loadPhoto(asset: asset)
    }

    func updateVisibleCellsStatus() {
        guard let visibleCells = self.collectionView?.visibleCells as? [PhotoCollectionViewCell] else { return }
        let selectedAssetIdentifier = self.selectedAssetsArray.map { (assert) -> String in
            return assert.localIdentifier
        }

        for cell in visibleCells {
            guard let representedAssetIdentifier = cell.asset?.localIdentifier else {
                cell.badgeNumber = 0
                continue
            }
            if selectedAssetIdentifier.count(ofElement: representedAssetIdentifier) > 0 {
                cell.badgeNumber = selectedAssetIdentifier.count(ofElement: representedAssetIdentifier)
            } else {
                cell.badgeNumber = 0
            }

        }
    }

    func reloadPhotoData() {
        scrollIdxHistory = 0
        self.collectionView!.reloadData()
        scrollIdxHistory = self.collectionView?.visibleCells.count ?? 0
        self.scrollToTop()
    }

    // Mark: Methods
    func loadPhoto(asset: PHAsset) {
        imageRequestId = PhotoProvider.requestImageData(for: asset, options: nil) { (imageData, dataUTI, orientation, info) in
            guard let imageData = imageData else {
                self.selectImageComplete(nil)
                return
            }
            let image = UIImage(data: imageData)

            self.selectImageComplete(image)
        }
    }

    // MARK: selectImageComplete
    func selectImageComplete(_ image: UIImage?) {

        DispatchQueue.main.async(execute: {
            guard let image = image else {
                
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
        guard let collectionView = self.collectionView, let fetchResult = self.fetchResult else { return }

        // The preheat window is twice the height of the visible rect.
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)

        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }

        // Compute the assets to start caching and to stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in
                collectionView.indexPathsForElements(in: rect)
            }
            .map { indexPath in
                fetchResult.object(at: fetchResult.count - 1 - indexPath.item)
        }
        let removedAssets = removedRects
            .flatMap { rect in
                collectionView.indexPathsForElements(in: rect)
            }
            .map { indexPath in
                fetchResult.object(at: fetchResult.count - 1 - indexPath.item)
        }

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
        guard let collectionView = self.collectionView else {
            return
        }
        DispatchQueue.main.async {
            guard var fetchResult = self.fetchResult, changeInstance.changeDetails(for: fetchResult) != nil else {
                return
            }

            guard let collectionChanges = changeInstance.changeDetails(for: fetchResult) else {
                self.resetCachedAssets()
                return
            }

            fetchResult = collectionChanges.fetchResultAfterChanges
            self.fetchResult = fetchResult
            if !collectionChanges.hasIncrementalChanges || collectionChanges.hasMoves {
                self.reloadPhotoData()
            }else {
                var removedPaths: [IndexPath]?
                var insertedPaths: [IndexPath]?
                var changedPaths: [IndexPath]?
                let beforeFetchResult = collectionChanges.fetchResultBeforeChanges

                if let removed = collectionChanges.removedIndexes {
                    removedPaths = self.indexPaths(from: removed, count: beforeFetchResult.count)
                }
                if let inserted = collectionChanges.insertedIndexes {
                    insertedPaths = self.indexPaths(from:inserted, count: fetchResult.count)
                }
                if let changed = collectionChanges.changedIndexes {
                    changedPaths = self.indexPaths(from: changed, count: fetchResult.count)
                }
                var shouldReload = false
                if let removedPaths = removedPaths, let changedPaths = changedPaths {
                    for changedPath in changedPaths {
                        if removedPaths.contains(changedPath) {
                            shouldReload = true
                            break
                        }
                    }
                }

                if let item = removedPaths?.first?.item {
                    if item > fetchResult.count {
                        shouldReload = true
                    }
                }

                if shouldReload {
                    self.reloadPhotoData()
                } else {
                    collectionView.performBatchUpdates({
                        if let theRemovedPaths = removedPaths {
                            collectionView.deleteItems(at: theRemovedPaths)
                        }
                        if let theInsertedPaths = insertedPaths {
                            collectionView.insertItems(at: theInsertedPaths)
                        }
                        if let theChangedPaths = changedPaths {
                            collectionView.reloadItems(at: theChangedPaths)
                        }

                        collectionChanges.enumerateMoves { fromIndex, toIndex in
                            collectionView.moveItem(at: IndexPath(item: toIndex, section: 0),
                                                    to: IndexPath(item: fromIndex, section: 0))
                        }
                    })
                }
            }
            self.resetCachedAssets()
        }
    }

    func indexPaths(from indexSet: IndexSet?, count: Int) -> [IndexPath]? {
        guard let set = indexSet else {
            return nil
        }

        return set.map { (index) -> IndexPath in
            let resultIndex = count - 1 - index
            if resultIndex >= 0 && resultIndex < count {
                return IndexPath(item: resultIndex, section: 0)
            }
            return IndexPath(item: 0, section: 0)
        }
    }
}

extension PhotoGridViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view?.isKind(of: UIButton.classForCoder()) ?? false {
            return false
        }
        return true
    }
}


