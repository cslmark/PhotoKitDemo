//
//  QHPIcloudOperation.h
//  FireVideo
//
//  Created by Iansl on 2018/10/10.
//  Copyright © 2018 Tencent Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

typedef NS_ENUM(NSUInteger, QHPIcloudOperationErrorCode) {
    QHPIcloudOperationCancel = 10000,
    QHPIcloudOperationCompleteWihAvssetNil = 10001,
    QHPIcloudOperationInvalidIdentifier = 10002,
};
typedef void(^ProgressBlock)(NSString* identifier, double progress, NSDictionary *__nullable info);
typedef void(^CompleteBlock)(NSString* identifier, AVAsset * _Nullable aVAsset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info);
typedef void(^ErrorBlock)(NSString* identifier,  NSError *__nullable error, NSDictionary *__nullable info);

extern const NSErrorDomain kIcloudOperationDomain;

@interface QHPIcloudOperation : NSOperation
@property (nonatomic, copy) NSString* identifier;
@property (nonatomic, strong) PHImageManager* manager;
@property (nonatomic, strong) PHAsset* asset;
@property (nonatomic, copy) ProgressBlock progressHandler;
@property (nonatomic, copy) CompleteBlock completeHandler;
@property (nonatomic, copy) ErrorBlock errorHandler;

-(instancetype) initWithIdentifier:(NSString*) identifier
                    phImageManager:(PHImageManager *) manager
                             asset:(PHAsset*) asset
                     progressBlock:(ProgressBlock) progressHandler
                     completeBlock:(CompleteBlock) completeHandler
                        errorBlock:(ErrorBlock) errorHandler;
-(void) cancelTask;
@end
