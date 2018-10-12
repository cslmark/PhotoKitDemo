//
//  CSLMediaManager.h
//  iOSPhotoKit
//
//  Created by Iansl on 2018/10/1.
//  Copyright © 2018 Iansl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@class CSLMediaManager;

@interface QHOVideoSection : NSObject
@property (nonatomic, strong) NSString *localizedTitle;
@property (nonatomic, strong) PHFetchResult<PHAsset *> *videoResults;
@property (nonatomic, readonly) NSUInteger count;
@end

@protocol QHOPhotoLibraryHandlerDelegate <NSObject>
@optional
- (void)handlerDidUpdate:(CSLMediaManager *)handler;
- (void)handlerDidUpdateIcloudItems:(NSSet *)icloudIdentifiers;
@end

@interface CSLMediaManager : NSObject
@property (nonatomic, copy, readonly) NSArray<QHOVideoSection *> *sections;

// 代理部分
- (void)registerDelegate:(id<QHOPhotoLibraryHandlerDelegate>)delegate;
- (void)removeDelegate:(id<QHOPhotoLibraryHandlerDelegate>)delegate;
+(instancetype) shareInstance;
+(void) deallocManager;

- (void)requestAuthorization:(void (^)(PHAuthorizationStatus status))completion;
- (void) setUpAlbums;

// 请求和缓存部分处理
- (void)startCachingImagesForAssets:(NSArray<PHAsset *> *)assets targetSize:(CGSize)targetSize contentMode:(PHImageContentMode)contentMode options:(nullable PHImageRequestOptions *)options;
- (PHImageRequestID)requestImageForAsset:(PHAsset *)asset targetSize:(CGSize)targetSize contentMode:(PHImageContentMode)contentMode options:(nullable PHImageRequestOptions *)options resultHandler:(void (^)(UIImage *__nullable result, NSDictionary *__nullable info))resultHandler;
- (void)cancelImageRequest:(PHImageRequestID)requestID;
- (PHImageRequestID)requestAVAssetForVideo:(PHAsset *)asset options:(nullable PHVideoRequestOptions *)options resultHandler:(void (^)(AVAsset *__nullable asset, AVAudioMix *__nullable audioMix, NSDictionary *__nullable info))resultHandler;
@end
