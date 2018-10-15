//
//  FirsthViewController.m
//  PhotoKitDemo
//
//  Created by IanChen on 2018/10/14.
//  Copyright © 2018年 Iansl. All rights reserved.
//

#import "FirsthViewController.h"
#import "QHPIcoudProgress.h"

@interface FirsthViewController ()
{
    float _progress;
}
@property (weak, nonatomic) IBOutlet UITextField *inputView;
- (IBAction)starSetClick:(UIButton *)sender;
@property (nonatomic, strong) QHPIcoudProgress* progressView;
@end

@implementation FirsthViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.progressView = [[QHPIcoudProgress alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
    [self.view addSubview:self.progressView];
    _progress = 0.0;
}



- (IBAction)starSetClick:(UIButton *)sender {
    [self.view endEditing:YES];
    float temp = [self.inputView.text floatValue];
    if(temp >= 0.0 && temp <= 1.0){
        _progress = temp;
        [self.progressView setProgress:_progress];
    }
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    _progress += 0.1;
    if(_progress >= 1.1){
        _progress = 0;
    }
    [self.progressView setProgress:_progress];
}
@end
