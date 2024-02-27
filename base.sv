/*
only basic output no configuration
--------------------------------------------------------------
Name                       Type                    Size  Value
--------------------------------------------------------------
uvm_test_top               router_test             -     @336 
  dst_agtt                 dst_agent_top           -     @349 
    dst_agh                dst_agent               -     @367 
      ddrvh                dst_driver              -     @377 
        rsp_port           uvm_analysis_port       -     @396 
        seq_item_port      uvm_seq_item_pull_port  -     @386 
      dmonh                dst_monitor             -     @406 
      dseqrh               dst_sequencer           -     @415 
        rsp_export         uvm_analysis_export     -     @424 
        seq_item_export    uvm_seq_item_pull_imp   -     @542 
        arbitration_queue  array                   0     -    
        lock_queue         array                   0     -    
        num_last_reqs      integral                32    'd1  
        num_last_rsps      integral                32    'd1  
  src_agtt                 src_agent_top           -     @358 
    src_agh                src_agent               -     @557 
      sdrvh                src_driver              -     @567 
        rsp_port           uvm_analysis_port       -     @586 
        seq_item_port      uvm_seq_item_pull_port  -     @576 
      smonh                src_monitor             -     @596 
      sseqrh               src_sequencer           -     @605 
        rsp_export         uvm_analysis_export     -     @614 
        seq_item_export    uvm_seq_item_pull_imp   -     @732 
        arbitration_queue  array                   0     -    
        lock_queue         array                   0     -    
        num_last_reqs      integral                32    'd1  
        num_last_rsps      integral                32    'd1  
--------------------------------------------------------------
*/

import uvm_pkg::*;
`include "uvm_macros.svh"

typedef enum {  UVM_ACTIVE,UVM_PASSIVE} is_active;

//#################################################################################  SORCE

//================================
//================================   XTN
//================================
class src_xtn extends uvm_sequence_item;
    `uvm_object_utils(src_xtn)
    function new(string name ="src_xtn");
        super.new(name);
    endfunction //new()
endclass 


//================================
//================================   sequence
//================================
class src_seq extends uvm_sequence #(src_xtn);
    `uvm_object_utils(src_seq)
    function new(string name ="src_seq");
        super.new(name);
    endfunction //new()
endclass //src_seq extends superClass


//================================
//================================   monitor
//================================
class src_monitor extends uvm_monitor;
    `uvm_component_utils(src_monitor)
    function new(string name ="src_monitor",uvm_component parent);
        super.new(name,parent);
    endfunction //new()
endclass //src_monitor extends superClass


//================================
//================================   driver
//================================
class src_driver extends uvm_driver #(src_xtn);
    `uvm_component_utils(src_driver)
    function new(string name ="src_driver",uvm_component parent);
        super.new(name,parent);
    endfunction //new()
endclass //src_driver



//================================
//================================   sequencer
//================================
class src_sequencer extends uvm_sequencer #(src_xtn);
    `uvm_component_utils(src_sequencer)
    function new(string name ="src_sequencer",uvm_component parent);
        super.new(name,parent);
    endfunction //new()
endclass //src_driver

//================================
//================================   src_agent
//================================
class src_agent extends uvm_agent;
    `uvm_component_utils(src_agent)
    src_driver     sdrvh;
    src_monitor    smonh;
    src_sequencer sseqrh;
    function new(string name ="src_agent",uvm_component parent);
        super.new(name,parent);
    endfunction //new()

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sdrvh = src_driver::type_id::create("sdrvh",this);
        smonh = src_monitor::type_id::create("smonh",this);
        sseqrh = src_sequencer::type_id::create("sseqrh",this);
    endfunction
endclass //src_agent extends superClass


//================================
//================================   src_agent_top
//================================
class src_agent_top extends uvm_env;
    `uvm_component_utils(src_agent_top)
    src_agent src_agh;
    function new(string name ="src_agent_top",uvm_component parent);
        super.new(name,parent);
    endfunction //new()

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        src_agh = src_agent::type_id::create("src_agh",this);
    endfunction
endclass //src_agent extends superClass






//#################################################################################  DESTINATION


class dst_xtn extends uvm_sequence_item;
    `uvm_object_utils(dst_xtn)
    function new(string name ="dst_xtn");
        super.new(name);
    endfunction //new()
endclass 


//================================
//================================   sequence
//================================
class dst_seq extends uvm_sequence #(dst_xtn);
    `uvm_object_utils(dst_seq)
    function new(string name ="dst_seq");
        super.new(name);
    endfunction //new()
endclass //dst_seq extends superClass


//================================
//================================   monitor
//================================
class dst_monitor extends uvm_monitor;
    `uvm_component_utils(dst_monitor)
    
    function new(string name ="dst_monitor",uvm_component parent);
        super.new(name,parent);
    endfunction //new()
endclass //dst_monitor extends superClass


//================================
//================================   driver
//================================
class dst_driver extends uvm_driver #(dst_xtn);
    `uvm_component_utils(dst_driver)
    function new(string name ="dst_driver",uvm_component parent);
        super.new(name,parent);
    endfunction //new()
endclass //dst_driver



//================================
//================================   sequencer
//================================
class dst_sequencer extends uvm_sequencer#(dst_xtn);
    `uvm_component_utils(dst_sequencer)
    function new(string name ="dst_sequencer",uvm_component parent);
        super.new(name,parent);
    endfunction //new()
endclass //dst_driver


//================================
//================================   dst_agent
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
//================================   dst_agent_top
//================================
class dst_agent_top extends uvm_env;
    `uvm_component_utils(dst_agent_top)

    dst_agent dst_agh;
    function new(string name ="dst_agent_top",uvm_component parent);
        super.new(name,parent);
    endfunction //new()

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        dst_agh = dst_agent::type_id::create("dst_agh",this);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

endclass //dst_agent extends superClass









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

//#################################################################################  enviroment


class router_test extends uvm_test;
    `uvm_component_utils(router_test)
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


module top; 
    initial 
        run_test("router_test");
    
    
endmodule