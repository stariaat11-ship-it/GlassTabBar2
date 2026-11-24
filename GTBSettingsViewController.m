#import "GTBSettingsViewController.h"
#import "GTBFlagManager.h"
#import <QuartzCore/QuartzCore.h>

@interface GTBFlagCell : UITableViewCell
@property (nonatomic, strong) UIVisualEffectView *cardBlurView;
@property (nonatomic, strong) UIView *iconBadgeView;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *keyBadgeLabel;
@property (nonatomic, strong) UISwitch *toggleSwitch;
@property (nonatomic, copy) void (^onToggle)(BOOL isOn);
@end

@implementation GTBFlagCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterial];
        _cardBlurView = [[UIVisualEffectView alloc] initWithEffect:blur];
        _cardBlurView.translatesAutoresizingMaskIntoConstraints = NO;
        _cardBlurView.layer.cornerRadius = 18.0;
        _cardBlurView.layer.cornerCurve = kCACornerCurveContinuous;
        _cardBlurView.clipsToBounds = YES;
        _cardBlurView.layer.borderWidth = 0.75;
        _cardBlurView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.18].CGColor;
        [self.contentView addSubview:_cardBlurView];

        _iconBadgeView = [[UIView alloc] init];
        _iconBadgeView.translatesAutoresizingMaskIntoConstraints = NO;
        _iconBadgeView.layer.cornerRadius = 11.0;
        _iconBadgeView.layer.cornerCurve = kCACornerCurveContinuous;
        [_cardBlurView.contentView addSubview:_iconBadgeView];

        _iconImageView = [[UIImageView alloc] init];
        _iconImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _iconImageView.contentMode = UIViewContentModeScaleAspectFit;
        _iconImageView.tintColor = [UIColor whiteColor];
        [_iconBadgeView addSubview:_iconImageView];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.font = [UIFont systemFontOfSize:15.5 weight:UIFontWeightSemibold];
        _titleLabel.textColor = [UIColor labelColor];
        _titleLabel.numberOfLines = 0;

        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _subtitleLabel.font = [UIFont systemFontOfSize:12.5 weight:UIFontWeightRegular];
        _subtitleLabel.textColor = [UIColor secondaryLabelColor];
        _subtitleLabel.numberOfLines = 0;

        _keyBadgeLabel = [[UILabel alloc] init];
        _keyBadgeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _keyBadgeLabel.font = [UIFont monospacedSystemFontOfSize:10.5 weight:UIFontWeightMedium];
        _keyBadgeLabel.textColor = [UIColor systemCyanColor];
        _keyBadgeLabel.numberOfLines = 0;

        UIStackView *textStack = [[UIStackView alloc] initWithArrangedSubviews:@[_titleLabel, _subtitleLabel, _keyBadgeLabel]];
        textStack.translatesAutoresizingMaskIntoConstraints = NO;
        textStack.axis = UILayoutConstraintAxisVertical;
        textStack.spacing = 3.0;
        [_cardBlurView.contentView addSubview:textStack];

        _toggleSwitch = [[UISwitch alloc] init];
        _toggleSwitch.translatesAutoresizingMaskIntoConstraints = NO;
        _toggleSwitch.onTintColor = [UIColor colorWithRed:0.18 green:0.75 blue:0.96 alpha:1.0];
        [_toggleSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        [_cardBlurView.contentView addSubview:_toggleSwitch];

        [NSLayoutConstraint activateConstraints:@[
            [_cardBlurView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:4.5],
            [_cardBlurView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-4.5],
            [_cardBlurView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16.0],
            [_cardBlurView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16.0],

            [_iconBadgeView.leadingAnchor constraintEqualToAnchor:_cardBlurView.contentView.leadingAnchor constant:14.0],
            [_iconBadgeView.centerYAnchor constraintEqualToAnchor:_cardBlurView.contentView.centerYAnchor],
            [_iconBadgeView.widthAnchor constraintEqualToConstant:36.0],
            [_iconBadgeView.heightAnchor constraintEqualToConstant:36.0],

            [_iconImageView.centerXAnchor constraintEqualToAnchor:_iconBadgeView.centerXAnchor],
            [_iconImageView.centerYAnchor constraintEqualToAnchor:_iconBadgeView.centerYAnchor],
            [_iconImageView.widthAnchor constraintEqualToConstant:19.0],
            [_iconImageView.heightAnchor constraintEqualToConstant:19.0],

            [_toggleSwitch.trailingAnchor constraintEqualToAnchor:_cardBlurView.contentView.trailingAnchor constant:-14.0],
            [_toggleSwitch.centerYAnchor constraintEqualToAnchor:_cardBlurView.contentView.centerYAnchor],

            [textStack.leadingAnchor constraintEqualToAnchor:_iconBadgeView.trailingAnchor constant:12.0],
            [textStack.trailingAnchor constraintEqualToAnchor:_toggleSwitch.leadingAnchor constant:-10.0],
            [textStack.topAnchor constraintEqualToAnchor:_cardBlurView.contentView.topAnchor constant:12.0],
            [textStack.bottomAnchor constraintEqualToAnchor:_cardBlurView.contentView.bottomAnchor constant:-12.0],
        ]];
    }
    return self;
}

