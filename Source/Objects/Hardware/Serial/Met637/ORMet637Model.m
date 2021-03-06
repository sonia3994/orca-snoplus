
//--------------------------------------------------------
// ORMet637Model
// Created by Mark  A. Howe on Mon Jan 23, 2012
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2012 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ***Imported Files

#import "ORMet637Model.h"
#import "ORSerialPortAdditions.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORTimeRate.h"
#import "ORAlarm.h"

#pragma mark ***External Strings
NSString* ORMet637ModelDumpCountChanged		  = @"ORMet637ModelDumpCountChanged";
NSString* ORMet637ModelDumpInProgressChanged  = @"ORMet637ModelDumpInProgressChanged";
NSString* ORMet637ModelIsLogChanged			  = @"ORMet637ModelIsLogChanged";
NSString* ORMet637ModelHoldTimeChanged		  = @"ORMet637ModelHoldTimeChanged";
NSString* ORMet637ModelTempUnitsChanged		  = @"ORMet637ModelTempUnitsChanged";
NSString* ORMet637ModelCountUnitsChanged	  = @"ORMet637ModelCountUnitsChanged";
NSString* ORMet637ModelStatusBitsChanged	  = @"ORMet637ModelStatusBitsChanged";
NSString* ORMet637ModelLocationChanged		  = @"ORMet637ModelLocationChanged";
NSString* ORMet637ModelHumidityChanged		  = @"ORMet637ModelHumidityChanged";
NSString* ORMet637ModelTemperatureChanged	  = @"ORMet637ModelTemperatureChanged";
NSString* ORMet637ModelActualDurationChanged  = @"ORMet637ModelActualDurationChanged";
NSString* ORMet637ModelCountAlarmLimitChanged = @"ORMet637ModelCountAlarmLimitChanged";
NSString* ORMet637ModelMaxCountsChanged		  = @"ORMet637ModelMaxCountsChanged";
NSString* ORMet637ModelCycleNumberChanged	  = @"ORMet637ModelCycleNumberChanged";
NSString* ORMet637ModelCycleWillEndChanged	  = @"ORMet637ModelCycleWillEndChanged";
NSString* ORMet637ModelCycleStartedChanged	  = @"ORMet637ModelCycleStartedChanged";
NSString* ORMet637ModelRunningChanged		  = @"ORMet637ModelRunningChanged";
NSString* ORMet637ModelCycleDurationChanged   = @"ORMet637ModelCycleDurationChanged";
NSString* ORMet637ModelCountingModeChanged	  = @"ORMet637ModelCountingModeChanged";
NSString* ORMet637ModelCountChanged			  = @"ORMet637ModelCount2Changed";
NSString* ORMet637ModelMeasurementDateChanged = @"ORMet637ModelMeasurementDateChanged";
NSString* ORMet637ModelMissedCountChanged   = @"ORMet637ModelMissedCountChanged";

NSString* ORMet637Lock = @"ORMet637Lock";

@interface ORMet637Model (private)
- (void) addCmdToQueue:(NSString*)aCmd;
- (void) process_response:(NSString*)theResponse;
- (void) checkCycle;
- (void) dumpTimeout;
- (void) clearDelay;
- (void) processOneCommandFromQueue;
- (void) checkDate;
- (void) startDataArrivalTimeout;
- (void) cancelDataArrivalTimeout;
- (void) doCycleKick;
- (void) postCouchDBRecord;
@end

@implementation ORMet637Model

- (id) init
{
	self = [super init];
	[[self undoManager] disableUndoRegistration];
	int i;
	for(i=0;i<6;i++){
		[self setIndex:i maxCounts:1000];
		[self setIndex:i countAlarmLimit:800];
	}
	[[self undoManager] enableUndoRegistration];
	return self;
}

- (void) dealloc
{
    [cycleWillEnd release];
    [cycleStarted release];
    [measurementDate release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [buffer release];
	
	int i;
	for(i=0;i<8;i++){
		[timeRates[i] release];
	}	
	
	[sensorErrorAlarm release];
	[sensorErrorAlarm clearAlarm];

	[lowBatteryAlarm release];
	[lowBatteryAlarm clearAlarm];

	[flowErrorAlarm release];
	[flowErrorAlarm clearAlarm];
    
	[missingCyclesAlarm release];
	[missingCyclesAlarm clearAlarm];

	[super dealloc];
}

- (void) sleep
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super sleep];
}

- (void) wakeUp
{
	[super wakeUp];
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"Met637.tif"]];
}

