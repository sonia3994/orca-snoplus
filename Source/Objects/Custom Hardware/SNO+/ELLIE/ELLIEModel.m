//
//  ELLIEModel.m
//  Orca
//
//  Created by Chris Jones on 01/04/2014.
//
//

/*TODO:
        - Check the standard run name doesn't already exsists in the DB
        - read from and write to the local couch DB for both smellie and tellie
        - fix the intensity steps in SMELLIE such that negative values cannot be considered
        - add the TELLIE GUI Information
        - add the sockets for TELLIE to communicate with itself
        - add the AMELLIE GUI
        - make sure old files cannot be overridden 
        - add the configuration files GUI for all the ELLIE systems (LOW PRIORITY)
*/

#import "ELLIEModel.h"
#import "ORTaskSequence.h"
#import "ORCouchDB.h"
#import "SNOPModel.h"
#import "ORRunModel.h"

//tags to define that an ELLIE run file has been updated
#define kSmellieRunDocumentAdded   @"kSmellieRunDocumentAdded"
#define kSmellieRunDocumentUpdated   @"kSmellieRunDocumentUpdated"
#define kTellieRunDocumentAdded   @"kTellieRunDocumentAdded"
#define kTellieRunDocumentUpdated   @"kTellieRunDocumentUpdated"
#define kAmellieRunDocumentAdded   @"kAmellieRunDocumentAdded"
#define kAmellieRunDocumentUpdated   @"kAmellieRunDocumentUpdated"


NSString* ELLIEAllLasersChanged = @"ELLIEAllLasersChanged";
NSString* ELLIEAllFibresChanged = @"ELLIEAllFibresChanged";

@interface SNOPModel (private)
-(void) _pushEllieCustomRunToDB:(NSString*)aCouchDBName runFiletoPush:(NSMutableDictionary*)customRunFile;
- (NSString*) stringDateFromDate:(NSDate*)aDate;
@end

@implementation ELLIEModel

@synthesize smellieRunSettings;
@synthesize exampleTask;


- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"ellie"]];
}

- (void) makeMainController
{
    [self linkToController:@"ELLIEController"];
    
}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
}

- (void) sleep
{
	[super sleep];
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
	[super dealloc];
}

-(NSString*)callPythonScript:(NSString*)pythonScriptFilePath withCmdLineArgs:(NSArray*)commandLineArgs
{
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/usr/bin/python"]; // Tell the task to execute the ssh command
    [task setArguments: [NSArray arrayWithObjects: pythonScriptFilePath, commandLineArgs,nil]];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    NSFileHandle *file;
    file = [pipe fileHandleForReading]; // This file handle is a reference to the output of the ssh command
    
    [task launch];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    
    NSString *responseFromCmdLine;
    responseFromCmdLine = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding]; // This string now contains the entire output of the ssh command.
    
    [task release];
    return responseFromCmdLine;
}

