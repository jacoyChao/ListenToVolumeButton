//
//  MSQVolumeButton.m
//  Unity-iPhone
//
//  Created by jacoy on 16/8/19.
//
//

#import "MSQVolumeButton.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
@interface MSQVolumeButton ()

@property (nonatomic, assign) BOOL isStealingVolumeButtons;
@property (nonatomic, assign) BOOL hadToLowerVolume;
@property (nonatomic, assign) BOOL hadToRaiseVolume;
@property (nonatomic, assign) BOOL suspended;
@property (nonatomic, readwrite) float launchVolume;
@property (nonatomic, strong) UIView *volumeView;
@property (nonatomic,strong)NSDate *lastDate;
@property (nonatomic,strong)NSTimer *timer;
@property (nonatomic,assign)NSTimer *timer1;
@property (nonatomic,assign)NSTimeInterval timeInterval;
@property (nonatomic,assign)BOOL isRecording;
@property (nonatomic,assign)BOOL releaseVolumeButton;

@end

@implementation MSQVolumeButton

static void volumeListenerCallback (
                                    void                      *inClientData,
                                    AudioSessionPropertyID    inID,
                                    UInt32                    inDataSize,
                                    const void                *inData
                                    ){
    const float *volumePointer = inData;
    float volume = *volumePointer;
    
    if (volume > [(__bridge MSQVolumeButton*)inClientData launchVolume])
    {
        [(__bridge MSQVolumeButton*)inClientData volumeUp];
    }
    else if (volume < [(__bridge MSQVolumeButton*)inClientData launchVolume])
    {
        [(__bridge MSQVolumeButton*)inClientData volumeDown];
    }
}
+ (instancetype)sharedInstance
{
    static id _volumeInstance;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _volumeInstance = [MSQVolumeButton new];
    });
    
    return _volumeInstance;
}
-(instancetype)init{
    if (self = [super init]) {
        self.lastDate = [NSDate date];
    }
    
    return self;
}
- (void)volumeUp
{
    AudioSessionRemovePropertyListenerWithUserData(kAudioSessionProperty_CurrentHardwareOutputVolume, volumeListenerCallback, (__bridge void *)(self));
    
    [self setVolume:self.launchVolume];
    
    [self performSelector:@selector(initializeVolumeButtonStealer) withObject:self afterDelay:0.1];
   
    if (self.upBlock)
    {
        self.upBlock();
    }
    
    [self clickVolumeButton];
}

- (void)volumeDown
{
    AudioSessionRemovePropertyListenerWithUserData(kAudioSessionProperty_CurrentHardwareOutputVolume, volumeListenerCallback, (__bridge void *)(self));
    
    [self setVolume:self.launchVolume];
    [self performSelector:@selector(initializeVolumeButtonStealer) withObject:self afterDelay:0.1];
    
    if (self.downBlock)
    {
        self.downBlock();
    }
    [self clickVolumeButton];
}

- (void)startStealingVolumeButtonEvents
{
    NSAssert([[NSThread currentThread] isMainThread], @"This must be called from the main thread");
    
    if (self.isStealingVolumeButtons)
    {
        return;
    }
    
    self.isStealingVolumeButtons = YES;
    
    AudioSessionInitialize(NULL, NULL, NULL, NULL);
    
    const UInt32 sessionCategory = kAudioSessionCategory_AmbientSound;
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
    
    [[AVAudioSession sharedInstance] setActive:YES error:nil];

    self.launchVolume = [[MPMusicPlayerController applicationMusicPlayer] volume];
    self.hadToLowerVolume = self.launchVolume == 1.0;
    self.hadToRaiseVolume = self.launchVolume == 0.0;
    
    CGRect frame = CGRectMake(0, -100, 10, 0);
    self.volumeView = [[MPVolumeView alloc] initWithFrame:frame];
    [self.volumeView sizeToFit];
    [[[[UIApplication sharedApplication] windows] firstObject] insertSubview:self.volumeView atIndex:0];
    
    // Avoid flashing the volume indicator
    if (self.hadToLowerVolume || self.hadToRaiseVolume)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.hadToLowerVolume)
            {
                [self setVolume:0.8];
                self.launchVolume = 0.8;
            }
            
            if (self.hadToRaiseVolume)
            {
                [self setVolume:0.2];
                self.launchVolume = 0.2;
            }
        });
    }
    
    
    
    [self initializeVolumeButtonStealer];
    
    if (!self.suspended)
    {
        // Observe notifications that trigger suspend
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(suspendStealingVolumeButtonEvents:)
                                                     name:UIApplicationWillResignActiveNotification     // -> Inactive
                                                   object:nil];
        
        // Observe notifications that trigger resume
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(resumeStealingVolumeButtonEvents:)
                                                     name:UIApplicationDidBecomeActiveNotification      // <- Active
                                                   object:nil];
    }
}

