//
//  ELLIEModel.h
//  Orca
//
//  Created by Chris Jones on 01/04/2014.
//
//

#import <Foundation/Foundation.h>
#import <ELLIEController.h>

@interface ELLIEModel :  OrcaObject{
    NSMutableDictionary* smellieRunSettings;
    NSTask* exampleTask;
}

@property (nonatomic,retain) NSMutableDictionary* smellieRunSettings;
@property (nonatomic,retain) NSTask* exampleTask;

-(void) setUpImage;
-(void) makeMainController;
-(void) wakeUp;
-(void) sleep;
-(void) dealloc;


/*This function calls a python script: 
    pythonScriptFilePath - this is the python script file path
    withCmdLineArgs - these are the arguments for the python script*/
-(NSString*)callPythonScript:(NSString*)pythonScriptFilePath withCmdLineArgs:(NSArray*)commandLineArgs;

//starts a SMELLIE run with given parameters and submits the smellie run file to the database
-(void)startSmellieRun:(NSDictionary*)smellieSettings;

-(void) exampleFunctionForPython;

@end

extern NSString* ELLIEAllLasersChanged;
extern NSString* ELLIEAllFibresChanged;