#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "GTBFlagManager.h"
#import "GTBSettingsViewController.h"

#pragma mark - Forward Declarations (TikTok 47.9.0)

@interface NSObject (GTBTikTokNaviBar)
- (id)awe_naviBar;
- (void)addRightNaviBarBtnView:(UIView *)view;
@end

#pragma mark - Runtime Hook Helpers (Zero Substrate/ElleKit dependency)

static IMP GTBHookInstanceMethod(Class cls, SEL sel, IMP newImp) {
    if (!cls) return NULL;
    Method m = class_getInstanceMethod(cls, sel);
    if (!m) return NULL;
    IMP prev = method_getImplementation(m);
    if (!class_addMethod(cls, sel, newImp, method_getTypeEncoding(m))) {
        prev = method_setImplementation(m, newImp);
    }
    return prev;
}

static IMP GTBHookClassMethod(Class cls, SEL sel, IMP newImp) {
    if (!cls) return NULL;
    return GTBHookInstanceMethod(object_getClass((id)cls), sel, newImp);
}

static BOOL GTBMarkClassHooked(NSString *className, Class *outClass) {
    static NSMutableSet<NSString *> *hooked = nil;
    if (!hooked) hooked = [NSMutableSet set];
    if ([hooked containsObject:className]) return NO;
    Class cls = NSClassFromString(className);
    if (!cls) return NO;
    [hooked addObject:className];
    if (outClass) *outClass = cls;
    return YES;
}

#define GTB_HOOK_INST(cls, sel, hookFn, origVar) \
    do { \
        IMP _prev = GTBHookInstanceMethod((cls), (sel), (IMP)(hookFn)); \
        if (_prev) (origVar) = (__typeof__(origVar))_prev; \
    } while (0)

#define GTB_HOOK_CLS(cls, sel, hookFn, origVar) \
    do { \
        IMP _prev = GTBHookClassMethod((cls), (sel), (IMP)(hookFn)); \
        if (_prev) (origVar) = (__typeof__(origVar))_prev; \
    } while (0)

static id GTBOverrideForKeyOrNil(NSString *key) {
    if (!key) return nil;
    return [[GTBFlagManager sharedManager] overrideValueForABKey:key];
}

static BOOL GTBShouldOverrideBool(NSString *key, BOOL orig) {
    GTBFlagManager *mgr = [GTBFlagManager sharedManager];
    if (!mgr.masterEnabled) return orig;
    return [mgr isFlagEnabled:key];
}

#pragma mark - Layer 1: A/B Test Data Stores & Manager Hooks

static NSDictionary *(*orig_ObjCStore_getAllConfig)(id, SEL) = NULL;
static NSDictionary *hook_ObjCStore_getAllConfig(id self, SEL _cmd) {
    NSDictionary *orig = orig_ObjCStore_getAllConfig ? orig_ObjCStore_getAllConfig(self, _cmd) : nil;
    return [[GTBFlagManager sharedManager] dictionaryByApplyingOverridesToDictionary:orig];
}

static NSDictionary *(*orig_SwiftStore_getAllConfig)(id, SEL) = NULL;
static NSDictionary *hook_SwiftStore_getAllConfig(id self, SEL _cmd) {
    NSDictionary *orig = orig_SwiftStore_getAllConfig ? orig_SwiftStore_getAllConfig(self, _cmd) : nil;
    return [[GTBFlagManager sharedManager] dictionaryByApplyingOverridesToDictionary:orig];
}

static id (*orig_ABMgr_getStableValue)(id, SEL, NSString *) = NULL;
static id hook_ABMgr_getStableValue(id self, SEL _cmd, NSString *key) {
    id overrideVal = GTBOverrideForKeyOrNil(key);
    if (overrideVal != nil) return overrideVal;
    return orig_ABMgr_getStableValue ? orig_ABMgr_getStableValue(self, _cmd, key) : nil;
}