- (void)suspendStealingVolumeButtonEvents:(NSNotification *)notification
{
    if (self.isStealingVolumeButtons)
    {
        self.suspended = YES; // Call first!
        [self stopStealingVolumeButtonEvents];
        self.isAvailable = NO;
    }
}

- (void)resumeStealingVolumeButtonEvents:(NSNotification *)notification
{
    if (self.suspended)
    {
        [self startStealingVolumeButtonEvents];
        self.suspended = NO; // Call last!
        self.isAvailable = YES;
    }
}

- (void)stopStealingVolumeButtonEvents
{
    NSAssert([[NSThread currentThread] isMainThread], @"This must be called from the main thread");
    
    if (!self.isStealingVolumeButtons)
    {
        return;
    }
    
    // Stop observing all notifications
    if (!self.suspended)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    
    AudioSessionRemovePropertyListener(kAudioSessionProperty_CurrentHardwareOutputVolume);
    

    [self.volumeView removeFromSuperview];
    self.volumeView = nil;
    self.isStealingVolumeButtons = NO;
}


-(void)setVolume:(CGFloat)volume{
    [[MPMusicPlayerController applicationMusicPlayer] setVolume:volume];
}


- (void)dealloc
{
    self.suspended = NO;
    [self stopStealingVolumeButtonEvents];
    
    self.upBlock = nil;
    self.downBlock = nil;
}

- (void)initializeVolumeButtonStealer
{
    AudioSessionAddPropertyListener(kAudioSessionProperty_CurrentHardwareOutputVolume, volumeListenerCallback, (__bridge void *)(self));
}


-(void)clickVolumeButton {
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
                        if (self.tapBlock && self.isAvailable)
                        {
                            self.tapBlock();
                        }
                        [self removeTimer];
                    }
                    
                });
            }
        }
        
    }
    self.timeInterval = time;
    self.releaseVolumeButton = NO;
}

-(void)setIsAvailable:(BOOL)isAvailable{
    _isAvailable = isAvailable;
    
}


-(void)releaseVolume{
    
    if (self.releaseVolumeButton == YES) {
        if (self.endLongPressBlock && self.isAvailable)
        {
            self.endLongPressBlock();
        }
        
        [self.timer1 invalidate];
        self.timer1 = nil;
    }
    self.releaseVolumeButton = YES;
    
}


