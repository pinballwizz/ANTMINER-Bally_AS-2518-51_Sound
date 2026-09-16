---------------------------------------------------------------------------------
--                    Bally AS-2518-51 Sound Board - ANTMINER S9
--
--                           Modified for ANTMINER S9 
--                               by pinballwiz
--                                 10/09/2026
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;
---------------------------------------------------------------------------------
entity AS_2518_51_antminer is
port(
	clock_50    : in std_logic;
   	I_RESET     : in std_logic;
	O_AUDIO_L 	: out std_logic;
	O_AUDIO_R 	: out std_logic;
   	ps2_clk     : inout std_logic;
	ps2_dat     : inout std_logic;
	led         : out std_logic_vector(7 downto 0);
	aled        : out std_logic_vector(3 downto 0)
);
end AS_2518_51_antminer;
--------------------------------------------------------------------------------
architecture struct of AS_2518_51_antminer is
 
 signal	clock_48    : std_logic;
 signal	clock_24    : std_logic;
 signal	clock_7     : std_logic;
 signal clock_3p58	: std_logic;
 signal clock_1p79	: std_logic;
 signal cpu_clk   	: std_logic;
 --
 signal snd_ctrl    : std_logic_vector(4 downto 0);
 signal reset	    : std_logic;
 --
 signal audio	    : std_logic_vector(7 downto 0);
 signal audio_pwm   : std_logic;
 --
 signal codeready	: std_logic;
 signal scancode	: std_logic_vector(9 downto 0);
 --
 constant CLOCK_FREQ    : integer := 27E6;
 signal counter_clk     : std_logic_vector(25 downto 0);
 signal clock_4hz       : std_logic;
 signal AD              : std_logic_vector(15 downto 0);
------------------------------------------------------------------------------
component AS_2518_51_Clocks
port(
  clk_out1          : out    std_logic;
  clk_out2          : out    std_logic;
  clk_in1           : in     std_logic
 );
end component;
------------------------------------------------------------------------------
begin

 reset <= not I_RESET;
 aled(3 downto 0) <= "1111"; -- turn unused onboard leds off
------------------------------------------------------------------------------
Clocks: AS_2518_51_Clocks
    port map (
        clk_in1   => clock_50,
        clk_out1  => clock_48,
        clk_out2  => clock_7
    );
------------------------------------------------------------------------------
-- Clocks Divide

process (clock_48)
begin
 if rising_edge(clock_48) then
	clock_24  <= not clock_24;
 end if;
end process;
--
process (clock_7)
begin
 if rising_edge(clock_7) then
	clock_3p58  <= not clock_3p58;
 end if;
end process;
--
process (clock_3p58)
begin
 if rising_edge(clock_3p58) then
	clock_1p79  <= not clock_1p79;
 end if;
end process;
--
process (clock_1p79)
begin
 if rising_edge(clock_1p79) then
	cpu_clk  <= not cpu_clk;
 end if;
end process;
------------------------------------------------------------------------------
-- Main

Core: entity work.AS_2518_51
port map(
	clk_179     => clock_1p79,
	cpu_clk     => cpu_clk,
	reset_l     => I_RESET,
	addr_i      => snd_ctrl,
	snd_int_i   => not scancode(8),
	test_sw_l   => '1',
	audio       => audio,
	AD		    => AD
	);
---------------------------------------------------------------------
-- Keyboard

keyboard: entity work.Keyboard
port map(
		Reset     => reset,
		Clock     => clock_48,
		PS2Clock  => ps2_clk,
		PS2Data   => ps2_dat,
		CodeReady => codeready,
		ScanCode  => scancode
		);	
-----------------------------------------------------------------------------
-- Input

scan_decode : process(scancode)
begin
    snd_ctrl <= "11111"; -- idle

    if scancode(8) = '0' then
        case scancode(7 downto 0) is

            -- 0-7
            when x"16" => snd_ctrl <= "00000"; -- 1
            when x"1E" => snd_ctrl <= "00001"; -- 2
            when x"26" => snd_ctrl <= "00010"; -- 3
            when x"25" => snd_ctrl <= "00011"; -- 4
            when x"2E" => snd_ctrl <= "00100"; -- 5
            when x"36" => snd_ctrl <= "00101"; -- 6
            when x"3D" => snd_ctrl <= "00110"; -- 7
            when x"3E" => snd_ctrl <= "00111"; -- 8

            -- 8-15
            when x"15" => snd_ctrl <= "01000"; -- Q
            when x"1D" => snd_ctrl <= "01001"; -- W
            when x"24" => snd_ctrl <= "01010"; -- E
            when x"2D" => snd_ctrl <= "01011"; -- R
            when x"2C" => snd_ctrl <= "01100"; -- T
            when x"35" => snd_ctrl <= "01101"; -- Y
            when x"3C" => snd_ctrl <= "01110"; -- U
            when x"43" => snd_ctrl <= "01111"; -- I

            -- 16-23
            when x"1C" => snd_ctrl <= "10000"; -- A
            when x"1B" => snd_ctrl <= "10001"; -- S
            when x"23" => snd_ctrl <= "10010"; -- D
            when x"2B" => snd_ctrl <= "10011"; -- F
            when x"34" => snd_ctrl <= "10100"; -- G
            when x"33" => snd_ctrl <= "10101"; -- H
            when x"3B" => snd_ctrl <= "10110"; -- J
            when x"42" => snd_ctrl <= "10111"; -- K

            -- 24-31
            when x"1A" => snd_ctrl <= "11000"; -- Z
            when x"22" => snd_ctrl <= "11001"; -- X
            when x"21" => snd_ctrl <= "11010"; -- C
            when x"2A" => snd_ctrl <= "11011"; -- V
            when x"32" => snd_ctrl <= "11100"; -- B
            when x"31" => snd_ctrl <= "11101"; -- N
            when x"3A" => snd_ctrl <= "11110"; -- M
            when x"41" => snd_ctrl <= "11111"; -- ,

            when others => null;
        end case;
    end if;
end process;
--------------------------------------------------------
-- DAC

Audio_DAC: entity work.dac
port map(
   clk_i   	=> clock_24,
   res_n_i 	=> I_RESET,
   dac_i   	=> audio,
   dac_o   	=> audio_pwm
	);

O_AUDIO_L <= audio_pwm;
O_AUDIO_R <= audio_pwm;	
------------------------------------------------------------------------------
-- Debug

process(reset, clock_24)
begin
  if reset = '1' then
   clock_4hz <= '0';
   counter_clk <= (others => '0');
  else
    if rising_edge(clock_24) then
      if counter_clk = CLOCK_FREQ/8 then
        counter_clk <= (others => '0');
        clock_4hz <= not clock_4hz;
        led(7 downto 0) <= not AD(11 downto 4);
      else
        counter_clk <= counter_clk + 1;
      end if;
    end if;
  end if;
end process;	
----------------------------------------------------------------------------
end struct;