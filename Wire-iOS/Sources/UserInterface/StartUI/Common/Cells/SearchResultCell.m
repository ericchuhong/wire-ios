// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


#import "SearchResultCell.h"
#import "WAZUIMagiciOS.h"
#import <PureLayout.h>
#import "UIView+MTAnimation.h"
#import "BadgeUserImageView.h"
#import "UIImage+ZetaIconsNeue.h"
#import "zmessaging+iOS.h"
#import <ZMCDataModel/ZMBareUser.h>

@interface SearchResultCell () <ZMCommonContactsSearchDelegate>
@property (nonatomic, strong) UIView *gesturesView;
@property (nonatomic, strong) BadgeUserImageView *badgeUserImageView;
@property (nonatomic, strong) UIImageView *conversationImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIView *avatarContainer;
@property (nonatomic, strong) UIButton *hideButton;
@property (nonatomic, strong) IconButton *instantConnectButton;

@property (nonatomic, strong) UIView *avatarOverlay;
@property (nonatomic, strong) UIImageView *successCheckmark;

@property (nonatomic, assign) BOOL initialConstraintsCreated;
@property (nonatomic, strong) NSLayoutConstraint *avatarViewSizeConstraint;
@property (nonatomic, strong) NSLayoutConstraint *conversationImageViewSize;
@property (nonatomic, strong) NSLayoutConstraint *nameLabelTopConstraint;
@property (nonatomic, strong) NSLayoutConstraint *nameLabelVerticalConstraint;
@property (nonatomic, strong) NSLayoutConstraint *nameRightMarginConstraint;
@property (nonatomic, strong) NSLayoutConstraint *subtitleRightMarginConstraint;

@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, weak)   id<ZMCommonContactsSearchToken> recentSearchToken;
@end

@implementation SearchResultCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.translatesAutoresizingMaskIntoConstraints = NO;

        @weakify(self);
        self.overscrollAction = ^(SwipeMenuCollectionCell *cell) {
            @strongify(self);
            if (self.hideSelectedAction != nil) {
                self.hideSelectedAction(self);
            }
            [self.hideButton setTitle:[NSLocalizedString(@"peoplepicker.hide_search_result_progress", @"") uppercaseString] forState:UIControlStateNormal];
        };

        self.gesturesView = [[UIView alloc] initForAutoLayout];
        self.gesturesView.backgroundColor = [UIColor clearColor];
        [self.swipeView addSubview:self.gesturesView];

        self.avatarContainer = [[UIView alloc] initForAutoLayout];
        self.avatarContainer.userInteractionEnabled = NO;
        self.avatarContainer.opaque = NO;
        [self.swipeView addSubview:self.avatarContainer];

        self.conversationImageView = [[UIImageView alloc] initForAutoLayout];
        self.conversationImageView.opaque = NO;
        [self.avatarContainer addSubview:self.conversationImageView];

        self.nameLabel = [[UILabel alloc] initForAutoLayout];
        self.nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.nameLabel.textAlignment = NSTextAlignmentLeft;
        [self.swipeView addSubview:self.nameLabel];

        self.subtitleLabel = [[UILabel alloc] initForAutoLayout];
        [self.swipeView addSubview:self.subtitleLabel];
        self.subtitleLabel.textColor = [UIColor colorWithWhite:1.0f alpha:0.4f];
        self.subtitleLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_light"];

        UITapGestureRecognizer *doubleTapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        doubleTapper.numberOfTapsRequired = 2;
        doubleTapper.numberOfTouchesRequired = 1;
        doubleTapper.delaysTouchesBegan = YES;
        [self.gesturesView addGestureRecognizer:doubleTapper];

        self.hideButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.hideButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.hideButton addTarget:self action:@selector(hideSearchResult:) forControlEvents:UIControlEventTouchUpInside];
        [self.hideButton setTitle:[NSLocalizedString(@"peoplepicker.hide_search_result", @"") uppercaseString] forState:UIControlStateNormal];
        self.hideButton.titleLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_bold"];
        [self.hideButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.hideButton.backgroundColor = [UIColor clearColor];
        [self.menuView addSubview:self.hideButton];
        
        self.instantConnectButton = [[IconButton alloc] initForAutoLayout];
        self.instantConnectButton.borderWidth = 0;
        self.instantConnectButton.adjustsImageWhenDisabled = NO;
        [self.instantConnectButton setIconColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.instantConnectButton setIcon:ZetaIconTypePlusCircled withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
        
        [self.instantConnectButton addTarget:self action:@selector(instantConnect:) forControlEvents:UIControlEventTouchUpInside];
        self.instantConnectButton.accessibilityIdentifier = @"instantPlusConnectButton";
        [self.swipeView addSubview:self.instantConnectButton];

        [self createUserImageView];
        [self setNeedsUpdateConstraints];
        [self updateForContext];
    }
    return self;
}

