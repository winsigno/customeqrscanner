// ScannerViewController.h
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger, CameraDirection) {
    kFront,
    kBack
};

typedef NS_ENUM(NSUInteger, ScanOrientation) {
    kAdaptive,
    kPortrait,
    kLandscape
};

@interface ScannerViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate>

@property (weak, nonatomic) IBOutlet UIButton *scanButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *laserDownTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *laserUpTrailingConstraint;
@property (weak, nonatomic) IBOutlet UIView *laserGradient;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *movingBarTopConstraint;
@property (weak, nonatomic) IBOutlet UIView *externalView;
@property (weak, nonatomic) IBOutlet UIView *blurFrame;

- (instancetype)initWithScanInstructions:(NSString*)instructions CameraDirection:(CameraDirection)direction ScanOrientation:(ScanOrientation)orientation ScanLine:(bool)lineEnabled ScanButtonEnabled:(bool)buttonEnabled ScanButton:(NSString*)buttonTitle EnableAutoFocus:(BOOL)enableAutoFocus;  
- (IBAction)closeBtnPressed:(id)sender;

@end
