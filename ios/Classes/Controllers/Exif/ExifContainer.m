//
//  ExifContainer.m
//  camerawesome
//
//  Created by Dimitri Dessus on 30/09/2022.
//

#import <ImageIO/ImageIO.h>
#import <CoreLocation/CoreLocation.h>
#import "ExifContainer.h"

NSString const * kCGImagePropertyProjection = @"ProjectionType";

@interface ExifContainer ()

@property (nonatomic, strong) NSMutableDictionary *imageMetadata;

@property (nonatomic, strong, readonly) NSMutableDictionary *exifDictionary;
@property (nonatomic, strong, readonly) NSMutableDictionary *tiffDictionary;
@property (nonatomic, strong, readonly) NSMutableDictionary *gpsDictionary;
@end

@implementation ExifContainer

- (instancetype)init {
  self = [super init];
  
  if (self) {
    _imageMetadata = [[NSMutableDictionary alloc] init];
  }
  
  return self;
}

- (void)addLocation:(CLLocation *)currentLocation {
  CLLocationDegrees latitude  = currentLocation.coordinate.latitude;
  CLLocationDegrees longitude = currentLocation.coordinate.longitude;
  
  NSString *latitudeRef = nil;
  NSString *longitudeRef = nil;
  
  if (latitude < 0.0) {
    
    latitude *= -1;
    latitudeRef = @"S";
    
  } else {
    latitudeRef = @"N";
  }
  
  if (longitude < 0.0) {
    longitude *= -1;
    longitudeRef = @"W";
  } else {
    longitudeRef = @"E";
  }
  
  self.gpsDictionary[(NSString*)kCGImagePropertyGPSTimeStamp] = [self getUTCFormattedDate:currentLocation.timestamp];
  
  self.gpsDictionary[(NSString*)kCGImagePropertyGPSLatitudeRef] = latitudeRef;
  self.gpsDictionary[(NSString*)kCGImagePropertyGPSLatitude] = [NSNumber numberWithFloat:latitude];
  
  self.gpsDictionary[(NSString*)kCGImagePropertyGPSLongitudeRef] = longitudeRef;
  self.gpsDictionary[(NSString*)kCGImagePropertyGPSLongitude] = [NSNumber numberWithFloat:longitude];
  
  self.gpsDictionary[(NSString*)kCGImagePropertyGPSDOP] = [NSNumber numberWithFloat:currentLocation.horizontalAccuracy];
  self.gpsDictionary[(NSString*)kCGImagePropertyGPSAltitude] = [NSNumber numberWithFloat:currentLocation.altitude];
}

- (void)addUserComment:(NSString*)comment {
  NSString *key = (__bridge_transfer NSString *)kCGImagePropertyExifUserComment;
  [self setValue:comment forExifKey:key];
}

- (void)addCreationDate:(NSDate *)date {
  NSString *dateString = [self getUTCFormattedDate:date];
  NSString *key = (__bridge_transfer NSString *)kCGImagePropertyExifDateTimeOriginal;
  [self setValue:dateString forExifKey:key];
  
}

- (void)addDescription:(NSString*)description {
  [self.tiffDictionary setObject:description forKey:(NSString *)kCGImagePropertyTIFFImageDescription];
}

- (void)addProjection:(NSString *)projection {
  [self setValue:projection forExifKey:kCGImagePropertyProjection];
}

- (void)setValue:(NSString *)key forExifKey:(NSString *)value {
  [self.exifDictionary setObject:value forKey:key];
}

- (NSDictionary *)exifData {
  return self.imageMetadata;
}

#pragma mark - Getters

- (NSMutableDictionary *)exifDictionary {
  return [self dictionaryForKey:(NSString*)kCGImagePropertyExifDictionary];
}

- (NSMutableDictionary *)tiffDictionary {
  return [self dictionaryForKey:(NSString*)kCGImagePropertyTIFFDictionary];
}

- (NSMutableDictionary *)gpsDictionary {
  return [self dictionaryForKey:(NSString*)kCGImagePropertyGPSDictionary];
}

- (NSMutableDictionary *)dictionaryForKey:(NSString *)key {
  NSMutableDictionary *dict = self.imageMetadata[key];
  
  if (!dict) {
    dict = [[NSMutableDictionary alloc] init];
    self.imageMetadata[key] = dict;
  }
  
  return dict;
}

#pragma mark - Helpers

- (NSString *)getUTCFormattedDate:(NSDate *)localDate {
  
  static NSDateFormatter *dateFormatter = nil;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"];
    
  });
  
  
  return [dateFormatter stringFromDate:localDate];
}

@end
