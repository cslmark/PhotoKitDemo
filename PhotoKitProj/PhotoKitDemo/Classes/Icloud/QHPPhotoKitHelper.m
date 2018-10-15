//
//  QHPPhotoKitHelper.m
//  FireVideo
//
//  Created by Iansl on 2018/10/10.
//  Copyright © 2018 Tencent Inc. All rights reserved.
//

#import "QHPPhotoKitHelper.h"
#import "GlobalDefines.h"

typedef NS_ENUM(NSUInteger, PhotoKitChangsType) {
    PhotoKitTypeInsert = 0,
    PhotoKitTypeRemove = 1,
    PhotoKitTypeChange = 2,
};

#define QueryIcloudCache  0
#define KVOOperationTest  0

@interface QHPPhotoKitHelper()<PHPhotoLibraryChangeObserver>
@property (nonatomic, strong) NSOperationQueue* queue;
@property (nonatomic, strong) NSMutableDictionary* taskCache;
@property (nonatomic, strong) PHImageManager* mediaManager;
@property (nonatomic, strong) PHCachingImageManager* cacheImageManager;
@property (nonatomic, strong) PHFetchResult<PHAssetCollection *> *smartAlbums;
@property (nonatomic, strong, readwrite) PHFetchResult<PHAsset *> *videoFetchResult;
//@property (nonatomic, strong) NSMutableDictionary* aVAssetCache;
@property (nonatomic, strong) NSMutableDictionary<NSString *, UIImage *> *imageCache;
@property (nonatomic, strong) NSMutableArray<PHAsset *>* waitTaskCache;
@property (nonatomic,strong) NSMutableSet *icloudIdentifiers;
@property (nonatomic,strong) NSMutableSet *icloudQueryedIdentifiers;
@property (nonatomic,strong) NSMutableArray<NSString *>* queryIcloudList;
@property (nonatomic, strong) dispatch_queue_t cacheQueue;
@property (nonatomic, strong) dispatch_queue_t iCloudQueryQueue;
@end

const static NSInteger kMaxConcurrent = 3;

@implementation QHPPhotoKitHelper
static dispatch_once_t onceToken;
static QHPPhotoKitHelper* instance = nil;

#pragma mark ================   初始化&单例&LifeCycle    ================
+(instancetype) shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

-(instancetype) init{
    if(self = [super init]) {
        _queue = [[NSOperationQueue alloc] init];
        _queue.maxConcurrentOperationCount = kMaxConcurrent;
        _taskCache = [[NSMutableDictionary alloc] init];
        _mediaManager = [PHImageManager defaultManager];
//        _aVAssetCache = [[NSMutableDictionary alloc] init];
        _cacheQueue = dispatch_queue_create("com.photokit.cachequeue", DISPATCH_QUEUE_SERIAL);
        _iCloudQueryQueue = dispatch_queue_create("com.photokit.icloudQueryqueue", DISPATCH_QUEUE_SERIAL);
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForeGround:) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

-(void) reloadData{
    [self setUpAlbums];
}

-(void) setUpAlbums{
    PHFetchResult<PHAssetCollection *> *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumVideos options:nil];
    self.smartAlbums = smartAlbums;
    PHCollection* collection = [smartAlbums firstObject];
    PHAssetCollection*  assetCollection = (PHAssetCollection*)collection;
    PHFetchOptions *options = [PHFetchOptions new];
    options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeVideo];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
    self.videoFetchResult = fetchResult;
    [self.queryIcloudList removeAllObjects];
    for(NSInteger i = 0; i < fetchResult.count; i++) {
        PHAsset* asset = fetchResult[i];
        [self.queryIcloudList addObject:asset.localIdentifier];
    }
}

-(void)dealloc{
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    self.taskCache = nil;
//    self.aVAssetCache = nil;
    self.mediaManager = nil;
    self.videoFetchResult = nil;
    self.smartAlbums = nil;
    self.cacheQueue = nil;
    self.imageCache = nil;
    self.queue = nil;
}

