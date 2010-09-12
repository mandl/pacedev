//`include "timescale.v"
`include "SD_defines.v"
`define tTLH 10 //Clock rise time
`define tHL 10 //Clock fall time
`define tISU 6 //Input setup time
`define tIH 0 //Input hold time
`define tODL 14 //Output delay
`define DLY_TO_OUTP 47 

`define BLOCKSIZE 512
`define MEMSIZE 2048 // 4 block
`define BLOCK_BUFFER_SIZE 1
`define TIME_BUSY 64

`define PRG 7
`define RCV 6
`define DATAS 5
`define TRAN 4
module sdModel(
  input sdClk,
  inout cmd,
  inout [3:0] dat
  
);

//tri cmd;
//tri [3:0] dat

reg oeCmd;
reg oeDat;
reg cmdOut;
reg [3:0] datOut;
reg [10:0] transf_cnt;

    

reg [5:0] lastCMD;
reg cardIdentificationState;
reg CardTransferActive;
reg [2:0] BusWidth;

assign cmd = oeCmd ? cmdOut : 1'bz;
assign dat = oeDat ? datOut : 4'bz;

reg InbuffStatus;
reg [31:0] BlockAddr;
reg [7:0] Inbuff [0:511];
reg [7:0] FLASHmem [0:`MEMSIZE];


reg [46:0]inCmd;
reg [5:0]cmdRead;
reg [7:0] cmdWrite;
reg crcIn;
reg crcEn;
reg crcRst;
reg [31:0] CardStatus;
reg [15:0] RCA;
reg [31:0] OCR;
reg [120:0] CID;
reg Busy; //0 when busy
wire [6:0] crcOut;
reg [4:0] crc_c;

reg [3:0] CurrentState; 
reg [3:0] DataCurrentState; 
`define RCASTART 16'h20
`define OCRSTART 32'hff8000
`define STATUSSTART 32'h0
`define CIDSTART 128'h00ffffffddddddddaaaaaaaa99999999  //Just some random data not really usefull anyway 

