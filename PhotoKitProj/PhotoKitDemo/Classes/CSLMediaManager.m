//
//  CSLMediaManager.m
//  iOSPhotoKit
//
//  Created by Iansl on 2018/10/1.
//  Copyright © 2018 Iansl. All rights reserved.
//

#import "CSLMediaManager.h"

@implementation QHOVideoSection
- (NSUInteger)count {
    return self.videoResults.count;
}
@end

@interface CSLMediaManager()<PHPhotoLibraryChangeObserver>
{
    
}
@property (nonatomic, copy, readwrite) NSArray<QHOVideoSection *> *sections;
@property (nonatomic, strong) NSHashTable *weakDelegates;
// 全局的缓存和请求对象
@property (nonatomic, strong) PHCachingImageManager* cacheManager;
@property (nonatomic, strong) PHFetchResult<PHAssetCollection *> *smartAlbums;
@end

@implementation CSLMediaManager
static dispatch_once_t onceToken;
static CSLMediaManager* instacne = nil;

#pragma mark ================   初始化&单例    ================
+(instancetype) shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instacne = [[self alloc] init];
    });
    return instacne;
}

+(void) deallocManager{
    onceToken = 0;
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:instacne];
    instacne = nil;
}

-(instancetype) init{
    self = [super init];
    if(self) {
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    }
    return self;
}

#pragma mark ================   代理部分管理    ================
- (NSHashTable *)weakDelegates {
    if (!_weakDelegates) {
        _weakDelegates = [NSHashTable weakObjectsHashTable];
    }
    return _weakDelegates;
}

- (void)registerDelegate:(id<QHOPhotoLibraryHandlerDelegate>)delegate {
    [self.weakDelegates addObject:delegate];
}

- (void)removeDelegate:(id<QHOPhotoLibraryHandlerDelegate>)delegate {
    [self.weakDelegates removeObject:delegate];
}

#pragma mark ================   授权部分    ================
- (void)requestAuthorization:(void (^)(PHAuthorizationStatus status))completion{
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if(completion) {
            completion(status);
        }
    }];
}

#pragma mark ================   Get Album    ================
-(void) setUpAlbums{
    PHFetchResult<PHAssetCollection *> *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumVideos options:nil];
    self.smartAlbums = smartAlbums;
    NSArray<PHFetchResult *> *albumsResults = @[smartAlbums /*, userAlbums*/];
    PHFetchOptions *options = [PHFetchOptions new];
    options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeVideo];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    
    NSMutableArray *sections = [NSMutableArray array];
    for (PHFetchResult<PHAssetCollection *> *fetchResult in albumsResults) {
        [fetchResult enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(PHAssetCollection * _Nonnull assetCollection, NSUInteger idx, BOOL * _Nonnull stop) {
            PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
            if ([fetchResult countOfAssetsWithMediaType:PHAssetMediaTypeVideo] > 0) {
                QHOVideoSection *section = [[QHOVideoSection alloc] init];
                section.localizedTitle = assetCollection.localizedTitle;
                section.videoResults = fetchResult;
                [sections addObject:section];
            }
        }];
    }
//    for (PHAssetCollection *collection in smartAlbums) {
//        // 有可能是PHCollectionList类的的对象，过滤掉
//        if (![collection isKindOfClass:[PHAssetCollection class]]) continue;
//        // 过滤空相册
//        if (collection.estimatedAssetCount <= 0) continue;
//        PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
//        [fetchResult enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(PHAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
//                QHOVideoSection *section = [[QHOVideoSection alloc] init];
//                section.localizedTitle = asset.localIdentifier;
//                section.localizedTitle = assetCollection.localizedTitle;
//                section.videoResults = fetchResult;
//                [sections addObject:section];
////            }
//        }];
//    }
    self.sections = sections;
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id<QHOPhotoLibraryHandlerDelegate> delegate in self.weakDelegates) {
            if ([delegate respondsToSelector:@selector(handlerDidUpdate:)]) {
                [delegate handlerDidUpdate:self];
            }
        }
    });
}

#pragma mark ================   请求和缓存部分处理    ================
-(PHCachingImageManager *) cacheManager{
    if(_cacheManager == nil){
        _cacheManager = [[PHCachingImageManager alloc] init];
    }
    return _cacheManager;
}

- (void)startCachingImagesForAssets:(NSArray<PHAsset *> *)assets targetSize:(CGSize)targetSize contentMode:(PHImageContentMode)contentMode options:(nullable PHImageRequestOptions *)options{
    [self.cacheManager startCachingImagesForAssets:assets targetSize:targetSize contentMode:contentMode options:options];
}

- (PHImageRequestID)requestImageForAsset:(PHAsset *)asset targetSize:(CGSize)targetSize contentMode:(PHImageContentMode)contentMode options:(nullable PHImageRequestOptions *)options resultHandler:(void (^)(UIImage *__nullable result, NSDictionary *__nullable info))resultHandler{
    return [self.cacheManager requestImageForAsset:asset targetSize:targetSize contentMode:contentMode options:options resultHandler:resultHandler];
}

- (void)cancelImageRequest:(PHImageRequestID)requestID{
    [self.cacheManager cancelImageRequest:requestID];
}

- (PHImageRequestID)requestAVAssetForVideo:(PHAsset *)asset options:(nullable PHVideoRequestOptions *)options resultHandler:(void (^)(AVAsset *__nullable asset, AVAudioMix *__nullable audioMix, NSDictionary *__nullable info))resultHandler{
    return [self.cacheManager requestAVAssetForVideo:asset options:options resultHandler:resultHandler];
}

#pragma mark ================   改变的时候    ================
- (void)photoLibraryDidChange:(PHChange *)changeInstance{
    NSLog(@"当前的线程=======  %@", [NSThread currentThread]);
    NSLog(@"相册已经获取的内容发生了改变=======");
    PHFetchResultChangeDetails *albumChanges = [changeInstance changeDetailsForFetchResult:self.smartAlbums];
    if(albumChanges.hasIncrementalChanges){
        self.smartAlbums = albumChanges.fetchResultAfterChanges;
        NSIndexSet *removed = albumChanges.removedIndexes;
        if(removed.count) {
            [removed enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                NSLog(@"idx = %@  被删除了", @(idx));
            }];
        }
        NSIndexSet *inserted = albumChanges.insertedIndexes;
        if(inserted.count) {
            [inserted enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                NSLog(@"idx = %@  被添加到", @(idx));
            }];
        }
        NSIndexSet *changed = albumChanges.changedIndexes;
        if (changed.count) {
            [changed enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                NSLog(@"idx = %@  被改变了", @(idx));
            }];
        }
        if(albumChanges.hasMoves) {
            [albumChanges enumerateMovesWithBlock:^(NSUInteger fromIndex, NSUInteger toIndex) {
                NSLog(@"%@  ========》  %@", @(fromIndex), @(toIndex));
            }];
        }
    }
    else {
        NSLog(@"没有增加的改变=============");
    }
    
    for(NSInteger i = 0; i < self.sections.count; i++) {
        QHOVideoSection *section = self.sections[i];
        PHFetchResult<PHAsset *> *videoResults = section.videoResults;
        PHFetchResultChangeDetails *tempChanges = [changeInstance changeDetailsForFetchResult:videoResults];
        if(tempChanges.hasIncrementalChanges) {
            NSLog(@"没有增加的改变============= %@", videoResults);
        } else {
            NSLog(@"没有增加的改变============= %@", videoResults);
        }
    }
    
    
}
@end
