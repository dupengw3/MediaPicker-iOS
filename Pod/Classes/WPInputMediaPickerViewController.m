#import "WPInputMediaPickerViewController.h"
#import "WPPHAssetDataSource.h"

static CGFloat const IPhoneSELandscapeWidth = 568.0f;
static CGFloat const IPhone7PortraitWidth = 375.0f;
static CGFloat const IPhone7LandscapeWidth = 667.0f;
static CGFloat const IPadPortraitWidth = 768.0f;
static CGFloat const IPadLandscapeWidth = 1024.0f;
static CGFloat const IPadPro12LandscapeWidth = 1366.0f;

@interface WPInputMediaPickerViewController()

@property (nonatomic, strong) WPMediaPickerViewController *mediaPicker;
@property (nonatomic, strong) UIToolbar *mediaToolbar;
@property (nonatomic, strong) id<WPMediaCollectionDataSource> privateDataSource;

@end

@implementation WPInputMediaPickerViewController

- (instancetype _Nonnull )initWithOptions:(WPMediaPickerOptions *_Nonnull)options {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _mediaPicker = [[WPMediaPickerViewController alloc] initWithOptions:[options copy]];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _mediaPicker = [[WPMediaPickerViewController alloc] initWithOptions:[WPMediaPickerOptions new]];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _mediaPicker = [[WPMediaPickerViewController alloc] initWithOptions:[WPMediaPickerOptions new]];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];    
    [self setupMediaPickerViewController];
}

- (void)setupMediaPickerViewController {
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    self.privateDataSource = [[WPPHAssetDataSource alloc] init];    
    self.mediaPicker.dataSource = self.privateDataSource;

    [self addChildViewController:self.mediaPicker];
    [self overridePickerTraits];
    
    self.mediaPicker.view.frame = self.view.bounds;
    self.mediaPicker.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mediaPicker.collectionView.collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    [self.view addSubview:self.mediaPicker.view];
    [self.mediaPicker didMoveToParentViewController:self];

    self.mediaToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    self.mediaToolbar.items = @[
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(mediaCanceled:)],
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(mediaSelected:)]
                      ];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self configureCollectionView];
}

- (void)configureCollectionView {
    CGFloat photoSpacing = 1.0f;
    CGFloat photoSize;
    CGSize cameraPreviewSize;
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.mediaPicker.collectionView.collectionViewLayout;
    if (self.scrollVertically) {
        CGFloat frameWidth = self.view.frame.size.width;
        NSUInteger numberOfPhotosForLine = [self numberOfPhotosPerRow:frameWidth];

        photoSize = [self.mediaPicker cellSizeForPhotosPerLineCount:numberOfPhotosForLine
                                                       photoSpacing:photoSpacing
                                                         frameWidth:frameWidth];

        // Check the actual width of the content based on the computed cell size
        // How many photos are we actually fitting per line?
        CGFloat totalSpacing = (numberOfPhotosForLine - 1) * photoSpacing;
        numberOfPhotosForLine = floorf((frameWidth - totalSpacing) / photoSize);

        CGFloat contentWidth = (numberOfPhotosForLine * photoSize) + totalSpacing;

        // If we have gaps in our layout, adjust to fit
        if (contentWidth < frameWidth) {
            photoSize = [self.mediaPicker cellSizeForPhotosPerLineCount:numberOfPhotosForLine
                                                           photoSpacing:photoSpacing
                                                             frameWidth:frameWidth];
        }

        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.sectionInset = UIEdgeInsetsMake(2, 0, 0, 0);
        self.mediaPicker.collectionView.alwaysBounceHorizontal = NO;
        self.mediaPicker.collectionView.alwaysBounceVertical = YES;
        cameraPreviewSize = CGSizeMake(photoSize, photoSize);
    } else {
        photoSize = floorf((self.view.frame.size.height - photoSpacing) / 2.0);
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.sectionInset = UIEdgeInsetsMake(0, 5, 0, 5);
        self.mediaPicker.collectionView.alwaysBounceHorizontal = YES;
        self.mediaPicker.collectionView.alwaysBounceVertical = NO;
        cameraPreviewSize = CGSizeMake(1.5*photoSize, 1.5*photoSize);
    }

    layout.itemSize = CGSizeMake(photoSize, photoSize);
    layout.minimumLineSpacing = photoSpacing;
    layout.minimumInteritemSpacing = photoSpacing;    
    WPMediaPickerOptions *options = [self.mediaPicker options];
    options.cameraPreviewSize = cameraPreviewSize;
    [self.mediaPicker setOptions:options];
    [layout invalidateLayout];
}

