--************************************************************************
-- Copyright (c) 2016-2017 Nisha Jacob
--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--**********************************************************************
-- @file sec_axi_wrapper_es.vhd
-- @brief Top level with wrapper to montior to AXI transcations
-- The axi slave and master interface must be included
-- e.g., via the IDE.
-- @author Nisha Jacob <nisha.jacob@aisec.fraunhofer.de>
-- @license This project is released under the MIT License.
--
--***********************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_wrap is
	generic (
		S_DATA_WIDTH	: integer	:= 32;
		S_ADDR_WIDTH	: integer	:= 4;

		M_AXI_ADDR_WIDTH	: integer	:= 32;
		M_AXI_DATA_WIDTH	: integer	:= 32;
		M_AXI_TRANSACTIONS_NUM	: integer	:= 4
	);
	port (
     	 alarm			: out	std_logic;
		-- AXI Slave Ports
		s_axi_aclk		: in std_logic;
		s_axi_aresetn	: in std_logic;
		s_axi_awaddr	: in std_logic_vector(S_ADDR_WIDTH-1 downto 0);
		s_axi_awprot	: in std_logic_vector(2 downto 0);
		s_axi_awvalid	: in std_logic;
		s_axi_awready	: out std_logic;
		s_axi_wdata		: in std_logic_vector(S_DATA_WIDTH-1 downto 0);
		s_axi_wstrb		: in std_logic_vector((S_DATA_WIDTH/8)-1 downto 0);
		s_axi_wvalid	: in std_logic;
		s_axi_wready	: out std_logic;
		s_axi_bresp		: out std_logic_vector(1 downto 0);
		s_axi_bvalid	: out std_logic;
		s_axi_bready	: in std_logic;
		s_axi_araddr	: in std_logic_vector(S_ADDR_WIDTH-1 downto 0);
		s_axi_arprot	: in std_logic_vector(2 downto 0);
		s_axi_arvalid	: in std_logic;
		s_axi_arready	: out std_logic;
		s_axi_rdata		: out std_logic_vector(S_DATA_WIDTH-1 downto 0);
		s_axi_rresp		: out std_logic_vector(1 downto 0);
		s_axi_rvalid	: out std_logic;
		s_axi_rready	: in std_logic;

		-- AXI Master Ports
		m_axi_aclk		: in std_logic;
		m_axi_aresetn	: in std_logic;
		m_axi_awaddr	: out std_logic_vector(M_AXI_ADDR_WIDTH-1 downto 0);
		m_axi_awprot	: out std_logic_vector(2 downto 0);
		m_axi_awcache	: out std_logic_vector(3 downto 0);
		m_axi_awvalid	: out std_logic;
		m_axi_awready	: in std_logic;
		m_axi_wdata		: out std_logic_vector(M_AXI_DATA_WIDTH-1 downto 0);
		m_axi_wstrb		: out std_logic_vector(M_AXI_DATA_WIDTH/8-1 downto 0);
		m_axi_wvalid	: out std_logic;
		m_axi_wready	: in std_logic;
		m_axi_bresp		: in std_logic_vector(1 downto 0);
		m_axi_bvalid	: in std_logic;
		m_axi_bready	: out std_logic;
		m_axi_araddr	: out std_logic_vector(M_AXI_ADDR_WIDTH-1 downto 0);
		m_axi_arprot	: out std_logic_vector(2 downto 0);
		m_axi_arcache	: out std_logic_vector(3 downto 0);
		m_axi_arvalid	: out std_logic;
		m_axi_arready	: in std_logic;
		m_axi_rdata		: in std_logic_vector(M_AXI_DATA_WIDTH-1 downto 0);
		m_axi_rresp		: in std_logic_vector(1 downto 0);
		m_axi_rvalid	: in std_logic;
		m_axi_rready	: out std_logic
	);
end axi_wrap;

