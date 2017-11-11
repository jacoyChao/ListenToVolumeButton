//
//  MSQVolumeButton.h
//  Unity-iPhone
//
//  Created by jacoy on 16/8/19.
//
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface MSQVolumeButton : NSObject


@property (nonatomic, copy) dispatch_block_t tapBlock;
@property (nonatomic, copy) dispatch_block_t beginLongPressBlock;
@property (nonatomic, copy) dispatch_block_t endLongPressBlock;
@property (nonatomic, assign) BOOL isAvailable;

+ (instancetype)sharedInstance;

- (void)setVolume:(CGFloat)volume;
- (void)startStealingVolumeButtonEvents;
- (void)stopStealingVolumeButtonEvents;

@end

