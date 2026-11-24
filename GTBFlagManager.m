#import "GTBFlagManager.h"

NSString *const GTBFlagsDidChangeNotification = @"GTBFlagsDidChangeNotification";
static NSString *const kGTBMasterKey = @"GTB_MasterEnabled_v1";
static NSString *const kGTBKeyPrefix = @"GTB_Flag_v1_";

@interface GTBFlagItem ()
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *symbolName;
@property (nonatomic, assign) GTBFlagCategory category;
@property (nonatomic, assign) GTBFlagStorageType storageType;
@property (nonatomic, assign) BOOL defaultValue;
@end

@implementation GTBFlagItem
+ (instancetype)itemWithKey:(NSString *)key
                      title:(NSString *)title
                   subtitle:(NSString *)subtitle
                     symbol:(NSString *)symbol
                   category:(GTBFlagCategory)category
                storageType:(GTBFlagStorageType)storageType
               defaultValue:(BOOL)defaultValue {
    GTBFlagItem *item = [[GTBFlagItem alloc] init];
    item.key = key;
    item.title = title;
    item.subtitle = subtitle;
    item.symbolName = symbol;
    item.category = category;
    item.storageType = storageType;
    item.defaultValue = defaultValue;
    return item;
}
@end

@interface GTBFlagManager ()
@property (nonatomic, strong) NSArray<GTBFlagItem *> *items;
@property (nonatomic, strong) NSDictionary<NSString *, GTBFlagItem *> *itemsByKey;
@end

@implementation GTBFlagManager

+ (instancetype)sharedManager {
    static GTBFlagManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[GTBFlagManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self buildCatalog];
        [self registerDefaultValues];
    }
    return self;
}

