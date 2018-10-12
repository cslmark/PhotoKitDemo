//
//  QHPCircleProgressView.m
//  FireVideo
//
//  Created by Iansl on 2018/10/3.
//  Copyright © 2018 Tencent Inc. All rights reserved.
//

#import "QHPDownLoadCircleProgress.h"


static const CGFloat kDefaultLineWidth = 3.0;

@implementation QHPDownLoadCircleProgress
-(instancetype) initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self){
        [self setup];
    }
    return self;
}

-(void)awakeFromNib{
    [super awakeFromNib];
    [self setup];
}

-(void) setup{
    _progress = 0;
    _lineWidth = kDefaultLineWidth;
    _cirCleR = 20.0;
    self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
}

-(void) setProgress:(CGFloat)progress{
    NSLog(@"progress ============= %@", @(progress));
    _progress = progress;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGFloat myW = rect.size.width;
    CGFloat myH = rect.size.height;
    CGPoint center = CGPointMake(myW/2, myH/2);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    UIColor* color = [UIColor blueColor];
    [color set];
    CGContextSetLineWidth(ctx, _lineWidth);
    CGContextAddArc(ctx, center.x, center.y, _cirCleR, 0.f, M_PI * 2 * _progress, 0);
    CGContextStrokePath(ctx);
}
@end
