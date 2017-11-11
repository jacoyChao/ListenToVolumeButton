//
//  MSQPrivateVolume.m
//  VolumeButton
//
//  Created by jacoy on 16/8/24.
//  Copyright © 2016年 jacoy. All rights reserved.
//

#import "MSQPrivateVolume.h"
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@interface MSQPrivateVolume ()

@property (nonatomic,strong)NSDate *lastDate;

@property (nonatomic,strong)NSTimer *timer;
@property (nonatomic,assign)NSTimer *timer1;
@property (nonatomic,assign)NSTimeInterval timeInterval;
@property (nonatomic,assign)BOOL isRecording;
@property (nonatomic,assign)BOOL releaseVolumeButton;
@property (nonatomic, strong) UIView *volumeView;

@end

@implementation MSQPrivateVolume

+ (instancetype)sharedInstance
{
    static id _volumeInstance;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _volumeInstance = [[MSQPrivateVolume alloc]init];
    });
    
    return _volumeInstance;
}

-(instancetype)init{
    if (self = [super init]) {
        self.lastDate = [NSDate date];
    }
    
    return self;
}


-(void)start{
    NSLog(@"start");
    [[NSNotificationCenter defaultCenter] addObserver:self
     
                                             selector:@selector(volumeChanged:)
     
                                                 name:@"AVSystemController_SystemVolumeDidChangeNotification"
     
                                               object:nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    self.volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(-20, -20, 10, 10)];
    
    self.volumeView.hidden = NO;
    
    [self.volumeView sizeToFit];
    
    [[[[UIApplication sharedApplication] windows] firstObject] insertSubview:self.volumeView atIndex:0];
}

-(void)stop{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self.volumeView removeFromSuperview];
    self.volumeView = nil;
}

-(void)volumeChanged:(NSNotification *)noti

{
    NSDate *date = [NSDate date];
    NSTimeInterval time = [date timeIntervalSinceDate:self.lastDate];
    
    self.lastDate = date;
    
    if (time >= 0.23) {
        
        if (!self.timer) {
            self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(longPress) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
            
            if (self.timer) {
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (self.timer) {
                        if (self.tapBlock) {
                            self.tapBlock();
                            
                            [self removeTimer];
                        }
                    }
                    
                });
            }
        }
        
    }
//    NSLog(@"time = %f",time);
    self.timeInterval = time;
    self.releaseVolumeButton = NO;
}




-(void)releaseVolume{
    
    if (self.releaseVolumeButton == YES) {
//        NSLog(@"结束长按");
        if (self.endLongPressBlock)
        {
            self.endLongPressBlock();
        }
        
        [self.timer1 invalidate];
        self.timer1 = nil;
    }
    self.releaseVolumeButton = YES;
    
}


-(void)longPress{
    
    if (self.timeInterval <= 0.3) {
//        NSLog(@"开始长按");
        if (self.beginLongPressBlock)
        {
            self.beginLongPressBlock();
        }
        self.isRecording = YES;
        [self removeTimer];
        
        if (!self.timer1) {
            self.timer1 = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(releaseVolume) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:self.timer1 forMode:NSRunLoopCommonModes];
        }
    }
}

-(void)removeTimer{
    [self.timer invalidate];
    self.timer = nil;
}
@end
