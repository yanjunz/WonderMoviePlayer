//
//  WonderMovieDownloadGridCell.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 28/2/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import "WonderMovieDownloadGridCell.h"
#import "WonderMoviePlayerConstants.h"
#import "UIView+Sizes.h"


@interface WonderMovieDownloadGridCell ()
@property (nonatomic, strong) NSMutableArray *buttons;
@property (nonatomic, strong) UILabel *headerLabel;
@end

@interface WonderMovieDownloadGridButton : UIButton

@end

@implementation WonderMovieDownloadGridCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 15, 200, 12)];
        headerLabel.backgroundColor = [UIColor clearColor];
        headerLabel.font = [UIFont systemFontOfSize:11];
        headerLabel.textColor = QQColor(videoplayer_drama_header_color);
        self.headerLabel = headerLabel;
        [self.contentView addSubview:headerLabel];
        
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.backgroundView = nil;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (void)getPreferredCountPerRow:(NSInteger *)countPerRow buttonWidth:(CGFloat *)buttonWidth forMaxWidth:(CGFloat)width
{
    CGFloat minButtonWidth = kDownloadViewGridCellButtonMinWidth;
    
    CGFloat preferredButtonWidth = minButtonWidth;
    
    int maxCount = (width - kDownloadViewGridCellLeftPadding * 2 + kDownloadViewGridCellHPadding) / (minButtonWidth + kDownloadViewGridCellHPadding);
    int preferredCount = maxCount;
    
    if (countPerRow) {
        *countPerRow = preferredCount;
    }
    if (preferredCount != 0) {
        preferredButtonWidth = minButtonWidth;
        if (buttonWidth) {
            *buttonWidth = preferredButtonWidth;
        }
    }
}

+ (CGFloat)cellHeightWithMinVideoSetNum:(int)minVideoSetNum maxVideoSetNum:(int)maxVideoSetNum countPerRow:(NSInteger)countPerRow
{
    if (minVideoSetNum == NSNotFound || maxVideoSetNum == NSNotFound) {
        return 0;
    }
    
    int lineCount = (maxVideoSetNum - minVideoSetNum + 1 + countPerRow - 1) / countPerRow;
    lineCount = MIN(countPerRow, MAX(0, lineCount));
    
    CGFloat rowSeparatorHeight = kDownloadViewGridCellVPadding;
    if (lineCount == 0) {
        return 0;
    }
    else {
        return kDownloadViewGridCellTopPadding + kDownloadViewGridCellButtonHeight * lineCount + rowSeparatorHeight * (lineCount - 1);
    }
}