- (void) makeMainController
{
	[self linkToController:@"ORMet637Controller"];
}
- (NSString*) helpURL
{
	return @"RS232/Met637.html";
}

- (void) dataReceived:(NSNotification*)note
{
    if([[note userInfo] objectForKey:@"serialPort"] == serialPort){
		
        NSString* theString = [[[[NSString alloc] initWithData:[[note userInfo] objectForKey:@"data"] 
												      encoding:NSASCIIStringEncoding] autorelease] uppercaseString];
	
		//the serial port may break the data up into small chunks, so we have to accumulate the chunks until
		//we get a full piece.
				
        if(!buffer)buffer = [[NSMutableString string] retain];
        [buffer appendString:theString];	
		
        do {
            NSRange lineRange = [buffer rangeOfString:@"\r\n"];
            if(lineRange.location!= NSNotFound){
                NSString* theResponse = [[[buffer substringToIndex:lineRange.location+1] copy] autorelease];
                [buffer deleteCharactersInRange:NSMakeRange(0,lineRange.location+1)];      //take the cmd out of the buffer
				
				if([theResponse length] != 0){
					[self process_response:theResponse];
				}
				if(!dumpInProgress){
					[self setLastRequest:nil];			 //clear the last request
					[self processOneCommandFromQueue];	 //do the next command in the queue
				}

            }
        } while([buffer rangeOfString:@"\r\n"].location!= NSNotFound);
	}
}

#pragma mark ***Accessors
- (int) missedCycleCount
{
    return missedCycleCount;
}

- (void) setMissedCycleCount:(int)aValue
{
    missedCycleCount = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet637ModelMissedCountChanged object:self];
    
	if(((missedCycleCount >= 3) && (countingMode == kMet637Auto)) || 
       ((missedCycleCount > 0) && (countingMode == kMet637Manual))){
		if(!missingCyclesAlarm){
			NSString* s = [NSString stringWithFormat:@"Met637 (Unit %lu) Missing Cycles",[self uniqueIdNumber]];
			missingCyclesAlarm = [[ORAlarm alloc] initWithName:s severity:kHardwareAlarm];
			[missingCyclesAlarm setSticky:YES];
            if(countingMode == kMet637Manual)[missingCyclesAlarm setHelpString:@"The particle counter did not report counts at the end of its last single cycle.\n\nThis alarm will not go away until the problem is cleared. Acknowledging the alarm will silence it."];			
            else [missingCyclesAlarm setHelpString:@"The particle counter is not reporting counts at the end of its cycle. ORCA tried to kick start it at least three times.\n\nThis alarm will not go away until the problem is cleared. Acknowledging the alarm will silence it."];
			[missingCyclesAlarm postAlarm];
		}
	}
	else {
		[missingCyclesAlarm clearAlarm];
		[missingCyclesAlarm release];
		missingCyclesAlarm = nil;
	}
    
}

- (int) dumpCount
{
    return dumpCount;
}

- (void) setDumpCount:(int)aDumpCount
{
    dumpCount = aDumpCount;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet637ModelDumpCountChanged object:self];
}

- (BOOL) dumpInProgress
{
    return dumpInProgress;
}

- (void) setDumpInProgress:(BOOL)aDumpInProgress
{
    dumpInProgress = aDumpInProgress;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet637ModelDumpInProgressChanged object:self];
}

- (BOOL) isLog
{
    return isLog;
}

- (void) setIsLog:(BOOL)aIsLog
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIsLog:isLog];
    isLog = aIsLog;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet637ModelIsLogChanged object:self];
}

- (int) holdTime
{
    return holdTime;
}

- (void) setHoldTime:(int)aHoldTime
{
	if(aHoldTime<0)aHoldTime = 0;
	if(aHoldTime>999)aHoldTime = 99;
    [[[self undoManager] prepareWithInvocationTarget:self] setHoldTime:holdTime];
    holdTime = aHoldTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet637ModelHoldTimeChanged object:self];
}

- (int) tempUnits
{
    return tempUnits;
}

- (void) setTempUnits:(int)aTempUnits
{
	if(aTempUnits<0)aTempUnits = 0;
	if(aTempUnits>1)aTempUnits = 1;
    [[[self undoManager] prepareWithInvocationTarget:self] setTempUnits:tempUnits];
    tempUnits = aTempUnits;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet637ModelTempUnitsChanged object:self];
}

- (int) countUnits
{
    return countUnits;
}