`define outDelay 4 
reg [2:0] outDelayCnt;
reg [9:0] flash_write_cnt;
reg [8:0] flash_blockwrite_cnt;

parameter SIZE = 10;
parameter CONTENT_SIZE = 40;
parameter 
    IDLE   =  10'b0000_0000_01,
    READ_CMD   =  10'b0000_0000_10,
    ANALYZE_CMD	    =  10'b0000_0001_00,
    SEND_CMD	    =  10'b0000_0010_00;
reg [SIZE-1:0] state;
reg [SIZE-1:0] next_state;

parameter 
    DATA_IDLE   =10'b0000_0000_01,    
    READ_WAITS  =10'b0000_0000_10,
    READ_DATA  = 10'b0000_0001_00,
    WRITE_FLASH =10'b0000_0010_00,
    WRITE_DATA  =10'b0000_0100_00;
parameter okcrctoken = 4'b0101;
parameter invalidcrctoken = 4'b1111;
reg [SIZE-1:0] dataState;
reg [SIZE-1:0] next_datastate;

reg ValidCmd;
reg inValidCmd;

reg [7:0] response_S;
reg [135:0] response_CMD;
integer responseType;

     reg [9:0] block_cnt;
     reg wptr;
     reg crc_ok;
     reg [3:0] last_din;
     


reg crcDat_rst;
reg crcDat_en;
reg [3:0] crcDat_in; 
wire [15:0] crcDat_out [3:0];

genvar i;
generate
for(i=0; i<4; i=i+1) begin:CRC_16_gen
  SD_CRC_16 CRC_16_i (crcDat_in[i],crcDat_en, sdClk, crcDat_rst, crcDat_out[i]);
end
endgenerate  
SD_CRC_7 CRC_7( 
crcIn,
crcEn,
sdClk,
crcRst,
crcOut);


reg appendCrc;
reg [5:0] startUppCnt;

reg q_start_bit;
//Card initinCMd
initial $readmemh("FLASH.txt",FLASHmem);

integer k;
initial begin
	$display("Contents of Mem after reading data file:");
	for (k=0; k<10; k=k+1) $display("%d:%h",k,FLASHmem[k]);
end
reg qCmd; 
reg [2:0] crcCnt;
initial begin 
  cardIdentificationState<=1;
  state<=IDLE;
  dataState<=DATA_IDLE;
  Busy<=0;
  oeCmd<=0;
  crcCnt<=0;
  CardTransferActive<=0;
  qCmd<=1;
  oeDat<=0;
  cmdOut<=0;
  cmdWrite<=0;  
  InbuffStatus<=0;
  datOut<=0;
  inCmd<=0;
  BusWidth<=1;
  responseType=0;
  crcIn<=0;
  response_S<=0;
  crcEn<=0;
  crcRst<=0;
  cmdRead<=0;
  ValidCmd<=0;
  inValidCmd=0;
  appendCrc<=0;
  RCA<= `RCASTART;
  OCR<= `OCRSTART;
  CardStatus <= `STATUSSTART;
  CID<=`CIDSTART;
  response_CMD<=0;
  outDelayCnt<=0;
  crcDat_rst<=1;
  crcDat_en<=0;
  crcDat_in<=0; 
  transf_cnt<=0;
  BlockAddr<=0;
  block_cnt <=0;     
  wptr<=0;
  transf_cnt<=0;
  crcDat_rst<=1;
  crcDat_en<=0;
  crcDat_in<=0; 
  flash_write_cnt<=0;
  flash_blockwrite_cnt<=0;
end

//CARD logic

always @ (state or cmd or cmdRead or ValidCmd or inValidCmd or cmdWrite or outDelayCnt)
begin : FSM_COMBO
 next_state  = 0;   
case(state)  
IDLE: begin
   if (!cmd) 
     next_state = READ_CMD;
  else
     next_state = IDLE; 
end  
READ_CMD: begin
  if (cmdRead>= 47) 
     next_state = ANALYZE_CMD;
  else
     next_state =  READ_CMD; 
 end
 ANALYZE_CMD: begin
  if ((ValidCmd  )   && (outDelayCnt >= `outDelay ))
     next_state = SEND_CMD;
  else if (inValidCmd)
     next_state =  IDLE; 
 else
    next_state =  ANALYZE_CMD; 
 end 
 SEND_CMD: begin
    if (cmdWrite>= response_S) 
     next_state = IDLE;
  else
     next_state =  SEND_CMD; 
 
 end
 
 
 endcase
end

always @ (dataState or CardStatus or crc_c or flash_write_cnt or dat[0] )
begin : FSM_COMBODAT
 next_datastate  = 0;   
