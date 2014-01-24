//
//  TestTableViewController.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 11/16/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import "TestTableViewController.h"
#import "NSObject+Block.h"
#import "UIView+Sizes.h"

@interface TestTableViewController () <UITableViewDataSource, UITableViewDelegate>

@end

@implementation TestTableViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:tableView];
    
//    WonderMovieTableFooterView *footerView = [[[WonderMovieTableFooterView alloc] initWithFrame:CGRectMake(0, tableView.height, tableView.width, 65)] autorelease];
//    [tableView addSubview:footerView];
//    
//    WonderMovieTableFooterView *headerView = [[[WonderMovieTableFooterView alloc] initWithFrame:CGRectMake(0, -65, tableView.width, 65)] autorelease];
//    [tableView addSubview:headerView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"cellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
        
    }
    cell.textLabel.text = [NSString stringWithFormat:@"Cell %d", indexPath.row];
    return cell;
}



@end