- (void)buildCatalog {
    NSArray<GTBFlagItem *> *list = @[
        // === 0. CORE GLASS TABBAR ===
        [GTBFlagItem itemWithKey:@"ttk_tabbar_liquid_glass_enabled"
                           title:@"Стеклянный таббар"
                        subtitle:@"Главный флаг нового Liquid Glass таббара"
                          symbol:@"rectangle.3.group.fill"
                        category:GTBFlagCategoryCore
                     storageType:GTBFlagStorageBool
                    defaultValue:YES],

        [GTBFlagItem itemWithKey:@"tux_liquid_glass_enabled"
                           title:@"Движок TUX Liquid Glass"
                        subtitle:@"Включает рендеринг Liquid Glass в дизайн-системе TUX"
                          symbol:@"sparkles"
                        category:GTBFlagCategoryCore
                     storageType:GTBFlagStorageBool
                    defaultValue:YES],

        [GTBFlagItem itemWithKey:@"ttk_tabbar_liquid_glass_fix"
                           title:@"Системный свитч iOS 26"
                        subtitle:@"Активирует TTKIOS26LiquidGlassSwitch (обязателен для допуска)"
                          symbol:@"checkmark.seal.fill"
                        category:GTBFlagCategoryCore
                     storageType:GTBFlagStorageBool
                    defaultValue:YES],

        [GTBFlagItem itemWithKey:@"enable_liquid_glass_smaller_450"
                           title:@"Экраны меньше 450pt"
                        subtitle:@"Разрешает стеклянный таббар на компактных iPhone"
                          symbol:@"iphone"
                        category:GTBFlagCategoryCore
                     storageType:GTBFlagStorageBool
                    defaultValue:YES],

        [GTBFlagItem itemWithKey:@"tux_tab_bar_update_enabled"
                           title:@"Обновление таббара TUX"
                        subtitle:@"Обновлённый компонент панели вкладок в TUX"
                          symbol:@"arrow.triangle.2.circlepath"
                        category:GTBFlagCategoryCore
                     storageType:GTBFlagStorageBool
                    defaultValue:YES],

        [GTBFlagItem itemWithKey:@"uses_liquid_glass_tabbar"
                           title:@"Флаг состояния Liquid Glass"
                        subtitle:@"Помечает активный таббар как использующий Liquid Glass"
                          symbol:@"tag.fill"
                        category:GTBFlagCategoryCore
                     storageType:GTBFlagStorageBool
                    defaultValue:YES],

        [GTBFlagItem itemWithKey:@"tux_liquid_glass_component_versions"
                           title:@"Версии компонентов TUX"
                        subtitle:@"Поднимает версии TUX для tabBar, button, menu и intro_panel"
                          symbol:@"slider.horizontal.3"
                        category:GTBFlagCategoryCore
                     storageType:GTBFlagStorageTuxVersions
                    defaultValue:YES],

        [GTBFlagItem itemWithKey:@"tux_liquid_glass_device_model_block_list"
                           title:@"Снять блоклист устройств"
                        subtitle:@"Очищает чёрный список моделей устройств для Liquid Glass"
                          symbol:@"lock.open.fill"
                        category:GTBFlagCategoryCore
                     storageType:GTBFlagStorageClearDeviceBlock
                    defaultValue:YES],

        [GTBFlagItem itemWithKey:@"gtb_bypass_ios_version_gate"
                           title:@"Обход проверки версии iOS"
                        subtitle:@"Разрешает TTKTabBarLiquidGlassConfig даже ниже iOS 26"
                          symbol:@"bolt.shield.fill"
                        category:GTBFlagCategoryCore
                     storageType:GTBFlagStorageBypassGate
                    defaultValue:NO],

        // === 1. SCROLL ANIMATION & TRANSITIONS ===
        [GTBFlagItem itemWithKey:@"ttk_tabbar_scroll_scale_enable"
                           title:@"Анимация сжатия при скролле"
                        subtitle:@"Уменьшение и масштабирование капсулы таббара при прокрутке"
                          symbol:@"arrow.up.and.down.and.sparkles"
                        category:GTBFlagCategoryScroll
                     storageType:GTBFlagStorageBool
                    defaultValue:YES],

        [GTBFlagItem itemWithKey:@"apply_scroll_compact_skip_sync_layout"
                           title:@"Плавный скролл (без sync layout)"
                        subtitle:@"Пропуск синхронного layoutIfNeeded при сжатии таббара"
                          symbol:@"speedometer"
                        category:GTBFlagCategoryScroll
                     storageType:GTBFlagStorageScrollPerfBool
                    defaultValue:YES],

        [GTBFlagItem itemWithKey:@"ttk_tabbar_liquid_glass_deferred_page_switch_enabled"
                           title:@"Отложенная смена вкладки"
                        subtitle:@"Сначала анимация стеклянной пилюли, затем переключение экрана"
                          symbol:@"capsule.fill"
                        category:GTBFlagCategoryScroll
                     storageType:GTBFlagStorageBool
                    defaultValue:YES],

        [GTBFlagItem itemWithKey:@"ttk_tabbar_fake_bar_glass_snapshot"
                           title:@"Стеклянный снапшот переходов"
                        subtitle:@"Сохраняет эффект стекла во время пуш/поп навигации"
                          symbol:@"camera.filters"
                        category:GTBFlagCategoryScroll
                     storageType:GTBFlagStorageBool
                    defaultValue:YES],

        [GTBFlagItem itemWithKey:@"ttk_tabbar_animator_transition_window"
                           title:@"Окно аниматора переходов"
                        subtitle:@"Сглаживает появление/скрытие таббара при переходах"
                          symbol:@"macwindow.on.rectangle"
                        category:GTBFlagCategoryScroll
                     storageType:GTBFlagStorageBool
                    defaultValue:YES],

        [GTBFlagItem itemWithKey:@"ttk_tabbar_transition_alpha_guard"
                           title:@"Защита альфы при переходах"
                        subtitle:@"Предотвращает мерцание прозрачности во время анимации"
                          symbol:@"shield.lefthalf.filled"
                        category:GTBFlagCategoryScroll
                     storageType:GTBFlagStorageBool
                    defaultValue:YES],

        [GTBFlagItem itemWithKey:@"feed_bottom_tab_theme_transition_opt_enabled"
                           title:@"Адаптация темы при скролле ленты"
                        subtitle:@"Плавное переключение светлого и тёмного стекла в ленте"
                          symbol:@"circle.lefthalf.filled"
                        category:GTBFlagCategoryScroll
                     storageType:GTBFlagStorageBool
                    defaultValue:YES],

        [GTBFlagItem itemWithKey:@"bottom_tab_animation_optimization_iOS"
                           title:@"Оптимизация анимаций таббара"
                        subtitle:@"Улучшенная плавность анимаций нижней панели на iOS"
                          symbol:@"wand.and.stars"
                        category:GTBFlagCategoryScroll
                     storageType:GTBFlagStorageBool
                    defaultValue:YES],

        [GTBFlagItem itemWithKey:@"tab_bar_animation_enable"
                           title:@"Базовые анимации таббара"
                        subtitle:@"Включает стандартные анимации кнопок и переключений"
                          symbol:@"play.circle.fill"
                        category:GTBFlagCategoryScroll
                     storageType:GTBFlagStorageBool
                    defaultValue:YES],

        // === 2. APPEARANCE & LAYOUT ===
        [GTBFlagItem itemWithKey:@"tabbar_button_text_disable"
                           title:@"Скрыть подписи под иконками"
                        subtitle:@"Компактный вид без текста — только стеклянные иконки"
                          symbol:@"textformat.abc.dottedunderline"
                        category:GTBFlagCategoryAppearance
                     storageType:GTBFlagStorageGlassConfigBool
                    defaultValue:NO],

        [GTBFlagItem itemWithKey:@"ttk_tabbar_liquid_glass_plus_button_size_fix"
                           title:@"Фикс размера кнопки «+»"
                        subtitle:@"Корректные пропорции центральной кнопки создания видео"
                          symbol:@"plus.app.fill"
                        category:GTBFlagCategoryAppearance
                     storageType:GTBFlagStorageBool
                    defaultValue:YES],

        [GTBFlagItem itemWithKey:@"ttk_tabbar_title_content_center"
                           title:@"Центрирование контента кнопок"
                        subtitle:@"Выравнивает иконки и заголовки точно по центру капсулы"
                          symbol:@"align.horizontal.center.fill"
                        category:GTBFlagCategoryAppearance
                     storageType:GTBFlagStorageBool
                    defaultValue:YES],

        [GTBFlagItem itemWithKey:@"icon_intrinsic_size_aspect_fit"
                           title:@"Пропорциональные иконки"
                        subtitle:@"Режим Aspect Fit для иконок внутри стеклянного таббара"
                          symbol:@"aspectratio.fill"
                        category:GTBFlagCategoryAppearance
                     storageType:GTBFlagStorageGlassConfigBool
                    defaultValue:YES],

        [GTBFlagItem itemWithKey:@"icon_intrinsic_size_skip_refresh"
                           title:@"Пропуск лишнего рефреша иконок"
                        subtitle:@"Убирает дёрганье при обновлении intrinsicContentSize"
                          symbol:@"arrow.clockwise.circle"
                        category:GTBFlagCategoryAppearance
                     storageType:GTBFlagStorageGlassConfigBool
                    defaultValue:YES],

        [GTBFlagItem itemWithKey:@"ttk_tabbar_liquid_glass_legacy_declared_icon_visible_height"
                           title:@"Классическая высота иконок"
                        subtitle:@"Использовать прежнюю высоту области видимости иконки"
                          symbol:@"arrow.up.and.down"
                        category:GTBFlagCategoryAppearance
                     storageType:GTBFlagStorageGlassConfigBool
                    defaultValue:NO],

        [GTBFlagItem itemWithKey:@"tab_bar_gradient_enable"
                           title:@"Градиентная подложка"
                        subtitle:@"Добавляет мягкий градиент за стеклянной панелью"
                          symbol:@"square.stack.3d.down.right.fill"
                        category:GTBFlagCategoryAppearance
                     storageType:GTBFlagStorageBool
                    defaultValue:NO],

        [GTBFlagItem itemWithKey:@"ttk_tabbar_liquid_glass_full_bar_background_tabs"
                           title:@"Сплошной фон стекла на вкладках"
                        subtitle:@"Полноширинная стеклянная подложка вместо отдельных пилюль"
                          symbol:@"rectangle.fill"
                        category:GTBFlagCategoryAppearance
                     storageType:GTBFlagStorageFullBarTabs
                    defaultValue:NO],

        // === 3. WINDOWING, IPAD & PERFORMANCE ===
        [GTBFlagItem itemWithKey:@"liquid_glass_chrome_geometry_cache"
                           title:@"Кэш геометрии рамки"
                        subtitle:@"Кэширует вычисления рамки Liquid Glass хрома"
                          symbol:@"memorychip"
                        category:GTBFlagCategoryAdvanced
                     storageType:GTBFlagStorageGlassConfigBool
                    defaultValue:YES],

        [GTBFlagItem itemWithKey:@"set_title_visible_layout_on_change"
                           title:@"Лейаут только при смене текста"
                        subtitle:@"Пересчитывает лейаут при реальном изменении видимости подписи"
                          symbol:@"rectangle.inset.filled"
                        category:GTBFlagCategoryAdvanced
                     storageType:GTBFlagStorageGlassConfigBool
                    defaultValue:YES],

        [GTBFlagItem itemWithKey:@"ttk_tabbar_non_fullscreen_liquid_glass_enabled"
                           title:@"Неполноэкранные окна (Split View)"
                        subtitle:@"Оставляет стеклянный таббар в режиме многозадачности"
                          symbol:@"rectangle.split.2x1.fill"
                        category:GTBFlagCategoryAdvanced
                     storageType:GTBFlagStorageBool
                    defaultValue:YES],

        [GTBFlagItem itemWithKey:@"ttk_tabbar_fold_screen_liquid_glass_enabled"
                           title:@"Поддержка Duo / Fold экранов"
                        subtitle:@"Включает Liquid Glass на складных/широких экранах"
                          symbol:@"rectangle.split.2x2.fill"
                        category:GTBFlagCategoryAdvanced
                     storageType:GTBFlagStorageBool
                    defaultValue:YES],

        [GTBFlagItem itemWithKey:@"vertical_tabbar_button_text_always_show"
                           title:@"Текст в вертикальном таббаре"
                        subtitle:@"Всегда отображать подписи в боковом/вертикальном режиме"
                          symbol:@"sidebar.left"
                        category:GTBFlagCategoryAdvanced
                     storageType:GTBFlagStorageGlassConfigBool
                    defaultValue:YES],

        [GTBFlagItem itemWithKey:@"ttk_tabbar_block_ipad_ios26_cancel_alpha_zero"
                           title:@"Фикс скрытия на iPad iOS 26"
                        subtitle:@"Блокирует ошибочное обнуление alpha таббара на iPad"
                          symbol:@"ipad"
                        category:GTBFlagCategoryAdvanced
                     storageType:GTBFlagStorageBool
                    defaultValue:YES],

        [GTBFlagItem itemWithKey:@"ttk_tabbar_allow_biz_alpha_write_during_transition"
                           title:@"Изменение alpha в переходах"
                        subtitle:@"Разрешает модулям менять прозрачность при переходах"
                          symbol:@"dial.low.fill"
                        category:GTBFlagCategoryAdvanced
                     storageType:GTBFlagStorageBool
                    defaultValue:NO],

        [GTBFlagItem itemWithKey:@"ttk_tabbar_allow_biz_hidden_write_during_nav"
                           title:@"Скрытие при навигации"
                        subtitle:@"Разрешает модулям управлять скрытием таббара в навигации"
                          symbol:@"eye.slash.fill"
                        category:GTBFlagCategoryAdvanced
                     storageType:GTBFlagStorageBool
                    defaultValue:NO],

        [GTBFlagItem itemWithKey:@"tux_intro_panel_lg_background_guard_enabled"
                           title:@"Защита фона интро-панелей"
                        subtitle:@"Корректная подложка Liquid Glass на всплывающих панелях"
                          symbol:@"rectangle.on.rectangle"
                        category:GTBFlagCategoryAdvanced
                     storageType:GTBFlagStorageBool
                    defaultValue:YES],
    ];

    self.items = list;
    NSMutableDictionary *map = [NSMutableDictionary dictionaryWithCapacity:list.count];
    for (GTBFlagItem *item in list) {
        map[item.key] = item;
    }
    self.itemsByKey = [map copy];
}

