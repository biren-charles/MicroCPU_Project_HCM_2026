----------------------------------------------------------------------------------
-- Company: University of Luxembourg
-- Engineer: creation by Prof. Bernard Steenis and use of students : Charles Biren, Hamza Bouziane & Mohamed Lemoussi
-- Create Date: 16.01.2026
-- Design Name: MicroCPU-Lab6
-- Module Name: interface
-- Description: interface for Lab6

-- Last Revision: 16.01.2026
-- Revision 0.01 - File Created
-- Additional Comments: none 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.ALL;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity interface is
--  Port ( );
Port (
  io_in : out std_logic_vector(31 downto 0);
   -- 31:28 = unused
   -- 27:24 = buttons
   -- 23:16 = unused
   -- 15:0 = switches
  io_out : in std_logic_vector(31 downto 0);
   -- 31:24 = disp left bank
   -- 23:16 = disp right bank
   -- 15:0 = leds
  clk : in std_logic; 
  btnU,btnL,btnR,btnD : in std_logic;
  sw : in std_logic_vector(15 downto 0);
  led : out std_logic_vector(15 downto 0);
  seg : out std_logic_vector(6 downto 0);
  dp : out std_logic; 
  an : out std_logic_vector(3 downto 0)
  );  
end interface;

architecture Behavioral of interface is
signal clkdiv : std_logic_vector(15 downto 0);
signal dispsel : std_logic_vector(3 downto 0);
signal dpseg : std_logic_vector(7 downto 0);
begin
-- clock divider
pdiv: process(clk) begin if rising_edge(clk) then clkdiv<=clkdiv+1; end if; end process;
-- buttons
pbut: process(clkdiv(15)) begin if rising_edge(clkdiv(15)) then io_in(27 downto 24)<=btnU&btnL&btnR&btnD; end if; end process; 
io_in(31 downto 28)<=x"0";
io_in(23 downto 16)<=x"00";
-- switches
io_in(15 downto 0)<=sw;
-- leds
led<=io_out(15 downto 0);
-- 7seg display
with clkdiv(15 downto 14) select 
  dispsel <= io_out(31 downto 28) when "00", io_out(27 downto 24) when "01", io_out(23 downto 20) when "10", io_out(19 downto 16) when "11",
  x"0" when others;
with clkdiv(15 downto 14) select
  an <= x"7" when "00", x"b" when "01", x"d" when "10", x"e" when "11",
  x"f" when others;
with dispsel select 
  dpseg <= x"c0" when x"0", x"f9" when x"1", x"a4" when x"2", x"b0" when x"3", x"99" when x"4", x"92" when x"5", 
           x"82" when x"6", x"f8" when x"7", x"80" when x"8", x"90" when x"9", x"88" when x"a", x"83" when x"b",
           x"c6" when x"c", x"a1" when x"d", x"86" when x"e", x"8e" when x"f",
           x"ff" when others; 
seg<=dpseg(6 downto 0);
dp<='1';   
end Behavioral;
