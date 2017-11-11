//
//  ViewController.m
//  VolumeButton
//
//  Created by jacoy on 16/8/20.
//  Copyright © 2016年 jacoy. All rights reserved.
//

#import "ViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "JCVolumeListener.h"

@interface ViewController ()



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [JCVolumeListener sharedInstance].beginLongPressBlock = ^{
        NSLog(@"开始长按");

    };

    [JCVolumeListener sharedInstance].endLongPressBlock = ^{
        NSLog(@"结束长按");

    };

    [JCVolumeListener sharedInstance].tapBlock = ^{
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

    [[JCVolumeListener sharedInstance] start];
}

- (IBAction)stop:(id)sender {
    
    NSLog(@"结束监听");
    
    [[JCVolumeListener sharedInstance] stop];
}


@end