static id (*orig_ABMgr_abTestCase)(id, SEL, NSString *) = NULL;
static id hook_ABMgr_abTestCase(id self, SEL _cmd, NSString *propertyName) {
    id overrideVal = GTBOverrideForKeyOrNil(propertyName);
    if (overrideVal != nil) return overrideVal;
    return orig_ABMgr_abTestCase ? orig_ABMgr_abTestCase(self, _cmd, propertyName) : nil;
}

static id (*orig_ABMgr_getUidABTestValue)(id, SEL, NSString *, BOOL, id) = NULL;
static id hook_ABMgr_getUidABTestValue(id self, SEL _cmd, NSString *key, BOOL stable, id defaultValue) {
    id overrideVal = GTBOverrideForKeyOrNil(key);
    if (overrideVal != nil) return overrideVal;
    return orig_ABMgr_getUidABTestValue ? orig_ABMgr_getUidABTestValue(self, _cmd, key, stable, defaultValue) : defaultValue;
}

static NSDictionary *(*orig_ABMgr_currentActiveData)(id, SEL) = NULL;
static NSDictionary *hook_ABMgr_currentActiveData(id self, SEL _cmd) {
    NSDictionary *orig = orig_ABMgr_currentActiveData ? orig_ABMgr_currentActiveData(self, _cmd) : nil;
    return [[GTBFlagManager sharedManager] dictionaryByApplyingOverridesToDictionary:orig];
}

#pragma mark - Layer 2: TTKTabBarLiquidGlassConfig / TTKIOS26LiquidGlassSwitch / TTKABTest

static BOOL (*orig_LGConfig_liquidGlassABEnabled)(id, SEL) = NULL;
static BOOL hook_LGConfig_liquidGlassABEnabled(id self, SEL _cmd) {
    BOOL orig = orig_LGConfig_liquidGlassABEnabled ? orig_LGConfig_liquidGlassABEnabled(self, _cmd) : NO;
    return GTBShouldOverrideBool(@"ttk_tabbar_liquid_glass_enabled", orig);
}

static BOOL (*orig_LGConfig_isAllowed)(id, SEL) = NULL;
static BOOL hook_LGConfig_isAllowed(id self, SEL _cmd) {
    BOOL orig = orig_LGConfig_isAllowed ? orig_LGConfig_isAllowed(self, _cmd) : NO;
    GTBFlagManager *mgr = [GTBFlagManager sharedManager];
    if (!mgr.masterEnabled) return orig;
    if ([mgr isFlagEnabled:@"gtb_bypass_ios_version_gate"]) {
        return [mgr isFlagEnabled:@"ttk_tabbar_liquid_glass_enabled"] && [mgr isFlagEnabled:@"ttk_tabbar_liquid_glass_fix"];
    }
    return orig;
}

static BOOL (*orig_LGConfig_foldScreen)(id, SEL) = NULL;
static BOOL hook_LGConfig_foldScreen(id self, SEL _cmd) {
    BOOL orig = orig_LGConfig_foldScreen ? orig_LGConfig_foldScreen(self, _cmd) : NO;
    return GTBShouldOverrideBool(@"ttk_tabbar_fold_screen_liquid_glass_enabled", orig);
}

static BOOL (*orig_LGConfig_nonFullScreen)(id, SEL) = NULL;
static BOOL hook_LGConfig_nonFullScreen(id self, SEL _cmd) {
    BOOL orig = orig_LGConfig_nonFullScreen ? orig_LGConfig_nonFullScreen(self, _cmd) : NO;
    return GTBShouldOverrideBool(@"ttk_tabbar_non_fullscreen_liquid_glass_enabled", orig);
}

static BOOL (*orig_LGConfig_buttonTextEnabled)(id, SEL) = NULL;
static BOOL hook_LGConfig_buttonTextEnabled(id self, SEL _cmd) {
    BOOL orig = orig_LGConfig_buttonTextEnabled ? orig_LGConfig_buttonTextEnabled(self, _cmd) : YES;
    GTBFlagManager *mgr = [GTBFlagManager sharedManager];
    if (!mgr.masterEnabled) return orig;
    return ![mgr isFlagEnabled:@"tabbar_button_text_disable"];
}