- (void)createUserImageView
{
    [self.badgeUserImageView removeFromSuperview];

    self.badgeUserImageView = [[BadgeUserImageView alloc] initWithMagicPrefix:self.magicModePrefix];
    self.badgeUserImageView.suggestedImageSize = UserImageViewSizeTiny;
    self.badgeUserImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.badgeUserImageView.badgeIconSize = ZetaIconSizeTiny;

    [self.avatarContainer addSubview:self.badgeUserImageView];
}

- (void)updateConstraints
{
    CGFloat rightMargin = [WAZUIMagic cgFloatForIdentifier:@"people_picker.search_results_mode.person_tile_right_margin"];
    CGFloat leftMargin = [WAZUIMagic cgFloatForIdentifier:@"people_picker.search_results_mode.person_tile_left_margin"];
    CGFloat nameAvatarMargin = [WAZUIMagic cgFloatForIdentifier:@"people_picker.search_results_mode.tile_name_horizontal_spacing"];
    if (! self.initialConstraintsCreated) {

        [self.badgeUserImageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
        [self.contentView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];

        [self.gesturesView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];

        [self.hideButton autoPinEdgeToSuperviewEdge:ALEdgeTop];
        [self.hideButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultLow forConstraints:^{
            [self.hideButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:leftMargin];
            [self.hideButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:nameAvatarMargin];
        }];
        [self.hideButton autoSetDimension:ALDimensionWidth toSize:64 relation:NSLayoutRelationGreaterThanOrEqual];

        [self.subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameLabel];
        [self.subtitleLabel autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.avatarContainer withOffset:[WAZUIMagic cgFloatForIdentifier:@"people_picker.search_results_mode.tile_name_horizontal_spacing"]];
        self.subtitleRightMarginConstraint = [self.subtitleLabel autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.swipeView withOffset:- rightMargin];

        self.nameLabelTopConstraint = [self.nameLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.swipeView withOffset:9.0f];
        self.nameLabelVerticalConstraint = [self.nameLabel autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.avatarContainer];
        
        if (self.subtitleLabel.text.length == 0) {
            self.nameLabelTopConstraint.active = NO;
            self.nameLabelVerticalConstraint.active = YES;
        }
        else {
            self.nameLabelVerticalConstraint.active = NO;
            self.nameLabelTopConstraint.active = YES;
        }
        
        [self.nameLabel autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.avatarContainer withOffset:nameAvatarMargin];
        self.nameRightMarginConstraint = [self.nameLabel autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.swipeView withOffset:- rightMargin];

        self.avatarViewSizeConstraint = [self.avatarContainer autoSetDimension:ALDimensionWidth toSize:80];
        [self.avatarContainer autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.avatarContainer];
        [self.avatarContainer autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.swipeView withOffset:leftMargin];
        [self.avatarContainer autoAlignAxisToSuperviewMarginAxis:ALAxisHorizontal];

        self.conversationImageViewSize = [self.conversationImageView autoSetDimension:ALDimensionWidth toSize:80];
        [self.conversationImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.conversationImageView];
        [self.conversationImageView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.swipeView withOffset:[WAZUIMagic cgFloatForIdentifier:@"people_picker.search_results_mode.person_tile_left_margin"]];
        [self.conversationImageView autoPinEdgeToSuperviewEdge:ALEdgeTop];

        [self.instantConnectButton autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.avatarContainer];
        [self.instantConnectButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0];
        [self.instantConnectButton autoSetDimensionsToSize:CGSizeMake(64, 64)];

        self.initialConstraintsCreated = YES;
        [self updateForContext];

        [UIView performWithoutAnimation:^{
            [self layoutIfNeeded];
        }];
    }

    self.subtitleRightMarginConstraint.constant = self.instantConnectButton.hidden ? -rightMargin : - self.instantConnectButton.bounds.size.width;
    self.nameRightMarginConstraint.constant = self.instantConnectButton.hidden ? -rightMargin : - self.instantConnectButton.bounds.size.width;

    [super updateConstraints];
}

- (void)updateForContext
{
    self.nameLabel.font = [UIFont fontWithMagicIdentifier:[self.magicModePrefix stringByAppendingString:@".name_label_font"]];
    self.nameLabel.textColor = [UIColor colorWithMagicIdentifier:[self.magicPrefix stringByAppendingString:@".name_label_font_color"]];

    CGFloat squareImageWidth = [WAZUIMagic cgFloatForIdentifier:[self.magicModePrefix stringByAppendingString:@".tile_image_diameter"]];
    self.avatarViewSizeConstraint.constant = squareImageWidth;
    self.conversationImageViewSize.constant = squareImageWidth;
    self.badgeUserImageView.badgeColor = [UIColor colorWithMagicIdentifier:[self.magicPrefix stringByAppendingString:@".badge_icon_color"]];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [UIView performWithoutAnimation:^{
        self.conversationImageView.image = nil;
        self.conversationImageView.hidden = NO;
        self.badgeUserImageView.hidden = NO;
        self.subtitleLabel.text = @"";
        self.nameLabel.text = @"";
        [self setDrawerOpen:NO animated:NO];
        // cleanup animation
        [self.instantConnectButton setIcon:ZetaIconTypePlusCircled withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
        [self.avatarOverlay removeFromSuperview];
        self.avatarOverlay = nil;
        [self.successCheckmark removeFromSuperview];
        self.successCheckmark = nil;
        self.contentView.alpha = 1.0f;
        [self.hideButton setTitle:[NSLocalizedString(@"peoplepicker.hide_search_result", @"") uppercaseString] forState:UIControlStateNormal];
    }];
}

- (void)updateForUser
{
    self.displayName = self.user.name;
    
    [self updateSubtitleForCommonConnections:self.user.topCommonConnections total:self.user.totalCommonConnections];
    
    BOOL canBeConnected = YES;

    if (self.user == nil) {
        canBeConnected = NO;
    }
    else if (BareUserToUser(self.user) != nil) {
        ZMUser *fullUser = BareUserToUser(self.user);

        canBeConnected = fullUser.canBeConnected && ! fullUser.isBlocked && ! fullUser.isPendingApproval;
    }
    else {
        canBeConnected = self.user.canBeConnected;
    }

    self.instantConnectButton.hidden = ! canBeConnected;
    [self setNeedsUpdateConstraints];
    self.badgeUserImageView.user = self.user;
}

#pragma mark - Public API

- (void)playAddUserAnimation
{
    [self.instantConnectButton setIcon:ZetaIconTypeCheckmarkCircled withSize:ZetaIconSizeTiny forState:UIControlStateNormal];

    self.avatarOverlay = [[UIView alloc] initForAutoLayout];
    self.avatarOverlay.backgroundColor = [UIColor blackColor];
    self.avatarOverlay.alpha = 0.0f;
    self.avatarOverlay.layer.cornerRadius = self.badgeUserImageView.bounds.size.width / 2.0f;
    [self.swipeView addSubview:self.avatarOverlay];

    [self.avatarOverlay autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.badgeUserImageView];
    [self.avatarOverlay autoAlignAxis:ALAxisVertical toSameAxisOfView:self.badgeUserImageView];
    [self.avatarOverlay autoSetDimensionsToSize:self.badgeUserImageView.bounds.size];
    [self layoutIfNeeded];

    [UIView mt_animateWithViews:@[self.avatarOverlay]
                       duration:0.15f
                 timingFunction:MTTimingFunctionEaseOutQuart
                     animations:^{
                         self.avatarOverlay.alpha = 0.5f;
                     }];

    self.successCheckmark = [[UIImageView alloc] initForAutoLayout];
    self.successCheckmark.image = [UIImage imageForIcon:ZetaIconTypeClock iconSize:ZetaIconSizeSmall color:[UIColor whiteColor]];
    [self.swipeView addSubview:self.successCheckmark];
    self.successCheckmark.transform = CGAffineTransformMakeScale(1.8f, 1.8f);
    self.successCheckmark.alpha = 0.0f;

    [self.successCheckmark autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.badgeUserImageView];
    [self.successCheckmark autoAlignAxis:ALAxisVertical toSameAxisOfView:self.badgeUserImageView];
    [self.successCheckmark autoSetDimensionsToSize:self.successCheckmark.image.size];
    [self layoutIfNeeded];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.successCheckmark != nil) {            
            self.successCheckmark.mt_animationExaggeration = 4;
            [UIView mt_animateWithViews:@[self.successCheckmark]
                               duration:0.35f
                         timingFunction:MTTimingFunctionEaseOutBack
                             animations:^{
                                 self.successCheckmark.transform = CGAffineTransformIdentity;
                                 self.successCheckmark.alpha = 1.0f;
                             }];
        }
    });

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.45f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView mt_animateWithViews:@[self.contentView]
                           duration:0.55f
                     timingFunction:MTTimingFunctionEaseOutQuart
                         animations:^{
                             self.contentView.alpha = 0.0f;
                         }];
    });

}