- (void)switchChanged:(UISwitch *)sender {
    if (self.onToggle) {
        self.onToggle(sender.isOn);
    }
}

- (void)configureWithItem:(GTBFlagItem *)item enabled:(BOOL)enabled masterActive:(BOOL)masterActive {
    self.titleLabel.text = item.title;
    self.subtitleLabel.text = item.subtitle;
    self.keyBadgeLabel.text = item.key;

    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightSemibold];
    UIImage *img = [UIImage systemImageNamed:item.symbolName withConfiguration:cfg];
    if (!img) {
        img = [UIImage systemImageNamed:@"switch.2" withConfiguration:cfg];
    }
    self.iconImageView.image = img;

    UIColor *accent = [self accentColorForCategory:item.category];
    self.iconBadgeView.backgroundColor = enabled ? accent : [UIColor tertiarySystemFillColor];
    self.iconImageView.tintColor = enabled ? [UIColor whiteColor] : [UIColor secondaryLabelColor];
    self.keyBadgeLabel.textColor = enabled ? accent : [UIColor tertiaryLabelColor];

    self.toggleSwitch.on = enabled;
    self.toggleSwitch.enabled = masterActive;
    self.cardBlurView.alpha = masterActive ? 1.0 : 0.55;
}

- (UIColor *)accentColorForCategory:(GTBFlagCategory)category {
    switch (category) {
        case GTBFlagCategoryCore:
            return [UIColor colorWithRed:0.15 green:0.68 blue:0.98 alpha:1.0];
        case GTBFlagCategoryScroll:
            return [UIColor colorWithRed:0.46 green:0.38 blue:0.98 alpha:1.0];
        case GTBFlagCategoryAppearance:
            return [UIColor colorWithRed:0.96 green:0.31 blue:0.58 alpha:1.0];
        case GTBFlagCategoryAdvanced:
            return [UIColor colorWithRed:0.16 green:0.78 blue:0.64 alpha:1.0];
    }
}

@end

@interface GTBSettingsViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) CAGradientLayer *bgGradient;
@property (nonatomic, strong) UILabel *statusBadgeLabel;
@property (nonatomic, strong) UISwitch *masterSwitch;
@property (nonatomic, strong) UILabel *toastLabel;
@end

@implementation GTBSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Glass TabBar";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    [self setupBackgroundGradient];
    [self setupNavigationBar];
    [self setupTableView];
    [self setupHeaderView];
    [self refreshHeaderState];

#if defined(__IPHONE_17_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 170000
    if (@available(iOS 17.0, *)) {
        __weak typeof(self) weakSelf = self;
        [self registerForTraitChanges:@[[UITraitUserInterfaceStyle class]] withHandler:^(__kindof id<UITraitEnvironment> traitEnvironment, UITraitCollection *previousCollection) {
            [weakSelf updateGradientColors];
        }];
    }
#endif
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.bgGradient.frame = self.view.bounds;
}

- (void)setupBackgroundGradient {
    self.bgGradient = [CAGradientLayer layer];
    self.bgGradient.startPoint = CGPointMake(0.0, 0.0);
    self.bgGradient.endPoint = CGPointMake(1.0, 1.0);
    [self updateGradientColors];
    [self.view.layer insertSublayer:self.bgGradient atIndex:0];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self updateGradientColors];
}

