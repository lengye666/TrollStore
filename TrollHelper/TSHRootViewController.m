#import "TSHRootViewController.h"  // 导入根视图控制器头文件
#import <TSUtil.h>  // 导入TrollStore工具类
#import <TSPresentationDelegate.h>  // 导入演示代理类

@implementation TSHRootViewController

// 判断是否为TrollStore的方法
- (BOOL)isTrollStore
{
	return NO;  // 返回NO表示不是TrollStore
}

// 视图加载完成时调用的方法
- (void)viewDidLoad
{
	[super viewDidLoad];  // 调用父类的viewDidLoad方法
	TSPresentationDelegate.presentationViewController = self;  // 设置演示代理的视图控制器为当前控制器

	// 添加应用进入前台时的通知监听，用于重新加载配置
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSpecifiers) name:UIApplicationWillEnterForegroundNotification object:nil];

	// 获取最新的TrollStore版本
	fetchLatestTrollStoreVersion(^(NSString* latestVersion)
	{
		NSString* currentVersion = [self getTrollStoreVersion];  // 获取当前TrollStore版本
		NSComparisonResult result = [currentVersion compare:latestVersion options:NSNumericSearch];  // 比较版本号
		if(result == NSOrderedAscending)  // 如果当前版本较旧
		{
			_newerVersion = latestVersion;  // 保存新版本号
			dispatch_async(dispatch_get_main_queue(), ^  // 在主线程中执行
			{
				[self reloadSpecifiers];  // 重新加载配置
			});
		}
	});

	// 检查是否已经验证过
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];  // 获取用户默认设置
	BOOL hasVerified = [defaults boolForKey:@"TSHPasswordVerified"];  // 读取验证状态
	if (!hasVerified) {  // 如果未验证
		[self checkPassword];  // 执行卡密验证
	}
}

