#import "unarchive.h"
#import <spawn.h>
#import <sys/wait.h>

static int run_command(const char* command, NSArray* args, NSString* workingDir) {
    NSMutableArray* fullArgs = [NSMutableArray arrayWithObject:[NSString stringWithUTF8String:command]];
    [fullArgs addObjectsFromArray:args];
    
    const char** argv = (const char**)malloc(sizeof(char*) * (fullArgs.count + 1));
    for (NSUInteger i = 0; i < fullArgs.count; i++) {
        argv[i] = [fullArgs[i] UTF8String];
    }
    argv[fullArgs.count] = NULL;
    
    pid_t pid;
    int status;
    posix_spawn_file_actions_t actions;
    posix_spawn_file_actions_init(&actions);
    
    if (workingDir) {
        posix_spawn_file_actions_addchdir(&actions, workingDir.UTF8String);
    }
    
    status = posix_spawn(&pid, command, &actions, NULL, (char* const*)argv, NULL);
    free(argv);
    
    if (status == 0) {
        if (waitpid(pid, &status, 0) != -1) {
            return WEXITSTATUS(status);
        }
    }
    return -1;
}

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
        return run_command("/usr/bin/unzip",
                         @[@"-o", fileToExtract, @"-d", extractionPath],
                         nil);
    }
    else if ([extension isEqualToString:@"tar"]) {
        // 使用系统自带的 tar 解压功能
        return run_command("/usr/bin/tar",
                         @[@"-xf", fileToExtract, @"-C", extractionPath],
                         nil);
    }
    else {
        NSLog(@"Unsupported archive format: %@", extension);
        return 1;
    }
    
    return 0;
}
