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


#import "ShareItemProvider.h"
#import "zmessaging+iOS.h"

NSString *ActivityToAnalyticsString(NSString *activity) {
    if ([activity isEqualToString:UIActivityTypePostToFacebook]) {
        return @"facebook";
    }
    if ([activity isEqualToString:UIActivityTypePostToTwitter]) {
        return @"twitter";
    }
    if ([activity isEqualToString:UIActivityTypePostToWeibo]) {
        return @"weibo";
    }
    if ([activity isEqualToString:UIActivityTypeMessage]) {
        return @"message";
    }
    if ([activity isEqualToString:UIActivityTypeMail]) {
        return @"mail";
    }
    if ([activity isEqualToString:UIActivityTypePrint]) {
        return @"print";
    }
    if ([activity isEqualToString:UIActivityTypeCopyToPasteboard]) {
        return @"copyToPasteboard";
    }
    if ([activity isEqualToString:UIActivityTypeAirDrop]) {
        return @"airdrop";
    }
    if (activity) {
        return activity;
    }
    // Worst case scenario
    return @"unknown";
}


@implementation ShareItemProvider

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController subjectForActivityType:(NSString *)activityType
{
    return NSLocalizedString(@"send_invitation.subject", @"");
}

- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType
{
    ZMUser<ZMEditableUser> *fullSelfUser = [ZMUser selfUserInUserSession:[ZMUserSession sharedSession]];
    
    NSString *shareText = nil;
    if (fullSelfUser.emailAddress.length == 0) {
        // User has no email address set
        shareText = NSLocalizedString(@"send_invitation_no_email.text", @"");
    }
    else {
        shareText = [NSString stringWithFormat:NSLocalizedString(@"send_invitation.text", @""), fullSelfUser.emailAddress];
    }
    
    return shareText;
}

@end
