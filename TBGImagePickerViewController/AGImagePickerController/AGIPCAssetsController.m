//
//  AGIPCAssetsController.m
//  AGImagePickerController
//
//  Created by Artur Grigor on 17.02.2012.
//  Copyright (c) 2012 - 2013 Artur Grigor. All rights reserved.
//  
//  For the full copyright and license information, please view the LICENSE
//  file that was distributed with this source code.
//  

#import "AGIPCAssetsController.h"
#import "AGIPCGridCollectionCell.h"
#import "AGImagePickerController+Helper.h"
#import "AGIPCGridCell.h"
#import "BBBadgeBarButtonItem.h"

@interface AGIPCAssetsController ()
{
    ALAssetsGroup *_assetsGroup;
    NSMutableArray *_assets;
    AGImagePickerController *_imagePickerController;
}

@property (nonatomic, strong) NSMutableArray *assets;

@end

@interface AGIPCAssetsController (Private)

- (void)changeSelectionInformation;

- (void)registerForNotifications;
- (void)unregisterFromNotifications;

- (void)didChangeLibrary:(NSNotification *)notification;
- (void)didChangeToolbarItemsForManagingTheSelection:(NSNotification *)notification;

- (BOOL)toolbarHidden;

- (void)loadAssets;
- (void)reloadData;

- (void)setupToolbarItems;

- (NSArray *)itemsForRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)doneAction:(id)sender;
- (void)selectAllAction:(id)sender;
- (void)deselectAllAction:(id)sender;
- (void)customBarButtonItemAction:(id)sender;

@end

@implementation AGIPCAssetsController

#pragma mark - Properties

@synthesize assetsGroup = _assetsGroup, assets = _assets, imagePickerController = _imagePickerController,mytableView = _mytableView;

- (BOOL)toolbarHidden
{
    if (! self.imagePickerController.shouldShowToolbarForManagingTheSelection)
        return YES;
    else
    {
        if (self.imagePickerController.toolbarItemsForManagingTheSelection != nil) {
            return !(self.imagePickerController.toolbarItemsForManagingTheSelection.count > 0);
        } else {
            return NO;
        }
    }
}

- (void)setAssetsGroup:(ALAssetsGroup *)theAssetsGroup
{
    @synchronized (self)
    {
        if (_assetsGroup != theAssetsGroup)
        {
            _assetsGroup = theAssetsGroup;
            [_assetsGroup setAssetsFilter:[ALAssetsFilter allPhotos]];

            [self reloadData];
        }
    }
}

- (ALAssetsGroup *)assetsGroup
{
    ALAssetsGroup *ret = nil;
    
    @synchronized (self)
    {
        ret = _assetsGroup;
    }
    
    return ret;
}

- (NSMutableArray *)selectedAssets
{
    NSMutableArray *selectedAssets = [NSMutableArray array];
    
	for (AGIPCGridItem *gridItem in self.assets) 
    {		
		if (gridItem.selected)
        {	
			[selectedAssets addObject:gridItem.asset];
		}
	}
    
    return selectedAssets;
}

#pragma mark - Object Lifecycle

