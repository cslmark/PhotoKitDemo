//
//  QHPCGRectTool.m
//  iOSPhotoKit
//
//  Created by Iansl on 2018/10/10.
//  Copyright © 2018 Iansl. All rights reserved.
//

#import "QHPCGRectTool.h"

@implementation QHPCGRectTool
+(ValueBlock) midY{
    return ^float(CGRect rect){
        CGFloat y = rect.origin.y;
        CGFloat height = rect.size.height;
        return y+height/2.0;
    };
}

+(ValueBlock) minY{
    return ^float(CGRect rect){
        CGFloat y = rect.origin.y;
        return y;
    };
}

+(ValueBlock) maxY{
    return ^float(CGRect rect){
        CGFloat y = rect.origin.y;
        CGFloat height = rect.size.height;
        return ((y+height)/2.0);
    };
}

+(ExpandBlock) insetBy{
    return ^CGRect(CGRect rect, CGFloat dx, CGFloat dy){
        CGFloat rectX = rect.origin.x;
        CGFloat rectY = rect.origin.y;
        CGFloat rectW = rect.size.width;
        CGFloat rectH = rect.size.height;
        if(dx > rectW/2 && dy > rectH/2) {
            return CGRectZero;
        } else {
            rectX = rectX + dx;
            rectY = rectY + dy;
            rectW = rectW - 2*dx;
            rectH = rectH - 2*dy;
            return CGRectMake(rectX, rectY, rectW, rectH);
        }
    };
}
@end
