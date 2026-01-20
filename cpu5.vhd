----------------------------------------------------------------------------------
-- Company: University of Luxembourg
-- Engineer: creation by Prof. Bernard Steenis and change by students : Charles Biren, Hamza Bouziane & Mohamed Lemoussi
-- Create Date: 16.01.2026
-- Design Name: MicroCPU-Lab6
-- Module Name: CPU
-- Description: CPU with sequencer + transfers + jumps + ALU Lab6
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.ALL;  -- used for pc(7 downto 0) <= pc + 1

entity cpu is
Port (
  clk, rst : in  std_logic;
  wr       : out std_logic;
  addr     : out std_logic_vector(15 downto 0);
  datawr   : out std_logic_vector(7 downto 0);
  datard   : in  std_logic_vector(7 downto 0)
);
end cpu;

architecture Behavioral of cpu is

  signal state : std_logic_vector(3 downto 0);
  signal pc    : std_logic_vector(15 downto 0);
  signal ir    : std_logic_vector(23 downto 0);

  -- =========================
  -- Task 3: Register file
  -- =========================
  type regfile_type is array (0 to 7) of std_logic_vector(7 downto 0);
  signal reg : regfile_type;

  -- =========================
  -- Task 5: ALU state signals
  -- =========================
  signal aluop2   : std_logic_vector(7 downto 0);
  signal alucode  : std_logic_vector(3 downto 0);
  signal alures   : std_logic_vector(7 downto 0);
  signal aluflags : std_logic_vector(3 downto 0);

