//
//  QHPIcloudPrePlayerView.m
//  FireVideo
//
//  Created by Iansl on 2018/10/4.
//  Copyright © 2018 Tencent Inc. All rights reserved.
//

#import "QHPIcloudPrePlayerView.h"
#import "Masonry.h"

@interface QHPIcloudPrePlayerView()
@property (nonatomic, weak) UIImageView* icloudImageView;
@property (nonatomic, weak) UILabel* descLabel;
@end

@implementation QHPIcloudPrePlayerView
-(instancetype) initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

-(void) setupUI{
    self.backgroundColor = [UIColor clearColor];
    self.backgroundColor = [UIColor colorWithRed:11.0/255 green:11.0/255 blue:11.0/255 alpha:0.8];
    UIImageView *icloudImageView = [[UIImageView alloc] init];
    [self addSubview:icloudImageView];
    self.icloudImageView = icloudImageView;
    __weak UIView* superView = self;
    [icloudImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(superView);
        make.top.equalTo(superView).offset(81.0);
        make.width.mas_equalTo(@(74.0));
        make.height.mas_equalTo(@(74.0));
    }];
    
    UILabel* descLabel = [[UILabel alloc] init];
    descLabel.font = [UIFont systemFontOfSize:14.0];
    descLabel.textColor = [UIColor greenColor];
    [self addSubview:descLabel];
    self.descLabel = descLabel;
    [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(superView);
        make.top.equalTo(icloudImageView.mas_bottom).offset(6.0);
    }];
    
    [self setNeedsUpdateConstraints];
}


- (void)updateConstraints {
    [super updateConstraints];
}


-(void) icloudType:(QHPIcloudPrePlayerType) icloudType progress:(CGFloat) progress{
    if(icloudType == IcloudCannotPreview) {
        self.descLabel.text = @"无法预览iCloud视频";
        self.icloudImageView.image = [UIImage imageNamed:@"publishIcloud"];
    }
    if(icloudType == IcloudDownLoad) {
        self.descLabel.text = [NSString stringWithFormat:@"正在从iCloud下载视频(%0.f%%)", progress * 100];
        self.icloudImageView.image = [UIImage imageNamed:@"publishIcloudDownLoad"];
    }
}

@end
