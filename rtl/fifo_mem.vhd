library IEEE;
	use IEEE.std_logic_1164.all;
	use IEEE.numeric_std.all;

entity fifo_mem is
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
end fifo_mem;

architecture fifo_mem_arc of fifo_mem is

	constant DEPTH:	integer:=2**ADDR_WIDTH; -- amount of data storage.
	-- Memory Array Type and Signal
	type mem_t is array (0 to DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0); 
	signal mem: mem_t;

begin
Wmem:process (wclk)
	begin
		if rising_edge(wclk) then
			if(wclken = '1') then -- Write if enable is high
				mem(to_integer(unsigned(waddr))) <= wdata; -- write to mem (convert bits to integer for address)
			end if;
		end if;	
	end process;			
			
Rmem:process (rclk)
	begin
		if rising_edge(rclk) then 
			if(rclken = '1') then
			rdata <= mem(to_integer(unsigned(raddr))); -- read from mem
			end if;
		end if;
	end process;	
end fifo_mem_arc;