- (void)registerDefaultValues {
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    defaults[kGTBMasterKey] = @YES;
    for (GTBFlagItem *item in self.items) {
        defaults[[kGTBKeyPrefix stringByAppendingString:item.key]] = @(item.defaultValue);
    }
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (BOOL)masterEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kGTBMasterKey];
}

- (void)setMasterEnabled:(BOOL)masterEnabled {
    [[NSUserDefaults standardUserDefaults] setBool:masterEnabled forKey:kGTBMasterKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:GTBFlagsDidChangeNotification object:nil];
}

- (NSArray<GTBFlagItem *> *)allItems {
    return self.items;
}

- (NSArray<GTBFlagItem *> *)itemsForCategory:(GTBFlagCategory)category {
    NSMutableArray *result = [NSMutableArray array];
    for (GTBFlagItem *item in self.items) {
        if (item.category == category) {
            [result addObject:item];
        }
    }
    return result;
}

- (NSString *)titleForCategory:(GTBFlagCategory)category {
    switch (category) {
        case GTBFlagCategoryCore: return @"Стеклянный таббар";
        case GTBFlagCategoryScroll: return @"Анимация при скролле и переходы";
        case GTBFlagCategoryAppearance: return @"Внешний вид и иконки";
        case GTBFlagCategoryAdvanced: return @"Окна, iPad и производительность";
    }
}

