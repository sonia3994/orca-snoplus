//
//  ELLIEController.m
//  Orca
//
//  Created by Chris Jones on 01/04/2014.
//
//

#import "ELLIEController.h"
#import "ELLIEModel.h"

@implementation ELLIEController

@synthesize smellieRunSettingsFromGUI;

//smellie maxiumum trigger frequency

//Set up functions
-(id)init
{
    self = [super initWithWindowNibName:@"ellie"];
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void) updateWindow
{
	[super updateWindow];
    
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
	[super registerNotificationObservers];
    
    //we don't want this notification
	[notifyCenter removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(setAllLasersAction:)
						 name : ELLIEAllLasersChanged
					   object : model];
    
    [notifyCenter addObserver : self
					 selector : @selector(setAllFibresAction:)
						 name : ELLIEAllFibresChanged
					   object : model];
    
}

//SMELLIE functions -------------------------

-(IBAction)setAllLasersAction:(id)sender;
{
    if([smellieAllLasersButton state] == 1){
        //Set the state of all Lasers to 1
        [smellie375nmLaserButton setState:1];
        [smellie405nmLaserButton setState:1];
        [smellie440nmLaserButton setState:1];
        [smellie500nmLaserButton setState:1];
    }
    
}

-(IBAction)setAllFibresAction:(id)sender;
{
    if([smellieAllFibresButton state] == 1){
        [smellieFibreButtonFS007 setState:1];
        [smellieFibreButtonFS107 setState:1];
        [smellieFibreButtonFS207 setState:1];
        [smellieFibreButtonFS025 setState:1];
        [smellieFibreButtonFS125 setState:1];
        [smellieFibreButtonFS225 setState:1];
        [smellieFibreButtonFS037 setState:1];
        [smellieFibreButtonFS137 setState:1];
        [smellieFibreButtonFS237 setState:1];
        [smellieFibreButtonFS055 setState:1];
        [smellieFibreButtonFS155 setState:1];
        [smellieFibreButtonFS255 setState:1];
    }
}

//Force the string value to be less than 100 and a valid value
-(IBAction)validateLaserMaxIntensity:(id)sender;
{
    NSString* maxLaserIntString = [smellieMaxIntensity stringValue];
    int maxLaserIntensity;
    
    @try{
        maxLaserIntensity  = [maxLaserIntString intValue];
    }
    @catch (NSException *e) {
        maxLaserIntensity = 100;
        [smellieMaxIntensity setIntValue:maxLaserIntensity];
        NSLog(@"SMELLIE_RUN_BUILDER: Maximum Laser intensity is invalid. Setting to 100%% by Default\n");
    }
    
    if((maxLaserIntensity < 0) ||(maxLaserIntensity > 100))
    {
        maxLaserIntensity = 100;
        [smellieMaxIntensity setIntValue:maxLaserIntensity];
        NSLog(@"SMELLIE_RUN_BUILDER: Maximum Laser intensity is too high (or too low). Setting to 100%% by Default\n");
    }
}

-(IBAction)validateLaserMinIntensity:(id)sender;
{
    NSString* minLaserIntString = [smellieMinIntensity stringValue];
    int minLaserIntensity;
    
    @try{
        minLaserIntensity  = [minLaserIntString intValue];
    }
    @catch (NSException *e) {
        minLaserIntensity = 20;
        [smellieMinIntensity setIntValue:minLaserIntensity];
        NSLog(@"SMELLIE_RUN_BUILDER: Minimum Laser intensity is invalid. Setting to 20%% by Default\n");
    }
    
    if((minLaserIntensity < 0) || (minLaserIntensity > 100))
    {
        minLaserIntensity = 0;
        [smellieMinIntensity setIntValue:minLaserIntensity];
        NSLog(@"SMELLIE_RUN_BUILDER: Minimum Laser intensity is too low or high. Setting to 0%% by Default\n");
    }
}

//The number of intensity steps cannot be more than the maximum intensity less minimum intensity 
-(IBAction)validateIntensitySteps:(id)sender;
{
    int numberOfIntensitySteps;
    int maxNumberOfSteps;
    
    @try{
        numberOfIntensitySteps = [smellieNumIntensitySteps intValue];
        maxNumberOfSteps = [smellieMaxIntensity intValue] - [smellieMinIntensity intValue];
    }
    @catch(NSException *e){
        NSLog(@"SMELLIE_RUN_BUILDER: Number of Intensity steps is invalid. Setting the number of steps to 1\n");
        numberOfIntensitySteps = 1;
        [smellieNumIntensitySteps setIntValue:numberOfIntensitySteps];
    }
    
    if( (numberOfIntensitySteps > maxNumberOfSteps)|| (numberOfIntensitySteps < 1)){
        numberOfIntensitySteps = maxNumberOfSteps;
        [smellieNumIntensitySteps setIntValue:maxNumberOfSteps];
        NSLog(@"SMELLIE_RUN_BUILDER: Number of Intensity steps is invalid. Setting the the maximum correct value\n");
    }
    
}