static BOOL (*orig_LGConfig_verticalButtonText)(id, SEL) = NULL;
static BOOL hook_LGConfig_verticalButtonText(id self, SEL _cmd) {
    BOOL orig = orig_LGConfig_verticalButtonText ? orig_LGConfig_verticalButtonText(self, _cmd) : NO;
    return GTBShouldOverrideBool(@"vertical_tabbar_button_text_always_show", orig);
}

static BOOL (*orig_LGConfig_scrollScale)(id, SEL) = NULL;
static BOOL hook_LGConfig_scrollScale(id self, SEL _cmd) {
    BOOL orig = orig_LGConfig_scrollScale ? orig_LGConfig_scrollScale(self, _cmd) : NO;
    return GTBShouldOverrideBool(@"ttk_tabbar_scroll_scale_enable", orig);
}

static BOOL (*orig_LGConfig_plusSizeFix)(id, SEL) = NULL;
static BOOL hook_LGConfig_plusSizeFix(id self, SEL _cmd) {
    BOOL orig = orig_LGConfig_plusSizeFix ? orig_LGConfig_plusSizeFix(self, _cmd) : NO;
    return GTBShouldOverrideBool(@"ttk_tabbar_liquid_glass_plus_button_size_fix", orig);
}

static BOOL (*orig_LGConfig_legacyIconHeight)(id, SEL) = NULL;
static BOOL hook_LGConfig_legacyIconHeight(id self, SEL _cmd) {
    BOOL orig = orig_LGConfig_legacyIconHeight ? orig_LGConfig_legacyIconHeight(self, _cmd) : NO;
    return GTBShouldOverrideBool(@"ttk_tabbar_liquid_glass_legacy_declared_icon_visible_height", orig);
}

static BOOL (*orig_LGConfig_pillFirst)(id, SEL) = NULL;
static BOOL hook_LGConfig_pillFirst(id self, SEL _cmd) {
    BOOL orig = orig_LGConfig_pillFirst ? orig_LGConfig_pillFirst(self, _cmd) : NO;
    return GTBShouldOverrideBool(@"ttk_tabbar_liquid_glass_deferred_page_switch_enabled", orig);
}

static BOOL (*orig_LGConfig_hasFullBarAllowlist)(id, SEL) = NULL;
static BOOL hook_LGConfig_hasFullBarAllowlist(id self, SEL _cmd) {
    BOOL orig = orig_LGConfig_hasFullBarAllowlist ? orig_LGConfig_hasFullBarAllowlist(self, _cmd) : NO;
    return GTBShouldOverrideBool(@"ttk_tabbar_liquid_glass_full_bar_background_tabs", orig);
}

static BOOL (*orig_LGConfig_isFullBarForTab)(id, SEL, NSString *) = NULL;
static BOOL hook_LGConfig_isFullBarForTab(id self, SEL _cmd, NSString *tabId) {
    BOOL orig = orig_LGConfig_isFullBarForTab ? orig_LGConfig_isFullBarForTab(self, _cmd, tabId) : NO;
    GTBFlagManager *mgr = [GTBFlagManager sharedManager];
    if (!mgr.masterEnabled) return orig;
    return [mgr isFlagEnabled:@"ttk_tabbar_liquid_glass_full_bar_background_tabs"];
}

static BOOL (*orig_IOS26Switch_isFixEnabled)(id, SEL) = NULL;
static BOOL hook_IOS26Switch_isFixEnabled(id self, SEL _cmd) {
    BOOL orig = orig_IOS26Switch_isFixEnabled ? orig_IOS26Switch_isFixEnabled(self, _cmd) : NO;
    return GTBShouldOverrideBool(@"ttk_tabbar_liquid_glass_fix", orig);
}