- (NSString *)subtitleForCategory:(GTBFlagCategory)category {
    switch (category) {
        case GTBFlagCategoryCore: return @"Основные A/B флаги активации Liquid Glass";
        case GTBFlagCategoryScroll: return @"Масштабирование капсулы, плавность и переходы";
        case GTBFlagCategoryAppearance: return @"Подписи, кнопка «+», отступы и фон";
        case GTBFlagCategoryAdvanced: return @"Кэширование, Split View, Fold и фиксы iPad";
    }
}

- (NSString *)symbolForCategory:(GTBFlagCategory)category {
    switch (category) {
        case GTBFlagCategoryCore: return @"sparkles.rectangle.stack.fill";
        case GTBFlagCategoryScroll: return @"arrow.up.and.down.circle.fill";
        case GTBFlagCategoryAppearance: return @"paintbrush.fill";
        case GTBFlagCategoryAdvanced: return @"gearshape.2.fill";
    }
}

- (BOOL)isFlagEnabled:(NSString *)key {
    return [[NSUserDefaults standardUserDefaults] boolForKey:[kGTBKeyPrefix stringByAppendingString:key]];
}

- (void)setFlagEnabled:(BOOL)enabled forKey:(NSString *)key {
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:[kGTBKeyPrefix stringByAppendingString:key]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:GTBFlagsDidChangeNotification object:nil];
}

