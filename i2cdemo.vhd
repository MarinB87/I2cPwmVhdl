--###############################
--# Project Name : I2C Slave
--# File         : i2cdemo.vhd
--# Project      : ic2 slave + Single port RAM 256 * 8 (ALTERA compatible)
--# Engineer     : Philippe THIRION
--# Modification History
--# Modified by Marin Basic
--# This is now a top level module for I2C controlled PWM
--# Extension for PWM is added
--###############################

library IEEE;
use IEEE.std_logic_1164.all;

entity I2CPWM is
  GENERIC(
      channels        : INTEGER := 64);         --number of output pwms and channels
	port(
		--MCLK         : in	std_logic;
		nRST         : in	std_logic;
		SCL          : inout std_logic;
		SDA          : inout std_logic;
		PWM_clock    : in STD_LOGIC;
		PWM_output   : out STD_LOGIC_VECTOR(channels-1 DOWNTO 0)
	);
end I2CPWM;

architecture rtl of I2CPWM is
-- COMPONENTS --
	component I2CSLAVE
		generic( DEVICE: std_logic_vector(7 downto 0));
		port(
			MCLK		: in	std_logic;
			nRST		: in	std_logic;
			SDA_IN		: in	std_logic;
			SCL_IN		: in	std_logic;
			SDA_OUT		: out	std_logic;
			SCL_OUT		: out	std_logic;
			ADDRESS		: out	std_logic_vector(7 downto 0);
			DATA_OUT	: out	std_logic_vector(7 downto 0);
			DATA_IN		: in	std_logic_vector(7 downto 0);
			WR			: out	std_logic;
			RD			: out	std_logic
		);
	end component;
	
	component sp256x8
		port(
		   pwm_clk      : in   STD_LOGIC;
		   pwm_sig_out  : out  STD_LOGIC_VECTOR(channels-1 DOWNTO 0);
			address      : in   std_logic_vector(7 downto 0);
			clock		    : in   std_logic;
			data		    : in   std_logic_vector(7 downto 0);
			wren		    : in   std_logic;
			q			    : out  std_logic_vector(7 downto 0)
		);
	end component;
	
	-- SIGNALS --
	signal SDA_IN		: std_logic;
	signal SCL_IN		: std_logic;
	signal SDA_OUT		: std_logic;
	signal SCL_OUT		: std_logic;
	signal ADDRESS		: std_logic_vector(7 downto 0);
	signal DATA_OUT   : std_logic_vector(7 downto 0);
	signal DATA_IN		: std_logic_vector(7 downto 0);
	signal WR			: std_logic;
	signal RD			: std_logic;
	
	signal q			   : std_logic_vector(7 downto 0);
	signal BUFFER8		: std_logic_vector(7 downto 0);

begin
	-- PORT MAP --
	I_RAM : sp256x8
		port map (
			address	   => ADDRESS,
			clock	      => PWM_clock,
			data        => DATA_OUT,
			wren        => WR,
			q           => q,
			pwm_clk     => PWM_clock,
			pwm_sig_out => PWM_output
		);
	I_I2CITF : I2CSLAVE
		generic map (DEVICE => x"38")
		port map (
			MCLK		=> PWM_clock,
			nRST		=> nRST,
			SDA_IN		=> SDA_IN,
			SCL_IN		=> SCL_IN,
			SDA_OUT		=> SDA_OUT,
			SCL_OUT		=> SCL_OUT,
			ADDRESS		=> ADDRESS,
			DATA_OUT	=> DATA_OUT,
			DATA_IN		=> DATA_IN,
			WR			=> WR,
			RD			=> RD
		);
	
	B8 : process(PWM_clock,nRST)
	begin
		if (nRST = '0') then
			BUFFER8 <= (others => '0');
		elsif (PWM_clock'event and PWM_clock='1') then
			if (RD = '1') then
				BUFFER8 <= q;
			end if;
		end if;
	end process B8;
	
	DATA_IN <= BUFFER8;
	
	--  open drain PAD pull up 1.5K needed
	SCL <= 'Z' when SCL_OUT='1' else '0';
	SCL_IN <= to_UX01(SCL);
	SDA <= 'Z' when SDA_OUT='1' else '0';
	SDA_IN <= to_UX01(SDA);

end rtl;

