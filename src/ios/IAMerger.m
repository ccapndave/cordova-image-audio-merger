#import "IAMerger.h"
#import "MovieMaker.h"
#import "CDVFile.h"

@implementation IAMerger

- (void)merge:(CDVInvokedUrlCommand*)command
{
    NSString* callbackId = [command callbackId];

    NSString* imagePath = [[command arguments] objectAtIndex:0];
    NSString* audioPath = [[command arguments] objectAtIndex:1];

    // Load the image
    NSData* data = [NSData dataWithContentsOfFile:imagePath];
    UIImage *uiImage = [UIImage imageWithData:data];

    // Get a file to write to in the documents
    NSString* docsPath = [NSTemporaryDirectory()stringByStandardizingPath];   // use file system temporary directory
    NSFileManager* fileMgr = [[NSFileManager alloc] init];
    NSString* outputMoviePath;
    int i = 1;
    do { outputMoviePath = [NSString stringWithFormat:@"%@/reflection_%03d.mp4", docsPath, i++]; } while ([fileMgr fileExistsAtPath:outputMoviePath]);

    [self.commandDelegate runInBackground:^{
        // Create the movie using Erica's hacked utility
        MovieMaker *movieMaker = [MovieMaker createMovieAtPath:outputMoviePath audioPath:audioPath frameSize:[uiImage size] fps:1];
        [movieMaker addImageToMovie:uiImage];
        [movieMaker finalizeMovie];

        NSDictionary* fileDict = [self getMediaDictionaryFromPath:outputMoviePath];
        NSArray* fileArray = [NSArray arrayWithObject:fileDict];
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:fileArray];

        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }];
}

- (NSDictionary*)getMediaDictionaryFromPath:(NSString*)fullPath
{
    NSFileManager* fileMgr = [[NSFileManager alloc] init];
    NSMutableDictionary* fileDict = [NSMutableDictionary dictionaryWithCapacity:5];

    CDVFile *fs = [self.commandDelegate getCommandInstance:@"File"];

    // Get canonical version of localPath
    NSURL *fileURL = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@", fullPath]];
    NSURL *resolvedFileURL = [fileURL URLByResolvingSymlinksInPath];
    NSString *path = [resolvedFileURL path];

    CDVFilesystemURL *url = [fs fileSystemURLforLocalPath:path];

    [fileDict setObject:[fullPath lastPathComponent] forKey:@"name"];
    [fileDict setObject:fullPath forKey:@"fullPath"];
    if (url) {
        [fileDict setObject:[url absoluteURL] forKey:@"localURL"];
    }
    // determine type
    id command = [self.commandDelegate getCommandInstance:@"File"];
    if ([command isKindOfClass:[CDVFile class]]) {
        CDVFile* cdvFile = (CDVFile*)command;
        NSString* mimeType = [cdvFile getMimeTypeFromPath:fullPath];
        [fileDict setObject:(mimeType != nil ? (NSObject*)mimeType : [NSNull null]) forKey:@"type"];
    }

    NSDictionary* fileAttrs = [fileMgr attributesOfItemAtPath:fullPath error:nil];
    [fileDict setObject:[NSNumber numberWithUnsignedLongLong:[fileAttrs fileSize]] forKey:@"size"];
    NSDate* modDate = [fileAttrs fileModificationDate];
    NSNumber* msDate = [NSNumber numberWithDouble:[modDate timeIntervalSince1970] * 1000];
    [fileDict setObject:msDate forKey:@"lastModifiedDate"];

    return fileDict;
}

@end
