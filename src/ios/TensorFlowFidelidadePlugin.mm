//
//  TensorFlowFidelidadePlugin.mm
//
//  Created by Andre Grillo on 15/12/2019.
//  Copyright © 2019 Andre Grillo. All rights reserved.
//

#import <TensorIO/TensorIO-umbrella.h>
#import <Cordova/CDV.h>

@interface TensorFlowFidelidadePlugin: CDVPlugin {
    id model;
    UIImage *image;
    CDVPluginResult *pluginResult;
}

@property (strong, nonatomic) CDVInvokedUrlCommand* commandHelper;
- (void)loadModel:(CDVInvokedUrlCommand*)command;

@end

@implementation TensorFlowFidelidadePlugin

- (void)loadModel:(CDVInvokedUrlCommand*)command {
    
    self.commandHelper = command;
    image = [self decodeBase64ToImage:[command.arguments objectAtIndex:1]];
    [command.arguments objectAtIndex:1];
    NSString *modelName = [command.arguments objectAtIndex:0];
    NSString *path = [NSBundle.mainBundle bundlePath];
    NSError *error;
    
    // Checks the model index on ModelBundleManager Array
    int modelIndex = 3;
    [TIOModelBundleManager.sharedManager loadModelBundlesAtPath:path error:&error];
    for (int i = 0; i < 3; i++) {
        if ([modelName isEqualToString:TIOModelBundleManager.sharedManager.modelBundles[i].identifier]) {
            modelIndex = i;
        }
    }
    
    //Checks if the modelIndex was found
    if (modelIndex > 2) {
        NSLog(@"Error: Model not found.");
        return;
    }
    
    TIOModelBundle *bundle = TIOModelBundleManager.sharedManager.modelBundles[modelIndex];
    model = [bundle newModel];
    
    UIImage *resizedImage;
    
    if ([modelName isEqualToString:@"enq_model"]){
        //Processa tamanho da imagem (resize)
        if (image.size.width == 64.0 && image.size.height == 64.0) {
            [self runModelEnquadramento:image];
        } else {
            CGSize modelImageSize = CGSizeMake(64.0, 64.0);
            resizedImage = [self resizeImage:image tosize:(modelImageSize)];
            [self runModelEnquadramento:resizedImage];
        }
    }
    else if ([modelName isEqualToString:@"quality_model"]){
        //Processa tamanho da imagem (resize)
        if (image.size.width == 64.0 && image.size.height == 64.0) {
            [self runModelEnquadramento:image];
        } else {
            CGSize modelImageSize = CGSizeMake(224.0, 224.0);
            resizedImage = [self resizeImage:image tosize:(modelImageSize)];
            [self runModelQuality:resizedImage];
        }
    }
    else if ([modelName isEqualToString:@"unet_vehicle_model"]){
        //Processa tamanho da imagem (resize)
        if (image.size.width == 64.0 && image.size.height == 64.0) {
            [self runModelEnquadramento:image];
        } else {
            CGSize modelImageSize = CGSizeMake(224.0, 224.0);
            resizedImage = [self resizeImage:image tosize:(modelImageSize)];
            [self runModel3];
        }
    }
}

- (UIImage *)decodeBase64ToImage:(NSString *)strEncodeData {
  NSData *data = [[NSData alloc]initWithBase64EncodedString:strEncodeData options:NSDataBase64DecodingIgnoreUnknownCharacters];
  return [UIImage imageWithData:data];
}

- (UIImage *)resizeImage:(UIImage *)image tosize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)runModelEnquadramento:(UIImage *)image{
    dispatch_async(dispatch_get_main_queue(), ^{
        TIOPixelBuffer *buffer = [[TIOPixelBuffer alloc] initWithPixelBuffer:image.pixelBuffer orientation:kCGImagePropertyOrientationUp];
        NSDictionary *inference = (NSDictionary *)[self->model runOn:buffer];
        NSLog(@"INFERENCE: %@",inference);
        NSDictionary<NSString*,NSNumber*> *classification = inference[@"output"];
        __block NSString *highKey;
        __block NSNumber *highVal;
        [classification enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSNumber *val, BOOL *stop) {
            if (highVal == nil || [val compare:highVal] == NSOrderedDescending) {
                highKey = key;
                highVal = val;
            }
        }];
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:highKey];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.commandHelper.callbackId];
        //NSLog(@"%@: %@".capitalizedString, highKey, highVal);
        //self.label.text = [NSString stringWithFormat:@"%@: %@", highKey, highVal];
    });
}

- (void)runModelQuality:(UIImage *)image{
    dispatch_async(dispatch_get_main_queue(), ^{
        TIOPixelBuffer *buffer = [[TIOPixelBuffer alloc] initWithPixelBuffer:image.pixelBuffer orientation:kCGImagePropertyOrientationUp];
        NSDictionary *inference = (NSDictionary *)[self->model runOn:buffer];
        NSArray *result = inference[@"output"];
        NSLog(@"%@",result);
        if ([result[0] floatValue] > [result[1] floatValue]) {
            NSLog(@"QUALIDADE RUIM! Valor da inferência: %@",result[0]);
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"false"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.commandHelper.callbackId];
        } else {
            NSLog(@"QUALIDADE BOA! Valor da inferência: %@",result[1]);
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"true"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.commandHelper.callbackId];
        }
    });
}

- (void)runModel3{
    dispatch_async(dispatch_get_main_queue(), ^{
    // code here
    });
}

@end
