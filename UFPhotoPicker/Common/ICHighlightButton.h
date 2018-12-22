//
//  ICHighlightButton.h
//  iCameraApp
//
//  Created by pisces_seven on 2017/7/13.
//  Copyright © 2017年 iCam. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, ICHighlightStyle) {
    ICHighlightStyleNone,//无press状态
    ICHighlightStyleAdjust,//系统自带press状态
    ICHighlightStyleImageCircle,//图片圆形press
    ICHighlightStyleTotalCircle,//整体圆形press
    ICHighlightStyleImageNormal,//图片正常形状press
    ICHighlightStyleTotalNormal,//整体正常形状press
};

typedef NS_ENUM(NSUInteger, ICHighlightZoom) {
    ICHighlightZoomNone,//无缩放
    ICHighlightZoomOut,//按下缩小
    ICHighlightZoomIn,//按下放大
};

@interface ICHighlightButton : UIButton

- (instancetype)initWithTextColor:(UIColor *)textColor HighlightStyle:(ICHighlightStyle)highlightStyle zoomStyle:(ICHighlightZoom)zoomStyle;

+ (instancetype)createCameraFunctionButtonWithBlock:(void (^)(id obj))block ;

@end
