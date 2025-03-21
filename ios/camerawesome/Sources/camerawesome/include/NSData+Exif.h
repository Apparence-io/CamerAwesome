//
//  UIImage+Exif.h
//  camerawesome
//
//  Created by Dimitri Dessus on 30/09/2022.
//  Modified from: https://github.com/Nikita2k/SimpleExif

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ExifContainer;

@interface NSData (Exif)

- (NSData *)addExif:(ExifContainer *)container;

@end

NS_ASSUME_NONNULL_END