- (void)updateGradientColors {
    BOOL isDark = (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark);
    if (isDark) {
        self.bgGradient.colors = @[
            (id)[UIColor colorWithRed:0.05 green:0.07 blue:0.13 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:0.08 green:0.06 blue:0.16 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:0.03 green:0.09 blue:0.14 alpha:1.0].CGColor,
        ];
    } else {
        self.bgGradient.colors = @[
            (id)[UIColor colorWithRed:0.92 green:0.96 blue:1.00 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:0.95 green:0.93 blue:0.99 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:0.90 green:0.97 blue:0.98 alpha:1.0].CGColor,
        ];
    }
}

- (void)setupNavigationBar {
    if (self.presentingViewController && (!self.navigationController || self.navigationController.viewControllers.count <= 1)) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose
                                                                                              target:self
                                                                                              action:@selector(closeTapped)];
    }

    UIBarButtonItem *restartBtn = [[UIBarButtonItem alloc] initWithTitle:@"Рестарт"
                                                                   style:UIBarButtonItemStyleDone
                                                                  target:self
                                                                  action:@selector(restartTapped)];
    restartBtn.tintColor = [UIColor colorWithRed:0.15 green:0.68 blue:0.98 alpha:1.0];
    self.navigationItem.rightBarButtonItem = restartBtn;
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 84.0;
    [self.tableView registerClass:[GTBFlagCell class] forCellReuseIdentifier:@"GTBFlagCell"];
    [self.view addSubview:self.tableView];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    ]];
}

