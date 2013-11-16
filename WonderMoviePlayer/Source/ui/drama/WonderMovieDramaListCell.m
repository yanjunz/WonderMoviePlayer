//
//  WonderMovieDramaListCell.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 11/15/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import "WonderMovieDramaListCell.h"
#import "WonderMoviePlayerConstants.h"
#import "UIView+Sizes.h"

@implementation WonderMovieDramaListCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.imageView.hidden = YES;
        self.textLabel.textColor = [UIColor whiteColor];
        
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    if (selected) {
        self.imageView.hidden = NO;
        self.textLabel.textColor = QQColor(videoplayer_drama_list_text_color);
    }
    else {
        self.imageView.hidden = YES;
        self.textLabel.textColor = [UIColor whiteColor];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat imageWidth = 10, imageHeight = 13;
    self.imageView.frame = CGRectMake(20, (self.height - imageHeight) / 2, imageWidth, imageHeight);
    
    self.textLabel.frame = CGRectMake(36, 0, self.width - 36 - 20, self.height);
}

@end