- (id)initWithImagePickerController:(AGImagePickerController *)imagePickerController andAssetsGroup:(ALAssetsGroup *)assetsGroup
{
    self = [super init];
    if (self)
    {
        self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
        self.view.backgroundColor = [UIColor whiteColor];

        self.mytableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - 80)];
        self.mytableView.allowsMultipleSelection = NO;
        self.mytableView.allowsSelection = NO;
        self.mytableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.mytableView.backgroundColor = [UIColor blackColor];
        self.mytableView.delegate = self;
        self.mytableView.dataSource = self;
        [self.view addSubview:self.mytableView];
        
        UICollectionViewFlowLayout *flowLayout=[[UICollectionViewFlowLayout alloc] init];
        flowLayout.itemSize=CGSizeMake(68,68);
        flowLayout.sectionInset = UIEdgeInsetsMake(2, 5, 0, 0);
        [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
        self.mycollectionView = [[UICollectionView alloc] initWithFrame:(CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 80, [UIScreen mainScreen].bounds.size.width, 80)) collectionViewLayout:flowLayout];
        [self.mycollectionView registerClass:[AGIPCGridCollectionCell  class] forCellWithReuseIdentifier:@"simpleCell"];
        self.mycollectionView.backgroundColor = [UIColor colorWithRed:20.0f/255 green:20.0/255 blue:20.0/255 alpha:1];
        self.mycollectionView.delegate = self;
        self.mycollectionView.dataSource = self;
        [self.view addSubview:self.mycollectionView];
        
        UIButton *customButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 20)];
        [customButton setTitle:@"确定" forState:UIControlStateNormal];
        [customButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [customButton addTarget:self action:@selector(doneAction:) forControlEvents:UIControlEventTouchUpInside];
        BBBadgeBarButtonItem *barButton = [[BBBadgeBarButtonItem alloc] initWithCustomUIButton:customButton];
        barButton.badgeValue = @"0";
        barButton.badgeOriginX = 28;
        barButton.badgeOriginY = -8;
        self.navigationItem.rightBarButtonItem = barButton;
        
        
        _assets = [[NSMutableArray alloc] init];
        self.assetsGroup = assetsGroup;
        self.imagePickerController = imagePickerController;
        self.title = NSLocalizedStringWithDefaultValue(@"AGIPC.Loading", nil, [NSBundle mainBundle], @"Loading...", nil);
        self.title = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyName];
        
        // Start loading the assets
        [self loadAssets];
    }
    
    return self;
}

- (void)dealloc
{
    [self unregisterFromNotifications];
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (! self.imagePickerController) return 0;
    
    double numberOfAssets = (double)self.assetsGroup.numberOfAssets;
    NSInteger nr = ceil(numberOfAssets / self.imagePickerController.numberOfItemsPerRow);
    
    return nr;
}

- (NSArray *)itemsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:self.imagePickerController.numberOfItemsPerRow];
    
    NSUInteger startIndex = indexPath.row * self.imagePickerController.numberOfItemsPerRow, 
                 endIndex = startIndex + self.imagePickerController.numberOfItemsPerRow - 1;
    if (startIndex < self.assets.count)
    {
        if (endIndex > self.assets.count - 1)
            endIndex = self.assets.count - 1;
        
        for (NSUInteger i = startIndex; i <= endIndex; i++)
        {
            [items addObject:(self.assets)[i]];
        }
    }
    
    return items;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    AGIPCGridCell *cell = (AGIPCGridCell *)[self.mytableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
    {		        
        cell = [[AGIPCGridCell alloc] initWithImagePickerController:self.imagePickerController items:[self itemsForRowAtIndexPath:indexPath] andReuseIdentifier:CellIdentifier];
    }	
	else 
    {		
		cell.items = [self itemsForRowAtIndexPath:indexPath];
	}
    
    cell.backgroundColor = [UIColor blackColor];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGRect itemRect = self.imagePickerController.itemRect;
    return itemRect.size.height + itemRect.origin.y;
}

#pragma mark - UICollectionDataSource Methods
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [AGIPCGridItem numberOfSelections];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifier = @"simpleCell";
    AGIPCGridCollectionCell *cell = (AGIPCGridCollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    if(cell == nil)
    {
        cell = [[AGIPCGridCollectionCell alloc] initWithFrame:CGRectMake(0, 0, 68, 68)];
    }
    
    ALAsset *tmpAsset = (ALAsset *)self.selectedAssets[indexPath.row];
    cell.imgView.image = [UIImage imageWithCGImage:tmpAsset.thumbnail];
    __weak typeof(self) weakSelf = self;
    cell.rmAction = ^(){
        for (AGIPCGridItem *gridItem in weakSelf.assets)
        {
            if(gridItem.asset == tmpAsset){
                gridItem.selected = NO;
            }
        }
        [weakSelf.mycollectionView reloadData];
    };
    return cell;
}

#pragma mark - View Lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return NO;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    // Reset the number of selections
    [AGIPCGridItem performSelector:@selector(resetNumberOfSelections)];
    
    [super viewWillAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Fullscreen
    if (self.imagePickerController.shouldChangeStatusBarStyle) {
        self.extendedLayoutIncludesOpaqueBars = YES;
    }
    
    // Setup Notifications
    [self registerForNotifications];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    // Destroy Notifications
    [self unregisterFromNotifications];
}

#pragma mark - Private

