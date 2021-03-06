#include "OREdelweissSLTv4Readout.hh"
#include "EdelweissSLTv4_HW_Definitions.h"

#include "readout_code.h"


#ifndef PMC_COMPILE_IN_SIMULATION_MODE
	#define PMC_COMPILE_IN_SIMULATION_MODE 0
#endif


#if PMC_COMPILE_IN_SIMULATION_MODE
    #warning MESSAGE: ORSLTv4Readout - PMC_COMPILE_IN_SIMULATION_MODE is 1
    #include <sys/time.h> // for gettimeofday on MAC OSX -tb-
#else
    //#warning MESSAGE: ORFLTv4Readout - PMC_COMPILE_IN_SIMULATION_MODE is 0
	#include "katrinhw4/subrackkatrin.h"
#endif


#if !PMC_COMPILE_IN_SIMULATION_MODE
// (this is the standard code accessing the v4 crate-tb-)
//----------------------------------------------------------------

extern Pbus* pbus; 
#include "ipe4tbtools.h"
//#include "HW_Readout.h" //for presentFLTMap
extern uint32_t presentFLTMap; // store a map of the present FLT cards


bool ORSLTv4Readout::Readout(SBC_LAM_Data* lamData)
{

    uint32_t readbuffer32[2048];
    uint32_t shipbuffer32[2048];
    uint16_t *shipbuffer16=(uint16_t *)shipbuffer32;
    uint32_t shipdebugbuffer32[2048];
    uint16_t *shipdebugbuffer16=(uint16_t *)shipdebugbuffer32;
    
    int32_t leaf_index;
    //read out the children flts that are in the readout list
    leaf_index = GetNextTriggerIndex()[0];
    //debug fprintf(stdout,"ORSLTv4Readout::Readout(SBC_LAM_Data* lamData): leaf_index %i\n",leaf_index);fflush(stdout);
	
    while(leaf_index >= 0) {
        leaf_index = readout_card(leaf_index,lamData);
    }


    //-------------------SLT HW specific section--------BEGIN
    uint32_t eventDataId= GetHardwareMask()[0];//this is energy record
    uint32_t waveFormId = GetHardwareMask()[1];
    uint32_t fltEventId = GetHardwareMask()[2];
    uint32_t col        = GetSlot() - 1; //GetSlot() is in fact stationNumber, which goes from 1 to 20 (slots go from 0-20) - for SLT this is always 10 or 2 (mini crate)
    uint32_t crate      = GetCrate();

    uint32_t partOfRunFLTMask = GetDeviceSpecificData()[0];
    uint32_t runFlags   = GetDeviceSpecificData()[3];//this is runFlagsMask of ORKatrinV4FLTModel.m, load_HW_Config_Structure:index:
    uint32_t takeEventData   = runFlags & kTakeEventDataFlag;//this is runFlagsMask of ORKatrinV4FLTModel.m, load_HW_Config_Structure:index:
    
    uint32_t versionSLTFPGA = GetDeviceSpecificData()[7];
    
    uint32_t location   = 0;
    
    if(runFlags & kFirstTimeFlag){// firstTime   
    	location   = ((crate & 0x01e)<<21) | (((col+1) & 0x0000001f)<<16); // | ((filterIndex & 0xf)<<4)  | (filterShapingLength & 0xf)  ;

fprintf(stderr,"OREWSLTv4Readout::Readout(SBC_LAM_Data* lamData): location %i, GetNextTriggerIndex()[0] %i\n",location,GetNextTriggerIndex()[0]);fflush(stderr);
		//make some plausability checks
		//...

		
		runFlags &= ~(kFirstTimeFlag);
        GetDeviceSpecificData()[3]=runFlags;// runFlags is GetDeviceSpecificData()[3], so this clears the 'first time' flag -tb-
		//TODO: better use a local static variable and init it the first time, as changing GetDeviceSpecificData()[3] could be dangerous -tb-
        //debug: 
		fprintf(stdout,"SLT #%i: first cycle\n",col+1);fflush(stdout);
        //debug: //sleep(1);
		return true;
	}



    
    //printf("SLT Readout: slot is %i ...\n",col);
    //usleep(1000000);//dummy
    
    uint32_t eventFifo0, eventFifo1, eventFifo2, eventFifo3, eventFifo4, numPage, triggerAddr;

    uint32_t eventFifoLen      =  pbus->read(SLTEventFIFONumReg);
    //printf("SLT Readout: partOfRunFLTMask is 0x%08x , presentFLTMap is  0x%08x ... eventFifoLen: 0x%08x (%i)  takeEventData: 0x%08x \n",partOfRunFLTMask,presentFLTMap,eventFifoLen,eventFifoLen & 0x7ff, takeEventData);



    if(versionSLTFPGA < kSLTRev20131212_5WordsPerEvent /*is 0x41950242*/) goto readoutWith4WordsPerEvent;//this was with a 4 word event fifo instead of 5 words (missing page and offset)
    
    //Standard version of readout loop:
	//===================================================================================================================
    //data readout loop
    if(takeEventData){
        int n,N=10;
        for(n=0; n<N; n++){
            uint32_t eventFifoStatus      =  pbus->read(SLTEventFIFOStatusReg);
            uint32_t numToRead      =  eventFifoStatus  & 0x7ff;
            if(numToRead<4){
                usleep(10);
                return true;
            }
            uint32_t eventID        =  pbus->read(SLTEventFIFONumReg); //event counter on SLT
            printf("SLT Readout: partOfRunFLTMask is 0x%08x , presentFLTMap is  0x%08x ... eventFifoLen: 0x%08x (%i)\n",partOfRunFLTMask,presentFLTMap,eventFifoLen,numToRead);
            eventFifo0  =  pbus->read(SLTEventFIFOReg);
            eventFifo1  =  pbus->read(SLTEventFIFOReg);
            eventFifo2  =  pbus->read(SLTEventFIFOReg);
            eventFifo3  =  pbus->read(SLTEventFIFOReg);
            eventFifo4  =  pbus->read(SLTEventFIFOReg);
            numPage     =  (eventFifo4 >>12) & 0xf;
            triggerAddr =  eventFifo4 & 0xfff;

            printf("eventFifo0..4:  0x%08x ;  0x%08x ;  0x%08x ;  0x%08x  ;  0x%08x \n", eventFifo0 , eventFifo1 , eventFifo2 , eventFifo3 , eventFifo4 );//TODO: debugging -tb-
            uint32_t flt = (eventFifo1 & 0xff000000) >>24;
            uint32_t fltBit = 0x1 << flt;
            printf("Trigger on FLT idx %i found! ChannelMap:  0x%08x ; energy:  0x%08x  (%i);   & with partOfRun: 0x%08x , & with presentFLTMap is  0x%08x \n",flt, eventFifo2 & 0x3ffff, eventFifo3 & 0xffffff, eventFifo3 & 0xffffff ,fltBit & partOfRunFLTMask,fltBit &presentFLTMap);

            //set the page number on FLT
            pbus->write(FLTReadPageNumReg(flt+1),numPage);
            //usleep(10000);//TODO: this is ugly, but we need to give the FLT time to write the trace!!! change it in the future! -tb-
            usleep(21000);//TODO: this is ugly, but we need to give the FLT time to write the trace!!! change it in the future! -tb-
            
            uint32_t chan,chanBit,chanMap; 
            chanMap=eventFifo2 & 0x3ffff;
            for(chan=0; chan<30; chan++){
                if(chan<18) chanBit=0x1 << chan; else chanBit=0x1 << (chan-18+6);
                if(chanBit & chanMap){//read out according data buffer and ship event
                    printf("    Ship ADC data for FLT#%i (idx %i), Channel (%i)\n",flt+1,flt, chan);
                    //-------------SHIP TRACE----------BEGIN
						        uint32_t wfRecordVersion=0;//length: 4 bit (0..15) 0x1=raw trace, full length
                        wfRecordVersion = 0x2 ;//0x2=always take adcoffset+post trigger time - recommended as default -tb-
                                uint32_t waveformLength = 2048; 
								uint32_t waveformLength32=waveformLength/2; //the waveform length is variable    
/*								
int itmp;
for(itmp=0; itmp<16; itmp++){
//int32_t tmpNumPage=numPage+itmp;
int32_t tmpNumPage=itmp;
if(tmpNumPage<0) tmpNumPage+=16;
if(tmpNumPage>15) tmpNumPage-=16;
pbus->write(FLTReadPageNumReg(flt+1),tmpNumPage);
*/

                                uint32_t address=  FLTRAMDataReg(flt+1, chan)  ;
                                //ensure to wait until FLT has written the trace ...
                                pbus->readBlock(address, (unsigned long *) readbuffer32, waveformLength);//read 2048 word32s
                                //rearrange (could do it later, copiing into ring buffer ...)
                                triggerAddr =  eventFifo4 & 0xfff;
                                {   int i,ioffset=0;
                                    ioffset=triggerAddr+1023;
                                    for(i=0; i<waveformLength; i++,ioffset++){
                                        ioffset = ioffset % 2048;
                                        shipbuffer16[i]=(uint16_t)((uint32_t)(readbuffer32[ioffset] & 0xffff));
                                        shipdebugbuffer16[i]=(uint16_t)((uint32_t)((readbuffer32[ioffset]>>16) & 0xffff));
                                    }
                                }

                                //prepare the record
                                uint32_t eventFlags=0;//append page, append next page  TODO: currently not used <--------------------remove it -tb-
    	                        location   = ((crate & 0x01e)<<21) | (((flt+1) & 0x0000001f)<<16)  | ((chan & 0xff) << 8); // | ((filterIndex & 0xf)<<4)  | (filterShapingLength & 0xf)  ;

                                uint32_t shapingLength=0;
                                if(chan<18)
                                    shapingLength= pbus->read(FLTTriggParReg(flt+1,chan)) & 0xff;

                                //ship data record
                                ensureDataCanHold(9 + waveformLength/2); 
                                data[dataIndex++] = fltEventId | (9 + waveformLength32);    
                                //printf("FLT%i: fltEventId is %i  loc+ev.chan %i\n",col+1,fltEventId,  location | eventchan<<8);
                                data[dataIndex++] = location;
                                data[dataIndex++] = eventFifo0;              //timestamp lo
                                data[dataIndex++] = eventFifo1;// & 0xffff;     //FLT# + timestamp hi
                                data[dataIndex++] = eventFifo2;              //channel map
                                data[dataIndex++] = eventFifo3;  //energy       
                                //data[dataIndex++] = eventID;
                                data[dataIndex++] = eventFifo4;
                                //DEBUG:data[dataIndex++] = debugbuffer[col][eventchan];   //TODO: debug ... energy; for checking page counter I wrote out page counter instead of energy -tb-
                                //      data[dataIndex++] = ((traceStart16 & 0x7ff)<<8) | eventFlags | (wfRecordVersion & 0xf);
                                data[dataIndex++] =  (wfRecordVersion & 0xf);//eventFlags
                                //data[dataIndex++] = ((traceStart16 & 0x7ff)<<8) |  (wfRecordVersion & 0xf);
                                //data[dataIndex++] = 0;    //spare to remain byte compatible with the v3 record
                                data[dataIndex++] = 0;//tmpNumPage; //shapingLength;//0;//postTriggerTime /*for debugging -tb-*/   ;    //spare to remain byte compatible with the v3 record
                                
                                //TODO: SHIP TRIGGER POS and POSTTRIGG time !!! -tb-
                                
                                //ship waveform
                                for(uint32_t i=0;i<waveformLength32;i++){
                                    //TESTING data[dataIndex++] = chan;//adctrace32[col][eventchan][i];
                                    data[dataIndex++] = shipbuffer32[i];
                                }
/*
}                                
pbus->write(FLTReadPageNumReg(flt+1),numPage);
*/

                                uint32_t debugFlag=1;
                                if(debugFlag && (chan>=6) && (chan<=17)){
                                    //ship data record
                                    ensureDataCanHold(9 + waveformLength/2); 
                                    location   = ((crate & 0x01e)<<21) | (((flt+1) & 0x0000001f)<<16)  | (((chan+32) & 0xff) << 8); // | ((filterIndex & 0xf)<<4)  | (filterShapingLength & 0xf)  ;

                                    data[dataIndex++] = fltEventId | (9 + waveformLength32);    
                                    //printf("FLT%i: fltEventId is %i  loc+ev.chan %i\n",col+1,fltEventId,  location | eventchan<<8);
                                    data[dataIndex++] = location;
                                    data[dataIndex++] = eventFifo0;              //timestamp lo
                                    data[dataIndex++] = eventFifo1;// & 0xffff;     //FLT# + timestamp hi
                                    data[dataIndex++] = eventFifo2;              //channel map
                                    data[dataIndex++] = eventFifo3;  //energy       
                                    //data[dataIndex++] = eventID;
                                    data[dataIndex++] = eventFifo4;
                                    //DEBUG:data[dataIndex++] = debugbuffer[col][eventchan];   //TODO: debug ... energy; for checking page counter I wrote out page counter instead of energy -tb-
                                    //      data[dataIndex++] = ((traceStart16 & 0x7ff)<<8) | eventFlags | (wfRecordVersion & 0xf);
                                    data[dataIndex++] =  (wfRecordVersion & 0xf);//eventFlags
                                    //data[dataIndex++] = ((traceStart16 & 0x7ff)<<8) |  (wfRecordVersion & 0xf);
                                    //data[dataIndex++] = 0;    //spare to remain byte compatible with the v3 record
                                    //data[dataIndex++] = shapingLength;//0;//postTriggerTime /*for debugging -tb-*/   ;    //spare to remain byte compatible with the v3 record
                                    data[dataIndex++] = 0;//postTriggerTime /*for debugging -tb-*/   ;    //spare to remain byte compatible with the v3 record
                                    //ship waveform
                                    for(uint32_t i=0;i<waveformLength32;i++){
                                        //TESTING data[dataIndex++] = chan;//adctrace32[col][eventchan][i];
                                        data[dataIndex++] = shipdebugbuffer32[i];
                                    }
                                }
                    
                    
                    
                    
                    
                    //-------------SHIP TRACE----------END
                }
            }


            // for shipping:     //uint32_t eventFifoLen      =  pbus->read(SLTEventFIFONumReg);
            //--->       and set as EVENT ID
        }
        
    }
    //-------------------SLT HW specific section--------END
    
    
 
    return true; 
    
    
    
    
    readoutWith4WordsPerEvent: ;
    //old version of readout loop (used in eg. Tuebingen 2013), before 2013-12-12 -tb-
	//===================================================================================================================
    //data readout loop
    if(takeEventData){
        int n,N=10;
        for(n=0; n<N; n++){
            uint32_t eventFifoStatus      =  pbus->read(SLTEventFIFOStatusReg);
            uint32_t numToRead      =  eventFifoStatus  & 0x7ff;
            if(numToRead<4){
                usleep(10);
                return true;
            }
            uint32_t eventID        =  pbus->read(SLTEventFIFONumReg); //event counter on SLT
            printf("SLT Readout: partOfRunFLTMask is 0x%08x , presentFLTMap is  0x%08x ... eventFifoLen: 0x%08x (%i)\n",partOfRunFLTMask,presentFLTMap,eventFifoLen,numToRead);
            eventFifo0  =  pbus->read(SLTEventFIFOReg);
            eventFifo1  =  pbus->read(SLTEventFIFOReg);
            eventFifo2  =  pbus->read(SLTEventFIFOReg);
            eventFifo3  =  pbus->read(SLTEventFIFOReg);
            /*
            TODO: check depending on the version? -tb-
            eventFifo4  =  pbus->read(SLTEventFIFOReg);
            */
            printf("eventFifo0..3:  0x%08x ;  0x%08x ;  0x%08x ;  0x%08x \n", eventFifo0 , eventFifo1 , eventFifo2 , eventFifo3 );
            uint32_t flt = (eventFifo1 & 0xff000000) >>24;
            uint32_t fltBit = 0x1 << flt;
            printf("Trigger on FLT idx %i found! ChannelMap:  0x%08x ; energy:  0x%08x  (%i);   & with partOfRun: 0x%08x , & with presentFLTMap is  0x%08x \n",flt, eventFifo2 & 0x3ffff, eventFifo3 & 0xffffff, eventFifo3 & 0xffffff ,fltBit & partOfRunFLTMask,fltBit &presentFLTMap);

            uint32_t chan,chanBit,chanMap; 
            chanMap=eventFifo2 & 0x3ffff;
            for(chan=0; chan<30; chan++){
                if(chan<18) chanBit=0x1 << chan; else chanBit=0x1 << (chan-18+6);
                if(chanBit & chanMap){//read out according data buffer and ship event
                    printf("    Ship ADC data for FLT#%i (idx %i), Channel (%i)\n",flt+1,flt, chan);
                    //-------------SHIP TRACE----------BEGIN
						        uint32_t wfRecordVersion=0;//length: 4 bit (0..15) 0x1=raw trace, full length
                        wfRecordVersion = 0x2 ;//0x2=always take adcoffset+post trigger time - recommended as default -tb-
                                uint32_t waveformLength = 2048; 
								uint32_t waveformLength32=waveformLength/2; //the waveform length is variable    
								

                                uint32_t address=  FLTRAMDataReg(flt+1, chan)  ;
                                pbus->readBlock(address, (unsigned long *) readbuffer32, waveformLength);//read 2048 word32s
                                {   int i;
                                    for(i=0; i<waveformLength; i++){
                                        shipbuffer16[i]=(uint16_t)((uint32_t)(readbuffer32[i] & 0xffff));
                                        shipdebugbuffer16[i]=(uint16_t)((uint32_t)((readbuffer32[i]>>16) & 0xffff));
                                    }
                                }

                                //prepare the record
                                uint32_t eventFlags=0;//append page, append next page  TODO: currently not used <--------------------remove it -tb-
    	                        location   = ((crate & 0x01e)<<21) | (((flt+1) & 0x0000001f)<<16)  | ((chan & 0xff) << 8); // | ((filterIndex & 0xf)<<4)  | (filterShapingLength & 0xf)  ;

                                uint32_t shapingLength=0;
                                if(chan<18)
                                    shapingLength= pbus->read(FLTTriggParReg(flt+1,chan)) & 0xff;

                                //ship data record
                                ensureDataCanHold(9 + waveformLength/2); 
                                data[dataIndex++] = fltEventId | (9 + waveformLength32);    
                                //printf("FLT%i: fltEventId is %i  loc+ev.chan %i\n",col+1,fltEventId,  location | eventchan<<8);
                                data[dataIndex++] = location;
                                data[dataIndex++] = eventFifo0;              //timestamp lo
                                data[dataIndex++] = eventFifo1;// & 0xffff;     //FLT# + timestamp hi
                                data[dataIndex++] = eventFifo2;              //channel map
                                data[dataIndex++] = eventFifo3;  //energy       
                                //data[dataIndex++] = energy; changed 2011-06-14 to add fifoEventID -tb-
                                data[dataIndex++] = eventID;
                                //DEBUG:data[dataIndex++] = debugbuffer[col][eventchan];   //TODO: debug ... energy; for checking page counter I wrote out page counter instead of energy -tb-
                                //      data[dataIndex++] = ((traceStart16 & 0x7ff)<<8) | eventFlags | (wfRecordVersion & 0xf);
                                data[dataIndex++] =  (wfRecordVersion & 0xf);//eventFlags
                                //data[dataIndex++] = ((traceStart16 & 0x7ff)<<8) |  (wfRecordVersion & 0xf);
                                //data[dataIndex++] = 0;    //spare to remain byte compatible with the v3 record
                                data[dataIndex++] = shapingLength;//0;//postTriggerTime /*for debugging -tb-*/   ;    //spare to remain byte compatible with the v3 record
                                
                                //TODO: SHIP TRIGGER POS and POSTTRIGG time !!! -tb-
                                
                                //ship waveform
                                for(uint32_t i=0;i<waveformLength32;i++){
                                    //TESTING data[dataIndex++] = chan;//adctrace32[col][eventchan][i];
                                    data[dataIndex++] = shipbuffer32[i];
                                }
                                
                                uint32_t debugFlag=1;
                                if(debugFlag && (chan>=6) && (chan<=17)){
                                    //ship data record
                                    ensureDataCanHold(9 + waveformLength/2); 
                                    location   = ((crate & 0x01e)<<21) | (((flt+1) & 0x0000001f)<<16)  | (((chan+32) & 0xff) << 8); // | ((filterIndex & 0xf)<<4)  | (filterShapingLength & 0xf)  ;

                                    data[dataIndex++] = fltEventId | (9 + waveformLength32);    
                                    //printf("FLT%i: fltEventId is %i  loc+ev.chan %i\n",col+1,fltEventId,  location | eventchan<<8);
                                    data[dataIndex++] = location;
                                    data[dataIndex++] = eventFifo0;              //timestamp lo
                                    data[dataIndex++] = eventFifo1;// & 0xffff;     //FLT# + timestamp hi
                                    data[dataIndex++] = eventFifo2;              //channel map
                                    data[dataIndex++] = eventFifo3;  //energy       
                                    //data[dataIndex++] = energy; changed 2011-06-14 to add fifoEventID -tb-
                                    data[dataIndex++] = eventID;
                                    //DEBUG:data[dataIndex++] = debugbuffer[col][eventchan];   //TODO: debug ... energy; for checking page counter I wrote out page counter instead of energy -tb-
                                    //      data[dataIndex++] = ((traceStart16 & 0x7ff)<<8) | eventFlags | (wfRecordVersion & 0xf);
                                    data[dataIndex++] =  (wfRecordVersion & 0xf);//eventFlags
                                    //data[dataIndex++] = ((traceStart16 & 0x7ff)<<8) |  (wfRecordVersion & 0xf);
                                    //data[dataIndex++] = 0;    //spare to remain byte compatible with the v3 record
                                    //data[dataIndex++] = shapingLength;//0;//postTriggerTime /*for debugging -tb-*/   ;    //spare to remain byte compatible with the v3 record
                                    data[dataIndex++] = 0;//postTriggerTime /*for debugging -tb-*/   ;    //spare to remain byte compatible with the v3 record
                                    //ship waveform
                                    for(uint32_t i=0;i<waveformLength32;i++){
                                        //TESTING data[dataIndex++] = chan;//adctrace32[col][eventchan][i];
                                        data[dataIndex++] = shipdebugbuffer32[i];
                                    }
                                }
                    
                    
                    
                    
                    
                    //-------------SHIP TRACE----------END
                }
            }


            // for shipping:     //uint32_t eventFifoLen      =  pbus->read(SLTEventFIFONumReg);
            //--->       and set as EVENT ID
        }
        
    }
    //-------------------SLT HW specific section--------END
    
    
 
    return true; 
    
    
    
    
}


