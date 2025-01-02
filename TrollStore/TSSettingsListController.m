#import "TSSettingsListController.h"
#import <TSUtil.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSListItemsController.h>
#import <TSPresentationDelegate.h>
#import "TSInstallationController.h"
#import "TSSettingsAdvancedListController.h"
#import "TSDonateListController.h"
#import "TSCustomConfig.h"

@interface NSUserDefaults (Private)
- (instancetype)_initWithSuiteName:(NSString *)suiteName container:(NSURL *)container;
@end
extern NSUserDefaults* trollStoreUserDefaults(void);

@implementation TSSettingsListController

- (void)viewDidLoad
{
	[super viewDidLoad];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSpecifiers) name:UIApplicationWillEnterForegroundNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSpecifiers) name:@"TrollStoreReloadSettingsNotification" object:nil];

#ifndef TROLLSTORE_LITE
	fetchLatestTrollStoreVersion(^(NSString* latestVersion)
	{
		NSString* currentVersion = [self getTrollStoreVersion];
		NSComparisonResult result = [currentVersion compare:latestVersion options:NSNumericSearch];
		if(result == NSOrderedAscending)
		{
			_newerVersion = latestVersion;
			dispatch_async(dispatch_get_main_queue(), ^
			{
				[self reloadSpecifiers];
			});
		}
	});

	//if (@available(iOS 16, *)) {} else {
		fetchLatestLdidVersion(^(NSString* latestVersion)
		{
			NSString* ldidPath = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"ldid"];
			NSString* ldidVersionPath = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"ldid.version"];
			#pragma unused(ldidPath)

			NSString* ldidVersion = nil;
			NSData* ldidVersionData = [NSData dataWithContentsOfFile:ldidVersionPath];
			if(ldidVersionData)
			{
				ldidVersion = [[NSString alloc] initWithData:ldidVersionData encoding:NSUTF8StringEncoding];
			}
			
			if(![latestVersion isEqualToString:ldidVersion])
			{
				_newerLdidVersion = latestVersion;
				dispatch_async(dispatch_get_main_queue(), ^
				{
					[self reloadSpecifiers];
				});
			}
		});
	//}

	if (@available(iOS 16, *))
	{
		_devModeEnabled = spawnRoot(rootHelperPath(), @[@"check-dev-mode"], nil, nil) == 0;
	}
	else
	{
		_devModeEnabled = YES;
	}
#endif
	[self reloadSpecifiers];
}

