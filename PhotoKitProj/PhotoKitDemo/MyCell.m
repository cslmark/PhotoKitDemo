//
//  MyCell.m
//  CollectionViewTest_0720
//
//  Created by smart on 15/7/20.
//  Copyright (c) 2015年 smart. All rights reserved.
//

#import "MyCell.h"
#import "CSLMediaManager.h"
#import "QHPDownLoadCircleProgress.h"

@implementation CellData
-(instancetype) initWithPHAsset:(PHAsset *) asset{
    self = [super init];
    if(self) {
        self.asset = asset;
        self.cellType = PHAssetCellTypeUnKnown;
        self.avAsset = nil;
        self.progress = 0;
        self.downLoading = NO;
        self.localIdentifier = asset.localIdentifier;
        self.requestID = -1;
        self.thumbnail = nil;
        self.coverImage = nil;
    }
    return self;
}
@end

@interface MyCell()
@property (weak, nonatomic) IBOutlet UIView *maskView;
@property (weak, nonatomic) IBOutlet UIProgressView *downLoadProgerss;
@property (weak, nonatomic) IBOutlet QHPDownLoadCircleProgress *downCircleProgress;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *labelView;
@property (weak, nonatomic) IBOutlet UIButton *icloudBtn;
- (IBAction)icloudBtnClick:(UIButton *)sender;
@end


@implementation MyCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self)
    {
        // 初始化时加载collectionCell.xib文件
        NSArray *arrayOfViews = [[NSBundle mainBundle] loadNibNamed:@"MyCell" owner:self options:nil];
        
        // 如果路径不存在，return nil
        if (arrayOfViews.count < 1)
        {
            return nil;
        }
        // 如果xib中view不属于UICollectionViewCell类，return nil
        if (![[arrayOfViews objectAtIndex:0] isKindOfClass:[UICollectionViewCell class]])
        {
            return nil;
        }
        // 加载nib
        self = [arrayOfViews objectAtIndex:0];
        self.maskView.hidden = YES;
    }
    return self;
}

-(void)setData:(CellData *)data{
    _data = data;
    self.maskView.hidden = !data.downLoading;
    // 判断照片
    [self dealWithIconPic];
    
    // 判断视频是否是icloud部分
    [self checkOutIcloudVideo];
    
    // 展示下载部分的逻辑
    [self showDownLoadView];
    
    PHAsset* asset = data.asset;
    self.fileName = [asset valueForKey:@"filename"];
}

-(void) dealWithIconPic{
    if(_data.coverImage) {
        self.imageView.image = _data.coverImage;
    } else {
        if(_data.thumbnail) {
            self.imageView.image = _data.thumbnail;
        } else {
            
        }
//        if(_requestID != -1) {
//            [[CSLMediaManager shareInstance] cancelImageRequest:_requestID];
//        }
//        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
//        options.resizeMode = PHImageRequestOptionsResizeModeExact;
//        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
//        options.networkAccessAllowed = YES;
//        [[CSLMediaManager shareInstance]requestImageForAsset:_data.asset targetSize:_itemSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
//
//        }];
    }
}

-(void) checkOutIcloudVideo{
    self.icloudBtn.hidden = !(_data.cellType == PHAssetCellTypeIcloud);
}

-(void) showDownLoadView{
    if(_data.downLoading) {
        self.maskView.hidden = NO;
        self.downLoadProgerss.progress = _data.progress;
//        self.downCircleProgress.progress = _data.progress;
        self.progressLabel.text = [NSString stringWithFormat:@"%0.f%%", _data.progress*100];
    } else {
        self.maskView.hidden = YES;
    }
}

-(void)setImage:(UIImage *)image{
    _image = image;
    self.imageView.image = image;
}

-(void) setFileName:(NSString *)fileName{
    _fileName = fileName;
    self.labelView.text = fileName;
}

-(void)setNeedDownLoad:(BOOL)needDownLoad{
    _needDownLoad = needDownLoad;
    self.icloudBtn.hidden = !needDownLoad;
}


- (IBAction)icloudBtnClick:(UIButton *)sender {
}

-(void) setIcloudProgree:(float) progress{
    self.maskView.hidden = NO;
    self.downLoadProgerss.progress = progress;
    self.downCircleProgress.progress = progress;
    self.progressLabel.text = [NSString stringWithFormat:@"%0.f%%", progress*100];
}

-(void) completeDownLoad{
    self.progressLabel.text = @"恭喜你，下载完成";
    self.needDownLoad = NO;
    [UIView animateWithDuration:5 animations:^{
        self.maskView.hidden = YES;
    }];
}
@end
