//
//  ORMPodProtocol.h
//  Orca
//
//  Created by Mark Howe on Thurs Jan 6,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

@protocol ORMPodProtocol <NSObject>

- (void) getValue:(NSString*)cmd target:(id)aTarget selector:(SEL)aSelector priority:(NSOperationQueuePriority)aPriority;
- (void) getValues:(NSArray*)cmds target:(id)aTarget selector:(SEL)aSelector priority:(NSOperationQueuePriority)aPriority;
- (void) getValues:(NSArray*)cmds target:(id)aTarget selector:(SEL)aSelector;
- (void) writeValue:(NSString*)aCmd target:(id)aTarget selector:(SEL)aSelector;
- (void) writeValue:(NSString*)aCmd target:(id)aTarget selector:(SEL)aSelector priority:(NSOperationQueuePriority)aPriority;
- (void) callBackToTarget:(id)aTarget selector:(SEL)aSelector userInfo:(id)userInfo;

@end
