//
//  QHPIcoudProgress.h
//  PhotoKitDemo
//
//  Created by IanChen on 2018/10/14.
//  Copyright © 2018年 Iansl. All rights reserved.
//

#import <UIKit/UIKit.h>
@class  QHPIcoudProgress;
@protocol QHPIcoudProgressViewDelegate <NSObject>
@optional
- (void)progressViewDidFinishAnimation:(QHPIcoudProgress *)progressView;
@end


@interface QHPIcoudProgress : UIView
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, assign) BOOL hideOnCompletion;

@property (nonatomic, weak) id <QHPIcoudProgressViewDelegate> delegate;

- (void)resetProgress;
- (void)finishAnimation;
@end