static BOOL (*orig_TTKABTest_fix)(id, SEL) = NULL;
static BOOL hook_TTKABTest_fix(id self, SEL _cmd) {
    BOOL orig = orig_TTKABTest_fix ? orig_TTKABTest_fix(self, _cmd) : NO;
    return GTBShouldOverrideBool(@"ttk_tabbar_liquid_glass_fix", orig);
}

static NSDictionary *(*orig_TTKABTest_lgConfig)(id, SEL) = NULL;
static NSDictionary *hook_TTKABTest_lgConfig(id self, SEL _cmd) {
    NSDictionary *orig = orig_TTKABTest_lgConfig ? orig_TTKABTest_lgConfig(self, _cmd) : nil;
    GTBFlagManager *mgr = [GTBFlagManager sharedManager];
    if (!mgr.masterEnabled) return orig;
    NSDictionary *overrideDict = [mgr overrideValueForABKey:@"ttk_tabbar_liquid_glass_config"];
    if ([overrideDict isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *merged = orig ? [orig mutableCopy] : [NSMutableDictionary dictionary];
        [merged addEntriesFromDictionary:overrideDict];
        return [merged copy];
    }
    return orig;
}

static BOOL (*orig_TTKABTest_plusFix)(id, SEL) = NULL;
static BOOL hook_TTKABTest_plusFix(id self, SEL _cmd) {
    BOOL orig = orig_TTKABTest_plusFix ? orig_TTKABTest_plusFix(self, _cmd) : NO;
    return GTBShouldOverrideBool(@"ttk_tabbar_liquid_glass_plus_button_size_fix", orig);
}

static NSDictionary *(*orig_TTKABTest_scrollPerfConfig)(id, SEL) = NULL;
static NSDictionary *hook_TTKABTest_scrollPerfConfig(id self, SEL _cmd) {
    NSDictionary *orig = orig_TTKABTest_scrollPerfConfig ? orig_TTKABTest_scrollPerfConfig(self, _cmd) : nil;
    GTBFlagManager *mgr = [GTBFlagManager sharedManager];
    if (!mgr.masterEnabled) return orig;
    NSDictionary *overrideDict = [mgr overrideValueForABKey:@"ttk_tabbar_scroll_compact_perf_config"];
    if ([overrideDict isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *merged = orig ? [orig mutableCopy] : [NSMutableDictionary dictionary];
        [merged addEntriesFromDictionary:overrideDict];
        return [merged copy];
    }
    return orig;
}

static BOOL (*orig_TTKABTest_smaller450)(id, SEL) = NULL;
static BOOL hook_TTKABTest_smaller450(id self, SEL _cmd) {
    BOOL orig = orig_TTKABTest_smaller450 ? orig_TTKABTest_smaller450(self, _cmd) : NO;
    return GTBShouldOverrideBool(@"enable_liquid_glass_smaller_450", orig);
}

#pragma mark - Layer 3: Native Settings UI Entry Point (TTKSettingsViewController)

static char kGTBButtonAddedKey;
static void (*orig_SettingsVC_viewDidLoad)(UIViewController *, SEL) = NULL;

static void hook_SettingsVC_openGlass(UIViewController *self, SEL _cmd) {
    GTBSettingsViewController *vc = [[GTBSettingsViewController alloc] init];
    if (self.navigationController) {
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.modalPresentationStyle = UIModalPresentationPageSheet;
        [self presentViewController:nav animated:YES completion:nil];
    }
}

static void hook_SettingsVC_viewDidLoad(UIViewController *self, SEL _cmd) {
    if (orig_SettingsVC_viewDidLoad) {
        orig_SettingsVC_viewDidLoad(self, _cmd);
    }

    if (objc_getAssociatedObject(self, &kGTBButtonAddedKey)) return;
    objc_setAssociatedObject(self, &kGTBButtonAddedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    UIColor *accent = [UIColor colorWithRed:0.15 green:0.68 blue:0.98 alpha:1.0];
    UIButtonConfiguration *btnCfg = [UIButtonConfiguration tintedButtonConfiguration];
    btnCfg.title = @"Glass";
    btnCfg.image = [UIImage systemImageNamed:@"sparkles"
                           withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:12 weight:UIImageSymbolWeightSemibold]];
    btnCfg.imagePadding = 5.0;
    btnCfg.baseForegroundColor = accent;
    btnCfg.baseBackgroundColor = accent;
    btnCfg.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
    btnCfg.contentInsets = NSDirectionalEdgeInsetsMake(6.0, 11.0, 6.0, 12.0);
    btnCfg.titleTextAttributesTransformer = ^NSDictionary<NSAttributedStringKey, id> *(NSDictionary<NSAttributedStringKey, id> *incoming) {
        NSMutableDictionary *d = [incoming mutableCopy];
        d[NSFontAttributeName] = [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold];
        return d;
    };

    UIButton *glassBtn = [UIButton buttonWithConfiguration:btnCfg primaryAction:nil];
    glassBtn.translatesAutoresizingMaskIntoConstraints = NO;
    glassBtn.layer.borderWidth = 0.75;
    glassBtn.layer.borderColor = [accent colorWithAlphaComponent:0.40].CGColor;
    glassBtn.layer.cornerRadius = 15.0;
    glassBtn.clipsToBounds = YES;
    [glassBtn sizeToFit];
    [glassBtn addTarget:self action:@selector(gtb_openGlassTabBarSettings) forControlEvents:UIControlEventTouchUpInside];

    id naviBar = [self respondsToSelector:@selector(awe_naviBar)] ? [self awe_naviBar] : nil;
    if (naviBar && [naviBar respondsToSelector:@selector(addRightNaviBarBtnView:)]) {
        [naviBar addRightNaviBarBtnView:glassBtn];
    } else if (self.navigationItem) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:glassBtn];
    }
}

