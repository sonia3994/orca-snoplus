//
//  ELLIEModel.m
//  Orca
//
//  Created by Chris Jones on 01/04/2014.
//
//

#import "ELLIEModel.h"
#import "ORTaskSequence.h"

NSString* ELLIEAllLasersChanged = @"ELLIEAllLasersChanged";
NSString* ELLIEAllFibresChanged = @"ELLIEAllFibresChanged";

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


-(void)startSmellieRun:(NSDictionary*)smellieSettings
{
    //TODO: Post to external DB and read from external DB
    
    //Deconstruct runFile into indiviual subruns ------------------

    //Extract the number of intensity steps
    NSNumber * numIntStepsObj = [smellieSettings objectForKey:@"num_intensity_steps"];
    int numIntSteps = [numIntStepsObj intValue];
    [numIntStepsObj release];
    
    //Extract the lasers to be fired (nm)
    //NSMutableArray * laserArray = [[NSMutableArray alloc] init];
 
    ///Loop through each Laser
    for(int laserLoopInt = 0;laserLoopInt < 4;laserLoopInt++){
        
        //Loop through each Fibre
        for(int fibreLoopInt = 0; fibreLoopInt < 16;fibreLoopInt++){
            
            //Loop through each intensity of a SMELLIE run 
            for(int intensityLoopInt =0;intensityLoopInt < numIntSteps; intensityLoopInt++){
            
                
                
            }//end of looping through each intensity setting on the smellie laser
            
        }//end of looping through each Fibre
        
    }//end of looping through each laser
    
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
