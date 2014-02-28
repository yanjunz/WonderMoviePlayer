//
//  WonderMovieDownloadGridCell.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 28/2/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WonderMovieDramaGridCell.h"

@interface WonderMovieDownloadGridCell : UITableViewCell
@property (nonatomic, assign) int minVideoSetNum;
@property (nonatomic, assign) int maxVideoSetNum;
@property (nonatomic, assign) int selectedButtonIndex; // NSNotFound for invalid value
@property (nonatomic, assign) WonderMovieDramaGridCellType cellType;

+ (CGFloat)cellHeightWithMinVideoSetNum:(int)minVideoSetNum maxVideoSetNum:(int)maxVideoSetNum;
- (void)configureCellWithMinVideoSetNum:(int)minVideoSetNum maxVideoSetNum:(int)maxVideoSetNum;

@end
