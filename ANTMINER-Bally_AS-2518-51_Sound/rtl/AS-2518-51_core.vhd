------------------------------------------------------
--              Bally AS-2518-51 Sound
--            modified by pinballwiz 2026
------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
------------------------------------------------------
entity AS_2518_51 is
	port(
		clk_179		: in 	std_logic; -- 1.79mhz
		cpu_clk		: in 	std_logic; -- 0.89mhz
		reset_l		: in	std_logic;
		test_sw_l	: in 	std_logic;
		addr_i		: in 	std_logic_vector(4 downto 0);
		snd_int_i	: in 	std_logic;
		audio		: out   std_logic_vector(7 downto 0);
		AD			: out	std_logic_vector(15 downto 0)
		);
end;
------------------------------------------------------
architecture rtl of AS_2518_51 is 

signal reset_h		: 	std_logic;
--
signal cpu_addr	    : 	std_logic_vector(15 downto 0);
signal cpu_din		: 	std_logic_vector(7 downto 0) := x"FF";
signal cpu_dout	    : 	std_logic_vector(7 downto 0);
signal cpu_rw		: 	std_logic;
signal cpu_vma		: 	std_logic;
signal cpu_irq		: 	std_logic;
signal cpu_nmi		:	std_logic;
--
signal pia_pa_i	    :   std_logic_vector(7 downto 0) := x"FF";
signal pia_pa_o	    : 	std_logic_vector(7 downto 0);
signal pia_pb_i	    :	std_logic_vector(7 downto 0) := x"FF";
signal pia_pb_o	    :   std_logic_vector(7 downto 0);
signal pia_dout	    :	std_logic_vector(7 downto 0);
signal pia_irq_a	:	std_logic;
signal pia_irq_b	:	std_logic;
signal pia_cb1		:   std_logic;
signal pia_cs		:	std_logic;
--
signal ay_pa_i		:	std_logic_vector(7 downto 0);
--
signal rom_dout	    :	std_logic_vector(7 downto 0);
signal rom_cs		: 	std_logic;
--
signal ram_dout 	: 	std_logic_vector(7 downto 0);
signal ram_cs		:	std_logic;
----------------------------------------------------------------
begin

reset_h <= (not reset_l);
AD <= cpu_addr;
-------------------------------------------------------------
cpu_irq <= pia_irq_a or pia_irq_b;
cpu_nmi <= not test_sw_l;
rom_cs <= cpu_addr(12) and cpu_vma;
pia_cs <= cpu_addr(7) and (not cpu_addr(12)) and cpu_vma;
ram_cs <= (not cpu_addr(7)) and (not cpu_addr(12)) and cpu_vma;
-------------------------------------------------------------
cpu_din <= 
	pia_dout when pia_cs = '1' else
	rom_dout when rom_cs = '1' else
	ram_dout when ram_cs = '1' else
	x"FF";
-------------------------------------------------------------
U3: entity work.cpu68
port map(
	clk     => cpu_clk,
	rst     => reset_h,
	rw      => cpu_rw,
	vma     => cpu_vma,
	address => cpu_addr,
	data_in => cpu_din,
	data_out => cpu_dout,
	hold    => '0',
	halt    => '0',
	irq     => cpu_irq,
	nmi     => cpu_nmi
);
------------------------------------------------------------
U4: entity work.U4_ROM
port map(
	clk     => cpu_clk,
	addr    => cpu_addr(10 downto 0),
	data	=> rom_dout
	);
------------------------------------------------------------	
U2: entity work.PIA6821
port map(
	clk     => cpu_clk,   
    rst     => reset_h,     
    cs      => pia_cs,     
    rw      => cpu_rw,    
    addr    => cpu_addr(1 downto 0),     
    data_in => cpu_dout,  
	data_out => pia_dout, 
	irqa    => pia_irq_a,   
	irqb    => pia_irq_b,    
	pa_i    => pia_pa_i,    
	pa_o    => pia_pa_o,    
	ca1     => snd_int_i,    
	ca2_i   => '1',    
	ca2_o   => open,    
	pb_i    => x"FF",    
	pb_o    => pia_pb_o,    
	cb1     => pia_cb1,    
	cb2_i   => '0',  
	cb2_o   => open   
);
---------------------------------------------------------
U10: entity work.m6810
port map(
   clk      => cpu_clk, 
   rst      => reset_h,     
   address  => cpu_addr(6 downto 0), 
   cs       => ram_cs,      
   rw       => cpu_rw,       
   data_in  => cpu_dout, 
   data_out => ram_dout
	);
---------------------------------------------------------
ay_pa_i(4 downto 0) <= not addr_i;
ay_pa_i(7 downto 5) <= "000";	
---------------------------------------------------------
AY_3_8910: entity work.YM2149
port map(
  -- data bus
  I_DA       => pia_pa_o,       -- in  std_logic_vector(7 downto 0);
  O_DA       => pia_pa_i,       -- out std_logic_vector(7 downto 0);
  O_DA_OE_L  => open,           -- out std_logic;
  -- control
  I_A9_L     => '0',            -- in  std_logic;
  I_A8       => '1',            -- in  std_logic;
  I_BDIR     => pia_pb_o(1),    -- in  std_logic;
  I_BC2      => '1',            -- in  std_logic;
  I_BC1      => pia_pb_o(0),    -- in  std_logic;
  I_SEL_L    => '0',            -- in  std_logic;
  -- audio
  O_AUDIO    => audio,          -- out std_logic_vector(7 downto 0);
  O_CHAN     => open,           -- out std_logic_vector(1 downto 0);
  -- port a
  I_IOA      => ay_pa_i,        -- in  std_logic_vector(7 downto 0);
  O_IOA      => open,           -- out std_logic_vector(7 downto 0);
  O_IOA_OE_L => open,           -- out std_logic;
  -- port b
  I_IOB      => x"FF",          -- in  std_logic_vector(7 downto 0);
  O_IOB      => open,           -- out std_logic_vector(7 downto 0);
  O_IOB_OE_L => open,           -- out std_logic;
  -- clock
  ENA        => '1',            -- cpu_ena,  -- in  std_logic; -- clock enable for higher speed operation
  RESET_L    => reset_l,        -- in  std_logic;
  CLK        => clk_179         -- in  std_logic  -- note 6 Mhz
);
--------------------------------------------------------
end rtl;