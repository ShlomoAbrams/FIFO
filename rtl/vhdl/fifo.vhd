library IEEE;
	use IEEE.std_logic_1164.all;
	use IEEE.numeric_std.all;

entity fifo is
	generic	(
		DATA_WIDTH: integer:=8; -- input/output data is 8 bits.
		ADDR_WIDTH: integer:=4 	-- data address in Fifo is 4 bits.
	);
	port (
	-- Write Side
	wclk	:in  std_logic;	
	wrst_n	:in  std_logic;
	winc	:in  std_logic;
	wfull	:out std_logic;
	wdata	:in  std_logic_vector(DATA_WIDTH-1 downto 0);
	-- Read Side
	rclk	:in  std_logic;
	rrst_n	:in  std_logic;
	rinc	:in  std_logic;
	rempty	:out std_logic;
	rdata 	:out std_logic_vector(DATA_WIDTH-1 downto 0)
	
	);
end fifo;

architecture fifo_arc of fifo is
component fifo_mem is
	generic	(
		DATA_WIDTH: integer:=8; -- input/output data is 8 bits.
		ADDR_WIDTH: integer:=4 	-- data address in Fifo is 4 bits.
	);
	port (
	-- Write Side
	wclk	:in  std_logic;	
	wclken	:in  std_logic;
	waddr	:in  std_logic_vector(ADDR_WIDTH-1 downto 0);
	wdata	:in  std_logic_vector(DATA_WIDTH-1 downto 0);	
	-- Read Side
	rclk	:in  std_logic;
	rclken	:in  std_logic;
	raddr	:in  std_logic_vector(ADDR_WIDTH-1 downto 0);
	rdata 	:out std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end component;
component fifo_w_ptr is 
	generic	(
		ADDR_WIDTH: integer:=4 	-- data address in Fifo is 4 bits.
	);
	port (
	wclk		:in  std_logic;	
	wrst_n		:in  std_logic;
	winc		:in  std_logic;
	w2q_rptr	:in  std_logic_vector(ADDR_WIDTH downto 0); -- read pointer after sync
	wfull		:out std_logic;
	waddr		:out std_logic_vector(ADDR_WIDTH-1 downto 0); -- N bits to mem
	wptr_g		:out std_logic_vector(ADDR_WIDTH downto 0) -- N+1 Gray bits to sync
	);
end component;
component fifo_r_ptr is
generic	(
		ADDR_WIDTH: integer:=4 -- data address in Fifo is 4 bits.
	);
	port (
	rclk		:in  std_logic;	
	rrst_n		:in  std_logic;
	rinc		:in  std_logic;
	r2q_wptr	:in  std_logic_vector(ADDR_WIDTH downto 0); -- write pointer after sync
	rempty		:out std_logic;
	raddr		:out std_logic_vector(ADDR_WIDTH-1 downto 0); -- N bits to mem
	rptr_g		:out std_logic_vector(ADDR_WIDTH downto 0) -- N+1 Gray bits to sync
	);
end component;
component fifo_synchronizer is 
generic	(
		ADDR_WIDTH: integer:=4 -- data address in Fifo is 4 bits.
	);
	port (
	clk		:in  std_logic;	
	rst_n	:in  std_logic;
	ptr_g	:in  std_logic_vector(ADDR_WIDTH downto 0); -- pointer before sync
	q2ptr_g	:out std_logic_vector(ADDR_WIDTH downto 0) --  pointer after sync
	);
end component;
-- Internal Signal wires
	signal wfull_wire	: std_logic; -- Full flag
	signal rempty_wire	: std_logic; -- Empty flag
	signal wclken_wire	: std_logic; -- write clock enable
	signal rclken_wire	: std_logic; -- read clock enable
	signal waddr_wire	: std_logic_vector(ADDR_WIDTH-1 downto 0)	; -- write address 
	signal raddr_wire	: std_logic_vector(ADDR_WIDTH-1 downto 0)	; -- read address
	signal rptr_wire	: std_logic_vector(ADDR_WIDTH downto 0)		; -- read pointer (gray)
	signal wptr_wire	: std_logic_vector(ADDR_WIDTH downto 0)		; -- write pointer (gray)
	signal w2q_rptr		: std_logic_vector(ADDR_WIDTH downto 0)		; -- post sync read pointer (gray)
	signal r2q_wptr		: std_logic_vector(ADDR_WIDTH downto 0)		; -- post sync write pointer (gray)

begin
	wfull <= wfull_wire;
	rempty <= rempty_wire;
	-- And_Logic_gates:
	wclken_wire <= winc and not(wfull_wire); -- enable write (And Gate - winc and not full) 
	rclken_wire <= rinc and not(rempty_wire);-- enable read (And Gate - rinc and not empty) 

	-- Connect Pins to wires:
	fifo_mem_unit: fifo_mem
		generic map (
			DATA_WIDTH => DATA_WIDTH,-- set internal data width to top level. 
			ADDR_WIDTH => ADDR_WIDTH -- set internal address width to top level. 
			)
		port map (
			-- write side
			wclk	=> wclk, 		-- connect internaL pin to external wire.
			wclken	=> wclken_wire, -- connect internal pin to internal wire.
			waddr	=> waddr_wire,	-- connect internal pin to internal wire.
			wdata	=> wdata,		-- connect internal pin to external wire.
			-- read side
			rclk	=> rclk, 		-- connect internal pin to external wire.
			rclken	=> rclken_wire, -- connect internal pin to internal wire.
			raddr	=> raddr_wire,	-- connect internal pin to internal wire.
			rdata	=> rdata		-- connect internal pin to external wire.
			);
	wptr_full_unit: fifo_w_ptr	
		generic	map (
			ADDR_WIDTH => ADDR_WIDTH-- set internal address width to top level.  
		)
		port map (
			wclk	=> wclk, 		-- connect internal pin to external wire.
			wrst_n	=> wrst_n, 		-- connect internal pin to external wire.
			winc	=> winc,		-- connect internal pin to external wire.
			w2q_rptr=> w2q_rptr,	-- connect internal pin to internal wire.
			wfull	=> wfull_wire,	-- connect internal pin to internal wire.
			waddr	=> waddr_wire,	-- connect internal pin to internal wire.
			wptr_g	=> wptr_wire	-- connect internal pin to internal wire.
		);
		rptr_empty_unit: fifo_r_ptr	
		generic	map (
			ADDR_WIDTH => ADDR_WIDTH-- set internal address width to top level.  
		)
		port map (
			rclk	=> rclk, 		-- connect internal pin to external wire.
			rrst_n	=> rrst_n, 		-- connect internal pin to external wire.
			rinc	=> rinc,		-- connect internal pin to external wire.
			r2q_wptr=> r2q_wptr,	-- connect internal pin to internal wire.
			rempty	=> rempty_wire,	-- connect internal pin to internal wire.
			raddr	=> raddr_wire,	-- connect internal pin to internal wire.
			rptr_g	=> rptr_wire	-- connect internal pin to internal wire.
		);
	write_to_read_sync: fifo_synchronizer
		generic	map (
			ADDR_WIDTH => ADDR_WIDTH-- set internal address width to top level.  
		)
		port map (
			clk		=> rclk,		-- connect internal pin to external wire.
			rst_n	=> rrst_n,		-- connect internal pin to external wire.
			ptr_g	=> wptr_wire, 	-- connect internal pin to internal wire.
			q2ptr_g	=> r2q_wptr		-- connect internal pin to internal wire.
		);
	read_to_write_sync: fifo_synchronizer
		generic	map (
			ADDR_WIDTH => ADDR_WIDTH-- set internal address width to top level.  
		)
		port map (
			clk		=> wclk,		-- connect internal pin to external wire.
			rst_n	=> wrst_n,		-- connect internal pin to external wire.
			ptr_g	=> rptr_wire, 	-- connect internal pin to internal wire.
			q2ptr_g	=> w2q_rptr		-- connect internal pin to internal wire.
		);
		
end fifo_arc;