library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity encDec is
    port(
        clk,rst,b,e,d: in std_logic;
        I : in std_logic_vector(15 downto 0);
        O : out std_logic_vector(15 downto 0)
    );
end encDec;

architecture HLSM of encDec is
    type stateType is (S_init,S_wait,S_dec,S_enc,S_store);
    signal currState,nextState : stateType;
    signal currOff,nextOff,currOut,nextOut: std_logic_vector(15 downto 0);
    
begin
    
    regs: process(clk,rst)
    begin   
        if(rst='1') then
            currState<=S_init;
            currOff<=(others=>'0');
            currOut<=(others=>'0');
        elsif (rising_edge(clk)) then
            currState<=nextState;
            currOff<=nextOff;
            currOut<=nextOut;
        end if;
    end process regs;
    
    O<=currOut;

    comb: process(currState,b,e,d,I,currOut,currOff)
    begin
        case currState is
            when S_init => nextState<=S_wait; nextOut<=(others=>'0'); nextOff<=(others=>'0');
            when S_wait => nextOut<=currOut; nextOff<=currOff;
                           if(b='1') then
                                nextState<=S_store;
                           elsif (e='1') then
                                nextState<=S_enc;
                           elsif (d='1') then
                                nextState<=S_dec;
                           else
                                nextState<=S_wait;
                           end if;
            when S_store => nextState<=S_wait; nextOff<=I; nextOut<=currOut;
            when S_dec => nextState<=S_wait; nextOff<=currOff; nextOut<=std_logic_vector(unsigned(I) - unsigned(currOff));
            when S_enc => nextState<=S_wait; nextOff<=currOff; nextOut<=std_logic_vector(unsigned(I) + unsigned(currOff));
            when others=> nextState<=S_init; nextOut<=(others=>'0'); nextOff<=(others=>'0');                
        end case;
    end process comb;
end HLSM;

architecture FSMD of encDec is
    -- shared signals
    signal add_sub,off_sel,out_sel: std_logic;
    -- FSM signals
    type stateType is (S_init,S_wait,S_dec,S_enc,S_store);
    signal currState,nextState : stateType;
    -- DP signals
    signal currOff,nextOff,currOut,nextOut,add_in,add_out: std_logic_vector(15 downto 0);
    
begin
    -- DP
    DPregs: process(clk,rst)
    begin   
        if(rst='1') then
            currOff<=(others=>'0');
            currOut<=(others=>'0');
        elsif (rising_edge(clk)) then
            currOff<=nextOff;
            currOut<=nextOut;
        end if;
    end process DPregs;
    
    O<=currOut;
    
    process(off_sel,out_sel,currOut,currOff,add_in,add_out,add_sub,I)
    variable cin: std_logic_vector(15 downto 0);
    begin
        if(off_sel='1') then
            nextOff<=currOff;
        else
            nextOff<=I;
        end if;
        
        if(out_sel='1') then
            nextOut<=currOut;
        else
            nextOut<=add_out;
        end if;
        
        for i in 0 to 15 loop
            add_in(i)<= currOff(i) xor add_sub;
        end loop;
        cin:=(15 downto 1 => '0')&add_sub;
        add_out<=std_logic_vector(unsigned(I)+unsigned(add_in)+unsigned(cin));
        
    end process;
    
    -- FSM
    
    FSMregs: process(clk,rst)
    begin   
        if(rst='1') then
            currState<=S_init;
        elsif (rising_edge(clk)) then
            currState<=nextState;
        end if;
    end process FSMregs;
    
    FSMcomb: process(currState,b,e,d,I)
    begin
    add_sub<='0';
        case currState is
            when S_init => nextState<=S_wait; out_sel<='1'; off_sel<='1';
            when S_wait => out_sel<='1'; off_sel<='1';
                           if(b='1') then
                                nextState<=S_store;
                           elsif (e='1') then
                                nextState<=S_enc;
                           elsif (d='1') then
                                nextState<=S_dec;
                           else
                                nextState<=S_wait;
                           end if;
            when S_store => nextState<=S_wait; out_sel<='1'; off_sel<='0';
            when S_dec => nextState<=S_wait; off_sel<='1'; out_sel<='0'; add_sub<='1';
            when S_enc => nextState<=S_wait; off_sel<='1'; out_sel<='0';
            when others=> nextState<=S_init; out_sel<='1'; off_sel<='1';             
        end case;
    end process FSMcomb;
end FSMD;