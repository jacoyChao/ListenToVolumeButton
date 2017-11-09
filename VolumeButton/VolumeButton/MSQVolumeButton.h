//
//  MSQVolumeButton.h
//  Unity-iPhone
//
//  Created by jacoy on 16/8/19.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MSQVolumeButton : NSObject
@property (nonatomic,copy)dispatch_block_t upBlock;
@property (nonatomic, copy) dispatch_block_t downBlock;
@property (nonatomic, readonly) float launchVolume;

@property (nonatomic, copy) dispatch_block_t tapBlock;
@property (nonatomic, copy) dispatch_block_t beginLongPressBlock;
@property (nonatomic, copy) dispatch_block_t endLongPressBlock;
@property (nonatomic,assign)BOOL isAvailable;
-(void)setVolume:(CGFloat)volume;
+ (instancetype)sharedInstance;
- (void)startStealingVolumeButtonEvents;
- (void)stopStealingVolumeButtonEvents;

@end


//
////
////  MSQVolumeButton.h
////  Unity-iPhone
////
////  Created by jacoy on 16/8/19.
////
////
//
//#import <Foundation/Foundation.h>
//
//@interface MSQVolumeButton : NSObject
//
//@property (nonatomic, copy)dispatch_block_t upBlock;
//@property (nonatomic, copy) dispatch_block_t downBlock;
//@property (nonatomic, readonly) float launchVolume;
//
//@property (nonatomic, copy) dispatch_block_t tapBlock;
//@property (nonatomic, copy) dispatch_block_t beginLongPressBlock;
//@property (nonatomic, copy) dispatch_block_t endLongPressBlock;
//@property (nonatomic, assign) BOOL isAvailable;
//
//+ (instancetype)sharedInstance;
//
//- (void)setVolume:(CGFloat)volume;
//- (void)startStealingVolumeButtonEvents;
//- (void)stopStealingVolumeButtonEvents;
//
//@end