- (void) setCountUnits:(int)aCountUnits
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCountUnits:countUnits];
    countUnits = aCountUnits;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet637ModelCountUnitsChanged object:self];
}

- (int) statusBits
{
    return statusBits;
}

- (void) setStatusBits:(int)aStatusBits
{
    statusBits = aStatusBits;
	[self checkAlarms];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet637ModelStatusBitsChanged object:self];
}

- (void) checkAlarms
{
	if(statusBits & 0x10){
		if(!lowBatteryAlarm){
			NSString* s = [NSString stringWithFormat:@"Met637 (Unit %lu)",[self uniqueIdNumber]];
			lowBatteryAlarm = [[ORAlarm alloc] initWithName:s severity:kHardwareAlarm];
			[lowBatteryAlarm setSticky:YES];
			[lowBatteryAlarm setHelpString:@"The battery on the particle counter is low. Is it supposed to be running on the battery?\n\nThis alarm will not go away until the problem is cleared. Acknowledging the alarm will silence it."];
			[lowBatteryAlarm postAlarm];
		}
	}
	else {
		[lowBatteryAlarm clearAlarm];
		[lowBatteryAlarm release];
		lowBatteryAlarm = nil;
	}
	
	if(statusBits & 0x20){
		if(!sensorErrorAlarm){
			NSString* s = [NSString stringWithFormat:@"Met637 (Unit %lu)",[self uniqueIdNumber]];
			sensorErrorAlarm = [[ORAlarm alloc] initWithName:s severity:kHardwareAlarm];
			[sensorErrorAlarm setSticky:YES];
			[sensorErrorAlarm setHelpString:@"The sensor is reporting a hardware error.\n\nThis alarm will not go away until the problem is cleared. Acknowledging the alarm will silence it."];
			[sensorErrorAlarm postAlarm];
		}
	}
	else {
		[sensorErrorAlarm clearAlarm];
		[sensorErrorAlarm release];
		sensorErrorAlarm = nil;
	}
	
	if(statusBits & 0x40){
		if(!flowErrorAlarm){
			NSString* s = [NSString stringWithFormat:@"Met637 (Unit %lu)",[self uniqueIdNumber]];
			flowErrorAlarm = [[ORAlarm alloc] initWithName:s severity:kHardwareAlarm];
			[flowErrorAlarm setSticky:YES];
			[flowErrorAlarm setHelpString:@"The particle counter is reporting a flow error.\n\nThis alarm will not go away until the problem is cleared. Acknowledging the alarm will silence it."];
			[flowErrorAlarm postAlarm];
		}
	}
	else {
		[flowErrorAlarm clearAlarm];
		[flowErrorAlarm release];
		flowErrorAlarm = nil;
	}
}

- (int) location
{
    return location;
}

- (void) setLocation:(int)aLocation
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLocation:location];
    location = aLocation;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet637ModelLocationChanged object:self];
}

- (float) humidity
{
    return humidity;
}

- (void) setHumidity:(float)aHumidity
{
    humidity = aHumidity;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet637ModelHumidityChanged object:self];
	if(timeRates[7] == nil) timeRates[7] = [[ORTimeRate alloc] init];
	[timeRates[7] addDataToTimeAverage:humidity];
}

- (float) temperature
{
    return temperature;
}

- (void) setTemperature:(float)aTemperature
{
    temperature = aTemperature;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet637ModelTemperatureChanged object:self];
	if(timeRates[6] == nil) timeRates[6] = [[ORTimeRate alloc] init];
	[timeRates[6] addDataToTimeAverage:temperature];

}

- (int) actualDuration
{
    return actualDuration;
}

- (void) setActualDuration:(int)aActualDuration
{
    actualDuration = aActualDuration;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet637ModelActualDurationChanged object:self];
}

- (float) countAlarmLimit:(int)index
{
	if(index>=0 && index<8) return countAlarmLimit[index];
	else return 0;
}

- (void) setIndex:(int)index countAlarmLimit:(float)aCountAlarmLimit
{
	if(index<0 || index>=8)return;
	[[[self undoManager] prepareWithInvocationTarget:self] setIndex:index countAlarmLimit:countAlarmLimit[index]];
    countAlarmLimit[index] = aCountAlarmLimit;
	NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:[NSNumber numberWithInt:index] forKey: @"Channel"];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet637ModelCountAlarmLimitChanged object:self userInfo:userInfo];
}

- (float) maxCounts:(int)index
{
	if(index>=0 && index<8) return maxCounts[index];
	else return 0;
}