-(void)longPress{
    
    if (self.timeInterval <= 0.23) {
        if (self.beginLongPressBlock && self.isAvailable)
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







//
////
////  MSQVolumeButton.m
////  Unity-iPhone
////
////  Created by jacoy on 16/8/19.
////
////
//
//#import "MSQVolumeButton.h"
//#import <MediaPlayer/MediaPlayer.h>
//#import <AudioToolbox/AudioToolbox.h>
//#import <AVFoundation/AVFoundation.h>
//
//@interface MSQVolumeButton ()
//
//@property (nonatomic, assign) BOOL isStealingVolumeButtons;
//@property (nonatomic, assign) BOOL hadToLowerVolume;
//@property (nonatomic, assign) BOOL hadToRaiseVolume;
//@property (nonatomic, assign) BOOL suspended;
//@property (nonatomic, readwrite) float launchVolume;
//@property (nonatomic, strong) UIView *volumeView;
//
//@property (nonatomic,strong)NSDate *lastDate;
//
//@property (nonatomic,strong)NSTimer *timer;
//@property (nonatomic,assign)NSTimer *timer1;
//
//@property (nonatomic,assign)NSTimeInterval timeInterval;
//@property (nonatomic,assign)BOOL isRecording;
//@property (nonatomic,assign)BOOL releaseVolumeButton;
//
//@end
//
//@implementation MSQVolumeButton
//
//static void volumeListenerCallback (
//                                    void                      *inClientData,
//                                    AudioSessionPropertyID    inID,
//                                    UInt32                    inDataSize,
//                                    const void                *inData
//                                    ){
//    const float *volumePointer = inData;
//    float volume = *volumePointer;
//
//    if (volume > [(__bridge MSQVolumeButton*)inClientData launchVolume])
//    {
//        [(__bridge MSQVolumeButton*)inClientData volumeUp];
//    }
//    else if (volume < [(__bridge MSQVolumeButton*)inClientData launchVolume])
//    {
//        [(__bridge MSQVolumeButton*)inClientData volumeDown];
//    }
//}
//
//+ (instancetype)sharedInstance
//{
//    static id _volumeInstance;
//    static dispatch_once_t onceToken;
//
//    dispatch_once(&onceToken, ^{
//        _volumeInstance = [MSQVolumeButton new];
//    });
//
//    return _volumeInstance;
//}
//
//- (void)dealloc
//{
//    self.suspended = NO;
//    [self stopStealingVolumeButtonEvents];
//
//    self.upBlock = nil;
//    self.downBlock = nil;
//}
//
//-(instancetype)init{
//    if (self = [super init]) {
//        self.lastDate = [NSDate date];
//    }
//
//    return self;
//}
//
//- (void)volumeUp
//{
//    AudioSessionRemovePropertyListenerWithUserData(kAudioSessionProperty_CurrentHardwareOutputVolume, volumeListenerCallback, (__bridge void *)(self));
//
//    [self setVolume:self.launchVolume];
//
//    [self performSelector:@selector(initializeVolumeButtonStealer) withObject:self afterDelay:0.1];
//
//    if (self.upBlock)
//    {
//        self.upBlock();
//    }
//
//    [self clickVolumeButton];
//}
//
//- (void)volumeDown
//{
//    AudioSessionRemovePropertyListenerWithUserData(kAudioSessionProperty_CurrentHardwareOutputVolume, volumeListenerCallback, (__bridge void *)(self));
//
//    [self setVolume:self.launchVolume];
//    [self performSelector:@selector(initializeVolumeButtonStealer) withObject:self afterDelay:0.1];
//
//    if (self.downBlock)
//    {
//        self.downBlock();
//    }
//    [self clickVolumeButton];
//}
//
//- (void)startStealingVolumeButtonEvents
//{
//
//    if (self.isStealingVolumeButtons)
//    {
//        return;
//    }
//
//    self.isStealingVolumeButtons = YES;
//
//    AudioSessionInitialize(NULL, NULL, NULL, NULL);
//
//    const UInt32 sessionCategory = kAudioSessionCategory_AmbientSound;
//    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
//
//    [[AVAudioSession sharedInstance] setActive:YES error:nil];
//
//    self.launchVolume = [[MPMusicPlayerController applicationMusicPlayer] volume];
//    self.hadToLowerVolume = self.launchVolume == 1.0;
//    self.hadToRaiseVolume = self.launchVolume == 0.0;
//
//    CGRect frame = CGRectMake(0, -100, 10, 0);
//    self.volumeView = [[MPVolumeView alloc] initWithFrame:frame];
//    [self.volumeView sizeToFit];
//    [[[[UIApplication sharedApplication] windows] firstObject] insertSubview:self.volumeView atIndex:0];
//
//    // Avoid flashing the volume indicator
//    if (self.hadToLowerVolume || self.hadToRaiseVolume)
//    {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if (self.hadToLowerVolume)
//            {
//                [self setVolume:0.8];
//                self.launchVolume = 0.8;
//            }
//
//            if (self.hadToRaiseVolume)
//            {
//                [self setVolume:0.2];
//                self.launchVolume = 0.2;
//            }
//        });
//    }
//
//    [self initializeVolumeButtonStealer];
//
//    if (!self.suspended)
//    {
//        // Observe notifications that trigger suspend
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(suspendStealingVolumeButtonEvents:)
//                                                     name:UIApplicationWillResignActiveNotification     // -> Inactive
//                                                   object:nil];
//
//        // Observe notifications that trigger resume
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(resumeStealingVolumeButtonEvents:)
//                                                     name:UIApplicationDidBecomeActiveNotification      // <- Active
//                                                   object:nil];
//    }
//}
//
//- (void)suspendStealingVolumeButtonEvents:(NSNotification *)notification
//{
//    if (self.isStealingVolumeButtons)
//    {
//        self.suspended = YES; // Call first!
//        [self stopStealingVolumeButtonEvents];
//        self.isAvailable = NO;
//    }
//}
//
//- (void)resumeStealingVolumeButtonEvents:(NSNotification *)notification
//{
//    if (self.suspended)
//    {
//        [self startStealingVolumeButtonEvents];
//        self.suspended = NO; // Call last!
//        self.isAvailable = YES;
//    }
//}
//
//- (void)stopStealingVolumeButtonEvents
//{
//
//    if (!self.isStealingVolumeButtons)
//    {
//        return;
//    }
//
//    // Stop observing all notifications
//    if (!self.suspended)
//    {
//        [[NSNotificationCenter defaultCenter] removeObserver:self];
//    }
//
//    AudioSessionRemovePropertyListener(kAudioSessionProperty_CurrentHardwareOutputVolume);
//
//
//    [self.volumeView removeFromSuperview];
//    self.volumeView = nil;
//    self.isStealingVolumeButtons = NO;
//}
//
//
//-(void)setVolume:(CGFloat)volume{
//    [[MPMusicPlayerController applicationMusicPlayer] setVolume:volume];
//}
//
//- (void)initializeVolumeButtonStealer
//{
//    AudioSessionAddPropertyListener(kAudioSessionProperty_CurrentHardwareOutputVolume, volumeListenerCallback, (__bridge void *)(self));
//}
//
//-(void)clickVolumeButton {
//    NSDate *date = [NSDate date];
//    NSTimeInterval time = [date timeIntervalSinceDate:self.lastDate];
//
//    self.lastDate = date;
//
//    // 时间间隔大于0.23,开始一次新的按键记录,并在里面判断是单击还是长按
//    if (time >= 0.23) {
//        if (!self.timer) {
//            // ???: 这个方法会将定时器加到default mode中，用timerWithTimeInterval:...就可以了
//            self.timer = [NSTimer timerWithTimeInterval:0.01 target:self selector:@selector(longPress) userInfo:nil repeats:YES];
//            //            self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(longPress) userInfo:nil repeats:YES];
//            [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
//
//            if (self.timer) {
//                // 如果是长按  第一个时间间隔是0.6   0.6s后就可以不再监听
//                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                    //如果是长按,则已经销毁了定时器,不会再进这个方法
//                    if (self.timer) {
//                        if (self.tapBlock && self.isAvailable) {
//                            self.tapBlock();
//
//                            [self removeTimer];
//                        }
//                    }
//                });
//            }
//        }
//    }
//
//    self.timeInterval = time;
//    self.releaseVolumeButton = NO;
//}
//
//-(void)releaseVolume{
//    if (self.releaseVolumeButton == YES) {
//        if (self.endLongPressBlock && self.isAvailable)
//        {
//            self.endLongPressBlock();
//        }
//
//        [self.timer1 invalidate];
//        self.timer1 = nil;
//    }
//    self.releaseVolumeButton = YES;
//}
//
//
//-(void)longPress{
//    //长按的第一次时间间隔是0.6s左右,所以判断小于0.7s就是长按
//    if (self.timeInterval <= 0.7) {
//        if (self.beginLongPressBlock && self.isAvailable)
//        {
//            self.beginLongPressBlock();
//        }
//        self.isRecording = YES;
//        [self removeTimer];
//
//        if (!self.timer1) {
//            self.timer1 = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(releaseVolume) userInfo:nil repeats:YES];
//            [[NSRunLoop currentRunLoop] addTimer:self.timer1 forMode:NSRunLoopCommonModes];
//        }
//    }
//}
//
//-(void)removeTimer{
//    [self.timer invalidate];
//    self.timer = nil;
//}
//
//
//@end