#pragma mark - Callbacks

- (void)doubleTap:(UITapGestureRecognizer *)doubleTapper
{
    if (self.doubleTapAction != nil) {
        self.doubleTapAction(self);
    }
}

- (void)hideSearchResult:(UIButton *)sender
{
    if (self.hideSelectedAction != nil) {
        self.hideSelectedAction(self);
    }
}

- (void)instantConnect:(UIButton *)button
{
    if (self.instantConnectAction != nil) {
        self.instantConnectAction(self);
    }
}

#pragma mark - Get, set

- (void)setUser:(id<ZMBareUser, ZMSearchableUser>)user
{
    _user = user;

    [self updateForUser];
}

- (void)setConversation:(ZMConversation *)conversation
{
    _conversation = conversation;
    
    if (conversation.conversationType == ZMConversationTypeOneOnOne) {
        ZMUser *otherUser = conversation.connectedUser;
        self.user = otherUser;
        self.badgeUserImageView.hidden = NO;
        self.conversationImageView.image = nil;
    }
    else {
        self.conversationImageView.image = [UIImage imageNamed:@"group-icon.png"];
        self.badgeUserImageView.hidden = YES;
        self.user = nil;
        self.displayName = conversation.displayName;
    }
}

- (void)setDisplayName:(NSString *)displayName
{
    _displayName = [displayName copy];

    self.nameLabel.text = [_displayName transformStringWithMagicKey:[self.magicModePrefix stringByAppendingString:@".name_label_text_transform"]];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];

    if (selected) {
        [self.badgeUserImageView setBadgeIcon:ZetaIconTypeCheckmark];
    } else {
        self.badgeUserImageView.badge = nil;
    }
}