- (void) setIndex:(int)index maxCounts:(float)aMaxCounts
{
	if(index<0 || index>=8)return;
	[[[self undoManager] prepareWithInvocationTarget:self] setIndex:index maxCounts:maxCounts[index]];
	maxCounts[index] = aMaxCounts;
	NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:[NSNumber numberWithInt:index] forKey: @"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet637ModelMaxCountsChanged object:self  userInfo:userInfo];
}

- (ORTimeRate*)timeRate:(int)index
{
	if(index>=0 && index<8) return timeRates[index];
	else return nil;
}

- (int) cycleNumber
{
    return cycleNumber;
}

- (void) setCycleNumber:(int)aCycleNumber
{
    cycleNumber = aCycleNumber;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet637ModelCycleNumberChanged object:self];
}

- (NSDate*) cycleWillEnd
{
    return cycleWillEnd;
}

- (void) setCycleWillEnd:(NSCalendarDate*)aCycleWillEnd
{
    [aCycleWillEnd retain];
    [cycleWillEnd release];
    cycleWillEnd = aCycleWillEnd;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet637ModelCycleWillEndChanged object:self];
}

- (NSDate*) cycleStarted
{
    return cycleStarted;
}

- (void) setCycleStarted:(NSDate*)aCycleStarted
{
    [aCycleStarted retain];
    [cycleStarted release];
    cycleStarted = aCycleStarted;

	int totalTime = [self cycleDuration]; //approx start time added.
	if(countingMode==kMet637Auto){
		if(cycleNumber>1) totalTime += holdTime;
		else			  totalTime += 6;
	}
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 
	NSDate* endTime = [aCycleStarted dateByAddingTimeInterval:totalTime];
#else
	NSDate* endTime = [aCycleStarted addTimeInterval:totalTime];
#endif
	[self setCycleWillEnd:endTime]; 
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet637ModelCycleStartedChanged object:self];
}

- (BOOL) running
{
    return running;
}

- (void) setRunning:(BOOL)aRunning
{
    running = aRunning;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet637ModelRunningChanged object:self];
}

- (int) cycleDuration
{
    return cycleDuration;
}

- (void) setCycleDuration:(int)aCycleDuration
{
	if(aCycleDuration < 10) aCycleDuration = 10;
	else if(aCycleDuration > 999) aCycleDuration = 999;
    [[[self undoManager] prepareWithInvocationTarget:self] setCycleDuration:cycleDuration];
    
    cycleDuration = aCycleDuration;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet637ModelCycleDurationChanged object:self];
}

- (int) countingMode
{
    return countingMode;
}

- (void) setCountingMode:(int)aCountingMode
{
    countingMode = aCountingMode;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet637ModelCountingModeChanged object:self];
}

- (NSString*) countingModeString
{
	switch ([self countingMode]) {
		case kMet637Manual: return @"Single Cycle";
		case kMet637Auto:   return @"Repeating";
		default: return @"--";
	}
}

- (void) setCount:(int)index value:(int)aValue
{
	if(index>=0 && index<6){
		count[index] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMet637ModelCountChanged object:self];
		if(timeRates[index] == nil) timeRates[index] = [[ORTimeRate alloc] init];
		[timeRates[index] addDataToTimeAverage:aValue];
	}
}

- (int) count:(int)index
{
	if(index>=0 && index<6)return count[index];
	else return 0;
}

- (NSString*) measurementDate
{
	if(!measurementDate)return @"";
    else return measurementDate;
}

- (void) setMeasurementDate:(NSString*)aMeasurementDate
{
    [measurementDate autorelease];
    measurementDate = [aMeasurementDate copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet637ModelMeasurementDateChanged object:self];
}

- (void) setUpPort
{
	[serialPort setSpeed:9600];
	[serialPort setParityNone];
	[serialPort setStopBits2:NO];
	[serialPort setDataBits:8];
}