- (NSMutableArray*)specifiers
{
	if(!_specifiers)
	{
		_specifiers = [NSMutableArray new];

#ifndef TROLLSTORE_LITE
		if(_newerVersion)
		{
			PSSpecifier* updateTrollStoreGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
			updateTrollStoreGroupSpecifier.name = @"更新可用";
			[_specifiers addObject:updateTrollStoreGroupSpecifier];

			PSSpecifier* updateTrollStoreSpecifier = [PSSpecifier preferenceSpecifierNamed:[NSString stringWithFormat:@"更新到 %@", _newerVersion]
										target:self
										set:nil
										get:nil
										detail:nil
										cell:PSButtonCell
										edit:nil];
			updateTrollStoreSpecifier.identifier = @"updateTrollStore";
			[updateTrollStoreSpecifier setProperty:@YES forKey:@"enabled"];
			updateTrollStoreSpecifier.buttonAction = @selector(updateTrollStorePressed);
			[_specifiers addObject:updateTrollStoreSpecifier];
		}

		if(!_devModeEnabled)
		{
			PSSpecifier* enableDevModeGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
			enableDevModeGroupSpecifier.name = @"开发者模式";
			[enableDevModeGroupSpecifier setProperty:@"一些应用需要开发者模式启用才能启动。启用后需要重启设备才能生效。" forKey:@"footerText"];
			[_specifiers addObject:enableDevModeGroupSpecifier];

			PSSpecifier* enableDevModeSpecifier = [PSSpecifier preferenceSpecifierNamed:@"启用开发者模式"
										target:self
										set:nil
										get:nil
										detail:nil
										cell:PSButtonCell
										edit:nil];
			enableDevModeSpecifier.identifier = @"enableDevMode";
			[enableDevModeSpecifier setProperty:@YES forKey:@"enabled"];
			enableDevModeSpecifier.buttonAction = @selector(enableDevModePressed);
			[_specifiers addObject:enableDevModeSpecifier];
		}
#endif

		PSSpecifier* utilitiesGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
		utilitiesGroupSpecifier.name = @"实用工具";

		NSString *utilitiesDescription = @"";
#ifdef TROLLSTORE_LITE
		if (shouldRegisterAsUserByDefault()) {
			utilitiesDescription = @"应用程序将默认注册为用户。由于 AppSync Unified 已安装。\n\n";
		}
		else {
			utilitiesDescription = @"应用程序将默认注册为系统。由于 AppSync Unified 未安装。当应用程序丢失系统注册并停止工作时，可以使用此处的 \"刷新应用程序注册\" 来修复它们。\n\n";
		}
#endif
		utilitiesDescription = [utilitiesDescription stringByAppendingString:@"如果应用程序在安装后没有立即出现，请在此处重启设备，应用程序将出现。"];

		[utilitiesGroupSpecifier setProperty:utilitiesDescription forKey:@"footerText"];
		[_specifiers addObject:utilitiesGroupSpecifier];

		PSSpecifier* respringButtonSpecifier = [PSSpecifier preferenceSpecifierNamed:@"重启"
											target:self
											set:nil
											get:nil
											detail:nil
											cell:PSButtonCell
											edit:nil];
		 respringButtonSpecifier.identifier = @"respring";
		[respringButtonSpecifier setProperty:@YES forKey:@"enabled"];
		respringButtonSpecifier.buttonAction = @selector(respringButtonPressed);

		[_specifiers addObject:respringButtonSpecifier];

		PSSpecifier* refreshAppRegistrationsSpecifier = [PSSpecifier preferenceSpecifierNamed:@"刷新应用程序注册"
											target:self
											set:nil
											get:nil
											detail:nil
											cell:PSButtonCell
											edit:nil];
		refreshAppRegistrationsSpecifier.identifier = @"refreshAppRegistrations";
		[refreshAppRegistrationsSpecifier setProperty:@YES forKey:@"enabled"];
		refreshAppRegistrationsSpecifier.buttonAction = @selector(refreshAppRegistrationsPressed);

		[_specifiers addObject:refreshAppRegistrationsSpecifier];

		PSSpecifier* rebuildIconCacheSpecifier = [PSSpecifier preferenceSpecifierNamed:@"重建图标缓存"
											target:self
											set:nil
											get:nil
											detail:nil
											cell:PSButtonCell
											edit:nil];
		 rebuildIconCacheSpecifier.identifier = @"uicache";
		[rebuildIconCacheSpecifier setProperty:@YES forKey:@"enabled"];
		rebuildIconCacheSpecifier.buttonAction = @selector(rebuildIconCachePressed);

		[_specifiers addObject:rebuildIconCacheSpecifier];

		NSArray *inactiveBundlePaths = trollStoreInactiveInstalledAppBundlePaths();
		if (inactiveBundlePaths.count > 0) {
			PSSpecifier* transferAppsSpecifier = [PSSpecifier preferenceSpecifierNamed:[NSString stringWithFormat:@"转移 %zu 个应用程序", inactiveBundlePaths.count]
											target:self
											set:nil
											get:nil
											detail:nil
											cell:PSButtonCell
											edit:nil];
			transferAppsSpecifier.identifier = @"transferApps";
			[transferAppsSpecifier setProperty:@YES forKey:@"enabled"];
			transferAppsSpecifier.buttonAction = @selector(transferAppsPressed);

			[_specifiers addObject:transferAppsSpecifier];
		}

#ifndef TROLLSTORE_LITE
		//if (@available(iOS 16, *)) { } else {
			NSString* ldidPath = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"ldid"];
			NSString* ldidVersionPath = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"ldid.version"];

			NSString* ldidVersion = nil;
			NSData* ldidVersionData = [NSData dataWithContentsOfFile:ldidVersionPath];
			if(ldidVersionData)
			{
				ldidVersion = [[NSString alloc] initWithData:ldidVersionData encoding:NSUTF8StringEncoding];
			}

			PSSpecifier* signingGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
			signingGroupSpecifier.name = @"签名";

			if([[NSFileManager defaultManager] fileExistsAtPath:ldidPath])
			{
				[signingGroupSpecifier setProperty:@"ldid 已安装，允许 TrollStore 安装未签名的 IPA 文件。" forKey:@"footerText"];
			}
			else
			{
				[signingGroupSpecifier setProperty:@"为了使 TrollStore 能够安装未签名的 IPA 文件，需要安装 ldid。由于许可问题，无法直接包含在 TrollStore 中。" forKey:@"footerText"];
			}

			[_specifiers addObject:signingGroupSpecifier];

			if([[NSFileManager defaultManager] fileExistsAtPath:ldidPath])
			{
				NSString* installedTitle = @"ldid：已安装";
				if(ldidVersion)
				{
					installedTitle = [NSString stringWithFormat:@"%@ (%@)", installedTitle, ldidVersion];
				}

				PSSpecifier* ldidInstalledSpecifier = [PSSpecifier preferenceSpecifierNamed:installedTitle
												target:self
												set:nil
												get:nil
												detail:nil
												cell:PSStaticTextCell
												edit:nil];
				[ldidInstalledSpecifier setProperty:@NO forKey:@"enabled"];
				ldidInstalledSpecifier.identifier = @"ldidInstalled";
				[_specifiers addObject:ldidInstalledSpecifier];

				if(_newerLdidVersion && ![_newerLdidVersion isEqualToString:ldidVersion])
				{
					NSString* updateTitle = [NSString stringWithFormat:@"更新到 %@", _newerLdidVersion];
					PSSpecifier* ldidUpdateSpecifier = [PSSpecifier preferenceSpecifierNamed:updateTitle
												target:self
												set:nil
												get:nil
												detail:nil
												cell:PSButtonCell
												edit:nil];
					ldidUpdateSpecifier.identifier = @"updateLdid";
					[ldidUpdateSpecifier setProperty:@YES forKey:@"enabled"];
					ldidUpdateSpecifier.buttonAction = @selector(installOrUpdateLdidPressed);
					[_specifiers addObject:ldidUpdateSpecifier];
				}
			}
			else
			{
				PSSpecifier* installLdidSpecifier = [PSSpecifier preferenceSpecifierNamed:@"安装 ldid"
												target:self
												set:nil
												get:nil
												detail:nil
												cell:PSButtonCell
												edit:nil];
				installLdidSpecifier.identifier = @"installLdid";
				[installLdidSpecifier setProperty:@YES forKey:@"enabled"];
				installLdidSpecifier.buttonAction = @selector(installOrUpdateLdidPressed);
				[_specifiers addObject:installLdidSpecifier];
			}
		//}

		PSSpecifier* persistenceGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
		persistenceGroupSpecifier.name = @"持久化";
		[_specifiers addObject:persistenceGroupSpecifier];

		if([[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/TrollStorePersistenceHelper.app"])
		{
			[persistenceGroupSpecifier setProperty:@"当 iOS 重建图标缓存时，所有 TrollStore 应用程序（包括 TrollStore 本身）将被重置为 \"用户\" 状态，并且可能会消失或无法启动。如果发生这种情况，可以使用此处的 \"刷新应用程序注册\" 来修复它们。" forKey:@"footerText"];
			PSSpecifier* installedPersistenceHelperSpecifier = [PSSpecifier preferenceSpecifierNamed:@"辅助工具已安装为独立应用程序"
											target:self
											set:nil
											get:nil
											detail:nil
											cell:PSStaticTextCell
											edit:nil];
			[installedPersistenceHelperSpecifier setProperty:@NO forKey:@"enabled"];
			installedPersistenceHelperSpecifier.identifier = @"persistenceHelperInstalled";
			[_specifiers addObject:installedPersistenceHelperSpecifier];
		}
		else
		{
			LSApplicationProxy* persistenceApp = findPersistenceHelperApp(PERSISTENCE_HELPER_TYPE_ALL);
			if(persistenceApp)
			{
				NSString* appName = [persistenceApp localizedName];

				[persistenceGroupSpecifier setProperty:[NSString stringWithFormat:@"当 iOS 重建图标缓存时，所有 TrollStore 应用程序（包括 TrollStore 本身）将被重置为 \"用户\" 状态，并且可能会消失或无法启动。如果发生这种情况，可以使用安装在 %@ 中的持久化辅助工具来刷新应用程序注册，从而使它们再次可用。", appName] forKey:@"footerText"];
				PSSpecifier* installedPersistenceHelperSpecifier = [PSSpecifier preferenceSpecifierNamed:[NSString stringWithFormat:@"辅助工具已安装到 %@", appName]
												target:self
												set:nil
												get:nil
												detail:nil
												cell:PSStaticTextCell
												edit:nil];
				[installedPersistenceHelperSpecifier setProperty:@NO forKey:@"enabled"];
				installedPersistenceHelperSpecifier.identifier = @"persistenceHelperInstalled";
				[_specifiers addObject:installedPersistenceHelperSpecifier];

				PSSpecifier* uninstallPersistenceHelperSpecifier = [PSSpecifier preferenceSpecifierNamed:@"卸载持久化辅助工具"
												target:self
												set:nil
												get:nil
												detail:nil
												cell:PSButtonCell
												edit:nil];

				uninstallPersistenceHelperSpecifier.identifier = @"uninstallPersistenceHelper";
				[uninstallPersistenceHelperSpecifier setProperty:@YES forKey:@"enabled"];
				[uninstallPersistenceHelperSpecifier setProperty:NSClassFromString(@"PSDeleteButtonCell") forKey:@"cellClass"];
				uninstallPersistenceHelperSpecifier.buttonAction = @selector(uninstallPersistenceHelperPressed);
				[_specifiers addObject:uninstallPersistenceHelperSpecifier];
			}
			else
			{
				[persistenceGroupSpecifier setProperty:@"当 iOS 重建图标缓存时，所有 TrollStore 应用程序（包括 TrollStore 本身）将被重置为 \"用户\" 状态，并且可能会消失或无法启动。唯一的方法是在无 root 环境中实现持久化，即替换系统应用程序。这里可以选择一个系统应用程序来替换为持久化辅助工具，以便在应用程序消失或无法启动时刷新注册。" forKey:@"footerText"];

				_installPersistenceHelperSpecifier = [PSSpecifier preferenceSpecifierNamed:@"安装持久化辅助工具"
												target:self
												set:nil
												get:nil
												detail:nil
												cell:PSButtonCell
												edit:nil];
				_installPersistenceHelperSpecifier.identifier = @"installPersistenceHelper";
				[_installPersistenceHelperSpecifier setProperty:@YES forKey:@"enabled"];
				_installPersistenceHelperSpecifier.buttonAction = @selector(installPersistenceHelperPressed);
				[_specifiers addObject:_installPersistenceHelperSpecifier];
			}
		}
#endif

		PSSpecifier* installationSettingsGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
		installationSettingsGroupSpecifier.name = @"安全";
		[installationSettingsGroupSpecifier setProperty:@"URL 方案，当启用时，允许应用程序和网站通过 apple-magnifier://install?url=<IPA_URL> URL 方案触发 TrollStore 安装，并通过 apple-magnifier://enable-jit?bundle-id=<BUNDLE_ID> URL 方案启用 JIT。" forKey:@"footerText"];

		[_specifiers addObject:installationSettingsGroupSpecifier];

		PSSpecifier* URLSchemeToggle = [PSSpecifier preferenceSpecifierNamed:@"URL 方案启用"
										target:self
										set:@selector(setURLSchemeEnabled:forSpecifier:)
										get:@selector(getURLSchemeEnabledForSpecifier:)
										detail:nil
										cell:PSSwitchCell
										edit:nil];

		[_specifiers addObject:URLSchemeToggle];

		PSSpecifier* installAlertConfigurationSpecifier = [PSSpecifier preferenceSpecifierNamed:@"显示安装确认提示"
										target:self
										set:@selector(setPreferenceValue:specifier:)
										get:@selector(readPreferenceValue:)
										detail:nil
										cell:PSLinkListCell
										edit:nil];

		installAlertConfigurationSpecifier.detailControllerClass = [PSListItemsController class];
		[installAlertConfigurationSpecifier setProperty:@"installationConfirmationValues" forKey:@"valuesDataSource"];
        [installAlertConfigurationSpecifier setProperty:@"installationConfirmationNames" forKey:@"titlesDataSource"];
		[installAlertConfigurationSpecifier setProperty:APP_ID forKey:@"defaults"];
		[installAlertConfigurationSpecifier setProperty:@"installAlertConfiguration" forKey:@"key"];
        [installAlertConfigurationSpecifier setProperty:@0 forKey:@"default"];

		[_specifiers addObject:installAlertConfigurationSpecifier];

		PSSpecifier* otherGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
		[otherGroupSpecifier setProperty:[NSString stringWithFormat:@"%@ %@\n\n 2022-2024 Lars Fröder (opa334)\n\nTrollStore 不是用于盗版！\n\n鸣谢:\nGoogle TAG, @alfiecg_dev: CoreTrust bug\n@lunotech11, @SerenaKit, @tylinux, @TheRealClarity, @dhinakg, @khanhduytran0: 各种贡献\n@ProcursusTeam: uicache, ldid\n@cstar_ow: uicache\n@saurik: ldid", APP_NAME, [self getTrollStoreVersion]] forKey:@"footerText"];
		[_specifiers addObject:otherGroupSpecifier];

		PSSpecifier* advancedLinkSpecifier = [PSSpecifier preferenceSpecifierNamed:@"高级"
										target:self
										set:nil
										get:nil
										detail:nil
										cell:PSLinkListCell
										edit:nil];
		advancedLinkSpecifier.detailControllerClass = [TSSettingsAdvancedListController class];
		[advancedLinkSpecifier setProperty:@YES forKey:@"enabled"];
		[_specifiers addObject:advancedLinkSpecifier];

		PSSpecifier* donateSpecifier = [PSSpecifier preferenceSpecifierNamed:@"捐赠"
										target:self
										set:nil
										get:nil
										detail:nil
										cell:PSLinkListCell
										edit:nil];
		donateSpecifier.detailControllerClass = [TSDonateListController class];
		[donateSpecifier setProperty:@YES forKey:@"enabled"];
		[_specifiers addObject:donateSpecifier];

#ifndef TROLLSTORE_LITE
		// 卸载 TrollStore
		PSSpecifier* uninstallTrollStoreSpecifier = [PSSpecifier preferenceSpecifierNamed:@"卸载 TrollStore"
										target:self
										set:nil
										get:nil
										detail:nil
										cell:PSButtonCell
										edit:nil];
		uninstallTrollStoreSpecifier.identifier = @"uninstallTrollStore";
		[uninstallTrollStoreSpecifier setProperty:@YES forKey:@"enabled"];
		[uninstallTrollStoreSpecifier setProperty:NSClassFromString(@"PSDeleteButtonCell") forKey:@"cellClass"];
		uninstallTrollStoreSpecifier.buttonAction = @selector(uninstallTrollStorePressed);
		[_specifiers addObject:uninstallTrollStoreSpecifier];
#endif
		/*PSSpecifier* doTheDashSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Do the Dash"
										target:self
										set:nil
										get:nil
										detail:nil
										cell:PSButtonCell
										edit:nil];
		doTheDashSpecifier.identifier = @"doTheDash";
		[doTheDashSpecifier setProperty:@YES forKey:@"enabled"];
		uninstallTrollStoreSpecifier.buttonAction = @selector(doTheDashPressed);
		[_specifiers addObject:doTheDashSpecifier];*/
	}

	[(UINavigationItem *)self.navigationItem setTitle:@"设置"];
	return _specifiers;
}

- (NSArray*)installationConfirmationValues
{
	return @[@0, @1, @2];
}

- (NSArray*)installationConfirmationNames
{
	return @[@"始终（推荐）", @"仅在远程 URL 安装时", @"从不（不推荐）"];
}

- (void)respringButtonPressed
{
	respring();
}

- (void)installOrUpdateLdidPressed
{
	[TSInstallationController installLdid];
}

- (void)enableDevModePressed
{
	int ret = spawnRoot(rootHelperPath(), @[@"arm-dev-mode"], nil, nil);

	if (ret == 0) {
		UIAlertController* rebootNotification = [UIAlertController alertControllerWithTitle:@"重启设备"
			message:@"重启后，请选择 \"启用\" 来启用开发者模式。"
			preferredStyle:UIAlertControllerStyleAlert
		];
		UIAlertAction* closeAction = [UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleCancel handler:^(UIAlertAction* action)
		{
			[self reloadSpecifiers];
		}];
		[rebootNotification addAction:closeAction];

		UIAlertAction* rebootAction = [UIAlertAction actionWithTitle:@"立即重启" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
		{
			spawnRoot(rootHelperPath(), @[@"reboot"], nil, nil);
		}];
		[rebootNotification addAction:rebootAction];

		[TSPresentationDelegate presentViewController:rebootNotification animated:YES completion:nil];
	} else {
		UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"错误 %d", ret] message:@"启用开发者模式失败。" preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction* closeAction = [UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleDefault handler:nil];
		[errorAlert addAction:closeAction];

		[TSPresentationDelegate presentViewController:errorAlert animated:YES completion:nil];
	}
}

