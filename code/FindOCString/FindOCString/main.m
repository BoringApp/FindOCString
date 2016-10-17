//
//  main.m
//  FindOCString
//
//  Created by ZhangGaoming on 17/10/2016.
//  Copyright © 2016 ZhangGaoming. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSError+extension.h"


// @"[^"]*[\u4E00-\u9FA5]+[^"\n]*?"

// /Users/GM/Desktop/test

#define DEFAULT_OUTPUT_PATH [[NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"output.txt"]

static int RETURN_CODE_FILE_NOT_EXIST = 0x2;

static NSString *const INPUT_FILE_PATH = @"/Users/GM/Linknow_iOS/LinkNow/Classes";
//static NSString *const INPUT_FILE_PATH = @"/Users/GM/Desktop/test/test.txt";
static const char *const SERIAL_QUEUE_NAME = "com.GMWorkStudio.OutputOCString";

BOOL isDir;

/**
 * @brief 获取用户输入的地址
 * @return 用户输入的文件地址
 */
NSString *getUserInputPath() {
    int maxLength = 256;
    char filePathC[maxLength];
    NSLog(@"请输入文件或文件夹地址");
    //    scanf("%s", &filePathC);
    
    fgets(filePathC, maxLength, stdin);
    
    filePathC[strlen(filePathC) - 1] = '\0';
    
    return [NSString stringWithCString:filePathC encoding:NSUTF8StringEncoding];
}

/**
 * 输入单个文件,输出文件中的 OC 字符串
 * @param filePathURL 文件地址
 * @return 是否输出成功
 */
BOOL outputSingleFile(NSURL *filePathURL) {
    assert(filePathURL);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSError *error = nil;
    // 载入输入的文件内容
    NSString *inputFileContent = [NSString stringWithContentsOfURL:filePathURL encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        [error logErrorInfo];
        return NO;
    }
    
    NSString *regexString = @"@\"[^\"]*[\\u4E00-\\u9FA5]+[^\"\\n]*?\"";
    NSError *regexError = nil;
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:regexString
                                                                                       options:NSRegularExpressionCaseInsensitive
                                                                                         error:&regexError];
    assert(!regexError);
    NSArray<NSTextCheckingResult *> *results = [regularExpression matchesInString:inputFileContent
                                                                          options:0
                                                                            range:NSMakeRange(0, inputFileContent.length)];
    
    
    
    
    // 单个文件的匹配输出
    NSMutableString *singleFileRegexContent = [NSMutableString string];
    [results enumerateObjectsUsingBlock:^(NSTextCheckingResult *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSString *string = [inputFileContent substringWithRange:obj.range];
        [singleFileRegexContent appendFormat:@"%@\n", string];
    }];
    
    // `输出文件`中的所有内容
    
    
    NSStringEncoding encoding;
    
    // 1. 读取输出文件
    // 1.1 判断文件是否存在-> 存在读取 不存在创建
    
    if ([fileManager fileExistsAtPath:DEFAULT_OUTPUT_PATH]) {
        NSError *loadFileError = nil;
        [NSString stringWithContentsOfFile:DEFAULT_OUTPUT_PATH
                                     usedEncoding:&encoding
                                            error:&loadFileError];
        if (error) {
            [error logErrorInfo];
            return NO;
        }
    } else {
        // 创建文件
        encoding = NSUTF8StringEncoding;
        BOOL isCreateSuccess = [fileManager createFileAtPath:DEFAULT_OUTPUT_PATH
                                                    contents:nil
                                                  attributes:nil];
        if (!isCreateSuccess) {
            NSLog(@"文件不存在,并且创建文件失败!");
            return NO;
        }
    }
    
    __block BOOL returnType = YES;
    dispatch_sync(dispatch_queue_create(SERIAL_QUEUE_NAME, DISPATCH_QUEUE_SERIAL), ^{
        NSFileHandle *fileHandel = [NSFileHandle fileHandleForWritingAtPath:DEFAULT_OUTPUT_PATH];
        if (!fileHandel) {
            NSLog(@"文件句柄打失败!");
            returnType = NO;
        }
        [fileHandel seekToEndOfFile];
        [fileHandel writeData:[singleFileRegexContent dataUsingEncoding:encoding]];
        [fileHandel closeFile];
    });
    
    //    NSLog(@"%@", singleFileRegexContent);
    return returnType;
}

void outputDirOCString(NSURL *dirPath) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *dirPathStr = dirPath.path;
    if (![fileManager isWritableFileAtPath:dirPath.path])return;
    NSArray<NSString *> *files = [fileManager subpathsAtPath:dirPathStr];
    __block int count = 0;
    [files enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        NSString *extension = [obj pathExtension];
        
        if (extension.length > 0 && ([extension isEqualToString:@"m"] || [extension isEqualToString:@"mm"])) {
            count++;
            //            NSLog(@"%@", obj);
            
            NSString *filePath = [INPUT_FILE_PATH stringByAppendingPathComponent:obj];
            NSURL *urlPath = [NSURL fileURLWithPath:filePath];
            outputSingleFile(urlPath);
        }
    }];
    
    NSLog(@"总共 %d 个文件被修改!", count);
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        // /Users/GM/Linknow_iOS/LinkNow/Classes
        // /Users/GM/Desktop/test/test.txt
#if DEBUG
        NSString *filePath = INPUT_FILE_PATH;
        //        NSString *filePath = getUserInputPath();
#else
        NSString *filePath = getUserInputPath();
        
#endif
        
        BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir];
        NSURL *filePathURL = [NSURL fileURLWithPath:filePath];
        // 文件不存在就退出
        if (!fileExist)return RETURN_CODE_FILE_NOT_EXIST;
        NSLog(@"输入的地址是否为目录 : %d", isDir);
        if (isDir) {
            outputDirOCString(filePathURL);
        } else {
            BOOL isOutputSuccess = outputSingleFile(filePathURL);
            NSLog(@"%d", isOutputSuccess);
        }
    }
    
    return 0;
}

