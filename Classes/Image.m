//
//  Image.m
//  LatestChatty2
//
//  Created by Alex Wayne on 3/28/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Image.h"


@implementation Image

@synthesize image;

- (id)initWithImage:(UIImage *)anImage {
  [super init];
  self.image = anImage;
  return self;
}



- (NSData *)compressJpeg:(CGFloat)quality {
  return UIImageJPEGRepresentation(image, quality);
}

- (NSString *)base64String {
  NSData *imageData = [self compressJpeg:0.7];
  return [[NSString base64StringFromData:imageData length:[imageData length]] stringByUrlEscape];
}

- (NSString *)uploadAndReturnImageUrl {
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
  // Clean and resize image
  [self autoRotateAndScale:800];
  
  // Setup raw image data
  NSString *imageBase64Data = [self base64String];
  
  // Request setup
  NSString *urlString = [Model urlStringWithPath:@"/images"];
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
  [request setHTTPMethod:@"POST"];
  
  // Create the post body
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *username = [[defaults stringForKey:@"username"] stringByUrlEscape];
  NSString *password = [[defaults stringForKey:@"password"] stringByUrlEscape];
  NSString *postBody = [NSString stringWithFormat:@"username=%@&password=%@&filename=iPhoneUpload.jpg&image=%@", username, password, imageBase64Data];
  [request setHTTPBody:[postBody dataUsingEncoding:NSASCIIStringEncoding]];
  
  // Send the request
  NSHTTPURLResponse *response;
  NSError *error;
  NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
  
  // Cleanup the request
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
  [request release];
  
  // Process response
  NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
  NSDictionary *responseDictionary = [responseString JSONValue];
  
  // Check for success
  NSString *imageURL = [responseDictionary objectForKey:@"success"];
  if (imageURL) {
    [responseString release];
    return imageURL;
  }
  
  // Failed
  NSLog(@"Upload Failed: %@", responseString);
  [responseString release];
  return nil;
}

#pragma mark Image Processor
// Code from: http://discussions.apple.com/thread.jspa?messageID=7949889
- (void)autoRotateAndScale:(NSUInteger)maxDimension {
	CGImageRef imgRef = image.CGImage;
	
	CGFloat width = CGImageGetWidth(imgRef);
	CGFloat height = CGImageGetHeight(imgRef);
	
	
	CGAffineTransform transform = CGAffineTransformIdentity;
	CGRect bounds = CGRectMake(0, 0, width, height);
	if (width > maxDimension || height > maxDimension) {
		CGFloat ratio = width/height;
		if (ratio > 1) {
			bounds.size.width = maxDimension;
			bounds.size.height = bounds.size.width / ratio;
		}
		else {
			bounds.size.height = maxDimension;
			bounds.size.width = bounds.size.height * ratio;
		}
	}
	
	CGFloat scaleRatio = bounds.size.width / width;
	CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
	CGFloat boundHeight;
	UIImageOrientation orient = image.imageOrientation;
	switch(orient) {
			
		case UIImageOrientationUp: //EXIF = 1
			transform = CGAffineTransformIdentity;
			break;
			
		case UIImageOrientationUpMirrored: //EXIF = 2
			transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
			transform = CGAffineTransformScale(transform, -1.0, 1.0);
			break;
			
		case UIImageOrientationDown: //EXIF = 3
			transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
			transform = CGAffineTransformRotate(transform, M_PI);
			break;
			
		case UIImageOrientationDownMirrored: //EXIF = 4
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
			transform = CGAffineTransformScale(transform, 1.0, -1.0);
			break;
			
		case UIImageOrientationLeftMirrored: //EXIF = 5
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
			transform = CGAffineTransformScale(transform, -1.0, 1.0);
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
			break;
			
		case UIImageOrientationLeft: //EXIF = 6
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
			break;
			
		case UIImageOrientationRightMirrored: //EXIF = 7
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeScale(-1.0, 1.0);
			transform = CGAffineTransformRotate(transform, M_PI / 2.0);
			break;
			
		case UIImageOrientationRight: //EXIF = 8
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
			transform = CGAffineTransformRotate(transform, M_PI / 2.0);
			break;
			
		default:
			[NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
			
	}
	
	UIGraphicsBeginImageContext(bounds.size);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
		CGContextScaleCTM(context, -scaleRatio, scaleRatio);
		CGContextTranslateCTM(context, -height, 0);
	}
	else {
		CGContextScaleCTM(context, scaleRatio, -scaleRatio);
		CGContextTranslateCTM(context, 0, -height);
	}
	
	CGContextConcatCTM(context, transform);
	
	CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
	UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	self.image = imageCopy;
}

@end
