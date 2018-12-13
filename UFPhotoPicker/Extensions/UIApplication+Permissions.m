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

-(void)requestAccessToPhotosWithSuccess:(void(^)(void))accessGranted andFailure:(void(^)(void))accessDenied {
    [PhotoProvider challengePhotoAuthorizationWithSucceedHanlde:^{
        accessGranted();
    } failureHandle:^{
        if(accessDenied){
            accessDenied();
            return ;
        }
    }];
}

-(void)requestAccessToCameraWithSuccess:(void(^)(void))accessGranted andFailure:(void(^)(void))accessDenied {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if(granted){
            accessGranted();
        } else if(accessDenied){
            accessDenied();
        } else {
        }
    }];
}

@end
