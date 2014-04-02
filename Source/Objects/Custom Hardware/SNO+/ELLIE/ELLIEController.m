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

-(IBAction)validationSmellieRunAction:(id)sender;
{
    
    //Validate that all of the fields make sense
    
    NSString* noOperatorNameErrorMsg = [[NSString alloc] initWithString:@"SMELLIE_RUN_BUILDER:Please enter a Operator Name" ];
    NSString* smellieRunErrorString = [[NSString alloc] initWithString:@"Unable to Validate. Check all fields are entered and see Status and Error Log" ];
    
    int validationErrorFlag = 0;
    
    //check the Operator has entered their name 
    if([[smellieOperatorName stringValue] length] == 0){
        NSLog(@"%@ \n",noOperatorNameErrorMsg);
        validationErrorFlag = 1;
    }
    
    
    //TODO:Complete all the other validation methods here 
    
    //If any errors has been detected in the validation 
    if(validationErrorFlag == 1){
        [smellieRunErrorTextField setStringValue:smellieRunErrorString];
        [smellieMakeNewRunButton setEnabled:NO]; //Disable the user from this button
    }
    else{
        validationErrorFlag = 0;
        [smellieRunErrorTextField setStringValue:@"No Error"];
        [smellieMakeNewRunButton setEnabled:YES]; //Enable the user from this button 
    }
    
    //pull the information from the interface
    [smellieRunSettingsFromGUI setObject:[smellie375nmLaserButton state] forKey:@"375nm_laser_on"];
    [smellieRunSettingsFromGUI setObject:[smellie405nmLaserButton state] forKey:@"405nm_laser_on"];
    [smellieRunSettingsFromGUI setObject:[smellie440nmLaserButton state] forKey:@"440nm_laser_on"];
    [smellieRunSettingsFromGUI setObject:[smellie500nmLaserButton state] forKey:@"500nm_laser_on"];
    [smellieRunSettingsFromGUI setObject:[smellieOperatorName stringValue] forKey:@"operator_name"];
    [smellieRunSettingsFromGUI setObject:[smellieRunName stringValue] forKey:@"run_name"];
    [smellieRunSettingsFromGUI setObject:[smellieOperationMode stringValue] forKey:@"operator_name"];
    [smellieRunSettingsFromGUI setObject:[smellieMaxIntensity integerValue] forKey:@"max_laser_intensity"];
    [smellieRunSettingsFromGUI setObject:[smellieMinIntensity integerValue] forKey:@"min_laser_intensity"];
    [smellieRunSettingsFromGUI setObject:[smellieNumIntensitySteps integerValue] forKey:@"num_intensity_steps"];
    [smellieRunSettingsFromGUI setObject:[smellieTriggerFrequency integerValue] forKey:@"trigger_frequency"];
    [smellieRunSettingsFromGUI setObject:[smellieNumTriggersPerLoop integerValue] forKey:@"triggers_per_loop"];
    
    //Example functions of how this values can be pulled 
    //state 1 is ON, state 0 is OFF for these buttons
    NSLog(@"375 laser setting %i \n",[smellie375nmLaserButton state]);
    NSLog(@"Entry into the Operator Field %@ \n",[smellieOperationMode stringValue]);
    
    //[model validationSmellieSettings];
}


//TELLIE functions -------------------------



@end