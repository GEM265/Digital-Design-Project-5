library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-- Soda List Component
entity soda_list is
    port(
        soda_sel : in std_logic_vector(3 downto 0);
        soda_price : out std_logic_vector(11 downto 0);
        soda_reserved : out std_logic
    );
end soda_list;

architecture behavioral of soda_list is
begin
    process(soda_sel)
    begin
        case soda_sel is
            when "0000" => soda_price <= conv_std_logic_vector(55, 12); soda_reserved <= '0';   -- $0.55
            when "0001" => soda_price <= conv_std_logic_vector(85, 12); soda_reserved <= '0';   -- $0.85
            when "0010" => soda_price <= conv_std_logic_vector(95, 12); soda_reserved <= '0';   -- $0.95
            when "0011" => soda_price <= conv_std_logic_vector(125, 12); soda_reserved <= '0';  -- $1.25
            when "0100" => soda_price <= conv_std_logic_vector(135, 12); soda_reserved <= '0';  -- $1.35
            when "0101" => soda_price <= conv_std_logic_vector(150, 12); soda_reserved <= '0';  -- $1.50
            when "0110" => soda_price <= conv_std_logic_vector(225, 12); soda_reserved <= '0';  -- $2.25
            when "0111" => soda_price <= conv_std_logic_vector(250, 12); soda_reserved <= '0';  -- $2.50
            when "1000" => soda_price <= conv_std_logic_vector(300, 12); soda_reserved <= '0';  -- $3.00
            when others => soda_price <= conv_std_logic_vector(0, 12); soda_reserved <= '1';    -- Reserved
        end case;
    end process;
end behavioral;
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
-- Coin List Component
entity coin_list is
    port(
        coin_sel : in std_logic_vector(1 downto 0);
        coin_amt : out std_logic_vector(11 downto 0)
    );
end coin_list;

architecture behavioral of coin_list is
begin
    process(coin_sel)
    begin
        case coin_sel is
            when "00" => coin_amt <= conv_std_logic_vector(1, 12);   -- $0.01
            when "01" => coin_amt <= conv_std_logic_vector(5, 12);   -- $0.05
            when "10" => coin_amt <= conv_std_logic_vector(10, 12);  -- $0.10
            when "11" => coin_amt <= conv_std_logic_vector(25, 12);  -- $0.25
            when others => coin_amt <= conv_std_logic_vector(0, 12);
        end case;
    end process;
end behavioral;
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
-- Deposit Register Component
entity deposit_register is
    port(
        clk : in std_logic;
        rst : in std_logic;
        incr : in std_logic;
        incr_amt : in std_logic_vector(11 downto 0);
        decr : in std_logic;
        decr_amt : in std_logic_vector(11 downto 0);
        amt : out std_logic_vector(11 downto 0)
    );
end deposit_register;

architecture behavioral of deposit_register is
    signal deposit_amount : std_logic_vector(11 downto 0);
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '0' then
                deposit_amount <= conv_std_logic_vector(0, 12);
            elsif incr = '1' then
                deposit_amount <= deposit_amount + incr_amt;
            elsif decr = '1' then
                deposit_amount <= deposit_amount - decr_amt;
            end if;
        end if;
    end process;
    
    amt <= deposit_amount;
end behavioral;
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
-- Vending Machine Controller Component
entity vending_machine_ctrl is
    port(
        clk : in std_logic;
        rst : in std_logic;
        lock : in std_logic;
        soda_reserved : in std_logic;
        soda_price : in std_logic_vector(11 downto 0);
        soda_req : in std_logic;
        deposit_amt : in std_logic_vector(11 downto 0);
        coin_push : in std_logic;
        coin_amt : in std_logic_vector(11 downto 0);
        soda_drop : out std_logic;
        deposit_incr : out std_logic;
        deposit_decr : out std_logic;
        coin_reject : out std_logic;
        error_amt : out std_logic;
        error_reserved : out std_logic
    );
end vending_machine_ctrl;

architecture behavioral of vending_machine_ctrl is
    type state_type is (IDLE, COIN_CHECK, COIN_ACCEPT, COIN_DECLINE, 
                       SODA_CHECK, SODA_ACCEPT, SODA_ACCEPT_WAIT, 
                       SODA_DECLINE_AMT, SODA_DECLINE_RESERVED);
    signal current_state, next_state : state_type;