- (void)installPersistenceHelperPressed
{
    // 获取可用的系统应用列表
    NSMutableArray* appCandidates = [NSMutableArray new];
    [[LSApplicationWorkspace defaultWorkspace] enumerateApplicationsOfType:0 block:^(LSApplicationProxy* appProxy)
    {
        if(![appProxy.bundleType isEqualToString:@"System"]) return;
        if(appProxy.installed)
        {
            [appCandidates addObject:appProxy];
        }
    }];

    // 按名称排序
    [appCandidates sortUsingComparator:^NSComparisonResult(LSApplicationProxy* a, LSApplicationProxy* b) {
        return [a.localizedName compare:b.localizedName];
    }];

    // 创建选择应用的提示
    UIAlertController* selectAppAlert = [UIAlertController alertControllerWithTitle:@"选择应用程序" 
        message:@"选择一个系统应用程序来安装MyStore持久化助手。该应用程序的原始功能将被替换，建议选择一个不常用的应用程序。\n\n注意：\n1. 安装后会自动备份原始应用\n2. 可以随时卸载恢复原始应用\n3. 建议选择提示或指南类应用" 
        preferredStyle:UIAlertControllerStyleActionSheet];

    // 添加应用选项
    for(LSApplicationProxy* appProxy in appCandidates)
    {
        UIAlertAction* installAction = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%@ (%@)", 
            [appProxy localizedName], appProxy.bundleIdentifier] 
            style:UIAlertActionStyleDefault 
            handler:^(UIAlertAction* action)
        {
            // 显示确认对话框
            UIAlertController* confirmAlert = [UIAlertController alertControllerWithTitle:@"确认安装" 
                message:[NSString stringWithFormat:@"您确定要将持久化助手安装到 %@ 吗？\n\n此操作将：\n1. 备份原始应用\n2. 安装持久化助手\n3. 保存配置信息", [appProxy localizedName]] 
                preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" 
                style:UIAlertActionStyleCancel 
                handler:nil];
            [confirmAlert addAction:cancelAction];

            UIAlertAction* confirmAction = [UIAlertAction actionWithTitle:@"确定" 
                style:UIAlertActionStyleDestructive 
                handler:^(UIAlertAction* action)
            {
                // 开始安装
                [TSPresentationDelegate startActivity:@"正在安装持久化助手..."];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                {
                    NSString* appId = appProxy.bundleIdentifier;
                    spawnRoot(rootHelperPath(), @[@"install-persistence-helper", appId], nil, nil);
                    dispatch_async(dispatch_get_main_queue(), ^
                    {
                        [self dismissViewControllerAnimated:YES completion:nil];
                        [self reloadSpecifiers];
                        
                        // 显示安装完成提示
                        UIAlertController* doneAlert = [UIAlertController alertControllerWithTitle:@"安装完成" 
                            message:@"持久化助手已安装成功。您可以在设置中查看和管理持久化助手的配置。" 
                            preferredStyle:UIAlertControllerStyleAlert];
                        
                        UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"确定" 
                            style:UIAlertActionStyleDefault 
                            handler:nil];
                        [doneAlert addAction:okAction];
                        
                        [TSPresentationDelegate presentViewController:doneAlert animated:YES completion:nil];
                    });
                });
            }];
            [confirmAlert addAction:confirmAction];

            [TSPresentationDelegate presentViewController:confirmAlert animated:YES completion:nil];
        }];
        [selectAppAlert addAction:installAction];
    }

    // 添加取消按钮
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" 
        style:UIAlertActionStyleCancel 
        handler:nil];
    [selectAppAlert addAction:cancelAction];

    // 显示选择对话框
    selectAppAlert.popoverPresentationController.sourceView = self.view;
    [TSPresentationDelegate presentViewController:selectAppAlert animated:YES completion:nil];
}

