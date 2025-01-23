//
//  ExifContainer.h
//  camerawesome
//
//  Created by Dimitri Dessus on 30/09/2022.
//  Taken from: https://github.com/Nikita2k/SimpleExif

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLLocation;

@interface ExifContainer : NSObject

- (void)addLocation:(CLLocation *)currentLocation;
- (void)addUserComment:(NSString *)comment;
- (void)addCreationDate:(NSDate *)date;
- (void)addDescription:(NSString *)description;
- (void)addProjection:(NSString *)projection;

- (void)setValue:(NSString *)key forExifKey:(NSString *)value;

- (NSDictionary *)exifData;
@end

NS_ASSUME_NONNULL_END
