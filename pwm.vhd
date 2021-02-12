--------------------------------------------------------------------------------
--
--   FileName:         pwm.vhd
--   Dependencies:     none
--   Design Software:  Quartus II 64-bit Version 12.1 Build 177 SJ Full Version
--
--   HDL CODE IS PROVIDED "AS IS."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 1.0 8/1/2013 Scott Larson
--     Initial Public Release
--   Version 2.0 1/9/2015 Scott Larson
--     Transistion between duty cycles always starts at center of pulse to avoid
--     anomalies in pulse shapes
--    
--   Modifications
--   Modified by Marin Basic. Number of PWM channels is extended to 64. Some
--   feautures such as rest line are removed.
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
use work.duty_cycle_pkg.all;

ENTITY pwm IS
  GENERIC(
      sys_clk         : INTEGER := 50_000_000; --system clock frequency in Hz
      pwm_freq        : INTEGER := 100_000;    --PWM switching frequency in Hz
      bits_resolution : INTEGER := 8;          --bits of resolution setting the duty cycle
      channels        : INTEGER := 64);         --number of output pwms and channels
  PORT(
      clk       : IN  STD_LOGIC;                                    --system clock
	   duty      : IN  duty_array(0 to channels - 1)(bits_resolution - 1 downto 0); --duty cycles
      pwm_out   : OUT STD_LOGIC_VECTOR(channels-1 DOWNTO 0));          --pwm outputs
END pwm;

ARCHITECTURE logic OF pwm IS
  CONSTANT  period     :  INTEGER := sys_clk/pwm_freq;                      --number of clocks in one pwm period
  TYPE counters IS ARRAY (0 TO channels-1) OF INTEGER RANGE 0 TO period - 1;  --data type for array of period counters
  SIGNAL  count        :  counters := (OTHERS => 0);        --array of period counters
  TYPE clocks_in_duties IS ARRAY (0 TO channels-1) OF INTEGER RANGE 0 TO period; --data type for array of clocks in duty cycle
  SIGNAL  clocks_in_duty    :  clocks_in_duties := (OTHERS => 0);                     --array of clocks in duty cycle
  
BEGIN
  PROCESS(clk)
  BEGIN
    IF(clk'EVENT AND clk = '1') THEN                                      --rising system clock edge
	  FOR i IN 0 to channels-1 LOOP                                            --create a counter for each phase
	     clocks_in_duty(i) <= conv_integer(duty(i))*period/(2**bits_resolution);   --determine clocks in duty cycle
      END LOOP;
	  
	  FOR i IN 0 to channels-1 LOOP                                            --create a counter for each phase
        IF(count(i) = period - 1) THEN                       --end of period reached
          count(i) <= 0;                                                         --reset counter
        ELSE                                                                   --end of period not reached
          count(i) <= count(i) + 1;                                              --increment counter
        END IF;
      END LOOP;
	  
      FOR i IN 0 to channels-1 LOOP                                            --control outputs for each phase
		  IF(conv_integer(duty(i)) = 255) THEN
		    pwm_out(i) <= '1';
		  ELSIF(count(i) >= clocks_in_duty(i)) THEN                           --phase's rising edge reached
          pwm_out(i) <= '0';                                                     --assert the pwm output
        ELSIF(count(i) < clocks_in_duty(i)) THEN                                       --phase's falling edge reached
          pwm_out(i) <= '1';                                                     --deassert the pwm output
        END IF;
      END LOOP;
    END IF;
  END PROCESS;
END logic;
