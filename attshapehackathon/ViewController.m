//
//  ViewController.m
//  CALHACKS
//
//  Created by Kevin Frans on 10/9/15.
//  Copyright © 2015 Kevin Frans. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/CGImageProperties.h>
#import <CoreLocation/CoreLocation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface ViewController () <AVAudioRecorderDelegate>{
    AVAudioRecorder *recorder;
    NSMutableDictionary *recorderSettings;
    NSString *recorderFilePath;
    AVAudioPlayer *audioPlayer;
    NSString *audioFileName;
}

@end

#define dWidth self.view.frame.size.width
#define dHeight self.view.frame.size.height

@implementation ViewController
{
    AVCaptureStillImageOutput* stillImageOutput;
    UIImageView* capturedView;
    UIButton* capture;
    UILabel* label;
    int count;
}




+ (Class)layerClass
{
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureDevice *)frontCamera {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionFront) {
            return device;
        }
    }
    return nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    session.sessionPreset = AVCaptureSessionPresetHigh;
    AVCaptureDevice *device = [self frontCamera];
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    [session addInput:input];
    AVCaptureVideoPreviewLayer *newCaptureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    newCaptureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    newCaptureVideoPreviewLayer.frame = CGRectMake(0, 0, dWidth, dHeight);
    //    newCaptureVideoPreviewLayer.la
    [self.view.layer addSublayer:newCaptureVideoPreviewLayer];
    [session startRunning];
    
    //    capturedView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, dWidth, dHeight)];
    //    //    capturedView.image = image;
    //    [self.view addSubview:capturedView];
    
    
    stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [stillImageOutput setOutputSettings:outputSettings];
    [session addOutput:stillImageOutput];
    
    
    [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(tick:) userInfo:nil repeats:YES];
    
    count = 3;
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(0, 500, dWidth, 100)];
    label.text = @"3";
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont boldSystemFontOfSize:60];
    [self.view addSubview:label];
    
//    double delayInSeconds = 2.0;
//    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
//    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    
    [self record];
//    });

    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
    [recorder setDelegate:self];
    [super viewDidLoad];
    
}

//MARK:voice recgnition stuff

#define DOCUMENTS_FOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]

- (void) record{
    NSMutableDictionary* recordSetting = [[NSMutableDictionary alloc]init];
    [recordSetting setValue :[NSNumber  numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:11025.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
    [recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    
    NSError *error = nil;
    
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [path objectAtIndex:0];
    NSString *myDBnew = [documentsDirectory stringByAppendingPathComponent:@"test.wav"];
    NSURL *recordedTmpFile = [NSURL fileURLWithPath:myDBnew];
    
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setURL:recordedTmpFile forKey:@"Test1"];
    [prefs synchronize];
    
    NSArray *dirPaths;
    NSString *docsDir;
    
    recorder = [[AVAudioRecorder alloc] initWithURL:recordedTmpFile settings:recordSetting error:&error];
    [recorder prepareToRecord];
    [recorder record];
    
    
    NSData* mydata = [NSData dataWithContentsOfURL:recordedTmpFile];
    
    
    NSLog(@"Using File called: %@",recordedTmpFile);
    
    NSString *path2 = @"https://stream.watsonplatform.net/speech-to-text/api/v1/recognize?timestamps=true&word_alternatives_threshold=0.9&continuous=true";
    
    NSLog(@"%@", path2);
    
    NSMutableURLRequest* _request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:path2]];
    [_request setHTTPMethod:@"POST"];
    [_request addValue:@"audio/wav" forHTTPHeaderField:@"Content-type"];
    
    NSMutableData *body = [NSMutableData data];
    
    
    NSString *jsonString = [NSString stringWithFormat:@"username:\14b72252-e378-4b0a-9cc6-117b1e7728f7, password:0udTrbZeCBqq,%@", mydata];
    
    NSArray *keys = [NSArray arrayWithObjects: @"username",@"password",@"isOnline",@"username", nil];
    
    [_request setHTTPBody:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
    NSURLResponse *response = nil;
    NSData *_connectionData = [self sendSynchronousRequest:_request returningResponse:&response error:&error];
    
    
    NSString *myString = [[NSString alloc] initWithData:_connectionData encoding:NSUTF8StringEncoding];
    NSLog(@"%@",myString);
    NSLog(@"awecdioaemwmeidmi");
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    
        [self playback];
    });
}

