//
//  QLDatePicker.m
//  Demo_QLDatePicker
//
//  Created by Shrek on 15/8/10.
//  Copyright (c) 2015年 M. All rights reserved.
//

/** QLDEBUG Print | M:method, L:line, C:content*/
#ifndef QLLog
#ifdef DEBUG
#define QLLog(FORMAT, ...) fprintf(stderr,"M:%s|L:%d|C->%s\n", __FUNCTION__, __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define QLLog(FORMAT, ...)
#endif
#endif

#define QLColorWithRGB(redValue, greenValue, blueValue) ([UIColor colorWithRed:((redValue)/255.0) green:((greenValue)/255.0) blue:((blueValue)/255.0) alpha:1])
#define QLColorRandom QLColorWithRGB(arc4random_uniform(256), arc4random_uniform(256), arc4random_uniform(256))

#import "QLDatePicker.h"

typedef NS_ENUM(NSUInteger, QLDatePickerComponentType) {
    QLDatePickerComponentTypeYear = 0,
    QLDatePickerComponentTypeMonth = 1,
    QLDatePickerComponentTypeDay = 2,
    QLDatePickerComponentTypeHour = 3,
    QLDatePickerComponentTypeMinute = 4
};

@interface QLDatePicker () <UIPickerViewDataSource, UIPickerViewDelegate>
{
    NSInteger _baseYear;
    NSInteger _yearCount;
    
    NSInteger _year;
    NSInteger _month;
    NSInteger _day;
    NSInteger _hour;
    NSInteger _minute;
    
    NSArray *_years;
    NSArray *_monthes;
    NSArray *_days;
    NSArray *_hours;
    NSArray *_minutes;
    
    NSInteger _totalCyclicCount;
    
    NSDateComponents *_componentsMinDate;
    NSDateComponents *_componentsMaxDate;
}

@end

@implementation QLDatePicker

- (NSCalendar *)calendar {
    if (!_calendar) {
        _calendar = [NSCalendar currentCalendar];
    }
    return _calendar;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self loadDefaultSetting];
    }
    return self;
}

#pragma mark - Load default UI and Data
- (void)loadDefaultSetting {
    self.dataSource = self;
    self.delegate = self;
    
    /** 年份 */
    _baseYear = 2000;
    _yearCount = 50;
    NSMutableArray *yearM = [NSMutableArray arrayWithCapacity:_yearCount];
    for (NSInteger index = _baseYear; index < _baseYear + _yearCount; index ++) {
        [yearM addObject:[NSString stringWithFormat:@"%zd年", index]];
    }
    _years = [yearM copy];
    
    /** 月份 */
    NSInteger monthCount = 12;
    NSMutableArray *monthM = [NSMutableArray arrayWithCapacity:monthCount];
    for (NSInteger index = 1; index < monthCount+1; index ++) {
        [monthM addObject:[NSString stringWithFormat:@"%2zd月", index]];
    }
    _monthes = [monthM copy];
    
    /** 日份 */
    NSInteger dayCount = 31;
    NSMutableArray *dayM = [NSMutableArray arrayWithCapacity:dayCount];
    for (NSInteger index = 1; index < dayCount+1; index ++) {
        [dayM addObject:[NSString stringWithFormat:@"%zd日", index]];
    }
    _days = [dayM copy];
    
    /** 时 */
    NSInteger hourCount = 24;
    NSMutableArray *hourM = [NSMutableArray arrayWithCapacity:hourCount];
    for (NSInteger index = 0; index < hourCount; index ++) {
        [hourM addObject:[NSString stringWithFormat:@"%zd", index]];
    }
    _hours = [hourM copy];
    
    /** 分 */
    NSInteger minuteCount = 60;
    NSMutableArray *minuteM = [NSMutableArray arrayWithCapacity:minuteCount];
    for (NSInteger index = 0; index < minuteCount; index ++) {
        [minuteM addObject:[NSString stringWithFormat:@"%zd", index]];
    }
    _minutes = [minuteM copy];
    
    _year = _baseYear;
    _month = 1;
    _day = 1;
    _hour = 0;
    _minute = 0;
    
    _totalCyclicCount = 20000;
    
    self.displayUnit = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute;
    
    [self reloadAllComponents];
    [self setDate:[NSDate date]];
}