- (NSUInteger)enabledCount {
    if (!self.masterEnabled) return 0;
    NSUInteger count = 0;
    for (GTBFlagItem *item in self.items) {
        if ([self isFlagEnabled:item.key]) count++;
    }
    return count;
}

- (NSUInteger)totalCount {
    return self.items.count;
}

- (void)applyPresetAllGlassAndAnimations {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setBool:YES forKey:kGTBMasterKey];
    for (GTBFlagItem *item in self.items) {
        BOOL val = item.defaultValue;
        if (item.category == GTBFlagCategoryCore || item.category == GTBFlagCategoryScroll) {
            val = YES;
        }
        [ud setBool:val forKey:[kGTBKeyPrefix stringByAppendingString:item.key]];
    }
    [ud synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:GTBFlagsDidChangeNotification object:nil];
}

- (void)applyPresetMinimalNoLabels {
    [self applyPresetAllGlassAndAnimations];
    [self setFlagEnabled:YES forKey:@"tabbar_button_text_disable"];
    [self setFlagEnabled:NO forKey:@"ttk_tabbar_liquid_glass_full_bar_background_tabs"];
}

- (void)resetToDefaults {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setBool:YES forKey:kGTBMasterKey];
    for (GTBFlagItem *item in self.items) {
        [ud setBool:item.defaultValue forKey:[kGTBKeyPrefix stringByAppendingString:item.key]];
    }
    [ud synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:GTBFlagsDidChangeNotification object:nil];
}