- (void)loadAssets
{
    [self.assets removeAllObjects];
    
    __ag_weak AGIPCAssetsController *weakSelf = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        __strong AGIPCAssetsController *strongSelf = weakSelf;
        
        @autoreleasepool {
            [strongSelf.assetsGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                
                if (result == nil) 
                {
                    return;
                }
                if (strongSelf.imagePickerController.shouldShowPhotosWithLocationOnly) {
                    CLLocation *assetLocation = [result valueForProperty:ALAssetPropertyLocation];
                    if (!assetLocation || !CLLocationCoordinate2DIsValid([assetLocation coordinate])) {
                        return;
                    }
                }
                
                AGIPCGridItem *gridItem = [[AGIPCGridItem alloc] initWithImagePickerController:self.imagePickerController asset:result andDelegate:self];
                
                // Drawing must be exectued in main thread. springox(20131220)
                /*
                if (strongSelf.imagePickerController.selection != nil &&
                    [strongSelf.imagePickerController.selection containsObject:result])
                {
                    gridItem.selected = YES;
                }
                 */
                
                //[strongSelf.assets addObject:gridItem];
                // Descending photos, springox(20131225)
                [strongSelf.assets insertObject:gridItem atIndex:0];

            }];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [strongSelf reloadData];
            
        });
    
    });
}

- (void)reloadData
{
    [self.mytableView reloadData];
    [self.mycollectionView reloadData];
    
    //[self setTitle:[self.assetsGroup valueForProperty:ALAssetsGroupPropertyName]];
    [self changeSelectionInformation];
    
    /*
    NSInteger totalRows = [self.tableView numberOfRowsInSection:0];
    //Prevents crash if totalRows = 0 (when the album is empty).
    if (totalRows > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:totalRows-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    }
     */
}

- (void)doneAction:(id)sender
{
    [self.imagePickerController performSelector:@selector(didFinishPickingAssets:) withObject:self.selectedAssets];
}

- (void)cancelAction:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)selectAllAction:(id)sender
{
    for (AGIPCGridItem *gridItem in self.assets) {
        gridItem.selected = YES;
    }
}

- (void)deselectAllAction:(id)sender
{
    for (AGIPCGridItem *gridItem in self.assets) {
        gridItem.selected = NO;
    }
}

- (void)changeSelectionInformation
{
    if (self.imagePickerController.shouldDisplaySelectionInformation ) {
        BBBadgeBarButtonItem *button = (BBBadgeBarButtonItem *)self.navigationItem.rightBarButtonItem;
        button.badgeValue = [NSString stringWithFormat:@"%d",[AGIPCGridItem numberOfSelections]];
    }
}

#pragma mark - AGGridItemDelegate Methods

- (void)agGridItem:(AGIPCGridItem *)gridItem didChangeNumberOfSelections:(NSNumber *)numberOfSelections
{
    self.navigationItem.rightBarButtonItem.enabled = (numberOfSelections.unsignedIntegerValue > 0);
    [self changeSelectionInformation];
    [self.mycollectionView reloadData];
}

- (BOOL)agGridItemCanSelect:(AGIPCGridItem *)gridItem
{
    if (self.imagePickerController.selectionMode == AGImagePickerControllerSelectionModeSingle && self.imagePickerController.selectionBehaviorInSingleSelectionMode == AGImagePickerControllerSelectionBehaviorTypeRadio) {
        for (AGIPCGridItem *item in self.assets)
            if (item.selected)
                item.selected = NO;
        
        return YES;
    } else {
        if (self.imagePickerController.maximumNumberOfPhotosToBeSelected > 0)
            return ([AGIPCGridItem numberOfSelections] < self.imagePickerController.maximumNumberOfPhotosToBeSelected);
        else
            return YES;
    }
}

#pragma mark - Notifications

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(didChangeLibrary:) 
                                                 name:ALAssetsLibraryChangedNotification 
                                               object:[AGImagePickerController defaultAssetsLibrary]];
}

- (void)unregisterFromNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:ALAssetsLibraryChangedNotification 
                                                  object:[AGImagePickerController defaultAssetsLibrary]];
}

- (void)didChangeLibrary:(NSNotification *)notification
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)didChangeToolbarItemsForManagingTheSelection:(NSNotification *)notification
{
    NSLog(@"here.");
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}
@end
