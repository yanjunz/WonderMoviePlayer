//
//  WonderMovieDownloadListCell.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 28/2/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import "WonderMovieDownloadListCell.h"
#import "WonderMoviePlayerConstants.h"
#import "UIView+Sizes.h"

@implementation WonderMovieDownloadListCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.selectionStyle = UITableViewCellSelectionStyleBlue;
        self.imageView.hidden = YES;
        self.textLabel.textColor = [UIColor whiteColor];
        
        self.backgroundColor = [UIColor clearColor];
        UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:self.bounds];
        self.selectedBackgroundView = selectedBackgroundView;
        selectedBackgroundView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.15];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setSelectedForDownload:(BOOL)selectedForDownload
{
    _selectedForDownload = selectedForDownload;
    if (_selectedForDownload) {
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
    self.imageView.frame = CGRectMake(16, (self.height - imageHeight) / 2, imageWidth, imageHeight);
    
    self.textLabel.frame = CGRectMake(36, 0, self.width - 36 - 20, self.height);
}


@end
