//
//  PHPhotoLibraryExtension.swift
//  UFPhotoPicker
//
//  Created by 曹华 on 2018/11/28.
//  Copyright © 2018年 曹华. All rights reserved.
//

import Photos

extension PHPhotoLibrary {
    
    class func checkAuthorizationStatus(completionHandler: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status -> Void in
                
                DispatchQueue.main.async {
                    if status != .authorized {
                        completionHandler(false)
                    }
                }
            }
            break
        case .denied:
            completionHandler(false)
        default:
            completionHandler(true)
            break
        }
    }
    
    class func guideToSetting() {
        DispatchQueue.main.async {
            UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
        }
    }
}