/**
 Given the provided frame width, this method returns a progressively increasing number of photos 
 to be used in a picker row.
 
 @param frameWidth Width of the frame containing the picker

 @return The number of photo cells to be used in a row. Defaults to 3.
 */
- (NSUInteger)numberOfPhotosPerRow:(CGFloat)frameWidth {
    NSUInteger numberOfPhotos = 3;

    if (frameWidth >= IPhone7PortraitWidth && frameWidth < IPhoneSELandscapeWidth) {
        numberOfPhotos = 4;
    } else if (frameWidth >= IPhoneSELandscapeWidth && frameWidth < IPhone7LandscapeWidth) {
        numberOfPhotos = 5;
    } else if (frameWidth >= IPhone7LandscapeWidth && frameWidth < IPadPortraitWidth) {
        numberOfPhotos = 6;
    } else if (frameWidth >= IPadPortraitWidth && frameWidth < IPadLandscapeWidth) {
        numberOfPhotos = 7;
    } else if (frameWidth >= IPadLandscapeWidth && frameWidth < IPadPro12LandscapeWidth) {
        numberOfPhotos = 9;
    } else if (frameWidth >= IPadPro12LandscapeWidth) {
        numberOfPhotos = 12;
    }

    return numberOfPhotos;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    [self overridePickerTraits];
}

- (void)overridePickerTraits
{
    // Due to an inputView being displayed in its own window, the force touch peek transition
    // doesn't display correctly. Because of this, we'll disable it for the input picker thus forcing
    // long touch to be used instead.
    UITraitCollection *traits = [UITraitCollection traitCollectionWithForceTouchCapability:UIForceTouchCapabilityUnavailable];
    [self setOverrideTraitCollection:[UITraitCollection traitCollectionWithTraitsFromCollections:@[self.traitCollection, traits]] forChildViewController:self.mediaPicker];
}

#pragma mark - WPMediaCollectionDataSource

- (void)setDataSource:(id<WPMediaCollectionDataSource>)dataSource {
    self.mediaPicker.dataSource = dataSource;
}

- (id<WPMediaCollectionDataSource>)dataSource {
    return self.mediaPicker.dataSource;
}

#pragma mark - WPMediaPickerViewControllerDelegate

- (void)setMediaPickerDelegate:(id<WPMediaPickerViewControllerDelegate>)mediaPickerDelegate {
    self.mediaPicker.mediaPickerDelegate = mediaPickerDelegate;
}

- (id<WPMediaPickerViewControllerDelegate>)mediaPickerDelegate {
    return self.mediaPicker.mediaPickerDelegate;
}

- (void)mediaSelected:(UIBarButtonItem *)sender {
    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:didFinishPickingAssets:)]) {
        [self.mediaPickerDelegate mediaPickerController:self.mediaPicker didFinishPickingAssets:self.mediaPicker.selectedAssets];
        [self.mediaPicker resetState:NO];
    }
    
}

- (void)mediaCanceled:(UIBarButtonItem *)sender {
    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerControllerDidCancel:)]) {
        [self.mediaPickerDelegate mediaPickerControllerDidCancel:self.mediaPicker];
        [self.mediaPicker resetState:NO];
    }
}

- (void)showCapture
{
    [self.mediaPicker showCapture];
}

@end
