//
//  JCVolumeListener.h
//  VolumeButton
//
//  Created by jacoy on 16/8/24.
//  Copyright © 2016年 jacoy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JCVolumeListener : NSObject

/**
 点击音量键
 */
@property (nonatomic, copy) dispatch_block_t tapBlock;

/**
 开始长按音量键
 */
@property (nonatomic, copy) dispatch_block_t beginLongPressBlock;


/**
 结束长按音量键
 */
@property (nonatomic, copy) dispatch_block_t endLongPressBlock;


+(instancetype)sharedInstance;

/**
 开始监听音量键
 */
-(void)start;

/**
 结束监听音量键
 */
-(void)stop;

@end