- (void)setupHeaderView {
    UIView *headerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 250.0)];

    UIVisualEffectView *heroCard = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial]];
    heroCard.translatesAutoresizingMaskIntoConstraints = NO;
    heroCard.layer.cornerRadius = 24.0;
    heroCard.layer.cornerCurve = kCACornerCurveContinuous;
    heroCard.clipsToBounds = YES;
    heroCard.layer.borderWidth = 1.0;
    heroCard.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.25].CGColor;
    [headerContainer addSubview:heroCard];

    // Glowing icon circle
    UIView *logoBg = [[UIView alloc] init];
    logoBg.translatesAutoresizingMaskIntoConstraints = NO;
    logoBg.layer.cornerRadius = 16.0;
    logoBg.layer.cornerCurve = kCACornerCurveContinuous;
    logoBg.backgroundColor = [UIColor colorWithRed:0.15 green:0.68 blue:0.98 alpha:1.0];
    [heroCard.contentView addSubview:logoBg];

    UIImageSymbolConfiguration *logoCfg = [UIImageSymbolConfiguration configurationWithPointSize:24 weight:UIImageSymbolWeightBold];
    UIImageView *logoImg = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"sparkles.rectangle.stack.fill" withConfiguration:logoCfg]];
    logoImg.translatesAutoresizingMaskIntoConstraints = NO;
    logoImg.tintColor = [UIColor whiteColor];
    logoImg.contentMode = UIViewContentModeScaleAspectFit;
    [logoBg addSubview:logoImg];

    UILabel *heroTitle = [[UILabel alloc] init];
    heroTitle.translatesAutoresizingMaskIntoConstraints = NO;
    heroTitle.text = @"Liquid Glass TabBar";
    heroTitle.font = [UIFont systemFontOfSize:20.0 weight:UIFontWeightBold];
    heroTitle.textColor = [UIColor labelColor];

    UILabel *heroSub = [[UILabel alloc] init];
    heroSub.translatesAutoresizingMaskIntoConstraints = NO;
    heroSub.text = @"TikTok 47.9.0 • A/B-флаги стекла и скролла";
    heroSub.font = [UIFont systemFontOfSize:12.5 weight:UIFontWeightMedium];
    heroSub.textColor = [UIColor secondaryLabelColor];

    self.statusBadgeLabel = [[UILabel alloc] init];
    self.statusBadgeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusBadgeLabel.font = [UIFont systemFontOfSize:11.5 weight:UIFontWeightSemibold];
    self.statusBadgeLabel.layer.cornerRadius = 9.0;
    self.statusBadgeLabel.layer.masksToBounds = YES;
    self.statusBadgeLabel.textAlignment = NSTextAlignmentCenter;
    self.statusBadgeLabel.adjustsFontSizeToFitWidth = YES;
    self.statusBadgeLabel.minimumScaleFactor = 0.72;

    UIStackView *titleStack = [[UIStackView alloc] initWithArrangedSubviews:@[heroTitle, heroSub]];
    titleStack.translatesAutoresizingMaskIntoConstraints = NO;
    titleStack.axis = UILayoutConstraintAxisVertical;
    titleStack.spacing = 2.0;
    [heroCard.contentView addSubview:titleStack];
    [heroCard.contentView addSubview:self.statusBadgeLabel];

    // Master switch row
    UIView *divider = [[UIView alloc] init];
    divider.translatesAutoresizingMaskIntoConstraints = NO;
    divider.backgroundColor = [[UIColor separatorColor] colorWithAlphaComponent:0.35];
    [heroCard.contentView addSubview:divider];

    UILabel *masterTitle = [[UILabel alloc] init];
    masterTitle.translatesAutoresizingMaskIntoConstraints = NO;
    masterTitle.text = @"Включить твик Glass TabBar";
    masterTitle.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];
    masterTitle.textColor = [UIColor labelColor];
    [heroCard.contentView addSubview:masterTitle];

    self.masterSwitch = [[UISwitch alloc] init];
    self.masterSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    self.masterSwitch.onTintColor = [UIColor colorWithRed:0.15 green:0.68 blue:0.98 alpha:1.0];
    self.masterSwitch.on = [GTBFlagManager sharedManager].masterEnabled;
    [self.masterSwitch addTarget:self action:@selector(masterSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    [heroCard.contentView addSubview:self.masterSwitch];

    // Presets bar
    UIButton *btnAll = [self presetButtonWithTitle:@"Всё + Анимации"
                                            color:[UIColor colorWithRed:0.15 green:0.68 blue:0.98 alpha:0.20]
                                        textColor:[UIColor colorWithRed:0.15 green:0.68 blue:0.98 alpha:1.0]
                                           action:@selector(presetAllTapped)];
    UIButton *btnMinimal = [self presetButtonWithTitle:@"Без текста"
                                                color:[UIColor colorWithRed:0.55 green:0.42 blue:0.98 alpha:0.20]
                                            textColor:[UIColor colorWithRed:0.55 green:0.42 blue:0.98 alpha:1.0]
                                               action:@selector(presetMinimalTapped)];
    UIButton *btnReset = [self presetButtonWithTitle:@"Сброс"
                                              color:[[UIColor systemRedColor] colorWithAlphaComponent:0.16]
                                          textColor:[UIColor systemRedColor]
                                             action:@selector(presetResetTapped)];

    UIStackView *presetStack = [[UIStackView alloc] initWithArrangedSubviews:@[btnAll, btnMinimal, btnReset]];
    presetStack.translatesAutoresizingMaskIntoConstraints = NO;
    presetStack.axis = UILayoutConstraintAxisHorizontal;
    presetStack.spacing = 8.0;
    presetStack.distribution = UIStackViewDistributionFillProportionally;
    [heroCard.contentView addSubview:presetStack];

    [NSLayoutConstraint activateConstraints:@[
        [heroCard.topAnchor constraintEqualToAnchor:headerContainer.topAnchor constant:12.0],
        [heroCard.bottomAnchor constraintEqualToAnchor:headerContainer.bottomAnchor constant:-8.0],
        [heroCard.leadingAnchor constraintEqualToAnchor:headerContainer.leadingAnchor constant:16.0],
        [heroCard.trailingAnchor constraintEqualToAnchor:headerContainer.trailingAnchor constant:-16.0],

        [logoBg.topAnchor constraintEqualToAnchor:heroCard.contentView.topAnchor constant:16.0],
        [logoBg.leadingAnchor constraintEqualToAnchor:heroCard.contentView.leadingAnchor constant:16.0],
        [logoBg.widthAnchor constraintEqualToConstant:48.0],
        [logoBg.heightAnchor constraintEqualToConstant:48.0],

        [logoImg.centerXAnchor constraintEqualToAnchor:logoBg.centerXAnchor],
        [logoImg.centerYAnchor constraintEqualToAnchor:logoBg.centerYAnchor],
        [logoImg.widthAnchor constraintEqualToConstant:28.0],
        [logoImg.heightAnchor constraintEqualToConstant:28.0],

        [titleStack.leadingAnchor constraintEqualToAnchor:logoBg.trailingAnchor constant:12.0],
        [titleStack.trailingAnchor constraintEqualToAnchor:heroCard.contentView.trailingAnchor constant:-16.0],
        [titleStack.centerYAnchor constraintEqualToAnchor:logoBg.centerYAnchor],

        [self.statusBadgeLabel.topAnchor constraintEqualToAnchor:logoBg.bottomAnchor constant:12.0],
        [self.statusBadgeLabel.leadingAnchor constraintEqualToAnchor:heroCard.contentView.leadingAnchor constant:16.0],
        [self.statusBadgeLabel.trailingAnchor constraintLessThanOrEqualToAnchor:heroCard.contentView.trailingAnchor constant:-16.0],
        [self.statusBadgeLabel.heightAnchor constraintEqualToConstant:24.0],

        [divider.topAnchor constraintEqualToAnchor:self.statusBadgeLabel.bottomAnchor constant:12.0],
        [divider.leadingAnchor constraintEqualToAnchor:heroCard.contentView.leadingAnchor constant:16.0],
        [divider.trailingAnchor constraintEqualToAnchor:heroCard.contentView.trailingAnchor constant:-16.0],
        [divider.heightAnchor constraintEqualToConstant:0.5],

        [masterTitle.topAnchor constraintEqualToAnchor:divider.bottomAnchor constant:12.0],
        [masterTitle.leadingAnchor constraintEqualToAnchor:heroCard.contentView.leadingAnchor constant:16.0],
        [masterTitle.trailingAnchor constraintEqualToAnchor:self.masterSwitch.leadingAnchor constant:-10.0],

        [self.masterSwitch.centerYAnchor constraintEqualToAnchor:masterTitle.centerYAnchor],
        [self.masterSwitch.trailingAnchor constraintEqualToAnchor:heroCard.contentView.trailingAnchor constant:-16.0],

        [presetStack.topAnchor constraintEqualToAnchor:masterTitle.bottomAnchor constant:14.0],
        [presetStack.leadingAnchor constraintEqualToAnchor:heroCard.contentView.leadingAnchor constant:16.0],
        [presetStack.trailingAnchor constraintEqualToAnchor:heroCard.contentView.trailingAnchor constant:-16.0],
        [presetStack.heightAnchor constraintEqualToConstant:36.0],
    ]];

    self.tableView.tableHeaderView = headerContainer;
}

- (UIButton *)presetButtonWithTitle:(NSString *)title color:(UIColor *)bg textColor:(UIColor *)fg action:(SEL)sel {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:fg forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold];
    btn.backgroundColor = bg;
    btn.layer.cornerRadius = 11.0;
    btn.layer.cornerCurve = kCACornerCurveContinuous;
    [btn addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)refreshHeaderState {
    GTBFlagManager *mgr = [GTBFlagManager sharedManager];
    self.masterSwitch.on = mgr.masterEnabled;
    if (mgr.masterEnabled) {
        self.statusBadgeLabel.text = [NSString stringWithFormat:@"  Активно подфункций: %lu из %lu  •  После правок нажмите «Рестарт»  ",
                                      (unsigned long)mgr.enabledCount, (unsigned long)mgr.totalCount];
        self.statusBadgeLabel.backgroundColor = [[UIColor systemGreenColor] colorWithAlphaComponent:0.18];
        self.statusBadgeLabel.textColor = [UIColor systemGreenColor];
    } else {
        self.statusBadgeLabel.text = @"  Отключено • Используются стандартные A/B-флаги сервера  ";
        self.statusBadgeLabel.backgroundColor = [[UIColor systemOrangeColor] colorWithAlphaComponent:0.18];
        self.statusBadgeLabel.textColor = [UIColor systemOrangeColor];
    }
}

#pragma mark - Actions

- (void)closeTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)masterSwitchChanged:(UISwitch *)sender {
    [GTBFlagManager sharedManager].masterEnabled = sender.isOn;
    [self refreshHeaderState];
    [self.tableView reloadData];
}