//used to create the timestamp in the couchDB files 
- (NSString*) stringDateFromDate:(NSDate*)aDate
{
    NSDateFormatter* snotDateFormatter = [[NSDateFormatter alloc] init];
    [snotDateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SS'Z'"];
    snotDateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    NSDate* strDate;
    if (!aDate)
        strDate = [NSDate date];
    else
        strDate = aDate;
    NSString* result = [snotDateFormatter stringFromDate:strDate];
    [snotDateFormatter release];
    strDate = nil;
    return [[result retain] autorelease];
}

//Push the information from the GUI into a couchDB database
-(void) _pushEllieCustomRunToDB:(NSString*)aCouchDBName runFiletoPush:(NSMutableDictionary*)customRunFile
{
    NSAutoreleasePool* runDocPool = [[NSAutoreleasePool alloc] init];
    NSMutableDictionary* runDocDict = [NSMutableDictionary dictionaryWithCapacity:100];
    
    //Collect a series of objects from the SNOPModel
    NSArray*  objs = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    
    //Initialise the SNOPModel
    SNOPModel* aSnotModel = [objs objectAtIndex:0];
    
    NSString* docType = [NSString stringWithString:aCouchDBName];
    [docType stringByAppendingString:@"_run"];
    
    [runDocDict setObject:docType forKey:@"doc_type"];
    [runDocDict setObject:[self stringDateFromDate:nil] forKey:@"time_stamp"];
            
    //self.runDocument = runDocDict;
    [[aSnotModel orcaDbRefWithEntryDB:aSnotModel withDB:aCouchDBName] addDocument:runDocDict tag:kSmellieRunDocumentAdded];
    
    //[[aSnotModel orcaDbRefWithEntryDB:aSnotModel withDB:aCouchDBName] updateDocument:runDocDict documentId:[runDocDict objectForKey:@"_id"] tag:kSmellieRunDocumentUpdated];
    
    //wait for main thread to receive acknowledgement from couchdb
    /*NSDate* timeout = [NSDate dateWithTimeIntervalSinceNow:2.0];
    while ([timeout timeIntervalSinceNow] > 0 && ![self.runDocument objectForKey:@"_id"]) {
        [NSThread sleepForTimeInterval:0.1];
    }
    
    //if failed emit alarm and give up
    
    runDocDict = [[[self runDocument] mutableCopy] autorelease];
    if (rc) {
        NSDate* runStart = [[[rc startTime] copy] autorelease];
        [runStartString setString:[self stringDateFromDate:runStart]];
    }
    [runDocDict setObject:@"in progress" forKey:@"run_status"];
    
    //self.runDocument = runDocDict;
    [[self orcaDbRef:self] updateDocument:runDocDict documentId:[runDocDict objectForKey:@"_id"] tag:kOrcaRunDocumentUpdated];*/
    
    [runDocPool release];
}

-(void) smellieDBpush:(NSMutableDictionary*)dbTestDic
{
    [self _pushEllieCustomRunToDB:@"smellie" runFiletoPush:dbTestDic];
}

//Pull the information from the database and perform a new run
-(NSMutableDictionary*) pullEllieCustomRunFromDB:(NSString*)aCouchDBName
{
    //TODO:Need to add the information in here 
    NSMutableDictionary* customRunFile = [[NSMutableDictionary alloc] init];
    return customRunFile;
}


-(void)startSmellieRun:(NSMutableDictionary*)smellieSettings
{
    //TODO: Post to external DB and read from external DB
    
    //Deconstruct runFile into indiviual subruns ------------------
    
    //Put this back in!
    //NSLog(@" output from connection %@",[self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/orcaControlSmellie.py" withCmdLineArgs:nil]);
    
    //Extract the number of intensity steps
    NSNumber * numIntStepsObj = [smellieSettings objectForKey:@"num_intensity_steps"];
    int numIntSteps = [numIntStepsObj intValue];
    [numIntStepsObj release];
    
    //Objects to add
    //NSNumber * firstLaser = [NSNumber numberWithInteger:[smellieSettings objectForKey:@"405nm_laser_on"]];
    
    //Extract the lasers to be fired into an array
    NSMutableArray * laserArray = [[NSMutableArray alloc] init];
    [laserArray addObject:[smellieSettings objectForKey:@"375nm_laser_on"] ];
    [laserArray addObject:[smellieSettings objectForKey:@"405nm_laser_on"] ];
    [laserArray addObject:[smellieSettings objectForKey:@"440nm_laser_on"] ];
    [laserArray addObject:[smellieSettings objectForKey:@"500nm_laser_on"] ];
    
    //Extract the fibres to be fired into an array
    NSMutableArray *fibreArray = [[NSMutableArray alloc] init];
    [fibreArray addObject:[smellieSettings objectForKey:@"FS007"] ];
    [fibreArray addObject:[smellieSettings objectForKey:@"FS107"] ];
    [fibreArray addObject:[smellieSettings objectForKey:@"FS207"] ];
    [fibreArray addObject:[smellieSettings objectForKey:@"FS025"] ];
    [fibreArray addObject:[smellieSettings objectForKey:@"FS125"] ];
    [fibreArray addObject:[smellieSettings objectForKey:@"FS225"] ];
    [fibreArray addObject:[smellieSettings objectForKey:@"FS037"] ];
    [fibreArray addObject:[smellieSettings objectForKey:@"FS137"] ];
    [fibreArray addObject:[smellieSettings objectForKey:@"FS237"] ];
    [fibreArray addObject:[smellieSettings objectForKey:@"FS055"] ];
    [fibreArray addObject:[smellieSettings objectForKey:@"FS155"] ];
    [fibreArray addObject:[smellieSettings objectForKey:@"FS255"] ];
 
    //NSLog(@" Laser %@", [[laserArray objectAtIndex:0] stringValue]);
    
    ///Loop through each Laser
    for(int laserLoopInt = 0;laserLoopInt < [laserArray count];laserLoopInt++){
        
        //Only loop through lasers that are included in the run 
        if([[laserArray objectAtIndex:laserLoopInt] intValue] != 1){
            continue;
        }
        
        //Loop through each Fibre
        for(int fibreLoopInt = 0; fibreLoopInt < [fibreArray count];fibreLoopInt++){
        
            //Only loop through fibres that are included in the run 
            if([[fibreArray objectAtIndex:fibreLoopInt] intValue] != 1){
                continue;
            }
            
            //Loop through each intensity of a SMELLIE run 
            for(int intensityLoopInt =0;intensityLoopInt < numIntSteps; intensityLoopInt++){
            
                //Call the smellie system here 
                //NSLog(@" Laser:%@ ", [laserArray objectAtIndex:laserLoopInt]);
                //NSLog(@" Fibre:%@ ",[fibreArray objectAtIndex:fibreLoopInt]);
                //NSLog(@" Intensity:%i \n'",intensityLoopInt);
                
            }//end of looping through each intensity setting on the smellie laser
            
        }//end of looping through each Fibre
        
    }//end of looping through each laser
    
    [fibreArray release];
    [laserArray release];
    
}


-(void)exampleFunctionForPython
{
    NSLog(@"load smellie settings\n");
    
    if(!self.exampleTask){
        NSLog(@"starting task\n");
        ORTaskSequence* aSequence = [ORTaskSequence taskSequenceWithDelegate:self];
        self.exampleTask = [[[NSTask alloc]init]autorelease];
        [self.exampleTask setLaunchPath:@"/usr/bin/python"];
        [self.exampleTask setArguments:[NSArray arrayWithObjects:@"/Users/jonesc/testScript.py", nil]];
        [aSequence addTaskObj:self.exampleTask];
        [aSequence setVerbose:YES];
        [aSequence setTextToDelegate:YES];
        [aSequence launch];
    }
    else{
        NSLog(@"ending task\n");
        [self.exampleTask terminate];
    }
    
    NSLog(@"sucess!\n");
    
}

@end
