//
//  ViewController.m
//  TBGImagePickerViewController
//
//  Created by MexiQQ on 15/8/6.
//  Copyright (c) 2015年 MexiQQ. All rights reserved.
//

#import "ViewController.h"
#import "AGImagePickerController.h"
@interface ViewController ()

@end

@implementation ViewController

- (instancetype)init{
    self = [super init];
    return self;
}

- (void)loadView{
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(120, 100, 80, 40)];
    [button setTitle:@"Open" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(test:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:button];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)test:(id)sender{
    AGImagePickerController *imagePickerController = [[AGImagePickerController alloc] initWithFailureBlock:^(NSError *error) {
        
        if (error == nil)
        {
            NSLog(@"User has cancelled.");
            [self dismissViewControllerAnimated:YES completion:nil];
        } else
        {
            NSLog(@"Error: %@", error);
            
            // Wait for the view controller to show first and hide it after that
            double delayInSeconds = 0.5;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self dismissViewControllerAnimated:YES completion:nil];
            });
        }
        
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        
    } andSuccessBlock:^(NSArray *info) {
        NSLog(@"Info: %@", info);
        [self dismissViewControllerAnimated:YES completion:nil];
        
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    }];
    
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

@end
