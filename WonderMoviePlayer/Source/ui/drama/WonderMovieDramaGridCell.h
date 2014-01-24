//
//  WonderMovieDramaGridCell.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 11/8/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    WonderMovieDramaGridCellTypeDefault,
    WonderMovieDramaGridCellTypeEnded,
    WonderMovieDramaGridCellTypeNewest,
} WonderMovieDramaGridCellType;

@class WonderMovieDramaGridCell;

@protocol WonderMovieDramaGridCellDelegate <NSObject>

- (void)wonderMovieDramaGridCell:(WonderMovieDramaGridCell *)cell didClickAtSetNum:(int)setNum;

@end

@interface WonderMovieDramaGridCell : UITableViewCell
@property (nonatomic, weak) id<WonderMovieDramaGridCellDelegate> delegate;
@property (nonatomic, assign) int minVideoSetNum;
@property (nonatomic, assign) int maxVideoSetNum;
@property (nonatomic, assign) int selectedButtonIndex; // NSNotFound for invalid value
@property (nonatomic, assign) WonderMovieDramaGridCellType cellType;

+ (CGFloat)cellHeightWithMinVideoSetNum:(int)minVideoSetNum maxVideoSetNum:(int)maxVideoSetNum;
- (void)configureCellWithMinVideoSetNum:(int)minVideoSetNum maxVideoSetNum:(int)maxVideoSetNum;
- (void)playWithSetNum:(int)setNum;
@end