case(dataState)  
 DATA_IDLE: begin
   if (CardStatus[12:9]==`RCV ) 
     next_datastate = READ_WAITS;
   else if (CardStatus[12:9]==`DATAS ) 
     next_datastate = WRITE_DATA;
   else
     next_datastate = DATA_IDLE; 
 end  
  
 READ_WAITS: begin
   if ( dat[0] == 1'b0 ) 
     next_datastate =  READ_DATA;
   else
     next_datastate =  READ_WAITS; 
 end
 
 READ_DATA : begin  
  if (crc_c==0  ) 
     next_datastate =  WRITE_FLASH;
  else
     next_datastate =  READ_DATA;
 end
  WRITE_FLASH : begin
  if (flash_write_cnt>265 ) 
     next_datastate =  DATA_IDLE;
  else
     next_datastate =  WRITE_FLASH;
end  
  WRITE_DATA : begin   
    if (transf_cnt >= `BIT_BLOCK) 
       next_datastate= DATA_IDLE;  
    else 
       next_datastate=WRITE_DATA;   
  end

 
 
 
 
 endcase
end

always @ (posedge sdClk  )
 begin 
  
    q_start_bit <= dat[0];
 end

always @ (posedge sdClk  )
begin : FSM_SEQ
    state <= next_state; 
end

always @ (posedge sdClk  )
begin : FSM_SEQDAT
    dataState <= next_datastate; 
end



always @ (posedge sdClk) begin
if (CardTransferActive) begin
 if (InbuffStatus==0) //empty
   CardStatus[8]<=1;
  else
   CardStatus[8]<=0;
  end
else 
  CardStatus[8]<=0;
     
 startUppCnt<=startUppCnt+1;
 OCR[31]<=Busy;
 if (startUppCnt == `TIME_BUSY)
   Busy <=1;   
end


always @ (posedge sdClk) begin
   qCmd<=cmd;
end

//read data and cmd on rising edge
always @ (posedge sdClk) begin
 case(state)
   IDLE: begin
      
      crcIn<=0;
      crcEn<=0;
      crcRst<=1;
      oeCmd<=0;
     
      cmdRead<=0;
      appendCrc<=0;
      ValidCmd<=0;
      inValidCmd=0;
      cmdWrite<=0;
      crcCnt<=0;
      response_CMD<=0;
      response_S<=0;
      outDelayCnt<=0;
      responseType=0;      
    end
   READ_CMD: begin //read cmd
      crcEn<=1;
      crcRst<=0;
      crcIn <= #`tIH qCmd; 
      inCmd[47-cmdRead]  <= #`tIH qCmd;    
      cmdRead <= #1 cmdRead+1;
      if (cmdRead >= 40) 
         crcEn<=0;
         
      if (cmdRead == 46) begin
          oeCmd<=1;
     cmdOut<=1;
      end
   end 
        
   ANALYZE_CMD: begin//check for valid cmd
   //Wrong CRC go idle
    if (inCmd[46] == 0) //start
      inValidCmd=1;
    else if (inCmd[7:1] != crcOut) begin
      inValidCmd=1;
      $fdisplay(sdModel_file_desc, "**sd_Model Commando CRC Error") ;
      $display(sdModel_file_desc, "**sd_Model Commando CRC Error") ;
    end  
    else if  (inCmd[0] != 1)  begin//stop 
      inValidCmd=1;
      $fdisplay(sdModel_file_desc, "**sd_Model Commando No Stop Bit Error") ;
      $display(sdModel_file_desc, "**sd_Model Commando No Stop Bit Error") ;
    end  
    else begin
      if(outDelayCnt ==0)
        CardStatus[3]<=0;
      case(inCmd[45:40])
        0 : response_S <= 0;
        2 : response_S <= 136;
        3 : response_S <= 48;
        7 : response_S <= 48;
        8 : response_S <= 0;
        14 : response_S <= 0;
        16 : response_S <= 48;
        17 : response_S <= 48;
        24 : response_S <= 48;
        33 : response_S <= 48;
        55 : response_S <= 48;
        41 : response_S <= 48;        
    endcase
         case(inCmd[45:40])
        0 : begin 
            response_CMD <= 0;
            cardIdentificationState<=1;
            ResetCard;
        end    
        2 : begin
         if (lastCMD != 41 && outDelayCnt==0) begin
               $fdisplay(sdModel_file_desc, "**Error in sequnce, ACMD 41 should precede 2 in Startup state") ;
               $display(sdModel_file_desc, "**Error in sequnce, ACMD 41 should precede 2 in Startup state") ;
               CardStatus[3]<=1;
            end  
        response_CMD[127:8] <= CID;
        appendCrc<=0; 
        CardStatus[12:9] <=2;
        end
        3 :  begin 
           if (lastCMD != 2 && outDelayCnt==0 ) begin
               $fdisplay(sdModel_file_desc, "**Error in sequnce, CMD 2 should precede 3 in Startup state") ;
               $display(sdModel_file_desc, "**Error in sequnce, CMD 2 should precede 3 in Startup state") ;
               CardStatus[3]<=1;
            end  
        response_CMD[127:112] <= RCA[15:0] ;
        response_CMD[111:96] <= CardStatus[15:0] ;
        appendCrc<=1;
        CardStatus[12:9] <=3;
        cardIdentificationState<=0;
       end
        6 : begin         
           if (lastCMD == 55 && outDelayCnt==0) begin             
              if (inCmd[9:8] == 2'b10) begin
               BusWidth <=4;      
                    $display(sdModel_file_desc, "**BUS WIDTH 4 ") ;
               end      
              else
               BusWidth <=1;               
              
              response_S<=48;
              response_CMD[127:96] <= CardStatus; 
           end   
           else if (outDelayCnt==0)begin
             response_CMD <= 0;
             response_S<=0;
             $fdisplay(sdModel_file_desc, "**Error Invalid CMD, %h",inCmd[45:40]) ;
             $display(sdModel_file_desc, "**Error Invalid CMD, %h",inCmd[45:40]) ;
            end
        end   
        7: begin
         if (outDelayCnt==0) begin 
          if (inCmd[39:24]== RCA[15:0]) begin
              CardTransferActive <= 1;
              response_CMD[127:96] <= CardStatus ; 
              CardStatus[12:9] <=`TRAN;                            
          end
          else begin
               CardTransferActive <= 0;
               response_CMD[127:96] <= CardStatus ; 
               CardStatus[12:9] <=3;  
          end          
         end        
        end      
        8 : response_CMD[127:96] <= 0; //V1.0 card
        16 : begin
          response_CMD[127:96] <= CardStatus ;         
                
        end 
        17 :  begin
          if (outDelayCnt==0) begin 
            if (CardStatus[12:9] == `TRAN) begin //If card is in transferstate                               
                CardStatus[12:9] <=`DATAS;//Put card in data state
                response_CMD[127:96] <= CardStatus ;
                BlockAddr = inCmd[39:8];
                if (BlockAddr%512 !=0)
                  $display("**Block Misalign Error");         
          end
           else begin
             response_S <= 0;
             response_CMD[127:96] <= 0; 
           end
         end
    
       end 
        
        24 : begin
          if (outDelayCnt==0) begin 
            if (CardStatus[12:9] == `TRAN) begin //If card is in transferstate
              if (CardStatus[8]) begin //If Free write buffer           
                CardStatus[12:9] <=`RCV;//Put card in Rcv state
                response_CMD[127:96] <= CardStatus ;
                BlockAddr = inCmd[39:8];
                if (BlockAddr%512 !=0)
                  $display("**Block Misalign Error");
              end
              else begin
                response_CMD[127:96] <= CardStatus;
                 $fdisplay(sdModel_file_desc, "**Error Try to blockwrite when No Free Writebuffer") ;
                 $display("**Error Try to blockwrite when No Free Writebuffer") ;
             end
           end
           else begin
             response_S <= 0;
             response_CMD[127:96] <= 0; 
           end
         end
    
       end 
        33 : response_CMD[127:96] <= 48;
        55 : 
        begin
          response_CMD[127:96] <= CardStatus ;         
          CardStatus[5] <=1;      //Next CMD is AP specific CMD
          appendCrc<=1;         
        end 
        41 : 
        begin  
         if (cardIdentificationState) begin
            if (lastCMD != 55 && outDelayCnt==0) begin
               $fdisplay(sdModel_file_desc, "**Error in sequnce, CMD 55 should precede 41 in Startup state") ;
               $display( "**Error in sequnce, CMD 55 should precede 41 in Startup state") ;
               CardStatus[3]<=1;
            end
            else begin
             responseType=3; 
             response_CMD[127:96] <= OCR;   
             appendCrc<=0;
             CardStatus[5] <=0;  
            if (Busy==1)
              CardStatus[12:9] <=1;
           end 
        end    
       end   
        
    endcase
     ValidCmd<=1;  
     crcIn<=0;
     
     outDelayCnt<=outDelayCnt+1;
     if (outDelayCnt==`outDelay)       
       crcRst<=1;
     oeCmd<=1;
     cmdOut<=1;
     response_CMD[135:134] <=0;
    
    if (responseType != 3)
       response_CMD[133:128] <=inCmd[45:40];
    if (responseType == 3)
       response_CMD[133:128] <=6'b111111;
       
     lastCMD <=inCmd[45:40];
    end
   end
   
   
   
 endcase    
