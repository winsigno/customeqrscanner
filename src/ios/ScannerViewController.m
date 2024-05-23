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
    // Show laser gradient
    self.laserGradient.hidden = false;
}

// Supported interface orientations
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    switch (self.orientation) {
        case kAdaptive:
            return UIInterfaceOrientationMaskAll;
        case kPortrait:
            return UIInterfaceOrientationMaskPortrait;
        case kLandscape:
            return UIInterfaceOrientationMaskLandscape;
        default:
            return UIInterfaceOrientationMaskAll;
    }
}

// Setup UI elements
- (void)setupUI {
    // Set instructions text
    self.informationView.text = self.instructionsText;
    // Customize scan button
    self.scanButton.layer.cornerRadius = 25;
    self.scanButton.clipsToBounds = YES;
    self.scanButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.scanButton.hidden = !self.scanButtonEnabled;
    // Hide moving bar if not enabled
    self.movingBar.hidden = !self.lineEnabled;
}

// Configure capture settings
- (void)configureCapture {
    // Initialize capture object
    self.capture = [[ZXCapture alloc] init];
    self.capture.sessionPreset = AVCaptureSessionPreset1920x1080;
    // Set camera direction
    [self setCameraDirection];
    // Set focus mode
    [self setFocusMode];
    // Set delegate
    self.capture.delegate = self;
    // Define the scan area (rect of interest)
    [self defineScanArea];
}

// Start capturing
- (void)startCapturing {
    self.scanning = NO;
    // Add capture layer to view
    UIView* cap = [[UIView alloc] init];
    [cap setTranslatesAutoresizingMaskIntoConstraints:false];
    [self.view addSubview:cap];
    [[cap.topAnchor constraintEqualToAnchor:self.view.topAnchor] setActive:YES];
    [[cap.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor] setActive:YES];
    [[cap.rightAnchor constraintEqualToAnchor:self.view.rightAnchor] setActive:YES];
    [[cap.leftAnchor constraintEqualToAnchor:self.view.leftAnchor] setActive:YES];
    [cap.layer addSublayer:self.capture.layer];
    [self.view sendSubviewToBack:cap];
    self.captureView = cap;
}

// Add gradient to the view for the moving laser effect
- (void)addGradientToView {
    if(!self.lineEnabled) { return; } // Check if line is enabled
    // Create gradient layer for the moving laser effect
    CAGradientLayer *gradientUp = [CAGradientLayer layer];
    // Set gradient colors
    gradientUp.colors = @[(id)[UIColor colorWithWhite:1 alpha:0].CGColor,(id)[UIColor whiteColor].CGColor,(id)[UIColor whiteColor].CGColor,(id)[UIColor colorWithWhite:1 alpha:0].CGColor];
    gradientUp.frame = self.laserGradient.bounds; // Set gradient frame
    // Set gradient locations
    gradientUp.locations = @[@0.5, @0.5, @0.5, @0.5];
    // Insert gradient layer at index 0
    [self.laserGradient.layer insertSublayer:gradientUp atIndex:0];
    // Store the gradient layer
    self.gradient = gradientUp;
}

// Set camera direction based on the specified direction
- (void)setCameraDirection {
    switch (self.direction) {
        case kBack:
            self.capture.camera = self.capture.back;
            break;
        case kFront:
            self.capture.camera = self.capture.front;
            break;
        default:
            self.capture.camera = self.capture.back;
            break;
    }
}

// Set focus mode
- (void)setFocusMode {
    if (self.enableAutoFocus) {
        self.capture.focusMode = AVCaptureFocusModeContinuousAutoFocus;
    } else {
        self.capture.focusMode = AVCaptureFocusModeLocked;
    }
}

// Adjust capture frame based on orientation
- (void)adjustCaptureFrame {
    CGFloat captureRotation = [self getCaptureRotation];
    CGAffineTransform transform = CGAffineTransformMakeRotation((CGFloat)(captureRotation / 180 * M_PI));
    [self.capture setTransform:transform];
    self.capture.layer.frame = UIScreen.mainScreen.bounds;
}

// Define scan area (rect of interest)
- (void)defineScanArea {
    // Assuming scanRectView is the view that defines the scanning area
    CGRect scanRect = self.scanRectView.frame;
    self.capture.scanRect = scanRect;
}

// Get capture rotation based on orientation
- (CGFloat)getCaptureRotation {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGFloat rotation;
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            rotation = 0;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            rotation = 90;
            break;
        case UIInterfaceOrientationLandscapeRight:
            rotation = -90;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            rotation = 180;
            break;
        default:
            rotation = 0;
            break;
    }
    return rotation;
}

// ZXCaptureDelegate method to handle captured result
- (void)captureResult:(ZXCapture *)capture result:(ZXResult *)result {
    if (!result || !result.text) {
        return;
    }
    // Process the scanned barcode data
    NSLog(@"Scanned data: %@", result.text);
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate); // Provide haptic feedback
    [self handleScannedData:result.text];
}

// Handle the scanned data
- (void)handleScannedData:(NSString *)data {
    self.decodedLabel.text = data;
    // Add any further processing of the scanned data here
}

// Close button action
- (IBAction)closeBtnPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
