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
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.imageView.hidden = YES;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        
        CGRect visibleCellFrame = CGRectMake(10, 5, self.contentView.width - 20, self.contentView.height - 10);
        UIView *bgView = [[UIView alloc] initWithFrame:self.contentView.bounds];
        bgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        UIImageView *backgroudView = [[UIImageView alloc] initWithImage:[QQVideoPlayerImage(@"download_cell_normal_single") stretchableImageWithLeftCapWidth:10 topCapHeight:10]];
        backgroudView.frame = visibleCellFrame;
        backgroudView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [bgView addSubview:backgroudView];
        self.backgroundView = bgView;
        
        self.imageView.image = QQVideoPlayerImage(@"download_check");
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        
        self.textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.textLabel.textColor = QQColor(videoplayer_download_normal_text_color);
        self.textLabel.font = [UIFont systemFontOfSize:15];
    }
    return self;
}

- (void)setSelectedForDownload:(BOOL)selectedForDownload
{
    _selectedForDownload = selectedForDownload;
    if (_selectedForDownload) {
        self.imageView.hidden = NO;
    }
    else {
        self.imageView.hidden = YES;
    }
}

- (void)setDisableForDownload:(BOOL)disableForDownload
{
    _disableForDownload = disableForDownload;
    if (_disableForDownload) {
        self.textLabel.textColor = QQColor(videoplayer_download_disable_text_color);
    }
    else {
        self.textLabel.textColor = QQColor(videoplayer_download_normal_text_color);
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect visibleCellFrame = CGRectMake(10, 5, self.contentView.width - 20, self.contentView.height - 10);
    
    CGFloat imgW = self.imageView.image.size.width, imgH = self.imageView.image.size.height;
    self.imageView.frame = CGRectMake(CGRectGetWidth(visibleCellFrame) + CGRectGetMinX(visibleCellFrame) - 10 - imgW, (self.contentView.height - imgH) / 2, imgW, imgH);
    
    CGFloat textLabelLeft = CGRectGetMinX(visibleCellFrame) + 10;
    self.textLabel.frame = CGRectMake(textLabelLeft, 0, self.contentView.width - self.imageView.width - textLabelLeft - 20, self.contentView.height);
}

@end