//checks to make sure the trigger frequency isn't too high 
-(IBAction)validateSmellieTriggerFrequency:(id)sender;
{
    int triggerFrequency;
    //maxmium allowed trigger frequency in the GUI
    int maxmiumTriggerFrequency = 1000;
    
    @try{
        triggerFrequency = [smellieTriggerFrequency intValue];
    }
    @catch(NSException *e){
        NSLog(@"SMELLIE_RUN_BUILDER: Trigger Frequency is invalid. Setting the frequency to 10 Hz\n");
        triggerFrequency = 10;
        [smellieTriggerFrequency setIntValue:triggerFrequency];
    }
    
    if( (triggerFrequency > maxmiumTriggerFrequency) || (triggerFrequency < 0)){
        [smellieTriggerFrequency setIntValue:10];
        NSLog(@"SMELLIE_RUN_BUILDER: Trigger Frequency is invalid. Setting the frequency to 10 Hz\n");
    }
}

-(IBAction)validateNumTriggersPerStep:(id)sender;
{
    int numberTriggersPerStep;
    //maxmium allowed number of triggers per loop
    int maximumNumberTriggersPerStep = 100000;
    
    @try{
        numberTriggersPerStep = [smellieNumTriggersPerLoop intValue];
    }
    @catch(NSException *e){
        NSLog(@"SMELLIE_RUN_BUILDER: Triggers per loop is invalid. Setting to 100\n");
        [smellieNumTriggersPerLoop setIntValue:100];
    }
    
    if( (numberTriggersPerStep > maximumNumberTriggersPerStep) || (numberTriggersPerStep < 0)){
        NSLog(@"SMELLIE_RUN_BUILDER: Triggers per loop is invalid. Setting to 100\n");
        [smellieNumTriggersPerLoop setIntValue:100];
    }
}