+(void) deallocManager{
    onceToken = 0;
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:instance];
    [[NSNotificationCenter defaultCenter] removeObserver:instance name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    for(QHPIcloudOperation *operation in instance.taskCache) {
        [operation cancelTask];
    }
    instance.taskCache = nil;
//    instance.aVAssetCache = nil;
    instance.mediaManager = nil;
    instance.videoFetchResult = nil;
    instance.smartAlbums = nil;
    instance.cacheQueue = nil;
    instance.queue = nil;
    instance.imageCache = nil;
    instance = nil;
}

#pragma mark - lazy
- (NSMutableDictionary<NSString *, UIImage *> *)imageCache {
    if (!_imageCache) {
        _imageCache = [[NSMutableDictionary alloc] init];
        
    }
    return _imageCache;
}

-(PHCachingImageManager *) cacheImageManager{
    if(_cacheImageManager == nil){
        _cacheImageManager = [[PHCachingImageManager alloc] init];
    }
    return _cacheImageManager;
}

-(NSMutableArray<NSString *> *)queryIcloudList{
    if(_queryIcloudList == nil) {
        _queryIcloudList = [NSMutableArray arrayWithCapacity:1];
    }
    return _queryIcloudList;
}

-(NSMutableArray<PHAsset *> *)waitTaskCache{
    if(_waitTaskCache == nil){
        _waitTaskCache = [NSMutableArray arrayWithCapacity:1];
    }
    return _waitTaskCache;
}

#pragma mark - 通知部分处理
- (void)receiveMemoryWarning:(id)sender {
    [self.imageCache removeAllObjects];
}

- (void) appEnterForeGround: (id) sender {
    // 刷新一遍icloud
    if([(NSObject *)self.icloudQueryDelegate respondsToSelector:@selector(qhpPhotoKitHelper:querySet:icloudSet:)]) {
          [self queryIcloudAssetAllItem];
    }
}

#pragma mark ================   pubic Access Methods    ================
#pragma mark - request
+ (void)requestAuthorization:(void (^)(PHAuthorizationStatus))completion {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) { completion(status); }
        });
    }];
}

- (void) requestAVAssetWithLocalIdentifier:(NSString *)localIdentifier progressHandler:(PHAssetVideoProgressHandler)handler completion:(void (^)(AVAsset *))completion {
    if (!localIdentifier.length || !completion) {
        return;
    }
    PHFetchResult<PHAsset *> *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil];
    PHAsset *asset = result.firstObject;
    if (!asset)
    {
        //QNBLogWarn(@"requestAVAssetWithLocalIdentifier : %@ 不存在",localIdentifier);
        dispatch_async(dispatch_get_main_queue(), ^{ completion(nil); });
        return;
    }
    PHVideoRequestOptions * options = [[PHVideoRequestOptions alloc] init];
    options.version = PHVideoRequestOptionsVersionCurrent;
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
    options.networkAccessAllowed = NO;
    options.progressHandler = handler;
    [self.mediaManager requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset* avasset, AVAudioMix* audioMix, NSDictionary* info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(avasset);
            
        });
    }];
}

-(void) requestAVAssetForVideoWith:(NSString *) identifier{
    PHFetchResult<PHAsset *> *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];
    PHAsset *asset = result.firstObject;
    // 如果  identifier 不合法直接返回
    if (!identifier.length || !asset) {
        NSError* error = [NSError errorWithDomain:kIcloudOperationDomain code:QHPIcloudOperationInvalidIdentifier userInfo:nil];
        if(self.delegate && [(NSObject *)self.delegate respondsToSelector:@selector(qhpPhotoKitHelper:cancelWithIdentifier:error:)]){
            [self.delegate qhpPhotoKitHelper:self cancelWithIdentifier:identifier error:error];
        }
        return;
    }
    // icloud 视频不进行缓存
//    if([self avCacheContains:identifier]) {
//        AVAsset *aVAsset = [self.aVAssetCache valueForKey:identifier];
//        if(self.delegate && [(NSObject *)self.delegate respondsToSelector:@selector(qhpPhotoKitHelper:completeWithIdentifier:aVAsset:avAudioMix:info:)]){
//            [self.delegate qhpPhotoKitHelper:self completeWithIdentifier:identifier aVAsset:aVAsset avAudioMix:nil info:nil];
//        }
//        return;
//    }
    if([self taskCacheContains:identifier]) {
        //Do Nothing
        return;
    }
    
    [self addIcloudTask:asset];
}

