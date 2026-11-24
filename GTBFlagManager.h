#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, GTBFlagCategory) {
    GTBFlagCategoryCore = 0,
    GTBFlagCategoryScroll = 1,
    GTBFlagCategoryAppearance = 2,
    GTBFlagCategoryAdvanced = 3,
};

typedef NS_ENUM(NSInteger, GTBFlagStorageType) {
    GTBFlagStorageBool = 0,               // Top-level BOOL A/B key
    GTBFlagStorageGlassConfigBool = 1,    // Key inside ttk_tabbar_liquid_glass_config
    GTBFlagStorageScrollPerfBool = 2,     // Key inside ttk_tabbar_scroll_compact_perf_config
    GTBFlagStorageFullBarTabs = 3,        // ttk_tabbar_liquid_glass_full_bar_background_tabs (NSArray)
    GTBFlagStorageClearDeviceBlock = 4,   // tux_liquid_glass_device_model_block_list (NSArray)
    GTBFlagStorageTuxVersions = 5,        // tux_liquid_glass_component_versions (NSDictionary)
    GTBFlagStorageBypassGate = 6,         // Tweak-level bypass (iOS < 26 / UIDesignRequiresCompatibility)
};

@interface GTBFlagItem : NSObject
@property (nonatomic, copy, readonly) NSString *key;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *subtitle;
@property (nonatomic, copy, readonly) NSString *symbolName;
@property (nonatomic, assign, readonly) GTBFlagCategory category;
@property (nonatomic, assign, readonly) GTBFlagStorageType storageType;
@property (nonatomic, assign, readonly) BOOL defaultValue;
@end

extern NSString *const GTBFlagsDidChangeNotification;

@interface GTBFlagManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, assign) BOOL masterEnabled;

- (NSArray<GTBFlagItem *> *)allItems;
- (NSArray<GTBFlagItem *> *)itemsForCategory:(GTBFlagCategory)category;
- (NSString *)titleForCategory:(GTBFlagCategory)category;
- (NSString *)subtitleForCategory:(GTBFlagCategory)category;
- (NSString *)symbolForCategory:(GTBFlagCategory)category;

- (BOOL)isFlagEnabled:(NSString *)key;
- (void)setFlagEnabled:(BOOL)enabled forKey:(NSString *)key;

- (NSUInteger)enabledCount;
- (NSUInteger)totalCount;

- (void)applyPresetAllGlassAndAnimations;
- (void)applyPresetMinimalNoLabels;
- (void)resetToDefaults;

/// Returns overridden value for a top-level A/B flag key, or nil if tweak shouldn't override it.
- (nullable id)overrideValueForABKey:(NSString *)key;

/// Returns merged dictionary of all overridden top-level A/B flags (for getAllConfig / currentActiveABTestData).
- (NSDictionary<NSString *, id> *)overriddenABDictionary;

/// Helper to merge overrides into an existing AB config dictionary.
- (NSDictionary *)dictionaryByApplyingOverridesToDictionary:(nullable NSDictionary *)source;

@end

NS_ASSUME_NONNULL_END
