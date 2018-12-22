//
//  UIApplication-Permissions.h
//  UIApplication-Permissions Sample
//
//  Created by Jack Rostron on 12/01/2014.
//  Copyright (c) 2014 Rostron. All rights reserved.
//  https://github.com/JackRostron/UIApplication-Permissions
//   Category on UIApplication that adds permission helpers


#import <UIKit/UIKit.h>

typedef enum {
    kPermissionAccessDenied, //User has rejected feature
    kPermissionAccessGranted, //User has accepted feature
    kPermissionAccessRestricted, //Blocked by parental controls or system settings
    kPermissionAccessUnknown, //Cannot be determined
    kPermissionAccessUnsupported, //Device doesn't support this - e.g Core Bluetooth
    kPermissionAccessMissingFramework, //Developer didn't import the required framework to the project
} kPermissionAccess;

@interface UIApplication (Permissions)

-(kPermissionAccess)hasAccessToPhotos;
-(kPermissionAccess)hasAccessToCamera;

-(void)requestAccessToPhotosWithSuccess:(void(^)())accessGranted andFailure:(nullable void(^)())accessDenied;
-(void)requestAccessToCameraWithSuccess:(void(^)())accessGranted andFailure:(nullable void(^)())accessDenied;

@end
