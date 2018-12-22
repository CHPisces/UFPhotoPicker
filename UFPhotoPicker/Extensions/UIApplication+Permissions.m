//
//  UIApplication-Permissions.m
//  UIApplication-Permissions Sample
//
//  Created by Jack Rostron on 12/01/2014.
//  Copyright (c) 2014 Rostron. All rights reserved.
//

#import "UIApplication+Permissions.h"
#import <Photos/Photos.h>
#import <objc/runtime.h>
#import <UFPhotoPicker-Swift.h>

@implementation UIApplication (Permissions)

-(kPermissionAccess)hasAccessToCamera
{
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusAuthorized:
            return kPermissionAccessGranted;
            break;
        case AVAuthorizationStatusDenied:
            return kPermissionAccessDenied;
            break;
            case AVAuthorizationStatusRestricted:
            return kPermissionAccessRestricted;
            break;

        default:
            return kPermissionAccessUnknown;
            break;
    }
}

-(kPermissionAccess)hasAccessToPhotos {
    switch ([PHPhotoLibrary authorizationStatus]) {
        case PHAuthorizationStatusAuthorized:
            return kPermissionAccessGranted;
            break;
            
        case PHAuthorizationStatusDenied:
            return kPermissionAccessDenied;
            break;
            
        case PHAuthorizationStatusRestricted:
            return kPermissionAccessRestricted;
            break;
            
        default:
            return kPermissionAccessUnknown;
            break;
    }
}

//获取当前屏幕显示的viewcontroller
+ (UIViewController *)getCurrentVC {

    UIViewController *result = nil;

    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;

    do {
        if ([rootVC isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navi = (UINavigationController *)rootVC;
            UIViewController *vc = [navi.viewControllers lastObject];
            result = vc;
            rootVC = vc.presentedViewController;
            continue;
        } else if([rootVC isKindOfClass:[UITabBarController class]]) {
            UITabBarController *tab = (UITabBarController *)rootVC;
            result = tab;
            rootVC = [tab.viewControllers objectAtIndex:tab.selectedIndex];
            continue;
        } else if([rootVC isKindOfClass:[UIViewController class]]) {
            result = rootVC;
            rootVC = nil;
        }
    } while (rootVC != nil);

    return result;
}

-(void)requestAccessToPhotosWithSuccess:(void(^)())accessGranted andFailure:(void(^)())accessDenied {
    [PhotoProvider challengePhotoAuthorizationWithSucceedHanlde:^{
        accessGranted();
    } failureHandle:^{
        if(accessDenied){
            accessDenied();
            return ;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Tips" message:@"未开启相册权限" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *sure = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
            }];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {

            }];
            [alert addAction:cancel];
            [alert addAction:sure];
        });
    }];
}

-(void)requestAccessToCameraWithSuccess:(void(^)())accessGranted andFailure:(void(^)())accessDenied {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if(granted){
            accessGranted();
        } else if(accessDenied){
            accessDenied();
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Tips" message:@"未开启相册权限" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *sure = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                }];
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    
                }];
                [alert addAction:cancel];
                [alert addAction:sure];
            });
        }
    }];
}

@end
