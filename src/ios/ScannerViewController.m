//
//  ScannerViewController.m
//  BarcodeTestApp
//
//  Created by Carlos Correa on 26/04/2021.
//

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

-(instancetype)initWithScanInstructions:(NSString *)instructions CameraDirection:(CameraDirection)direction ScanOrientation:(ScanOrientation)orientation ScanLine:(bool)lineEnabled ScanButtonEnabled:(bool)buttonEnabled ScanButton:(NSString *)buttonTitle EnableAutoFocus:(BOOL)enableAutoFocus {
    self = [super initWithNibName:nil bundle:nil];
    self.instructionsText = instructions;
    self.scanButtonTitle = buttonTitle;
    self.direction = direction;
    self.orientation = orientation;
    self.lineEnabled = lineEnabled;
    self.scanButtonEnabled = buttonEnabled;
    self.enableAutoFocus = enableAutoFocus;
    return self;
}

- (void)dealloc {
    [self.capture.layer removeFromSuperlayer];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    switch (self.orientation) {
        case kPortrait:
            [[UIDevice currentDevice] setValue:[NSNumber numberWithInt:UIDeviceOrientationPortrait] forKey:@"orientation"];
            break;
        case kLandscape:
            [[UIDevice currentDevice] setValue:[NSNumber numberWithInt:UIDeviceOrientationPortrait] forKey:@"orientation"];
            break;
        default:
            break;
    }
    
    self.informationView.text = self.instructionsText;
    
    self.capture = [[ZXCapture alloc] init];
    self.capture.sessionPreset = AVCaptureSessionPreset1920x1080;
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
    self.capture.focusMode = AVCaptureFocusModeContinuousAutoFocus;
    self.capture.delegate = self;
    
    self.scanning = NO;
    
    self.scanButton.layer.cornerRadius = 25;
    self.scanButton.clipsToBounds = YES;
    self.scanButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.scanButton setTitle:self.scanButtonTitle forState:UIControlStateNormal];
    self.scanButton.hidden = !self.scanButtonEnabled;
    
    self.movingBar.hidden = !self.lineEnabled;
    self.laserGradient.hidden = !self.lineEnabled;
    
    self.view.backgroundColor = UIColor.blackColor;
    
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
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    self.capture.layer.frame = self.view.bounds;
    
    CGFloat scanRectRotation = [self getScanRotation];
    self.capture.rotation = scanRectRotation;
   
    self.capture.layer.frame = self.view.bounds;
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    [self applyRectOfInterest:orientation];
    [self addGradientToView];
    [self animateMovingBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    CGFloat captureRotation = [self getCaptureRotation];
    CGAffineTransform transform = CGAffineTransformMakeRotation((CGFloat)(captureRotation / 180 * M_PI));
    [self.capture setTransform:transform];
    self.capture.layer.frame = UIScreen.mainScreen.bounds;
    _laserGradient.hidden = false;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations{
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

// Comment the added feature: Add gradient to the view for the moving laser effect
- (void)addGradientToView{
    if(!self.lineEnabled) { return; } // Check if line is enabled
    // Create gradient layer for the moving laser effect
    CAGradientLayer *gradientUp = [CAGradientLayer layer];
    
    // Set gradient colors
    gradientUp.colors = @[(id)[UIColor colorWithWhite:1 alpha:0].CGColor,(id)[UIColor whiteColor].CGColor,(id)[UIColor whiteColor].CGColor,(id)[UIColor colorWithWhite:1 alpha:0].CGColor];
    gradientUp.frame = self.laserGradient.bounds; // Set gradient frame
    
    // Set gradient locations
    gradientUp.locations = @[@0.5, @0.5, @0.5, @0.5];
    
    // Insert gradient layer at index 0
    [_laserGradient.layer insertSublayer:gradientUp atIndex:0];
    
    // Store the gradient layer
    self.gradient = gradientUp;
}

// Comment the added feature:
