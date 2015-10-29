//
//  QLDatePicker.h
//  Demo_QLDatePicker
//
//  Created by Shrek on 15/8/10.
//  Copyright (c) 2015年 M. All rights reserved.
//

#import <UIKit/UIKit.h>

@class QLDatePicker;

@protocol QLDatePickerDelegate <NSObject>

- (void)datePicker:(QLDatePicker *)datePicker DidSelectDate:(NSDate *)date;

@end

@interface QLDatePicker : UIPickerView

/** default is NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute */
@property (nonatomic) NSCalendarUnit displayUnit;

/** default is [NSCalendar currentCalendar]. setting nil returns to default */
@property (nonatomic, copy) NSCalendar *calendar;

/** default is current date when picker created. */
@property (nonatomic, strong) NSDate *date;

/** specify min/max date range. default is nil. When min > max, the values are ignored. */
@property (nonatomic, strong) NSDate *minimumDate;

/** default is nil */
@property (nonatomic, strong) NSDate *maximumDate;

@property (nonatomic, weak) id<QLDatePickerDelegate> delegateForAction;

//@property (nonatomic) NSInteger minuteInterval;    // display minutes wheel with interval. interval must be evenly divided into 60. default is 1. min is 1, max is 30
//@property (nonatomic, retain) NSTimeZone *timeZone; // default is nil. use current time zone or time zone from calendar
//@property (nonatomic, retain) NSLocale   *locale;   // default is [NSLocale currentLocale]. setting nil returns to default
//- (void)setDate:(NSDate *)date animated:(BOOL)animated; // if animated is YES, animate the wheels of time to display the new date
@end
