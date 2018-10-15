//
//  QHPIcoudProgress.m
//  PhotoKitDemo
//
//  Created by IanChen on 2018/10/14.
//  Copyright © 2018年 Iansl. All rights reserved.
//

#import "QHPIcoudProgress.h"

@interface QHPIcoudProgressLayer : CALayer
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) CGFloat lineWidth;
@end

#define kDeaultLineWidth (3.0)

@implementation QHPIcoudProgressLayer

+ (BOOL)needsDisplayForKey:(NSString *)key {
    if ([key isEqualToString:@"progress"]) {
        return YES;
    }
    return [super needsDisplayForKey:key];
}

- (instancetype)initWithLayer:(QHPIcoudProgressLayer *)layer {
    if (self = [super initWithLayer:layer]) {
        self.progress = layer.progress;
    }
    return self;
}

- (void)drawInContext:(CGContextRef)ctx {
    self.lineWidth = self.lineWidth ?: kDeaultLineWidth;
    CGFloat radius = MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)) / 2;
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(radius, radius)
                                                        radius:radius - self.lineWidth / 2
                                                    startAngle:- M_PI / 2
                                                      endAngle:M_PI * 2 * self.progress - M_PI / 2
                                                     clockwise:YES];
    CGContextSetRGBStrokeColor(ctx, 223, 255, 0, 1.0);
    CGContextSetLineWidth(ctx, self.lineWidth);
    CGContextAddPath(ctx, path.CGPath);
    CGContextStrokePath(ctx);
}
@end

@interface QHPIcoudProgress()<CAAnimationDelegate>
@property (nonatomic, strong) QHPIcoudProgressLayer* progressLayer;
@property (nonatomic, assign) BOOL isAnimating;
@end

@implementation QHPIcoudProgress
- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _progressLayer = [QHPIcoudProgressLayer layer];
        _progressLayer.contentsScale = [UIScreen mainScreen].scale;
        _progressLayer.lineWidth = kDeaultLineWidth;
        _progressLayer.frame = self.bounds;
        [self.layer addSublayer:_progressLayer];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.progressLayer.frame = self.bounds;
}

- (void)resetProgress {
    _progress = 0;
    self.progressLayer.progress = 0;
    [self.progressLayer removeAllAnimations];
    [self.progressLayer setNeedsDisplay];
}

- (void)finishAnimation {
    if (!self.isAnimating) {
        [self notifyAnimationDidFinish];
    } else {
        [self setProgress:1.0];
    }
}

- (void)notifyAnimationDidFinish {
    if ([self.delegate respondsToSelector:@selector(progressViewDidFinishAnimation:)]) {
        [self.delegate progressViewDidFinishAnimation:self];
    }
    self.hidden = self.hideOnCompletion;
}

#pragma mark - accessor methods
- (void)setProgress:(CGFloat)progress {
    if (_progress == progress) {
        return;
    }
    if (_progress > progress) {
        [self resetProgress];
    }
    
    self.isAnimating = YES;
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"progress"];
    animation.duration = 1.2 * fabs(progress - _progress);
    animation.toValue = @(progress);
    animation.removedOnCompletion = YES;
    animation.fillMode = kCAFillModeForwards;
    animation.delegate = self;
    [self.progressLayer addAnimation:animation forKey:@"animation"];
    _progress = progress;
    self.hidden = NO;
}

- (void)setLineWidth:(CGFloat)lineWidth {
    _lineWidth = lineWidth;
    self.progressLayer.lineWidth = lineWidth;
}

#pragma mark - CAAnimationDelegate
- (void)animationDidStop:(CABasicAnimation *)anim finished:(BOOL)flag {
    self.isAnimating = NO;
    CGFloat progress = self.progress;
    if ([anim isKindOfClass:[CABasicAnimation class]]) {
        progress = [anim.toValue floatValue];
    }
    self.progressLayer.progress = progress;
    if (1.0 <= progress) {
        [self notifyAnimationDidFinish];
    }
}


@end