- (void)configureCellWithMinVideoSetNum:(int)minVideoSetNum maxVideoSetNum:(int)maxVideoSetNum forWidth:(CGFloat)width
{
    int countPerRow = 5, row = 3;
    CGFloat buttonWidth = 0;
    [[self class] getPreferredCountPerRow:&countPerRow buttonWidth:&buttonWidth forMaxWidth:width];
    row = (maxVideoSetNum - minVideoSetNum + 1 + countPerRow - 1) / countPerRow;
    _countPerRow = countPerRow;
    _buttonWidth = buttonWidth;
    
    // remove old buttons
    for (UIButton *btn in self.buttons) {
        [btn removeFromSuperview];
    }
    
    self.buttons = [NSMutableArray arrayWithCapacity:countPerRow * row];
    CGFloat leftPadding = (width - (buttonWidth + kDownloadViewGridCellHPadding) * countPerRow + kDownloadViewGridCellHPadding) / 2, topPadding = kDownloadViewGridCellTopPadding;
    
    for (int i = 0; i < countPerRow * row; ++i) {
        UIButton *button = [WonderMovieDownloadGridButton buttonWithType:UIButtonTypeCustom];
        [button setBackgroundImage:[QQVideoPlayerImage(@"download_cell_normal_single") stretchableImageWithLeftCapWidth:10 topCapHeight:10] forState:UIControlStateNormal];
        [button setBackgroundImage:[QQVideoPlayerImage(@"download_cell_sel_single") stretchableImageWithLeftCapWidth:10 topCapHeight:10] forState:UIControlStateHighlighted];
        [button setBackgroundImage:[QQVideoPlayerImage(@"download_cell_sel_single") stretchableImageWithLeftCapWidth:10 topCapHeight:10] forState:UIControlStateReserved];
        [button setBackgroundImage:[QQVideoPlayerImage(@"download_cell_sel_single") stretchableImageWithLeftCapWidth:10 topCapHeight:10] forState:UIControlStateSelected];
        UIImage *image = QQVideoPlayerImage(@"download_check");
        [button setImage:image forState:UIControlStateSelected];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTitleColor:QQColor(videoplayer_download_normal_text_color) forState:UIControlStateNormal];
        [button setTitleColor:QQColor(videoplayer_download_disable_text_color) forState:UIControlStateDisabled];
        button.titleLabel.textAlignment = UITextAlignmentCenter;
        button.imageEdgeInsets = UIEdgeInsetsMake(0., 0, 0., 10.);
        
        button.hidden = YES;
        button.frame = CGRectMake(leftPadding + (i % countPerRow) * (buttonWidth + kDownloadViewGridCellHPadding),
                                  topPadding + (i / countPerRow) * (kDownloadViewGridCellButtonHeight + kDownloadViewGridCellVPadding),
                                  buttonWidth, kDownloadViewGridCellButtonHeight);
        [button addTarget:self action:@selector(onClickVideo:) forControlEvents:UIControlEventTouchUpInside];
        button.titleLabel.font = [UIFont systemFontOfSize:15];
        [self.contentView addSubview:button];
        [self.buttons addObject:button];
    }
    self.headerLabel.left = leftPadding;
    
    _minVideoSetNum = NSNotFound;
    _maxVideoSetNum = NSNotFound;
    _selectedButtonIndex = NSNotFound;
    
    self.minVideoSetNum = minVideoSetNum;
    self.maxVideoSetNum = maxVideoSetNum;
    
    if (minVideoSetNum != NSNotFound && maxVideoSetNum != NSNotFound) {
        self.headerLabel.text = [NSString stringWithFormat:@"%d-%d", minVideoSetNum, maxVideoSetNum];
    }
    
    if (_minVideoSetNum != NSNotFound && _maxVideoSetNum != NSNotFound) {
        for (int i = 0; i < self.buttons.count; ++i) {
            UIButton *button = self.buttons[i];
            button.enabled = YES;
            int setNum = _minVideoSetNum + i;
            button.tag = setNum;
            
            if (setNum <= _maxVideoSetNum) {
                
                button.hidden = NO;
                
                if (setNum == _maxVideoSetNum && self.cellType != WonderMovieDramaGridCellTypeDefault) {
                    [button setTitle:[NSString stringWithFormat:@"%d(%@)", setNum,
                                      self.cellType == WonderMovieDramaGridCellTypeEnded ? @"终" : @"新"]
                            forState:UIControlStateNormal];
                    [button setBackgroundImage:nil forState:UIControlStateSelected];
                }
                else {
                    [button setTitle:[NSString stringWithFormat:@"%d", setNum] forState:UIControlStateNormal];
                }
            }
            else {
                button.hidden = YES;
            }
            
            if (i == _selectedButtonIndex) {
                button.selected = YES;
                CGSize size = [button.titleLabel sizeThatFits:button.bounds.size];
                CGPoint center = button.center;
                center.x -= (size.width / 2 + 15.0);
            }
            else {
                button.selected = NO;
            }
        }
    }
}

- (void)selectSetNums:(NSArray *)setNums
{
    for (UIButton *btn in self.buttons) {
        if ([setNums containsObject:@(btn.tag)]) {
            btn.selected = YES;
        }
        else {
            btn.selected = NO;
        }
    }
}

- (void)disbaleSetNums:(NSArray *)setNums
{
    for (UIButton *btn in self.buttons) {
        if ([setNums containsObject:@(btn.tag)]) {
            btn.enabled = NO;
        }
        else {
            btn.enabled = YES;
        }
    }
}

#pragma mark Action
- (IBAction)onClickVideo:(UIButton *)sender
{
    sender.selected = !sender.selected;
    
    if ([self.delegate respondsToSelector:@selector(wonderMovieDownloadGridCell:didSelect:withSetNum:)]) {
        [self.delegate wonderMovieDownloadGridCell:self didSelect:sender.selected withSetNum:sender.tag];
    }
}

@end


@implementation WonderMovieDownloadGridButton

- (CGRect)imageRectForContentRect:(CGRect)contentRect
{
    CGRect frame = [super imageRectForContentRect:contentRect];
    frame.origin.x = CGRectGetMaxX(contentRect) - CGRectGetWidth(frame) -  self.imageEdgeInsets.right + self.imageEdgeInsets.left;
    return frame;
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
    return contentRect;
}

@end
