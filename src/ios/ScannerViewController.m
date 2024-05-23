// ScannerViewController.m

#import "ScannerViewController.h"

@interface ScannerViewController ()

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) AVCaptureMetadataOutput *metadataOutput;
@property (nonatomic) NSString* instructionsText;
@property (nonatomic) NSString* scanButtonTitle;
@property (nonatomic) CameraDirection direction;
@property (nonatomic) ScanOrientation orientation;
@property (nonatomic) bool lineEnabled;
@property (nonatomic) bool scanButtonEnabled;
@property (nonatomic, assign) BOOL enableAutoFocus;

@end

@implementation ScannerViewController

#pragma mark - View Controller Methods

- (instancetype)initWithScanInstructions:(NSString *)instructions CameraDirection:(CameraDirection)direction ScanOrientation:(ScanOrientation)orientation ScanLine:(bool)lineEnabled ScanButtonEnabled:(bool)buttonEnabled ScanButton:(NSString *)buttonTitle EnableAutoFocus:(BOOL)enableAutoFocus {
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

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupCamera];
    [self setupUI];
}

- (void)setupCamera {
    self.session = [[AVCaptureSession alloc] init];
    AVCaptureDevice *device;
    
    switch (self.direction) {
        case kBack:
            device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            break;
        case kFront:
            device = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo][1];
            break;
        default:
            device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            break;
    }

    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (error) {
        NSLog(@"Error getting camera input: %@", error.localizedDescription);
        return;
    }
    
    if ([self.session canAddInput:input]) {
        [self.session addInput:input];
    }
    
    self.metadataOutput = [[AVCaptureMetadataOutput alloc] init];
    if ([self.session canAddOutput:self.metadataOutput]) {
        [self.session addOutput:self.metadataOutput];
        [self.metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        [self.metadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
    }
    
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.previewLayer.frame = self.view.layer.bounds;
    [self.view.layer addSublayer:self.previewLayer];
    
    [self.session startRunning];
}

- (void)setupUI {
    self.informationView.text = self.instructionsText;
    self.scanButton.layer.cornerRadius = 25;
    self.scanButton.clipsToBounds = YES;
    self.scanButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.scanButton.hidden = !self.scanButtonEnabled;
    self.movingBar.hidden = !self.lineEnabled;
    self.view.backgroundColor = UIColor.blackColor;
    [self addGradientToView];
}

- (void)addGradientToView {
    if (!self.lineEnabled) { return; }
    CAGradientLayer *gradientUp = [CAGradientLayer layer];
    gradientUp.colors = @[(id)[UIColor colorWithWhite:1 alpha:0].CGColor, (id)[UIColor whiteColor].CGColor, (id)[UIColor whiteColor].CGColor, (id)[UIColor colorWithWhite:1 alpha:0].CGColor];
    gradientUp.frame = self.laserGradient.bounds;
    gradientUp.locations = @[@0.5, @0.5, @0.5, @0.5];
    [self.laserGradient.layer insertSublayer:gradientUp atIndex:0];
    self.gradient = gradientUp;
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects.count == 0) {
        return;
    }
    
    AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects objectAtIndex:0];
    if ([[metadataObject type] isEqualToString:AVMetadataObjectTypeQRCode]) {
        NSString *qrCodeString = metadataObject.stringValue;
        NSLog(@"Scanned QR Code: %@", qrCodeString);
        [self handleScannedData:qrCodeString];
        [self.session stopRunning];
    }
}

- (void)handleScannedData:(NSString *)data {
    self.decodedLabel.text = data;
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    // Additional processing for scanned data
}

- (IBAction)closeBtnPressed:(id)sender {
    [self.session stopRunning];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