-(void) playback{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    [audioSession setActive:YES error:nil];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:[prefs URLForKey:@"Test1"] error:nil];
    
    player.delegate = self;
    [player setNumberOfLoops:0];
    player.volume = 1;
    [player prepareToPlay];
    [player play];
}


//MARK:camera stuff
-(void) tick:(NSTimer*)timer
{
    count = count - 1;
    label.text = [NSString stringWithFormat:@"%d",count];
    if(count == 0)
    {
        count = 10;
        [self capture];
    }
}

-(void) capture
{
    
    UIView* v = [[UIView alloc] initWithFrame: CGRectMake(0, 0, dWidth, dHeight)];
    [self.view addSubview: v];
    v.backgroundColor = [UIColor whiteColor];
    [UIView animateWithDuration:0.2 delay:0.0 options:
     UIViewAnimationOptionCurveEaseIn animations:^{
         v.backgroundColor = [UIColor clearColor];
     } completion:^ (BOOL completed) {
         [v removeFromSuperview];
     }];
    
    
    [[NSUserDefaults standardUserDefaults] setInteger:[[NSUserDefaults standardUserDefaults] integerForKey:@"snap"]+1 forKey:@"snap"];
    
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in stillImageOutput.connections)
    {
        for (AVCaptureInputPort *port in [connection inputPorts])
        {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] )
            {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection)
        {
            break;
        }
    }
    
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
     {
         CFDictionaryRef exifAttachments = CMGetAttachment( imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
         if (exifAttachments)
         {
             // Do something with the attachments.
             //             NSLog(@"attachements: %@", exifAttachments);
         } else {
             NSLog(@"no attachments");
         }
         
         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
         
         UIImage *image = [[UIImage alloc] initWithData:imageData];
         
         [self saveImage:image withImageName:@"hi"];
         
         NSString* path = [NSString stringWithFormat:@"https://gateway-a.watsonplatform.net/visual-recognition/api/v3/classify?api_key=82422138f175d04931e20854d49e9de6b422c023&version=2016-05-20&images_file=hi.jpg"];
         
         NSLog(@"%@", path);
         
         NSMutableURLRequest* _request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:path]];
         [_request setHTTPMethod:@"POST"];
         [_request addValue:@"en" forHTTPHeaderField:@"Accept-language"];
         NSData *agooodname = UIImageJPEGRepresentation(image, 1);
         [_request setHTTPBody:agooodname];
         
         NSURLResponse *response = nil;
         
         NSData *_connectionData = [self sendSynchronousRequest:_request returningResponse:&response error:&error];
         
         
//         NSLog(@"%@", _connectionData);
         
         NSString *myString = [[NSString alloc] initWithData:_connectionData encoding:NSUTF8StringEncoding];
         NSLog(@"%@",myString);
     }];
}

- (void)saveImage:(UIImage*)image withImageName:(NSString*)imageName {
    
    NSData *imageData = UIImageJPEGRepresentation(image, 0.2f);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *fullPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", imageName]];
    
    [fileManager createFileAtPath:fullPath contents:imageData attributes:nil];
    NSLog(@"image saved");
    
}

- (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error
{
    
    NSError __block *err = NULL;
    NSData __block *data;
    BOOL __block reqProcessed = false;
    NSURLResponse __block *resp;
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable _data, NSURLResponse * _Nullable _response, NSError * _Nullable _error) {
        resp = _response;
        err = _error;
        data = _data;
        reqProcessed = true;
    }] resume];
    
    while (!reqProcessed) {
        [NSThread sleepForTimeInterval:0];
    }
    
    *response = resp;
    *error = err;
    return data;
}


-(void) sendRequest:(NSURLRequest*) request
{
    
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         if (error)
         {
             NSLog(@"Error,%@", [error localizedDescription]);
         }
         else
         {
             dispatch_async(dispatch_get_main_queue(), ^{
                 //                 bg.backgroundColor = [UIColor blueColor];
                 NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]);
             });
         }
     }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