- (NSString *)magicPrefix
{
    NSMutableString *prefix = [NSMutableString stringWithString:self.magicModePrefix];
    [prefix appendString:@".context_create_conversation"];
    return prefix;
}

- (NSString *)magicModePrefix
{
    return @"people_picker.search_results_mode";
}

#pragma mark - Override

- (NSString *)mutuallyExclusiveSwipeIdentifier
{
    return NSStringFromClass(self.class);
}

- (BOOL)canOpenDrawer
{
    return ! self.user.isConnected && self.canBeHidden;
}

- (void)updateSubtitleForCommonConnections:(NSOrderedSet *)users total:(NSUInteger)total
{
    if (self.user.isConnected || users.count == 0) {
        self.subtitleLabel.text = @"";
        self.nameLabelTopConstraint.active = NO;
        self.nameLabelVerticalConstraint.active = YES;
    }
    else {
        self.nameLabelVerticalConstraint.active = NO;
        self.nameLabelTopConstraint.active = YES;
        
        if (users.count == 1) { // Knows "Name"
            self.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"peoplepicker.suggested.knows_one", @""), [users.firstObject displayName]];
        }
        else if (users.count == 2) { // Knows "Name" and "Other Name"
            NSArray *usersArray = users.array;
            self.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"peoplepicker.suggested.knows_two", @""), [usersArray[0] displayName], [usersArray[1] displayName]];
        }
        else { // Knows "Name" and N others
            self.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"peoplepicker.suggested.knows_more", @""), [users.firstObject displayName], total - 1];
        }
    }
}

#pragma mark - ZMCommonContactsSearchDelegate

- (void)didReceiveCommonContactsUsers:(NSOrderedSet *)users forSearchToken:(id<ZMCommonContactsSearchToken>)searchToken
{
    if (searchToken == self.recentSearchToken && ! [self.user isConnected]) {
        [self updateSubtitleForCommonConnections:users total:users.count];
    }
}

@end
