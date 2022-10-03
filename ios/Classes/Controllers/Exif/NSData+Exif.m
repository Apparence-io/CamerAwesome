//
//  UIImage+Exif.m
//  camerawesome
//
//  Created by Dimitri Dessus on 30/09/2022.
//

#import "NSData+Exif.h"

#import <ImageIO/ImageIO.h>
#import "NSData+Exif.h"
#import "ExifContainer.h"

@implementation NSData (Exif)

- (NSData *)addExif:(ExifContainer *)container {
  CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef) self, NULL);
  
  CFStringRef UTI = CGImageSourceGetType(source);
  
  NSMutableData *dest_data = [NSMutableData data];
  CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)dest_data, UTI, 1, NULL);
  
  if (!destination) {
    NSLog(@"Error: Could not create image destination");
  }
  
  CGImageDestinationAddImageFromSource(destination, source, 0, (__bridge CFDictionaryRef) container.exifData);
  BOOL success = NO;
  success = CGImageDestinationFinalize(destination);
  
  if (!success) {
    NSLog(@"Error: Could not create data from image destination");
  }
  
  CFRelease(destination);
  CFRelease(source);
  
  return dest_data;
}

@end