#else //of #if !PMC_COMPILE_IN_SIMULATION_MODE
// (here follow the 'simulation' versions of all functions -tb-)
//----------------------------------------------------------------

// 'simulation' of hitrate is done in HW_Readout.cc in doReadBlock -tb-

bool ORSLTv4Readout::Readout(SBC_LAM_Data* lamData)
{
#if 1
    //"counter" for debugging/simulation
    static int currentSec=0;
    static int currentUSec=0;
    static int lastSec=0;
    static int lastUSec=0;
    //static long int counter=0;
    static long int secCounter=0;
    
    struct timeval t;//    struct timezone tz; is obsolete ... -tb-
    //timing
    gettimeofday(&t,NULL);
    currentSec = t.tv_sec;  
    currentUSec = t.tv_usec;  
    double diffTime = (double)(currentSec  - lastSec) +
    ((double)(currentUSec - lastUSec)) * 0.000001;
    
    if(diffTime >1.0){
        secCounter++;
        printf("PrPMC (SLTv4 simulation mode) sec %ld: 1 sec is over ...\n",secCounter);
        fflush(stdout);
        //remember for next call
        lastSec      = currentSec; 
        lastUSec     = currentUSec; 
		//Do something here every 1 second. Begin ...
		//
        #if 0 
			uint32_t dataId            = GetHardwareMask()[0];
			uint32_t stationNumber     = GetSlot();
			uint32_t crate             = GetCrate();
			data[dataIndex++] = dataId | 5;
			data[dataIndex++] =  ((stationNumber & 0x0000001f) << 16) | (crate & 0x0f) <<21;
			data[dataIndex++] = 6;
			data[dataIndex++] = 8;
			data[dataIndex++] = 15;
        #endif
		//... End.
    }else{
        // skip shipping data record
        // obsolete ... return config->card_info[index].next_Card_Index;
        // obsolete, too ... return GetNextCardIndex();
    }
#endif
	//loop over FLTs
    int32_t leaf_index;
    //read out the children flts that are in the readout list
    leaf_index = GetNextTriggerIndex()[0];
    while(leaf_index >= 0) {
        leaf_index = readout_card(leaf_index,lamData);
        //printf("PrPMC (SLTv4 simulation mode) leaf_index %ld  ...\n",leaf_index);
        //fflush(stdout);
    }
    
    
#if 0
    //old uint32_t dataId            = config->card_info[index].hw_mask[0];
    //old uint32_t stationNumber     = config->card_info[index].slot;
    //old uint32_t crate             = config->card_info[index].crate;
	//new
    uint32_t dataId            = GetHardwareMask()[0];
    uint32_t stationNumber     = GetSlot();
    uint32_t crate             = GetCrate();
    data[dataIndex++] = dataId | 5;
    data[dataIndex++] =  ((stationNumber & 0x0000001f) << 16) | (crate & 0x0f) <<21;
    data[dataIndex++] = 6;
    data[dataIndex++] = 8;
    data[dataIndex++] = 15;
#endif
 
    return true; 
}




#endif //of #if !PMC_COMPILE_IN_SIMULATION_MODE ... #else ...
//----------------------------------------------------------------



