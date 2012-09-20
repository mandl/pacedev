library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;
use work.target_pkg.all;
use work.project_pkg.all;
use work.platform_pkg.all;

package platform_variant_pkg is

	--  
	-- PACE constants which *MUST* be defined
	--

	--
	-- Platform-specific constants (optional)
	--

  constant PLATFORM_VARIANT             : string := "kungfum";
  constant PLATFORM_VARIANT_SRC_DIR     : string := PLATFORM_SRC_DIR & PLATFORM_VARIANT & "/";
  
  type rom_a is array (natural range <>) of string;
  constant M62_ROM                      : rom_a(0 to 1) := 
                                          (
                                            0 => "a-4e-c.bin", 
                                            1 => "a-4d-c.bin"
                                          );
  constant M62_ROM_WIDTHAD              : natural := 14;

  constant M62_CHAR_ROM                 : rom_a(0 to 2) := 
                                          (
                                            0 => "g-4c-a.bin", 
                                            1 => "g-4d-a.bin",
                                            2 => "g-4e-a.bin"
                                          );

  constant M62_SPRITE_ROM               : rom_a(0 to 11) := 
                                          (
                                            0 => "b-4k-.bin", 
                                            3 => "b-4f-.bin",
                                            6 => "b-4l-.bin",
                                            9 => "b-4h-.bin",
                                            1 => "b-3n-.bin",
                                            4 => "b-4n-.bin",
                                            7 => "b-4m-.bin",
                                            10 => "b-3m-.bin",
                                            2 => "b-4c-.bin",
                                            5 => "b-4e-.bin",
                                            8 => "b-4d-.bin",
                                            11 => "b-4a-.bin"
                                          );

	constant tile_pal : pal_a(0 to 255) :=
	(
    0 => (0=>"00000011", 1=>"00000011", 2=>"00000011"),  -- 030303
    1 => (0=>"11111111", 1=>"00000011", 2=>"00000011"),  -- FF0303
    2 => (0=>"00000011", 1=>"11111111", 2=>"00000011"),  -- 03FF03
    3 => (0=>"11111111", 1=>"11111111", 2=>"00000011"),  -- FFFF03
    4 => (0=>"00000011", 1=>"00000011", 2=>"11111111"),  -- 0303FF
    5 => (0=>"11111111", 1=>"00000011", 2=>"11111111"),  -- FF03FF
    6 => (0=>"00000011", 1=>"11111111", 2=>"11111111"),  -- 03FFFF
    7 => (0=>"11111111", 1=>"11111111", 2=>"11111111"),  -- FFFFFF
    8 => (0=>"10100110", 1=>"10000100", 2=>"11011100"),  -- A684DC
    9 => (0=>"11110000", 1=>"10110111", 2=>"10000100"),  -- F0B784
    10 => (0=>"11011100", 1=>"10100110", 2=>"01110000"),  -- DCA670
    11 => (0=>"11111111", 1=>"00000011", 2=>"00110001"),  -- FF0331
    12 => (0=>"11110000", 1=>"11110000", 2=>"11001100"),  -- F0F0CC
    13 => (0=>"10110111", 1=>"10000100", 2=>"00000011"),  -- B78403
    14 => (0=>"11001100", 1=>"10100110", 2=>"10000100"),  -- CCA684
    15 => (0=>"11110000", 1=>"11110000", 2=>"11110000"),  -- F0F0F0
    16 => (0=>"10110111", 1=>"10110111", 2=>"10110111"),  -- B7B7B7
    17 => (0=>"11111111", 1=>"11111111", 2=>"11111111"),  -- FFFFFF
    18 => (0=>"10000100", 1=>"11001100", 2=>"10000100"),  -- 84CC84
    19 => (0=>"11001100", 1=>"11110000", 2=>"11001100"),  -- CCF0CC
    20 => (0=>"01100010", 1=>"01100010", 2=>"01100010"),  -- 626262
    21 => (0=>"11011100", 1=>"10010100", 2=>"01010000"),  -- DC9450
    22 => (0=>"10110111", 1=>"10010100", 2=>"01010000"),  -- B79450
    23 => (0=>"10100110", 1=>"10100110", 2=>"10100110"),  -- A6A6A6
    24 => (0=>"00000011", 1=>"00000011", 2=>"00000011"),  -- 030303
    25 => (0=>"10110111", 1=>"10000100", 2=>"00000011"),  -- B78403
    26 => (0=>"11111111", 1=>"11111111", 2=>"00000011"),  -- FFFF03
    27 => (0=>"10100110", 1=>"11001100", 2=>"11111111"),  -- A6CCFF
    28 => (0=>"11111111", 1=>"11111111", 2=>"11111111"),  -- FFFFFF
    29 => (0=>"11001100", 1=>"10010100", 2=>"10000100"),  -- CC9484
    30 => (0=>"10100110", 1=>"10100110", 2=>"10100110"),  -- A6A6A6
    31 => (0=>"11111111", 1=>"11110000", 2=>"11001100"),  -- FFF0CC
    32 => (0=>"10100110", 1=>"10000100", 2=>"11011100"),  -- A684DC
    33 => (0=>"11001100", 1=>"00110001", 2=>"01000001"),  -- CC3141
    34 => (0=>"11111111", 1=>"10000100", 2=>"10000100"),  -- FF8484
    35 => (0=>"11111111", 1=>"10110111", 2=>"10110111"),  -- FFB7B7
    36 => (0=>"00000011", 1=>"00000011", 2=>"00000011"),  -- 030303
    37 => (0=>"11110000", 1=>"11110000", 2=>"11001100"),  -- F0F0CC
    38 => (0=>"10110111", 1=>"10000100", 2=>"00000011"),  -- B78403
    39 => (0=>"11001100", 1=>"10100110", 2=>"10000100"),  -- CCA684
    40 => (0=>"11001100", 1=>"10100110", 2=>"10000100"),  -- CCA684
    41 => (0=>"00000011", 1=>"11001100", 2=>"11001100"),  -- 03CCCC
    42 => (0=>"11011100", 1=>"11111111", 2=>"11111111"),  -- DCFFFF
    43 => (0=>"11011100", 1=>"10010100", 2=>"01110000"),  -- DC9470
    44 => (0=>"11110000", 1=>"11110000", 2=>"11001100"),  -- F0F0CC
    45 => (0=>"10100110", 1=>"10000100", 2=>"11011100"),  -- A684DC
    46 => (0=>"11001100", 1=>"11001100", 2=>"11001100"),  -- CCCCCC
    47 => (0=>"11111111", 1=>"11001100", 2=>"01110000"),  -- FFCC70
    48 => (0=>"10100110", 1=>"10000100", 2=>"11011100"),  -- A684DC
    49 => (0=>"11011100", 1=>"11111111", 2=>"11111111"),  -- DCFFFF
    50 => (0=>"00000011", 1=>"11110000", 2=>"11110000"),  -- 03F0F0
    51 => (0=>"11011100", 1=>"10010100", 2=>"01110000"),  -- DC9470
    52 => (0=>"11111111", 1=>"11001100", 2=>"01110000"),  -- FFCC70
    53 => (0=>"11001100", 1=>"11001100", 2=>"11001100"),  -- CCCCCC
    54 => (0=>"01110000", 1=>"01110000", 2=>"01110000"),  -- 707070
    55 => (0=>"11001100", 1=>"10100110", 2=>"10000100"),  -- CCA684
    56 => (0=>"11110000", 1=>"11110000", 2=>"11001100"),  -- F0F0CC
    57 => (0=>"00000011", 1=>"11111111", 2=>"00000011"),  -- 03FF03
    58 => (0=>"11111111", 1=>"11001100", 2=>"00000011"),  -- FFCC03
    59 => (0=>"11111111", 1=>"11011100", 2=>"00000011"),  -- FFDC03
    60 => (0=>"00000011", 1=>"11111111", 2=>"11111111"),  -- 03FFFF
    61 => (0=>"10110111", 1=>"10000100", 2=>"00000011"),  -- B78403
    62 => (0=>"11111111", 1=>"11111111", 2=>"00000011"),  -- FFFF03
    63 => (0=>"11111111", 1=>"00000011", 2=>"00000011"),  -- FF0303
    64 => (0=>"11111111", 1=>"00000011", 2=>"00110001"),  -- FF0331
    65 => (0=>"10110111", 1=>"10000100", 2=>"00000011"),  -- B78403
    66 => (0=>"11111111", 1=>"11111111", 2=>"00000011"),  -- FFFF03
    67 => (0=>"11001100", 1=>"10100110", 2=>"10000100"),  -- CCA684
    68 => (0=>"11011100", 1=>"10010100", 2=>"01110000"),  -- DC9470
    69 => (0=>"11111111", 1=>"11001100", 2=>"01110000"),  -- FFCC70
    70 => (0=>"00000011", 1=>"11110000", 2=>"11110000"),  -- 03F0F0
    71 => (0=>"11011100", 1=>"11111111", 2=>"11111111"),  -- DCFFFF
    72 => (0=>"10100110", 1=>"11001100", 2=>"11111111"),  -- A6CCFF
    73 => (0=>"11111111", 1=>"11001100", 2=>"01110000"),  -- FFCC70
    74 => (0=>"11001100", 1=>"10100110", 2=>"10000100"),  -- CCA684
    75 => (0=>"10110111", 1=>"10000100", 2=>"00000011"),  -- B78403
    76 => (0=>"10110111", 1=>"10000100", 2=>"00000011"),  -- B78403
    77 => (0=>"11110000", 1=>"11011100", 2=>"10100110"),  -- F0DCA6
    78 => (0=>"11110000", 1=>"11110000", 2=>"11110000"),  -- F0F0F0
    79 => (0=>"11111111", 1=>"11111111", 2=>"11111111"),  -- FFFFFF
    80 => (0=>"10110111", 1=>"10000100", 2=>"00000011"),  -- B78403
    81 => (0=>"11111111", 1=>"11001100", 2=>"01110000"),  -- FFCC70
    82 => (0=>"11011100", 1=>"10010100", 2=>"01110000"),  -- DC9470
    83 => (0=>"11110000", 1=>"11110000", 2=>"11001100"),  -- F0F0CC
    84 => (0=>"11011100", 1=>"11111111", 2=>"11111111"),  -- DCFFFF
    85 => (0=>"00000011", 1=>"11110000", 2=>"11110000"),  -- 03F0F0
    86 => (0=>"11001100", 1=>"11001100", 2=>"11001100"),  -- CCCCCC
    87 => (0=>"01110000", 1=>"01110000", 2=>"01110000"),  -- 707070
    88 => (0=>"10100110", 1=>"10000100", 2=>"11011100"),  -- A684DC
    89 => (0=>"11111111", 1=>"11111111", 2=>"11111111"),  -- FFFFFF
    90 => (0=>"11111111", 1=>"11111111", 2=>"11111111"),  -- FFFFFF
    91 => (0=>"11111111", 1=>"00000011", 2=>"00110001"),  -- FF0331
    92 => (0=>"10100110", 1=>"10000100", 2=>"11011100"),  -- A684DC
    93 => (0=>"11001100", 1=>"00000011", 2=>"10000100"),  -- CC0384
    94 => (0=>"00000011", 1=>"00000011", 2=>"00000011"),  -- 030303
    95 => (0=>"11111111", 1=>"11111111", 2=>"11111111"),  -- FFFFFF
    96 => (0=>"10100110", 1=>"10000100", 2=>"11011100"),  -- A684DC
    97 => (0=>"00000011", 1=>"10110111", 2=>"11001100"),  -- 03B7CC
    98 => (0=>"00000011", 1=>"00000011", 2=>"00000011"),  -- 030303
    99 => (0=>"11111111", 1=>"11001100", 2=>"01110000"),  -- FFCC70
    100 => (0=>"10010100", 1=>"10010100", 2=>"10010100"),  -- 949494
    101 => (0=>"11001100", 1=>"10100110", 2=>"10000100"),  -- CCA684
    102 => (0=>"11001100", 1=>"11001100", 2=>"11001100"),  -- CCCCCC
    103 => (0=>"11110000", 1=>"11110000", 2=>"11001100"),  -- F0F0CC
    104 => (0=>"11111111", 1=>"11111111", 2=>"11111111"),  -- FFFFFF
    105 => (0=>"10110111", 1=>"10000100", 2=>"00000011"),  -- B78403
    106 => (0=>"11001100", 1=>"10100110", 2=>"10000100"),  -- CCA684
    107 => (0=>"11110000", 1=>"11110000", 2=>"11001100"),  -- F0F0CC
    108 => (0=>"10010100", 1=>"10010100", 2=>"10010100"),  -- 949494
    109 => (0=>"10100110", 1=>"11001100", 2=>"11111111"),  -- A6CCFF
    110 => (0=>"00000011", 1=>"11011100", 2=>"00000011"),  -- 03DC03
    111 => (0=>"10110111", 1=>"11111111", 2=>"10110111"),  -- B7FFB7
    112 => (0=>"10010100", 1=>"10010100", 2=>"10010100"),  -- 949494
    113 => (0=>"10110111", 1=>"10000100", 2=>"00000011"),  -- B78403
    114 => (0=>"00000011", 1=>"11110000", 2=>"10100110"),  -- 03F0A6
    115 => (0=>"11111111", 1=>"11011100", 2=>"10010100"),  -- FFDC94
    116 => (0=>"10010100", 1=>"10010100", 2=>"10010100"),  -- 949494
    117 => (0=>"11001100", 1=>"10100110", 2=>"10000100"),  -- CCA684
    118 => (0=>"00000011", 1=>"11011100", 2=>"00000011"),  -- 03DC03
    119 => (0=>"10110111", 1=>"11111111", 2=>"10110111"),  -- B7FFB7
    120 => (0=>"10010100", 1=>"10010100", 2=>"10010100"),  -- 949494
    121 => (0=>"11111111", 1=>"10110111", 2=>"10110111"),  -- FFB7B7
    122 => (0=>"00000011", 1=>"11110000", 2=>"10100110"),  -- 03F0A6
    123 => (0=>"11111111", 1=>"11011100", 2=>"10010100"),  -- FFDC94
    124 => (0=>"11111111", 1=>"11111111", 2=>"11111111"),  -- FFFFFF
    125 => (0=>"11001100", 1=>"10100110", 2=>"10000100"),  -- CCA684
    126 => (0=>"11011100", 1=>"11011100", 2=>"11011100"),  -- DCDCDC
    127 => (0=>"10110111", 1=>"10110111", 2=>"10110111"),  -- B7B7B7
    128 => (0=>"10010100", 1=>"10010100", 2=>"10010100"),  -- 949494
    129 => (0=>"11111111", 1=>"10110111", 2=>"10110111"),  -- FFB7B7
    130 => (0=>"10110111", 1=>"10000100", 2=>"00000011"),  -- B78403
    131 => (0=>"11110000", 1=>"11110000", 2=>"11001100"),  -- F0F0CC
    132 => (0=>"00000011", 1=>"11011100", 2=>"00000011"),  -- 03DC03
    133 => (0=>"11011100", 1=>"11011100", 2=>"11011100"),  -- DCDCDC
    134 => (0=>"10110111", 1=>"11111111", 2=>"10110111"),  -- B7FFB7
    135 => (0=>"10110111", 1=>"10110111", 2=>"10110111"),  -- B7B7B7
    136 => (0=>"10100110", 1=>"10000100", 2=>"11011100"),  -- A684DC
    137 => (0=>"00000011", 1=>"00000011", 2=>"00000011"),  -- 030303
    138 => (0=>"11001100", 1=>"10100110", 2=>"10000100"),  -- CCA684
    139 => (0=>"11110000", 1=>"11110000", 2=>"11001100"),  -- F0F0CC
    140 => (0=>"10110111", 1=>"10000100", 2=>"00000011"),  -- B78403
    141 => (0=>"11111111", 1=>"11001100", 2=>"10110111"),  -- FFCCB7
    142 => (0=>"00000011", 1=>"11011100", 2=>"11011100"),  -- 03DCDC
    143 => (0=>"10110111", 1=>"10100110", 2=>"10000100"),  -- B7A684
    144 => (0=>"10100110", 1=>"10000100", 2=>"11011100"),  -- A684DC
    145 => (0=>"00000011", 1=>"00000011", 2=>"00000011"),  -- 030303
    146 => (0=>"11001100", 1=>"10100110", 2=>"10000100"),  -- CCA684
    147 => (0=>"11110000", 1=>"11110000", 2=>"11001100"),  -- F0F0CC
    148 => (0=>"11001100", 1=>"10010100", 2=>"10000100"),  -- CC9484
    149 => (0=>"11111111", 1=>"11001100", 2=>"10110111"),  -- FFCCB7
    150 => (0=>"10100110", 1=>"11001100", 2=>"11111111"),  -- A6CCFF
    151 => (0=>"10110111", 1=>"10000100", 2=>"00000011"),  -- B78403
    152 => (0=>"10100110", 1=>"10000100", 2=>"11011100"),  -- A684DC
    153 => (0=>"10100110", 1=>"10000100", 2=>"00000011"),  -- A68403
    154 => (0=>"11001100", 1=>"10100110", 2=>"10000100"),  -- CCA684
    155 => (0=>"11110000", 1=>"11110000", 2=>"11001100"),  -- F0F0CC
    156 => (0=>"11001100", 1=>"10010100", 2=>"10000100"),  -- CC9484
    157 => (0=>"11111111", 1=>"11001100", 2=>"10110111"),  -- FFCCB7
    158 => (0=>"11001100", 1=>"10100110", 2=>"10000100"),  -- CCA684
    159 => (0=>"10110111", 1=>"10000100", 2=>"00000011"),  -- B78403
    160 => (0=>"00000011", 1=>"00000011", 2=>"00000011"),  -- 030303
    161 => (0=>"11111111", 1=>"11111111", 2=>"11111111"),  -- FFFFFF
    162 => (0=>"11111111", 1=>"10010100", 2=>"01110000"),  -- FF9470
    163 => (0=>"10100110", 1=>"10100110", 2=>"10100110"),  -- A6A6A6
    164 => (0=>"11111111", 1=>"11111111", 2=>"11001100"),  -- FFFFCC
    165 => (0=>"11111111", 1=>"11111111", 2=>"10110111"),  -- FFFFB7
    166 => (0=>"11001100", 1=>"11001100", 2=>"00000011"),  -- CCCC03
    167 => (0=>"11110000", 1=>"11110000", 2=>"00000011"),  -- F0F003
    168 => (0=>"00000011", 1=>"00000011", 2=>"00000011"),  -- 030303
    169 => (0=>"00000011", 1=>"11111111", 2=>"11111111"),  -- 03FFFF
    170 => (0=>"11111111", 1=>"00000011", 2=>"11111111"),  -- FF03FF
    171 => (0=>"10100110", 1=>"10100110", 2=>"10100110"),  -- A6A6A6
    172 => (0=>"11111111", 1=>"11111111", 2=>"11111111"),  -- FFFFFF
    173 => (0=>"11001100", 1=>"11001100", 2=>"11001100"),  -- CCCCCC
    174 => (0=>"10100110", 1=>"10100110", 2=>"10100110"),  -- A6A6A6
    175 => (0=>"10110111", 1=>"10110111", 2=>"10110111"),  -- B7B7B7
    176 => (0=>"10100110", 1=>"10000100", 2=>"11011100"),  -- A684DC
    177 => (0=>"10010100", 1=>"10010100", 2=>"10010100"),  -- 949494
    178 => (0=>"11001100", 1=>"11111111", 2=>"11001100"),  -- CCFFCC
    179 => (0=>"11110000", 1=>"11110000", 2=>"11001100"),  -- F0F0CC
    180 => (0=>"00000011", 1=>"00000011", 2=>"11111111"),  -- 0303FF
    181 => (0=>"11110000", 1=>"10110111", 2=>"10010100"),  -- F0B794
    182 => (0=>"10110111", 1=>"11110000", 2=>"11110000"),  -- B7F0F0
    183 => (0=>"11001100", 1=>"10100110", 2=>"10000100"),  -- CCA684
    184 => (0=>"11111111", 1=>"11111111", 2=>"11111111"),  -- FFFFFF
    185 => (0=>"11111111", 1=>"11111111", 2=>"11111111"),  -- FFFFFF
    186 => (0=>"10100110", 1=>"10000100", 2=>"11011100"),  -- A684DC
    187 => (0=>"11111111", 1=>"11111111", 2=>"11111111"),  -- FFFFFF
    188 => (0=>"00000011", 1=>"00000011", 2=>"00000011"),  -- 030303
    189 => (0=>"11111111", 1=>"11111111", 2=>"11111111"),  -- FFFFFF
    190 => (0=>"11111111", 1=>"11111111", 2=>"11111111"),  -- FFFFFF
    191 => (0=>"11111111", 1=>"11111111", 2=>"11111111"),  -- FFFFFF
    192 => (0=>"11111111", 1=>"11111111", 2=>"11111111"),  -- FFFFFF
    193 => (0=>"11111111", 1=>"11111111", 2=>"11111111"),  -- FFFFFF
    194 => (0=>"00000011", 1=>"00000011", 2=>"00000011"),  -- 030303
    195 => (0=>"11111111", 1=>"11111111", 2=>"11111111"),  -- FFFFFF
    196 => (0=>"11111111", 1=>"00000011", 2=>"00000011"),  -- FF0303
    197 => (0=>"11111111", 1=>"11111111", 2=>"11111111"),  -- FFFFFF
    198 => (0=>"11111111", 1=>"11111111", 2=>"11111111"),  -- FFFFFF
    199 => (0=>"11111111", 1=>"11111111", 2=>"11111111"),  -- FFFFFF
    200 => (0=>"10100110", 1=>"10000100", 2=>"11011100"),  -- A684DC
    201 => (0=>"11111111", 1=>"11111111", 2=>"00000011"),  -- FFFF03
    202 => (0=>"10100110", 1=>"10000100", 2=>"11011100"),  -- A684DC
    203 => (0=>"11111111", 1=>"11111111", 2=>"00000011"),  -- FFFF03
    204 => (0=>"11111111", 1=>"00000011", 2=>"00000011"),  -- FF0303
    205 => (0=>"11111111", 1=>"11111111", 2=>"00000011"),  -- FFFF03
    206 => (0=>"00000011", 1=>"00000011", 2=>"10100110"),  -- 0303A6
    207 => (0=>"11111111", 1=>"11111111", 2=>"11111111"),  -- FFFFFF
    208 => (0=>"10100110", 1=>"10000100", 2=>"11011100"),  -- A684DC
    209 => (0=>"11111111", 1=>"00000011", 2=>"00000011"),  -- FF0303
    210 => (0=>"10100110", 1=>"10000100", 2=>"11011100"),  -- A684DC
    211 => (0=>"11111111", 1=>"11111111", 2=>"11111111"),  -- FFFFFF
    212 => (0=>"11111111", 1=>"00000011", 2=>"00000011"),  -- FF0303
    213 => (0=>"11111111", 1=>"10010100", 2=>"10010100"),  -- FF9494
    214 => (0=>"00000011", 1=>"00000011", 2=>"00000011"),  -- 030303
    215 => (0=>"11111111", 1=>"11111111", 2=>"11111111"),  -- FFFFFF
    216 => (0=>"11111111", 1=>"11110000", 2=>"11011100"),  -- FFF0DC
    217 => (0=>"10100110", 1=>"10100110", 2=>"10100110"),  -- A6A6A6
    218 => (0=>"00000011", 1=>"00000011", 2=>"00000011"),  -- 030303
    219 => (0=>"11111111", 1=>"11111111", 2=>"00000011"),  -- FFFF03
    220 => (0=>"11111111", 1=>"00000011", 2=>"00000011"),  -- FF0303
    221 => (0=>"11111111", 1=>"11001100", 2=>"10110111"),  -- FFCCB7
    222 => (0=>"11011100", 1=>"10110111", 2=>"10010100"),  -- DCB794
    223 => (0=>"11110000", 1=>"11001100", 2=>"10100110"),  -- F0CCA6
    224 => (0=>"01100010", 1=>"01100010", 2=>"01100010"),  -- 626262
    225 => (0=>"11111111", 1=>"11111111", 2=>"00000011"),  -- FFFF03
    226 => (0=>"11111111", 1=>"00000011", 2=>"00000011"),  -- FF0303
    227 => (0=>"11011100", 1=>"00100010", 2=>"11001100"),  -- DC22CC
    228 => (0=>"11001100", 1=>"11110000", 2=>"11001100"),  -- CCF0CC
    229 => (0=>"10000100", 1=>"11001100", 2=>"10000100"),  -- 84CC84
    230 => (0=>"11111111", 1=>"11111111", 2=>"11111111"),  -- FFFFFF
    231 => (0=>"11110000", 1=>"11011100", 2=>"10100110"),  -- F0DCA6
    232 => (0=>"10100110", 1=>"10000100", 2=>"11011100"),  -- A684DC
    233 => (0=>"11111111", 1=>"11111111", 2=>"00000011"),  -- FFFF03
    234 => (0=>"11111111", 1=>"00000011", 2=>"00000011"),  -- FF0303
    235 => (0=>"11110000", 1=>"11110000", 2=>"11001100"),  -- F0F0CC
    236 => (0=>"01100010", 1=>"01100010", 2=>"01100010"),  -- 626262
    237 => (0=>"11110000", 1=>"11011100", 2=>"10100110"),  -- F0DCA6
    238 => (0=>"11011100", 1=>"00100010", 2=>"11001100"),  -- DC22CC
    239 => (0=>"10110111", 1=>"10000100", 2=>"00000011"),  -- B78403
    240 => (0=>"01100010", 1=>"01100010", 2=>"01100010"),  -- 626262
    241 => (0=>"10110111", 1=>"10000100", 2=>"00000011"),  -- B78403
    242 => (0=>"11111111", 1=>"11111111", 2=>"00000011"),  -- FFFF03
    243 => (0=>"11011100", 1=>"00100010", 2=>"11001100"),  -- DC22CC
    244 => (0=>"00000011", 1=>"10110111", 2=>"00000011"),  -- 03B703
    245 => (0=>"11110000", 1=>"11011100", 2=>"10100110"),  -- F0DCA6
    246 => (0=>"11111111", 1=>"00000011", 2=>"00000011"),  -- FF0303
    247 => (0=>"11111111", 1=>"11111111", 2=>"11111111"),  -- FFFFFF
    248 => (0=>"11111111", 1=>"11110000", 2=>"11011100"),  -- FFF0DC
    249 => (0=>"11111111", 1=>"00000011", 2=>"00000011"),  -- FF0303
    250 => (0=>"10010100", 1=>"10000100", 2=>"10110111"),  -- 9484B7
    251 => (0=>"10110111", 1=>"10000100", 2=>"00000011"),  -- B78403
    252 => (0=>"10100110", 1=>"10100110", 2=>"10100110"),  -- A6A6A6
    253 => (0=>"10000100", 1=>"11001100", 2=>"10000100"),  -- 84CC84
    254 => (0=>"11011100", 1=>"11001100", 2=>"10110111"),  -- DCCCB7
    255 => (0=>"11110000", 1=>"11110000", 2=>"11001100"),  -- F0F0CC
		others => (others => (others => '0'))
  );
                                          
	constant sprite_pal : pal_a(0 to 15) :=
	(
    1 => (0=>"00000000", 1=>"00000000", 2=>"00011010"),
    2 => (0=>"11000001", 1=>"00000000", 2=>"10101110"),
    3 => (0=>"00000000", 1=>"10101110", 2=>"11001000"),
    4 => (0=>"10000100", 1=>"11001000", 2=>"00000000"),
    5 => (0=>"11000001", 1=>"00000000", 2=>"00000000"),
    6 => (0=>"00000000", 1=>"11001000", 2=>"00000000"),
    7 => (0=>"10000100", 1=>"00000000", 2=>"00000000"),
    8 => (0=>"11000001", 1=>"11001000", 2=>"11001000"),
    9 => (0=>"11000001", 1=>"11001000", 2=>"00000000"),
    10 => (0=>"10000100", 1=>"01010001", 2=>"00000000"),
    11 => (0=>"00111110", 1=>"00110111", 2=>"00000000"),
    12 => (0=>"00111110", 1=>"00000000", 2=>"11001000"),
    13 => (0=>"11000001", 1=>"10010000", 2=>"00000000"),
    14 => (0=>"00111110", 1=>"10010000", 2=>"11001000"),
    15 => (0=>"00000000", 1=>"01010001", 2=>"00000000"),
		others => (others => (others => '0'))
	);

  type table_a is array (natural range <>) of integer range 0 to 15;
  constant sprite_table : table_a(0 to 63) :=
  (
    1 => 1,
    2 => 2,
    3 => 3,
    5 => 4,
    6 => 2,
    7 => 5,
    9 => 5,
    10 => 6,
    11 => 7,
    13 => 7,
    14 => 8,
    15 => 9,
    17 => 10,
    19 => 11,
    29 => 9,
    30 => 14,
    31 => 5,
    33 => 5,
    34 => 3,
    35 => 15,
    37 => 9,
    38 => 1,
    39 => 5,
    41 => 1,
    42 => 8,
    45 => 1,
    46 => 5,
    49 => 1,
    50 => 5,
    51 => 3,
    53 => 4,
    54 => 13,
    55 => 5,
    57 => 5,
    59 => 5,
    62 => 5,
    63 => 5,
    others => 0
  );
  
end package platform_variant_pkg;
