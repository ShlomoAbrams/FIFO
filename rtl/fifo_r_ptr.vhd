library IEEE;
	use IEEE.std_logic_1164.all;
	use IEEE.numeric_std.all;

entity fifo_r_ptr is
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
end fifo_r_ptr;

architecture fifo_r_ptr_arc of fifo_r_ptr is
	-- Current state (Flip-Flops) MSB pointer bit for full comparision.
	signal rptr_b_cur	: unsigned(ADDR_WIDTH downto 0);
	signal rptr_g_cur	: std_logic_vector(ADDR_WIDTH downto 0);
	signal rempty_cur	: std_logic;
	-- Next State wires (combinational math)
	signal rptr_b_next	: unsigned(ADDR_WIDTH downto 0);
	signal rptr_g_next	: std_logic_vector(ADDR_WIDTH downto 0);
	signal rempty_next	: std_logic;
begin
	rempty <= rempty_cur;
	raddr <= std_logic_vector(rptr_b_cur(ADDR_WIDTH-1 downto 0)); -- remove MSB for address
	rptr_g<= rptr_g_cur;
	-- Conbinational Math
	rptr_b_next	<= rptr_b_cur + 1 when (rinc = '1' and rempty_cur = '0') else rptr_b_cur; -- Calulate next rptr_b only if we need to increment and fifo isnt full:
	rptr_g_next	<= std_logic_vector(rptr_b_next) xor ('0' & std_logic_vector(rptr_b_next(ADDR_WIDTH downto 1))); -- Calulate next rptr_g by shifting right and doing Xor with itself
	rempty_next <= '1' when (rptr_g_next = r2q_wptr) else '0'; -- Empty_next: Compare Next Gray Pointer to Write pointer. Full when: Top 2 bits are opposite, all bottom bits are identical.
	-- Sequential Logic: Calulate write pointers and full flag
	process(rclk,rrst_n)
	begin
		if (rrst_n = '0') then -- Async reset: clear Flip-Flops
			rptr_b_cur 	<= (others => '0');
			rptr_g_cur	<= (others => '0');
			rempty_cur	<= '1';
		elsif rising_edge(rclk) then -- update Flip-Flops to next value
			rptr_b_cur 	<= rptr_b_next;
			rptr_g_cur	<= rptr_g_next	;
			rempty_cur	<= rempty_next;
		end if;
	end process;	
end fifo_r_ptr_arc;