- (void)presetAllTapped {
    [[GTBFlagManager sharedManager] applyPresetAllGlassAndAnimations];
    [self refreshHeaderState];
    [self.tableView reloadData];
    [self showToast:@"Пресет «Всё + Анимации» применён"];
}

- (void)presetMinimalTapped {
    [[GTBFlagManager sharedManager] applyPresetMinimalNoLabels];
    [self refreshHeaderState];
    [self.tableView reloadData];
    [self showToast:@"Пресет «Стекло без текста» применён"];
}

- (void)presetResetTapped {
    [[GTBFlagManager sharedManager] resetToDefaults];
    [self refreshHeaderState];
    [self.tableView reloadData];
    [self showToast:@"Настройки сброшены по умолчанию"];
}

- (void)restartTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Перезапустить TikTok?"
                                                                   message:@"Таббар инициализируется при старте приложения. Перезапустите TikTok, чтобы изменения A/B-флагов вступили в силу."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Перезапустить" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        exit(0);
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showToast:(NSString *)message {
    [self.toastLabel removeFromSuperview];
    UILabel *label = [[UILabel alloc] init];
    label.text = [NSString stringWithFormat:@"  %@  ", message];
    label.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.78];
    label.layer.cornerRadius = 14.0;
    label.layer.masksToBounds = YES;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:label];
    self.toastLabel = label;

    [NSLayoutConstraint activateConstraints:@[
        [label.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [label.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-18.0],
        [label.heightAnchor constraintEqualToConstant:34.0],
    ]];

    label.alpha = 0.0;
    [UIView animateWithDuration:0.2 animations:^{
        label.alpha = 1.0;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.25 animations:^{
                label.alpha = 0.0;
            } completion:^(BOOL done) {
                [label removeFromSuperview];
            }];
        });
    }];
}

