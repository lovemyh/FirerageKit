//
//  UIImageView+FRFaceAwareFill.m
//  FirerageKit
//
//  Created by Aidian.Tang on 14-5-29.
//  Copyright (c) 2014年 Illidan.Firerage. All rights reserved.
//

#import "UIImageView+FRFaceAwareFill.h"
#import "SDImageCache.h"
#import "objc/runtime.h"

static char operationKey;

@implementation UIImageView (FRFaceAwareFill)

- (void)cancelCurrentImageLoad {
    // Cancel in progress downloader from queue
    id <SDWebImageOperation> operation = objc_getAssociatedObject(self, &operationKey);
    if (operation) {
        [operation cancel];
        objc_setAssociatedObject(self, &operationKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)setFaceAwareFilledImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(SDWebImageCompletedBlock)completedBlock
{
    [self setImageWithURL:url placeholderImage:placeholder faceAwareFilled:YES cropProportion:self.frame.size.width / self.frame.size.height cropType:FRCropTopType completed:completedBlock];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder faceAwareFilled:(BOOL)faceAwareFilled cropProportion:(CGFloat)proportion cropType:(FRCropType)cropType completed:(SDWebImageCompletedBlock)completedBlock
{
    [self cancelCurrentImageLoad];
    
    self.image = placeholder;
    
    if (!url) {
        if (completedBlock) {
            completedBlock(nil, nil, SDImageCacheTypeNone);
        }
        return;
    }
    
    CGSize cropSize = CGSizeMake(self.frame.size.width * 2, self.frame.size.height * 2);
    NSString *cacheKey = [NSString stringWithFormat:@"%@cacheForSize%@faceAwareFilled%dproportion%fcropType%d", url.absoluteString, NSStringFromCGSize(cropSize), faceAwareFilled, proportion, cropType];
    [[SDImageCache sharedImageCache] queryDiskCacheForKey:cacheKey done:^(UIImage *cacheImage, SDImageCacheType cacheType) {
        if (cacheImage) {
            self.image = cacheImage;
            if (completedBlock) {
                completedBlock(cacheImage, nil, SDImageCacheTypeDisk);
            }
        } else {
            __weak UIImageView *wself = self;
            id <SDWebImageOperation> operation = [SDWebImageManager.sharedManager downloadWithURL:url options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                if (!wself) return;
                dispatch_main_sync_safe(^{
                    if (!wself) return;
                    if (image) {
                        if (faceAwareFilled) {
                            [image faceAwareFillWithSize:cropSize cropType:cropType block:^(UIImage *faceAwareFilledImage) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    wself.image = faceAwareFilledImage;
                                });
                                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                                    [[SDImageCache sharedImageCache] storeImage:faceAwareFilledImage forKey:cacheKey];
                                });
                                if (completedBlock && finished) {
                                    completedBlock(faceAwareFilledImage, error, cacheType);
                                }
                            }];
                        } else {
                            UIImage *cropImage = [image cropWithProportion:proportion type:cropType];
                            wself.image = cropImage;
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                                [[SDImageCache sharedImageCache] storeImage:cropImage forKey:cacheKey];
                            });
                            if (completedBlock && finished) {
                                completedBlock(cropImage, error, cacheType);
                            }
                        }
                    } else if (completedBlock && finished) {
                        completedBlock(image, error, cacheType);
                    }
                });
            }];
            objc_setAssociatedObject(self, &operationKey, operation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }];
}

- (void)setCropImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(SDWebImageCompletedBlock)completedBlock
{
    [self setCropImageWithURL:url placeholderImage:placeholder cropType:FRCropTopType completed:completedBlock];
}

- (void)setCropImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder cropType:(FRCropType)cropType completed:(SDWebImageCompletedBlock)completedBlock
{
    [self setImageWithURL:url placeholderImage:placeholder faceAwareFilled:NO cropProportion:self.frame.size.width / self.frame.size.height cropType:cropType completed:completedBlock];
}

@end