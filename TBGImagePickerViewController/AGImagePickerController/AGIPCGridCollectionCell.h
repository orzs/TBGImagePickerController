//
//  AGIPCGridCollectionCell.h
//  AGImagePickerController Demo
//
//  Created by MexiQQ on 15/7/27.
//  Copyright (c) 2015年 Artur Grigor. All rights reserved.
//

#import <UIKit/UIKit.h> 

typedef void(^removeAction)();
@interface AGIPCGridCollectionCell : UICollectionViewCell

@property (nonatomic,strong) UIImageView *imgView;
@property (nonatomic,strong) UIButton *removeButton;
@property (nonatomic,strong) removeAction rmAction;
@end
