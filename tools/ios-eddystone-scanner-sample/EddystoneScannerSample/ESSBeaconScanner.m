#import <CoreBluetooth/CoreBluetooth.h>

#import "ESSBeaconScanner.h"
#import "ESSEddystone.h"


@interface ESSBeaconScanner () <CBCentralManagerDelegate> {
  CBCentralManager *_centralManager;
  dispatch_queue_t _beaconOperationsQueue;

  BOOL _shouldBeScanning;
}
@end


@implementation ESSBeaconScanner

- (instancetype)init {
  if ((self = [super init]) != nil) {
    const char *const kBeaconsOperationQueueName = "kESSBeaconScannerBeaconsOperationQueueName";
    _beaconOperationsQueue = dispatch_queue_create(kBeaconsOperationQueueName, NULL);
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                           queue:_beaconOperationsQueue];
  }

  return self;
}

- (void)startScanning {
  dispatch_async(_beaconOperationsQueue, ^{
    if (_centralManager.state != CBCentralManagerStatePoweredOn) {
      NSLog(@"CBCentralManager state is %ld, cannot start or stop scanning",
            (long)_centralManager.state);
      _shouldBeScanning = YES;
    } else {
      NSLog(@"Starting to scan for Eddystones");
      NSString *const kESSEddystoneServiceID = @"FEAA";
      NSArray *services = @[
          [CBUUID UUIDWithString: kESSEddystoneServiceID]
      ];
      [_centralManager scanForPeripheralsWithServices:services options: nil];
    }
  });
}

- (void)stopScanning {
  _shouldBeScanning = NO;
  [_centralManager stopScan];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
  if (central.state == CBCentralManagerStatePoweredOn && _shouldBeScanning) {
    [self startScanning];
  }
}

// This will be called from the |beaconsOperationQueue|.
- (void)centralManager:(CBCentralManager *)central
    didDiscoverPeripheral:(CBPeripheral *)peripheral
        advertisementData:(NSDictionary *)advertisementData
                     RSSI:(NSNumber *)RSSI {
  NSDictionary *serviceData = advertisementData[CBAdvertisementDataServiceDataKey];
  NSData *beaconServiceData = serviceData[[ESSBeaconInfo eddystoneServiceID]];

  ESSFrameType frameType = [ESSBeaconInfo frameTypeForFrame:beaconServiceData];

  if (frameType == kESSEddystoneURLFrameType) {
    NSURL *url = [ESSBeaconInfo parseURLFromFrameData:beaconServiceData];
    // Report the sighted URL frame.
    if ([_delegate respondsToSelector:@selector(beaconScanner:didFindURL:)]) {
      [_delegate beaconScanner:self didFindURL:url];
    }
  } else {
    NSLog(@"Unsupported frame type (%d) detected. Ignorning.", (int)frameType);
  }
}


@end