#pragma mark - UIPickerViewDataSource, UIPickerViewDelegate
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return _years.count > 1 ? 5 : 0;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    switch (component) {
        case QLDatePickerComponentTypeYear:
            return _yearCount;
        case QLDatePickerComponentTypeMonth:
            return 12;
        case QLDatePickerComponentTypeDay:
            return 31;
        case QLDatePickerComponentTypeHour:
            return 24;
        case QLDatePickerComponentTypeMinute:
            return 60;
        default:
            return 0;
    }
}
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    switch (component) {
        case QLDatePickerComponentTypeYear: // 年
            return 65;
            
        case QLDatePickerComponentTypeMonth: // 月
        case QLDatePickerComponentTypeDay: // 日
            return 40;
            
        case QLDatePickerComponentTypeHour: // 时
        case QLDatePickerComponentTypeMinute: // 分
            return 30;
            
        default:
            return 0;
    }
}
- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 30;
}
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    NSString *strTitle = @"titleForRow";
    NSInteger days = 0;
    BOOL shouldGrayLabel = NO;
    
    /** 设置不可用日期的灰度 */
    switch (component) {
        case QLDatePickerComponentTypeYear: {
            strTitle = _years[row];
            
            NSInteger yearMin = _componentsMinDate.year;
            NSInteger yearOnMin;
            NSString *strYearOnMin = _years[row];
            NSScanner *scanner = [NSScanner scannerWithString:strYearOnMin];
            [scanner scanInteger:(NSInteger *)&yearOnMin];
            if (_minimumDate && yearMin > yearOnMin) {
                shouldGrayLabel = YES;
            }
            
            NSInteger yearMax = _componentsMaxDate.year;
            NSInteger yearOnMax;
            NSString *strYearOnMax = _years[row];
            scanner = [NSScanner scannerWithString:strYearOnMax];
            [scanner scanInteger:(NSInteger *)&yearOnMax];
            if (_maximumDate && yearMax < yearOnMax) {
                shouldGrayLabel = YES;
            }
            
            break;
        }
        case QLDatePickerComponentTypeMonth: {
            strTitle = _monthes[row];
            
            NSInteger yearMin = _componentsMinDate.year;
            if (_minimumDate && _year <= yearMin) {
                NSInteger monthMin = _componentsMinDate.month;
                NSInteger monthOn;
                NSString *strMonth = _monthes[row];
                NSScanner *scanner = [NSScanner scannerWithString:strMonth];
                [scanner scanInteger:(NSInteger *)&monthOn];
                shouldGrayLabel = monthMin > monthOn;
            }
            
            NSInteger yearMax = _componentsMaxDate.year;
            if (_maximumDate && _year >= yearMax) {
                NSInteger monthMax = _componentsMaxDate.month;
                NSInteger monthOn;
                NSString *strMonth = _monthes[row];
                NSScanner *scanner = [NSScanner scannerWithString:strMonth];
                [scanner scanInteger:(NSInteger *)&monthOn];
                shouldGrayLabel = monthMax < monthOn;
            }
            
            break;
        }
        case QLDatePickerComponentTypeDay: {
            strTitle = _days[row];
            days = [self getCurrentMonthDays];
            
            NSInteger yearMin = _componentsMinDate.year;
            NSInteger monthMin = _componentsMinDate.month;
            if (_minimumDate && _year <= yearMin && _month <= monthMin) {
                NSInteger dayMin = _componentsMinDate.day;
                NSInteger dayOn;
                NSString *strday = _days[row];
                NSScanner *scanner = [NSScanner scannerWithString:strday];
                [scanner scanInteger:(NSInteger *)&dayOn];
                shouldGrayLabel = dayMin > dayOn;
            }
            
            NSInteger yearMax = _componentsMaxDate.year;
            NSInteger monthMax = _componentsMaxDate.month;
            if (_maximumDate && _year >= yearMax && _month >= monthMax) {
                NSInteger dayMax = _componentsMaxDate.day;
                NSInteger dayOn;
                NSString *strday = _days[row];
                NSScanner *scanner = [NSScanner scannerWithString:strday];
                [scanner scanInteger:(NSInteger *)&dayOn];
                shouldGrayLabel = dayMax < dayOn;
            }
            
            break;
        }
        case QLDatePickerComponentTypeHour: {
            strTitle = _hours[row];
            
            NSInteger yearMin = _componentsMinDate.year;
            NSInteger monthMin = _componentsMinDate.month;
            NSInteger dayMin = _componentsMinDate.day;
            if (_minimumDate && _year <= yearMin && _month <= monthMin && _day <= dayMin) {
                NSInteger hourMin = _componentsMinDate.hour;
                NSInteger hourOn;
                NSString *strHour = _hours[row];
                NSScanner *scanner = [NSScanner scannerWithString:strHour];
                [scanner scanInteger:(NSInteger *)&hourOn];
                shouldGrayLabel = hourMin > hourOn;
            }
            
            NSInteger yearMax = _componentsMaxDate.year;
            NSInteger monthMax = _componentsMaxDate.month;
            NSInteger dayMax = _componentsMaxDate.day;
            if (_maximumDate && _year >= yearMax && _month >= monthMax && _day >= dayMax) {
                NSInteger hourMax = _componentsMaxDate.hour;
                NSInteger hourOn;
                NSString *strHour = _hours[row];
                NSScanner *scanner = [NSScanner scannerWithString:strHour];
                [scanner scanInteger:(NSInteger *)&hourOn];
                shouldGrayLabel = hourMax < hourOn;
            }
            
            break;
        }
        case QLDatePickerComponentTypeMinute: {
            strTitle = _minutes[row];
            
            NSInteger yearMin = _componentsMinDate.year;
            NSInteger monthMin = _componentsMinDate.month;
            NSInteger dayMin = _componentsMinDate.day;
            NSInteger hourMin = _componentsMinDate.hour;
            if (_minimumDate && _year <= yearMin && _month <= monthMin && _day <= dayMin && _hour <= hourMin) {
                NSInteger minuteMin = _componentsMinDate.minute;
                NSInteger minuteOn;
                NSString *strMinute = _minutes[row];
                NSScanner *scanner = [NSScanner scannerWithString:strMinute];
                [scanner scanInteger:(NSInteger *)&minuteOn];
                shouldGrayLabel = minuteMin > minuteOn;
            }
            
            NSInteger yearMax = _componentsMaxDate.year;
            NSInteger monthMax = _componentsMaxDate.month;
            NSInteger dayMax = _componentsMaxDate.day;
            NSInteger hourMax = _componentsMaxDate.hour;
            if (_maximumDate && _year >= yearMax && _month >= monthMax && _day >= dayMax && _hour >= hourMax) {
                NSInteger minuteMax = _componentsMaxDate.minute;
                NSInteger minuteOn;
                NSString *strMinute = _minutes[row];
                NSScanner *scanner = [NSScanner scannerWithString:strMinute];
                [scanner scanInteger:(NSInteger *)&minuteOn];
                shouldGrayLabel = minuteMax < minuteOn;
            }
            
            break;
        }
    }
    UILabel *label = [UILabel new];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = strTitle;
    
    if ((days > 27 && row >= days) || shouldGrayLabel) {
        label.textColor = [UIColor darkGrayColor];
    } else {
        label.textColor = [UIColor blackColor];
    }
    
    return label;
}
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    switch (component) {
        case QLDatePickerComponentTypeYear: {
            /** 设置最小的年份及其不可用时的自动跳转 */
            NSInteger yearCurrent;
            NSString *strYear = _years[row];
            NSScanner *scanner = [NSScanner scannerWithString:strYear];
            [scanner scanInteger:&yearCurrent];
            
            NSInteger yearMin = _componentsMinDate.year;
            NSInteger yearMax = _componentsMaxDate.year;
            if (yearCurrent < yearMin) {
                NSInteger yearTempMin;
                
                NSString *strYearMin = _years[row];
                NSScanner *scannerMin = [NSScanner scannerWithString:strYearMin];
                [scannerMin scanInteger:&yearTempMin];
                NSInteger deltaYearMin = yearMin - yearTempMin;
                if (deltaYearMin > 0) {
                    _year = yearMin;
                    NSInteger selectedRow = row + deltaYearMin;
                    [self selectRow:selectedRow inComponent:QLDatePickerComponentTypeYear animated:YES];
                    strYearMin = _years[selectedRow];
                    scannerMin = [NSScanner scannerWithString:strYearMin];
                    [scannerMin scanInteger:&yearTempMin];
                    if (yearTempMin == yearMin) {
                        NSInteger dayMonth = [self selectedRowInComponent:QLDatePickerComponentTypeMonth];
                        [self pickerView:pickerView didSelectRow:dayMonth inComponent:QLDatePickerComponentTypeMonth];
                    }
                } else if (deltaYearMin == 0) {
                    _year = yearTempMin;
                    NSInteger monthRow = [self selectedRowInComponent:QLDatePickerComponentTypeMonth];
                    [self pickerView:pickerView didSelectRow:monthRow inComponent:QLDatePickerComponentTypeMonth];
                } else {
                    _year = yearTempMin;
                }
            } else if (yearCurrent > yearMax) {
                /** 设置最大的年份及其不可用时的自动跳转 */
                NSInteger yearTempMax;
                
                NSString *strYearMax = _years[row];
                NSScanner *scannerMax = [NSScanner scannerWithString:strYearMax];
                [scannerMax scanInteger:&yearTempMax];
                NSInteger deltaYearMax = yearMax - yearTempMax;
                if (deltaYearMax < 0) {
                    _year = yearMax;
                    NSInteger selectedRow = row + deltaYearMax;
                    [self selectRow:selectedRow inComponent:QLDatePickerComponentTypeYear animated:YES];
                    strYearMax = _years[selectedRow];
                    scannerMax = [NSScanner scannerWithString:strYearMax];
                    [scannerMax scanInteger:&yearTempMax];
                    if (yearTempMax == yearMax) {
                        NSInteger dayMonth = [self selectedRowInComponent:QLDatePickerComponentTypeMonth];
                        [self pickerView:pickerView didSelectRow:dayMonth inComponent:QLDatePickerComponentTypeMonth];
                    }
                } else if (deltaYearMax == 0) {
                    _year = yearTempMax;
                    NSInteger monthRow = [self selectedRowInComponent:QLDatePickerComponentTypeMonth];
                    [self pickerView:pickerView didSelectRow:monthRow inComponent:QLDatePickerComponentTypeMonth];
                } else {
                    _year = yearTempMax;
                }
            } else {
                _year = yearCurrent;
            }
            
            [self reloadComponent:QLDatePickerComponentTypeMonth];
            break;
        }
        case QLDatePickerComponentTypeMonth: {
            /** 设置最小的月份及其不可用时的自动跳转 */
            NSInteger yearMin = _componentsMinDate.year;
            NSInteger yearMax = _componentsMaxDate.year;
            if (yearMin == _year) {
                NSInteger monthMin = _componentsMinDate.month;
                NSInteger monthTempMin;
                
                NSString *strMonthMin = _monthes[row];
                NSScanner *scannerMin = [NSScanner scannerWithString:strMonthMin];
                [scannerMin scanInteger:(NSInteger *)&monthTempMin];
                NSInteger deltaMonthMin = monthMin - monthTempMin;
                if (deltaMonthMin > 0) {
                    _month = monthMin;
                    NSInteger selectedRow = row + deltaMonthMin;
                    [self selectRow:selectedRow inComponent:QLDatePickerComponentTypeMonth animated:YES];
                    strMonthMin = _monthes[selectedRow];
                    scannerMin = [NSScanner scannerWithString:strMonthMin];
                    [scannerMin scanInteger:&monthTempMin];
                    if (monthTempMin == monthMin) {
                        NSInteger dayRow = [self selectedRowInComponent:QLDatePickerComponentTypeDay];
                        [self pickerView:pickerView didSelectRow:dayRow inComponent:QLDatePickerComponentTypeDay];
                    }
                } else if (deltaMonthMin == 0) {
                    _month = monthTempMin;
                    NSInteger dayRow = [self selectedRowInComponent:QLDatePickerComponentTypeDay];
                    [self pickerView:pickerView didSelectRow:dayRow inComponent:QLDatePickerComponentTypeDay];
                } else {
                    _month = monthTempMin;
                }
            } else if (yearMax == _year) { /** 设置最大的月份及其不可用时的自动跳转 */
                NSInteger monthMax = _componentsMaxDate.month;
                NSInteger monthTempMax;
                
                NSString *strMonthMax = _monthes[row];
                NSScanner *scannerMax = [NSScanner scannerWithString:strMonthMax];
                [scannerMax scanInteger:(NSInteger *)&monthTempMax];
                NSInteger deltaMonthMax = monthMax - monthTempMax;
                if (deltaMonthMax < 0) {
                    _month = monthMax;
                    NSInteger selectedRow = row + deltaMonthMax;
                    [self selectRow:selectedRow inComponent:QLDatePickerComponentTypeMonth animated:YES];
                    strMonthMax = _monthes[selectedRow];
                    scannerMax = [NSScanner scannerWithString:strMonthMax];
                    [scannerMax scanInteger:&monthTempMax];
                    if (monthTempMax == monthMax) {
                        NSInteger dayRow = [self selectedRowInComponent:QLDatePickerComponentTypeDay];
                        [self pickerView:pickerView didSelectRow:dayRow inComponent:QLDatePickerComponentTypeDay];
                    }
                } else if (deltaMonthMax == 0) {
                    _month = monthTempMax;
                    NSInteger dayRow = [self selectedRowInComponent:QLDatePickerComponentTypeDay];
                    [self pickerView:pickerView didSelectRow:dayRow inComponent:QLDatePickerComponentTypeDay];
                } else {
                    _month = monthTempMax;
                }
            } else {
                NSString *strMonth = _monthes[row];
                NSScanner *scanner = [NSScanner scannerWithString:strMonth];
                [scanner scanInteger:(NSInteger *)&_month];
            }
            
            NSInteger deltaDay = _day - [self getCurrentMonthDays];
            if (deltaDay > 0) {
                NSInteger selectedRow = [self selectedRowInComponent:2];
                [self selectRow:selectedRow-deltaDay inComponent:2 animated:YES];
                
                NSString *strDay = _days[selectedRow-deltaDay];
                NSScanner *scanner = [NSScanner scannerWithString:strDay];
                [scanner scanInteger:(NSInteger *)&_day];
            }
            [self reloadComponent:QLDatePickerComponentTypeDay];
            break;
        }
        case QLDatePickerComponentTypeDay: {
            /** 设置最小的日及其不可用时的自动跳转 */
            NSInteger yearMin = _componentsMinDate.year;
            NSInteger monthMin = _componentsMinDate.month;
            NSInteger yearMax = _componentsMaxDate.year;
            NSInteger monthMax = _componentsMaxDate.month;
            if (yearMin == _year && monthMin == _month) {
                NSInteger dayMin = _componentsMinDate.day;
                NSInteger dayTempMin;
                
                NSString *strDayMin = _days[row];
                NSScanner *scannerMin = [NSScanner scannerWithString:strDayMin];
                [scannerMin scanInteger:(NSInteger *)&dayTempMin];
                NSInteger deltaDayMin = dayMin - dayTempMin;
                if (deltaDayMin > 0) {
                    _day = dayMin;
                    NSInteger selectedRow = row + deltaDayMin;
                    [self selectRow:selectedRow inComponent:QLDatePickerComponentTypeDay animated:YES];
                    strDayMin = _days[selectedRow];
                    scannerMin = [NSScanner scannerWithString:strDayMin];
                    [scannerMin scanInteger:&dayTempMin];
                    if (dayTempMin == dayMin) {
                        NSInteger dayRow = [self selectedRowInComponent:QLDatePickerComponentTypeHour];
                        [self pickerView:pickerView didSelectRow:dayRow inComponent:QLDatePickerComponentTypeHour];
                    }
                } else if (deltaDayMin == 0) {
                    _day = dayTempMin;
                    NSInteger dayRow = [self selectedRowInComponent:QLDatePickerComponentTypeHour];
                    [self pickerView:pickerView didSelectRow:dayRow inComponent:QLDatePickerComponentTypeHour];
                } else {
                    _day = dayTempMin;
                }
            } else if (yearMax == _year && monthMax == _month) { /** 设置最大的日及其不可用时的自动跳转 */
                NSInteger dayMax = _componentsMaxDate.day;
                NSInteger dayTempMax;
                
                NSString *strDayMax = _days[row];
                NSScanner *scannerMax = [NSScanner scannerWithString:strDayMax];
                [scannerMax scanInteger:(NSInteger *)&dayTempMax];
                NSInteger deltaDayMax = dayMax - dayTempMax;
                if (deltaDayMax < 0) {
                    _day = dayMax;
                    NSInteger selectedRow = row + deltaDayMax;
                    [self selectRow:selectedRow inComponent:QLDatePickerComponentTypeDay animated:YES];
                    strDayMax = _days[selectedRow];
                    scannerMax = [NSScanner scannerWithString:strDayMax];
                    [scannerMax scanInteger:&dayTempMax];
                    if (dayTempMax == dayMax) {
                        NSInteger dayRow = [self selectedRowInComponent:QLDatePickerComponentTypeHour];
                        [self pickerView:pickerView didSelectRow:dayRow inComponent:QLDatePickerComponentTypeHour];
                    }
                } else if (deltaDayMax == 0) {
                    _day = dayTempMax;
                    NSInteger dayRow = [self selectedRowInComponent:QLDatePickerComponentTypeHour];
                    [self pickerView:pickerView didSelectRow:dayRow inComponent:QLDatePickerComponentTypeHour];
                } else {
                    _day = dayTempMax;
                }
            } else {
                NSString *strDay = _days[row];
                NSScanner *scanner = [NSScanner scannerWithString:strDay];
                [scanner scanInteger:(NSInteger *)&_day];
            }
            
            NSInteger delta = _day - [self getCurrentMonthDays];
            if (delta > 0) {
                NSInteger selectedRow = [self selectedRowInComponent:2];
                [self selectRow:selectedRow-delta inComponent:2 animated:YES];
                
                NSString *strDay = _days[selectedRow-delta];
                NSScanner *scanner = [NSScanner scannerWithString:strDay];
                [scanner scanInteger:(NSInteger *)&_day];
            }
            [self reloadComponent:QLDatePickerComponentTypeHour];
            break;
        }
        case QLDatePickerComponentTypeHour: {
            /** 设置最小的小时及其不可用时的自动跳转 */
            NSInteger yearMin = _componentsMinDate.year;
            NSInteger monthMin = _componentsMinDate.month;
            NSInteger dayMin = _componentsMinDate.day;
            NSInteger yearMax = _componentsMaxDate.year;
            NSInteger monthMax = _componentsMaxDate.month;
            NSInteger dayMax = _componentsMaxDate.day;
            if (yearMin == _year && monthMin == _month && dayMin == _day) {
                NSInteger hourMin = _componentsMinDate.hour;
                NSInteger hourTempMin;
                
                NSString *strHourMin = _hours[row];
                NSScanner *scannerMin = [NSScanner scannerWithString:strHourMin];
                [scannerMin scanInteger:(NSInteger *)&hourTempMin];
                NSInteger deltaHourMin = hourMin - hourTempMin;
                if (deltaHourMin > 0) {
                    _hour = hourMin;
                    NSInteger selectedRow = row + deltaHourMin;
                    [self selectRow:selectedRow inComponent:QLDatePickerComponentTypeHour animated:YES];
                    strHourMin = _hours[selectedRow];
                    scannerMin = [NSScanner scannerWithString:strHourMin];
                    [scannerMin scanInteger:&hourTempMin];
                    if (hourTempMin == hourMin) {
                        NSInteger hourRow = [self selectedRowInComponent:QLDatePickerComponentTypeMinute];
                        [self pickerView:pickerView didSelectRow:hourRow inComponent:QLDatePickerComponentTypeMinute];
                    }
                } else if (deltaHourMin == 0) {
                    _hour = hourTempMin;
                    NSInteger hourRow = [self selectedRowInComponent:QLDatePickerComponentTypeMinute];
                    [self pickerView:pickerView didSelectRow:hourRow inComponent:QLDatePickerComponentTypeMinute];
                } else {
                    _hour = hourTempMin;
                }
            } else if (yearMax == _year && monthMax == _month && dayMax == _day) { /** 设置最大的小时及其不可用时的自动跳转 */
                NSInteger hourMax = _componentsMaxDate.hour;
                NSInteger hourTempMax;
                
                NSString *strHourMax = _hours[row];
                NSScanner *scannerMax = [NSScanner scannerWithString:strHourMax];
                [scannerMax scanInteger:(NSInteger *)&hourTempMax];
                NSInteger deltaHourMax = hourMax - hourTempMax;
                if (deltaHourMax < 0) {
                    _hour = hourMax;
                    NSInteger selectedRow = row + deltaHourMax;
                    [self selectRow:selectedRow inComponent:QLDatePickerComponentTypeHour animated:YES];
                    strHourMax = _hours[selectedRow];
                    scannerMax = [NSScanner scannerWithString:strHourMax];
                    [scannerMax scanInteger:&hourTempMax];
                    if (hourTempMax == hourMax) {
                        NSInteger hourRow = [self selectedRowInComponent:QLDatePickerComponentTypeMinute];
                        [self pickerView:pickerView didSelectRow:hourRow inComponent:QLDatePickerComponentTypeMinute];
                    }
                } else if (deltaHourMax == 0) {
                    _hour = hourTempMax;
                    NSInteger hourRow = [self selectedRowInComponent:QLDatePickerComponentTypeMinute];
                    [self pickerView:pickerView didSelectRow:hourRow inComponent:QLDatePickerComponentTypeMinute];
                } else {
                    _hour = hourTempMax;
                }
            } else {
                NSString *strHour = _hours[row];
                NSScanner *scanner = [NSScanner scannerWithString:strHour];
                [scanner scanInteger:(NSInteger *)&_hour];
            }
            
            [self reloadComponent:QLDatePickerComponentTypeMinute];
            break;
        }
        case QLDatePickerComponentTypeMinute: {
            /** 设置最小的分钟及其不可用时的自动跳转 */
            NSInteger yearMin = _componentsMinDate.year;
            NSInteger monthMin = _componentsMinDate.month;
            NSInteger dayMin = _componentsMinDate.day;
            NSInteger hourMin = _componentsMinDate.hour;
            NSInteger yearMax = _componentsMaxDate.year;
            NSInteger monthMax = _componentsMaxDate.month;
            NSInteger dayMax = _componentsMaxDate.day;
            NSInteger hourMax = _componentsMaxDate.hour;
            if (yearMin == _year && monthMin == _month && dayMin == _day && hourMin == _hour) {
                NSInteger minuteMin = _componentsMinDate.minute;
                NSInteger minuteTemp;
                
                NSString *strMinute = _minutes[row];
                NSScanner *scanner = [NSScanner scannerWithString:strMinute];
                [scanner scanInteger:(NSInteger *)&minuteTemp];
                NSInteger deltaminute = minuteMin - minuteTemp;
                if (deltaminute > 0) {
                    _minute = minuteMin;
                    NSInteger selectedRow = row + deltaminute;
                    [self selectRow:selectedRow inComponent:QLDatePickerComponentTypeMinute animated:YES];
                } else {
                    _minute = minuteTemp;
                }
            } else if (yearMax == _year && monthMax == _month && dayMax == _day && hourMax == _hour) { /** 设置最大的分钟及其不可用时的自动跳转 */
                NSInteger minuteMax = _componentsMaxDate.minute;
                NSInteger minuteTempMax;
                
                NSString *strMinute = _minutes[row];
                NSScanner *scanner = [NSScanner scannerWithString:strMinute];
                [scanner scanInteger:(NSInteger *)&minuteTempMax];
                NSInteger deltaminute = minuteMax - minuteTempMax;
                if (deltaminute < 0) {
                    _minute = minuteMax;
                    NSInteger selectedRow = row + deltaminute;
                    [self selectRow:selectedRow inComponent:QLDatePickerComponentTypeMinute animated:YES];
                } else {
                    _minute = minuteTempMax;
                }
            } else {
                NSString *strMinute = _minutes[row];
                NSScanner *scanner = [NSScanner scannerWithString:strMinute];
                [scanner scanInteger:(NSInteger *)&_minute];
            }
        }
    }
    if ([self.delegateForAction respondsToSelector:@selector(datePicker:DidSelectDate:)]) {
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"yyyyMMddHHmm";
        NSString *strYear = [NSString stringWithFormat:@"%zd", _year];
        NSString *strMonth = _month < 10 ? [NSString stringWithFormat:@"0%zd", _month] : [NSString stringWithFormat:@"%zd", _month];
        NSString *strDay = _day < 10 ? [NSString stringWithFormat:@"0%zd", _day] : [NSString stringWithFormat:@"%zd", _day];
        NSString *strHour = _hour < 10 ? [NSString stringWithFormat:@"0%zd", _hour] : [NSString stringWithFormat:@"%zd", _hour];
        NSString *strMinute = _minute < 10 ? [NSString stringWithFormat:@"0%zd", _minute] : [NSString stringWithFormat:@"%zd", _minute];
        NSString *strDateSelected = [NSString stringWithFormat:@"%@%@%@%@%@", strYear, strMonth, strDay, strHour, strMinute];
        NSDate *dateSelected = [dateFormatter dateFromString:strDateSelected];
        [self.delegateForAction datePicker:self DidSelectDate:dateSelected];
    }
}

