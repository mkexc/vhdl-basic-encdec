library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_encDec is
end tb_encDec;

architecture Behavioral of tb_encDec is
    component encDec is
        port(
            clk,rst,b,e,d: in std_logic;
            I : in std_logic_vector(15 downto 0);
            O : out std_logic_vector(15 downto 0)
        );
    end component encDec;
    
    signal clk_s,rst_s,b_s,e_s,d_s: std_logic;
    signal I_s,O_s,OFSMD_s : std_logic_vector(15 downto 0);
    constant clkper : time := 10 ns;
    
    for HLSM: encDec use entity work.encDec(HLSM);
    for FSMD: encDec use entity work.encDec(FSMD);
    
begin
    HLSM: encDec port map (clk=>clk_s,rst=>rst_s,b=>b_s,e=>e_s,d=>d_s,I=>I_s,O=>O_s);
    FSMD: encDec port map (clk=>clk_s,rst=>rst_s,b=>b_s,e=>e_s,d=>d_s,I=>I_s,O=>OFSMD_s);
    
    process
    begin
        clk_s<='0';
        wait for clkper/2;
        clk_s<='1';
        wait for clkper/2;
    end process;
    
    process
    begin
        rst_s<='1'; e_s<='0'; d_s<='0'; b_s<='0';
        wait for clkper;
        rst_s<='0';
        wait for clkper; 
        I_s<="0001010100110101"; b_s<='1';
        wait for clkper; b_s<='0';
        wait for clkper;
        I_s<="0010101010101010"; e_s<='1';
        wait for clkper; e_s<='0';
        wait for clkper;
        I_s<=O_s; d_s<='1';
        wait for clkper; d_s<='0';
        wait for clkper;
        wait;
    end process;

end Behavioral;
