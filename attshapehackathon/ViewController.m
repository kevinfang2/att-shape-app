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
#import <Firebase/Firebase.h>
#import <tgmath.h>

@interface ViewController () <AVAudioRecorderDelegate>{
    AVAudioRecorder *recorder;
    NSMutableDictionary *recorderSettings;
    NSString *recorderFilePath;
    AVAudioPlayer *audioPlayer;
    NSString *audioFileName;
    Firebase *myRootRef;
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
    int index;
    float timePassed;
    float oneCycle;
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
    myRootRef = [[Firebase alloc] initWithUrl:@"https://troll3333.firebaseIO.com"];

    
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
    index = 0;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(calibrate:)];
    [self.view addGestureRecognizer:tap];

}

-(void)calibrate:(UITapGestureRecognizer*)sender{
    if(index == 0){
        [NSTimer scheduledTimerWithTimeInterval:0.01 target: self
                                       selector: @selector(add) userInfo: nil repeats: YES];
        index++;
    }
    else{
        oneCycle = timePassed;
        [NSTimer scheduledTimerWithTimeInterval:0.01 target: self
                                       selector: @selector(add) userInfo: nil repeats: YES];
//        NSLog(@"%f",timePassed);
        index = -1;
    }
}

-(void)add{
    timePassed += 0.01;
//    NSLog(@"%f", timePassed);
}


//MARK:voice recgnition stuff

#define DOCUMENTS_FOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]

-(void) record{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err = nil;
    [audioSession setCategory :AVAudioSessionCategoryPlayAndRecord error:&err];
    if(err)
    {
        NSLog(@"audioSession: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
        return;
    }
    [audioSession setActive:YES error:&err];
    err = nil;
    if(err)
    {
        NSLog(@"audioSession: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
        return;
    }
    
    recorderSettings = [[NSMutableDictionary alloc] init];
    
//    [recorderSettings setValue :[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
//    [recorderSettings setValue:[NSNumber numberWithFloat:48000.0] forKey:AVSampleRateKey];
//    [recorderSettings setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
//    [recorderSettings setValue:[NSNumber numberWithBool:AVAudioQualityMax] forKey:AVEncoderAudioQualityKey];
    [recorderSettings setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM]
                         forKey:AVFormatIDKey];
    [recorderSettings setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    [recorderSettings setValue:[NSNumber numberWithBool:YES] forKey:AVLinearPCMIsBigEndianKey];
    [recorderSettings setValue:[NSNumber numberWithBool:YES] forKey:AVLinearPCMIsFloatKey];
    [recorderSettings setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsNonInterleaved];
    [recorderSettings setValue:[NSNumber numberWithFloat:16000.0] forKey:AVSampleRateKey];
    
    
    // Create a new audio file
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [path objectAtIndex:0];
    NSString *myDBnew = [documentsDirectory stringByAppendingPathComponent:@"test.wav"];
    NSURL *recordedTmpFile = [NSURL fileURLWithPath:myDBnew];

    audioFileName = @"recordingTestFile";
    recorderFilePath = [NSString stringWithFormat:@"%@/%@.caf", DOCUMENTS_FOLDER, audioFileName] ;
    
    NSURL *url = [NSURL fileURLWithPath:recorderFilePath];
    err = nil;
    recorder = [[ AVAudioRecorder alloc] initWithURL:url settings:recorderSettings error:&err];
    if(!recorder){
        NSLog(@"recorder: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
        UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle: @"Warning" message: [err localizedDescription] delegate: nil
                         cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    [recorder setDelegate:self];
    [recorder prepareToRecord];
    recorder.meteringEnabled = YES;
    
    BOOL audioHWAvailable = audioSession.inputIsAvailable;
    if (! audioHWAvailable) {
        UIAlertView *cantRecordAlert =
        [[UIAlertView alloc] initWithTitle: @"Warning" message: @"Audio input hardware not available"
                                  delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [cantRecordAlert show];
        return;
    }
    
    [recorder recordForDuration:(NSTimeInterval) 30];
    
    double delayInSeconds = 5.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        NSError *error  = nil;
        
        NSLog(@"Using File called: %@",recordedTmpFile);
        
        NSString *path2 = @"https://stream.watsonplatform.net/speech-to-text/api/v1/recognize?&continuous=true&timestamps=true&word_alternatives_threshold=0.9&model=en-US_NarrowbandModel";
        
        NSLog(@"%@", path2);
        
        NSMutableURLRequest* _request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:path2]];
        [_request setHTTPMethod:@"POST"];
        [_request addValue:@"audio/l16;rate=16000" forHTTPHeaderField:@"Content-type"];
//        request.setValue("audio/l16;rate=16000", forHTTPHeaderField: "content-type")
        
//        NSMutableDictionary *contentDictionary = [[NSMutableDictionary alloc]init];
//        [contentDictionary setValue:@"14b72252-e378-4b0a-9cc6-117b1e7728f7" forKey:@"username"];
//        [contentDictionary setValue:@"0udTrbZeCBqq" forKey:@"password"];
        
//        NSData *data = [NSJSONSerialization dataWithJSONObject:contentDictionary options:NSJSONWritingPrettyPrinted error:nil];
//        NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSMutableData *body = [NSMutableData data];
        NSData* mydata = [NSData dataWithContentsOfURL:recordedTmpFile];
//        NSString *post = [NSString stringWithFormat:@"Username=%@&Password=%@",@"14b72252-e378-4b0a-9cc6-117b1e7728f7",@"0udTrbZeCBqq",nil];
//        NSLog(@"the data Details is =%@", post);
        NSData *wavData = [self stripAndAddWavHeader:mydata];
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", @"14b72252-e378-4b0a-9cc6-117b1e7728f7", @"0udTrbZeCBqq"];
        NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64Encoding]];
        [_request setValue:authValue forHTTPHeaderField:@"Authorization"];
        
//        let loginData: NSData = post.dataUsingEncoding(NSUTF8StringEncoding);
//        let base64LoginString = [p].base64EncodedStringWithOptions(nil)
//        [body appendData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:wavData];
    

//        NSArray *keys = [NSArray arrayWithObjects: @"username",@"password",@"imageFile", nil];
        
        [_request setHTTPBody:body];
        NSURLResponse *response = nil;
        NSData *_connectionData = [self sendSynchronousRequest:_request returningResponse:&response error:&error];
        
        NSLog(@"%@",path2);
        
        NSString *myString = [[NSString alloc] initWithData:_connectionData encoding:NSUTF8StringEncoding];
        NSLog(@"%@",myString);
    });
   
}

