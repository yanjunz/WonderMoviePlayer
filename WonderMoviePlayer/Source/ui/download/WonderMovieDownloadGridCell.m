//
//  WonderMovieDownloadGridCell.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 28/2/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import "WonderMovieDownloadGridCell.h"
#import "WonderMoviePlayerConstants.h"

#define kDramaGridCellButtonHeight      (52/2)
#define kDramaGridCellButtonWidth       (180/2)
#define kDramaGridCellButtonCountPerRow 3
#define kDramaGridCellButtonMaxRow      3

@interface WonderMovieDownloadGridCell ()
@property (nonatomic, strong) NSMutableArray *buttons;
@property (nonatomic, strong) UILabel *headerLabel;
@end

@implementation WonderMovieDownloadGridCell

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
            [button setBackgroundImage:QQVideoPlayerImage(@"tv_drama_button_press") forState:UIControlStateSelected];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [button setTitleColor:QQColor(videoplayer_playing_text_color) forState:UIControlStateSelected];
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
    BOOL showPlayingFlag = NO;
    if (_minVideoSetNum != NSNotFound && _maxVideoSetNum != NSNotFound) {
        for (int i = 0; i < kDramaGridCellButtonCountPerRow * kDramaGridCellButtonMaxRow; ++i) {
            UIButton *button = self.buttons[i];
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
                showPlayingFlag = YES;
            }
            else {
                button.selected = NO;
            }
        }
    }
}


@end
