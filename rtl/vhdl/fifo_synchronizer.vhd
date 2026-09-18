library IEEE;
	use IEEE.std_logic_1164.all;
	use IEEE.numeric_std.all;

entity fifo_synchronizer is
	generic	(
		ADDR_WIDTH: integer:=4 -- data address in Fifo is 4 bits.
	);
	port (
	clk		:in  std_logic;	
	rst_n	:in  std_logic;
	ptr_g	:in  std_logic_vector(ADDR_WIDTH downto 0); -- pointer before sync
	q2ptr_g	:out std_logic_vector(ADDR_WIDTH downto 0) --  pointer after sync
	);
end fifo_synchronizer;

architecture fifo_synchronizer_arc of fifo_synchronizer is
	signal q1ptr_g	: std_logic_vector(ADDR_WIDTH downto 0); -- after 1st Flip-Flops
begin
	-- Sequential Logic: Calulate q1/q2 Flip-Flops
	process(clk,rst_n)
	begin
		if (rst_n = '0') then -- Async reset: clear Flip-Flops
			q1ptr_g	<= (others => '0');
			q2ptr_g	<= (others => '0');
		elsif rising_edge(clk) then -- update Flip-Flops to next value
			q2ptr_g <= q1ptr_g;
			q1ptr_g	<= ptr_g;
		end if;
	end process;	

end fifo_synchronizer_arc;