#pragma mark - UITableViewDataSource & Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[GTBFlagManager sharedManager] itemsForCategory:(GTBFlagCategory)section].count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    GTBFlagManager *mgr = [GTBFlagManager sharedManager];
    GTBFlagCategory cat = (GTBFlagCategory)section;

    UIView *header = [[UIView alloc] init];
    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:15 weight:UIImageSymbolWeightBold];
    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:[mgr symbolForCategory:cat] withConfiguration:cfg]];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    icon.tintColor = [UIColor colorWithRed:0.15 green:0.68 blue:0.98 alpha:1.0];

    UILabel *title = [[UILabel alloc] init];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = [mgr titleForCategory:cat];
    title.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightBold];
    title.textColor = [UIColor labelColor];

    UILabel *sub = [[UILabel alloc] init];
    sub.translatesAutoresizingMaskIntoConstraints = NO;
    sub.text = [mgr subtitleForCategory:cat];
    sub.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];
    sub.textColor = [UIColor secondaryLabelColor];

    [header addSubview:icon];
    [header addSubview:title];
    [header addSubview:sub];

    [NSLayoutConstraint activateConstraints:@[
        [icon.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:20.0],
        [icon.topAnchor constraintEqualToAnchor:header.topAnchor constant:14.0],
        [icon.widthAnchor constraintEqualToConstant:20.0],
        [icon.heightAnchor constraintEqualToConstant:20.0],

        [title.leadingAnchor constraintEqualToAnchor:icon.trailingAnchor constant:8.0],
        [title.centerYAnchor constraintEqualToAnchor:icon.centerYAnchor],
        [title.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-20.0],

        [sub.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:20.0],
        [sub.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:3.0],
        [sub.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-20.0],
        [sub.bottomAnchor constraintEqualToAnchor:header.bottomAnchor constant:-6.0],
    ]];

    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section {
    return 56.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GTBFlagCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GTBFlagCell" forIndexPath:indexPath];
    GTBFlagManager *mgr = [GTBFlagManager sharedManager];
    GTBFlagItem *item = [mgr itemsForCategory:(GTBFlagCategory)indexPath.section][indexPath.row];
    BOOL enabled = [mgr isFlagEnabled:item.key];
    [cell configureWithItem:item enabled:enabled masterActive:mgr.masterEnabled];

    __weak typeof(self) weakSelf = self;
    cell.onToggle = ^(BOOL isOn) {
        [mgr setFlagEnabled:isOn forKey:item.key];
        [weakSelf refreshHeaderState];
        [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    };
    return cell;
}

@end