begin
    -- State register
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '0' then
                current_state <= IDLE;
            else
                current_state <= next_state;
            end if;
        end if;
    end process;
    
    -- Next state logic
    process(current_state, coin_push, soda_req, lock, soda_reserved, 
            deposit_amt, soda_price, coin_amt)
    begin
        next_state <= current_state;
        
        case current_state is
            when IDLE =>
                if coin_push = '1' then
                    next_state <= COIN_CHECK;
                elsif soda_req = '1' then
                    next_state <= SODA_CHECK;
                end if;
                
            when COIN_CHECK =>
                if (coin_amt + deposit_amt) > conv_std_logic_vector(1000, 12) then
                    next_state <= COIN_DECLINE;
                else
                    next_state <= COIN_ACCEPT;
                end if;
                
            when COIN_ACCEPT =>
                next_state <= IDLE;
                
            when COIN_DECLINE =>
                if lock = '0' then
                    next_state <= IDLE;
                end if;
                
            when SODA_CHECK =>
                if soda_reserved = '1' then
                    next_state <= SODA_DECLINE_RESERVED;
                elsif deposit_amt >= soda_price then
                    next_state <= SODA_ACCEPT;
                else
                    next_state <= SODA_DECLINE_AMT;
                end if;
                
            when SODA_ACCEPT =>
                next_state <= SODA_ACCEPT_WAIT;
                
            when SODA_ACCEPT_WAIT =>
                if lock = '0' then
                    next_state <= IDLE;
                end if;
                
            when SODA_DECLINE_AMT =>
                if lock = '0' then
                    next_state <= IDLE;
                end if;
                
            when SODA_DECLINE_RESERVED =>
                if lock = '0' then
                    next_state <= IDLE;
                end if;
        end case;
    end process;
    
    -- Output logic
    process(current_state)
    begin
        -- Default outputs
        soda_drop <= '0';
        deposit_incr <= '0';
        deposit_decr <= '0';
        coin_reject <= '0';
        error_amt <= '0';
        error_reserved <= '0';
        
        case current_state is
            when COIN_ACCEPT =>
                deposit_incr <= '1';
                
            when COIN_DECLINE =>
                coin_reject <= '1';
                
            when SODA_ACCEPT =>
                deposit_decr <= '1';
                
            when SODA_ACCEPT_WAIT =>
                soda_drop <= '1';
                
            when SODA_DECLINE_AMT =>
                error_amt <= '1';
                
            when SODA_DECLINE_RESERVED =>
                error_reserved <= '1';
                
            when others =>
                null;
        end case;
    end process;
end behavioral;
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
-- Main Vending Machine Subsystem
entity vending_machine_subsystem is
    port(
        clk : in std_logic;
        rst : in std_logic;
        lock : in std_logic;
        soda_sel : in std_logic_vector(3 downto 0);
        soda_req : in std_logic;
        coin_push : in std_logic;
        coin_sel : in std_logic_vector(1 downto 0);
        coin_reject : out std_logic;
        soda_reserved : out std_logic;
        soda_price : out std_logic_vector(11 downto 0);
        soda_drop : out std_logic;
        deposit_amt : out std_logic_vector(11 downto 0);
        error_amt : out std_logic;
        error_reserved : out std_logic
    );
end vending_machine_subsystem;

architecture behavioral of vending_machine_subsystem is
    component soda_list is
        port(
            soda_sel : in std_logic_vector(3 downto 0);
            soda_price : out std_logic_vector(11 downto 0);
            soda_reserved : out std_logic
        );
    end component;
    
    component coin_list is
        port(
            coin_sel : in std_logic_vector(1 downto 0);
            coin_amt : out std_logic_vector(11 downto 0)
        );
    end component;
    
    component deposit_register is
        port(
            clk : in std_logic;
            rst : in std_logic;
            incr : in std_logic;
            incr_amt : in std_logic_vector(11 downto 0);
            decr : in std_logic;
            decr_amt : in std_logic_vector(11 downto 0);
            amt : out std_logic_vector(11 downto 0)
        );
    end component;
    
    component vending_machine_ctrl is
        port(
            clk : in std_logic;
            rst : in std_logic;
            lock : in std_logic;
            soda_reserved : in std_logic;
            soda_price : in std_logic_vector(11 downto 0);
            soda_req : in std_logic;
            deposit_amt : in std_logic_vector(11 downto 0);
            coin_push : in std_logic;
            coin_amt : in std_logic_vector(11 downto 0);
            soda_drop : out std_logic;
            deposit_incr : out std_logic;
            deposit_decr : out std_logic;
            coin_reject : out std_logic;
            error_amt : out std_logic;
            error_reserved : out std_logic
        );
    end component;
    
    -- Internal signals
    signal coin_amt_internal : std_logic_vector(11 downto 0);
    signal soda_price_internal : std_logic_vector(11 downto 0);
    signal soda_reserved_internal : std_logic;
    signal deposit_amt_internal : std_logic_vector(11 downto 0);
    signal deposit_incr_internal : std_logic;
    signal deposit_decr_internal : std_logic;
    
begin
    -- Component instantiations
    soda_list_inst : soda_list
        port map(
            soda_sel => soda_sel,
            soda_price => soda_price_internal,
            soda_reserved => soda_reserved_internal
        );
        
    coin_list_inst : coin_list
        port map(
            coin_sel => coin_sel,
            coin_amt => coin_amt_internal
        );
        
    deposit_register_inst : deposit_register
        port map(
            clk => clk,
            rst => rst,
            incr => deposit_incr_internal,
            incr_amt => coin_amt_internal,
            decr => deposit_decr_internal,
            decr_amt => soda_price_internal,
            amt => deposit_amt_internal
        );
        
    vending_machine_ctrl_inst : vending_machine_ctrl
        port map(
            clk => clk,
            rst => rst,
            lock => lock,
            soda_reserved => soda_reserved_internal,
            soda_price => soda_price_internal,
            soda_req => soda_req,
            deposit_amt => deposit_amt_internal,
            coin_push => coin_push,
            coin_amt => coin_amt_internal,
            soda_drop => soda_drop,
            deposit_incr => deposit_incr_internal,
            deposit_decr => deposit_decr_internal,
            coin_reject => coin_reject,
            error_amt => error_amt,
            error_reserved => error_reserved
        );
    
    -- Output assignments
    soda_price <= soda_price_internal;
    soda_reserved <= soda_reserved_internal;
    deposit_amt <= deposit_amt_internal;
    
end behavioral;