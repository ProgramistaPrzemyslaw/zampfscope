----------------------------------------------------------------------------------
-- Company: WUT
-- Engineer: Michal Smol - Miszq
--
-- Create Date: 05.11.2023 23:04:16
-- Design Name:
-- Module Name: HDMI_TB - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------


library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;


entity HDMI_TB is
GENERIC(
	C_image_legnth : integer := 307200
	);
end HDMI_TB;

architecture behavioral of HDMI_TB is
  constant IMG_WIDTH        : integer   := 640;
  constant IMG_HEIGHT       : integer   := 480;
  constant clock_period     : time      := 4 ns;


  signal clk_250MHz         : std_logic := '0';
  signal img_pixel_clock        : std_logic := '0';
  signal reset              : std_logic := '0';
  signal curr_RGB           : std_logic_vector(23 downto 0);
  signal tmds_all           : std_logic_vector(7 downto 0);
  --signal curr_x, curr_y     : integer;

  signal blanking           : std_logic;
  signal image_cnt 	: integer range 0 to C_image_legnth := 0;
begin

-- DUT : entity work.HDMI_test
-- generic map (
--   img_width   => IMG_WIDTH,
--   img_height  => IMG_HEIGHT
-- )
-- port map (
--   i_pxl_clk   => clk_250MHz,
--   i_reset_n   => reset_n,
--   o_tmds_all  => tmds_all,
--   i_rgb_pixel => curr_RGB,
--   o_curr_x    => curr_x,
--   o_curr_y    => curr_y,
--   blanking    => blanking
-- );

-- image_generator : entity work.HDMI_image_gen
-- generic map (IMG_WIDTH, IMG_HEIGHT)
-- port map (
--   i_clk   => clk_250MHz,  -- can be this clock, can be 25MHz clock... both will work
--   i_x     => curr_x,
--   i_y     => curr_y,
--   o_rgb   => curr_RGB
-- );

DUT: entity work.HDMI_TOP
port map(
  clk_250MHZ    =>  clk_250MHz,
  i_reset       =>  reset,
  o_curr_RGB    =>  curr_RGB,
  o_tmds        =>  tmds_all,
  o_video_ena   =>  blanking
);

clk_sim: process
begin
  clk_250MHz <= '0';
  wait for clock_period/2;
  clk_250MHz <= '1';
  wait for clock_period/2;
end process;

clk_pixel_pr: process
begin
  img_pixel_clock <= '0';
  wait for clock_period/2*10;
  img_pixel_clock <= '1';
  wait for clock_period/2*10;
end process;

file_save : process(img_pixel_clock, blanking)

    file     response_file     : text;
    constant response_filename : string  := "image_out.ppm";
    variable l_o               : line;
    variable response_status   : file_open_status;
    variable x_size            : integer := 640;
    variable y_size            : integer := 480;
    variable x, y              : integer;
begin



	if(image_cnt = 0) then
    file_open(response_status, response_file, response_filename, write_mode);
    write (l_o, string'("P3"));       -- magic number
    writeline(response_file, l_o);
    write (l_o, string'("# generated by VHDL testbench"));       -- comment
    writeline(response_file, l_o);
    write (l_o, string'("# created by Przemyslawwo vhdllo goddini"));       -- comment
    writeline(response_file, l_o);
    write (l_o, string'("# everything fixed to be proper ppm file spec by Michaello angello"));       -- comment
    writeline(response_file, l_o);
    write (l_o, x_size);
    write (l_o, string'(" "));
    write (l_o, y_size);
    writeline(response_file, l_o);
    write (l_o, string'("255"));       -- maximum value
    writeline(response_file, l_o);
    end if;

    if(rising_edge(img_pixel_clock) AND blanking = '1') then
    	if(image_cnt <= C_image_legnth) then
            write (l_o, to_integer(unsigned(curr_RGB(23 downto 16))));
            write (l_o, string'(" "));
            write (l_o, to_integer(unsigned(curr_RGB(15 downto 8))));
            write (l_o, string'(" "));
            write (l_o, to_integer(unsigned(curr_RGB(7 downto 0)))); -- x_counter
            write (l_o, string'("  "));
            write (response_file, l_o.all);
            deallocate(l_o);
           -- l_o := new string'("");
            --write (response_file, string(l_o));
            --l_o'clear;
            image_cnt <= image_cnt + 1;

            if(image_cnt mod x_size = 0 and image_cnt /= 0) then
                write(response_file, (1 => LF));
            end if;
        else
    		file_close(response_file);
    		assert false
    		  report "Simulation completed"
    		  severity failure;
    	end if;

    end if;
end process;
end architecture;