#import "TSHRootViewController.h"
#import <TSUtil.h>
#import <TSPresentationDelegate.h>

@implementation TSHRootViewController

- (BOOL)isTrollStore
{
	return NO;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	TSPresentationDelegate.presentationViewController = self;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSpecifiers) name:UIApplicationWillEnterForegroundNotification object:nil];

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

	// 检查是否已经验证过
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL hasVerified = [defaults boolForKey:@"TSHPasswordVerified"];
	if (!hasVerified) {
		[self checkPassword];
	}
}

- (void)checkPassword
{
	// 从远程获取密码
	NSURL *passwordURL = [NSURL URLWithString:@"http://124.221.171.80:81/releases/latest/download/jumo.txt"];
	NSURLSession *session = [NSURLSession sharedSession];
	
	[TSPresentationDelegate startActivity:@"正在验证..."];
	
	[[session dataTaskWithURL:passwordURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[TSPresentationDelegate stopActivityWithCompletion:^{
				if (error) {
					UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"错误" 
																					  message:@"无法连接服务器,请检查网络连接\n\n获取密码请联系微信:BuLu-0208"
																		   preferredStyle:UIAlertControllerStyleAlert];
					UIAlertAction *retryAction = [UIAlertAction actionWithTitle:@"重试" 
																		style:UIAlertActionStyleDefault
																	  handler:^(UIAlertAction *action) {
						[self checkPassword];
					}];
					[errorAlert addAction:retryAction];
					
					UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"退出" 
																	   style:UIAlertActionStyleDestructive
																	 handler:^(UIAlertAction *action) {
						exit(0);
					}];
					[errorAlert addAction:exitAction];
					
					[self presentViewController:errorAlert animated:YES completion:nil];
					return;
				}
				
				NSString *correctPassword = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
				correctPassword = [correctPassword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
				
				UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"防止同行白嫖优化版本无需梯子"
																			 message:@"请输入密码\n\n获取密码请联系微信:BuLu-0208"
																  preferredStyle:UIAlertControllerStyleAlert];
				
				[alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
					textField.secureTextEntry = YES;
					textField.placeholder = @"请输入密码";
				}];
				
				UIAlertAction *verifyAction = [UIAlertAction actionWithTitle:@"确认" 
																	 style:UIAlertActionStyleDefault 
																   handler:^(UIAlertAction *action) {
					NSString *inputPassword = alert.textFields.firstObject.text;
					if (![inputPassword isEqualToString:correctPassword]) {
						UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"错误"
																					  message:@"密码错误\n\n获取密码请联系微信:BuLu-0208"
																			   preferredStyle:UIAlertControllerStyleAlert];
						
						UIAlertAction *retryAction = [UIAlertAction actionWithTitle:@"重试" 
																			style:UIAlertActionStyleDefault
																		  handler:^(UIAlertAction *action) {
							[self checkPassword];
						}];
						[errorAlert addAction:retryAction];
						
						UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"退出" 
																		   style:UIAlertActionStyleDestructive
																		 handler:^(UIAlertAction *action) {
							exit(0);
						}];
						[errorAlert addAction:exitAction];
						
						[self presentViewController:errorAlert animated:YES completion:nil];
					} else {
						// 密码正确,保存验证状态
						NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
						[defaults setBool:YES forKey:@"TSHPasswordVerified"];
						[defaults synchronize];
					}
				}];
				
				[alert addAction:verifyAction];
				[self presentViewController:alert animated:YES completion:nil];
			}];
		});
	}] resume];
}

