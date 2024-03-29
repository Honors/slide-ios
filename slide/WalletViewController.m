//
//  WalletViewController.m
//  slide
//
//  Created by Matt Neary on 10/15/14.
//  Copyright (c) 2014 slide. All rights reserved.
//

#import "WalletViewController.h"
#import "FieldsDataStore.h"
#import "RelationshipFormsViewController.h"

@implementation WalletViewController

- (UIColor *)colorwithHexString:(NSString *)hexStr alpha:(CGFloat)alpha;
{
    unsigned int hexint = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexStr];
    [scanner setCharactersToBeSkipped:[NSCharacterSet
                                       characterSetWithCharactersInString:@"#"]];
    [scanner scanHexInt:&hexint];
    UIColor *color =
    [UIColor colorWithRed:((CGFloat) ((hexint & 0xFF0000) >> 16))/255
                    green:((CGFloat) ((hexint & 0xFF00) >> 8))/255
                     blue:((CGFloat) (hexint & 0xFF))/255
                    alpha:alpha];
    return color;
}

- (void)reload {
    cards = [[FieldsDataStore sharedInstance] getRegisteredUsers];
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self reload];
}
- (void)viewDidAppear:(BOOL)animated {
    [self reload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    RelationshipFormsViewController *rfvc = [[RelationshipFormsViewController alloc] init];
    rfvc.forms = [NSArray arrayWithArray:cards[indexPath.row][@"forms"]];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.navigationController pushViewController:rfvc animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return cards.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"card"];
    NSArray *sviews = cell.contentView.subviews;
    UILabel *title = sviews[0];
    UILabel *formCount = sviews[1];
    NSDictionary *card = cards[indexPath.row];
    NSString *color = card[@"color"] ? card[@"color"] : @"#3385FF";
    cell.contentView.backgroundColor = [self colorwithHexString:color alpha:1.0];
    title.text = card[@"orgName"] ? card[@"orgName"] : @"Unaffiliated Forms";
    formCount.text = [NSString stringWithFormat:@"%lu forms", (unsigned long)((NSArray *)card[@"forms"]).count];
    return cell;
}

@end