begin

  --------------------------------------------------------------------
  -- SEQUENCER (FSM)
  --------------------------------------------------------------------
  pseq : process(clk, rst)
    variable i : integer;
  begin
    if rst = '1' then
      state <= x"0";
      pc    <= (others => '0');
      ir    <= (others => '0');
      addr  <= (others => '0');
      wr    <= '0';
      datawr <= (others => '0');
      aluop2  <= (others => '0');
      alucode <= (others => '0');
      for i in 0 to 7 loop
        reg(i) <= (others => '0');
      end loop;

    elsif rising_edge(clk) then
      case state is

        when x"0" =>
          -- Init
          state <= x"1";
          pc    <= x"0000";
          addr  <= x"0000";
          wr    <= '0';

        when x"1" =>
          -- Fetch first byte
          ir(23 downto 16) <= datard;
          pc(7 downto 0)   <= pc(7 downto 0) + 1;

          ----------------------------------------------------------------
          -- Task 5 - Instruction 10: ALU 2-op with register (1 byte)
          -- OPCODE = 01 AAA RRR with AAA /= 111
          ----------------------------------------------------------------
          if datard(7 downto 6) = "01" and datard(5 downto 3) /= "111" then
            aluop2  <= reg(to_integer(unsigned(datard(2 downto 0))));
            alucode <= '0' & datard(5 downto 3); -- 0AAA
          end if;

          ----------------------------------------------------------------
          -- Task 5 - Instruction 11: ALU 1-op (1 byte)
          -- OPCODE = 01111 BBB  => ALUCODE = 1BBB
          ----------------------------------------------------------------
          if datard(7 downto 3) = "01111" then
            aluop2  <= (others => '0');          -- unused
            alucode <= '1' & datard(2 downto 0); -- 1BBB
          end if;

          ----------------------------------------------------------------
          -- Task 3 minimal: STORE INDIRECT preparation on 1=>4
          -- OPCODE = 10001 RRR
          ----------------------------------------------------------------
          if datard(7 downto 3) = "10001" then
            addr(15 downto 8) <= reg(6);
            addr(7 downto 0)  <= reg(7);
            wr <= '1';
            datawr <= reg(to_integer(unsigned(datard(2 downto 0))));
          end if;

          if datard(7) = '0' or datard(6 downto 5) = "00" then
            state <= x"4"; 
          else
            state <= x"2";
            addr(7 downto 0) <= pc(7 downto 0) + 1;
          end if;

        when x"2" =>
          ir(15 downto 8) <= datard;
          pc(7 downto 0)  <= pc(7 downto 0) + 1;

          ----------------------------------------------------------------
          -- Task 5 - Instruction 9: ALU 2-op with constant (2 bytes)
          -- OPCODE = 11001 AAA
          -- Here opcode is already in IR, operand2 is DATARD
          ----------------------------------------------------------------
          if ir(23 downto 19) = "11001" then
            aluop2  <= datard;
            alucode <= '0' & ir(18 downto 16); 
          end if;

          if ir(22 downto 21) = "01" or ir(22 downto 21) = "10" then
            state <= x"4"; 
          else
            state <= x"3";
            addr(7 downto 0) <= pc(7 downto 0) + 1;
          end if;

        when x"3" =>
          ir(7 downto 0) <= datard;
          pc(7 downto 0) <= pc(7 downto 0) + 1;
          state <= x"4";

        when x"4" =>
          -- Default values (can be overridden)
          wr   <= '0';
          addr <= pc;

          ----------------------------------------------------------------
          -- Task 5: ALU write-back (4=>1)
          -- store flags in R1(3:0); store result in R0 unless CMP (0010)
          ----------------------------------------------------------------
          if ir(23 downto 22) = "01" or ir(23 downto 19) = "11001" then
            reg(1)(3 downto 0) <= aluflags;
            if alucode /= "0010" then
              reg(0) <= alures;
            end if;
          end if;

          ----------------------------------------------------------------
          -- Task 3: LOAD CONSTANT (4=>1)
          -- OPCODE = 1 10 00 RRR DDDDDDDD  => ir(23 downto 19)="11000"
          ----------------------------------------------------------------
          if ir(23 downto 19) = "11000" then
            reg(to_integer(unsigned(ir(18 downto 16)))) <= ir(15 downto 8);
          end if;

          ----------------------------------------------------------------
          -- Task 4: JUMP 12..15 (4=>1) using FLAGS reg(1)
          ----------------------------------------------------------------
          if ir(23)='1' and ir(20 downto 19)="11" and
             ( ir(18 downto 16)="000" or reg(1)(to_integer(unsigned(ir(17 downto 16)))) = ir(18) )
          then
            -- 12: JUMP INDIRECT yy="00"
            if ir(22 downto 21)="00" then
              pc(15 downto 8) <= reg(6);
              pc(7 downto 0)  <= reg(7);
              addr(15 downto 8) <= reg(6);
              addr(7 downto 0)  <= reg(7);
            end if;

            -- 13: JUMP SHORT ABS yy="01"
            if ir(22 downto 21)="01" then
              pc(7 downto 0)   <= ir(15 downto 8);
              addr(7 downto 0) <= ir(15 downto 8);
            end if;

            -- 14: JUMP SHORT REL yy="10"
            if ir(22 downto 21)="10" then
              pc(7 downto 0) <= std_logic_vector(unsigned(pc(7 downto 0)) + unsigned(ir(15 downto 8)));
              addr(7 downto 0) <= std_logic_vector(unsigned(pc(7 downto 0)) + unsigned(ir(15 downto 8)));
            end if;

            -- 15: JUMP LONG yy="11"
            if ir(22 downto 21)="11" then
              pc(15 downto 8) <= ir(15 downto 8);
              pc(7 downto 0)  <= ir(7 downto 0);
              addr(15 downto 8) <= ir(15 downto 8);
              addr(7 downto 0)  <= ir(7 downto 0);
            end if;
          end if;

          -- Next instruction
          state <= x"1";

        when others =>
          null;

      end case;
    end if;
  end process;

  --------------------------------------------------------------------
  -- ALU COMBINATIONAL PROCESS (Task 5)
  -- Uses reg(0) as Alu1, aluop2 as Alu2, alucode selects operation.
  --------------------------------------------------------------------
  alu_proc : process(reg(0), aluop2, alucode)
    variable var_alu1 : std_logic_vector(9 downto 0);
    variable var_alu2 : std_logic_vector(9 downto 0);
    variable var_res  : std_logic_vector(9 downto 0);
    variable tmp8     : std_logic_vector(7 downto 0);
  begin
    -- Double extension: bit8 = sign, bit9 = '0' (unsigned extension)
    var_alu1 := '0' & reg(0)(7) & reg(0);
    var_alu2 := '0' & aluop2(7) & aluop2;

    var_res := (others => '0');

    case alucode is
      -- 2-operand (0AAA)
      when "0000" => var_res := std_logic_vector(unsigned(var_alu1) + unsigned(var_alu2)); -- ADD
      when "0001" => var_res := std_logic_vector(unsigned(var_alu1) - unsigned(var_alu2)); -- SUB
      when "0010" => var_res := std_logic_vector(unsigned(var_alu1) - unsigned(var_alu2)); -- CMP
      when "0100" => tmp8 := reg(0) and aluop2; var_res := '0' & tmp8(7) & tmp8;           -- AND
      when "0101" => tmp8 := reg(0) or  aluop2; var_res := '0' & tmp8(7) & tmp8;           -- OR
      when "0110" => tmp8 := reg(0) xor aluop2; var_res := '0' & tmp8(7) & tmp8;           -- XOR
      when "0011" => var_res := (others => '0');                                            -- unused
      when "0111" => var_res := (others => '0');                                            -- reserved

      -- 1-operand (1BBB)
      when "1000" => var_res := std_logic_vector(unsigned(to_unsigned(0, 10)) - unsigned(var_alu1)); -- NEG
      when "1001" => tmp8 := not reg(0);               var_res := '0' & tmp8(7) & tmp8;        -- NOT
      when "1010" => var_res := std_logic_vector(unsigned(var_alu1) + 1);                       -- INC
      when "1011" => var_res := std_logic_vector(unsigned(var_alu1) - 1);                       -- DEC
      when "1100" => tmp8 := reg(0)(6 downto 0) & reg(0)(7); var_res := '0' & tmp8(7) & tmp8;  -- ROTL
      when "1101" => tmp8 := reg(0)(0) & reg(0)(7 downto 1); var_res := '0' & tmp8(7) & tmp8;  -- ROTR
      when "1110" => tmp8 := reg(0)(6 downto 0) & '0';      var_res := '0' & tmp8(7) & tmp8;   -- SHL
      when "1111" => tmp8 := reg(0)(7) & reg(0)(7 downto 1); var_res := '0' & tmp8(7) & tmp8;  -- SHR

      when others => var_res := (others => '0');
    end case;

    -- Result
    alures <= var_res(7 downto 0);

-- Flags: Z, S, C, O (stored into reg(1)(3 downto 0))

-- Z flag
if var_res(7 downto 0) = x"00" then
  aluflags(0) <= '1';
else
  aluflags(0) <= '0';
end if;

-- S, C, O flags
aluflags(1) <= var_res(7);                -- S (negative)
aluflags(2) <= var_res(8) xor var_res(7);  -- C (signed carry)
aluflags(3) <= var_res(9);                -- O (unsigned overflow)

  end process;

end Behavioral;
