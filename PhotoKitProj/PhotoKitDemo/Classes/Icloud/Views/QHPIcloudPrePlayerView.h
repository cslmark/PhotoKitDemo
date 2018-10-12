//
//  QHPIcloudPrePlayerView.h
//  FireVideo
//
//  Created by Iansl on 2018/10/4.
//  Copyright © 2018 Tencent Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, QHPIcloudPrePlayerType) {
    IcloudDownLoad = 0,
    IcloudCannotPreview = 1,
};

@interface QHPIcloudPrePlayerView : UIView
- (void) icloudType:(QHPIcloudPrePlayerType) icloudType progress:(CGFloat) progress;
@end
