//
//  MSQPrivateVolume.h
//  VolumeButton
//
//  Created by jacoy on 16/8/24.
//  Copyright © 2016年 jacoy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MSQPrivateVolume : NSObject

@property (nonatomic, copy) dispatch_block_t tapBlock;
@property (nonatomic, copy) dispatch_block_t beginLongPressBlock;
@property (nonatomic, copy) dispatch_block_t endLongPressBlock;
+(instancetype)sharedInstance;

-(void)start;
-(void)stop;

@end
