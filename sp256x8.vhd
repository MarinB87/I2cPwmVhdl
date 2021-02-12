--###############################
--# Project Name : I2C Slave
--# File         : ALTERA compatible
--# Project      : VHDL RAM model
--# Engineer     : Philippe THIRION
--# Modification History
--# Modified by Marin Basic
--# PWM component supporting 64 outputs is added
--###############################

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.duty_cycle_pkg.all;

entity sp256x8 is
   GENERIC(
      MEMORY_WIDTH : INTEGER := 8;
      MEMORY_SIZE  : INTEGER := 64);         --number of output pwms
	port(
	   pwm_clk      : in  std_logic;
		pwm_sig_out  : out STD_LOGIC_VECTOR(MEMORY_SIZE-1 DOWNTO 0);
		
		address	 : in	std_logic_vector(7 downto 0);
		clock		 : in	std_logic;
		data		 : in	std_logic_vector(7 downto 0);
		wren		 : in	std_logic;
		q		    : out	std_logic_vector(7 downto 0)
	);
end sp256x8;

architecture rtl of sp256x8 is

-- COMPONENTS --
	component PWM
		port(
        clk       : IN  STD_LOGIC;                                    --system clock
	     duty      : IN  duty_array(0 to MEMORY_SIZE - 1)(MEMORY_WIDTH - 1 downto 0); --duty cycles
        pwm_out   : OUT STD_LOGIC_VECTOR(MEMORY_SIZE-1 DOWNTO 0)         --pwm outputs
		);
	end component;

	--type memory is array(0 to MEMORY_SIZE - 1) of std_logic_vector(MEMORY_WIDTH - 1 downto 0);
	--signal mem : memory;
	signal mem : duty_array(0 to MEMORY_SIZE - 1)(MEMORY_WIDTH - 1 downto 0);
begin
    -- PORT MAP --
	I_PWM : PWM
		port map (
			clk      => pwm_clk,
			duty     => mem,
			pwm_out  => pwm_sig_out
		);
		
	RAM : process(clock)
	begin
		if (clock'event and clock='1') then
			if (wren = '0') then
				q <= mem(to_integer(unsigned(address)));
			else
				mem(to_integer(unsigned(address))) <= data;
				q <= data;  -- ????
			end if;
		end if;
	end process RAM;
end rtl;