- (NSDictionary<NSString *, id> *)buildLiquidGlassConfigDict {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (GTBFlagItem *item in self.items) {
        if (item.storageType == GTBFlagStorageGlassConfigBool) {
            dict[item.key] = @([self isFlagEnabled:item.key]);
        }
    }
    // Mirror the 3 core booleans that TTKTabBarLiquidGlassConfig also checks inside config dict
    dict[@"ttk_tabbar_liquid_glass_enabled"] = @([self isFlagEnabled:@"ttk_tabbar_liquid_glass_enabled"]);
    dict[@"ttk_tabbar_fold_screen_liquid_glass_enabled"] = @([self isFlagEnabled:@"ttk_tabbar_fold_screen_liquid_glass_enabled"]);
    dict[@"ttk_tabbar_non_fullscreen_liquid_glass_enabled"] = @([self isFlagEnabled:@"ttk_tabbar_non_fullscreen_liquid_glass_enabled"]);
    return [dict copy];
}

- (NSDictionary<NSString *, id> *)buildScrollCompactPerfConfigDict {
    return @{
        @"apply_scroll_compact_skip_sync_layout": @([self isFlagEnabled:@"apply_scroll_compact_skip_sync_layout"]),
    };
}

- (nullable id)overrideValueForABKey:(NSString *)key {
    if (!self.masterEnabled || key.length == 0) return nil;

    if ([key isEqualToString:@"ttk_tabbar_liquid_glass_config"]) {
        return [self buildLiquidGlassConfigDict];
    }
    if ([key isEqualToString:@"ttk_tabbar_scroll_compact_perf_config"]) {
        return [self buildScrollCompactPerfConfigDict];
    }

    GTBFlagItem *item = self.itemsByKey[key];
    if (!item) return nil;

    BOOL on = [self isFlagEnabled:key];
    switch (item.storageType) {
        case GTBFlagStorageBool:
            return @(on);
        case GTBFlagStorageFullBarTabs:
            return on ? @[ @"homepage_hot", @"homepage_follow", @"homepage_friends", @"homepage_shop", @"notification_notice", @"user_profile", @"*" ] : @[];
        case GTBFlagStorageClearDeviceBlock:
            return on ? @[] : nil;
        case GTBFlagStorageTuxVersions:
            return on ? @{ @"tabBar": @2, @"button": @2, @"menu": @2, @"intro_panel": @2 } : @{};
        case GTBFlagStorageGlassConfigBool:
        case GTBFlagStorageScrollPerfBool:
        case GTBFlagStorageBypassGate:
            return nil;
    }
}

- (NSDictionary<NSString *, id> *)overriddenABDictionary {
    if (!self.masterEnabled) return @{};

    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    for (GTBFlagItem *item in self.items) {
        id val = [self overrideValueForABKey:item.key];
        if (val) {
            result[item.key] = val;
        }
    }
    result[@"ttk_tabbar_liquid_glass_config"] = [self buildLiquidGlassConfigDict];
    result[@"ttk_tabbar_scroll_compact_perf_config"] = [self buildScrollCompactPerfConfigDict];
    return [result copy];
}

- (NSDictionary *)dictionaryByApplyingOverridesToDictionary:(nullable NSDictionary *)source {
    if (!self.masterEnabled) return source ?: @{};

    NSMutableDictionary *merged = source ? [source mutableCopy] : [NSMutableDictionary dictionary];
    NSDictionary *overrides = [self overriddenABDictionary];
    [overrides enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSDictionary class]] && [merged[key] isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *sub = [merged[key] mutableCopy];
            [sub addEntriesFromDictionary:(NSDictionary *)obj];
            merged[key] = [sub copy];
        } else {
            merged[key] = obj;
        }
    }];
    return [merged copy];
}

@end
