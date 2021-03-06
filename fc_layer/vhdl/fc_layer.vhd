library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;

entity fc_layer is
	generic (
		NO_INPUTS : natural;
		NO_OUTPUTS : natural;
		DATA_INTEGER_WIDTH : natural;
		DATA_FRACTION_WIDTH : natural;
		COEF_INTEGER_WIDTH : natural;
		COEF_FRACTION_WIDTH : natural;
		RESULT_INTEGER_WIDTH : natural;
		RESULT_FRACTION_WIDTH : natural
	);

	port (
		din : in std_logic_vector(NO_INPUTS * (DATA_INTEGER_WIDTH + DATA_FRACTION_WIDTH) - 1 downto 0);
		w : in std_logic_vector(NO_OUTPUTS * NO_INPUTS * (COEF_INTEGER_WIDTH + COEF_FRACTION_WIDTH) - 1 downto 0);
		dout : out std_logic_vector(NO_OUTPUTS * (RESULT_INTEGER_WIDTH + RESULT_FRACTION_WIDTH) - 1 downto 0);
		clk : in std_logic;
		rst : in std_logic;
		ce : in std_logic
	);
end fc_layer;

architecture RTL of fc_layer is

------------------------------
--			COMPONENTS		--
------------------------------

component adder_tree is
	Generic (
			NO_INPUTS : natural;
			DATA_WIDTH : natural
	);

	Port (
			din : in std_logic_vector(NO_INPUTS * DATA_WIDTH - 1 downto 0);
      dout : out std_logic_vector(DATA_WIDTH - 1 downto 0);
      clk : in std_logic;
      ce : in std_logic;
      rst : in std_logic
	);
end component;

------------------------------
--			CONSTANTS		--
------------------------------

constant DATA_WIDTH : natural := DATA_INTEGER_WIDTH + DATA_FRACTION_WIDTH;
constant COEF_WIDTH : natural := COEF_INTEGER_WIDTH + COEF_FRACTION_WIDTH;
constant RESULT_WIDTH : natural := RESULT_INTEGER_WIDTH + RESULT_FRACTION_WIDTH;

constant MULT_RES_FRACTION_WIDTH : natural := DATA_FRACTION_WIDTH + COEF_FRACTION_WIDTH;
constant MULT_RES_WIDTH : natural := DATA_WIDTH + COEF_WIDTH;

signal data_from_mults_to_adders : std_logic_vector(NO_OUTPUTS * NO_INPUTS * MULT_RES_WIDTH - 1 downto 0);
signal res_from_adders : std_logic_vector(NO_OUTPUTS * MULT_RES_WIDTH - 1 downto 0);

begin

	output_neurons_gen: for J in 0 to NO_OUTPUTS - 1 generate
		mult_gen : for I in 0 to NO_INPUTS - 1 generate
			data_from_mults_to_adders(J * NO_INPUTS * MULT_RES_WIDTH + (I+1) * MULT_RES_WIDTH - 1 downto J * NO_INPUTS * MULT_RES_WIDTH + I * MULT_RES_WIDTH) <= std_logic_vector(
			  signed(din((I+1) * DATA_WIDTH - 1 downto I * DATA_WIDTH)) * signed(w(J * NO_INPUTS * COEF_WIDTH + (I+1) * COEF_WIDTH - 1 downto J * NO_INPUTS * COEF_WIDTH + I * COEF_WIDTH))
			);
		end generate;

		adder_tree_inst : adder_tree
			generic map (
				NO_INPUTS => NO_INPUTS,
				DATA_WIDTH => MULT_RES_WIDTH
			)
			port map (
				din => data_from_mults_to_adders((J+1) * NO_INPUTS * MULT_RES_WIDTH - 1 downto J * NO_INPUTS * MULT_RES_WIDTH),
				dout => res_from_adders((J+1) * MULT_RES_WIDTH - 1 downto J * MULT_RES_WIDTH),
				clk => clk,
				ce => ce,
				rst => rst
			);

		dout((J+1) * RESULT_WIDTH - 1 downto J * RESULT_WIDTH) <= res_from_adders((J * MULT_RES_WIDTH) + MULT_RES_FRACTION_WIDTH + RESULT_INTEGER_WIDTH - 1 downto (J * MULT_RES_WIDTH) + MULT_RES_FRACTION_WIDTH - RESULT_FRACTION_WIDTH);

	end generate;

end RTL;
