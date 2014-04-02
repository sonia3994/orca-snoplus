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
}

@property (nonatomic,retain) NSMutableDictionary* smellieRunSettings;

-(void) setUpImage;
-(void) makeMainController;
-(void) wakeUp;
-(void) sleep;
-(void) dealloc;

-(void) validationSmellieSettings;

@end

extern NSString* ELLIEAllLasersChanged;