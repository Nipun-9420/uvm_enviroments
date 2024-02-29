    /*
    in this code i am making 1 src agent and 3 dst agent and seting 4 diffrent values to each agnet throusg config agent

    */




    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><<><><><><><<><><><><><><><>
    //INTERFACE
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><<><><><><><<><><><><><><><

    interface router_if(input bit clk);

        logic [7:0 ]data_in;
        logic pkt_valid;
        logic resetn;
        logic err,busy;
        logic read_enb;
        logic [7:0] data_out;
        logic vld_out;

        clocking s_dr_cb@(posedge clk);
        default input#1 output  #1;
            input busy;
            output pkt_valid;
            output  data_in;
            output resetn;
        endclocking

        clocking s_mon_cb@(posedge clk);
        default input#1 output  #1;
            input pkt_valid;
            input  data_in;
            input resetn;
            input busy;
        endclocking

        clocking d_mon_cb@(posedge clk);
        default input#1 output  #1;
            input  data_out;
            input read_enb;
        endclocking

        clocking d_dr_cb@(posedge clk);
        default input#1 output  #1;
            input vld_out;
            output read_enb;
        endclocking


        modport S_DR_MP(clocking s_dr_cb);
        modport S_MON_MP(clocking s_mon_cb);
        modport D_MON_MP(clocking d_mon_cb);
        modport D_DR_MP(clocking d_dr_cb);

        endinterface


    



    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><<><><><><><<><><><><><><><>
    //RTL
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><<><><><><><<><><><><><><><>
    
    
    //:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    //                          FSM
    //:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

    module router_fsm (clock,resetn,pkt_valid,busy,parity_done,data_in,soft_reset_0,
        soft_reset_1,soft_reset_2,fifo_full,lfd_state,rst_int_reg,write_enb_reg,full_state,
        laf_state,ld_state,detect_add,fifo_empty_2,fifo_empty_1,fifo_empty_0,low_pkt_valid);
        
        input clock,resetn,pkt_valid,fifo_empty_0,fifo_empty_1,fifo_empty_2,fifo_full,
        soft_reset_0,soft_reset_1,soft_reset_2,parity_done,low_pkt_valid;
        input [1:0] data_in;
        output busy;   //----------------------------------------------------------------------output
        output lfd_state,rst_int_reg,write_enb_reg,full_state,laf_state,ld_state,detect_add; //----output
        reg [1:0] temp1;
        parameter DECODE_ADDRESS       = 3'b000,
                  WAIT_TILL_EMPTY      = 3'b001,
                  LOAD_FIRST_DATA      = 3'b010,
                  LOAD_DATA            = 3'b011,
                  LOAD_PARITY          = 3'b100,
                  FIFO_FULL_STATE      = 3'b101,
                  LOAD_AFTER_FULL      = 3'b110,
                  CHECK_PARITY_ERROR   = 3'b111;
        reg [2:0] state,next_state;
        
        //**********************************to save input data into temp variable
        always @(posedge clock) 
        begin
          if (detect_add) 
          begin
            temp1<=data_in;
          end
        end
        
        //****************************************************tell how to handel reset
        always @(posedge clock) 
        begin
          if (~resetn) 
            state <= DECODE_ADDRESS;
          else if (soft_reset_0 && (temp1 == 2'b00))
            state <= DECODE_ADDRESS; 
          else if (soft_reset_1 && (temp1 == 2'b01))
            state <= DECODE_ADDRESS; 
          else if (soft_reset_2 && (temp1 == 2'b10))
            state <= DECODE_ADDRESS; 
          else
          state <= next_state;
        end
        //**************************************************************MAIN FSM
        always @(*) 
        begin
           next_state= DECODE_ADDRESS;
            case (state)
              DECODE_ADDRESS:
                  begin
                    if((pkt_valid && (data_in[1:0]==0) && fifo_empty_0) || 
                       (pkt_valid && (data_in[1:0]==1) && fifo_empty_1) || 
                       (pkt_valid && (data_in[1:0]==2) && fifo_empty_2))
                        
                          next_state=LOAD_FIRST_DATA;
        
                    else if((pkt_valid && (data_in[1:0]==0) && (~fifo_empty_0))||
                            (pkt_valid && (data_in[1:0]==1) && (~fifo_empty_1))||
                            (pkt_valid && (data_in[1:0]==2) && (~fifo_empty_2)))
                      
                      next_state=WAIT_TILL_EMPTY;
        
                    else
                      next_state = DECODE_ADDRESS;
                  end 
        
              WAIT_TILL_EMPTY:
                  begin
                    if((!fifo_empty_0) || (!fifo_empty_1) || (!fifo_empty_2))
                      next_state=WAIT_TILL_EMPTY;
                    else if(fifo_empty_0||fifo_empty_1||fifo_empty_2)
                      next_state=LOAD_FIRST_DATA;
                    else
                      next_state=WAIT_TILL_EMPTY;
                  end
                  
        
              LOAD_FIRST_DATA:
                  begin
                    next_state=LOAD_DATA;
                  end
              LOAD_DATA:
                  begin
                    if(fifo_full)
                      next_state = FIFO_FULL_STATE;
                     else if(!fifo_full && !pkt_valid)
                      next_state = LOAD_PARITY;
                    else
                      next_state = LOAD_DATA;
                  end
              LOAD_PARITY:
                  begin
                    next_state = CHECK_PARITY_ERROR;
                  end
              FIFO_FULL_STATE:
                  begin
                    if(!fifo_full)
                      next_state = LOAD_AFTER_FULL;
                    else 
                      next_state = FIFO_FULL_STATE;
                  end
              LOAD_AFTER_FULL:
                  begin
                    if((!parity_done) && (!low_pkt_valid))
                      next_state = LOAD_DATA;
                    else if((!parity_done) && (low_pkt_valid))
                      next_state = LOAD_PARITY;
                    else if(parity_done)
                    next_state = DECODE_ADDRESS;
                  end
              CHECK_PARITY_ERROR:
                  begin
                    if(fifo_full)
                      next_state =FIFO_FULL_STATE ;
                    else 
                      next_state = DECODE_ADDRESS;
                  end
            endcase  
        end
        
         assign detect_add = ((state==DECODE_ADDRESS)?1:0); 
          assign write_enb_reg=((state==LOAD_DATA||state==LOAD_PARITY||state==LOAD_AFTER_FULL)?1:0);
          assign full_state=((state==FIFO_FULL_STATE)?1:0);
          assign lfd_state=((state==LOAD_FIRST_DATA)?1:0);
          assign busy=((state==FIFO_FULL_STATE||state==LOAD_AFTER_FULL||state==WAIT_TILL_EMPTY||state==LOAD_FIRST_DATA||state==LOAD_PARITY||state==CHECK_PARITY_ERROR)?1:0);
          assign ld_state=((state==LOAD_DATA)?1:0);
          assign laf_state=((state==LOAD_AFTER_FULL)?1:0);
          assign rst_int_reg=((state==CHECK_PARITY_ERROR)?1:0);
        
        endmodule
        
        










    //:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    //                          SYNCHORINISER SYNC
    //:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

    module router_sync(dect_add,data_in,write_enb_reg,clock,resetn,vld_out_0,vld_out_1,
        vld_out_2,read_enb_0,read_enb_1,read_enb_2,full_2,full_1,full_0,soft_reset_2,soft_reset_1,
        soft_reset_0,empty_2,empty_1,empty_0,fifo_full,write_enb);
        
        input dect_add,write_enb_reg,clock,resetn,read_enb_0,read_enb_1,read_enb_2,full_0,full_1,full_2,empty_0,empty_1,empty_2;
        
        output reg fifo_full,soft_reset_0,soft_reset_1,soft_reset_2;
        input [1:0] data_in;
        output reg[2:0] write_enb;
        output vld_out_0,vld_out_1,vld_out_2;
        
        //************************************************************************TEMP VER TO STORE DATA
        reg [1:0] data_in_t;
        reg[4:0]count0,count1,count2;
        
        always @(posedge clock) 
        begin
        if(!resetn)
        data_in_t <=0;
        else if (dect_add)
        data_in_t <= data_in;   
        end
        
        //************************************************************************TEMP VER TO STORE DATA
        always @(*) 
        begin
            case (data_in_t)
                2'b00:
                begin
                        fifo_full <=full_0;
                    if(write_enb_reg)
                        write_enb <= 3'b001;
                    else    
                        write_enb <= 3'b000;
                end
                2'b01:
                begin
                        fifo_full <= full_1;
                    if(write_enb_reg)
                        write_enb <= 3'b010;
                    else    
                        write_enb <= 3'b000;
                end
                2'b10:
                begin
                    fifo_full =full_2;
                    if(write_enb_reg)
                        write_enb <= 3'b100;
                    else    
                        write_enb <= 3'b000;
                end
                default: 
                begin
                    fifo_full <= 0;
                    write_enb<= 3'b000;
                end
            endcase    
        end
        
        //************************************************************************soft_reset_1
        always @(posedge clock) 
            begin
                if (!resetn)
                begin
                    count0        <= 0;
                    soft_reset_0  <= 0;
                end
                else if (vld_out_0)
                begin
                    if (~read_enb_0)
                    begin
                        if(count0==29)
                            begin
                                soft_reset_0   <=1'b1;
                                count0         <=0;
                            end
                        else
                            begin
                                soft_reset_0    <=1'b0;
                                count0          <=count0+1'b1;
                            end
                    end
                    else
                    count0  <=0;
                end
            end
        
        //************************************************************************soft_reset_1
        always @(posedge clock) 
            begin
                if (!resetn)
                begin
                    count1        <= 0;
                    soft_reset_1  <= 0;
                end
                else if (vld_out_1)
                begin
                    if (~read_enb_1)
                    begin
                        if(count1 ==29)
                            begin
                                soft_reset_1    <=1'b1;
                                count1          <=0;
                            end
                        else
                            begin
                                soft_reset_1    <=1'b0;
                                count1          <=count1 +1'b1;
                            end
                    end
                    else
                    count1  <=0;
                end
            end
        
        //************************************************************************soft_reset_2
        always @(posedge clock) 
            begin
                if (!resetn)
                begin
                    count2        <= 0;
                    soft_reset_2  <= 0;
                end
                else if (vld_out_2)
                begin
                    if (~read_enb_2)
                    begin
                        if(count2 ==29)
                            begin
                                soft_reset_2    <=1'b1;
                                count2          <=0;
                            end
                        else
                            begin
                                soft_reset_2    <=1'b0;
                                count2          <=count2 +1'b1;
                            end
                    end
                    else
                    count2  <=0;
                end
            end
            
        //************************************************************************vld_out_logic
        assign vld_out_0 = (~empty_0);
        assign vld_out_1 = (~empty_1);
        assign vld_out_2 = (~empty_2);
        
        endmodule
        

        









    //:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    //                          RESISTER
    //:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


    module router_reg(clock,resetn,pkt_valid,data_in,fifo_full,detect_add,
        ld_state,laf_state,full_state,lfd_state,rst_int_reg,err,
        parity_done,low_packet_valid,dout);

    input clock,resetn,pkt_valid,fifo_full,detect_add,ld_state,laf_state,full_state,lfd_state,rst_int_reg;
    input [7:0]data_in;
    output reg err,parity_done,low_packet_valid;
    output reg [7:0]dout;
    reg [7:0]header,int_reg,int_parity,ext_parity;


    //------------------------------DATA OUT LOGIC---------------------------------

    always@(posedge clock)
    begin
    if(!resetn)
    begin
    dout    	 <=0;
    header  	 <=0;
    int_reg 	 <=0;
     end
    else if(detect_add && pkt_valid && data_in[1:0]!=2'b11)
    header<=data_in;
    else if(lfd_state)
    dout<=header;
    else if(ld_state && !fifo_full)
    dout<=data_in;
    else if(ld_state && fifo_full)
    int_reg<=data_in;
    else if(laf_state)
    dout<=int_reg;
    end

    //---------------------------LOW PACKET VALID LOGIC----------------------------

    always@(posedge clock)
         begin
        if(!resetn)
               low_packet_valid<=0; 
           else if(rst_int_reg)
               low_packet_valid<=0;

        else if(ld_state && !pkt_valid) 
               low_packet_valid<=1;
      end
    //----------------------------PARITY DONE LOGIC--------------------------------

    always@(posedge clock)
    begin
    if(!resetn)
    parity_done<=0;
    else if(detect_add)
    parity_done<=0;
    else if((ld_state && !fifo_full && !pkt_valid)
        ||(laf_state && low_packet_valid && !parity_done))
    parity_done<=1;
    end

    //---------------------------PARITY CALCULATE LOGIC----------------------------

    always@(posedge clock)
    begin
    if(!resetn)
    int_parity<=0;
    else if(detect_add)
    int_parity<=0;
    else if(lfd_state && pkt_valid)
    int_parity<=int_parity^header;
    else if(ld_state && pkt_valid && !full_state)
    int_parity<=int_parity^data_in;
    else
    int_parity<=int_parity;
    end


    //-------------------------------ERROR LOGIC-----------------------------------

    always@(posedge clock)
    begin
    if(!resetn)
            err<=0;
    else if(parity_done)
             begin
               if (int_parity==ext_parity)
                  err<=0;
               else 
              err<=1;
           end
      else
          err<=0;
    end

    //-------------------------------EXTERNAL PARITY LOGIC-------------------------

    always@(posedge clock)
    begin
    if(!resetn)
        ext_parity<=0;
    else if(detect_add)
        ext_parity<=0;
    else if((ld_state && !fifo_full && !pkt_valid) || (laf_state && !parity_done && low_packet_valid))
        ext_parity<=data_in;
    end

    endmodule





    //:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    //                          FIFO
    //:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    module router_fifo(clock,resetn,write_enb,soft_reset,read_enb,data_in,lfd_state,full,data_out,empty);

        input clock,resetn,soft_reset;
        input write_enb,read_enb,lfd_state;
        output empty,full;    
        input [7:0] data_in;
        output reg [7:0] data_out;
        reg [4:0] rd_pointer,wr_pointer;
        reg [6:0] count;
        reg [8:0] mem[15:0];
        integer i;
        reg  lfd_state_s;
        
        //********************************************************************************************************logic for full and empty
        assign full = ({~wr_pointer[4],wr_pointer[3:0]}==rd_pointer) ? 1 : 0;
        assign empty = (rd_pointer==wr_pointer) ? 1 : 0;
        
        //********************************************************************************************************logic for counter
        always @(posedge clock) 
        begin
          if (read_enb && !empty) 
          begin
            if ((mem[rd_pointer[3:0]][8])==1'b1) 
            begin
              count<=mem[rd_pointer[3:0]][7:2]+1;
            end
              else if(count!=0)
            begin
              count <= count - 1;
            end
          end
        end  
        //***************************************************************************************************rd pointer logic
        always @(posedge clock) 
        begin
          if (!resetn ) 
          begin
            rd_pointer<=0 ; 
          end 
          else if (read_enb && (~empty))
          begin
            rd_pointer <= rd_pointer + 1;
          end
        end
        //***************************************************************************************************-wr pointer logic
        always @(posedge clock) 
        begin
          if (!resetn ) 
          begin
            wr_pointer<=0 ; 
          end 
          else if (write_enb && (~full))
          begin
            wr_pointer <= wr_pointer + 1;
          end
        end
        
        //***************************************************************************************************tem logic
         always@(posedge clock)
            begin
              if(!resetn)
                lfd_state_s <= 0;
              else
                lfd_state_s <= lfd_state;
            end 
        //***************************************************************************************************read operation
        always @(posedge clock) 
        begin
          if (!resetn) 
          begin
            data_out<=0;  
          end  
           else if(soft_reset) 
                  data_out <= 8'bz;
          else if ((read_enb) && (!empty)) 
          begin
            data_out <= mem[rd_pointer[3:0]][7:0];
          end
          else if (count==0) 
          begin
            data_out=8'bz;
          end
        end
        //***************************************************************************************************write operation
        always @(posedge clock) 
        begin
          if(!resetn || soft_reset) 
          begin
            //wr_pointer <= 'h0;
            for (i=0; i<16; i=i+1)
            mem[i] <= 'h0;
          end 
          else if (write_enb && ~(full)) 
          begin
            if (lfd_state_s) 
            begin
              mem[wr_pointer[3:0]][8]<=1'b1;
              mem[wr_pointer[3:0]][7:0]={lfd_state_s,data_in};
            end
            else 
            begin
              mem[wr_pointer[3:0]][8]<=1'b0;
              mem[wr_pointer[3:0]][7:0]={lfd_state_s,data_in};
            end
          end
        end
        
        
        
        endmodule
        
        










//:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//                          TOP
//:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    module router_top(clock,resetn,pkt_valid,read_enb_0,read_enb_1,read_enb_2,data_in,
        busy,err,vld_out_0,vld_out_1,vld_out_2,data_out_0,data_out_1,data_out_2);

input [7:0]data_in;
input pkt_valid,clock,resetn,read_enb_0,read_enb_1,read_enb_2;
output [7:0]data_out_0,data_out_1,data_out_2;
output vld_out_0,vld_out_1,vld_out_2,err,busy;

wire soft_reset_0,full_0,empty_0,soft_reset_1,full_1,empty_1,soft_reset_2,full_2,empty_2,
fifo_full,detect_add,ld_state,laf_state,full_state,lfd_state,rst_int_reg,
parity_done,low_packet_valid,write_enb_reg;
wire [2:0]write_enb;
wire [7:0]d_in;

//**********************************************fifo0 instantiation
router_fifo FIFO_0(.clock(clock),
           .resetn(resetn),
       .soft_reset(soft_reset_0),
   .write_enb(write_enb[0]),
   .read_enb(read_enb_0),
               .lfd_state(lfd_state),
   .data_in(d_in),
   .full(full_0),
   .empty(empty_0),
   .data_out(data_out_0));
       

//**********************************************fifo1 instantiation
router_fifo FIFO_1(.clock(clock),
           .resetn(resetn),
   .soft_reset(soft_reset_1),
   .write_enb(write_enb[1]),
   .read_enb(read_enb_1),
               .lfd_state(lfd_state),
       .data_in(d_in),
   .full(full_1),
   .empty(empty_1),
   .data_out(data_out_1));
           

//**********************************************fifo1 instantiation	
router_fifo FIFO_2(.clock(clock),
           .resetn(resetn),
   .soft_reset(soft_reset_2),
   .write_enb(write_enb[2]),
   .read_enb(read_enb_2),
               .lfd_state(lfd_state),
   .data_in(d_in),
   .full(full_2),
   .empty(empty_2),
   .data_out(data_out_2));

//**********************************************register instantiation

router_reg REGISTER(.clock(clock),
            .resetn(resetn),
    .pkt_valid(pkt_valid),
        .data_in(data_in),
    .fifo_full(fifo_full),
        .detect_add(detect_add),
                .ld_state(ld_state),
    .laf_state(laf_state),
    .full_state(full_state),
           .lfd_state(lfd_state),
    .rst_int_reg(rst_int_reg),
    .err(err),
                .parity_done(parity_done),
    .low_packet_valid(low_packet_valid),
    .dout(d_in));
      
      
      
      
        
//********************************************synchronizer instantiation-----  						 
router_sync SYNCHRONIZER(.clock(clock),
                 .resetn(resetn),
     .data_in(data_in[1:0]),
     .dect_add(detect_add),
     .full_0(full_0),
     .full_1(full_1),
     .full_2(full_2),
     .empty_0(empty_0),
     .empty_1(empty_1),
     .empty_2(empty_2),
     .write_enb_reg(write_enb_reg),
     .read_enb_0(read_enb_0),
     .read_enb_1(read_enb_1),
     .read_enb_2(read_enb_2),
     .write_enb(write_enb),
     .fifo_full(fifo_full),
     .vld_out_0(vld_out_0),
     .vld_out_1(vld_out_1),
     .vld_out_2(vld_out_2),
     .soft_reset_0(soft_reset_0),
     .soft_reset_1(soft_reset_1),
     .soft_reset_2(soft_reset_2));						 
                 
//******************************************************fsm instantiation-----
router_fsm FSM(.clock(clock),
       .resetn(resetn),
   .pkt_valid(pkt_valid),
   .data_in(data_in[1:0]),
   .fifo_full(fifo_full),
   .fifo_empty_0(empty_0),
   .fifo_empty_1(empty_1),
   .fifo_empty_2(empty_2),
           .soft_reset_0(soft_reset_0),
   .soft_reset_1(soft_reset_1),
   .soft_reset_2(soft_reset_2),
   .parity_done(parity_done),
   .low_pkt_valid(low_packet_valid),
           .write_enb_reg(write_enb_reg),
       .detect_add(detect_add),
   .ld_state(ld_state),
   .laf_state(laf_state),
   .lfd_state(lfd_state),
   .full_state(full_state),
       .rst_int_reg(rst_int_reg),
       .busy(busy));

endmodule






















    
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><<><><><><><<><><><><><><><>
    //TESTBENCH START
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><<><><><><><<><><><><><><><>
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    typedef enum {UVM_ACTIVE,UVM_PASSIVE} uvm_active_passive_enum;

    //#################################################################################  SORCE



    //================================
    //================================                                         SRC_CONFIG
    //================================  
    class src_config extends uvm_object;
      `uvm_object_utils(src_config)

      int no_src_agent;

      int mistry_number;

      uvm_active_passive_enum is_active;

      virtual router_if vif;
      function new(string name ="src_config");
        super.new(name);
      endfunction //new()
    endclass //src_config extends superClass



    //================================
    //================================                                                   XTN
    //================================



    class src_xtn extends uvm_sequence_item;
        `uvm_object_utils(src_xtn)

    rand bit [7:0]header;		
	rand bit [7:0]PL[];
	rand bit [7:0]parity;
	bit error,busy;

    constraint limit  {header[1:0]!=3;}
	constraint limit1 {PL.size==header[7:2];}
	constraint limit2 {PL.size  inside{[1:64]};}
    extern function void do_print (uvm_printer printer);

        function new(string name ="src_xtn");
            super.new(name);
        endfunction //new()


        function void post_randomize();
            parity= header^0;
            foreach(PL[i])
                parity = parity ^PL[i];
        endfunction


    endclass 

    function void  src_xtn::do_print (uvm_printer printer);
        super.do_print(printer);
    
       
        //              	srting name   		bitstream value     size    radix for printing
        printer.print_field( "header", this.header,	UVM_DEC	);
        printer.print_field( "address is ", this.header[1:0], UVM_DEC	);
        foreach(PL[i])
    begin
      //  printer.print_field( "busy ", this.busy, UVM_DEC	);
           printer.print_field( $sformatf("payload[%0d]",i),this.PL[i],UVM_DEC);
    end
        printer.print_field( "parity", this.parity, UVM_DEC	);
        printer.print_field( "busy ", this.busy, UVM_DEC	);
        
        //printer.print_field( "xtn_delay", 		this.xtn_delay,     65,		 UVM_DEC		);
       
        //  	         	   variable name	xtn_type		$bits(variable name) 	variable name.name
       // printer.print_generic( "xtn_type", 		"addr_t",		$bits(xtn_type),		xtn_type.name);
    
    endfunction:do_print
    

    //================================
    //================================                                               sequence
    //================================
    class src_seq extends uvm_sequence #(src_xtn);
        `uvm_object_utils(src_seq)
        function new(string name ="src_seq");
            super.new(name);
        endfunction //new()
    endclass //src_seq extends superClass

class router_rand_sseqs extends src_seq;
`uvm_object_utils(router_rand_sseqs)
extern function new(string name="router_rand_sseqs");
extern task body();
endclass

//-------------------------------------------
function router_rand_sseqs::new(string name="router_rand_sseqs");
	super.new(name);
endfunction

task router_rand_sseqs::body();
	repeat(4)
		begin
			req = router_src_xtn::type_id::create("req");
			start_item(req);
			assert(req.randomize()with {header[1:0]==2'b00;});
			finish_item(req);
		end
endtask


    //================================
    //================================                                                 monitor
    //================================
    class src_monitor extends uvm_monitor;
        `uvm_component_utils(src_monitor)
        virtual router_if.S_MON_MP vif;
	    src_config m_cfg;
	    uvm_analysis_port#(src_xtn)monitor_port;

        function new(string name ="src_monitor",uvm_component parent);
            super.new(name,parent);
        endfunction //new()

    extern function void build_phase(uvm_phase phase);
	extern function void connect_phase(uvm_phase phase);
	extern task run_phase(uvm_phase phase);
	extern task collect_data();
	extern function void report_phase(uvm_phase phase);
    endclass //src_monitor extends superClass

    function void src_monitor:: build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(src_config)::get(this,"","src_config",m_cfg))
                `uvm_fatal(get_type_name(),"configuration is failing")
    endfunction

    function void src_monitor:: connect_phase(uvm_phase phase);	
        super.connect_phase(phase);
        vif = m_cfg.vif;
    endfunction


    
task src_monitor::collect_data();
    src_xtn xtn;	
    xtn = src_xtn::type_id::create("xtn");
    @(vif.s_mon_cb);
    while(vif.s_mon_cb.busy)	
        @(vif.s_mon_cb);
    while(vif.s_mon_cb.pkt_valid!==1)//------------it was 0
        @(vif.s_mon_cb);
    xtn.header =vif.s_mon_cb.data_in;
        @(vif.s_mon_cb);		
    xtn.PL = new[xtn.header[7:2]];
    foreach(xtn.PL[i])
        begin
            while(vif.s_mon_cb.busy)	
                @(vif.s_mon_cb);
            xtn.PL[i]= vif.s_mon_cb.data_in;
            @(vif.s_mon_cb);		
        end	
    while(vif.s_mon_cb.busy)	
                @(vif.s_mon_cb);

    while(vif.s_mon_cb.pkt_valid)
        @(vif.s_mon_cb);
    xtn.parity= vif.s_mon_cb.data_in;
        @(vif.s_mon_cb);

//	`uvm_info(get_type_name(),$sformatf("printing from monitor \n %s", xtn.sprint()),UVM_LOW) 
endtask


task src_monitor::run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever collect_data();
endtask


function void router_src_monitor::report_phase(uvm_phase phase);
	//-------------------------------------------------------	`uvm_info(get_type_name(),"report phae",UVM_NONE);
endfunction






    //================================
    //================================                                                        driver
    //================================
    class src_driver extends uvm_driver #(src_xtn);
        `uvm_component_utils(src_driver)
        virtual router_if.S_DR_MP vif;
        src_config m_cfg;

        function new(string name ="src_driver",uvm_component parent);
            super.new(name,parent);
        endfunction //new()

    extern function void build_phase(uvm_phase phase);
	extern function void connect_phase(uvm_phase phase);
	extern task run_phase(uvm_phase phase);
	extern task send_to_data(router_src_xtn xtn);
	extern function void report_phase(uvm_phase phase);

    endclass //src_driver

    function void src_driver:: build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(src_config)::get(this,"","src_config",m_cfg))
                `uvm_fatal(get_type_name(),"configuration is failing")
    endfunction

    function void src_driver::connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        vif = m_cfg.vif;        
    endfunction

    task src_driver::send_to_data(src_xtn xtn);
        `uvm_info(get_type_name(),$sformatf("printing from src driver \n %s", xtn.sprint()),UVM_LOW) 
 
         @(vif.s_dr_cb)
         while(vif.s_dr_cb.busy)
             @(vif.s_dr_cb);
         vif.s_dr_cb.pkt_valid<=1'b1;//------------------------ it was 0
         vif.s_dr_cb.data_in<=xtn.header;
             @(vif.s_dr_cb);
         foreach(xtn.PL[i])
             begin
                 while(vif.s_dr_cb.busy)
                     @(vif.s_dr_cb);
                 vif.s_dr_cb.data_in<=xtn.PL[i];
                     @(vif.s_dr_cb);				
             end	
             while(vif.s_dr_cb.busy)
                 @(vif.s_dr_cb);
             vif.s_dr_cb.pkt_valid<=1'b0;
             vif.s_dr_cb.data_in<=xtn.parity;
             repeat(2)
                 @(vif.s_dr_cb);
             xtn.error = vif.s_dr_cb.err;
 endtask

 task src_driver::run_phase(uvm_phase phase);
	super.run_phase(phase);
	@(vif.s_dr_cb)
		vif.s_dr_cb.resetn<=1'b0;
	@(vif.s_dr_cb)
		vif.s_dr_cb.resetn<=1'b1;
		forever
			begin	
				seq_item_port.get_next_item(req);
				send_to_data(req);
				seq_item_port.item_done();
			end

endtask

function void src_driver::report_phase(uvm_phase phase);
    //-------------------------------	`uvm_info(get_type_name(),"report phase",UVM_NONE);
    endfunction




    
    //================================
    //================================                                                            sequencer
    //================================
    class src_sequencer extends uvm_sequencer #(src_xtn);
        `uvm_component_utils(src_sequencer)
        function new(string name ="src_sequencer",uvm_component parent);
            super.new(name,parent);
        endfunction //new()
    endclass //src_driver



    //================================
    //================================                                                        src_agent
    //================================
    class src_agent extends uvm_agent;
        `uvm_component_utils(src_agent)
        src_driver     sdrvh;
        src_monitor    smonh;
        src_sequencer sseqrh;
        router_src_config m_cfg;


    extern function new(string name = "src_agent",uvm_component parent);
	extern function void build_phase (uvm_phase phase);
	extern function void connect_phase(uvm_phase phase);

       
    endclass //src_agent extends superClass

    function src_agent::new(string name = "src_agent",uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void src_agent::build_phase(uvm_phase phase);
    
        super.build_phase(phase);
       // get the config object using uvm_config_db
        if(!uvm_config_db #(src_config)::get(this,"","src_config",m_cfg))
            `uvm_fatal("CONFIG","cannot get() m_cfg from uvm_config_db. Have you set() it?") 
        smonh=src_monitor::type_id::create("smonh",this);	
        if(m_cfg.is_active==UVM_ACTIVE)
            begin
                sdrvh=src_driver::type_id::create("sdrvh",this);
                sseqrh=src_sequencer::type_id::create("sseqrh",this);
            end
            
    endfunction
    
    function void src_agent::connect_phase(uvm_phase phase);
        if(m_cfg.is_active==UVM_ACTIVE)
            begin
                sdrvh.seq_item_port.connect(sseqrh.seq_item_export);
              end
    endfunction






    //================================
    //================================                                                src_agent_top
    //================================
    class src_agent_top extends uvm_env;
        `uvm_component_utils(src_agent_top)
        int no_src_agent;
        src_agent src_agh[];
        src_config s_cfg[];
        router_env_config m_cfg;

    extern function new(string name ="router_src_agent_top",uvm_component parent);
	extern function void build_phase(uvm_phase phase);
	extern task run_phase(uvm_phase phase);
    endclass //src_agent extends superClass

    function src_agent_top::new(string name="router_src_agent_top",uvm_component parent);
        super.new(name,parent);
    endfunction

    function void src_agent_top::build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(env_config)::get(this,"","env_config",m_cfg))
            `uvm_fatal("AGT_TOP","cannot get config data");
    
        src_agh = new[m_cfg.no_of_src_agt];
        s_cfg = new[m_cfg.no_of_src_agt];
        foreach(sagth[i])
        begin
            s_cfg[i]=m_cfg.m_src_cfg[i];
            src_agh[i] = router_src_agent::type_id::create($sformatf("src_agh[%0d]",i),this);
        //	uvm_config_db#(router_src_config)::set(this,$sformatf("s_cfg[%0d]*",i),"rd_config",s_cfg[i]);
            uvm_config_db#(src_config)::set(this,"*","src_config",s_cfg[i]);
        
        end
        
    endfunction







    //#################################################################################  DESTINATION

    //================================
    //================================                                                                        DEST_CONFIG
    //================================
    class dst_config extends uvm_object;
      `uvm_object_utils(dst_config)
      int no_src_agent;
      uvm_active_passive_enum is_active;

      int mistry_number;
      function new(string name ="dst_config");
        super.new(name);
      endfunction //new()

    endclass //src_config extends superClass




  //================================
    //================================                                                                        xtn
    //================================
    class dst_xtn extends uvm_sequence_item;
        `uvm_object_utils(dst_xtn)
        function new(string name ="dst_xtn");
            super.new(name);
        endfunction //new()
    endclass 


    //================================
    //================================                                                                        sequence
    //================================
    class dst_seq extends uvm_sequence #(dst_xtn);
        `uvm_object_utils(dst_seq)
        function new(string name ="dst_seq");
            super.new(name);
        endfunction //new()
    endclass //dst_seq extends superClass


    //================================
    //================================                                                                                  monitor
    //================================
    class dst_monitor extends uvm_monitor;
        `uvm_component_utils(dst_monitor)
        
        function new(string name ="dst_monitor",uvm_component parent);
            super.new(name,parent);
        endfunction //new()
    endclass //dst_monitor extends superClass


    //================================
    //================================                                                                     driver
    //================================
    class dst_driver extends uvm_driver #(dst_xtn);
        `uvm_component_utils(dst_driver)
        function new(string name ="dst_driver",uvm_component parent);
            super.new(name,parent);
        endfunction //new()
    endclass //dst_driver



    //================================
    //================================                                                                         sequencer
    //================================
    class dst_sequencer extends uvm_sequencer#(dst_xtn);
        `uvm_component_utils(dst_sequencer)
        function new(string name ="dst_sequencer",uvm_component parent);
            super.new(name,parent);
        endfunction //new()
    endclass //dst_driver


    //================================
    //================================                                                                          dst_agent
    //================================
    class dst_agent extends uvm_agent;
        `uvm_component_utils(dst_agent)

        dst_driver     ddrvh;
        dst_monitor    dmonh;
        dst_sequencer dseqrh;
        function new(string name ="dst_agent",uvm_component parent);
            super.new(name,parent);
        endfunction //new()

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            ddrvh = dst_driver::type_id::create("ddrvh",this);
            dmonh = dst_monitor::type_id::create("dmonh",this);
            dseqrh = dst_sequencer::type_id::create("dseqrh",this);
        endfunction
    endclass //dst_agent extends superClass


    //================================
    //================================   ----------------------------------------------------------dst_agent_top
    //================================
    class dst_agent_top extends uvm_env;
        `uvm_component_utils(dst_agent_top)
        int no_dst_agent ;

        dst_agent dst_agh[];
        function new(string name ="dst_agent_top",uvm_component parent);
            super.new(name,parent);
        endfunction //new()

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
        if(! uvm_config_db#(int)::get(this, "", "no_dst_agent", no_dst_agent))
            `uvm_fatal(get_name(), "failinf no of dst agt")
            
            dst_agh = new[no_dst_agent];
            foreach (dst_agh[i]) 
            begin
                dst_agh[i] = dst_agent::type_id::create($sformatf("dst_agh[%0d]",i),this);
            end
                    
        endfunction

        function void end_of_elaboration_phase(uvm_phase phase);
            super.end_of_elaboration_phase(phase);
            uvm_top.print_topology();
        endfunction

    endclass //dst_agent extends superClass





    //#################################################################################  enviroment configuraion

    class env_config extends uvm_object;
        `uvm_object_utils(env_config)
        int no_src_agent;
        int no_dst_agent;

        dst_config d_cfg[];
        src_config s_cfg[];

        int mistry_number;
        function new(string name ="env_config");
          super.new(name);
        endfunction //new()
        
      endclass //src_config extends superClass

    //#################################################################################  enviroment


    class route_env extends uvm_env;
        `uvm_component_utils(route_env)

        dst_agent_top dst_agtt;
        src_agent_top src_agtt;
        function new(string name ="route_env",uvm_component parent);
            super.new(name,parent);
        endfunction //new()

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            dst_agtt = dst_agent_top::type_id::create("dst_agtt",this);
            src_agtt = src_agent_top::type_id::create("src_agtt",this);
        endfunction

        
        
    endclass //dst_agent extends superClass

    //#################################################################################  test



    class router_test extends uvm_test;
        `uvm_component_utils(router_test)
        int no_src_agent =1;
        int no_dst_agent =3;
        
        dst_agent_top dst_agtt;
        src_agent_top src_agtt;
        function new(string name ="route_env",uvm_component parent);
            super.new(name,parent);
        endfunction //new()

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            dst_agtt = dst_agent_top::type_id::create("dst_agtt",this);
            src_agtt = src_agent_top::type_id::create("src_agtt",this);

            uvm_config_db#(int)::set(this, "*", "no_src_agent", no_src_agent);
            uvm_config_db#(int)::set(this, "*", "no_dst_agent", no_dst_agent);
        endfunction
    endclass //dst_agent extends superClass




    module top; 
        initial 
        begin
            run_test("router_test");
 
        end        
        
    endmodule