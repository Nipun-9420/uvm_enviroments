    /*
    in this code i am making 1 src agent and 3 dst agent and seting 4 diffrent values to each agnet throusg config agent

    */

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    typedef enum {UVM_ACTIVE,UVM_PASSIVE} uvm_active_passive_enum;

    //#################################################################################  SORCE



    //================================
    //================================                                         SRC_CONFIG
    //================================  
    class src_config extends superClass;
      `uvm_object_utils(src_config)
      int no_src_agent;
      int mistry_number;
      function new(string name ="src_config");
        super.new(name);
      endfunction //new()
    endclass //src_config extends superClass



    //================================
    //================================                                                   XTN
    //================================
    class src_config extends uvm_object;
        `uvm_object_utils(src_config)

        function new(string name ="src_config");
                super.new(name);
        endfunction

    endclass
    class src_xtn extends uvm_sequence_item;
        `uvm_object_utils(src_xtn)
        function new(string name ="src_xtn");
            super.new(name);
        endfunction //new()
    endclass 


    //================================
    //================================                                               sequence
    //================================
    class src_seq extends uvm_sequence #(src_xtn);
        `uvm_object_utils(src_seq)
        function new(string name ="src_seq");
            super.new(name);
        endfunction //new()
    endclass //src_seq extends superClass


    //================================
    //================================                                                 monitor
    //================================
    class src_monitor extends uvm_monitor;
        `uvm_component_utils(src_monitor)
        function new(string name ="src_monitor",uvm_component parent);
            super.new(name,parent);
        endfunction //new()
    endclass //src_monitor extends superClass


    //================================
    //================================                                                        driver
    //================================
    class src_driver extends uvm_driver #(src_xtn);
        `uvm_component_utils(src_driver)
        function new(string name ="src_driver",uvm_component parent);
            super.new(name,parent);
        endfunction //new()
    endclass //src_driver



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
    //================================                                                src_agent_top
    //================================
    class src_agent_top extends uvm_env;
        `uvm_component_utils(src_agent_top)
        int no_src_agent;
        src_agent src_agh[];
        function new(string name ="src_agent_top",uvm_component parent);
            super.new(name,parent);
        endfunction //new()

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            if(! uvm_config_db#(int)::get(this, "", "no_src_agent", no_src_agent))
            `uvm_fatal(get_name(), "failinf no of dst agt")
            
            src_agh = new[no_src_agent];
            foreach (src_agh[i]) 
            begin
                src_agh[i] = src_agent::type_id::create($sformatf("src_agh[%0d]",i),this);
            end

        endfunction
    endclass //src_agent extends superClass






    //#################################################################################  DESTINATION

    //================================
    //================================                                                                        DEST_CONFIG
    //================================
    class src_config extends superClass;
      `uvm_object_utils(src_config)
      int no_src_agent;
      int mistry_number;
      function new(string name ="src_config");
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
            run_test("router_test");
        
        
    endmodule