#import <Foundation/Foundation.h>

@class ESSBeaconScanner;

// Delegates to the ESSBeaconScanner should implement this protocol.
@protocol ESSBeaconScannerDelegate <NSObject>

@optional

- (void)beaconScanner:(ESSBeaconScanner *)scanner
           didFindURL:(NSURL *)url;

@end

@interface ESSBeaconScanner : NSObject

@property(nonatomic, weak) id<ESSBeaconScannerDelegate> delegate;


- (void)startScanning;
- (void)stopScanning;

@end