end 

always @ ( negedge sdClk) begin
 case(state)

SEND_CMD: begin
     crcRst<=0;
     crcEn<=1;
    cmdWrite<=cmdWrite+1;    
    if (response_S!=0)
     cmdOut<=0;   
   else
      cmdOut<=1;  
       
    if ((cmdWrite>0) &&  (cmdWrite < response_S-8)) begin
      cmdOut<=response_CMD[135-cmdWrite];
      crcIn<=response_CMD[134-cmdWrite];
      if (cmdWrite >= response_S-9)
       crcEn<=0;
    end
   else if (cmdWrite!=0) begin
     crcEn<=0;
     cmdOut<=crcOut[6-crcCnt];
     crcCnt<=crcCnt+1; 
      if (responseType == 3)
           cmdOut<=1;
   end
  if (cmdWrite == response_S-1)
    cmdOut<=1;
     
  end
 endcase
end



integer outdly_cnt;







always @ (posedge sdClk) begin
  
  case (dataState)
  DATA_IDLE: begin
      
  end
  
  READ_WAITS: begin
      oeDat<=0;
      crcDat_rst<=0;
      crcDat_en<=1;
      crcDat_in<=0; 
      crc_c<=15;//
      crc_ok<=1;      
  end       
  READ_DATA: begin
  
     
    InbuffStatus<=1;
    if (transf_cnt<`BIT_BLOCK_REC) begin
       if (wptr)
         Inbuff[block_cnt][7:4] <= dat;
       else
          Inbuff[block_cnt][3:0] <= dat;       
      
       crcDat_in<=dat;
       crc_ok<=1;
       transf_cnt<=transf_cnt+1; 
       if (wptr)
         block_cnt<=block_cnt+1;     
       wptr<=~wptr;
       
       
    end
    else if  ( transf_cnt <= (`BIT_BLOCK_REC +`BIT_CRC_CYCLE-1)) begin
       transf_cnt<=transf_cnt+1; 
       crcDat_en<=0;  
       last_din <=dat; 
       
       if (transf_cnt> `BIT_BLOCK_REC) begin       
        crc_c<=crc_c-1;
                                
          if (crcDat_out[0][crc_c] != last_din[0])
           crc_ok<=0;
          if  (crcDat_out[1][crc_c] != last_din[1])
           crc_ok<=0;
          if  (crcDat_out[2][crc_c] != last_din[2])
           crc_ok<=0;
          if  (crcDat_out[3][crc_c] != last_din[3])
           crc_ok<=0;         
      end                 
    end 
  end 
  WRITE_FLASH: begin
     oeDat<=1;
     block_cnt <=0;     
     wptr<=0;
     transf_cnt<=0;
     crcDat_rst<=1;
     crcDat_en<=0;
     crcDat_in<=0; 
     
    
  end  
      
  endcase
  
  