architecture rtl of axi_wrap is
	 type state_t is (IDLE,
					INIT_EXEC,
				    INIT_ABORT,
					EXEC_DONE
					);
	 signal state_reg_t : state_t ;
	--------------------------------------------------------------------
	-- Signals for wrapper
	--------------------------------------------------------------------
	signal valid_trans_s		: std_logic;
	signal TZ_arprot_s			: std_logic_vector(2 downto 0);
	signal TZ_awprot_s			: std_logic_vector(2 downto 0);
	signal abort_s				: std_logic;
	signal add_range_high_reg	: std_logic_vector (M_AXI_DATA_WIDTH-1 downto 0);
	signal TZ_s					: std_logic_vector(2 downto 0);
	signal num_trans_reg		: std_logic_vector(M_AXI_DATA_WIDTH/2-1 downto 0);
    signal total_trans_reg  	: std_logic_vector(M_AXI_DATA_WIDTH/2-1 downto 0);
	signal err_typ_reg			: std_logic_vector(1 downto 0);
    signal m_araddr_s    		: std_logic_vector(M_AXI_DATA_WIDTH-1 downto 0);
    signal m_awaddr_s    		: std_logic_vector(M_AXI_DATA_WIDTH-1 downto 0);
    signal m_rdata_s    		: std_logic_vector(M_AXI_DATA_WIDTH-1 downto 0);
    signal m_wdata_s    		: std_logic_vector(M_AXI_DATA_WIDTH-1 downto 0);
	signal m_awvalid_s			: std_logic;
	signal m_arvalid_s			: std_logic;
	signal m_aresetn_s			: std_logic;
	signal m_rvalid_s	       	: std_logic;
	signal m_awready_s			: std_logic;
	---------------------------------------------------------------------
	-- slave signal declaration
	signal start_transfer_s		: std_logic;
	signal reset_s				: std_logic;
	signal start_add_s			: std_logic_vector(S_DATA_WIDTH -1 downto 0);
	signal add_range_low_reg	: std_logic_vector (M_AXI_DATA_WIDTH-1 downto 0);
    signal done_s				: std_logic;
    signal size_s				: std_logic_vector(15 downto 0);

	-- master signal decleration
    signal m_en_s				: std_logic;
    signal m_done_s     		: std_logic;
    signal m_size_s     		: std_logic_vector(M_AXI_DATA_WIDTH/2-1 downto 0);

	-- stablizing enable
	signal start_operation		: std_logic;

	-- component declaration
	component wrap_config is
		generic (
		S_DATA_WIDTH	: integer	:= 32;
		S_ADDR_WIDTH	: integer	:= 4
		);
		port (
		-- user ports
		EN              : out std_logic;
		RST				: out std_logic;
        ADDR            : out std_logic_vector(S_DATA_WIDTH-1 downto 0);
        LENGTH          : out std_logic_vector(15 downto 0);
        DONE            : in std_logic;
  	    Abort_Access	: in std_logic;
		Error_Code		: in std_logic_vector (1 downto 0);

        ----- AXI slave signals
		s_aclk_i		: in std_logic;
		s_aresetn_i		: in std_logic;
		s_awaddr_i		: in std_logic_vector(S_ADDR_WIDTH-1 downto 0);
		s_awprot_i		: in std_logic_vector(2 downto 0);
		s_awvalid_i		: in std_logic;
		s_awready_o		: out std_logic;
		s_wdata_i		: in std_logic_vector(S_DATA_WIDTH-1 downto 0);
		s_wstrb_i		: in std_logic_vector((S_DATA_WIDTH/8)-1 downto 0);
		s_wvalid_i		: in std_logic;
		s_wready_o		: out std_logic;
		s_bresp_o		: out std_logic_vector(1 downto 0);
		s_bvalid_o		: out std_logic;
		s_bready_i		: in std_logic;
		s_araddr_i		: in std_logic_vector(S_ADDR_WIDTH-1 downto 0);
		s_arprot_i		: in std_logic_vector(2 downto 0);
		s_arvalid_i		: in std_logic;
		s_arready_o		: out std_logic;
		s_rdata_o		: out std_logic_vector(S_DATA_WIDTH-1 downto 0);
		s_rresp_o		: out std_logic_vector(1 downto 0);
		s_rvalid_o		: out std_logic;
		s_rready_i		: in std_logic
		);
	end component wrap_config;


	component gen_axi_M is
		generic (
		M_ADDR_WIDTH	: integer	:= 32;
		M_DATA_WIDTH	: integer	:= 32;
		M_TRANSACTIONS_NUM	: integer	:= 4
		);
		port (
        M_ADDR          : in std_logic_vector(M_DATA_WIDTH-1 downto 0);
        M_LENGTH        : in std_logic_vector(M_DATA_WIDTH/2-1 downto 0);
        M_DONE          : out std_logic;
		init_axi_txn	: in std_logic;
		m_aclk_i		: in std_logic;
		m_aresetn_i		: in std_logic;
		m_awaddr_o		: out std_logic_vector(M_ADDR_WIDTH-1 downto 0);
		m_awprot_o		: out std_logic_vector(2 downto 0);
		m_awcache_o		: out std_logic_vector(3 downto 0);
		m_awvalid_o		: out std_logic;
		m_awready_i		: in std_logic;
		m_wdata_o		: out std_logic_vector(M_DATA_WIDTH-1 downto 0);
		m_wstrb_o		: out std_logic_vector(M_DATA_WIDTH/8-1 downto 0);
		m_wvalid_o		: out std_logic;
		m_wready_i		: in std_logic;
		m_bresp_i		: in std_logic_vector(1 downto 0);
		m_bvalid_i		: in std_logic;
		m_bready_o		: out std_logic;
		m_araddr_o		: out std_logic_vector(M_ADDR_WIDTH-1 downto 0);
		m_arprot_o		: out std_logic_vector(2 downto 0);
		m_arcache_o		: out std_logic_vector(3 downto 0);
		m_arvalid_o		: out std_logic;
		m_arready_i		: in std_logic;
		m_rdata_i		: in std_logic_vector(M_DATA_WIDTH-1 downto 0);
		m_rresp_i		: in std_logic_vector(1 downto 0);
		m_rvalid_i		: in std_logic;
		m_rready_o		: out std_logic
		);
	end component gen_axi_M;


