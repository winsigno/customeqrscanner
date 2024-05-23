// ScannerViewController.m

#import "ScannerViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/CoreAnimation.h>
#import "OSBarcodeErrors.h"

@interface ScannerViewController ()

@property (nonatomic, strong) ZXCapture *capture;
@property (nonatomic, weak) IBOutlet UILabel *informationView;
@property (nonatomic, weak) IBOutlet UIView *movingBar;
@property (nonatomic, weak) IBOutlet UIView *scanRectView;
@property (nonatomic, weak) IBOutlet UILabel *decodedLabel;
@property (nonatomic, weak) UIView *captureView;
@property (nonatomic, weak) CAGradientLayer *gradient;
@property (nonatomic) BOOL scanning;
@property (nonatomic) BOOL isFirstApplyOrientation;
@property (nonatomic) NSString* instructionsText;
@property (nonatomic) NSString* scanButtonTitle;
@property (nonatomic) CameraDirection direction;
@property (nonatomic) ScanOrientation orientation;
@property (nonatomic) bool lineEnabled;
@property (nonatomic) bool scanButtonEnabled;
@property (nonatomic, assign) BOOL enableAutoFocus;

@end

@implementation ScannerViewController {
    CALayer *frameLayer;
    CGAffineTransform _captureSizeTransform;
}

#pragma mark - View Controller Methods

// Initialization method with parameters
-(instancetype)initWithScanInstructions:(NSString *)instructions CameraDirection:(CameraDirection)direction ScanOrientation:(ScanOrientation)orientation ScanLine:(bool)lineEnabled ScanButtonEnabled:(bool)buttonEnabled ScanButton:(NSString *)buttonTitle EnableAutoFocus:(BOOL)enableAutoFocus {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.instructionsText = instructions;
        self.scanButtonTitle = buttonTitle;
        self.direction = direction;
        self.orientation = orientation;
        self.lineEnabled = lineEnabled;
        self.scanButtonEnabled = buttonEnabled;
        self.enableAutoFocus = enableAutoFocus;
    }
    return self;
}

// Dealloc method
- (void)dealloc {
    [self.capture.layer removeFromSuperlayer];
}

// View did load
- (void)viewDidLoad {
    [super viewDidLoad];
    // Setup UI elements
    [self setupUI];
    // Configure capture settings
    [self configureCapture];
    // Start capturing
    [self startCapturing];
    // Add gradient for moving laser effect
    [self addGradientToView];
}

// View will appear
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Adjust capture frame
    [self adjustCaptureFrame];
    // Show laser g
