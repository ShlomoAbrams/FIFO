library IEEE;
	use IEEE.std_logic_1164.all;
	use IEEE.numeric_std.all;

entity fifo_w_ptr is
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
end fifo_w_ptr;

architecture fifo_w_ptr_arc of fifo_w_ptr is
	-- Current state (Flip-Flops) MSB pointer bit for full comparision.
	signal wptr_b_cur	: unsigned(ADDR_WIDTH downto 0);
	signal wptr_g_cur	: std_logic_vector(ADDR_WIDTH downto 0);
	signal wfull_cur	: std_logic;
	-- Next State wires (combinational math)
	signal wptr_b_next	: unsigned(ADDR_WIDTH downto 0);
	signal wptr_g_next	: std_logic_vector(ADDR_WIDTH downto 0);
	signal wfull_next	: std_logic;
begin
	wfull <= wfull_cur;
	waddr <= std_logic_vector(wptr_b_cur(ADDR_WIDTH-1 downto 0)); -- remove MSB for address
	wptr_g<= wptr_g_cur;
	-- Conbinational Math
	wptr_b_next	<= wptr_b_cur + 1 when (winc = '1' and wfull_cur = '0') else wptr_b_cur; -- Calulate next wptr_b only if we need to increment and fifo isnt full:
	wptr_g_next <= std_logic_vector(wptr_b_next) xor ('0' & std_logic_vector(wptr_b_next(ADDR_WIDTH downto 1))); -- Calulate next wptr_g by shifting right and doing Xor with itself
	wfull_next 	<= '1' when (wptr_g_next(ADDR_WIDTH) /= w2q_rptr(ADDR_WIDTH) and wptr_g_next(ADDR_WIDTH-1) /= w2q_rptr(ADDR_WIDTH-1) and wptr_g_next(ADDR_WIDTH-2 downto 0) = w2q_rptr(ADDR_WIDTH-2 downto 0)) else '0'; -- Full_next: Compare Next Gray Pointer to Read pointer. Full when: Top 2 bits are opposite, all bottom bits are identical.
	-- Sequential Logic: Calulate write pointers and full flag
	process(wclk,wrst_n)
	begin
		if (wrst_n = '0') then -- Async reset: clear Flip-Flops
			wptr_b_cur 	<= (others => '0');
			wptr_g_cur	<= (others => '0');
			wfull_cur	<= '0';
		elsif rising_edge(wclk) then -- update Flip-Flops to next value
			wptr_b_cur 	<= wptr_b_next;
			wptr_g_cur	<= wptr_g_next;
			wfull_cur	<= wfull_next;
		end if;
	end process;	
end fifo_w_ptr_arc;