- (void) firstActionAfterOpeningPort
{
	[self probe];
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	[self setIsLog:				[decoder decodeBoolForKey:@"isLog"]];
	[self setHoldTime:			[decoder decodeIntForKey:   @"holdTime"]];
	[self setTempUnits:			[decoder decodeIntForKey:   @"tempUnits"]];
	[self setCountUnits:		[decoder decodeIntForKey:   @"countUnits"]];
	[self setLocation:			[decoder decodeIntForKey:   @"location"]];
	wasRunning =				[decoder decodeBoolForKey:  @"wasRunning"];
	[self setCycleDuration:		[decoder decodeIntForKey:   @"cycleDuration"]];
	[self setCountingMode:		[decoder decodeIntForKey:   @"countingMode"]];

	int i; 
	for(i=0;i<8;i++){
		timeRates[i] = [[ORTimeRate alloc] init];
		[self setIndex:i countAlarmLimit:  	[decoder decodeFloatForKey: [NSString stringWithFormat:@"countAlarmLimit%d",i]]];
		[self setIndex:i maxCounts:			[decoder decodeFloatForKey: [NSString stringWithFormat:@"maxCounts%d",i]]];
	}
	
	[[self undoManager] enableUndoRegistration];
	
	return self;
}
- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:	isLog			forKey:@"isLog"];
    [encoder encodeInt:		holdTime		forKey: @"holdTime"];
    [encoder encodeInt:		tempUnits		forKey: @"tempUnits"];
    [encoder encodeInt:		countUnits		forKey: @"countUnits"];
    [encoder encodeInt:		location		forKey: @"location"];
    [encoder encodeInt:		cycleDuration	forKey: @"cycleDuration"];
    [encoder encodeInt:		countingMode	forKey: @"countingMode"];
    [encoder encodeBool:	wasRunning		forKey:	@"wasRunning"];
	int i; 
	for(i=0;i<8;i++){
		[encoder encodeFloat:	countAlarmLimit[i] forKey: [NSString stringWithFormat:@"countAlarmLimit%d",i]];
		[encoder encodeFloat:	maxCounts[i]	   forKey: [NSString stringWithFormat:@"maxCounts%d",i]];

	}
}
#pragma mark *** Commands
- (void) sendNewData
{
	if([serialPort isOpen]){
		NSLog(@"Met637 (%d): Starting print of new data\n",[self uniqueIdNumber]);
		NSLog(@"Any subsequent cmd will abort the print\n");
	}
	[self addCmdToQueue:@"3"]; 
}

- (void) sendAllData 
{ 
	if([serialPort isOpen]){
		NSLog(@"Met637 (%d): Starting print of all data\n",[self uniqueIdNumber]);
		NSLog(@"Any subsequent cmd will abort the print\n");
	}
	[self addCmdToQueue:@"2"]; 
}

- (void) setDate
{ 
	unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSMinuteCalendarUnit | NSHourCalendarUnit;
	NSDate *today = [NSDate date];
	NSCalendar *gregorian = [[[NSCalendar alloc]  initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSDateComponents *comps = [gregorian components:unitFlags fromDate:today];
	[self addCmdToQueue:[NSString stringWithFormat:@"D %02d/%02d/%02d",[comps month],[comps day],[comps year]-2000]]; 
	[self addCmdToQueue:[NSString stringWithFormat:@"T %02d:%02d",[comps hour],[comps minute]]]; 
}
- (void) sendClearData				{ [self addCmdToQueue:@"C\rY"]; }
- (void) sendStart					{ [self addCmdToQueue:@"S"]; }
- (void) sendEnd					{ [self addCmdToQueue:@"E"]; }
- (void) getSampleTime				{ [self addCmdToQueue:@"ST"]; }
- (void) getSampleMode				{ [self addCmdToQueue:@"SM"]; }
- (void) getLocation				{ [self addCmdToQueue:@"ID"]; }
- (void) getHoldTime				{ [self addCmdToQueue:@"SH"]; }
- (void) getUnits					{ [self addCmdToQueue:@"CU\rTU"]; }
- (void) sendCountingTime:(int)aValue { [self addCmdToQueue:[NSString stringWithFormat:@"ST %d",aValue]]; }
- (void) sendCountingMode:(BOOL)aValue{ [self addCmdToQueue:[NSString stringWithFormat:@"SM %d",aValue]]; }
- (void) sendID:(int)aValue			{ [self addCmdToQueue:[NSString stringWithFormat:@"ID %d",aValue]]; }
- (void) sendHoldTime:(int)aValue	{ [self addCmdToQueue:[NSString stringWithFormat:@"SH %d",aValue]]; }
- (void) sendTempUnit:(int)aTempUnit countUnits:(int)aCountUnit		{ [self addCmdToQueue:[NSString stringWithFormat:@"CU %d\rTU %d",aTempUnit,aCountUnit]]; }
- (void) probe						{ probing = YES; [self getSampleTime]; }

#pragma mark ***Polling and Cycles
- (void) startCycle
{
    [self startCycle:NO];
}
- (void) startCycle:(BOOL)force
{
	if((![self running] || force) && [serialPort isOpen]){
		[self sendEnd];
        [self enqueueCmd:@"++Delay"];
		[self setCycleNumber:1];
		NSDate* now = [NSDate date];
		[self setCycleStarted:now];
		[self sendCountingMode:countingMode];
		[self sendHoldTime:holdTime];
		[self sendTempUnit:tempUnits countUnits:countUnits];
		[self sendCountingTime:cycleDuration];
        [self enqueueCmd:@"++Delay"];
		[self sendStart];
        [self startDataArrivalTimeout];
		NSLog(@"Met637(%d) Starting particle counter in %@ mode\n",[self uniqueIdNumber], [self countingModeString]);
	}
}

- (void) stopCycle
{
	if([self running] && [serialPort isOpen]){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkCycle) object:nil];
		[self setCycleNumber:0];
		[self sendEnd];
        [self cancelDataArrivalTimeout];
		NSLog(@"Met637(%d) Stopping particle counter. Was in %@ mode\n",[self uniqueIdNumber], [self countingModeString]);
	}
}