-(IBAction)validationSmellieRunAction:(id)sender;
{
    
    [smellieMakeNewRunButton setEnabled:NO];
    
    //Error messages
    NSString* smellieRunErrorString = [[NSString alloc] initWithString:@"Unable to Validate. Check all fields are entered and see Status and Error Log" ];
    
    NSNumber* validationErrorFlag = [[NSNumber alloc] init];
    validationErrorFlag = [NSNumber numberWithInt:1];
    
    //check the Operator has entered their name 
    if([[smellieOperatorName stringValue] length] == 0){
        NSLog(@"SMELLIE_RUN_BUILDER:Please enter a Operator Name \n");
    }

    //TODO:Check there are no files with the same name (although each will have a unique id)
    //check the Operator has a valid run name 
    else if([[smellieRunName stringValue] length] == 0){
        NSLog(@"SMELLIE_RUN_BUILDER:Please enter a Run Name\n");
    }
    
    //check that an operation mode has been given 
    else if([[smellieOperationMode stringValue] length] == 0){
        NSLog(@"SMELLIE_RUN_BUILDER:Please enter an Operation Mode \n");
    }
    
    //check the maximum laser intensity is given
    else if([[smellieMaxIntensity stringValue] length] == 0){
        NSLog(@"SMELLIE_RUN_BUILDER:Please enter an Maxmium Laser Intensity\n");
    }
    
    //check the minimum laser intensity is given
    else if([[smellieMinIntensity stringValue] length] == 0){
        NSLog(@"SMELLIE_RUN_BUILDER:Please enter an Minimum Laser Intensity\n");
    }
    
    //check the intensity step is given 
    else if([[smellieNumIntensitySteps stringValue] length] == 0){
        NSLog(@"SMELLIE_RUN_BUILDER:Please enter a number of intensity steps\n");
    }
    
    //check the trigger frequency is given 
    else if([[smellieTriggerFrequency stringValue] length] == 0){
        NSLog(@"SMELLIE_RUN_BUILDER:Please enter a trigger frequency\n");
    }
    
    //check the trigger frequency is given
    else if([[smellieNumTriggersPerLoop stringValue] length] == 0){
        NSLog(@"SMELLIE_RUN_BUILDER:Please enter a number of triggers per loop\n");
    }
    
    else{
        validationErrorFlag = [NSNumber numberWithInt:2];
    }
    
    //If any errors has been detected in the validation 
    if([validationErrorFlag intValue] == 1){
        [smellieRunErrorTextField setStringValue:smellieRunErrorString];
        [smellieMakeNewRunButton setEnabled:NO]; //Disable the user from this button
    }
    else if ([validationErrorFlag intValue] == 2){
        [smellieRunErrorTextField setStringValue:@"No Error"];
        [smellieMakeNewRunButton setEnabled:YES]; //Enable the user from this button
        

    
        //fill the SMELLIE run information from the interface into an Array 
        [smellieRunSettingsFromGUI setObject:[smellieOperatorName stringValue] forKey:@"operator_name"];
        [smellieRunSettingsFromGUI setObject:[smellieRunName stringValue] forKey:@"run_name"];
        [smellieRunSettingsFromGUI setObject:[smellieOperationMode stringValue] forKey:@"operator_name"];
        [smellieRunSettingsFromGUI setObject:[smellieMaxIntensity integerValue] forKey:@"max_laser_intensity"];
        [smellieRunSettingsFromGUI setObject:[smellieMinIntensity integerValue] forKey:@"min_laser_intensity"];
        [smellieRunSettingsFromGUI setObject:[smellieNumIntensitySteps integerValue] forKey:@"num_intensity_steps"];
        [smellieRunSettingsFromGUI setObject:[smellieTriggerFrequency integerValue] forKey:@"trigger_frequency"];
        [smellieRunSettingsFromGUI setObject:[smellieNumTriggersPerLoop integerValue] forKey:@"triggers_per_loop"];
        [smellieRunSettingsFromGUI setObject:[smellie375nmLaserButton state] forKey:@"375nm_laser_on"];
        [smellieRunSettingsFromGUI setObject:[smellie405nmLaserButton state] forKey:@"405nm_laser_on"];
        [smellieRunSettingsFromGUI setObject:[smellie440nmLaserButton state] forKey:@"440nm_laser_on"];
        [smellieRunSettingsFromGUI setObject:[smellie500nmLaserButton state] forKey:@"500nm_laser_on"];
        
        //Fill the SMELLIE Fibre Array information
        [smellieRunSettingsFromGUI setObject:[smellieFibreButtonFS007 state] forKey:@"FS007"];
        [smellieRunSettingsFromGUI setObject:[smellieFibreButtonFS107 state] forKey:@"FS107"];
        [smellieRunSettingsFromGUI setObject:[smellieFibreButtonFS207 state] forKey:@"FS207"];
        [smellieRunSettingsFromGUI setObject:[smellieFibreButtonFS025 state] forKey:@"FS025"];
        [smellieRunSettingsFromGUI setObject:[smellieFibreButtonFS125 state] forKey:@"FS125"];
        [smellieRunSettingsFromGUI setObject:[smellieFibreButtonFS225 state] forKey:@"FS225"];
        [smellieRunSettingsFromGUI setObject:[smellieFibreButtonFS037 state] forKey:@"FS037"];
        [smellieRunSettingsFromGUI setObject:[smellieFibreButtonFS137 state] forKey:@"FS137"];
        [smellieRunSettingsFromGUI setObject:[smellieFibreButtonFS237 state] forKey:@"FS237"];
        [smellieRunSettingsFromGUI setObject:[smellieFibreButtonFS055 state] forKey:@"FS055"];
        [smellieRunSettingsFromGUI setObject:[smellieFibreButtonFS155 state] forKey:@"FS155"];
        [smellieRunSettingsFromGUI setObject:[smellieFibreButtonFS255 state] forKey:@"FS255"];
        
        

        [model loadSmellieSettings]; //load settings to the SMELLIE DAQ (SNODROP)
    }
    else{
        NSLog(@"SMELLIE_BUILD_RUN: Unknown invalid Entry or no entries sent\n");
    }
    
    [validationErrorFlag release];
    [smellieRunErrorString release];
    
    //Example functions of how this values can be pulled 
    //state 1 is ON, state 0 is OFF for these buttons
    //NSLog(@"375 laser setting %i \n",[smellie375nmLaserButton state]);
    //NSLog(@"Entry into the Operator Field %@ \n",[smellieOperationMode stringValue]);
    
    //[model validationSmellieSettings];
}


//TELLIE functions -------------------------



@end