//
//  ViewController.m
//  VolumeButton
//
//  Created by jacoy on 16/8/20.
//  Copyright © 2016年 jacoy. All rights reserved.
//

#import "ViewController.h"
#import "MSQVolumeButton.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "MSQPrivateVolume.h"

@interface ViewController ()

@property (nonatomic,strong)MSQVolumeButton *buttonStealer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//
//    self.buttonStealer = [MSQVolumeButton sharedInstance];
//    self.buttonStealer.isAvailable = YES;
//   self.buttonStealer.tapBlock = ^{
//        NSLog(@"单击");
//    };
//    
//    self.buttonStealer.beginLongPressBlock = ^{
//        NSLog(@"开始长按");
//    };
//    
//    self.buttonStealer.endLongPressBlock = ^{
//        NSLog(@"结束长按");
//    };
    
    [MSQPrivateVolume sharedInstance].beginLongPressBlock = ^{
        NSLog(@"开始长按");

    };
    
    [MSQPrivateVolume sharedInstance].endLongPressBlock = ^{
        NSLog(@"结束长按");
        
    };
    
    [MSQPrivateVolume sharedInstance].tapBlock = ^{
        NSLog(@"单击");
        
    };
    
    [[AVAudioSession sharedInstance] setActive:YES error:nil];

    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(-20, -20, 10, 10)];

    volumeView.hidden = NO;

    [volumeView sizeToFit];

    [self.view addSubview:volumeView];

}

- (IBAction)start:(id)sender {

    NSLog(@"开始监听");
//    [[MSQVolumeButton sharedInstance] startStealingVolumeButtonEvents];
    [[MSQPrivateVolume sharedInstance] start];
}

- (IBAction)stop:(id)sender {
    
    NSLog(@"结束监听");
    [[MSQPrivateVolume sharedInstance] stop];

//    [[MSQVolumeButton sharedInstance] stopStealingVolumeButtonEvents];
}

//-(void)volumeChanged:(NSNotification *)noti
//
//{
//
//    float volume =
//
//    [[[noti userInfo]
//
//      objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"]
//
//     floatValue];
//
//    NSLog(@"volumn is %f", volume);
//
//}




@end