-(NSData*) stripAndAddWavHeader:(NSData*) wav {
    unsigned long wavDataSize = [wav length] - 44;
    
    NSData *WaveFile= [NSMutableData dataWithData:[wav subdataWithRange:NSMakeRange(44, wavDataSize)]];
    
    NSMutableData *newWavData;
    newWavData = [self addWavHeader:WaveFile];
    
    return newWavData;
}


- (NSMutableData *)addWavHeader:(NSData *)wavNoheader {
    
    int headerSize = 44;
    long totalAudioLen = [wavNoheader length];
    long totalDataLen = [wavNoheader length] + headerSize-8;
    long longSampleRate = 22050.0;
    int channels = 1;
    long byteRate = 8 * 44100.0 * channels/8;
    
    
    
    Byte *header = (Byte*)malloc(44);
    header[0] = 'R';  // RIFF/WAVE header
    header[1] = 'I';
    header[2] = 'F';
    header[3] = 'F';
    header[4] = (Byte) (totalDataLen & 0xff);
    header[5] = (Byte) ((totalDataLen >> 8) & 0xff);
    header[6] = (Byte) ((totalDataLen >> 16) & 0xff);
    header[7] = (Byte) ((totalDataLen >> 24) & 0xff);
    header[8] = 'W';
    header[9] = 'A';
    header[10] = 'V';
    header[11] = 'E';
    header[12] = 'f';  // 'fmt ' chunk
    header[13] = 'm';
    header[14] = 't';
    header[15] = ' ';
    header[16] = 16;  // 4 bytes: size of 'fmt ' chunk
    header[17] = 0;
    header[18] = 0;
    header[19] = 0;
    header[20] = 1;  // format = 1
    header[21] = 0;
    header[22] = (Byte) channels;
    header[23] = 0;
    header[24] = (Byte) (longSampleRate & 0xff);
    header[25] = (Byte) ((longSampleRate >> 8) & 0xff);
    header[26] = (Byte) ((longSampleRate >> 16) & 0xff);
    header[27] = (Byte) ((longSampleRate >> 24) & 0xff);
    header[28] = (Byte) (byteRate & 0xff);
    header[29] = (Byte) ((byteRate >> 8) & 0xff);
    header[30] = (Byte) ((byteRate >> 16) & 0xff);
    header[31] = (Byte) ((byteRate >> 24) & 0xff);
    header[32] = (Byte) (2 * 8 / 8);  // block align
    header[33] = 0;
    header[34] = 16;  // bits per sample
    header[35] = 0;
    header[36] = 'd';
    header[37] = 'a';
    header[38] = 't';
    header[39] = 'a';
    header[40] = (Byte) (totalAudioLen & 0xff);
    header[41] = (Byte) ((totalAudioLen >> 8) & 0xff);
    header[42] = (Byte) ((totalAudioLen >> 16) & 0xff);
    header[43] = (Byte) ((totalAudioLen >> 24) & 0xff);
    
    NSMutableData *newWavData = [NSMutableData dataWithBytes:header length:44];
    [newWavData appendBytes:[wavNoheader bytes] length:[wavNoheader length]];
    return newWavData;
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
        count = 3;
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
         
         CGFloat moduloResult = fmodf(timePassed, oneCycle);
         
         CGFloat degrees = (moduloResult/oneCycle * 360);
         NSLog(@"degrees is %f",degrees);
         if(degrees > 315 || degrees <= 45){
             myRootRef = [[Firebase alloc] initWithUrl:@"https://troll3333.firebaseio.com"];
             [[myRootRef childByAppendingPath:@"left"] setValue:[NSNumber numberWithInteger:500]];
             
             myRootRef = [[Firebase alloc] initWithUrl:@"https://troll3333.firebaseio.com"];
             [[myRootRef childByAppendingPath:@"right"] setValue:[NSNumber numberWithInteger:500]];
         }
         else if(degrees > 45 && degrees <= 135){
             myRootRef = [[Firebase alloc] initWithUrl:@"https://troll3333.firebaseio.com"];
             [[myRootRef childByAppendingPath:@"left"] setValue:[NSNumber numberWithInteger:200]];
             
             myRootRef = [[Firebase alloc] initWithUrl:@"https://troll3333.firebaseio.com"];
             [[myRootRef childByAppendingPath:@"right"] setValue:[NSNumber numberWithInteger:0]];
         }
         else if(degrees > 135 && degrees <= 225){
             myRootRef = [[Firebase alloc] initWithUrl:@"https://troll3333.firebaseio.com"];
             [[myRootRef childByAppendingPath:@"left"] setValue:[NSNumber numberWithInteger:0]];
             
             myRootRef = [[Firebase alloc] initWithUrl:@"https://troll3333.firebaseio.com"];
             [[myRootRef childByAppendingPath:@"right"] setValue:[NSNumber numberWithInteger:200]];
         }
         else{
             myRootRef = [[Firebase alloc] initWithUrl:@"https://troll3333.firebaseio.com"];
             [[myRootRef childByAppendingPath:@"left"] setValue:[NSNumber numberWithInteger:0]];
             
             myRootRef = [[Firebase alloc] initWithUrl:@"https://troll3333.firebaseio.com"];
             [[myRootRef childByAppendingPath:@"right"] setValue:[NSNumber numberWithInteger:200]];
         }
        

         
         NSString *myString = [[NSString alloc] initWithData:_connectionData encoding:NSUTF8StringEncoding];
         NSLog(@"%@",myString);
         
         myRootRef = [[[Firebase alloc] initWithUrl:@"https://troll3333.firebaseio.com"] childByAppendingPath:@"jsonFile"];
         [myRootRef setValue:[NSString stringWithFormat:@"%@",myString]];

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
