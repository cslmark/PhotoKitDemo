//
//  QHPIcloudOperation.m
//  FireVideo
//
//  Created by Iansl on 2018/10/10.
//  Copyright © 2018 Tencent Inc. All rights reserved.
//

#import "QHPIcloudOperation.h"
#import "GlobalDefines.h"

const NSErrorDomain  kIcloudOperationDomain = @"QHPIcloudOperationDomain";

@interface QHPIcloudOperation()
@property (nonatomic, assign) PHImageRequestID requestID;
@end

@implementation QHPIcloudOperation
- (void)main{
    @autoreleasepool{
        if(self.isCancelled) {
            return;
        }
        dispatch_semaphore_t sigal = dispatch_semaphore_create(0);
        PHVideoRequestOptions *videoOptions = [[PHVideoRequestOptions alloc] init];
        videoOptions.networkAccessAllowed = YES;
        videoOptions.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
        
        DECLARE_WEAK_SELF
        videoOptions.progressHandler = ^(double progress, NSError *__nullable error, BOOL *stop, NSDictionary *__nullable info) {
            DECLARE_STRONG_SELF
            if(strongSelf.isCancelled) {
                *stop = YES;
                return;
            } else {
                if(error) {
                    *stop = YES;
//                    if(self.errorHandler) {
//                        self.errorHandler(self.identifier, error, info);
////                        dispatch_semaphore_signal(sigal);
//                    }
                    return;
                }
            }
            if(strongSelf.progressHandler) {
                strongSelf.progressHandler(strongSelf.identifier ,progress, info);
            }
        };
        self.requestID = [self.manager requestAVAssetForVideo:self.asset options:videoOptions resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
            DECLARE_STRONG_SELF
            if(strongSelf.isCancelled) {
                // 如上如果*stop设置为YES是马上调用Complete回调 所以只需要在这里处理一次
                [strongSelf cancelHandler];
                dispatch_semaphore_signal(sigal);
                return;
            }
            if(asset == nil) {
                // 如果为空Dictionary里面的包含具体的错误信息
                [strongSelf downLoadAvAssetnilHandler:info];
                dispatch_semaphore_signal(sigal);
                return;
            } else {
                if(strongSelf.completeHandler) {
                    strongSelf.completeHandler(strongSelf.identifier, asset, audioMix, info);
                }
                dispatch_semaphore_signal(sigal);
            }
        }];
        dispatch_semaphore_wait(sigal, DISPATCH_TIME_FOREVER);
    }
}

-(instancetype) initWithIdentifier:(NSString*) identifier
                    phImageManager:(PHImageManager *) manager
                             asset:(PHAsset*) asset
                     progressBlock:(ProgressBlock) progressHandler
                     completeBlock:(CompleteBlock) completeHandler
                        errorBlock:(ErrorBlock) errorHandler{
    self = [super init];
    if(self) {
        _identifier = identifier;
        _manager = manager;
        _asset = asset;
        _progressHandler = progressHandler;
        _completeHandler = completeHandler;
        _errorHandler = errorHandler;
    }
    return self;
}

-(void) cancelHandler{
    NSError* reasonError = [NSError errorWithDomain:kIcloudOperationDomain code:QHPIcloudOperationCancel userInfo:nil];
    // dealloc 测试
    if(self.errorHandler) {
        self.errorHandler(self.identifier, reasonError, nil);
    }
}

-(void) downLoadAvAssetnilHandler:(NSDictionary *) info{
    NSError* reasonError = [NSError errorWithDomain:kIcloudOperationDomain code:QHPIcloudOperationCompleteWihAvssetNil userInfo:info];
    if(self.errorHandler) {
        self.errorHandler(self.identifier, reasonError, nil);
    }
}

-(void) cancelTask{
    [self.manager cancelImageRequest:self.requestID];
    [super cancel];
}

-(void)dealloc{
//    NSLog(@"操作完成被释放了。。。。。。。============>>>>>");
}


@end
