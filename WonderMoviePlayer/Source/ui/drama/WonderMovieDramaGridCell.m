//
//  WonderMovieDramaGridCell.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 11/8/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import "WonderMovieDramaGridCell.h"
#import "WonderMoviePlayerConstants.h"

#define kDramaGridCellButtonHeight      (52/2)
#define kDramaGridCellButtonWidth       (180/2)
#define kDramaGridCellButtonCountPerRow 3
#define kDramaGridCellButtonMaxRow      3

@interface WonderMovieDramaGridCell ()
@property (nonatomic, retain) NSMutableArray *buttons;
@property (nonatomic, retain) UILabel *headerLabel;
@end

@implementation WonderMovieDramaGridCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.buttons = [NSMutableArray arrayWithCapacity:kDramaGridCellButtonMaxRow * kDramaGridCellButtonCountPerRow];
        CGFloat leftPadding = 20, topPadding = 15 + 11 + 8;
        for (int i = 0; i < kDramaGridCellButtonCountPerRow * kDramaGridCellButtonMaxRow; ++i) {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            [button setBackgroundImage:QQVideoPlayerImage(@"tv_drama_button_normal") forState:UIControlStateNormal];
            [button setBackgroundImage:QQVideoPlayerImage(@"tv_drama_button_press") forState:UIControlStateHighlighted];
            [button setBackgroundImage:QQVideoPlayerImage(@"tv_drama_button_press") forState:UIControlStateReserved];
//            [button setBackgroundImage:QQVideoPlayerImage(@"tv_drama_button_selected") forState:UIControlStateSelected];
//            [button setImage:QQVideoPlayerImage(@"list_play") forState:UIControlStateSelected];
            button.hidden = YES;
            button.frame = CGRectMake(leftPadding + (i % kDramaGridCellButtonCountPerRow) * (kDramaGridCellButtonWidth + 8),
                                      topPadding + (i / kDramaGridCellButtonCountPerRow) * (kDramaGridCellButtonHeight + 19),
                                      kDramaGridCellButtonWidth, kDramaGridCellButtonHeight);
            [button addTarget:self action:@selector(onClickVideo:) forControlEvents:UIControlEventTouchUpInside];
            button.titleLabel.font = [UIFont systemFontOfSize:15];
            [self.contentView addSubview:button];
            [self.buttons addObject:button];
        }
        
        _minVideoSetNum = NSNotFound;
        _maxVideoSetNum = NSNotFound;
        _selectedButtonIndex = NSNotFound;
        
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 15, 200, 12)];
        headerLabel.backgroundColor = [UIColor clearColor];
        headerLabel.font = [UIFont systemFontOfSize:11];
        headerLabel.textColor = QQColor(videoplayer_drama_header_color);
        self.headerLabel = headerLabel;
        [self.contentView addSubview:headerLabel];
        [headerLabel release];
        
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.backgroundView = nil;
    }
    return self;
}

- (void)dealloc
{
    self.delegate = nil;
    self.buttons = nil;
    self.headerLabel = nil;
    [super dealloc];
}

+ (CGFloat)cellHeightWithMinVideoSetNum:(int)minVideoSetNum maxVideoSetNum:(int)maxVideoSetNum
{
    if (minVideoSetNum == NSNotFound || maxVideoSetNum == NSNotFound) {
        return 0;
    }
    
    int lineCount = (maxVideoSetNum - minVideoSetNum + 1 + kDramaGridCellButtonCountPerRow - 1) / kDramaGridCellButtonCountPerRow;
    lineCount = MIN(kDramaGridCellButtonMaxRow, MAX(0, lineCount));
    
    CGFloat rowSeparatorHeight = 19;
    if (lineCount == 0) {
        return 0;
    }
    else {
        return (15+11+8) + kDramaGridCellButtonHeight * lineCount + rowSeparatorHeight * (lineCount - 1);
    }
}

- (void)configureCellWithMinVideoSetNum:(int)minVideoSetNum maxVideoSetNum:(int)maxVideoSetNum
{
    self.minVideoSetNum = minVideoSetNum;
    self.maxVideoSetNum = maxVideoSetNum;
    
    if (minVideoSetNum != NSNotFound && maxVideoSetNum != NSNotFound) {
        self.headerLabel.text = [NSString stringWithFormat:@"%d-%d", minVideoSetNum, maxVideoSetNum];
    }
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (_minVideoSetNum != NSNotFound && _maxVideoSetNum != NSNotFound) {
        for (int i = 0; i < kDramaGridCellButtonCountPerRow * kDramaGridCellButtonMaxRow; ++i) {
            UIButton *button = self.buttons[i];
            int setNum = _minVideoSetNum + i;
            button.tag = setNum;
            
            button.selected = (i == _selectedButtonIndex);

            if (setNum <= _maxVideoSetNum) {
                
                button.hidden = NO;
                
                if (setNum == _maxVideoSetNum && self.cellType != WonderMovieDramaGridCellTypeDefault) {
                    [button setTitle:[NSString stringWithFormat:@"%d(%@)", setNum,
                                      self.cellType == WonderMovieDramaGridCellTypeEnded ? @"终" : @"新"]
                            forState:UIControlStateNormal];
                    [button setBackgroundImage:nil forState:UIControlStateSelected];
                    [button setImage:QQVideoPlayerImage(@"list_play") forState:UIControlStateSelected];
                }
                else {
                    [button setTitle:[NSString stringWithFormat:@"%d", setNum] forState:UIControlStateNormal];
                    [button setBackgroundImage:QQVideoPlayerImage(@"tv_drama_button_selected") forState:UIControlStateSelected];
                    [button setImage:nil forState:UIControlStateSelected];
                }
            }
            else {
                button.hidden = YES;
            }
        }
    }
}

- (void)playWithSetNum:(int)setNum
{
    if (_minVideoSetNum != NSNotFound && _maxVideoSetNum != NSNotFound && setNum <= _maxVideoSetNum) {
        _selectedButtonIndex = setNum - _minVideoSetNum;
    }
    else {
        _selectedButtonIndex = NSNotFound;
    }
}

#pragma mark - UIAction
- (IBAction)onClickVideo:(UIButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(wonderMovieDramaGridCell:didClickAtSetNum:)]) {
        [self.delegate wonderMovieDramaGridCell:self didClickAtSetNum:sender.tag];
    }
}

@end
