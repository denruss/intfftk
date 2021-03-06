-------------------------------------------------------------------------------
--
-- Title       : mlt61x18_dsp48e2
-- Design      : FFTK
-- Author      : Kapitanov
-- Company     :
--
-- Description : Multiplier 61x18 based on DSP48E1 block
--
-------------------------------------------------------------------------------
--
--	Version 1.0: 15.02.2018
--
--  Description: Triple complex multiplier by DSP48 unit
--
--  Math: MLT_P = MLT_A * MLT_B (w/ triple multiplier)
--
--  DSP48 data signals:
--    A port - data width up to 59 (61)* bits
--    B port - data width up to 18 bits
--  * - 59 bits for DSP48E1, 61 bits for DSP48E2.
--
--  Total delay			: 5 clock cycles,
--  Total resources		: 3 DSP48 units
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
--	GNU GENERAL PUBLIC LICENSE
--  Version 3, 29 June 2007
--
--	Copyright (c) 2018 Kapitanov Alexander
--
--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
--  THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
--  APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT 
--  HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY 
--  OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, 
--  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
--  PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM 
--  IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF 
--  ALL NECESSARY SERVICING, REPAIR OR CORRECTION. 
-- 
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.DSP48E2;	

entity mlt61x18_dsp48e2 is
	port (
		MLT_A 	: in  std_logic_vector(60 downto 0); --! A port: up to 42 bits
		MLT_B 	: in  std_logic_vector(17 downto 0); --! B port: up to 18 bits
		MLT_P 	: out std_logic_vector(78 downto 0); --! P port: double multiplier
		RST  	: in  std_logic; --! Global reset
		CLK 	: in  std_logic	 --! Math clock	
	);
end mlt61x18_dsp48e2;

architecture mlt61x18_dsp48e2 of mlt61x18_dsp48e2 is

	signal dspA_M1		: std_logic_vector(29 downto 0);
	signal dspA_M2		: std_logic_vector(29 downto 0);
	signal dspA_M3		: std_logic_vector(29 downto 0);
	signal dspB_12		: std_logic_vector(17 downto 0);
	signal dspB_ZZ		: std_logic_vector(17 downto 0);
	
	signal dspP_M1		: std_logic_vector(47 downto 0);
	signal dspP_M2		: std_logic_vector(47 downto 0);
	signal dspP_M3		: std_logic_vector(47 downto 0);
	signal dspP_MZ		: std_logic_vector(47 downto 0);
	signal dspP_12		: std_logic_vector(47 downto 0);
	signal dspP_23		: std_logic_vector(47 downto 0);