#pragma mark •••Bit Processing Protocol
- (void) processIsStarting
{
	if(!running){
		if(!sentStartOnce){
		   sentStartOnce = YES;
		   sentStopOnce = NO;
            wasRunning = NO;

			[self startCycle:YES];
		}
	}
    else wasRunning = YES;
}

- (void) processIsStopping
{
	if(!wasRunning){
		if(!sentStopOnce){
			sentStopOnce = YES;
			sentStartOnce = NO;
			[self stopCycle];
		}
	}
}

//note that everything called by these routines MUST be threadsafe
- (void) startProcessCycle
{    
	@try { 
	}
	@catch(NSException* localException) { 
		//catch this here to prevent it from falling thru, but nothing to do.
	}
}

- (void) endProcessCycle
{
}

- (NSString*) identifier
{
	NSString* s;
 	@synchronized(self){
		s= [NSString stringWithFormat:@"Met637,%lu",[self uniqueIdNumber]];
	}
	return s;
}

- (NSString*) processingTitle
{
	NSString* s;
 	@synchronized(self){
		s= [self identifier];
	}
	return s;
}

- (double) convertedValue:(int)aChan
{
	double theValue = 0;
	@synchronized(self){
		if(aChan<6)			theValue = [self count:aChan];
		else if(aChan==6)	theValue = [self temperature];
		else if(aChan==7)	theValue = [self humidity];
	}
	return theValue;
}

- (double) maxValueForChan:(int)aChan
{
	double theValue;
	@synchronized(self){
		theValue = (double)[self maxCounts:aChan]; 
	}
	return theValue;
}

- (double) minValueForChan:(int)aChan
{
	return 0;
}

- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit channel:(int)channel
{
	@synchronized(self){
		*theLowLimit = -.001;
		*theHighLimit =  [self countAlarmLimit:channel]; 
	}		
}

- (BOOL) processValue:(int)channel
{
	BOOL r;
	@synchronized(self){
		r = YES;    //temp -- figure out what the process bool for this object should be.
	}
	return r;
}

- (void) setProcessOutput:(int)channel value:(int)value
{
    //nothing to do. not used in adcs. really shouldn't be in the protocol
}

- (BOOL) dataForChannelValid:(int)aChannel
{
    return [self isValid] && [serialPort isOpen];
}

@end

@implementation ORMet637Model (private)

- (void) postCouchDBRecord
{    
    NSDictionary* values = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSArray arrayWithObjects:
                                [NSNumber numberWithInt:count[0]],
                                [NSNumber numberWithInt:count[1]],
                                [NSNumber numberWithInt:count[2]],
                                [NSNumber numberWithInt:count[3]],
                                [NSNumber numberWithInt:count[4]],
                                [NSNumber numberWithInt:count[5]],
                                nil], @"counts",
                            [NSArray arrayWithObjects:
                                 [NSNumber numberWithInt:countAlarmLimit[0]],
                                 [NSNumber numberWithInt:countAlarmLimit[1]],
                                 [NSNumber numberWithInt:countAlarmLimit[2]],
                                 [NSNumber numberWithInt:countAlarmLimit[3]],
                                 [NSNumber numberWithInt:countAlarmLimit[4]],
                                 [NSNumber numberWithInt:countAlarmLimit[5]],
                                 nil], @"countLimits",
                            [NSNumber numberWithFloat:  temperature],       @"temperature",
                            [NSNumber numberWithFloat:  humidity],         @"humidity",
                            [NSNumber numberWithInt:    actualDuration],   @"actualDuration",
                            [NSNumber numberWithInt:    statusBits],       @"statusBits",
                            [NSNumber numberWithInt:    cycleDuration],    @"pollTime",
                            nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord" object:self userInfo:values];
}

