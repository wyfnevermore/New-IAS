//
//  Styles.m
//  New IAS
//
//  Created by wyfnevermore on 2017/2/9.
//  Copyright © 2017年 wyfnevermore. All rights reserved.
//

#import "Styles.h"

@interface Styles ()

@end

@implementation Styles

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setButtonStyle:(UIButton*)button{
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor colorWithRed:132.0/255 green:212.0/255 blue:248.0/255 alpha:1]];
    button.layer.cornerRadius = 15.0;//圆角的弧度
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
