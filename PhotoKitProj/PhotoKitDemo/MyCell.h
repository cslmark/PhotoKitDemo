//
//  MyCell.h
//  CollectionViewTest_0720
//
//  Created by smart on 15/7/20.
//  Copyright (c) 2015年 smart. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

typedef NS_ENUM(NSUInteger, PHAssetCellType) {
    PHAssetCellTypeUnKnown = 0,
    PHAssetCellTypeIcloud = 1,
    PHAssetCellTypeLocal = 2,
};

@interface CellData: NSObject
@property (nonatomic, strong) PHAsset* asset;
@property (nonatomic, strong) AVAsset* avAsset;
@property (nonatomic, assign) PHAssetCellType cellType;
@property (nonatomic, assign) float progress;
@property (nonatomic, assign) BOOL  downLoading;
@property (nonatomic, copy)   NSString* localIdentifier;   // 作为标识具体的asset
@property (nonatomic, assign) PHImageRequestID requestID;
@property (nonatomic, strong) UIImage* thumbnail;
@property (nonatomic, strong) UIImage* coverImage;

-(instancetype) initWithPHAsset:(PHAsset *) asset;
@end

@protocol MyCellDelegate
-(void) icloudDownLoadBtnClick;
@end

@interface MyCell : UICollectionViewCell
@property (nonatomic, strong) CellData* data;
@property (nonatomic, copy) UIImage *image;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, assign) BOOL   needDownLoad;
@property (nonatomic, strong) PHAsset* asset;
@property (nonatomic, assign) BOOL   downLoading;
@property (nonatomic, assign) PHImageRequestID requestID;
@property (nonatomic, assign) CGSize itemSize;

-(void) setIcloudProgree:(float) progress;
-(void) completeDownLoad;
@end