- (void) checkCycle
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkCycle) object:nil];
	if([serialPort isOpen]){ 
        [self probe];
        if(running){
            [self performSelector:@selector(checkCycle) withObject:nil afterDelay:kMet637ProbeTime];
        }
    }
}
- (void) startDataArrivalTimeout
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doCycleKick) object:nil];
    [self performSelector:@selector(doCycleKick)  withObject:nil afterDelay:(cycleDuration+120)];
}

- (void) cancelDataArrivalTimeout
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doCycleKick) object:nil];
}

- (void) doCycleKick
{
    [self setMissedCycleCount:missedCycleCount+1];
    NSLogColor([NSColor redColor],@"%@ data did not arrive at end of cycle (missed %d)\n",[self fullID],missedCycleCount);
    if(countingMode == kMet637Auto){
        NSLogColor([NSColor redColor],@"Kickstarting %@\n",[self fullID]);
        [self setCount:0 value:0];
        [self setCount:1 value:0];
        [self setCount:2 value:0];
        [self setCount:3 value:0];
        [self setCount:4 value:0];
        [self setCount:5 value:0];       
        [self setTemperature:0];
        [self setHumidity:0];
        [self setIsValid:NO];

        [self stopCycle];
        [self startCycle:YES];
    }
}


- (void) addCmdToQueue:(NSString*)aCmd
{
	if([serialPort isOpen]){ 
		aCmd = [aCmd stringByReplacingOccurrencesOfString:@"\n" withString:@""];
		if(![aCmd hasSuffix:@"\r"])aCmd = [aCmd stringByAppendingFormat:@"\r"];
		
		[self enqueueCmd:aCmd];
		[self enqueueCmd:@"++Delay"];
		
		if(!lastRequest){
			[self processOneCommandFromQueue];
		}
	}
	else NSLog(@"Met637 (%d): Serial Port not open. Cmd Ignored.\n",[self uniqueIdNumber]);
}