-(void) cancelAVAssetForVideoWith:(NSString *) identifier{
    if([self taskCacheContains:identifier]) {
        //Do Nothing
        return;
    }
    QHPIcloudOperation* operation = [self.taskCache valueForKey:identifier];
    if(operation) {
        [operation cancelTask];
    }
}

- (void)requestImageWithPHAsset:(PHAsset *)asset targetSize:(CGSize)targetSize resultHandler:(void (^)(UIImage *, NSDictionary *))handler {
    if (!handler) { return; }
    NSString *identifier = asset.localIdentifier;
    NSMutableDictionary *imageCache = self.imageCache;
    UIImage *cachedImage = [imageCache objectForKey:identifier];
    if (cachedImage) {
        handler(cachedImage, nil);
        return;
    }
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.resizeMode = PHImageRequestOptionsResizeModeExact;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.networkAccessAllowed = YES;
    [self.cacheImageManager requestImageForAsset:asset
                                               targetSize:targetSize
                                              contentMode:PHImageContentModeAspectFill
                                                  options:options
                                            resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                                if (!result) return;
                                                BOOL isDegraded = [info[PHImageResultIsDegradedKey] boolValue];
                                                if (!isDegraded) {
                                                    [imageCache setObject:result forKey:identifier];
                                                }
                                                dispatch_async(dispatch_get_main_queue(), ^{ handler(result, info); });
                                            }];
}

#pragma mark - image Cache
-(void) startCachingImagesForAssets:(NSArray<PHAsset *> *)assets  targetSize:(CGSize)targetSize{
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.resizeMode = PHImageRequestOptionsResizeModeExact;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.networkAccessAllowed = YES;
    [self.cacheImageManager startCachingImagesForAssets:assets targetSize:targetSize contentMode:PHImageContentModeAspectFill options:options];
}

-(void) stopCachingImagesForAssets:(NSArray<PHAsset *> *)assets  targetSize:(CGSize)targetSize{
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.resizeMode = PHImageRequestOptionsResizeModeExact;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.networkAccessAllowed = YES;
    [self.cacheImageManager stopCachingImagesForAssets:assets targetSize:targetSize contentMode:PHImageContentModeAspectFill options:options];
}

-(void) stopCachingImagesForAllAssets{
    [self.cacheImageManager stopCachingImagesForAllAssets];
}

#pragma mark - Icloud Query
- (AVAsset *)requestAVAssetWithLocalIdentifier:(NSString *)localIdentifier
{
    AVAsset __block *resultAsset = nil;
    if (!localIdentifier.length) {
        return nil;
    }
    PHFetchResult<PHAsset *> *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil];
    PHAsset *asset = result.firstObject;
    if (!asset)
    {
        //QNBLogWarn(@"requestAVAssetWithLocalIdentifier : %@ 不存在",localIdentifier);
        return nil;
    }
    
    
    PHVideoRequestOptions * options = [[PHVideoRequestOptions alloc] init];
    options.version = PHVideoRequestOptionsVersionCurrent;
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
    options.networkAccessAllowed = NO;
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset* avasset, AVAudioMix* audioMix, NSDictionary* info) {
        resultAsset = avasset;
        dispatch_semaphore_signal(semaphore);
    }];
    //3秒超时
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 3* NSEC_PER_SEC));
    
    return resultAsset;
}