begin
	MLT_P(16 downto 00) <= dspP_MZ(16 downto 00) when rising_edge(clk);
	MLT_P(33 downto 17) <= dspP_M2(16 downto 00) when rising_edge(clk);
	MLT_P(78 downto 34) <= dspP_M1(44 downto 00);
	
	dspP_MZ <= dspP_M3 when rising_edge(clk); 
	
	dspA_M3(16 downto 00) <= MLT_A(16 downto 00);
	dspA_M3(29 downto 17) <= (others => '0');	
	dspA_M2(16 downto 00) <= MLT_A(33 downto 17);
	dspA_M2(29 downto 17) <= (others => '0');
	dspA_M1(26 downto 00) <= MLT_A(60 downto 34) when rising_edge(clk);
	dspA_M1(29 downto 27) <= (others => MLT_A(60)) when rising_edge(clk);
    
	dspB_12 <= MLT_B;
    dspB_ZZ <= dspB_12 after 0.1 ns when rising_edge(clk);
    
	---- Wrap DSP48E2 units ----
	xDSP_M1: DSP48E2
		generic map (
			-- Feature Control Attributes: Data Path Selection
			USE_MULT 		=> "MULTIPLY",
			-- Register Control Attributes: Pipeline Register Configuration
			ACASCREG 		=> 1,
			ADREG 			=> 1,
			ALUMODEREG 		=> 1,
			AREG 			=> 2,
			BCASCREG	 	=> 1,
			BREG 			=> 2,
			CARRYINREG 		=> 1,
			CARRYINSELREG 	=> 1,
			CREG 			=> 1,
			DREG 			=> 1,
			INMODEREG 		=> 1,
			MREG 			=> 1,
			OPMODEREG 		=> 1,
			PREG 			=> 1 
		)		
		port map (         
			-- Data: input / output data ports
			A 				=> dspA_M1, -- 30-bit input: A data input
			B 				=> dspB_ZZ, -- 18-bit input: B data input
			C 				=> (others=>'0'),
			D 				=> (others=>'0'),
			P               => dspP_M1,
			PCOUT			=> open,
			-- Control: Inputs/Status Bits
			ALUMODE 		=> (others=>'0'),
			INMODE 			=> (others=>'0'),
			OPMODE 			=> "001010101",
			-- Carry input data
			ACIN			=> (others=>'0'),    
			BCIN            => (others=>'0'),
			PCIN            => dspP_12,
			CARRYINSEL 		=> (others=>'0'),
			CARRYCASCIN		=> '0',
			CARRYIN         => '0',           
			MULTSIGNIN		=> '0',			
			-- Clock enables
			CEA1            => '1',
			CEA2            => '1',
			CEAD            => '1',
			CEALUMODE       => '1',
			CEB1            => '1',
			CEB2            => '1',
			CEC             => '1',
			CECARRYIN       => '1',
			CECTRL          => '1',
			CED				=> '1',
			CEINMODE		=> '1',
			CEM             => '1',
			CEP             => '1',
			CLK             => CLK,
			-- Reset/Clock Enable --
			RSTA            => RST,
			RSTALLCARRYIN	=> RST,
			RSTALUMODE   	=> RST,
			RSTB            => RST,
			RSTC            => RST,
			RSTCTRL         => RST,
			RSTD			=> RST,
			RSTINMODE		=> RST,
			RSTM            => RST,
			RSTP            => RST 
		);
		
	xDSP_M2: DSP48E2
		generic map (
			-- Feature Control Attributes: Data Path Selection
			USE_MULT 		=> "MULTIPLY",
			-- Register Control Attributes: Pipeline Register Configuration
			ACASCREG 		=> 1,
			ADREG 			=> 1,
			ALUMODEREG 		=> 1,
			AREG 			=> 2,
			BCASCREG	 	=> 1,
			BREG 			=> 2,
			CARRYINREG 		=> 1,
			CARRYINSELREG 	=> 1,
			CREG 			=> 1,
			DREG 			=> 1,
			INMODEREG 		=> 1,
			MREG 			=> 1,
			OPMODEREG 		=> 1,
			PREG 			=> 1 
		)		
		port map (         
			-- Data: input / output data ports
			A 				=> dspA_M2, -- 30-bit input: A data input
			B 				=> dspB_12, -- 18-bit input: B data input
			C 				=> (others=>'0'),
			D 				=> (others=>'0'),
			P               => dspP_M2,
			PCOUT			=> dspP_12,
			-- Control: Inputs/Status Bits
			ALUMODE 		=> (others=>'0'),
			INMODE 			=> (others=>'0'),
			OPMODE 			=> "001010101",
			-- Carry input data
			ACIN			=> (others=>'0'),    
			BCIN            => (others=>'0'),
			PCIN            => dspP_23,
			CARRYINSEL 		=> (others=>'0'),
			CARRYCASCIN		=> '0',
			CARRYIN         => '0',           
			MULTSIGNIN		=> '0',			
			-- Clock enables
			CEA1            => '1',
			CEA2            => '1',
			CEAD            => '1',
			CEALUMODE       => '1',
			CEB1            => '1',
			CEB2            => '1',
			CEC             => '1',
			CECARRYIN       => '1',
			CECTRL          => '1',
			CED				=> '1',
			CEINMODE		=> '1',
			CEM             => '1',
			CEP             => '1',
			CLK             => CLK,
			-- Reset/Clock Enable --
			RSTA            => RST,
			RSTALLCARRYIN	=> RST,
			RSTALUMODE   	=> RST,
			RSTB            => RST,
			RSTC            => RST,
			RSTCTRL         => RST,
			RSTD			=> RST,
			RSTINMODE		=> RST,
			RSTM            => RST,
			RSTP            => RST 
		);	

	xDSP_M3: DSP48E2
		generic map (
			-- Feature Control Attributes: Data Path Selection
			USE_MULT 		=> "MULTIPLY",
			-- Register Control Attributes: Pipeline Register Configuration
			ACASCREG 		=> 1,
			ADREG 			=> 1,
			ALUMODEREG 		=> 1,
			AREG 			=> 1,
			BCASCREG	 	=> 1,
			BREG 			=> 1,
			CARRYINREG 		=> 1,
			CARRYINSELREG 	=> 1,
			CREG 			=> 1,
			DREG 			=> 1,
			INMODEREG 		=> 1,
			MREG 			=> 1,
			OPMODEREG 		=> 1,
			PREG 			=> 1 
		)		
		port map (         
			-- Data: input / output data ports
			A 				=> dspA_M3, -- 30-bit input: A data input
			B 				=> dspB_12, -- 18-bit input: B data input
			C 				=> (others=>'0'),
			D 				=> (others=>'0'),
			P               => dspP_M3,
			PCOUT			=> dspP_23,
			-- Control: Inputs/Status Bits
			ALUMODE 		=> (others=>'0'),
			INMODE 			=> (others=>'0'),
			OPMODE 			=> "000000101",
			-- Carry input data
			ACIN			=> (others=>'0'),    
			BCIN            => (others=>'0'),
			PCIN            => (others=>'0'),
			CARRYINSEL 		=> (others=>'0'),
			CARRYCASCIN		=> '0',
			CARRYIN         => '0',           
			MULTSIGNIN		=> '0',			
			-- Clock enables
			CEA1            => '1',
			CEA2            => '1',
			CEAD            => '1',
			CEALUMODE       => '1',
			CEB1            => '1',
			CEB2            => '1',
			CEC             => '1',
			CECARRYIN       => '1',
			CECTRL          => '1',
			CED				=> '1',
			CEINMODE		=> '1',
			CEM             => '1',
			CEP             => '1',
			CLK             => CLK,
			-- Reset/Clock Enable --
			RSTA            => RST,
			RSTALLCARRYIN	=> RST,
			RSTALUMODE   	=> RST,
			RSTB            => RST,
			RSTC            => RST,
			RSTCTRL         => RST,
			RSTD			=> RST,
			RSTINMODE		=> RST,
			RSTM            => RST,
			RSTP            => RST 
		);	
		
end mlt61x18_dsp48e2;