begin

-- Instantiation of Axi Bus Interface S00_AXI
wrap_config_0 : wrap_config
 	generic map (
 		S_DATA_WIDTH	=> S_DATA_WIDTH,
 		S_ADDR_WIDTH	=> S_ADDR_WIDTH
 	)
 	port map (
		EN      => start_transfer_s,
		RST		=> reset_s,
        ADDR    => start_add_s,
        LENGTH  => size_s,
        DONE    => done_s,
  	    Abort_Access	=> abort_s ,
		Error_Code		=> err_typ_reg,
 		s_aclk_i		=> s_axi_aclk,
 		s_aresetn_i		=> s_axi_aresetn,
 		s_awaddr_i		=> s_axi_awaddr,
 		s_awprot_i		=> s_axi_awprot,
 		s_awvalid_i		=> s_axi_awvalid,
 		s_awready_o		=> s_axi_awready,
 		s_wdata_i		=> s_axi_wdata,
 		s_wstrb_i		=> s_axi_wstrb,
 		s_wvalid_i		=> s_axi_wvalid,
 		s_wready_o		=> s_axi_wready,
 		s_bresp_o		=> s_axi_bresp,
 		s_bvalid_o		=> s_axi_bvalid,
 		s_bready_i		=> s_axi_bready,
 		s_araddr_i		=> s_axi_araddr,
 		s_arprot_i		=> s_axi_arprot,
 		s_arvalid_i		=> s_axi_arvalid,
 		s_arready_o		=> s_axi_arready,
 		s_rdata_o		=> s_axi_rdata,
 		s_rresp_o		=> s_axi_rresp,
 		s_rvalid_o		=> s_axi_rvalid,
 		s_rready_i		=> s_axi_rready
	);


