//
//  QLViewController.m
//  Demo_QLDatePicker
//
//  Created by Shrek on 15/8/10.
//  Copyright (c) 2015年 M. All rights reserved.
//

#import "QLViewController.h"
#import "QLDatePicker.h"
#import "Masonry.h"

@interface QLViewController () <QLDatePickerDelegate>

@end

@implementation QLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __weak typeof(self) selfWeak = self;
    
    QLDatePicker *datePicker = [QLDatePicker new];
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyyMMddHHmm";
    NSDate *dateMin = [formatter dateFromString:@"201407110743"];
    //[datePicker setDate:date];
    [datePicker setMinimumDate:dateMin];
    NSDate *dateMax = [formatter dateFromString:@"201609122010"];
    [datePicker setMaximumDate:dateMax];
    datePicker.delegateForAction = self;
    [self.view addSubview:datePicker];
    
    [datePicker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(selfWeak.view);
        make.left.and.right.equalTo(selfWeak.view);
        make.height.equalTo(@(80));
    }];
}

#pragma mark - QLDatePickerDelegate
- (void)datePicker:(QLDatePicker *)datePicker DidSelectDate:(NSDate *)date {
    NSLog(@"%@", date);
}

@end
