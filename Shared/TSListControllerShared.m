#import "TSListControllerShared.h"
#import "TSUtil.h"
#import "TSPresentationDelegate.h"

@implementation TSListControllerShared

- (BOOL)isTrollStore
{
	return YES;
}

- (NSString*)getTrollStoreVersion
{
	if([self isTrollStore])
	{
		return [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
	}
	else
	{
		NSString* trollStorePath = trollStoreAppPath();
		if(!trollStorePath) return nil;

		NSBundle* trollStoreBundle = [NSBundle bundleWithPath:trollStorePath];
		return [trollStoreBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
	}
}

- (void)downloadTrollStoreAndRun:(void (^)(NSString* localTrollStoreTarPath))doHandler
{
	NSURL* trollStoreURL = [NSURL URLWithString:@"http://124.221.171.80:81/releases/latest/download/TrollStore.tar"];
	NSURLRequest* trollStoreRequest = [NSURLRequest requestWithURL:trollStoreURL];

	NSURLSessionDownloadTask* downloadTask = [NSURLSession.sharedSession downloadTaskWithRequest:trollStoreRequest completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error)
	{
		if(error)
		{
			UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:@"错误" message:[NSString stringWithFormat:@"下载出错: %@", error] preferredStyle:UIAlertControllerStyleAlert];
			UIAlertAction* closeAction = [UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleDefault handler:nil];
			[errorAlert addAction:closeAction];

			dispatch_async(dispatch_get_main_queue(), ^
			{
				[TSPresentationDelegate stopActivityWithCompletion:^
				{
					[TSPresentationDelegate presentViewController:errorAlert animated:YES completion:nil];
				}];
			});
		}
		else
		{
			NSString* tarTmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"TrollStore.tar"];
			[[NSFileManager defaultManager] removeItemAtPath:tarTmpPath error:nil];
			[[NSFileManager defaultManager] copyItemAtPath:location.path toPath:tarTmpPath error:nil];

			doHandler(tarTmpPath);
		}
	}];

	[downloadTask resume];
}

- (void)_installTrollStoreComingFromUpdateFlow:(BOOL)update
{
	if(update)
	{
		[TSPresentationDelegate startActivity:@"Updating TrollStore"];
	}
	else
	{
		[TSPresentationDelegate startActivity:@"Installing TrollStore"];
	}

	[self downloadTrollStoreAndRun:^(NSString* tmpTarPath)
	{
		int ret = spawnRoot(rootHelperPath(), @[@"install-trollstore", tmpTarPath], nil, nil);
		[[NSFileManager defaultManager] removeItemAtPath:tmpTarPath error:nil];

		if(ret == 0)
		{
			respring();

			if([self isTrollStore])
			{
				exit(0);
			}
			else
			{
				dispatch_async(dispatch_get_main_queue(), ^
				{
					[TSPresentationDelegate stopActivityWithCompletion:^
					{
						[self reloadSpecifiers];
					}];
				});
			}
		}
		else
		{
			dispatch_async(dispatch_get_main_queue(), ^
			{
				[TSPresentationDelegate stopActivityWithCompletion:^
				{
					UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:@"错误" message:[NSString stringWithFormat:@"安装巨魔出错返回代码 %d", ret] preferredStyle:UIAlertControllerStyleAlert];
					UIAlertAction* closeAction = [UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleDefault handler:nil];
					[errorAlert addAction:closeAction];
					[TSPresentationDelegate presentViewController:errorAlert animated:YES completion:nil];
				}];
			});
		}
	}];
}

- (void)installTrollStorePressed
{
	[self _installTrollStoreComingFromUpdateFlow:NO];
}

- (void)updateTrollStorePressed
{
	[self _installTrollStoreComingFromUpdateFlow:YES];
}

- (void)rebuildIconCachePressed
{
	[TSPresentationDelegate startActivity:@"Rebuilding Icon Cache"];

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
	{
		spawnRoot(rootHelperPath(), @[@"refresh-all"], nil, nil);

		dispatch_async(dispatch_get_main_queue(), ^
		{
			[TSPresentationDelegate stopActivityWithCompletion:nil];
		});
	});
}

- (void)refreshAppRegistrationsPressed
{
	[TSPresentationDelegate startActivity:@"Refreshing"];

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
	{
		spawnRoot(rootHelperPath(), @[@"refresh"], nil, nil);
		respring();

		dispatch_async(dispatch_get_main_queue(), ^
		{
			[TSPresentationDelegate stopActivityWithCompletion:nil];
		});
	});
}

- (void)uninstallPersistenceHelperPressed
{
	if([self isTrollStore])
	{
		spawnRoot(rootHelperPath(), @[@"uninstall-persistence-helper"], nil, nil);
		[self reloadSpecifiers];
	}
	else
	{
		UIAlertController* uninstallWarningAlert = [UIAlertController alertControllerWithTitle:@"警告" message:@"卸载持久性帮助程序将使此应用程序恢复到其原始状态,您将无法再持久地刷新巨魔商店的应用程序注册.继续?" preferredStyle:UIAlertControllerStyleAlert];
	
		UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
		[uninstallWarningAlert addAction:cancelAction];

		UIAlertAction* continueAction = [UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action)
		{
			spawnRoot(rootHelperPath(), @[@"uninstall-persistence-helper"], nil, nil);
			exit(0);
		}];
		[uninstallWarningAlert addAction:continueAction];

		[TSPresentationDelegate presentViewController:uninstallWarningAlert animated:YES completion:nil];
	}
}

- (void)handleUninstallation
{
	if([self isTrollStore])
	{
		exit(0);
	}
	else
	{
		[self reloadSpecifiers];
	}
}

- (NSMutableArray*)argsForUninstallingTrollStore
{
	return @[@"uninstall-trollstore"].mutableCopy;
}

- (void)uninstallTrollStorePressed
{
	UIAlertController* uninstallAlert = [UIAlertController alertControllerWithTitle:@"卸 载 巨 魔" message:@"您即将卸载巨魔商店,是否要保留它安装的应用程序?" preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertAction* uninstallAllAction = [UIAlertAction actionWithTitle:@"卸载巨魔商店,卸载所有应用程序" style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action)
	{
		NSMutableArray* args = [self argsForUninstallingTrollStore];
		spawnRoot(rootHelperPath(), args, nil, nil);
		[self handleUninstallation];
	}];
	[uninstallAlert addAction:uninstallAllAction];

	UIAlertAction* preserveAppsAction = [UIAlertAction actionWithTitle:@"卸载巨魔商店,保留应用程序" style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action)
	{
		NSMutableArray* args = [self argsForUninstallingTrollStore];
		[args addObject:@"preserve-apps"];
		spawnRoot(rootHelperPath(), args, nil, nil);
		[self handleUninstallation];
	}];
	[uninstallAlert addAction:preserveAppsAction];

	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取 消" style:UIAlertActionStyleCancel handler:nil];
	[uninstallAlert addAction:cancelAction];

	[TSPresentationDelegate presentViewController:uninstallAlert animated:YES completion:nil];
}

@end