-- Instantiation of Axi Bus Interface M00_AXI
gen_axi_0 :gen_axi_M
	generic map (
		M_ADDR_WIDTH	=> M_AXI_ADDR_WIDTH,
		M_DATA_WIDTH	=> M_AXI_DATA_WIDTH,
		M_TRANSACTIONS_NUM	=> M_AXI_TRANSACTIONS_NUM
	)
	port map (
        M_ADDR			=> add_range_low_reg,
		M_LENGTH  		=> m_size_s,
        M_DONE    		=> m_done_s,
		init_axi_txn	=> m_en_s,
		m_aclk_i		=> m_axi_aclk,
		m_aresetn_i		=> m_aresetn_s,
		m_awaddr_o		=> m_awaddr_s,
		m_awprot_o		=> TZ_s,
		m_awcache_o		=> m_axi_awcache,
		m_awvalid_o		=> m_awvalid_s,
		m_awready_i		=> m_awready_s,
		m_wdata_o		=> m_wdata_s,
		m_wstrb_o		=> m_axi_wstrb,
		m_wvalid_o		=> m_wvalid_s,
		m_wready_i		=> m_axi_wready,
		m_bresp_i		=> m_axi_bresp,
		m_bvalid_i		=> m_axi_bvalid,
		m_bready_o		=> m_axi_bready,
		m_araddr_o		=> m_araddr_s,
		m_arprot_o		=> TZ_s,
		m_arcache_o		=> m_axi_arcache,
		m_arvalid_o		=> m_arvalid_s,
		m_arready_i		=> m_axi_arready,
		m_rdata_i		=> m_rdata_s,
		m_rresp_i		=> m_axi_rresp,
		m_rvalid_i		=> m_rvalid_s,
		m_rready_o		=> m_axi_rready
	);


	--Generate a pulse to enable transactions.
	process(m_axi_aclk, start_transfer_s)
		begin
			if (rising_edge (m_axi_aclk)) then
		    if (m_aresetn_s = '0' ) then
				start_operation <= '0';
			elsif(start_operation = '1')then
				start_operation <= '0';
		    else
				start_operation <= start_transfer_s;
		    end if;
		  end if;
		end process;

    -- Count number of transcations.
    process(m_axi_aclk)
        begin
            if (rising_edge (m_axi_aclk)) then
                if (m_aresetn_s = '0' or start_operation = '1' ) then
                    num_trans_reg <= (others => '0');
                elsif(m_arvalid_s = '1' and m_axi_awready = '1')then
                    num_trans_reg <= std_logic_vector(unsigned(num_trans_reg)+1);
	-- both read and write
                --elsif(m_awvalid_s = '1' and m_axi_arready = '1')then
                --    num_trans_reg <= std_logic_vector(unsigned(num_trans_reg)+1);
                end if;
            end if;
        end process;

	-- top level FSM
	TOP_EXECUTION_PROC:process(m_axi_aclk, state_reg_t)
		begin
			if (rising_edge (m_axi_aclk)) then
				if (m_aresetn_s = '0' ) then
					state_reg_t  <= IDLE;
					add_range_low_reg	<= x"0A000000";
					add_range_high_reg	<= x"0A000000";
					abort_s <= '0';
					valid_trans_s <= '0';
					done_s <= '0';
					m_size_s <= (others => '0');
					err_typ_reg <= (others => '0');
				else
			        -- state transition
					case (state_reg_t) is
						when IDLE =>
							if(start_operation = '1') then
								valid_trans_s <= '1';
								state_reg_t <= INIT_EXEC;
								add_range_low_reg <= start_add_s;
								add_range_high_reg <= std_logic_vector(unsigned(start_add_s)+ (unsigned (size_s)* 4));
								m_en_s <= '1';
								m_size_s (15 downto 0)  <= size_s;
								done_s <= '0';
								abort_s <= '0';
								err_typ_reg <= (others => '0');
							else
								valid_trans_s <= '0';
								state_reg_t <= IDLE;
								done_s <= done_s;
								abort_s <= abort_s;
								m_en_s <= '0';
							end if;
						when INIT_EXEC =>
							if(m_done_s = '1') then
								state_reg_t <= EXEC_DONE;
								valid_trans_s <= '0';

							elsif(num_trans_reg > total_trans_reg) then
								state_reg_t <= INIT_ABORT;
								valid_trans_s <= '0';
								err_typ_reg		<= "01";			-- exceeded permitted number of transcations
							elsif (valid_trans_s = '1' and m_awvalid_s = '1')then
								if (m_awaddr_s>= add_range_low_reg and m_awaddr_s<= add_range_high_reg) then
									valid_trans_s		<= '1';
									state_reg_t	<= INIT_EXEC;
								else
									valid_trans_s		<= '0';
									err_typ_reg			<= "10";		-- out-of-range write
									state_reg_t <= INIT_ABORT;
									abort_s <= '1';
								end if;
							elsif(valid_trans_s ='1' and m_arvalid_s ='1')then
								if (m_araddr_s >= add_range_low_reg and m_araddr_s <= add_range_high_reg) then
									valid_trans_s		<= '1';
									state_reg_t	<= init_exec;
								else
									valid_trans_s		<= '0';
									err_typ_reg			<= "11";		-- out-of-range read
									state_reg_t <= INIT_ABORT;
									abort_s <= '1';
								end if;
							end if;
						when INIT_ABORT =>
							done_s <= '0';
							abort_s <= '1';
							state_reg_t <= IDLE;
						when EXEC_DONE =>
							done_s <= '1';
							state_reg_t <= IDLE;
						when others =>
							state_reg_t <= IDLE;
					end case;
				end if;
			end if;
		end process;

    m_axi_arvalid <= m_arvalid_s;
    m_axi_awvalid <= m_awvalid_s;
	m_axi_awaddr <= m_awaddr_s;
	m_axi_araddr <= m_araddr_s;
    m_rvalid_s <= m_axi_rvalid when valid_trans_s = '1'
							   else '0';
    m_awready_s <= m_axi_awready when valid_trans_s = '1'
								 else '0';
	m_rdata_s <= m_axi_rdata when valid_trans_s = '1' and m_rvalid_s = '1'
							else (others => '0');
    m_axi_wvalid <= m_wvalid_s when valid_trans_s = '1'
						    else '0';
	m_axi_wdata <= m_wdata_s when valid_trans_s = '1' and m_wvalid_s = '1'
							else (others => '0');
	-- Trustzone secure for master is to assigned trustzone setting of the salve interface.
	-- Alternative would be to pass trustzone setting as a seperate setting through the control register.
	m_axi_awprot <= s_axi_awprot when valid_trans_s = '1'
								 else "010";
	m_axi_arprot <= s_axi_arprot when valid_trans_s = '1'
								 else "010";
	alarm <= abort_s;
	-- Reset the master transcation if error is detected
	m_aresetn_s <= '0' when abort_s = '1'
						or reset_s = '1'
						else m_axi_aresetn;
	-- only read length
	total_trans_reg <=  std_logic_vector(unsigned(m_size_s));

end rtl;