// 卡密验证方法
- (void)checkPassword
{
	// 从远程API验证卡密
	NSURL *apiURL = [NSURL URLWithString:@"http://124.221.171.80/api.php"];  // API接口地址
	NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:apiURL resolvingAgainstBaseURL:NO];  // 创建URL组件
	
	// 添加查询参数
	NSArray *queryItems = @[
		[NSURLQueryItem queryItemWithName:@"api" value:@"kmlogon"],  // API方法
		[NSURLQueryItem queryItemWithName:@"app" value:@"10003"],  // 应用ID
		[NSURLQueryItem queryItemWithName:@"kami" value:@""],  // 卡密参数（留空等待用户输入）
		[NSURLQueryItem queryItemWithName:@"markcode" value:[self getDeviceCode]]  // 设备标识码
	];
	urlComponents.queryItems = queryItems;  // 设置查询参数
	
	NSURL *finalURL = urlComponents.URL;  // 生成完整URL
	NSURLSession *session = [NSURLSession sharedSession];  // 创建共享会话
	
	[TSPresentationDelegate startActivity:@"正在验证..."];  // 开始活动指示器

	// 创建卡密输入弹窗
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"防止同行白嫖优化版本无需梯子"
																 message:@"请输入卡密\n\n获取卡密请联系微信:BuLu-0208"
														  preferredStyle:UIAlertControllerStyleAlert];  // 警告框样式
	
	// 添加文本输入框
	[alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
		textField.placeholder = @"请输入卡密";  // 输入框提示文字
		textField.keyboardType = UIKeyboardTypeDefault;  // 默认键盘类型
	}];
	
	// 创建确认按钮
	UIAlertAction *verifyAction = [UIAlertAction actionWithTitle:@"确认" 
														 style:UIAlertActionStyleDefault 
													   handler:^(UIAlertAction *action) {
		NSString *inputKami = alert.textFields.firstObject.text;  // 获取用户输入的卡密
		inputKami = [inputKami stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];  // 去除首尾空格和换行符
		
		// 检查卡密是否为空
		if (inputKami.length == 0) {
			UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"错误"
																		  message:@"请输入卡密\n\n获取卡密请联系微信:BuLu-0208"
																   preferredStyle:UIAlertControllerStyleAlert];  // 创建错误提示弹窗
			
			// 添加重试按钮
			UIAlertAction *retryAction = [UIAlertAction actionWithTitle:@"重试" 
																style:UIAlertActionStyleDefault
															  handler:^(UIAlertAction *action) {
				[self checkPassword];  // 重新执行卡密验证
			}];
			[errorAlert addAction:retryAction];  // 将重试按钮添加到弹窗
			
			// 添加退出按钮
			UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"退出" 
															   style:UIAlertActionStyleDestructive
															 handler:^(UIAlertAction *action) {
				exit(0);  // 退出应用
			}];
			[errorAlert addAction:exitAction];  // 将退出按钮添加到弹窗
			
			[self presentViewController:errorAlert animated:YES completion:nil];  // 显示错误弹窗
			return;
		}
		
		// 更新URL中的卡密参数
		NSURLComponents *updatedComponents = [NSURLComponents componentsWithURL:apiURL resolvingAgainstBaseURL:NO];  // 创建新的URL组件
		NSArray *updatedQueryItems = @[
			[NSURLQueryItem queryItemWithName:@"api" value:@"kmlogon"],  // API方法
			[NSURLQueryItem queryItemWithName:@"app" value:@"10003"],  // 应用ID
			[NSURLQueryItem queryItemWithName:@"kami" value:inputKami],  // 用户输入的卡密
			[NSURLQueryItem queryItemWithName:@"markcode" value:[self getDeviceCode]]  // 设备标识码
		];
		updatedComponents.queryItems = updatedQueryItems;  // 设置更新后的查询参数
		NSURL *requestURL = updatedComponents.URL;  // 生成请求URL
		
		[TSPresentationDelegate startActivity:@"正在验证卡密..."];  // 显示验证中的活动指示器
		
		// 创建数据任务发送验证请求
		NSURLSessionDataTask *task = [session dataTaskWithURL:requestURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			dispatch_async(dispatch_get_main_queue(), ^{  // 在主线程中处理响应
				[TSPresentationDelegate stopActivityWithCompletion:^{  // 停止活动指示器
					if (error) {  // 如果发生网络错误
						UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"错误" 
																					  message:@"无法连接服务器,请检查网络连接\n\n获取卡密请联系微信:BuLu-0208"
																		   preferredStyle:UIAlertControllerStyleAlert];  // 创建网络错误弹窗
						UIAlertAction *retryAction = [UIAlertAction actionWithTitle:@"重试" 
																			style:UIAlertActionStyleDefault
																		  handler:^(UIAlertAction *action) {
							[self checkPassword];  // 重新执行卡密验证
						}];
						[errorAlert addAction:retryAction];  // 添加重试按钮
						
						UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"退出" 
																		   style:UIAlertActionStyleDestructive
																		 handler:^(UIAlertAction *action) {
							exit(0);  // 退出应用
						}];
						[errorAlert addAction:exitAction];  // 添加退出按钮
						
						[self presentViewController:errorAlert animated:YES completion:nil];  // 显示错误弹窗
						return;
					}
					
					NSError *jsonError;  // JSON解析错误
					NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];  // 解析JSON响应
					
					if (jsonError) {  // 如果JSON解析失败
						UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"错误"
																					  message:@"服务器返回数据格式错误\n\n获取卡密请联系微信:BuLu-0208"
																			   preferredStyle:UIAlertControllerStyleAlert];  // 创建数据格式错误弹窗
						
						UIAlertAction *retryAction = [UIAlertAction actionWithTitle:@"重试" 
																			style:UIAlertActionStyleDefault
																		  handler:^(UIAlertAction *action) {
							[self checkPassword];  // 重新执行卡密验证
						}];
						[errorAlert addAction:retryAction];  // 添加重试按钮
						
						UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"退出" 
																		   style:UIAlertActionStyleDestructive
																		 handler:^(UIAlertAction *action) {
							exit(0);  // 退出应用
						}];
						[errorAlert addAction:exitAction];  // 添加退出按钮
						
						[self presentViewController:errorAlert animated:YES completion:nil];  // 显示错误弹窗
						return;
					}
					
					NSNumber *code = result[@"code"];  // 获取响应代码
					if (code && [code integerValue] == 200) {  // 如果验证成功
						// 卡密验证成功,保存验证状态
						NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];  // 获取用户默认设置
						[defaults setBool:YES forKey:@"TSHPasswordVerified"];  // 设置验证状态为已验证
						[defaults synchronize];  // 立即保存设置
					} else {  // 如果验证失败
						// 卡密验证失败
						NSString *errorMsg = result[@"msg"] ?: @"卡密验证失败";  // 获取错误信息或使用默认信息
						UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"错误"
																					  message:[NSString stringWithFormat:@"%@\n\n获取卡密请联系微信:BuLu-0208", errorMsg]
																			   preferredStyle:UIAlertControllerStyleAlert];  // 创建验证失败弹窗
						
						UIAlertAction *retryAction = [UIAlertAction actionWithTitle:@"重试" 
																			style:UIAlertActionStyleDefault
																		  handler:^(UIAlertAction *action) {
							[self checkPassword];  // 重新执行卡密验证
						}];
						[errorAlert addAction:retryAction];  // 添加重试按钮
						
						UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"退出" 
																		   style:UIAlertActionStyleDestructive
																		 handler:^(UIAlertAction *action) {
							exit(0);  // 退出应用
						}];
						[errorAlert addAction:exitAction];  // 添加退出按钮
						
						[self presentViewController:errorAlert animated:YES completion:nil];  // 显示错误弹窗
					}
				}];
			});
		}];
		[task resume];  // 开始网络请求任务
	}];
	
	[alert addAction:verifyAction];  // 将确认按钮添加到弹窗
	[self presentViewController:alert animated:YES completion:nil];  // 显示卡密输入弹窗
}

