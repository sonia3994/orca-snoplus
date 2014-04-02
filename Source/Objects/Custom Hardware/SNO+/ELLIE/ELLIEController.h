//
//  ELLIEController.h
//  Orca
//
//  Created by Chris Jones on 01/04/2014.
//
//

#import <Foundation/Foundation.h>

@interface ELLIEController : OrcaObjectController {
    
    //SMELLIE interface --------------------------------------
    
    //Storage of run information
    NSMutableDictionary* smellieRunSettingsFromGUI;
    
    //check buttons for lasers
    IBOutlet NSButton* smellie375nmLaserButton;    //check box for 375nm Laser
    IBOutlet NSButton* smellie405nmLaserButton;    //check box for 405nm Laser
    IBOutlet NSButton* smellie440nmLaserButton;    //check box for 440nm Laser
    IBOutlet NSButton* smellie500nmLaserButton;    //check box for 500nm Laser
    IBOutlet NSButton* smellieAllLasersButton;     //check box for all Lasers set 
    
    //More Run Information
    IBOutlet NSTextField* smellieOperatorName;      //Operator Name Field
    IBOutlet NSTextField* smellieRunName;           //Run Name Field
    IBOutlet NSComboBox* smellieOperationMode;      //Operation mode (master or slave)
    IBOutlet NSTextField* smellieMaxIntensity;      //maximum intensity of lasers in run
    IBOutlet NSTextField* smellieMinIntensity;      //minimum intensity of lasers in run
    IBOutlet NSTextField* smellieNumIntensitySteps;     //number of intensities to step through
    IBOutlet NSTextField* smellieTriggerFrequency;  //trigger frequency of SMELLIE in Hz
    IBOutlet NSTextField* smellieNumTriggersPerLoop;    //number of triggers to be sent per iteration
    
    //Control Button
    IBOutlet NSButton* smellieMakeNewRunButton; //make a new smellie run 
    
    //Error Fields
    IBOutlet NSTextField* smellieRunErrorTextField; //new run error text field 

    //TELLIE interface ------------------------------------------
    
}

@property (nonatomic,retain) NSMutableDictionary* smellieRunSettingsFromGUI;

-(id)init;
-(void)dealloc;
-(void) updateWindow;
-(void) registerNotificationObservers;

//SMELLIE functions ----------------------------


//Button clicked to validate the new run type settings for smellie 
-(IBAction)validationSmellieRunAction:(id)sender;
-(IBAction)setAllLasersAction:(id)sender;












//TELLIE functions -----------------------------

@end