-(void)queryIcloudAssetItemWithIdentifiers:(NSArray <NSString *>*)identifiers
{
    dispatch_async(_iCloudQueryQueue, ^{
#if QueryIcloudCache
        if (self.icloudIdentifiers == nil) {
            self.icloudIdentifiers = [[NSMutableSet alloc] init];
        }
        
        //这里已经查过的就不要再查了
        if (self.icloudQueryedIdentifiers == nil) {
            self.icloudQueryedIdentifiers = [[NSMutableSet alloc] init];
        }
#endif
        
        @autoreleasepool {
            NSMutableArray* icloudList = [[NSMutableArray alloc] init];
            for (NSInteger i=0; i<identifiers.count; i++) {
                NSString *assetId = [identifiers objectAtIndex:i];
                //这里已经查过的就不要再查了
#if QueryIcloudCache
                if ([self.icloudQueryedIdentifiers containsObject:assetId]) {
                    continue;
                }
#endif
                AVAsset *resultAsset = [self requestAVAssetWithLocalIdentifier:assetId];
                if (resultAsset == nil) {
#if QueryIcloudCache
                    [self.icloudIdentifiers addObject:assetId];
#endif
                    [icloudList addObject:assetId];
                }
#if QueryIcloudCache
                [self.icloudQueryedIdentifiers addObject:assetId];
#endif
            }
            if([(NSObject *)self.icloudQueryDelegate respondsToSelector:@selector(qhpPhotoKitHelper:querySet:icloudSet:)]) {
                [self.icloudQueryDelegate qhpPhotoKitHelper:self querySet:identifiers icloudSet:icloudList];
            }
        }
    });
}

-(void) queryIcloudAssetAllItem
{
    dispatch_async(_iCloudQueryQueue, ^{
#if QueryIcloudCache
        if (self.icloudIdentifiers == nil) {
            self.icloudIdentifiers = [[NSMutableSet alloc] init];
        }

        //这里已经查过的就不要再查了
        if (self.icloudQueryedIdentifiers == nil) {
            self.icloudQueryedIdentifiers = [[NSMutableSet alloc] init];
        }
#endif
        
        NSArray* identifiers = [self.queryIcloudList mutableCopy];
        @autoreleasepool {
            NSMutableArray* icloudList = [[NSMutableArray alloc] init];
            for(NSString* icloudIdentifier in self.icloudIdentifiers) {
                [icloudList addObject:icloudIdentifier];
            }
            for (NSInteger i=0; i< identifiers.count; i++) {
                NSString *assetId = [identifiers objectAtIndex:i];
                //这里已经查过的就不要再查了
#if QueryIcloudCache
                if ([self.icloudQueryedIdentifiers containsObject:assetId]) {
                    continue;
                }
#endif
                AVAsset *resultAsset = [self requestAVAssetWithLocalIdentifier:assetId];
                if (resultAsset == nil) {
#if QueryIcloudCache
                    [self.icloudIdentifiers addObject:assetId];
#endif
                    [icloudList addObject:assetId];
                }
#if QueryIcloudCache
                [self.icloudQueryedIdentifiers addObject:assetId];
#endif
            }
            if([(NSObject *)self.icloudQueryDelegate respondsToSelector:@selector(qhpPhotoKitHelper:querySet:icloudSet:)]) {
                [self.icloudQueryDelegate qhpPhotoKitHelper:self querySet:identifiers icloudSet:icloudList];
            }
        }
    });
}

#pragma mark - clean cancel Method
-(void) cancelAllTask{
    [self.taskCache enumerateKeysAndObjectsUsingBlock:^(NSString* key, QHPIcloudOperation* obj, BOOL * _Nonnull stop) {
        [obj cancelTask];
    }];    
//    [self.queue cancelAllOperations];
}