- (void) process_response:(NSString*)theResponse
{
	[self setIsValid:YES];
	theResponse = [theResponse stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSArray* partsByComma = [theResponse componentsSeparatedByString:@","];
	if([partsByComma count] >= 14 && ![theResponse hasPrefix:@"TIME"]){
		if(!dumpInProgress){
			[self setMeasurementDate: [partsByComma objectAtIndex:0]];
		
			[self setCount:0 value:[[partsByComma objectAtIndex:1] intValue]];
			[self setCount:1 value:[[partsByComma objectAtIndex:2] intValue]];
			[self setCount:2 value:[[partsByComma objectAtIndex:3] intValue]];
			[self setCount:3 value:[[partsByComma objectAtIndex:4] intValue]];
			[self setCount:4 value:[[partsByComma objectAtIndex:5] intValue]];
			[self setCount:5 value:[[partsByComma objectAtIndex:6] intValue]];
			
			[self setTemperature:[[partsByComma objectAtIndex:7] floatValue]];
			[self setHumidity:[[partsByComma objectAtIndex:8] floatValue]];
			[self setLocation:[[partsByComma objectAtIndex:9] floatValue]];
			[self setActualDuration:[[partsByComma objectAtIndex:10] intValue]];
			[self setStatusBits:[[partsByComma objectAtIndex:13] intValue]];
            
            [self setMissedCycleCount:0];
            [self cancelDataArrivalTimeout];
        
            [self postCouchDBRecord];
            
            if(countingMode == kMet637Manual){
                [self stopCycle];
            }
            else {
                [self startDataArrivalTimeout];
                int theCount = [self cycleNumber];
                [self setCycleNumber:theCount+1];
                [self setCycleStarted:[NSDate date]];
            }
			
            [self checkDate];
		}
		else {
			theResponse = [theResponse stringByReplacingOccurrencesOfString:@"\n" withString:@""];
			theResponse = [theResponse stringByReplacingOccurrencesOfString:@"\r" withString:@""];
			//put in a unix time stamp for convenience
			NSString* aDate = [partsByComma objectAtIndex:0];
			
			NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
			[dateFormatter setDateFormat:@"dd-MMM-yyyy HH:mm:ss"];
			NSDate* gmtTime = [dateFormatter dateFromString:aDate];
			NSNumber *timestamp=[[[NSNumber alloc] initWithDouble:[gmtTime timeIntervalSince1970]] autorelease];
			
			NSLog(@"%d, %@, %@\n",dumpCount,timestamp,theResponse);
			[self setDumpCount:dumpCount+1];
			[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dumpTimeout) object:nil];
			[self performSelector:@selector(dumpTimeout) withObject:nil afterDelay:.5];
		}
	}
	else {
		if(([theResponse length]==1) && ([lastRequest hasPrefix:@"2"] || [lastRequest hasPrefix:@"3"])){
			[self setDumpInProgress:YES];
			[self setDumpCount:0];
			[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dumpTimeout) object:nil];
			[self performSelector:@selector(dumpTimeout) withObject:nil afterDelay:.5];
		}
		else if([lastRequest hasPrefix:@"CU"]){
			if([partsByComma count] == 2){
				NSString* theUnits = [partsByComma objectAtIndex:1];
				if([theUnits hasPrefix:@"CF"])[self setCountUnits:0];
				else if([theUnits hasPrefix:@"/L"])[self setCountUnits:1];
				else if([theUnits hasPrefix:@"TC"])[self setCountUnits:2];
			}
		}
		else if([lastRequest hasPrefix:@"ST"]){
			NSArray* partsBySpaces = [theResponse componentsSeparatedByString:@" "];
			if([partsBySpaces count]==2){
				NSString* st = [partsBySpaces objectAtIndex:1];
				[self setCycleDuration:[st intValue]];
			}
		}
		else if([lastRequest hasPrefix:@"TU"]){
			NSArray* partsBySpaces = [theResponse componentsSeparatedByString:@" "];
			if([partsBySpaces count]==2){
				NSString* st = [partsBySpaces objectAtIndex:1];
				[self setTempUnits:[st intValue]];
			}
		}
        else if([theResponse rangeOfString:@"COUNTING STOPPED" options:NSCaseInsensitiveSearch].location != NSNotFound){
			[self setRunning:NO];
		}
		else if([theResponse rangeOfString:@"COUNTING STARTED" options:NSCaseInsensitiveSearch].location != NSNotFound){
			[self setRunning:YES];
			[self checkCycle];
		}
        else if([theResponse rangeOfString:@"CANNOT CHANGE WHILE" options:NSCaseInsensitiveSearch].location != NSNotFound){
			if(probing){
				probing = NO;
			}
			[self setRunning:YES];
		}
		else if([theResponse hasPrefix:@"CLEAR"]){
			NSLog(@"Met637(%d) Clearing ALL data.",[self uniqueIdNumber]);
		}	
	}
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
}

- (void) checkDate
{
    if([measurementDate length]){
        NSDateFormatter* dateFormat = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormat setDateFormat:@"dd-MMM-yyyy HH:mm:ss"];
        NSDate* measuredDate = [dateFormat dateFromString:measurementDate];
        NSTimeInterval delta = fabs((double)[measuredDate timeIntervalSinceNow]);
        if(delta > kMet637AllowedTimeDelta){
            NSLog(@"Stopping %@ to sync the time (time error: %.0f secs)\n",[self fullID],delta);
            [self stopCycle];
            int i;
            for(i=0;i<5/kMet637DelayTime;i++){
                [self enqueueCmd:@"++Delay"];
            }
            [self setDate];
            if(countingMode == kMet637Auto){
                NSLog(@"Restarting %@ after sync'ing the date\n",[self fullID]);
                [self startCycle:YES];
            }
            
        }
    }
}

- (void) clearDelay
{
	delay = NO;
	[self processOneCommandFromQueue];
}

- (void) dumpTimeout
{
	[self setDumpInProgress:NO];
	[self setDumpCount:0];
	[self setLastRequest:nil];			 //clear the last request
	[self processOneCommandFromQueue];	 //do the next command in the queue

	NSLog(@"Met637 (%d): Data printout finished\n",[self uniqueIdNumber]);
}

- (void) processOneCommandFromQueue
{
    if(delay)return;
	
	NSString* aCmd = [self nextCmd];
	if(aCmd){
		if([aCmd isEqualToString:@"++Delay"]){
			delay = YES;
			[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(clearDelay) object:nil];
			[self performSelector:@selector(clearDelay) withObject:nil afterDelay:kMet637DelayTime];
		}
		else {
			[self startTimeout:3];
			[self setLastRequest:aCmd];
			[serialPort writeString:aCmd];
		}
	}
}

@end
