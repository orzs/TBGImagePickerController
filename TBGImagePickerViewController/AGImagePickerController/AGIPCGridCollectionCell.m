//
//  AGIPCGridCollectionCell.m
//  AGImagePickerController Demo
//
//  Created by MexiQQ on 15/7/27.
//  Copyright (c) 2015年 Artur Grigor. All rights reserved.
//

#import "AGIPCGridCollectionCell.h"

@interface AGIPCGridCollectionCell()
@property (nonatomic,assign) CGPoint origin;
@end

@implementation AGIPCGridCollectionCell

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self){
        self.backgroundColor = [UIColor colorWithRed:20.0f/255 green:20.0/255 blue:20.0/255 alpha:1];
        self.imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 9, 60, 60)];
        self.imgView.layer.masksToBounds = YES;
        self.imgView.layer.borderWidth = 2.0;
        self.imgView.layer.borderColor = [[UIColor colorWithRed:211.0f/255 green:91.0f/255 blue:9.0f/255 alpha:1.0f] CGColor];
        self.removeButton = [[UIButton alloc]initWithFrame:CGRectMake(48, 0 , 20, 20)];
        
        [self.removeButton setBackgroundImage:[UIImage imageNamed:@"AGImagePickerController.bundle/picker_delete"] forState:UIControlStateNormal];
        self.removeButton.layer.masksToBounds = YES;
        self.removeButton.layer.cornerRadius = 10;
        self.removeButton.layer.borderWidth = 0;
        [self.removeButton addTarget:self action:@selector(removeAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    [self addSubview:self.imgView];
    [self addSubview:self.removeButton];
    
    self.origin = self.center;
    return  self;
}

- (IBAction)removeAction:(id)sender{
    self.rmAction();
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    self.imgView.alpha = highlighted ? 0.75f : 1.0f;
}

@end