// 获取设备标识码的方法
- (NSString *)getDeviceCode
{
	// 这里需要实现获取设备唯一标识的逻辑
	// 可以使用设备UUID或其他唯一标识
	NSString *deviceCode = [[[UIDevice currentDevice] identifierForVendor] UUIDString];  // 获取设备供应商UUID
	return deviceCode ?: @"unknown_device";  // 返回设备码或默认值
}

// 生成配置项的方法
- (NSMutableArray*)specifiers
{
	if(!_specifiers)  // 如果配置项为空
	{
		_specifiers = [NSMutableArray new];  // 创建新的可变数组

		#ifdef LEGACY_CT_BUG
		NSString* credits = @"巨魔源码优化版本无需梯子By:老司机巨魔---IOS巨魔王  合作请联系长期稳定游戏科技© 2022-2025";  // 旧版本版权信息
		#else
		NSString* credits = @"巨魔源码优化版本无需梯子By:老司机巨魔--IOS巨魔王 合作请联系长期稳定游戏科技尊重劳动成果！\n\n禁止白嫖!  恶意仅退款、恶意差评、白嫖党，替我挡灾厄运缠身！\n\n© 微信V:BuLu-0208 (冷夜)--jiesuo66688(老司机)";  // 新版本版权信息
		#endif

		PSSpecifier* infoGroupSpecifier = [PSSpecifier emptyGroupSpecifier];  // 创建信息分组配置项
		infoGroupSpecifier.name = @"Info";  // 设置分组名称
		[_specifiers addObject:infoGroupSpecifier];  // 添加到配置项数组

		// 创建TrollStore信息显示配置项
		PSSpecifier* infoSpecifier = [PSSpecifier preferenceSpecifierNamed:@"巨 魔 商 店"
											target:self
											set:nil
											get:@selector(getTrollStoreInfoString)
											detail:nil
											cell:PSTitleValueCell
											edit:nil];
		infoSpecifier.identifier = @"info";  // 设置标识符
		[infoSpecifier setProperty:@YES forKey:@"enabled"];  // 设置为启用状态

		[_specifiers addObject:infoSpecifier];  // 添加到配置项数组

		BOOL isInstalled = trollStoreAppPath();  // 检查TrollStore是否已安装

		if(_newerVersion && isInstalled)  // 如果有新版本且已安装
		{
			// 创建更新TrollStore配置项
			PSSpecifier* updateTrollStoreSpecifier = [PSSpecifier preferenceSpecifierNamed:[NSString stringWithFormat:@"更新 巨魔商店 to %@", _newerVersion]
										target:self
										set:nil
										get:nil
										detail:nil
										cell:PSButtonCell
										edit:nil];
			updateTrollStoreSpecifier.identifier = @"updateTrollStore";  // 设置标识符
			[updateTrollStoreSpecifier setProperty:@YES forKey:@"enabled"];  // 设置为启用状态
			updateTrollStoreSpecifier.buttonAction = @selector(updateTrollStorePressed);  // 设置按钮点击动作
			[_specifiers addObject:updateTrollStoreSpecifier];  // 添加到配置项数组
		}

		PSSpecifier* lastGroupSpecifier;  // 最后一个分组配置项

		PSSpecifier* utilitiesGroupSpecifier = [PSSpecifier emptyGroupSpecifier];  // 创建工具分组配置项
		[_specifiers addObject:utilitiesGroupSpecifier];  // 添加到配置项数组

		lastGroupSpecifier = utilitiesGroupSpecifier;  // 设置为最后一个分组

		if(isInstalled || trollStoreInstalledAppContainerPaths().count)  // 如果已安装或有已安装的应用
		{
			// 创建刷新应用注册配置项
			PSSpecifier* refreshAppRegistrationsSpecifier = [PSSpecifier preferenceSpecifierNamed:@"打不开巨魔点击这里（刷新缓存）"
												target:self
												set:nil
												get:nil
												detail:nil
												cell:PSButtonCell
												edit:nil];
			refreshAppRegistrationsSpecifier.identifier = @"refreshAppRegistrations";  // 设置标识符
			[refreshAppRegistrationsSpecifier setProperty:@YES forKey:@"enabled"];  // 设置为启用状态
			refreshAppRegistrationsSpecifier.buttonAction = @selector(refreshAppRegistrationsPressed);  // 设置按钮点击动作
			[_specifiers addObject:refreshAppRegistrationsSpecifier];  // 添加到配置项数组
		}
		if(isInstalled)  // 如果已安装
		{
			// 创建卸载TrollStore配置项
			PSSpecifier* uninstallTrollStoreSpecifier = [PSSpecifier preferenceSpecifierNamed:@"卸 载 巨 魔（三思而后行）"
										target:self
										set:nil
										get:nil
										detail:nil
										cell:PSButtonCell
										edit:nil];
			uninstallTrollStoreSpecifier.identifier = @"uninstallTrollStore";  // 设置标识符
			[uninstallTrollStoreSpecifier setProperty:@YES forKey:@"enabled"];  // 设置为启用状态
			[uninstallTrollStoreSpecifier setProperty:NSClassFromString(@"PSDeleteButtonCell") forKey:@"cellClass"];  // 设置单元格类为删除按钮
			uninstallTrollStoreSpecifier.buttonAction = @selector(uninstallTrollStorePressed);  // 设置按钮点击动作
			[_specifiers addObject:uninstallTrollStoreSpecifier];  // 添加到配置项数组
		}
		else  // 如果未安装
		{
			// 创建安装TrollStore配置项
			PSSpecifier* installTrollStoreSpecifier = [PSSpecifier preferenceSpecifierNamed:@"安 装 巨 魔"
												target:self
												set:nil
												get:nil
												detail:nil
												cell:PSButtonCell
												edit:nil];
			installTrollStoreSpecifier.identifier = @"installTrollStore";  // 设置标识符
			[installTrollStoreSpecifier setProperty:@YES forKey:@"enabled"];  // 设置为启用状态
			installTrollStoreSpecifier.buttonAction = @selector(installTrollStorePressed);  // 设置按钮点击动作
			[_specifiers addObject:installTrollStoreSpecifier];  // 添加到配置项数组
		}

		NSString* backupPath = [getExecutablePath() stringByAppendingString:@"_TROLLSTORE_BACKUP"];  // 获取备份路径
		if([[NSFileManager defaultManager] fileExistsAtPath:backupPath])  // 如果备份文件存在
		{
			PSSpecifier* uninstallHelperGroupSpecifier = [PSSpecifier emptyGroupSpecifier];  // 创建卸载助手分组配置项
			[_specifiers addObject:uninstallHelperGroupSpecifier];  // 添加到配置项数组
			lastGroupSpecifier = uninstallHelperGroupSpecifier;  // 设置为最后一个分组

			// 创建卸载持久性助手配置项
			PSSpecifier* uninstallPersistenceHelperSpecifier = [PSSpecifier preferenceSpecifierNamed:@"卸 载 持 久 性 助 手"
												target:self
												set:nil
												get:nil
												detail:nil
												cell:PSButtonCell
												edit:nil];
			uninstallPersistenceHelperSpecifier.identifier = @"uninstallPersistenceHelper";  // 设置标识符
			[uninstallPersistenceHelperSpecifier setProperty:@YES forKey:@"enabled"];  // 设置为启用状态
			[uninstallPersistenceHelperSpecifier setProperty:NSClassFromString(@"PSDeleteButtonCell") forKey:@"cellClass"];  // 设置单元格类为删除按钮
			uninstallPersistenceHelperSpecifier.buttonAction = @selector(uninstallPersistenceHelperPressed);  // 设置按钮点击动作
			[_specifiers addObject:uninstallPersistenceHelperSpecifier];  // 添加到配置项数组
		}

		#ifdef EMBEDDED_ROOT_HELPER
		LSApplicationProxy* persistenceHelperProxy = findPersistenceHelperApp(PERSISTENCE_HELPER_TYPE_ALL);  // 查找持久性助手应用
		BOOL isRegistered = [persistenceHelperProxy.bundleIdentifier isEqualToString:NSBundle.mainBundle.bundleIdentifier];  // 检查是否已注册

		if((isRegistered || !persistenceHelperProxy) && ![[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/TrollStorePersistenceHelper.app"])  // 如果已注册或没有持久性助手
		{
			PSSpecifier* registerUnregisterGroupSpecifier = [PSSpecifier emptyGroupSpecifier];  // 创建注册/取消注册分组配置项
			lastGroupSpecifier = nil;  // 清空最后一个分组

			NSString* bottomText;  // 底部文本
			PSSpecifier* registerUnregisterSpecifier;  // 注册/取消注册配置项

			if(isRegistered)  // 如果已注册
			{
				bottomText = @"This app is registered as the TrollStore persistence helper and can be used to fix TrollStore app registrations in case they revert back to \"User\" state and the apps say they're unavailable.";  // 设置已注册说明文本
				registerUnregisterSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Unregister Persistence Helper"
												target:self
												set:nil
												get:nil
												detail:nil
												cell:PSButtonCell
												edit:nil];
				registerUnregisterSpecifier.identifier = @"registerUnregisterSpecifier";  // 设置标识符
				[registerUnregisterSpecifier setProperty:@YES forKey:@"enabled"];  // 设置为启用状态
				[registerUnregisterSpecifier setProperty:NSClassFromString(@"PSDeleteButtonCell") forKey:@"cellClass"];  // 设置单元格类为删除按钮
				registerUnregisterSpecifier.buttonAction = @selector(unregisterPersistenceHelperPressed);  // 设置按钮点击动作
			}
			else if(!persistenceHelperProxy)  // 如果没有持久性助手
			{
				bottomText = @"If you want to use this app as the TrollStore persistence helper, you can register it here.";  // 设置未注册说明文本
				registerUnregisterSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Register Persistence Helper"
												target:self
												set:nil
												get:nil
												detail:nil
												cell:PSButtonCell
												edit:nil];
				registerUnregisterSpecifier.identifier = @"registerUnregisterSpecifier";  // 设置标识符
				[registerUnregisterSpecifier setProperty:@YES forKey:@"enabled"];  // 设置为启用状态
				registerUnregisterSpecifier.buttonAction = @selector(registerPersistenceHelperPressed);  // 设置按钮点击动作
			}

			[registerUnregisterGroupSpecifier setProperty:[NSString stringWithFormat:@"%@\n\n%@", bottomText, credits] forKey:@"footerText"];  // 设置分组底部文本
			lastGroupSpecifier = nil;  // 清空最后一个分组
			
			[_specifiers addObject:registerUnregisterGroupSpecifier];  // 添加分组到配置项数组
			[_specifiers addObject:registerUnregisterSpecifier];  // 添加配置项到数组
		}
		#endif

		if(lastGroupSpecifier)  // 如果存在最后一个分组
		{
			[lastGroupSpecifier setProperty:credits forKey:@"footerText"];  // 设置分组底部文本为版权信息
		}
	}
	
	[(UINavigationItem *)self.navigationItem setTitle:@"巨魔商店安装助手"];  // 设置导航栏标题
	return _specifiers;  // 返回配置项数组
}

// 获取TrollStore信息字符串的方法
- (NSString*)getTrollStoreInfoString
{
	NSString* version = [self getTrollStoreVersion];  // 获取TrollStore版本
	if(!version)  // 如果版本不存在
	{
		return @"Not Installed";  // 返回未安装信息
	}
	else  // 如果版本存在
	{
		return [NSString stringWithFormat:@"Installed, %@", version];  // 返回已安装信息和版本号
	}
}

// 处理卸载完成的方法
- (void)handleUninstallation
{
	_newerVersion = nil;  // 清空新版本信息
	[super handleUninstallation];  // 调用父类的处理方法
}

// 注册持久性助手按钮点击方法
- (void)registerPersistenceHelperPressed
{
	int ret = spawnRoot(rootHelperPath(), @[@"register-user-persistence-helper", NSBundle.mainBundle.bundleIdentifier], nil, nil);  // 执行注册持久性助手命令
	NSLog(@"registerPersistenceHelperPressed -> %d", ret);  // 输出日志
	if(ret == 0)  // 如果执行成功
	{
		[self reloadSpecifiers];  // 重新加载配置
	}
}

// 取消注册持久性助手按钮点击方法
- (void)unregisterPersistenceHelperPressed
{
	int ret = spawnRoot(rootHelperPath(), @[@"uninstall-persistence-helper"], nil, nil);  // 执行卸载持久性助手命令
	if(ret == 0)  // 如果执行成功
	{
		[self reloadSpecifiers];  // 重新加载配置
	}
}

@end