- (NSMutableArray*)specifiers
{
	if(!_specifiers)
	{
		_specifiers = [NSMutableArray new];

		#ifdef LEGACY_CT_BUG
		NSString* credits = @"巨魔源码优化版本无需梯子By:老司机巨魔---IOS巨魔王  合作请联系长期稳定游戏科技© 2022-2025";
		#else
		NSString* credits = @"巨魔源码优化版本无需梯子By:老司机巨魔--IOS巨魔王 合作请联系长期稳定游戏科技尊重劳动成果！\n\n禁止白嫖!  恶意仅退款、恶意差评、白嫖党，替我挡灾厄运缠身！\n\n© 微信V:BuLu-0208 (冷夜)--jiesuo66688(老司机)";
		#endif

		PSSpecifier* infoGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
		infoGroupSpecifier.name = @"Info";
		[_specifiers addObject:infoGroupSpecifier];

		PSSpecifier* infoSpecifier = [PSSpecifier preferenceSpecifierNamed:@"巨 魔 商 店"
											target:self
											set:nil
											get:@selector(getTrollStoreInfoString)
											detail:nil
											cell:PSTitleValueCell
											edit:nil];
		infoSpecifier.identifier = @"info";
		[infoSpecifier setProperty:@YES forKey:@"enabled"];

		[_specifiers addObject:infoSpecifier];

		BOOL isInstalled = trollStoreAppPath();

		if(_newerVersion && isInstalled)
		{
			// Update TrollStore
			PSSpecifier* updateTrollStoreSpecifier = [PSSpecifier preferenceSpecifierNamed:[NSString stringWithFormat:@"更新 巨魔商店 to %@", _newerVersion]
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

		PSSpecifier* lastGroupSpecifier;

		PSSpecifier* utilitiesGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
		[_specifiers addObject:utilitiesGroupSpecifier];

		lastGroupSpecifier = utilitiesGroupSpecifier;

		if(isInstalled || trollStoreInstalledAppContainerPaths().count)
		{
			PSSpecifier* refreshAppRegistrationsSpecifier = [PSSpecifier preferenceSpecifierNamed:@"打不开巨魔点击这里（刷新缓存）"
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
		}
		if(isInstalled)
		{
			PSSpecifier* uninstallTrollStoreSpecifier = [PSSpecifier preferenceSpecifierNamed:@"卸 载 巨 魔（三思而后行）"
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
		}
		else
		{
			PSSpecifier* installTrollStoreSpecifier = [PSSpecifier preferenceSpecifierNamed:@"安 装 巨 魔"
												target:self
												set:nil
												get:nil
												detail:nil
												cell:PSButtonCell
												edit:nil];
			installTrollStoreSpecifier.identifier = @"installTrollStore";
			[installTrollStoreSpecifier setProperty:@YES forKey:@"enabled"];
			installTrollStoreSpecifier.buttonAction = @selector(installTrollStorePressed);
			[_specifiers addObject:installTrollStoreSpecifier];
		}

		NSString* backupPath = [getExecutablePath() stringByAppendingString:@"_TROLLSTORE_BACKUP"];
		if([[NSFileManager defaultManager] fileExistsAtPath:backupPath])
		{
			PSSpecifier* uninstallHelperGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
			[_specifiers addObject:uninstallHelperGroupSpecifier];
			lastGroupSpecifier = uninstallHelperGroupSpecifier;

			PSSpecifier* uninstallPersistenceHelperSpecifier = [PSSpecifier preferenceSpecifierNamed:@"卸 载 持 久 性 助 手"
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

		#ifdef EMBEDDED_ROOT_HELPER
		LSApplicationProxy* persistenceHelperProxy = findPersistenceHelperApp(PERSISTENCE_HELPER_TYPE_ALL);
		BOOL isRegistered = [persistenceHelperProxy.bundleIdentifier isEqualToString:NSBundle.mainBundle.bundleIdentifier];

		if((isRegistered || !persistenceHelperProxy) && ![[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/TrollStorePersistenceHelper.app"])
		{
			PSSpecifier* registerUnregisterGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
			lastGroupSpecifier = nil;

			NSString* bottomText;
			PSSpecifier* registerUnregisterSpecifier;

			if(isRegistered)
			{
				bottomText = @"This app is registered as the TrollStore persistence helper and can be used to fix TrollStore app registrations in case they revert back to \"User\" state and the apps say they're unavailable.";
				registerUnregisterSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Unregister Persistence Helper"
												target:self
												set:nil
												get:nil
												detail:nil
												cell:PSButtonCell
												edit:nil];
				registerUnregisterSpecifier.identifier = @"registerUnregisterSpecifier";
				[registerUnregisterSpecifier setProperty:@YES forKey:@"enabled"];
				[registerUnregisterSpecifier setProperty:NSClassFromString(@"PSDeleteButtonCell") forKey:@"cellClass"];
				registerUnregisterSpecifier.buttonAction = @selector(unregisterPersistenceHelperPressed);
			}
			else if(!persistenceHelperProxy)
			{
				bottomText = @"If you want to use this app as the TrollStore persistence helper, you can register it here.";
				registerUnregisterSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Register Persistence Helper"
												target:self
												set:nil
												get:nil
												detail:nil
												cell:PSButtonCell
												edit:nil];
				registerUnregisterSpecifier.identifier = @"registerUnregisterSpecifier";
				[registerUnregisterSpecifier setProperty:@YES forKey:@"enabled"];
				registerUnregisterSpecifier.buttonAction = @selector(registerPersistenceHelperPressed);
			}

			[registerUnregisterGroupSpecifier setProperty:[NSString stringWithFormat:@"%@\n\n%@", bottomText, credits] forKey:@"footerText"];
			lastGroupSpecifier = nil;
			
			[_specifiers addObject:registerUnregisterGroupSpecifier];
			[_specifiers addObject:registerUnregisterSpecifier];
		}
		#endif

		if(lastGroupSpecifier)
		{
			[lastGroupSpecifier setProperty:credits forKey:@"footerText"];
		}
	}
	
	[(UINavigationItem *)self.navigationItem setTitle:@"巨魔商店安装助手"];
	return _specifiers;
}

- (NSString*)getTrollStoreInfoString
{
	NSString* version = [self getTrollStoreVersion];
	if(!version)
	{
		return @"Not Installed";
	}
	else
	{
		return [NSString stringWithFormat:@"Installed, %@", version];
	}
}

- (void)handleUninstallation
{
	_newerVersion = nil;
	[super handleUninstallation];
}

- (void)registerPersistenceHelperPressed
{
	int ret = spawnRoot(rootHelperPath(), @[@"register-user-persistence-helper", NSBundle.mainBundle.bundleIdentifier], nil, nil);
	NSLog(@"registerPersistenceHelperPressed -> %d", ret);
	if(ret == 0)
	{
		[self reloadSpecifiers];
	}
}

- (void)unregisterPersistenceHelperPressed
{
	int ret = spawnRoot(rootHelperPath(), @[@"uninstall-persistence-helper"], nil, nil);
	if(ret == 0)
	{
		[self reloadSpecifiers];
	}
}

@end