#pragma mark - Hook Installer

static void GTBInstallAllHooks(void) {
    @synchronized([GTBFlagManager sharedManager]) {
        Class cls = Nil;

        if (GTBMarkClassHooked(@"AWEABTestObjCDataStore", &cls)) {
            GTB_HOOK_INST(cls, @selector(getAllConfig), hook_ObjCStore_getAllConfig, orig_ObjCStore_getAllConfig);
        }

        if (GTBMarkClassHooked(@"AWEABTestSwiftDataStoreAdapter", &cls)) {
            GTB_HOOK_INST(cls, @selector(getAllConfig), hook_SwiftStore_getAllConfig, orig_SwiftStore_getAllConfig);
        }

        if (GTBMarkClassHooked(@"AWEABTestManager", &cls)) {
            GTB_HOOK_INST(cls, @selector(getStableValueWithKey:), hook_ABMgr_getStableValue, orig_ABMgr_getStableValue);
            GTB_HOOK_INST(cls, @selector(ABTestCaseWithPropertyName:), hook_ABMgr_abTestCase, orig_ABMgr_abTestCase);
            GTB_HOOK_INST(cls, @selector(getUidABTestValue:stable:defaultValue:), hook_ABMgr_getUidABTestValue, orig_ABMgr_getUidABTestValue);
            GTB_HOOK_INST(cls, @selector(currentActiveABTestData), hook_ABMgr_currentActiveData, orig_ABMgr_currentActiveData);
        }

        if (GTBMarkClassHooked(@"TTKTabBarLiquidGlassConfig", &cls)) {
            GTB_HOOK_CLS(cls, @selector(liquidGlassABEnabled), hook_LGConfig_liquidGlassABEnabled, orig_LGConfig_liquidGlassABEnabled);
            GTB_HOOK_CLS(cls, @selector(isLiquidGlassTabBarAllowed), hook_LGConfig_isAllowed, orig_LGConfig_isAllowed);
            GTB_HOOK_CLS(cls, @selector(foldScreenLiquidGlassEnabled), hook_LGConfig_foldScreen, orig_LGConfig_foldScreen);
            GTB_HOOK_CLS(cls, @selector(nonFullScreenLiquidGlassEnabled), hook_LGConfig_nonFullScreen, orig_LGConfig_nonFullScreen);
            GTB_HOOK_CLS(cls, @selector(buttonTextEnabled), hook_LGConfig_buttonTextEnabled, orig_LGConfig_buttonTextEnabled);
            GTB_HOOK_CLS(cls, @selector(verticalButtonTextAlwaysShow), hook_LGConfig_verticalButtonText, orig_LGConfig_verticalButtonText);
            GTB_HOOK_CLS(cls, @selector(scrollScaleEnabled), hook_LGConfig_scrollScale, orig_LGConfig_scrollScale);
            GTB_HOOK_CLS(cls, @selector(plusButtonIconSizeFixEnabled), hook_LGConfig_plusSizeFix, orig_LGConfig_plusSizeFix);
            GTB_HOOK_CLS(cls, @selector(legacyDeclaredIconVisibleHeight), hook_LGConfig_legacyIconHeight, orig_LGConfig_legacyIconHeight);
            GTB_HOOK_CLS(cls, @selector(pillFirstDeferredTabSwitchEnabled), hook_LGConfig_pillFirst, orig_LGConfig_pillFirst);
            GTB_HOOK_CLS(cls, @selector(hasFullBarBackgroundAllowlist), hook_LGConfig_hasFullBarAllowlist, orig_LGConfig_hasFullBarAllowlist);
            GTB_HOOK_CLS(cls, @selector(isFullBarBackgroundEnabledForTabIdentifier:), hook_LGConfig_isFullBarForTab, orig_LGConfig_isFullBarForTab);
        }

        if (GTBMarkClassHooked(@"TTKIOS26LiquidGlassSwitch", &cls)) {
            GTB_HOOK_CLS(cls, @selector(isFixEnabled), hook_IOS26Switch_isFixEnabled, orig_IOS26Switch_isFixEnabled);
        }

        if (GTBMarkClassHooked(@"TTKABTest", &cls)) {
            GTB_HOOK_CLS(cls, @selector(ttTabbarLiquidGlassFix), hook_TTKABTest_fix, orig_TTKABTest_fix);
            GTB_HOOK_CLS(cls, @selector(ttkTabbarLiquidGlassConfig), hook_TTKABTest_lgConfig, orig_TTKABTest_lgConfig);
            GTB_HOOK_CLS(cls, @selector(ttkTabbarLiquidGlassPlusButtonSizeFix), hook_TTKABTest_plusFix, orig_TTKABTest_plusFix);
            GTB_HOOK_CLS(cls, @selector(ttkTabbarScrollCompactPerfConfig), hook_TTKABTest_scrollPerfConfig, orig_TTKABTest_scrollPerfConfig);
            GTB_HOOK_CLS(cls, @selector(enableLiquidGlassForSmallerThan450DevicesServer), hook_TTKABTest_smaller450, orig_TTKABTest_smaller450);
        }

        if (GTBMarkClassHooked(@"TTKSettingsViewController", &cls)) {
            class_addMethod(cls, NSSelectorFromString(@"gtb_openGlassTabBarSettings"), (IMP)hook_SettingsVC_openGlass, "v@:");
            GTB_HOOK_INST(cls, @selector(viewDidLoad), hook_SettingsVC_viewDidLoad, orig_SettingsVC_viewDidLoad);
        }
    }
}

__attribute__((constructor))
static void GTBInit(void) {
    [GTBFlagManager sharedManager];
    GTBInstallAllHooks();

    // Retry hook installation if any framework loads lazily after constructor
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
        GTBInstallAllHooks();
    }];
}
