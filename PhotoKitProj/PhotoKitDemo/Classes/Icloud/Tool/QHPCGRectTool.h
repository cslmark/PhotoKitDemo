//
//  QHPCGRectTool.h
//  iOSPhotoKit
//
//  Created by Iansl on 2018/10/10.
//  Copyright © 2018 Iansl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef float(^ValueBlock)(CGRect rect);
typedef CGRect(^ExpandBlock)(CGRect rect, CGFloat dx, CGFloat dy);

@interface QHPCGRectTool : NSObject
+(ValueBlock) midY;
+(ValueBlock) minY;
+(ValueBlock) maxY;

+(ExpandBlock) insetBy;
@end