- (void)transferAppsPressed
{
	UIAlertController *confirmationAlert = [UIAlertController alertControllerWithTitle:@"转移应用程序" message:[NSString stringWithFormat:@"此选项将转移 %zu 个应用程序从 "OTHER_APP_NAME@" 到 "APP_NAME@". 继续吗？", trollStoreInactiveInstalledAppBundlePaths().count] preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertAction* transferAction = [UIAlertAction actionWithTitle:@"转移" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
	{
		[TSPresentationDelegate startActivity:@"转移中"];
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
		{
			NSString *log;
			int transferRet = spawnRoot(rootHelperPath(), @[@"transfer-apps"], nil, &log);

			dispatch_async(dispatch_get_main_queue(), ^
			{
				[TSPresentationDelegate stopActivityWithCompletion:^{
					[self reloadSpecifiers];

					if (transferRet != 0) {
						NSArray *remainingApps = trollStoreInactiveInstalledAppBundlePaths();
						UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"转移失败" message:[NSString stringWithFormat:@"无法转移 %zu 个应用程序", remainingApps.count] preferredStyle:UIAlertControllerStyleAlert];

						UIAlertAction* copyLogAction = [UIAlertAction actionWithTitle:@"复制调试日志" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
						{
							UIPasteboard* pasteboard = [UIPasteboard generalPasteboard];
							pasteboard.string = log;
						}];
						[errorAlert addAction:copyLogAction];

						UIAlertAction* closeAction = [UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleDefault handler:nil];
						[errorAlert addAction:closeAction];

						[TSPresentationDelegate presentViewController:errorAlert animated:YES completion:nil];
					}
				}];
			});
		});
	}];
	[confirmationAlert addAction:transferAction];

	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
	[confirmationAlert addAction:cancelAction];

	[TSPresentationDelegate presentViewController:confirmationAlert animated:YES completion:nil];
}