#pragma mark - Private
- (NSString *)validateDateStringFromYear:(NSInteger)year Month:(NSInteger)month {
    NSString *strMonth = [NSString stringWithFormat:@"%zd", month];
    if (month < 10) {
        strMonth = [NSString stringWithFormat:@"0%zd", month];
    }
    return [NSString stringWithFormat:@"%zd%@", _year, strMonth];
}
- (NSInteger)getCurrentMonthDays {
    // 找出这个月有多少天
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyyMM";
    NSString *strDate = [self validateDateStringFromYear:_year Month:_month];
    NSDate *date = [formatter dateFromString:strDate];
    NSRange range = [self.calendar rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:date];
    return range.length;
}

#pragma mark - OverRide
- (void)setDate:(NSDate *)date {
    _date = date;
    //  通过已定义的日历对象，获取某个时间点的NSDateComponents表示，并设置需要表示哪些信息（NSCalendarUnitYear, NSCalendarUnitMonth, NSCalendarUnitDay等）
    NSDateComponents *components = [self.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:date];
    
    NSInteger year = components.year;
    [self selectRow:year-_baseYear inComponent:0 animated:YES];
    _year = year;
    
    NSInteger month = components.month;
    [self selectRow:month-1 inComponent:1 animated:YES];
    _month = month;
    
    NSInteger day = components.day;
    [self selectRow:day-1 inComponent:2 animated:YES];
    _day = day;
    
    NSInteger hour = components.hour;
    [self selectRow:hour inComponent:3 animated:YES];
    _hour = hour;
    
    NSInteger minute = components.minute;
    [self selectRow:minute inComponent:4 animated:YES];
    _minute = minute;
}
- (void)setMinimumDate:(NSDate *)minimumDate {
    if (self.maximumDate) {
        NSComparisonResult result = [minimumDate compare:self.maximumDate];
        if (result == NSOrderedAscending || result == NSOrderedSame) {
            _minimumDate = minimumDate;
        }
    } else {
        _minimumDate = minimumDate;
    }
    
    if (_minimumDate) {
        _componentsMinDate = [self.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:_minimumDate];
        //[self reloadAllComponents];
    }
}
- (void)setMaximumDate:(NSDate *)maximumDate {
    if (self.minimumDate) {
        NSComparisonResult result = [maximumDate compare:self.minimumDate];
        if (result == NSOrderedDescending || result == NSOrderedSame) {
            _maximumDate = maximumDate;
        }
    } else {
        _maximumDate = maximumDate;
    }
    
    if (_maximumDate) {
        _componentsMaxDate = [self.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:_maximumDate];
        //[self reloadAllComponents];
    }
}

@end
