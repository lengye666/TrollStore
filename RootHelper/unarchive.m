#import "unarchive.h"
#import <Foundation/Foundation.h>

int extract(NSString* fileToExtract, NSString* extractionPath)
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    
    // 创建目标目录
    if (![fileManager createDirectoryAtPath:extractionPath
            withIntermediateDirectories:YES
            attributes:nil
            error:&error]) {
        NSLog(@"Failed to create directory: %@", error);
        return 1;
    }
    
    // 根据文件扩展名选择解压方法
    NSString *extension = [fileToExtract.lowercaseString pathExtension];
    
    if ([extension isEqualToString:@"zip"]) {
        // 使用系统自带的 zip 解压功能
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = @"/usr/bin/unzip";
        task.arguments = @[@"-o", fileToExtract, @"-d", extractionPath];
        
        [task launch];
        [task waitUntilExit];
        
        return task.terminationStatus;
    }
    else if ([extension isEqualToString:@"tar"]) {
        // 使用系统自带的 tar 解压功能
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = @"/usr/bin/tar";
        task.arguments = @[@"-xf", fileToExtract, @"-C", extractionPath];
        
        [task launch];
        [task waitUntilExit];
        
        return task.terminationStatus;
    }
    else {
        NSLog(@"Unsupported archive format: %@", extension);
        return 1;
    }
    
    return 0;
}