- (id)getURLSchemeEnabledForSpecifier:(PSSpecifier*)specifier
{
	BOOL URLSchemeActive = (BOOL)[NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleURLTypes"];
	return @(URLSchemeActive);
}

- (void)setURLSchemeEnabled:(id)value forSpecifier:(PSSpecifier*)specifier
{
	NSNumber* newValue = value;
	NSString* newStateString = [newValue boolValue] ? @"enable" : @"disable";
	spawnRoot(rootHelperPath(), @[@"url-scheme", newStateString], nil, nil);

	UIAlertController* rebuildNoticeAlert = [UIAlertController alertControllerWithTitle:@"URL 方案已更改" message:@"为了正确应用 URL 方案设置的更改，需要重建图标缓存。" preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction* rebuildNowAction = [UIAlertAction actionWithTitle:@"立即重建" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
	{
		[self rebuildIconCachePressed];
	}];
	[rebuildNoticeAlert addAction:rebuildNowAction];

	UIAlertAction* rebuildLaterAction = [UIAlertAction actionWithTitle:@"稍后重建" style:UIAlertActionStyleCancel handler:nil];
	[rebuildNoticeAlert addAction:rebuildLaterAction];

	[TSPresentationDelegate presentViewController:rebuildNoticeAlert animated:YES completion:nil];
}

- (void)doTheDashPressed
{
	spawnRoot(rootHelperPath(), @[@"dash"], nil, nil);
}

- (void)setPreferenceValue:(NSObject*)value specifier:(PSSpecifier*)specifier
{
	NSUserDefaults* tsDefaults = trollStoreUserDefaults();
	[tsDefaults setObject:value forKey:[specifier propertyForKey:@"key"]];
}

- (NSObject*)readPreferenceValue:(PSSpecifier*)specifier
{
	NSUserDefaults* tsDefaults = trollStoreUserDefaults();
	NSObject* toReturn = [tsDefaults objectForKey:[specifier propertyForKey:@"key"]];
	if(!toReturn)
	{
		toReturn = [specifier propertyForKey:@"default"];
	}
	return toReturn;
}

- (NSMutableArray*)argsForUninstallingTrollStore
{
	NSMutableArray* args = @[@"uninstall-trollstore"].mutableCopy;

	NSNumber* uninstallationMethodToUseNum = [trollStoreUserDefaults() objectForKey:@"uninstallationMethod"];
    int uninstallationMethodToUse = uninstallationMethodToUseNum ? uninstallationMethodToUseNum.intValue : 0;
    if(uninstallationMethodToUse == 1)
    {
        [args addObject:@"custom"];
    }

	return args;
}

@end
