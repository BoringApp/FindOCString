//
//  NSError+extension.m
//  AVFoundationTest
//
//  Created by ZhangGaoming on 16/10/2016.
//  Copyright © 2016 ZhangGaoming. All rights reserved.
//

#import "NSError+extension.h"

@implementation NSError (extension)
- (void)logErrorInfo{
    NSLog(@"\n\n\n\n-------------------> ### ERROR DECODE BEGIN ### <------------------- \n 方法名：%s \n 文件: %s, 行：%d \n 错误描述 :%@ \n 错误原因 : %@, \n 错误实例: \n %@ \n -------------------> ### ERROR DECODE END ### <------------------- \n\n\n", __func__,  __FILE__, __LINE__, self.localizedDescription, self.localizedFailureReason,  self);
}
@end