end



reg data_send_index;
integer write_out_index;
always @ (negedge sdClk) begin
  
  case (dataState)
  DATA_IDLE: begin
     write_out_index<=0;
     transf_cnt<=0;
     data_send_index<=0; 
     outdly_cnt<=0;
     
  end
  
  
   WRITE_DATA: begin
      oeDat<=1;
      outdly_cnt<=outdly_cnt+1;
     
      if ( outdly_cnt > `DLY_TO_OUTP) begin
         transf_cnt <= transf_cnt+1;
         crcDat_en<=1;
         crcDat_rst<=0;
         
      end   
      else begin
        crcDat_en<=0;
        crcDat_rst<=1;          
        oeDat<=1;   
        crc_c<=16; 
     end   
      
       if (transf_cnt==1) begin  
               
          last_din <= FLASHmem[BlockAddr+(write_out_index)][7:4];           
          datOut<=0;
          crcDat_in<= FLASHmem[BlockAddr+(write_out_index)][7:4];  
          data_send_index<=1;    
        end
        else if ( (transf_cnt>=2) && (transf_cnt<=`BIT_BLOCK-`CRC_OFF )) begin                 
          data_send_index<=~data_send_index;
          if (!data_send_index) begin
             last_din<=FLASHmem[BlockAddr+(write_out_index)][7:4];
             crcDat_in<= FLASHmem[BlockAddr+(write_out_index)][7:4];
          end
          else begin
             last_din<=FLASHmem[BlockAddr+(write_out_index)][3:0];
             crcDat_in<= FLASHmem[BlockAddr+(write_out_index)][3:0];
             write_out_index<=write_out_index+1;
         end       
                                
          datOut<= last_din; 
                      
                    
          if ( transf_cnt >=`BIT_BLOCK-`CRC_OFF ) begin
             crcDat_en<=0;             
         end
         
       end
       else if (transf_cnt>`BIT_BLOCK-`CRC_OFF & crc_c!=0) begin
         datOut<= last_din; 
         crcDat_en<=0;
         crc_c<=crc_c-1; 
         if (crc_c<= 16) begin         
         datOut[0]<=crcDat_out[0][crc_c-1];
         datOut[1]<=crcDat_out[1][crc_c-1];
         datOut[2]<=crcDat_out[2][crc_c-1];
         datOut[3]<=crcDat_out[3][crc_c-1];       
       end  
       end
       else if (transf_cnt==`BIT_BLOCK-2) begin     
          datOut<=4'b1111;          
      end   
       else if ((transf_cnt !=0) && (crc_c == 0 ))begin
         oeDat<=0; 
         CardStatus[12:9] <= `TRAN;
         end
      
      
      
  end
  
  
  
  WRITE_FLASH: begin
    flash_write_cnt<=flash_write_cnt+1;
     CardStatus[12:9] <= `PRG;
      datOut[0]<=0;
       datOut[1]<=1;
       datOut[2]<=1;
       datOut[3]<=1;
    if (flash_write_cnt == 0)
      datOut<=1;
    else if(flash_write_cnt == 1)
     datOut[0]<=1;
    else if(flash_write_cnt == 2)
     datOut[0]<=0;
      
     
    else if ((flash_write_cnt > 2) && (flash_write_cnt < 7)) begin
      if (crc_ok) 
        datOut[0] <=okcrctoken[6-flash_write_cnt];
      else
        datOut[0] <= invalidcrctoken[6-flash_write_cnt];
    end
    else if  ((flash_write_cnt >= 7) && (flash_write_cnt < 264)) begin
       datOut[0]<=0;
      
      flash_blockwrite_cnt<=flash_blockwrite_cnt+2;
       FLASHmem[BlockAddr+(flash_blockwrite_cnt)]<=Inbuff[flash_blockwrite_cnt];
       FLASHmem[BlockAddr+(flash_blockwrite_cnt+1)]<=Inbuff[flash_blockwrite_cnt+1];
    end
    else begin
      datOut<=1;      
      InbuffStatus<=0;
      CardStatus[12:9] <= `TRAN;
    end  
  end
endcase
end

integer sdModel_file_desc;

initial
begin
  sdModel_file_desc = $fopen("log/sd_model.log");
  if (sdModel_file_desc < 2)
  begin
    $display("*E Could not open/create testbench log file in /log/ directory!");
    $finish;
  end
end

task ResetCard; //  MAC registers
begin
 cardIdentificationState<=1;
  state<=IDLE;
  dataState<=DATA_IDLE;
  Busy<=0;
  oeCmd<=0;
  crcCnt<=0;
  CardTransferActive<=0;
  qCmd<=1;
  oeDat<=0;
  cmdOut<=0;
  cmdWrite<=0;
  
  InbuffStatus<=0;
  datOut<=0;
  inCmd<=0;
  BusWidth<=1;
  responseType=0;
  crcIn<=0;
  response_S<=0;
  crcEn<=0;
  crcRst<=0;
  cmdRead<=0;
  ValidCmd<=0;
  inValidCmd=0;
  appendCrc<=0;
  RCA<= `RCASTART;
  OCR<= `OCRSTART;
  CardStatus <= `STATUSSTART;
  CID<=`CIDSTART;
  response_CMD<=0;
  outDelayCnt<=0;
  crcDat_rst<=1;
  crcDat_en<=0;
  crcDat_in<=0; 
  transf_cnt<=0;
  BlockAddr<=0;
  block_cnt <=0;     
     wptr<=0;
     transf_cnt<=0;
     crcDat_rst<=1;
     crcDat_en<=0;
     crcDat_in<=0; 
flash_write_cnt<=0;
flash_blockwrite_cnt<=0;
end
endtask  
  

endmodule