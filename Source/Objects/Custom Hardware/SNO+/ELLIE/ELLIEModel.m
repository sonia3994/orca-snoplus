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
@synthesize loadSmellieSettingsTask;

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

-(void)loadSmellieSettings
{
    NSLog(@"load smellie settings\n");
    
    /*ORTaskSequence* aSequence = [ORTaskSequence taskSequenceWithDelegate:self];
    //[NSArray arrayWithObjects:@"-c",@"1",@"-t",@"1",@"-q",IPNumber,nil]
    [aSequence addTask:@"/Users/jonesc/"
             arguments:[NSArray arrayWithObjects:@"python",@"testScript.py",nil]];
    [aSequence addTaskObj:self.orcaDBPingTask];
    [aSequence setVerbose:YES];
    [aSequence setTextToDelegate:YES];
    [aSequence launch];*/
    
    if(!self.loadSmellieSettingsTask){
        NSLog(@"starting task");
        ORTaskSequence* aSequence = [ORTaskSequence taskSequenceWithDelegate:self];
        self.loadSmellieSettingsTask = [[[NSTask alloc]init]autorelease];
        //Not sure if the arguements here are correct!
        [self.loadSmellieSettingsTask setLaunchPath:@"/Users/jonesc"];
        [self.loadSmellieSettingsTask setArguments:[NSArray arrayWithObjects:@"python",@"testScript.py", nil]];
        //Need to check the above arguments with the couchdb load button 
        [aSequence addTaskObj:self.loadSmellieSettingsTask];
        [aSequence setVerbose:YES];
        [aSequence setTextToDelegate:YES];
        [aSequence launch];
    }
    else{
        NSLog(@"ending task");
        [self.loadSmellieSettingsTask terminate];
    }
    
    NSLog(@"sucess!");
    
    /*
     if(!self.orcaDBPingTask){
     ORTaskSequence* aSequence = [ORTaskSequence taskSequenceWithDelegate:self];
     self.orcaDBPingTask = [[[NSTask alloc] init] autorelease];
     
     [self.orcaDBPingTask setLaunchPath:@"/sbin/ping"];
     [self.orcaDBPingTask setArguments: [NSArray arrayWithObjects:@"-c",@"2",@"-t",@"5",@"-q",self.orcaDBIPAddress,nil]];
     
     [aSequence addTaskObj:self.orcaDBPingTask];
     [aSequence setVerbose:YES];
     [aSequence setTextToDelegate:YES];
     [aSequence launch];
     }
     else {
     [self.orcaDBPingTask terminate];
     }
     */
    
    /*[self setGoScriptFailed:NO];
	NSString* resourcePath = [[NSBundle mainBundle] resourcePath];
	ORTaskSequence* aSequence = [ORTaskSequence taskSequenceWithDelegate:self];
    NSString* pwd = [passWord length]?passWord:@"\n";
	[aSequence addTask:[resourcePath stringByAppendingPathComponent:@"loginScript"]
			 arguments:[NSArray arrayWithObjects:userName,pwd,IPNumber,@"~/ORCA/goScript",nil]];
    
	[aSequence setVerbose:verbose];
	[aSequence setTextToDelegate:YES];*/
    
   
    /*pingTask = [[NSTask alloc] init];
    
    [pingTask setLaunchPath:@"/sbin/ping"];
    
    [pingTask setArguments: [NSArray arrayWithObjects:@"-c",@"1",@"-t",@"1",@"-q",IPNumber,nil]];
    
    [aSequence addTaskObj:pingTask];
    [aSequence setVerbose:aFlag];
    [aSequence setTextToDelegate:YES];
    [aSequence launch];*/
    
    //NSLog(@"Output: %@ ",output);
    
    /*NSString *path = @"python /Users/jonesc/testScript.py";
    //NSArray *args = [NSArray arrayWithObjects:..., nil];
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: path];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    [task setStandardInput:[NSPipe pipe]];
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    
    [task launch];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    
    NSString *stringReadOut;
    stringReadOut = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];

    NSLog(@"This is the readout: %@",stringReadOut);
    
    [stringReadOut release];
    [task release];*/
    
    /*NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/usr/bin/ssh"]; // Tell the task to execute the ssh command
    [task setArguments: [NSArray arrayWithObjects: @"<user>:<hostname>", @"<command>"]]; // Set the arguments for ssh to contain only your command. If other configuration is necessary, see the ssh(1) man page.
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    NSFileHandle *file;
    file = [pipe fileHandleForReading]; // This file handle is a reference to the output of the ssh command
    
    [task launch];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    
    NSString *string;
    string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding]; // This string now contains the entire output of the ssh command.*/
    
    
}

@end
