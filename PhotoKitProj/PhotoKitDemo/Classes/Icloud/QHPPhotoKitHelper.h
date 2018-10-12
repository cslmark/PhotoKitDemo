//
//  QHPPhotoKitHelper.h
//  FireVideo
//
//  Created by Iansl on 2018/10/10.
//  Copyright © 2018 Tencent Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "QHPIcloudOperation.h"

@class QHPPhotoKitHelper;

@protocol QHPPhotoKitIcloudQueryDelegate
@optional
-(void) qhpPhotoKitHelper:(QHPPhotoKitHelper *) helper querySet:(NSArray <NSString *>*) queryList icloudSet:(NSArray <NSString *>*) icloudList;
@end

@protocol QHPPhotoKitChangeDelegate
@optional
-(void) qhpPhotoKitHelper:(QHPPhotoKitHelper *) helper phChangeDetail:(PHFetchResultChangeDetails *)changes;
@end

@protocol QHPPhotoKitHelperDelegate
@optional
-(void) qhpPhotoKitHelper:(QHPPhotoKitHelper *) helper progressWithIdentifier:(NSString*) identifier progress:(double) progress info:(NSDictionary *) info;
-(void) qhpPhotoKitHelper:(QHPPhotoKitHelper *) helper failWithIdentifier:(NSString*) identifier error:(NSError *) error info:(NSDictionary *) info;
-(void) qhpPhotoKitHelper:(QHPPhotoKitHelper *) helper cancelWithIdentifier:(NSString*) identifier error:(NSError *) error;
-(void) qhpPhotoKitHelper:(QHPPhotoKitHelper *) helper completeWithIdentifier:(NSString*) identifier aVAsset:(AVAsset *) aVAsset avAudioMix:(AVAudioMix *) audioMix info:(NSDictionary *) info;
@end

@interface QHPPhotoKitHelper : NSObject
@property (nonatomic, weak) id<QHPPhotoKitHelperDelegate> delegate;
@property (nonatomic, weak) id<QHPPhotoKitChangeDelegate> changeDelegate;
@property (nonatomic, weak) id<QHPPhotoKitIcloudQueryDelegate> icloudQueryDelegate;
@property (nonatomic, strong, readonly) PHFetchResult<PHAsset *> *videoFetchResult;

+(instancetype) shareInstance;
+(void) deallocManager;
+ (void)requestAuthorization:(void (^)(PHAuthorizationStatus))completion;

// 获取视频数据
-(void) reloadData;

// 请求和取消video
- (void) requestAVAssetWithLocalIdentifier:(NSString *)localIdentifier progressHandler:(PHAssetVideoProgressHandler)handler completion:(void (^)(AVAsset *))completion;
-(void) requestAVAssetForVideoWith:(NSString *) identifier;
-(void) cancelAVAssetForVideoWith:(NSString *) identifier;

// 请求图片
- (void)requestImageWithPHAsset:(PHAsset *)asset targetSize:(CGSize)targetSize resultHandler:(void (^)(UIImage *, NSDictionary *))handler;

// 验证是否是icloud视频
- (AVAsset *)requestAVAssetWithLocalIdentifier:(NSString *)localIdentifier;
-(void)queryIcloudAssetItemWithIdentifiers:(NSArray <NSString *>*)identifiers;
-(void)queryIcloudAssetAllItem;

// 相片缓存
-(void) startCachingImagesForAssets:(NSArray<PHAsset *> *)assets  targetSize:(CGSize)targetSize;
-(void) stopCachingImagesForAssets:(NSArray<PHAsset *> *)assets  targetSize:(CGSize)targetSize;
-(void) stopCachingImagesForAllAssets;

// 本地下载的时候更新icloud标志缓存
-(void) updateCloudCacheWithIdentifier:(NSString *) identifier isCloud:(BOOL) isIcloud;

// 停止所有下载任务
-(void) cancelAllTask;
@end
