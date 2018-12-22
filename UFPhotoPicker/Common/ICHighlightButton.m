//
//  ICHighlightButton.m
//  iCameraApp
//
//  Created by pisces_seven on 2017/7/13.
//  Copyright © 2017年 iCam. All rights reserved.
//

#import "ICHighlightButton.h"

@interface ICHighlightButton ()

@property (nonatomic, strong) UIView *coverView;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, assign) ICHighlightStyle highlightStyle;
@property (nonatomic, assign) ICHighlightZoom zoomStyle;

@end

@implementation ICHighlightButton

- (instancetype)init{
    if (self = [super init]) {
        self.adjustsImageWhenHighlighted = NO;
    }
    return self;
}

- (instancetype)initWithTextColor:(UIColor *)textColor HighlightStyle:(ICHighlightStyle)highlightStyle zoomStyle:(ICHighlightZoom)zoomStyle{
    if (self = [super init]) {
        if (textColor) {
            self.textColor = textColor;
            [self setTitleColor:textColor forState:UIControlStateNormal];
            self.titleLabel.textColor = textColor;
        }
        self.titleLabel.adjustsFontSizeToFitWidth = YES;
        self.adjustsImageWhenHighlighted = highlightStyle == ICHighlightStyleAdjust;
        self.highlightStyle = highlightStyle;
        self.zoomStyle = zoomStyle;
    }
    return self;
}

+(instancetype)createCameraFunctionButtonWithBlock:(void (^)(id obj))block {
    ICHighlightButton *button = [[ICHighlightButton alloc] initWithTextColor:nil HighlightStyle:ICHighlightStyleTotalNormal zoomStyle:ICHighlightZoomOut];
    button.frame = CGRectMake(0, 0, 60, 60);
    if (block) {
        block(button);
    }
    return button;
}

- (void)setEnabled:(BOOL)enabled{
    if (self.isEnabled == enabled) {
        return;
    }
    [super setEnabled:enabled];

    self.alpha = enabled ? 1.0 : 0.2;
}

- (void)setHighlighted:(BOOL)highlighted{

    if (self.isHighlighted == highlighted) {
        return;
    }

    if (self.highlightStyle != ICHighlightStyleNone) {
        [super setHighlighted:highlighted];

        if (self.highlightStyle != ICHighlightStyleAdjust) {

            if (self.highlightStyle == ICHighlightStyleTotalCircle || self.highlightStyle == ICHighlightStyleImageCircle) {
                self.coverView.hidden = !highlighted;
            }else {
                self.imageView.alpha = highlighted ? 0.6 : 1.0;
            }

            if (self.textColor) {
                self.titleLabel.textColor = highlighted ? [self.textColor colorWithAlphaComponent:0.6] : self.textColor;
            }
        }

        if (self.zoomStyle != ICHighlightZoomNone) {
            [UIView animateWithDuration:0.2 animations:^{
                self.transform = highlighted ? CGAffineTransformMakeScale((self.zoomStyle == ICHighlightZoomOut ? 0.9 : 1.1), (self.zoomStyle == ICHighlightZoomOut ? 0.9 : 1.1)) : CGAffineTransformIdentity;
            }];
        }
    }
}

- (UIView *)coverView{
    if (!_coverView) {
        _coverView = [[UIView alloc]initWithFrame:self.bounds];
        _coverView.backgroundColor = [[UIColor whiteColor]colorWithAlphaComponent:0.3];
        if (self.highlightStyle == ICHighlightStyleImageCircle || self.highlightStyle == ICHighlightStyleImageNormal) {
            _coverView.frame = self.imageView.frame;
        }
        if (self.highlightStyle == ICHighlightStyleTotalCircle){
            _coverView.layer.cornerRadius = self.bounds.size.width / 2.0;
            _coverView.clipsToBounds = YES;
        }
        if(self.highlightStyle == ICHighlightStyleImageCircle){
            _coverView.layer.cornerRadius = self.imageView.bounds.size.width / 2.0;
            _coverView.clipsToBounds = YES;
        }
        [self addSubview:_coverView];
    }
    return _coverView;
}

@end