#pragma mark ================   private Methods    ================
#pragma mark - 任务的管理
// 把任务加入到queue并开始执行
-(void) addNewIcloudTask2Queue:(PHAsset *)asset{
    DECLARE_WEAK_SELF
    QHPIcloudOperation* operation = [[QHPIcloudOperation alloc] initWithIdentifier:asset.localIdentifier phImageManager:_mediaManager asset:asset progressBlock:^(NSString *identifier, double progress, NSDictionary * _Nullable info) {
        DECLARE_STRONG_SELF
        if(strongSelf.delegate && [(NSObject *)strongSelf.delegate respondsToSelector:@selector(qhpPhotoKitHelper:progressWithIdentifier:progress:info:)]){
            [strongSelf.delegate qhpPhotoKitHelper:strongSelf progressWithIdentifier:identifier progress:progress info:info];
        }
    } completeBlock:^(NSString *identifier, AVAsset * _Nullable aVAsset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        DECLARE_STRONG_SELF
        [strongSelf dealWithCompleteWithIdentifier:identifier avAsset:aVAsset];
        if(strongSelf.delegate && [(NSObject *)strongSelf.delegate respondsToSelector:@selector(qhpPhotoKitHelper:completeWithIdentifier:aVAsset:avAudioMix:info:)]){
            [strongSelf.delegate qhpPhotoKitHelper:strongSelf completeWithIdentifier:identifier aVAsset:aVAsset avAudioMix:audioMix info:info];
        }
    } errorBlock:^(NSString *identifier, NSError * _Nullable error, NSDictionary *__nullable info) {
        DECLARE_STRONG_SELF
        [strongSelf dealWithErrorWithIdentifier:identifier];
        if([error.domain isEqualToString:kIcloudOperationDomain] && (error.code == QHPIcloudOperationCancel)) {
            if(strongSelf.delegate && [(NSObject *)strongSelf.delegate respondsToSelector:@selector(qhpPhotoKitHelper:cancelWithIdentifier:error:)]){
                [strongSelf.delegate qhpPhotoKitHelper:strongSelf cancelWithIdentifier:identifier error:error];
            }
        } else {
            if(strongSelf.delegate && [(NSObject *)strongSelf.delegate respondsToSelector:@selector(qhpPhotoKitHelper:failWithIdentifier:error:info:)]){
                [strongSelf.delegate qhpPhotoKitHelper:strongSelf failWithIdentifier:identifier error:error info:info];
            }
        }
    }];
    [self taskCacheAddWithIdentifier:operation.identifier qhpIcoudOperation:operation];
    [self.queue addOperation:operation];
    
#if KVOOperationTest
    [operation addObserver:self forKeyPath:@"cancelled" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    [operation addObserver:self forKeyPath:@"executing" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    [operation addObserver:self forKeyPath:@"finished" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
#endif
}

// 根据当前的状况来判断
-(void) addIcloudTask:(PHAsset *)asset{
    dispatch_async(_cacheQueue, ^{
        if(self.taskCache.count < kMaxConcurrent) {
            [self addNewIcloudTask2Queue:asset];
        } else {
            [self.waitTaskCache addObject:asset];
        }
    });
}

-(void) checkNeedPushWaitingTask{
    dispatch_async(_cacheQueue, ^{
        if(self.waitTaskCache.count){
            PHAsset *asset = [self.waitTaskCache lastObject];
            [self addNewIcloudTask2Queue:asset];
            [self.waitTaskCache removeObject:asset];
        }
    });
}

#pragma mark - 缓存处理 taskCache && aVAssetCache
-(BOOL) taskCacheContains:(NSString *) identifier{
    __block BOOL contains = NO;
    dispatch_async(_cacheQueue, ^{
        NSArray* keyArray = [self.taskCache allKeys];
        contains = [keyArray containsObject:identifier];
    });
    return contains;
}

-(void) taskCacheRemove:(NSString *) identifier{
    dispatch_async(_cacheQueue, ^{
        if([self.taskCache.allKeys containsObject:identifier]) {
            [self.taskCache removeObjectForKey:identifier];
        }
    });
}

-(void) taskCacheAddWithIdentifier:(NSString *) identifier qhpIcoudOperation:(QHPIcloudOperation *) operation{
    dispatch_async(_cacheQueue, ^{
        [self.taskCache setObject:operation forKey:operation.identifier];
    });
}

//-(BOOL) avCacheContains:(NSString *) identifier{
//    __block BOOL contains = NO;
//    dispatch_async(_cacheQueue, ^{
//        NSArray* keyArray = [self.aVAssetCache allKeys];
//        contains = [keyArray containsObject:identifier];
//    });
//    return contains;
//}
//
//-(void) avCacheAddWithIdentifier:(NSString *) identifier aVAsset:(AVAsset *) aVAsset{
//    if([self  avCacheContains:identifier]) {
//        dispatch_async(_cacheQueue, ^{
//            [self.aVAssetCache removeObjectForKey:identifier];
//        });
//    }
//    dispatch_async(_cacheQueue, ^{
//        [self.aVAssetCache setObject:aVAsset forKey:identifier];
//    });
//}


// 如果下载成功改变标志位 移除任务
-(void) dealWithErrorWithIdentifier:(NSString *) identifier{
    [self taskCacheRemove:identifier];
    [self checkNeedPushWaitingTask];
#if QueryIcloudCache
    [self updateCloudCacheWithIdentifier:identifier isCloud:YES];
#endif
}

-(void) dealWithCompleteWithIdentifier:(NSString *) identifier avAsset:(AVAsset *)aVAsset{
    [self taskCacheRemove:identifier];
    [self checkNeedPushWaitingTask];
//    [self avCacheAddWithIdentifier:identifier aVAsset:aVAsset];
#if QueryIcloudCache
    [self updateCloudCacheWithIdentifier:identifier isCloud:NO];
#endif
}

// 改变icloud的缓存
-(void) updateCloudCacheWithIdentifier:(NSString *) identifier isCloud:(BOOL) isIcloud{
    if(identifier == nil || identifier.length == 0){
        return;
    }
    dispatch_async(_iCloudQueryQueue, ^{
        if(![self.icloudQueryedIdentifiers containsObject:identifier]) {
            [self.icloudQueryedIdentifiers addObject:identifier];
        }
        if(isIcloud){
            if(![self.icloudIdentifiers containsObject:identifier]) {
                [self.icloudIdentifiers addObject:identifier];
            }
        } else {
            if([self.icloudIdentifiers containsObject:identifier]){
                [self.icloudIdentifiers removeObject:identifier];
            }
        }
    });
}



// 处理Change部分
-(void) dealWithChangeArray:(NSArray<PHAsset *> *) changeList changeType:(PhotoKitChangsType) type{
    dispatch_async(_cacheQueue, ^{
        for(PHAsset* asset in changeList) {
//            if([self avCacheContains:asset.localIdentifier]) {
//                [self.aVAssetCache removeObjectForKey:asset.localIdentifier];
//            }
            if(type == PhotoKitTypeInsert) {
                //如果是增加的话
                if(![self.queryIcloudList containsObject:asset.localIdentifier]){
                    [self.queryIcloudList addObject:asset.localIdentifier];
                }
            } else {
#if QueryIcloudCache
                // 去掉icloud
                if([self.icloudQueryedIdentifiers containsObject:asset.localIdentifier]) {
                    [self.icloudQueryedIdentifiers removeObject:asset.localIdentifier];
                }
                // 去掉icloud
                if([self.icloudIdentifiers containsObject:asset.localIdentifier]) {
                    [self.icloudIdentifiers removeObject:asset.localIdentifier];
                }
#endif
            }
        }
    });
}

// ImageCache 的缓存部分
-(void) resetCachedAssets{
    dispatch_async(_cacheQueue, ^{
        self.taskCache = [[NSMutableDictionary alloc] init];
//        self.aVAssetCache = [[NSMutableDictionary alloc] init];
#if QueryIcloudCache
        [self.icloudIdentifiers removeAllObjects];
        [self.icloudQueryedIdentifiers removeAllObjects];
#endif
        [self.queryIcloudList removeAllObjects];
    });
}

#pragma mark - PHPhotoLibraryChangeObserver
- (void)photoLibraryDidChange:(PHChange *)changeInstance{
    PHFetchResultChangeDetails *changes = [changeInstance changeDetailsForFetchResult:self.videoFetchResult];
    if(changes == nil) {
        return;
    }
    self.videoFetchResult = changes.fetchResultAfterChanges;
    if(changes.hasIncrementalChanges) {
        NSArray* removeList = changes.removedObjects;
        NSArray* changeList = changes.changedObjects;
        NSArray* insertList = changes.insertedObjects;
        [self dealWithChangeArray:removeList changeType:PhotoKitTypeRemove];
        [self dealWithChangeArray:changeList changeType:PhotoKitTypeChange];
        [self dealWithChangeArray:insertList changeType:PhotoKitTypeInsert];
        
    } else {
        [self resetCachedAssets];
        [self setUpAlbums];
    }
    if([(NSObject *)self.changeDelegate respondsToSelector:@selector(qhpPhotoKitHelper:phChangeDetail:)]){
        [self.changeDelegate qhpPhotoKitHelper:self phChangeDetail:changes];
    }
}

#pragma mark - KVO For Test
#if KVOOperationTest
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    NSLog(@"%@监听到%@属性的改变为%@",object,keyPath,change);
}
#endif
@end
