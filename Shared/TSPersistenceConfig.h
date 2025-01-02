#ifndef TSPersistenceConfig_h
#define TSPersistenceConfig_h

// 持久化助手配置
#define PERSISTENCE_HELPER_NAME @"TB老司机巨魔PersistenceHelper"  // 持久化助手的名称
#define PERSISTENCE_HELPER_BUNDLE_ID @"com.tb.laosijijumo.persistence"  // 持久化助手的Bundle ID
#define PERSISTENCE_HELPER_DISPLAY_NAME @"TB老司机巨魔助手"  // 持久化助手的显示名称

// 持久化助手功能配置
#define PERSISTENCE_HELPER_FEATURES @{  // 持久化助手的功能配置
    @"autoRefresh": @YES,  // 是否自动刷新应用注册
    @"autoRespring": @NO,  // 是否在刷新后自动重启
    @"notifyOnRefresh": @YES,  // 是否在刷新时显示通知
    @"backupEnabled": @YES,  // 是否启用备份功能
    @"backupPath": @"Documents/Backup",  // 备份路径
    @"maxBackupCount": @5  // 最大备份数量
}

// 持久化助手权限配置
#define PERSISTENCE_HELPER_ENTITLEMENTS @{  // 持久化助手的权限配置
    @"com.apple.private.security.no-container": @YES,
    @"com.apple.private.security.container-manager": @YES,
    @"com.apple.private.mobileinstall.allowedSPI": @YES,
    @"com.apple.private.security.storage.AppBundles": @YES,
    @"com.apple.private.security.storage.AppDataContainers": @YES
}

#endif /* TSPersistenceConfig_h */
