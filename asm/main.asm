; *************************************************************************************
; Boulder Dash version 2 by raspberrypioneer 2024
;
; This version enhances the disassembly of Boulderdash, by TobyLobster 2024
; See https://github.com/TobyLobster/Boulderdash for the original version
;
; It includes the following three main features:
; Loading caves from files
;   - Cave parameters (diamonds needed, cave time etc) and the map layout are loaded from 
;     individual cave files, one for each of the caves A-T (credit to billcarr2005 for this)
;   - Each cave file contains everything needed to use that cave with the game engine. The  
;     cave definition has the structure described below
;   - This approach allows new caves to be developed and used with the main game engine, 
;     including caves developed by Boulder Dash fans, see https://www.boulder-dash.nl/
;
; Preservation of the original version of the game
;   - The original version is preserved by having the difficulty levels use the 'standard' 
;     pseudo-random method of plotting boulders, diamonds, etc in a cave (same method used 
;     by the original Boulder Dash developer, Peter Liepa)
;   - Cave files are used for the basic essential tiles needed to form the map and are drawn 
;     first. They include 'null' tiles which are replaced by the tiles produced by the random 
;     plotting method which happens next
;
; Additions to support the Boulder Dash 2 game
;   - New elements introduced, slime and growing wall
;   - Slime allows rocks and diamonds to pass through it but nothing else. It requires a new 
;     slime permeability cave parameter to control how quickly those elements permeate. 
;     Used in caves E (random delay) and M (no pass-through delay)
;   - Growing wall allows a wall to extend horizontally if the item beside it is empty space. 
;     Used in cave O only
;   - Caves G and K require two tiles to be plotted using the pseudo-random method instead 
;     of just one. These tiles may differ, and the second one is plotted below the first one. 
;     The cave parameters include the 4 tiles needed to populate the second tile
;   - Cave tiles are now plotted by applying the basic essential tiles from the cave file 
;     first, followed by random ones if allowed by use of the 'null' tile 
;     (previously the other way around). Needed to support the two-tile random plot above
;   - The starting position of butterflies and fireflies in some caves has needed slight 
;     adjustment. Those elements can sometimes attempt to travel in a different default 
;     direction in the original game (e.g. right instead of left). Support for an extra 3 
;     versions of butterflies and fireflies would be required to replicate this, however 
;     setting different starting positions is a great substitute. This affects caves 
;     A, F, H which still play in much the same way as the original game
;   - None of this affects the original Boulder Dash game
;
; As a result of these changes there are many unused bytes which could be removed if 
; necessary.
;
;
; Cave file structure
; -------------------
; 48 bytes for cave parameters. See the label cave_parameter_data for details.
; 400 bytes for the tile map. Each tile is a nibble (each byte represents two tiles)
; In total there are 800 tiles for the interior of the cave (20 rows by 40 columns)
; The top and bottom steel walls are not included and are plotted by the game engine.
;
; From the original disassembly ...
; Ingredients
; -----------
;
; Caves: There are 20 caves total (16 main caves A-P plus four bonus caves Q-T)
; Difficulty levels: 1-5 for each cave
;
; * A *stage* consists of a cave letter and difficulty level. e.g. A1 is a stage.
;
; * The *tile map* is the 40x22 map of the entire stage.
;   Map rows are separated by 64 bytes in memory, despite only being 40 bytes in length.
;   (This simplifies the conversion between row number and address and vice-versa).
;
;   Sometimes other data is stored in the spare bytes between rows.
;
;   Each entry in the tile map is a *cell*, which holds a basic cell type in the lower
;   4 bits and a modifier in the top four bits. These are converted into sprites using
;   the 'cell_type_to_sprite' lookup table.
;
; * The *grid* is the visible area of sprites, showing a 20x12 section of the tile map.
;
;   An offscreen cache of the sprites currently displayed in the grid is stored in the
; 'grid_of_currently_displayed_sprites' array.
;
;   By consulting and updating the cache, we only draw sprites that have changed since
;   the previous tick.
;
; * The *status bar* is single row of text at the top of the grid, showing the current
; score etc.
;
;   Each player has a status bar, and different status bars are shown while paused.
;
; Cell values in tile_map:
;   $00 = map_space
;   $01 = map_earth
;   $02 = map_wall
;   $03 = map_titanium_wall       (as seen on the border of the whole map)
;   $04 = map_diamond
;   $05 = map_rock
;   $06 = map_firefly             (with animation states $06, $16, $26, $36)
;   $07 = map_amoeba              (states $07, $17, $27, $37, $47, $57, $67, and $77 as the amoeba grows)
;   $08 = map_rockford_appearing_or_end_position
;   $09 = map_slime
;   $0a = map_explosion
;   $0b = map_bomb                (new element, animation states $0b to $7b as timer ticks)
;   $0c = map_growing_wall
;   $0d = map_magic_wall
;   $0e = map_butterfly           (with animation states $0e, $1e, $2e, $3e)
;   $0f = map_rockford            ($0f=waiting, $1f=walking left, $2f=walking right)
;
; Upper nybble sometimes holds an animation state, and top bit is a flag depending on context:
;   $00 = map_anim_state0
;   $10 = map_anim_state1
;   $20 = map_anim_state2
;   $30 = map_anim_state3
;   $40 = map_anim_state4
;   $50 = map_anim_state5
;   $60 = map_anim_state6
;   $70 = map_anim_state7
;   $80 = map_unprocessed
;   $c0 = map_deadly              (cell is deadly, directly below a rock or diamond that fell)
;
; Special cases:
;   $18 = map_active_exit         (exit is available and flashing)
;
;   $46 = map_start_large_explosion   (first state of the 'death' explosion for rockford / firefly / butterfly)
;   $33 = map_large_explosion_state3
;   $23 = map_large_explosion_state2
;   $13 = map_large_explosion_state1
;   $45 = rock that's just fallen this tick
;
; *************************************************************************************

; Constants
inkey_key_b                              = 155
inkey_key_colon                          = 183
inkey_key_escape                         = 143
inkey_key_return                         = 182
inkey_key_slash                          = 151
inkey_key_space                          = 157
inkey_key_x                              = 189
inkey_key_z                              = 158
map_active_exit                          = 24
map_anim_state0                          = 0
map_anim_state1                          = 16
map_anim_state2                          = 32
map_anim_state3                          = 48
map_anim_state4                          = 64
map_anim_state5                          = 80
map_anim_state6                          = 96
map_anim_state7                          = 112
map_butterfly                            = 14
map_deadly                               = 192
map_diamond                              = 4
map_earth                                = 1
map_explosion                            = 10
map_firefly                              = 6
map_slime                                = 9
map_amoeba                               = 7
map_growing_wall                         = 12
map_large_explosion_state1               = 19
map_large_explosion_state2               = 35
map_large_explosion_state3               = 51
map_magic_wall                           = 13
map_rock                                 = 5
map_rockford                             = 15
map_rockford_appearing_or_end_position   = 8
map_space                                = 0
map_start_large_explosion                = 70
map_titanium_wall                        = 3
map_unprocessed                          = 128
map_bomb                                 = 11
map_wall                                 = 2
opcode_dex                               = 202
opcode_inx                               = 232
opcode_lda_abs_y                         = 185
opcode_ldy_abs                           = 172
osbyte_flush_buffer_class                = 15
osbyte_inkey                             = 129
osbyte_read_adc_or_get_buffer_status     = 128
osword_read_clock                        = 1
osword_sound                             = 7
osword_write_clock                       = 2
osword_write_palette                     = 12
sprite_0                                 = 50
sprite_1                                 = 51
sprite_2                                 = 52
sprite_3                                 = 53
sprite_4                                 = 54
sprite_5                                 = 55
sprite_6                                 = 56
sprite_7                                 = 57
sprite_8                                 = 58
sprite_9                                 = 59
sprite_boulder1                          = 1
sprite_boulder2                          = 2
sprite_box                               = 9
sprite_butterfly1                        = 22
sprite_butterfly2                        = 23
sprite_butterfly3                        = 24
sprite_comma                             = 63
sprite_diamond1                          = 3
sprite_diamond2                          = 4
sprite_diamond3                          = 5
sprite_diamond4                          = 6
sprite_earth1                            = 29
sprite_earth2                            = 30
sprite_equals                            = 61
sprite_explosion1                        = 12
sprite_explosion2                        = 13
sprite_explosion3                        = 14
sprite_explosion4                        = 15
sprite_firefly1                          = 25
sprite_firefly2                          = 26
sprite_firefly3                          = 27
sprite_firefly4                          = 28
sprite_full_stop                         = 64
sprite_amoeba1                           = 20
sprite_amoeba2                           = 21
sprite_magic_wall1                       = 16
sprite_magic_wall2                       = 17
sprite_magic_wall3                       = 18
sprite_magic_wall4                       = 19
sprite_pathway                           = 31
sprite_rockford_blinking1                = 32
sprite_rockford_blinking2                = 33
sprite_rockford_blinking3                = 34
sprite_rockford_moving_left1             = 42
sprite_rockford_moving_left2             = 43
sprite_rockford_moving_left3             = 44
sprite_rockford_moving_left4             = 45
sprite_rockford_moving_right1            = 46
sprite_rockford_moving_right2            = 47
sprite_rockford_moving_right3            = 48
sprite_rockford_moving_right4            = 49
sprite_rockford_tapping_foot1            = 37
sprite_rockford_tapping_foot2            = 38
sprite_rockford_tapping_foot3            = 39
sprite_rockford_tapping_foot4            = 40
sprite_rockford_tapping_foot5            = 41
sprite_rockford_winking1                 = 35
sprite_rockford_winking2                 = 36
sprite_slash                             = 62
sprite_space                             = 0
sprite_titanium_wall1                    = 7
sprite_titanium_wall2                    = 8
sprite_wall1                             = 10
sprite_wall2                             = 11
sprite_white                             = 60
sprite_bomb1                             = 91
sprite_bomb2                             = 92
sprite_bomb3                             = 93
sprite_bomb4                             = 94
sprite_bubble1                           = 95
total_caves                              = 20

; Memory locations
page_0                                  = $00
data_set_ptr_low                        = $46
sound0_active_flag                      = $46
data_set_ptr_high                       = $47
sound1_active_flag                      = $47
remember_y                              = $48
sound2_active_flag                      = $48
sound3_active_flag                      = $49
sound4_active_flag                      = $4a
sound5_active_flag                      = $4b
sound6_active_flag                      = $4c
sound7_active_flag                      = $4d
pause_counter                           = $4e
gravity_timer                           = $4f
magic_wall_state                        = $50
magic_wall_timer                        = $51
rockford_cell_value                     = $52
delay_trying_to_push_rock               = $53
amoeba_replacement                      = $54
amoeba_growth_interval                  = $55
number_of_amoeba_cells_found            = $56
amoeba_counter                          = $57
ticks_since_last_direction_key_pressed  = $58
countdown_while_switching_palette       = $59
tick_counter                            = $5a
current_rockford_sprite                 = $5b
sub_second_ticks                        = $5c
previous_direction_keys                 = $5d
just_pressed_direction_keys             = $5e
rockford_explosion_cell_type            = $5f
current_amoeba_cell_type                = $60
keys_to_process                         = $62
neighbour_cell_contents                 = $64
demo_mode_tick_count                    = $65
zeroed_but_unused                       = $66
demo_key_duration                       = $67
status_text_address_low                 = $69
map_rockford_end_position_addr_low      = $6a
timeout_until_demo_mode                 = $6a
map_rockford_end_position_addr_high     = $6b
diamonds_required                       = $6c
time_remaining                          = $6d
bomb_delay                              = $6e
bonus_life_available_flag               = $6f
map_rockford_current_position_addr_low  = $70
map_rockford_current_position_addr_high = $71
amount_to_increment_status_bar          = $72
dissolve_to_solid_flag                  = $72
cell_above_left                         = $73
grid_column_counter                     = $73
grid_x                                  = $73
neighbouring_cell_variable              = $73
cell_above                              = $74
out_of_time_message_countdown           = $74
cell_above_right                        = $75
cell_left                               = $76
cell_current                            = $77
loop_counter                            = $77
amount_to_increment_ptr_minus_one       = $78
cell_right                              = $78
cell_below_left                         = $79
initial_cell_fill_value                 = $79
value_to_clear_map_to                   = $79
cell_below                              = $7a
cell_below_right                        = $7b
lower_nybble_value                      = $7c
real_keys_pressed                       = $7c
x_loop_counter                          = $7c
bomb_counter                            = $7d
visible_top_left_map_x                  = $7e
visible_top_left_map_y                  = $7f
screen_addr2_low                        = $80
screen_addr2_high                       = $81
next_ptr_low                            = $82
next_ptr_high                           = $83
wait_delay_centiseconds                 = $84
tile_map_ptr_low                        = $85
tile_y                                  = $85
tile_map_ptr_high                       = $86
tile_x                                  = $86
cave_number                             = $87
random_seed                             = $88
difficulty_level                        = $89
map_x                                   = $8a
screen_addr1_low                        = $8a
map_y                                   = $8b
screen_addr1_high                       = $8b
map_address_low                         = $8c
ptr_low                                 = $8c
map_address_high                        = $8d
ptr_high                                = $8d
sound_channel                           = $8e
offset_to_sound                         = $8f

l0ba9                                   = $0ba9
grid_of_currently_displayed_sprites     = $0c00
start_of_grid_screen_address            = $5bc0
screen_addr_row_6                       = $5f80
screen_addr_row_28                      = $7b00
screen_addr_row_30                      = $7d80
osword                                  = $fff1
osbyte                                  = $fff4
lfff6                                   = $fff6
oscli_instruction_for_load              = $fff7

    * = $1300

sprite_addr_space
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; 1300: 00 00 00... ...
    !byte 0, 0, 0, 0, 0, 0                                                              ; 131a: 00 00 00... ...
sprite_addr_boulder1
    !byte $33, $57, $bf, $2d, $69, $c3, $87, $0f, $88, $4c, $ae, $7f, $7f, $b7, $3f     ; 1320: 33 57 bf... 3W.
    !byte $7b, $0b, $0d, $0b, $0d, $2c, $78, $42,   3, $3d, $1e, $0f, $0f, $0e, $0e     ; 132f: 7b 0b 0d... {..
    !byte $0c,   8                                                                      ; 133e: 0c 08       ..
sprite_addr_boulder2  ;now a bubble
    !byte $11, $23, $44, $44, $88, $88, $00, $88, $88, $44, $2a, $22, $11, $11, $11, $00
    !byte $88, $00, $88, $88, $46, $54, $23, $11, $11, $15, $11, $19, $22, $26, $c4, $88
;    !byte $33, $57, $af, $4f, $0f, $0f, $0f, $0f, $88, $4c, $ae, $7f, $7f, $37, $3f     ; 1340: 33 57 af... 3W.
;    !byte $1f, $0b, $0d, $0b, $0d, $0e, $0f,   6,   3, $0f, $0f, $0f, $0f, $0e, $0e     ; 134f: 1f 0b 0d... ...
;    !byte $0c,   8                                                                      ; 135e: 0c 08       ..
sprite_addr_diamond1
    !byte $11, $11, $13, $23, $77, $37, $df, $ef,   0,   0, $88, $88, $4c, $8c, $ce     ; 1360: 11 11 13... ...
    !byte $ee, $7f, $bf, $57, $67, $33, $33, $11,   1, $6e, $ae, $cc, $cc,   8, $88     ; 136f: ee 7f bf... ...
    !byte   0,   0                                                                      ; 137e: 00 00       ..
sprite_addr_diamond2
    !byte $11, $11, $23, $33, $37, $57, $ef, $7f,   0,   0, $88,   8, $8c, $cc, $ee     ; 1380: 11 11 23... ..#
    !byte $6e, $bf, $df, $67, $77, $33, $13,   1, $11, $ae, $ce, $cc, $4c, $88, $88     ; 138f: 6e bf df... n..
    !byte   0,   0                                                                      ; 139e: 00 00       ..
sprite_addr_diamond3
    !byte $11,   1, $33, $33, $57, $67, $7f, $bf,   0,   0,   8, $88, $cc, $cc, $6e     ; 13a0: 11 01 33... ..3
    !byte $ae, $df, $ef, $77, $37, $13, $23, $11, $11, $ce, $ee, $4c, $8c, $88, $88     ; 13af: ae df ef... ...
    !byte   0,   0                                                                      ; 13be: 00 00       ..
sprite_addr_diamond4
    !byte   1, $11, $33, $13, $67, $77, $bf, $df,   0,   0, $88, $88, $cc, $4c, $ae     ; 13c0: 01 11 33... ..3
    !byte $ce, $ef, $7f, $37, $57, $23, $33, $11, $11, $ee, $6e, $8c, $cc, $88,   8     ; 13cf: ce ef 7f... ...
    !byte   0,   0                                                                      ; 13de: 00 00       ..
sprite_addr_titanium_wall1
    !byte $0f, $0f,   9,   9, $4d, $4d, $0f, $0f, $0f, $0f,   9,   9, $4d, $4d, $0f     ; 13e0: 0f 0f 09... ...
    !byte $0f, $0f, $0f,   9,   9, $4d, $4d, $0f, $0f, $0f, $0f,   9,   9, $4d, $4d     ; 13ef: 0f 0f 0f... ...
    !byte $0f, $0f                                                                      ; 13fe: 0f 0f       ..
sprite_addr_titanium_wall2
    !byte $0f, $0f,   9,   9, $4d, $4d, $0f, $0f, $0f, $0f,   9,   9, $4d, $4d, $0f     ; 1400: 0f 0f 09... ...
    !byte $0f, $0f, $0f,   9,   9, $4d, $4d, $0f, $0f, $0f, $0f,   9,   9, $4d, $4d     ; 140f: 0f 0f 0f... ...
    !byte $0f, $0f                                                                      ; 141e: 0f 0f       ..
sprite_addr_box
    !byte $0f, $0f,   8,   8,   8,   8,   8,   8, $0f, $0f,   1,   1,   1,   1,   1     ; 1420: 0f 0f 08... ...
    !byte   1,   8,   8,   8,   8,   8,   8, $0f, $0f,   1,   1,   1,   1,   1,   1     ; 142f: 01 08 08... ...
    !byte $0f, $0f                                                                      ; 143e: 0f 0f       ..
sprite_addr_wall1
    !byte $77, $37,   7,   0, $ee, $ee, $0e,   0, $ee, $ee, $0e,   0, $77, $37,   7     ; 1440: 77 37 07... w7.
    !byte   0, $77, $37,   7,   0, $ee, $ee, $0e,   0, $ee, $ee, $0e,   0, $77, $37     ; 144f: 00 77 37... .w7
    !byte   7,   0                                                                      ; 145e: 07 00       ..
sprite_addr_wall2
    !byte $77, $37,   7,   0, $ee, $ee, $0e,   0, $ee, $ee, $0e,   0, $77, $37,   7     ; 1460: 77 37 07... w7.
    !byte   0, $77, $37,   7,   0, $ee, $ee, $0e,   0, $ee, $ee, $0e,   0, $77, $37     ; 146f: 00 77 37... .w7
    !byte   7,   0                                                                      ; 147e: 07 00       ..
sprite_addr_explosion1
    !byte   0,   0,   0,   0, $11, $44,   1, $22,   0,   0,   0,   0,   0, $88,   0     ; 1480: 00 00 00... ...
    !byte $aa, $10, $13, $22,   0, $11,   0,   0,   0, $84, $c4,   8,   0,   0,   0     ; 148f: aa 10 13... ...
    !byte   0,   0                                                                      ; 149e: 00 00       ..
sprite_addr_explosion2
    !byte   0,   0,   0, $11, $88,   1,   0, $44,   0,   0,   0,   0, $88,   0, $44     ; 14a0: 00 00 00... ...
    !byte $51, $20,   0,   4, $22, $44, $11,   0,   0,   2,   0, $a2,   8,   0,   0     ; 14af: 51 20 00... Q .
    !byte   0,   0                                                                      ; 14be: 00 00       ..
sprite_addr_explosion3
    !byte   0,   0, $11,   0,   2,   0,   0,   0,   0,   0,   0, $44,   0, $22,   0     ; 14c0: 00 00 11... ...
    !byte $31, $88, $40,   0,   8, $22, $88, $11,   0,   0,   1,   0, $80, $15,   0     ; 14cf: 31 88 40... 1.@
    !byte   0,   0                                                                      ; 14de: 00 00       ..
sprite_addr_explosion4
    !byte   0, $11,   0,   4,   0,   0,   0,   0,   0,   0, $22,   0, $11,   0,   0     ; 14e0: 00 11 00... ...
    !byte $10,   0, $80,   0,   0, $22,   0, $88, $11,   0,   1,   0,   0, $80, $15     ; 14ef: 10 00 80... ...
    !byte   0,   0                                                                      ; 14fe: 00 00       ..
sprite_addr_magic_wall1
    !byte $77, $37,   7, $4c, $ee, $ee, $0e,   0, $ee, $ee, $0e,   0, $77, $37,   7     ; 1500: 77 37 07... w7.
    !byte $23, $77, $37,   7, $4c, $ee, $ee, $0e,   0, $ee, $ee, $0e,   0, $77, $37     ; 150f: 23 77 37... #w7
    !byte   7, $23                                                                      ; 151e: 07 23       .#
sprite_addr_magic_wall2
    !byte $77, $37,   7, $13, $ee, $ee, $0e,   0, $ee, $ee, $0e,   0, $77, $37,   7     ; 1520: 77 37 07... w7.
    !byte $8c, $77, $37,   7, $13, $ee, $ee, $0e,   0, $ee, $ee, $0e,   0, $77, $37     ; 152f: 8c 77 37... .w7
    !byte   7, $8c                                                                      ; 153e: 07 8c       ..
sprite_addr_magic_wall3
    !byte $77, $37,   7,   0, $ee, $ee, $0e, $23, $ee, $ee, $0e, $4c, $77, $37,   7     ; 1540: 77 37 07... w7.
    !byte   0, $77, $37,   7,   0, $ee, $ee, $0e, $23, $ee, $ee, $0e, $4c, $77, $37     ; 154f: 00 77 37... .w7
    !byte   7,   0                                                                      ; 155e: 07 00       ..
sprite_addr_magic_wall4
    !byte $77, $37,   7,   0, $ee, $ee, $0e, $8c, $ee, $ee, $0e, $13, $77, $37,   7     ; 1560: 77 37 07... w7.
    !byte   0, $77, $37,   7,   0, $ee, $ee, $0e, $8c, $ee, $ee, $0e, $13, $77, $37     ; 156f: 00 77 37... .w7
    !byte   7,   0                                                                      ; 157e: 07 00       ..
sprite_addr_amoeba1
    !byte $2e, $1f, $0f, $8f, $47, $8f, $0f, $0f, $47, $8f, $0f, $0f, $1f, $0f, $0f     ; 1580: 2e 1f 0f... ...
    !byte $cf, $cf, $23, $23, $cf, $0f, $1f, $2e, $4c, $cf, $1f, $1f, $0f, $0f, $8f     ; 158f: cf cf 23... ..#
    !byte $47, $23                                                                      ; 159e: 47 23       G#
sprite_addr_amoeba2
    !byte $1f, $0f, $8f, $47, $23, $47, $8f, $1f, $8f, $0f, $0f, $1f, $2e, $1f, $cf     ; 15a0: 1f 0f 8f... ...
    !byte $23, $1f, $cf, $cf, $0f, $0f, $0f, $1f, $2e, $23, $cf, $0f, $0f, $0f, $0f     ; 15af: 23 1f cf... #..
    !byte $8f, $47                                                                      ; 15be: 8f 47       .G
sprite_addr_butterfly1
    !byte   0,   8, $88, $88, $8c, $cc, $ce, $ee,   0,   2, $22, $22, $26, $66, $6e     ; 15c0: 00 08 88... ...
    !byte $ee, $ff, $ee, $ce, $cc, $8c, $88, $88,   8, $ee, $ee, $6e, $66, $26, $22     ; 15cf: ee ff ee... ...
    !byte $22,   2                                                                      ; 15de: 22 02       ".
sprite_addr_butterfly2
    !byte   0,   4, $44, $44, $44, $46, $66, $66,   0,   4, $44, $44, $44, $4c, $cc     ; 15e0: 00 04 44... ..D
    !byte $cc, $77, $66, $66, $46, $44, $44, $44,   4, $cc, $cc, $cc, $4c, $44, $44     ; 15ef: cc 77 66... .wf
    !byte $44,   4                                                                      ; 15fe: 44 04       D.
sprite_addr_butterfly3
    !byte   0,   0,   2, $22, $22, $22, $22, $33,   0,   0,   8, $88, $88, $88, $88     ; 1600: 00 00 02... ...
    !byte $88, $33, $33, $22, $22, $22, $22,   2,   0, $88, $88, $88, $88, $88, $88     ; 160f: 88 33 33... .33
    !byte   8,   0                                                                      ; 161e: 08 00       ..
sprite_addr_firefly1
    !byte $ff, $ff, $f8, $f8, $cb, $cb, $ca, $ca, $ff, $ff, $f1, $f1, $3d, $3d, $35     ; 1620: ff ff f8... ...
    !byte $35, $ca, $ca, $cb, $cb, $f8, $f8, $ff, $ff, $35, $35, $3d, $3d, $f1, $f1     ; 162f: 35 ca ca... 5..
    !byte $ff, $ff                                                                      ; 163e: ff ff       ..
sprite_addr_firefly2
    !byte $f0, $f0, $87, $87, $84, $84, $95, $95, $f0, $f0, $1e, $1e, $12, $12, $9a     ; 1640: f0 f0 87... ...
    !byte $9a, $95, $95, $84, $84, $87, $87, $f0, $f0, $9a, $9a, $12, $12, $1e, $1e     ; 164f: 9a 95 95... ...
    !byte $f0, $f0                                                                      ; 165e: f0 f0       ..
sprite_addr_firefly3
    !byte $0f, $0f,   8,   8, $3b, $3b, $3a, $3a, $0f, $0f,   1,   1, $cd, $cd, $c5     ; 1660: 0f 0f 08... ...
    !byte $c5, $3a, $3a, $3b, $3b,   8,   8, $0f, $0f, $c5, $c5, $cd, $cd,   1,   1     ; 166f: c5 3a 3a... .::
    !byte $0f, $0f                                                                      ; 167e: 0f 0f       ..
sprite_addr_firefly4
    !byte   0,   0, $77, $77, $74, $74, $65, $65,   0,   0, $ee, $ee, $e2, $e2, $6a     ; 1680: 00 00 77... ..w
    !byte $6a, $65, $65, $74, $74, $77, $77,   0,   0, $6a, $6a, $e2, $e2, $ee, $ee     ; 168f: 6a 65 65... jee
    !byte   0,   0                                                                      ; 169e: 00 00       ..
sprite_addr_earth1
    !byte $20, $c0, $70, $d0, $f0, $a0, $70, $b0, $50, $90, $60, $d0, $b0, $e0, $b0     ; 16a0: 20 c0 70...  .p
    !byte $e0, $70, $d0, $e0, $70, $a0, $c0, $b0, $40, $f0, $e0, $d0, $70, $a0, $d0     ; 16af: e0 70 d0... .p.
    !byte $40, $a0                                                                      ; 16be: 40 a0       @.
sprite_addr_earth2
    !byte $20, $c0, $70, $d0, $f0, $a0, $70, $b0, $50, $90, $60, $d0, $b0, $e0, $b0     ; 16c0: 20 c0 70...  .p
    !byte $e0, $70, $d0, $e0, $70, $a0, $c0, $b0, $40, $f0, $e0, $d0, $70, $a0, $d0     ; 16cf: e0 70 d0... .p.
    !byte $40, $a0                                                                      ; 16de: 40 a0       @.
sprite_addr_pathway
    !byte   0, $77,   0,   0,   0, $ee,   0,   0,   0, $66,   0,   0,   0, $aa,   0     ; 16e0: 00 77 00... .w.
    !byte   0,   0, $55,   0,   0,   0, $ee,   0,   0,   0, $bb,   0,   0,   0, $99     ; 16ef: 00 00 55... ..U
    !byte   0,   0                                                                      ; 16fe: 00 00       ..
sprite_addr_rockford_blinking1
    !byte   0, $22, $33, $55, $55, $33, $11, $13,   0, $44, $cc, $aa, $aa, $cc, $88     ; 1700: 00 22 33... ."3
    !byte $8c,   5, $15,   1, $11, $23, $22, $22,   6, $0a, $8a,   8, $88, $4c, $44     ; 170f: 8c 05 15... ...
    !byte $44,   6                                                                      ; 171e: 44 06       D.
sprite_addr_rockford_blinking2
    !byte   0, $22, $33, $77, $55, $33, $11, $13,   0, $44, $cc, $ee, $aa, $cc, $88     ; 1720: 00 22 33... ."3
    !byte $8c,   5, $15,   1, $11, $23, $22, $22,   6, $0a, $8a,   8, $88, $4c, $44     ; 172f: 8c 05 15... ...
    !byte $44,   6                                                                      ; 173e: 44 06       D.
sprite_addr_rockford_blinking3
    !byte   0, $22, $33, $77, $77, $33, $11, $13,   0, $44, $cc, $ee, $ee, $cc, $88     ; 1740: 00 22 33... ."3
    !byte $8c,   5, $15,   1, $11, $23, $22, $22,   6, $0a, $8a,   8, $88, $4c, $44     ; 174f: 8c 05 15... ...
    !byte $44,   6                                                                      ; 175e: 44 06       D.
sprite_addr_rockford_winking1
    !byte   0, $22, $33, $55, $55, $33, $11, $13,   0, $44, $cc, $ee, $aa, $cc, $88     ; 1760: 00 22 33... ."3
    !byte $8c,   5, $15,   1, $11, $23, $22, $22,   6, $0a, $8a,   8, $88, $4c, $44     ; 176f: 8c 05 15... ...
    !byte $44,   6                                                                      ; 177e: 44 06       D.
sprite_addr_rockford_winking2
    !byte   0, $22, $33, $55, $55, $33, $11, $13,   0, $44, $cc, $ee, $ee, $cc, $88     ; 1780: 00 22 33... ."3
    !byte $8c,   5, $15,   1, $11, $23, $22, $22,   6, $0a, $8a,   8, $88, $4c, $44     ; 178f: 8c 05 15... ...
    !byte $44,   6                                                                      ; 179e: 44 06       D.
sprite_addr_rockford_moving_down1
    !byte   0, $22, $33, $55, $55, $33, $11, $13,   0, $44, $cc, $aa, $aa, $cc, $88     ; 17a0: 00 22 33... ."3
    !byte $8c,   5, $13,   1, $11, $23, $22, $22,   6, $0a, $8c,   8, $88, $4c, $44     ; 17af: 8c 05 13... ...
    !byte $44,   6                                                                      ; 17be: 44 06       D.
sprite_addr_rockford_moving_down2
    !byte   0, $22, $33, $55, $55, $33, $11, $13,   0, $44, $cc, $aa, $aa, $cc, $88     ; 17c0: 00 22 33... ."3
    !byte $8c,   5, $13,   1, $11, $23, $22,   6,   0, $0a, $8c,   8, $88, $4c, $44     ; 17cf: 8c 05 13... ...
    !byte $44,   6                                                                      ; 17de: 44 06       D.
sprite_addr_rockford_moving_down3
    !byte   0, $22, $33, $77, $55, $33, $11, $13,   0, $44, $cc, $ee, $aa, $cc, $88     ; 17e0: 00 22 33... ."3
    !byte $8c,   5, $13,   1, $11, $23, $22, $22,   6, $0a, $8c,   8, $88, $4c, $44     ; 17ef: 8c 05 13... ...
    !byte $44,   6                                                                      ; 17fe: 44 06       D.
sprite_addr_rockford_moving_up1
    !byte   0, $22, $33, $77, $77, $33, $11, $13,   0, $44, $cc, $ee, $ee, $cc, $88     ; 1800: 00 22 33... ."3
    !byte $8c,   5, $13,   1, $11, $23, $22,   6,   0, $0a, $8c,   8, $88, $4c, $44     ; 180f: 8c 05 13... ...
    !byte $44,   6                                                                      ; 181e: 44 06       D.
sprite_addr_rockford_moving_up2
    !byte   0, $22, $33, $77, $77, $33, $11, $13,   0, $44, $cc, $ee, $ee, $cc, $88     ; 1820: 00 22 33... ."3
    !byte $8c,   5, $13,   1, $11, $23, $22, $22,   6, $0a, $8c,   8, $88, $4c, $44     ; 182f: 8c 05 13... ...
    !byte $44,   6                                                                      ; 183e: 44 06       D.
sprite_addr_rockford_moving_left1
    !byte $11, $33, $55, $55, $33, $11, $11, $13, $88, $cc, $cc, $cc, $cc, $88, $88     ; 1840: 11 33 55... .3U
    !byte $88,   1, $11,   1, $11, $23, $44, $44, $0c,   8, $88,   8, $88, $6e,   1     ; 184f: 88 01 11... ...
    !byte   1,   0                                                                      ; 185e: 01 00       ..
sprite_addr_rockford_moving_left2
    !byte $11, $33, $55, $55, $33, $11, $11, $13, $88, $cc, $cc, $cc, $cc, $88, $88     ; 1860: 11 33 55... .3U
    !byte $88,   1, $11,   1, $11, $23, $22, $22,   6,   8, $88,   8, $88, $4c, $22     ; 186f: 88 01 11... ...
    !byte   2,   2                                                                      ; 187e: 02 02       ..
sprite_addr_rockford_moving_left3
    !byte   0, $11, $33, $55, $55, $33, $11, $13,   0, $88, $cc, $cc, $cc, $cc, $88     ; 1880: 00 11 33... ..3
    !byte $88,   1, $11,   1, $11,   1, $11, $11,   3,   8, $88,   8, $88,   8, $88     ; 188f: 88 01 11... ...
    !byte $cc,   4                                                                      ; 189e: cc 04       ..
sprite_addr_rockford_moving_left4
    !byte   0, $11, $33, $55, $55, $33, $11, $13,   0, $88, $cc, $cc, $cc, $cc, $88     ; 18a0: 00 11 33... ..3
    !byte $88,   1, $11,   1, $11,   1, $11, $11,   3,   8, $88,   8, $88,   8, $88     ; 18af: 88 01 11... ...
    !byte $88,   8                                                                      ; 18be: 88 08       ..
sprite_addr_rockford_moving_right1
    !byte   0, $11, $33, $33, $33, $33, $11, $11,   0, $88, $cc, $aa, $aa, $cc, $88     ; 18c0: 00 11 33... ..3
    !byte $8c,   1, $11,   1, $11,   1, $11, $11,   1,   8, $88,   8, $88,   8, $88     ; 18cf: 8c 01 11... ...
    !byte $88, $0c                                                                      ; 18de: 88 0c       ..
sprite_addr_rockford_moving_right2
    !byte   0, $11, $33, $33, $33, $33, $11, $11,   0, $88, $cc, $aa, $aa, $cc, $88     ; 18e0: 00 11 33... ..3
    !byte $8c,   1, $11,   1, $11,   1, $11, $33,   2,   8, $88,   8, $88,   8, $88     ; 18ef: 8c 01 11... ...
    !byte $88, $0c                                                                      ; 18fe: 88 0c       ..
sprite_addr_rockford_moving_right3
    !byte $11, $33, $33, $33, $33, $11, $11, $11, $88, $cc, $aa, $aa, $cc, $88, $88     ; 1900: 11 33 33... .33
    !byte $8c,   1, $11,   1, $11, $23, $44,   4,   4,   8, $88,   8, $88, $4c, $44     ; 190f: 8c 01 11... ...
    !byte $44,   6                                                                      ; 191e: 44 06       D.
sprite_addr_rockford_moving_right4
    !byte $11, $33, $33, $33, $33, $11, $11, $11, $88, $cc, $aa, $aa, $cc, $88, $88     ; 1920: 11 33 33... .33
    !byte $8c,   1, $11,   1, $11, $67,   8,   8,   0,   8, $88,   8, $88, $4c, $22     ; 192f: 8c 01 11... ...
    !byte $22,   3                                                                      ; 193e: 22 03       ".
sprite_addr_0
    !byte   0, $33, $34, $67, $68, $6e, $69, $7f,   0, $cc, $c0, $6e, $68, $ee, $e0     ; 1940: 00 33 34... .34
    !byte $ee, $78, $7f, $78, $6e, $68, $3f, $34,   7, $e0, $6e, $68, $6e, $68, $cc     ; 194f: ee 78 7f... .x.
    !byte $c0,   8                                                                      ; 195e: c0 08       ..
sprite_addr_1
    !byte   0, $11, $12, $33, $34, $17, $12, $13,   0, $88, $80, $88, $80, $88, $80     ; 1960: 00 11 12... ...
    !byte $88, $12, $13, $12, $13, $12, $77, $78, $0f, $80, $88, $80, $88, $80, $ee     ; 196f: 88 12 13... ...
    !byte $e0, $0c                                                                      ; 197e: e0 0c       ..
sprite_addr_2
    !byte   0, $33, $34, $67, $68, $0c,   0,   0,   0, $cc, $c0, $6e, $68, $6e, $68     ; 1980: 00 33 34... .34
    !byte $cc,   1, $11, $12, $33, $34, $77, $78, $0f, $c0, $88, $80,   0,   0, $ee     ; 198f: cc 01 11... ...
    !byte $e0, $0c                                                                      ; 199e: e0 0c       ..
sprite_addr_3
    !byte   0, $33, $34, $67, $68, $0c,   0, $11,   0, $cc, $c0, $6e, $68, $6e, $68     ; 19a0: 00 33 34... .34
    !byte $cc, $12,   3,   0, $66, $68, $3f, $34,   7, $c0, $6e, $68, $6e, $68, $cc     ; 19af: cc 12 03... ...
    !byte $c0,   8                                                                      ; 19be: c0 08       ..
sprite_addr_4
    !byte   0,   0,   1, $11, $12, $33, $34, $67,   0, $cc, $c0, $cc, $c0, $cc, $c0     ; 19c0: 00 00 01... ...
    !byte $cc, $69, $7f, $78, $0f,   1,   1,   1,   1, $c0, $ee, $e0, $cc, $c0, $cc     ; 19cf: cc 69 7f... .i.
    !byte $c0,   8                                                                      ; 19de: c0 08       ..
sprite_addr_5
    !byte   0, $77, $78, $6f, $68, $7f, $78, $0f,   0, $ee, $e0, $0c,   0, $cc, $c0     ; 19e0: 00 77 78... .wx
    !byte $6e,   0,   0,   0, $66, $68, $3f, $34,   7, $68, $6e, $68, $6e, $68, $cc     ; 19ef: 6e 00 00... n..
    !byte $c0,   8                                                                      ; 19fe: c0 08       ..
sprite_addr_6
    !byte   0, $11, $12, $33, $34, $66, $68, $7f,   0, $cc, $c0,   8,   0,   0,   0     ; 1a00: 00 11 12... ...
    !byte $cc, $78, $6f, $68, $6e, $68, $3f, $34,   7, $c0, $6e, $68, $6e, $68, $cc     ; 1a0f: cc 78 6f... .xo
    !byte $c0,   8                                                                      ; 1a1e: c0 08       ..
sprite_addr_7
    !byte   0, $77, $78, $0f,   0,   0,   1, $11,   0, $ee, $e0, $6e, $68, $cc, $c0     ; 1a20: 00 77 78... .wx
    !byte $88, $12, $33, $34, $37, $34, $37, $34,   6, $80,   0,   0,   0,   0,   0     ; 1a2f: 88 12 33... ..3
    !byte   0,   0                                                                      ; 1a3e: 00 00       ..
sprite_addr_8
    !byte   0, $33, $34, $67, $68, $6e, $68, $3f,   0, $cc, $c0, $6e, $68, $6e, $68     ; 1a40: 00 33 34... .34
    !byte $cc, $34, $67, $68, $6e, $68, $3f, $34,   7, $c0, $6e, $68, $6e, $68, $cc     ; 1a4f: cc 34 67... .4g
    !byte $c0,   8                                                                      ; 1a5e: c0 08       ..
sprite_addr_9
    !byte   0, $33, $34, $67, $68, $6e, $68, $3f,   0, $cc, $c0, $6e, $68, $6e, $68     ; 1a60: 00 33 34... .34
    !byte $ee, $34,   7,   0,   0,   1, $33, $34,   7, $e0, $6e, $68, $cc, $c0, $88     ; 1a6f: ee 34 07... .4.
    !byte $80,   0                                                                      ; 1a7e: 80 00       ..
sprite_addr_white
    !byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff     ; 1a80: ff ff ff... ...
    !byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff     ; 1a8f: ff ff ff... ...
    !byte $ff, $ff                                                                      ; 1a9e: ff ff       ..
sprite_addr_dash
    !byte   0,   0,   0,   0,   0, $77, $78, $0f,   0,   0,   0,   0,   0, $ee, $e0     ; 1aa0: 00 00 00... ...
    !byte $0c,   0, $77, $78, $0f,   0,   0,   0,   0,   0, $ee, $e0, $0c,   0,   0     ; 1aaf: 0c 00 77... ..w
    !byte   0,   0                                                                      ; 1abe: 00 00       ..
sprite_addr_slash
    !byte   0,   0,   0,   0,   0,   1, $10, $13,   0,   0, $60, $6e, $c0, $cc, $80     ; 1ac0: 00 00 00... ...
    !byte $88, $30, $37, $60, $6e, $0c,   0,   0,   0,   0,   0,   0,   0,   0,   0     ; 1acf: 88 30 37... .07
    !byte   0,   0                                                                      ; 1ade: 00 00       ..
sprite_addr_comma
    !byte   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0     ; 1ae0: 00 00 00... ...
    !byte   0,   0,   0,   0,   1,   1, $33, $34,   6,   0,   0, $c0, $cc, $c0, $cc     ; 1aef: 00 00 00... ...
    !byte   8,   0                                                                      ; 1afe: 08 00       ..
sprite_addr_full_stop
    !byte   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0     ; 1b00: 00 00 00... ...
    !byte   0,   0,   0, $11, $12, $13, $12,   3,   0,   0,   0, $88, $80, $88, $80     ; 1b0f: 00 00 00... ...
    !byte   0,   0                                                                      ; 1b1e: 00 00       ..
sprite_addr_A
    !byte   0, $33, $34, $67, $68, $6e, $68, $7f,   0, $cc, $c0, $6e, $68, $6e, $68     ; 1b20: 00 33 34... .34
    !byte $ee, $78, $6f, $68, $6e, $68, $6e, $68, $0c, $e0, $6e, $68, $6e, $68, $6e     ; 1b2f: ee 78 6f... .xo
    !byte $68, $0c                                                                      ; 1b3e: 68 0c       h.
sprite_addr_B
    !byte   0, $77, $78, $6f, $68, $6e, $68, $7f,   0, $cc, $c0, $6e, $68, $6e, $68     ; 1b40: 00 77 78... .wx
    !byte $cc, $78, $6f, $68, $6e, $68, $7f, $78, $0f, $c0, $6e, $68, $6e, $68, $cc     ; 1b4f: cc 78 6f... .xo
    !byte $c0,   8                                                                      ; 1b5e: c0 08       ..
sprite_addr_C
    !byte   0, $33, $34, $67, $68, $6e, $68, $6e,   0, $cc, $c0, $6e, $68, $0c,   0     ; 1b60: 00 33 34... .34
    !byte   0, $68, $6e, $68, $6e, $68, $3f, $34,   7,   0,   0,   0, $66, $68, $cc     ; 1b6f: 00 68 6e... .hn
    !byte $c0,   8                                                                      ; 1b7e: c0 08       ..
sprite_addr_D
    !byte   0, $77, $78, $6f, $69, $6f, $68, $6e,   0, $88, $80, $cc, $c0, $6e, $68     ; 1b80: 00 77 78... .wx
    !byte $6e, $68, $6e, $68, $6e, $69, $7f, $78, $0f, $68, $6e, $48, $cc, $c0, $88     ; 1b8f: 6e 68 6e... nhn
    !byte $80,   0                                                                      ; 1b9e: 80 00       ..
sprite_addr_E
    !byte   0, $77, $78, $6f, $68, $6e, $68, $7f,   0, $ee, $e0, $0c,   0,   0,   0     ; 1ba0: 00 77 78... .wx
    !byte $cc, $78, $6f, $68, $6e, $68, $7f, $78, $0f, $c0,   8,   0,   0,   0, $ee     ; 1baf: cc 78 6f... .xo
    !byte $e0, $0c                                                                      ; 1bbe: e0 0c       ..
sprite_addr_F
    !byte   0, $77, $78, $6f, $68, $6e, $68, $7f,   0, $ee, $e0, $0c,   0,   0,   0     ; 1bc0: 00 77 78... .wx
    !byte $cc, $78, $6f, $68, $6e, $68, $6e, $68, $0c, $c0,   8,   0,   0,   0,   0     ; 1bcf: cc 78 6f... .xo
    !byte   0,   0                                                                      ; 1bde: 00 00       ..
sprite_addr_G
    !byte   0, $33, $34, $6f, $68, $6e, $68, $6e,   0, $cc, $c0, $6e, $68, $0c,   0     ; 1be0: 00 33 34... .34
    !byte $ee, $69, $6f, $68, $6e, $68, $3f, $34,   7, $e0, $6e, $68, $6e, $68, $cc     ; 1bef: ee 69 6f... .io
    !byte $c0,   8                                                                      ; 1bfe: c0 08       ..
sprite_addr_H
    !byte   0, $66, $68, $6e, $68, $6e, $68, $7f,   0, $66, $68, $6e, $68, $6e, $68     ; 1c00: 00 66 68... .fh
    !byte $ee, $78, $6f, $68, $6e, $68, $6e, $68, $0c, $e0, $6e, $68, $6e, $68, $6e     ; 1c0f: ee 78 6f... .xo
    !byte $68, $0c                                                                      ; 1c1e: 68 0c       h.
sprite_addr_I
    !byte   0, $77, $78, $1f, $12, $13, $12, $13,   0, $ee, $e0, $8c, $80, $88, $80     ; 1c20: 00 77 78... .wx
    !byte $88, $12, $13, $12, $13, $12, $77, $78, $0f, $80, $88, $80, $88, $80, $ee     ; 1c2f: 88 12 13... ...
    !byte $e0, $0c                                                                      ; 1c3e: e0 0c       ..
sprite_addr_J
    !byte   0, $33, $34,   7,   1,   1,   1,   1,   0, $ee, $e0, $cc, $c0, $cc, $c0     ; 1c40: 00 33 34... .34
    !byte $cc,   1,   1,   1, $67, $69, $3f, $34,   7, $c0, $cc, $c0, $cc, $c0, $88     ; 1c4f: cc 01 01... ...
    !byte $80,   0                                                                      ; 1c5e: 80 00       ..
sprite_addr_K
    !byte   0, $66, $68, $6e, $69, $7f, $78, $7f,   0, $66, $68, $cc, $c0, $88, $80     ; 1c60: 00 66 68... .fh
    !byte   0, $78, $7f, $78, $6f, $69, $6f, $68, $0c,   0, $88, $80, $cc, $c0, $6e     ; 1c6f: 00 78 7f... .x.
    !byte $68, $0c                                                                      ; 1c7e: 68 0c       h.
sprite_addr_L
    !byte   0, $66, $68, $6e, $68, $6e, $68, $6e,   0,   0,   0,   0,   0,   0,   0     ; 1c80: 00 66 68... .fh
    !byte   0, $68, $6e, $68, $6e, $68, $7f, $78, $0f,   0,   0,   0,   0,   0, $ee     ; 1c8f: 00 68 6e... .hn
    !byte $e0, $0c                                                                      ; 1c9e: e0 0c       ..
sprite_addr_M
    !byte   0, $66, $68, $7f, $78, $7f, $78, $6f,   0, $33, $34, $77, $78, $ff, $f0     ; 1ca0: 00 66 68... .fh
    !byte $bf, $69, $6f, $69, $6f, $68, $6e, $68, $0c, $b4, $bf, $b4, $37, $34, $37     ; 1caf: bf 69 6f... .io
    !byte $34,   6                                                                      ; 1cbe: 34 06       4.
sprite_addr_N
    !byte   0, $66, $68, $6e, $68, $7f, $78, $7f,   0, $66, $68, $6e, $68, $6e, $68     ; 1cc0: 00 66 68... .fh
    !byte $ee, $78, $6f, $69, $6f, $68, $6e, $68, $0c, $e0, $ee, $e0, $6e, $68, $6e     ; 1ccf: ee 78 6f... .xo
    !byte $68, $0c                                                                      ; 1cde: 68 0c       h.
sprite_addr_O
    !byte   0, $33, $34, $66, $68, $6e, $68, $6e,   0, $cc, $c0, $6e, $68, $6e, $68     ; 1ce0: 00 33 34... .34
    !byte $6e, $68, $6e, $68, $6e, $68, $3f, $34,   7, $68, $6e, $68, $6e, $68, $cc     ; 1cef: 6e 68 6e... nhn
    !byte $c0,   8                                                                      ; 1cfe: c0 08       ..
sprite_addr_P
    !byte   0, $77, $78, $6f, $68, $6e, $68, $7f,   0, $cc, $c0, $6e, $68, $6e, $68     ; 1d00: 00 77 78... .wx
    !byte $cc, $78, $6f, $68, $6e, $68, $6e, $68, $0c, $c0,   8,   0,   0,   0,   0     ; 1d0f: cc 78 6f... .xo
    !byte   0,   0                                                                      ; 1d1e: 00 00       ..
sprite_addr_Q
    !byte   0, $33, $34, $66, $68, $6e, $68, $6e,   0, $cc, $c0, $6e, $68, $6e, $68     ; 1d20: 00 33 34... .34
    !byte $6e, $68, $6e, $69, $6f, $69, $3f, $34,   6, $68, $ae, $a0, $cc, $c0, $6e     ; 1d2f: 6e 68 6e... nhn
    !byte $68, $0c                                                                      ; 1d3e: 68 0c       h.
sprite_addr_R
    !byte   0, $77, $78, $6f, $68, $6e, $68, $7f,   0, $cc, $c0, $6e, $68, $6e, $68     ; 1d40: 00 77 78... .wx
    !byte $cc, $78, $6f, $69, $6f, $68, $6e, $68, $0c, $c0, $cc, $c0, $6e, $68, $6e     ; 1d4f: cc 78 6f... .xo
    !byte $68, $0c                                                                      ; 1d5e: 68 0c       h.
sprite_addr_S
    !byte   0, $33, $34, $66, $68, $6e, $68, $3f,   0, $cc, $c0, $6e, $68, $0c,   0     ; 1d60: 00 33 34... .34
    !byte $cc, $34,   7,   0, $66, $68, $3f, $34,   7, $c0, $6e, $68, $6e, $68, $cc     ; 1d6f: cc 34 07... .4.
    !byte $c0,   8                                                                      ; 1d7e: c0 08       ..
sprite_addr_T
    !byte   0, $77, $78, $1f, $12, $13, $12, $13,   0, $ee, $e0, $8c, $80, $88, $80     ; 1d80: 00 77 78... .wx
    !byte $88, $12, $13, $12, $13, $12, $13, $12,   3, $80, $88, $80, $88, $80, $88     ; 1d8f: 88 12 13... ...
    !byte $80,   0                                                                      ; 1d9e: 80 00       ..
sprite_addr_U
    !byte   0, $66, $68, $6e, $68, $6e, $68, $6e,   0, $66, $68, $6e, $68, $6e, $68     ; 1da0: 00 66 68... .fh
    !byte $6e, $68, $6e, $68, $6e, $68, $3f, $34,   7, $68, $6e, $68, $6e, $68, $cc     ; 1daf: 6e 68 6e... nhn
    !byte $c0,   8                                                                      ; 1dbe: c0 08       ..
sprite_addr_V
    !byte   0, $66, $68, $6e, $68, $6e, $68, $6e,   0, $66, $68, $6e, $68, $6e, $68     ; 1dc0: 00 66 68... .fh
    !byte $6e, $68, $6e, $68, $3f, $34, $17, $12,   3, $68, $6e, $68, $cc, $c0, $88     ; 1dcf: 6e 68 6e... nhn
    !byte $80,   0                                                                      ; 1dde: 80 00       ..
sprite_addr_W
    !byte   0, $66, $68, $6e, $68, $6e, $69, $6f,   0, $33, $34, $37, $34, $bf, $b4     ; 1de0: 00 66 68... .fh
    !byte $bf, $69, $7f, $78, $7f, $78, $6e, $68, $0c, $b4, $ff, $f0, $7f, $78, $3f     ; 1def: bf 69 7f... .i.
    !byte $34,   6                                                                      ; 1dfe: 34 06       4.
sprite_addr_X
    !byte   0, $66, $68, $6e, $68, $3f, $34, $17,   0, $66, $68, $6e, $68, $cc, $c0     ; 1e00: 00 66 68... .fh
    !byte $88, $12, $33, $34, $67, $68, $6e, $68, $0c, $80, $cc, $c0, $6e, $68, $6e     ; 1e0f: 88 12 33... ..3
    !byte $68, $0c                                                                      ; 1e1e: 68 0c       h.
sprite_addr_Y
    !byte   0, $66, $68, $6e, $68, $6e, $68, $3f,   0, $66, $68, $6e, $68, $6e, $68     ; 1e20: 00 66 68... .fh
    !byte $cc, $34, $17, $12, $13, $12, $13, $12,   3, $c0, $88, $80, $88, $80, $88     ; 1e2f: cc 34 17... .4.
    !byte $80,   0                                                                      ; 1e3e: 80 00       ..
sprite_addr_Z
    !byte   0, $77, $78, $0f,   0,   0,   1, $11,   0, $ee, $e0, $6e, $68, $cc, $c0     ; 1e40: 00 77 78... .wx
    !byte $88, $12, $33, $34, $66, $68, $7f, $78, $0f, $80,   0,   0,   0,   0, $ee     ; 1e4f: 88 12 33... ..3
    !byte $e0, $0c                                                                      ; 1e5e: e0 0c       ..
sprite_addr_bomb
    !byte $00, $00, $10, $01, $01, $03, $07, $0c, $00, $80, $00, $00, $00, $08, $0c, $06
    !byte $28, $28, $08, $1c, $2c, $0c, $07, $03, $82, $82, $02, $06, $86, $06, $0c, $08
sprite_addr_bomb3
    !byte $00, $00, $20, $10, $01, $13, $37, $4c, $00, $00, $00, $00, $00, $08, $8c, $46
    !byte $5d, $7f, $6e, $7f, $5d, $4c, $37, $03, $46, $46, $46, $46, $46, $46, $8c, $08
sprite_addr_bomb2
    !byte $00, $00, $00, $00, $10, $13, $37, $4c, $00, $00, $00, $80, $00, $08, $8c, $46
    !byte $5d, $7f, $4c, $5d, $5d, $4c, $37, $03, $46, $46, $46, $ce, $ce, $46, $8c, $08
sprite_addr_bomb1
    !byte $00, $00, $00, $00, $10, $12, $37, $6e, $00, $00, $00, $00, $00, $08, $8c, $ce
    !byte $4c, $6e, $6e, $6e, $6e, $4c, $37, $03, $ce, $ce, $ce, $ce, $ce, $46, $8c, $08
sprite_addr_bubble2
    !byte $11, $32, $45, $54, $88, $88, $01, $a8, $88, $4c, $a2, $22, $11, $11, $91, $48
    !byte $89, $05, $8b, $8d, $ac, $34, $46, $33, $11, $17, $1f, $1f, $0e, $2e, $4c, $88

; *************************************************************************************
initial_values_of_variables_from_0x50
    !byte $0d                                                                           ; 1e60: 0d          .              ; magic_wall_state
    !byte 99                                                                            ; 1e61: 63          c              ; magic_wall_timer
    !byte $9f                                                                           ; 1e62: 9f          .              ; rockford_cell_value
    !byte 4                                                                             ; 1e63: 04          .              ; delay_trying_to_push_rock
    !byte 0                                                                             ; 1e64: 00          .              ; amoeba_replacement
    !byte 99                                                                            ; 1e65: 63          c              ; amoeba_growth_interval
    !byte 0                                                                             ; 1e66: 00          .              ; number_of_amoeba_cells_found
    !byte 1                                                                             ; 1e67: 01          .              ; amoeba_counter
    !byte 240                                                                           ; 1e68: f0          .              ; ticks_since_last_direction_key_pressed
    !byte 0                                                                             ; 1e69: 00          .              ; countdown_while_switching_palette
    !byte 31                                                                            ; 1e6a: 1f          .              ; tick_counter
    !byte 0                                                                             ; 1e6b: 00          .              ; current_rockford_sprite
    !byte 12                                                                            ; 1e6c: 0c          .              ; sub_second_ticks
    !byte 0                                                                             ; 1e6d: 00          .              ; previous_direction_keys
    !byte 0                                                                             ; 1e6e: 00          .              ; just_pressed_direction_keys
    !byte 0                                                                             ; 1e6f: 00          .              ; rockford_explosion_cell_type

set_clock_value
    !byte 5, 0, 0, 0, 0                ; Five byte clock value (low byte to high byte)

initial_clock_value                    ; Five byte clock value (low byte to high byte)
    !byte 0, 0, 0, 0, 0

unused1
    !byte 0, 0, 0, 0, 0, 0

; *************************************************************************************
; Sprites to use for idle animation of rockford. They are encoded into the nybbles of
; each byte. First it cycles through the bottom nybbles until near the end of the idle
; animation, then cycles through through the top nybbles
idle_animation_data
    !byte 16*(sprite_rockford_tapping_foot4-0x20) + sprite_rockford_blinking1-0x20      ; 1e80: 80          .
    !byte 16*(sprite_rockford_tapping_foot3-0x20) + sprite_rockford_blinking1-0x20      ; 1e81: 70          p
    !byte 16*(sprite_rockford_tapping_foot2-0x20) + sprite_rockford_blinking1-0x20      ; 1e82: 60          `
    !byte 16*(sprite_rockford_tapping_foot3-0x20) + sprite_rockford_blinking1-0x20      ; 1e83: 70          p
    !byte 16*(sprite_rockford_tapping_foot4-0x20) + sprite_rockford_blinking2-0x20      ; 1e84: 81          .
    !byte 16*(sprite_rockford_tapping_foot1-0x20) + sprite_rockford_blinking3-0x20      ; 1e85: 52          R
    !byte 16*(sprite_rockford_tapping_foot2-0x20) + sprite_rockford_blinking2-0x20      ; 1e86: 61          a
    !byte 16*(sprite_rockford_tapping_foot1-0x20) + sprite_rockford_blinking1-0x20      ; 1e87: 50          P
    !byte 16*(sprite_rockford_tapping_foot3-0x20) + sprite_rockford_blinking1-0x20      ; 1e88: 70          p
    !byte 16*(sprite_rockford_tapping_foot5-0x20) + sprite_rockford_blinking1-0x20      ; 1e89: 90          .
    !byte 16*(sprite_rockford_tapping_foot5-0x20) + sprite_rockford_blinking3-0x20      ; 1e8a: 92          .
    !byte 16*(sprite_rockford_tapping_foot3-0x20) + sprite_rockford_blinking1-0x20      ; 1e8b: 70          p
    !byte 16*(sprite_rockford_tapping_foot1-0x20) + sprite_rockford_blinking3-0x20      ; 1e8c: 52          R
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_blinking1-0x20          ; 1e8d: 00          .
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_blinking1-0x20          ; 1e8e: 00          .
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_blinking1-0x20          ; 1e8f: 00          .
    !byte 16*(sprite_rockford_blinking2-0x20) + sprite_rockford_blinking2-0x20          ; 1e90: 11          .
    !byte 16*(sprite_rockford_blinking3-0x20) + sprite_rockford_blinking3-0x20          ; 1e91: 22          "
    !byte 16*(sprite_rockford_blinking2-0x20) + sprite_rockford_blinking2-0x20          ; 1e92: 11          .
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_blinking1-0x20          ; 1e93: 00          .
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_blinking1-0x20          ; 1e94: 00          .
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_blinking2-0x20          ; 1e95: 01          .
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot5-0x20      ; 1e96: 09          .
    !byte 16*(sprite_rockford_blinking3-0x20) + sprite_rockford_tapping_foot3-0x20      ; 1e97: 27          '
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot1-0x20      ; 1e98: 05          .
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot1-0x20      ; 1e99: 05          .
    !byte 16*(sprite_rockford_blinking3-0x20) + sprite_rockford_tapping_foot1-0x20      ; 1e9a: 25          %
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot1-0x20      ; 1e9b: 05          .
    !byte 16*(sprite_rockford_tapping_foot1-0x20) + sprite_rockford_tapping_foot1-0x20  ; 1e9c: 55          U
    !byte 16*(sprite_rockford_tapping_foot3-0x20) + sprite_rockford_tapping_foot5-0x20  ; 1e9d: 79          y
    !byte 16*(sprite_rockford_tapping_foot5-0x20) + sprite_rockford_tapping_foot1-0x20  ; 1e9e: 95          .
    !byte 16*(sprite_rockford_tapping_foot3-0x20) + sprite_rockford_tapping_foot1-0x20  ; 1e9f: 75          u
    !byte 16*(sprite_rockford_tapping_foot1-0x20) + sprite_rockford_tapping_foot1-0x20  ; 1ea0: 55          U
    !byte 16*(sprite_rockford_blinking3-0x20) + sprite_rockford_tapping_foot4-0x20      ; 1ea1: 28          (
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot1-0x20      ; 1ea2: 05          .
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot2-0x20      ; 1ea3: 06          .
    !byte 16*(sprite_rockford_blinking3-0x20) + sprite_rockford_tapping_foot3-0x20      ; 1ea4: 27          '
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot1-0x20      ; 1ea5: 05          .
    !byte 16*(sprite_rockford_blinking3-0x20) + sprite_rockford_tapping_foot1-0x20      ; 1ea6: 25          %
    !byte 16*(sprite_rockford_tapping_foot1-0x20) + sprite_rockford_tapping_foot1-0x20  ; 1ea7: 55          U
    !byte 16*(sprite_rockford_tapping_foot1-0x20) + sprite_rockford_tapping_foot1-0x20  ; 1ea8: 55          U
    !byte 16*(sprite_rockford_tapping_foot1-0x20) + sprite_rockford_tapping_foot5-0x20  ; 1ea9: 59          Y
    !byte 16*(sprite_rockford_tapping_foot1-0x20) + sprite_rockford_tapping_foot1-0x20  ; 1eaa: 55          U
    !byte 16*(sprite_rockford_tapping_foot2-0x20) + sprite_rockford_tapping_foot1-0x20  ; 1eab: 65          e
    !byte 16*(sprite_rockford_tapping_foot5-0x20) + sprite_rockford_blinking2-0x20      ; 1eac: 91          .
    !byte 16*(sprite_rockford_tapping_foot2-0x20) + sprite_rockford_blinking3-0x20      ; 1ead: 62          b
    !byte 16*(sprite_rockford_tapping_foot5-0x20) + sprite_rockford_blinking2-0x20      ; 1eae: 91          .
    !byte 16*(sprite_rockford_tapping_foot2-0x20) + sprite_rockford_blinking1-0x20      ; 1eaf: 60          `
    !byte 16*(sprite_rockford_tapping_foot3-0x20) + sprite_rockford_blinking1-0x20      ; 1eb0: 70          p
    !byte 16*(sprite_rockford_blinking3-0x20) + sprite_rockford_tapping_foot1-0x20      ; 1eb1: 25          %
    !byte 16*(sprite_rockford_blinking2-0x20) + sprite_rockford_tapping_foot2-0x20      ; 1eb2: 16          .
    !byte 16*(sprite_rockford_blinking2-0x20) + sprite_rockford_tapping_foot5-0x20      ; 1eb3: 19          .
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot4-0x20      ; 1eb4: 08          .
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot5-0x20      ; 1eb5: 09          .
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot2-0x20      ; 1eb6: 06          .
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot1-0x20      ; 1eb7: 05          .
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot2-0x20      ; 1eb8: 06          .
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot1-0x20      ; 1eb9: 05          .
    !byte 16*(sprite_rockford_winking1-0x20) + sprite_rockford_tapping_foot2-0x20       ; 1eba: 36          6
    !byte 16*(sprite_rockford_winking2-0x20) + sprite_rockford_tapping_foot1-0x20       ; 1ebb: 45          E
    !byte 16*(sprite_rockford_winking2-0x20) + sprite_rockford_tapping_foot4-0x20       ; 1ebc: 48          H
    !byte 16*(sprite_rockford_winking2-0x20) + sprite_rockford_tapping_foot3-0x20       ; 1ebd: 47          G
    !byte 16*(sprite_rockford_winking1-0x20) + sprite_rockford_tapping_foot2-0x20       ; 1ebe: 36          6
    !byte 16*(sprite_rockford_winking1-0x20) + sprite_rockford_tapping_foot1-0x20       ; 1ebf: 35          5

; *************************************************************************************
sprite_to_next_sprite
    !byte sprite_space                                                                  ; 1f00: 00          .
    !byte sprite_boulder1                                                               ; 1f01: 01          .
    !byte sprite_boulder2                                                               ; 1f02: 02          .
    !byte sprite_diamond2                                                               ; 1f03: 04          .
    !byte sprite_diamond3                                                               ; 1f04: 05          .
    !byte sprite_diamond4                                                               ; 1f05: 06          .
    !byte sprite_diamond1                                                               ; 1f06: 03          .
    !byte $60                                                                           ; 1f07: 60          `
    !byte sprite_titanium_wall2                                                         ; 1f08: 08          .
    !byte $67                                                                           ; 1f09: 67          g
    !byte $61                                                                           ; 1f0a: 61          a
    !byte sprite_wall2                                                                  ; 1f0b: 0b          .
    !byte sprite_explosion1                                                             ; 1f0c: 0c          .
    !byte sprite_explosion2                                                             ; 1f0d: 0d          .
    !byte sprite_explosion3                                                             ; 1f0e: 0e          .

; *************************************************************************************
used_for_unknown1
    !byte $0f, $11, $12, $13, $10, $14, $15, $17, $18, $62, $1a, $1b, $1c, $1a, $1d     ; 1f0f: 0f 11 12... ...
    !byte $68, $1f, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2b, $2c, $2d     ; 1f1e: 68 1f 20... h.
    !byte $63, $2f, $30, $31, $65                                                       ; 1f2d: 63 2f 30... c/0

    !byte sprite_0                                                                      ; 1f32: 32          2
    !byte sprite_0                                                                      ; 1f33: 32          2
    !byte sprite_diamond1                                                               ; 1f34: 03          .
    !byte sprite_0                                                                      ; 1f35: 32          2
    !byte sprite_0                                                                      ; 1f36: 32          2
    !byte $0a                                                                           ; 1f37: 0a          .
    !byte sprite_8                                                                      ; 1f38: 3a          :
    !byte sprite_2                                                                      ; 1f39: 34          4
    !byte sprite_2                                                                      ; 1f3a: 34          4
    !byte sprite_space                                                                  ; 1f3b: 00          .
    !byte sprite_0                                                                      ; 1f3c: 32          2
    !byte sprite_0                                                                      ; 1f3d: 32          2
    !byte sprite_0                                                                      ; 1f3e: 32          2
    !byte sprite_space                                                                  ; 1f3f: 00          .
    !byte sprite_7                                                                      ; 1f40: 39          9
    !byte sprite_7                                                                      ; 1f41: 39          9
    !byte sprite_6                                                                      ; 1f42: 38          8
    !byte sprite_4                                                                      ; 1f43: 36          6
    !byte sprite_7                                                                      ; 1f44: 39          9
    !byte sprite_6                                                                      ; 1f45: 38          8
    !text "PLAYER"                                                                      ; 1f46: 50 4c 41... PLA
    !byte sprite_space                                                                  ; 1f4c: 00          .
    !byte sprite_1                                                                      ; 1f4d: 33          3
    !byte sprite_comma                                                                  ; 1f4e: 3f          ?
    !byte sprite_space                                                                  ; 1f4f: 00          .
    !byte sprite_3                                                                      ; 1f50: 35          5
    !byte sprite_space                                                                  ; 1f51: 00          .
    !text "MEN"                                                                         ; 1f52: 4d 45 4e    MEN
    !byte sprite_space                                                                  ; 1f55: 00          .
    !text "A"                                                                           ; 1f56: 41          A
    !byte sprite_slash                                                                  ; 1f57: 3e          >
    !byte sprite_1                                                                      ; 1f58: 33          3
    !byte sprite_space                                                                  ; 1f59: 00          .

    !byte $5a, $5b, $5c, $5d, $5e, $5f,   7, $0a, $16, $64, $2a, $66, $2e,   9, $1e     ; 1f5a: 5a 5b 5c... Z[\
    !byte $69, $6a, $6b, $6c, $6d, $6e, $6f, $70, $71, $72, $73, $74, $75, $76, $77     ; 1f69: 69 6a 6b... ijk
    !byte $78, $79, $7a, $7b, $7c, $7d, $7e, $7f                                        ; 1f78: 78 79 7a... xyz

; *************************************************************************************
; 
; Table to convert a cell type 0-$7f into a sprite number.
; 
; Not all possible cell types are used (see the top of file for the valid cell types).
; By changing the entries of this table on the fly, this table allows the sprite to
; animate without the underlying cell type needing to change.
; 
; *************************************************************************************
cell_type_to_sprite
    !byte sprite_space                                                                  ; 1f80: 00          .              ; cell type $00 = map_space
    !byte sprite_earth2                                                                 ; 1f81: 1e          .              ; cell type $01 = map_earth
    !byte sprite_wall2                                                                  ; 1f82: 0b          .              ; cell type $02 = map_wall
    !byte sprite_titanium_wall2                                                         ; 1f83: 08          .              ; cell type $03 = map_titanium_wall
    !byte sprite_diamond1                                                               ; 1f84: 03          .              ; cell type $04 = map_diamond
    !byte sprite_boulder1                                                               ; 1f85: 01          .              ; cell type $05 = map_rock
    !byte sprite_firefly4                                                               ; 1f86: 1c          .              ; cell type $06 = map_firefly
amoeba_animated_sprite0
    !byte sprite_amoeba1                                                                ; 1f87: 14          .              ; cell type $07 = map_amoeba
    !byte sprite_earth2                                                                 ; 1f88: 1e          .              ; cell type $08 = map_rockford_appearing_or_end_position
slime_animated_sprite0
    !byte sprite_amoeba1                                                                ; 1f89: 07          .              ; cell type $09 = map_slime
    !byte $4c                                                                           ; 1f8a: 4c 44       .              ; cell type $0A = map_explosion
    !byte sprite_bomb1                                                                  ; cell type $0B = map_bomb
    !byte sprite_magic_wall1                                                            ;                                  ; cell type $0C = map_growing_wall
    !byte sprite_wall2                                                                  ; 1f8d: 0b          .              ; cell type $0D = map_magic_wall
    !byte sprite_butterfly1                                                             ; 1f8e: 16          .              ; cell type $0E = map_butterfly
rockford_sprite
    !byte sprite_rockford_tapping_foot1                                                 ; 1f8f: 25          %              ; cell type $0F = map_rockford

    !byte sprite_explosion4                                                             ; 1f90: 0f          .              ; cell type $10 = map_space | map_anim_state1
    !byte sprite_explosion4                                                             ; 1f91: 0f          .              ; cell type $11 = map_earth | map_anim_state1
    !byte sprite_explosion4                                                             ; 1f92: 0f          .              ; cell type $12 = map_wall | map_anim_state1
    !byte sprite_explosion4                                                             ; 1f93: 0f          .              ; cell type $13 = map_large_explosion_state1
    !byte sprite_rockford_winking2                                                      ; 1f94: 24          $              ; cell type $14 = map_diamond | map_anim_state1
    !byte sprite_boulder2                                                               ; 1f95: 31          1              ; cell type $15 = map_rock | map_anim_state1
    !byte sprite_firefly4                                                               ; 1f96: 1c          .              ; cell type $16 = map_firefly | map_anim_state1
    !byte sprite_amoeba1                                                                ; 1f97: 14          .              ; cell type $17 = map_amoeba | map_anim_state1
    !byte sprite_box                                                                    ; 1f98: 09          .              ; cell type $18 = map_active_exit
    !byte sprite_amoeba1                                                                ; 1f99: 3e          >              ; cell type $19 = map_slime | map_anim_state1
    !byte sprite_firefly4                                                               ; 1f9a: 1c          .              ; cell type $1A = map_explosion | map_anim_state1
    !byte sprite_bomb2                                                                  ; cell type $1B = map_bomb | map_anim_state1
    !byte sprite_magic_wall1                                                            ; 1f9c: 14          .              ; cell type $1C = map_growing_wall | map_anim_state1
    !byte sprite_magic_wall1                                                            ; 1f9d: 10          .              ; cell type $1D = map_magic_wall | map_anim_state1
    !byte sprite_butterfly1                                                             ; 1f9e: 16          .              ; cell type $1E = map_butterfly | map_anim_state1
    !byte sprite_rockford_moving_left3                                                  ; 1f9f: 2c          ,              ; cell type $1F = map_rockford | map_anim_state1

    !byte sprite_explosion3                                                             ; 1fa0: 0e          .              ; cell type $20 = map_space | map_anim_state2
    !byte sprite_explosion3                                                             ; 1fa1: 0e          .              ; cell type $21 = map_earth | map_anim_state2
    !byte sprite_explosion3                                                             ; 1fa2: 0e          .              ; cell type $22 = map_wall | map_anim_state2
    !byte sprite_explosion3                                                             ; 1fa3: 0e          .              ; cell type $23 = map_large_explosion_state2
    !byte sprite_diamond2                                                               ; 1fa4: 04          .              ; cell type $24 = map_diamond | map_anim_state2
    !byte sprite_bubble1                                                                ; 1fa5: 31          1              ; cell type $25 = map_rock | map_anim_state2
    !byte sprite_firefly4                                                               ; 1fa6: 1c          .              ; cell type $26 = map_firefly | map_anim_state2
    !byte sprite_amoeba2                                                                ; 1fa7: 15          .              ; cell type $27 = map_amoeba | map_anim_state2
    !byte sprite_firefly2                                                               ; 1fa8: 1a          .              ; cell type $28 = map_rockford_appearing_or_end_position | map_anim_state2
    !byte sprite_amoeba2                                                                ; 1fa9: 61          a              ; cell type $29 = map_slime | map_anim_state2
    !byte $46                                                                           ; 1faa: 1c          .              ; cell type $2A = map_explosion | map_anim_state2
    !byte sprite_bomb3                                                                  ; cell type $2B = map_bomb | map_anim_state2
    !byte sprite_magic_wall1                                                            ; 1fac: 14          .              ; cell type $2C = map_growing_wall | map_anim_state2
    !byte sprite_wall2                                                                  ; 1fad: 0b          .              ; cell type $2D = map_magic_wall | map_anim_state2
    !byte sprite_butterfly1                                                             ; 1fae: 16          .              ; cell type $2E = map_butterfly | map_anim_state2
    !byte sprite_rockford_moving_right4                                                 ; 1faf: 31          1              ; cell type $2F = map_rockford | map_anim_state2

    !byte sprite_explosion2                                                             ; 1fb0: 0d          .              ; cell type $30 = map_space | map_anim_state3
    !byte sprite_explosion2                                                             ; 1fb1: 0d          .              ; cell type $31 = map_earth | map_anim_state3
    !byte sprite_explosion2                                                             ; 1fb2: 0d          .              ; cell type $32 = map_wall | map_anim_state3
    !byte sprite_explosion2                                                             ; 1fb3: 0d          .              ; cell type $33 = map_large_explosion_state3
    !byte sprite_diamond2                                                               ; 1fb4: 04          .              ; cell type $34 = map_diamond | map_anim_state3
    !byte sprite_boulder1                                                               ; 1fb5: 31          1              ; cell type $35 = map_rock | map_anim_state3
    !byte sprite_firefly4                                                               ; 1fb6: 1c          .              ; cell type $36 = map_firefly | map_anim_state3
    !byte sprite_amoeba2                                                                ; 1fb7: 15          .              ; cell type $37 = map_amoeba | map_anim_state3
    !byte sprite_firefly2                                                               ; 1fb8: 1a          .              ; cell type $38 = map_rockford_appearing_or_end_position | map_anim_state3
    !byte sprite_amoeba2                                                                ; 1fb9: 0b          .              ; cell type $39 = map_slime | map_anim_state3
    !byte sprite_firefly4                                                               ; 1fba: 1c          .              ; cell type $3A = map_explosion | map_anim_state3
    !byte sprite_bomb4                                                                  ; cell type $3B = map_bomb | map_anim_state3
    !byte sprite_magic_wall1                                                            ; 1fbc: 14          .              ; cell type $3C = map_growing_wall | map_anim_state3
    !byte sprite_wall2                                                                  ; 1fbd: 0b          .              ; cell type $3D = map_magic_wall | map_anim_state3
    !byte sprite_butterfly1                                                             ; 1fbe: 16          .              ; cell type $3E = map_butterfly | map_anim_state3
    !byte sprite_rockford_tapping_foot4                                                 ; 1fbf: 28          (              ; cell type $3F = map_rockford | map_anim_state3

    !byte sprite_explosion1                                                             ; 1fc0: 0c          .              ; cell type $40 = map_space | map_anim_state4
    !byte sprite_explosion1                                                             ; 1fc1: 0c          .              ; cell type $41 = map_earth | map_anim_state4
    !byte sprite_explosion1                                                             ; 1fc2: 0c          .              ; cell type $42 = map_wall | map_anim_state4
    !byte sprite_explosion1                                                             ; 1fc3: 0c          .              ; cell type $43 = map_titanium_wall | map_anim_state4
    !byte sprite_diamond1                                                               ; 1fc4: 03          .              ; cell type $44 = map_diamond | map_anim_state4
    !byte sprite_boulder1                                                               ; 1fc5: 01          .              ; cell type $45 = map_rock | map_anim_state4
    !byte sprite_explosion1                                                             ; 1fc6: 0c          .              ; cell type $46 = map_start_large_explosion
amoeba_animated_sprites4
    !byte sprite_amoeba2                                                                ; 1fc7: 15          .              ; cell type $47 = map_amoeba | map_anim_state4
    !byte sprite_rockford_moving_right4                                                 ; 1fc8: 31          1              ; cell type $48 = map_rockford_appearing_or_end_position | map_anim_state4
slime_animated_sprite1
    !byte sprite_amoeba2                                                                ; 1fc9: 20                         ; cell type $49 = map_slime | map_anim_state4
    !byte sprite_firefly4                                                               ; 1fca: 1c          .              ; cell type $4A = map_explosion | map_anim_state4
    !byte sprite_bomb1                                                                  ; cell type $4B = map_bomb | map_anim_state4
    !byte sprite_magic_wall1                                                            ;                                  ; cell type $4D = map_growing_wall | map_anim_state4
    !text "A"                                                                           ; 1fcc: 4b 42       A              ; cell type $4C = map_magic_wall | map_anim_state4
    !byte sprite_butterfly2                                                             ; 1fce: 17          .              ; cell type $4E = map_butterfly | map_anim_state4
    !byte sprite_rockford_moving_right3                                                 ; 1fcf: 30          0              ; cell type $4F = map_rockford | map_anim_state4

    !byte sprite_explosion2                                                             ; 1fd0: 0d          .              ; cell type $50 = map_space | map_anim_state5
    !byte sprite_explosion2                                                             ; 1fd1: 0d          .              ; cell type $51 = map_earth | map_anim_state5
    !byte sprite_explosion2                                                             ; 1fd2: 0d          .              ; cell type $52 = map_wall | map_anim_state5
    !byte sprite_explosion2                                                             ; 1fd3: 0d          .              ; cell type $53 = map_titanium_wall | map_anim_state5
    !byte sprite_rockford_winking2                                                      ; 1fd4: 24          $              ; cell type $54 = map_diamond | map_anim_state5
    !byte sprite_boulder1                                                               ; 1fd5: 31          1              ; cell type $55 = map_rock | map_anim_state5
    !byte sprite_firefly2                                                               ; 1fd6: 1a          .              ; cell type $56 = map_firefly | map_anim_state5
    !byte sprite_amoeba1                                                                ; 1fd7: 14          .              ; cell type $57 = map_amoeba | map_anim_state5
    !byte sprite_rockford_moving_right4                                                 ; 1fd8: 31          1              ; cell type $58 = map_rockford_appearing_or_end_position | map_anim_state5
    !byte sprite_amoeba1                                                                ; 1fd9: 3e          >              ; cell type $59 = map_slime | map_anim_state5
    !byte sprite_firefly4                                                               ; 1fda: 1c          .              ; cell type $5A = map_explosion | map_anim_state5
    !byte sprite_bomb2                                                                  ; cell type $5B = map_bomb | map_anim_state5
    !byte sprite_magic_wall1                                                            ; 1fdc: 11          .              ; cell type $5C = map_growing_wall | map_anim_state5
    !byte sprite_magic_wall2                                                            ; 1fdd: 11          .              ; cell type $5D = map_magic_wall | map_anim_state5
    !byte sprite_butterfly2                                                             ; 1fde: 17          .              ; cell type $5E = map_butterfly | map_anim_state5
    !byte sprite_rockford_moving_left2                                                  ; 1fdf: 2b          +              ; cell type $5F = map_rockford | map_anim_state5

    !byte sprite_explosion3                                                             ; 1fe0: 0e          .              ; cell type $60 = map_space | map_anim_state6
    !byte sprite_explosion3                                                             ; 1fe1: 0e          .              ; cell type $61 = map_earth | map_anim_state6
    !byte sprite_explosion3                                                             ; 1fe2: 0e          .              ; cell type $62 = map_wall | map_anim_state6
    !byte sprite_explosion3                                                             ; 1fe3: 0e          .              ; cell type $63 = map_titanium_wall | map_anim_state6
    !byte sprite_diamond1                                                               ; 1fe4: 03          .              ; cell type $64 = map_diamond | map_anim_state6
    !byte sprite_boulder1                                                               ; 1fe5: 31          1              ; cell type $65 = map_rock | map_anim_state6
    !byte sprite_firefly2                                                               ; 1fe6: 1a          .              ; cell type $66 = map_firefly | map_anim_state6
    !byte sprite_amoeba1                                                                ; 1fe7: 14          .              ; cell type $67 = map_amoeba | map_anim_state6
    !byte sprite_rockford_moving_right4                                                 ; 1fe8: 31          1              ; cell type $68 = map_rockford_appearing_or_end_position | map_anim_state6
    !byte sprite_amoeba1                                                                ; 1fe9: 61          a              ; cell type $69 = map_slime | map_anim_state6
    !byte sprite_firefly4                                                               ; 1fea: 1c          .              ; cell type $6A = map_explosion | map_anim_state6
    !byte sprite_bomb3                                                                  ; cell type $6B = map_bomb | map_anim_state6
    !byte sprite_magic_wall1                                                            ; 1fec: 11          .              ; cell type $6C = map_growing_wall | map_anim_state6
    !byte sprite_explosion2                                                             ; 1fed: 0d          .              ; cell type $6D = map_magic_wall | map_anim_state6
    !byte sprite_butterfly2                                                             ; 1fee: 17          .              ; cell type $6E = map_butterfly | map_anim_state6
    !byte sprite_rockford_tapping_foot4                                                 ; 1fef: 28          (              ; cell type $6F = map_rockford | map_anim_state6

    !byte sprite_explosion4                                                             ; 1ff0: 0f          .              ; cell type $70 = map_space | map_anim_state7
    !byte sprite_explosion4                                                             ; 1ff1: 0f          .              ; cell type $71 = map_earth | map_anim_state7
    !byte sprite_explosion4                                                             ; 1ff2: 0f          .              ; cell type $72 = map_wall | map_anim_state7
    !byte sprite_explosion4                                                             ; 1ff3: 0f          .              ; cell type $73 = map_titanium_wall | map_anim_state7
    !byte sprite_diamond1                                                               ; 1ff4: 03          .              ; cell type $74 = map_diamond | map_anim_state7
    !byte sprite_boulder1                                                               ; 1ff5: 31          1              ; cell type $75 = map_rock | map_anim_state7
    !byte sprite_firefly2                                                               ; 1ff6: 1a          .              ; cell type $76 = map_firefly | map_anim_state7
    !byte sprite_amoeba2                                                                ; 1ff7: 15          .              ; cell type $77 = map_amoeba | map_anim_state7
    !byte sprite_rockford_moving_right4                                                 ; 1ff8: 31          1              ; cell type $78 = map_rockford_appearing_or_end_position | map_anim_state7
    !byte sprite_amoeba2                                                                ; 1ff9: 0b          .              ; cell type $79 = map_slime | map_anim_state7
    !byte sprite_firefly4                                                               ; 1ffa: 1c          .              ; cell type $7A = map_explosion | map_anim_state7
    !byte sprite_bomb4                                                                  ; cell type $7B = map_bomb | map_anim_state7
    !byte sprite_magic_wall1                                                            ; 1ffc: 1e          .              ; cell type $7C = map_growing_wall | map_anim_state7
    !byte sprite_explosion1                                                             ; 1ffd: 0c          .              ; cell type $7D = map_magic_wall | map_anim_state7
    !byte sprite_butterfly2                                                             ; 1ffe: 17          .              ; cell type $7E = map_butterfly | map_anim_state7
    !byte sprite_explosion1                                                             ; 1fff: 0c          .              ; cell type $7F = map_rockford | map_anim_state7

; *************************************************************************************
sprite_addresses_low
    !byte <sprite_addr_space                                                            ; 2000: 00          .
    !byte <sprite_addr_boulder1                                                         ; 2001: 20
    !byte <sprite_addr_boulder2                                                         ; 2002: 40          @
    !byte <sprite_addr_diamond1                                                         ; 2003: 60          `
    !byte <sprite_addr_diamond2                                                         ; 2004: 80          .
    !byte <sprite_addr_diamond3                                                         ; 2005: a0          .
    !byte <sprite_addr_diamond4                                                         ; 2006: c0          .
sprite_titanium_addressA
    !byte <sprite_addr_titanium_wall1                                                   ; 2007: e0          .
    !byte <sprite_addr_titanium_wall2                                                   ; 2008: 00          .
    !byte <sprite_addr_box                                                              ; 2009: 20
    !byte <sprite_addr_wall1                                                            ; 200a: 40          @
    !byte <sprite_addr_wall2                                                            ; 200b: 60          `
    !byte <sprite_addr_explosion1                                                       ; 200c: 80          .
    !byte <sprite_addr_explosion2                                                       ; 200d: a0          .
    !byte <sprite_addr_explosion3                                                       ; 200e: c0          .
    !byte <sprite_addr_explosion4                                                       ; 200f: e0          .
    !byte <sprite_addr_magic_wall1                                                      ; 2010: 00          .
    !byte <sprite_addr_magic_wall2                                                      ; 2011: 20
    !byte <sprite_addr_magic_wall3                                                      ; 2012: 40          @
    !byte <sprite_addr_magic_wall4                                                      ; 2013: 60          `
    !byte <sprite_addr_amoeba1                                                          ; 2014: 80          .
    !byte <sprite_addr_amoeba2                                                          ; 2015: a0          .
    !byte <sprite_addr_butterfly1                                                       ; 2016: c0          .
    !byte <sprite_addr_butterfly2                                                       ; 2017: e0          .
    !byte <sprite_addr_butterfly3                                                       ; 2018: 00          .
    !byte <sprite_addr_firefly1                                                         ; 2019: 20
    !byte <sprite_addr_firefly2                                                         ; 201a: 40          @
    !byte <sprite_addr_firefly3                                                         ; 201b: 60          `
    !byte <sprite_addr_firefly4                                                         ; 201c: 80          .
    !byte <sprite_addr_earth1                                                           ; 201d: a0          .
    !byte <sprite_addr_earth2                                                           ; 201e: c0          .
    !byte <sprite_addr_pathway                                                          ; 201f: e0          .
    !byte <sprite_addr_rockford_blinking1                                               ; 2020: 00          .
    !byte <sprite_addr_rockford_blinking2                                               ; 2021: 20
    !byte <sprite_addr_rockford_blinking3                                               ; 2022: 40          @
    !byte <sprite_addr_rockford_winking1                                                ; 2023: 60          `
    !byte <sprite_addr_rockford_winking2                                                ; 2024: 80          .
    !byte <sprite_addr_rockford_moving_down1                                            ; 2025: a0          .
    !byte <sprite_addr_rockford_moving_down2                                            ; 2026: c0          .
    !byte <sprite_addr_rockford_moving_down3                                            ; 2027: e0          .
    !byte <sprite_addr_rockford_moving_up1                                              ; 2028: 00          .
    !byte <sprite_addr_rockford_moving_up2                                              ; 2029: 20
    !byte <sprite_addr_rockford_moving_left1                                            ; 202a: 40          @
    !byte <sprite_addr_rockford_moving_left2                                            ; 202b: 60          `
    !byte <sprite_addr_rockford_moving_left3                                            ; 202c: 80          .
    !byte <sprite_addr_rockford_moving_left4                                            ; 202d: a0          .
    !byte <sprite_addr_rockford_moving_right1                                           ; 202e: c0          .
    !byte <sprite_addr_rockford_moving_right2                                           ; 202f: e0          .
    !byte <sprite_addr_rockford_moving_right3                                           ; 2030: 00          .
    !byte <sprite_addr_rockford_moving_right4                                           ; 2031: 20
    !byte <sprite_addr_0                                                                ; 2032: 40          @
    !byte <sprite_addr_1                                                                ; 2033: 60          `
    !byte <sprite_addr_2                                                                ; 2034: 80          .
    !byte <sprite_addr_3                                                                ; 2035: a0          .
    !byte <sprite_addr_4                                                                ; 2036: c0          .
    !byte <sprite_addr_5                                                                ; 2037: e0          .
    !byte <sprite_addr_6                                                                ; 2038: 00          .
    !byte <sprite_addr_7                                                                ; 2039: 20
    !byte <sprite_addr_8                                                                ; 203a: 40          @
    !byte <sprite_addr_9                                                                ; 203b: 60          `
    !byte <sprite_addr_white                                                            ; 203c: 80          .
    !byte <sprite_addr_dash                                                             ; 203d: a0          .
    !byte <sprite_addr_slash                                                            ; 203e: c0          .
    !byte <sprite_addr_comma                                                            ; 203f: e0          .
    !byte <sprite_addr_full_stop                                                        ; 2040: 00          .
    !byte <sprite_addr_A                                                                ; 2041: 20
    !byte <sprite_addr_B                                                                ; 2042: 40          @
    !byte <sprite_addr_C                                                                ; 2043: 60          `
    !byte <sprite_addr_D                                                                ; 2044: 80          .
    !byte <sprite_addr_E                                                                ; 2045: a0          .
    !byte <sprite_addr_F                                                                ; 2046: c0          .
    !byte <sprite_addr_G                                                                ; 2047: e0          .
    !byte <sprite_addr_H                                                                ; 2048: 00          .
    !byte <sprite_addr_I                                                                ; 2049: 20
    !byte <sprite_addr_J                                                                ; 204a: 40          @
    !byte <sprite_addr_K                                                                ; 204b: 60          `
    !byte <sprite_addr_L                                                                ; 204c: 80          .
    !byte <sprite_addr_M                                                                ; 204d: a0          .
    !byte <sprite_addr_N                                                                ; 204e: c0          .
    !byte <sprite_addr_O                                                                ; 204f: e0          .
    !byte <sprite_addr_P                                                                ; 2050: 00          .
    !byte <sprite_addr_Q                                                                ; 2051: 20
    !byte <sprite_addr_R                                                                ; 2052: 40          @
    !byte <sprite_addr_S                                                                ; 2053: 60          `
    !byte <sprite_addr_T                                                                ; 2054: 80          .
    !byte <sprite_addr_U                                                                ; 2055: a0          .
    !byte <sprite_addr_V                                                                ; 2056: c0          .
    !byte <sprite_addr_W                                                                ; 2057: e0          .
    !byte <sprite_addr_X                                                                ; 2058: 00          .
    !byte <sprite_addr_Y                                                                ; 2059: 20
    !byte <sprite_addr_Z                                                                ; 205a: 40          @
    !byte <sprite_addr_bomb
    !byte <sprite_addr_bomb3
    !byte <sprite_addr_bomb2
    !byte <sprite_addr_bomb1
    !byte <sprite_addr_bubble2
unused4
;    !byte $60                                                                           ; 205b: 60          `
;    !byte $80                                                                           ; 205c: 80          .
;    !byte $a0                                                                           ; 205d: a0          .
;    !byte $c0                                                                           ; 205e: c0          .
;    !byte $e0                                                                           ; 205f: e0          .
sprite_titanium_addressB
    !byte <sprite_addr_titanium_wall1                                                   ; 2060: e0          .
unused5
    !byte $40, $e0, $80, $60,   0, $e0,   0,   0, $20, $40, $60, $80, $a0, $c0, $e0     ; 2061: 40 e0 80... @..
    !byte   0, $20, $40, $60, $80, $a0, $c0, $e0,   0, $20, $40, $60, $80, $a0, $c0     ; 2070: 00 20 40... . @
    !byte $e0                                                                           ; 207f: e0          .

; *************************************************************************************
sprite_addresses_high
    !byte >sprite_addr_space                                                            ; 2080: 13          .
    !byte >sprite_addr_boulder1                                                         ; 2081: 13          .
    !byte >sprite_addr_boulder2                                                         ; 2082: 13          .
    !byte >sprite_addr_diamond1                                                         ; 2083: 13          .
    !byte >sprite_addr_diamond2                                                         ; 2084: 13          .
    !byte >sprite_addr_diamond3                                                         ; 2085: 13          .
    !byte >sprite_addr_diamond4                                                         ; 2086: 13          .
    !byte >sprite_addr_titanium_wall1                                                   ; 2087: 13          .
    !byte >sprite_addr_titanium_wall2                                                   ; 2088: 14          .
    !byte >sprite_addr_box                                                              ; 2089: 14          .
    !byte >sprite_addr_wall1                                                            ; 208a: 14          .
    !byte >sprite_addr_wall2                                                            ; 208b: 14          .
    !byte >sprite_addr_explosion1                                                       ; 208c: 14          .
    !byte >sprite_addr_explosion2                                                       ; 208d: 14          .
    !byte >sprite_addr_explosion3                                                       ; 208e: 14          .
    !byte >sprite_addr_explosion4                                                       ; 208f: 14          .
    !byte >sprite_addr_magic_wall1                                                      ; 2090: 15          .
    !byte >sprite_addr_magic_wall2                                                      ; 2091: 15          .
    !byte >sprite_addr_magic_wall3                                                      ; 2092: 15          .
    !byte >sprite_addr_magic_wall4                                                      ; 2093: 15          .
    !byte >sprite_addr_amoeba1                                                          ; 2094: 15          .
    !byte >sprite_addr_amoeba2                                                          ; 2095: 15          .
    !byte >sprite_addr_butterfly1                                                       ; 2096: 15          .
    !byte >sprite_addr_butterfly2                                                       ; 2097: 15          .
    !byte >sprite_addr_butterfly3                                                       ; 2098: 16          .
    !byte >sprite_addr_firefly1                                                         ; 2099: 16          .
    !byte >sprite_addr_firefly2                                                         ; 209a: 16          .
    !byte >sprite_addr_firefly3                                                         ; 209b: 16          .
    !byte >sprite_addr_firefly4                                                         ; 209c: 16          .
    !byte >sprite_addr_earth1                                                           ; 209d: 16          .
    !byte >sprite_addr_earth2                                                           ; 209e: 16          .
    !byte >sprite_addr_pathway                                                          ; 209f: 16          .
    !byte >sprite_addr_rockford_blinking1                                               ; 20a0: 17          .
    !byte >sprite_addr_rockford_blinking2                                               ; 20a1: 17          .
    !byte >sprite_addr_rockford_blinking3                                               ; 20a2: 17          .
    !byte >sprite_addr_rockford_winking1                                                ; 20a3: 17          .
    !byte >sprite_addr_rockford_winking2                                                ; 20a4: 17          .
    !byte >sprite_addr_rockford_moving_down1                                            ; 20a5: 17          .
    !byte >sprite_addr_rockford_moving_down2                                            ; 20a6: 17          .
    !byte >sprite_addr_rockford_moving_down3                                            ; 20a7: 17          .
    !byte >sprite_addr_rockford_moving_up1                                              ; 20a8: 18          .
    !byte >sprite_addr_rockford_moving_up2                                              ; 20a9: 18          .
    !byte >sprite_addr_rockford_moving_left1                                            ; 20aa: 18          .
    !byte >sprite_addr_rockford_moving_left2                                            ; 20ab: 18          .
    !byte >sprite_addr_rockford_moving_left3                                            ; 20ac: 18          .
    !byte >sprite_addr_rockford_moving_left4                                            ; 20ad: 18          .
    !byte >sprite_addr_rockford_moving_right1                                           ; 20ae: 18          .
    !byte >sprite_addr_rockford_moving_right2                                           ; 20af: 18          .
    !byte >sprite_addr_rockford_moving_right3                                           ; 20b0: 19          .
    !byte >sprite_addr_rockford_moving_right4                                           ; 20b1: 19          .
    !byte >sprite_addr_0                                                                ; 20b2: 19          .
    !byte >sprite_addr_1                                                                ; 20b3: 19          .
    !byte >sprite_addr_2                                                                ; 20b4: 19          .
    !byte >sprite_addr_3                                                                ; 20b5: 19          .
    !byte >sprite_addr_4                                                                ; 20b6: 19          .
    !byte >sprite_addr_5                                                                ; 20b7: 19          .
    !byte >sprite_addr_6                                                                ; 20b8: 1a          .
    !byte >sprite_addr_7                                                                ; 20b9: 1a          .
    !byte >sprite_addr_8                                                                ; 20ba: 1a          .
    !byte >sprite_addr_9                                                                ; 20bb: 1a          .
    !byte >sprite_addr_white                                                            ; 20bc: 1a          .
    !byte >sprite_addr_dash                                                             ; 20bd: 1a          .
    !byte >sprite_addr_slash                                                            ; 20be: 1a          .
    !byte >sprite_addr_comma                                                            ; 20bf: 1a          .
    !byte >sprite_addr_full_stop                                                        ; 20c0: 1b          .
    !byte >sprite_addr_A                                                                ; 20c1: 1b          .
    !byte >sprite_addr_B                                                                ; 20c2: 1b          .
    !byte >sprite_addr_C                                                                ; 20c3: 1b          .
    !byte >sprite_addr_D                                                                ; 20c4: 1b          .
    !byte >sprite_addr_E                                                                ; 20c5: 1b          .
    !byte >sprite_addr_F                                                                ; 20c6: 1b          .
    !byte >sprite_addr_G                                                                ; 20c7: 1b          .
    !byte >sprite_addr_H                                                                ; 20c8: 1c          .
    !byte >sprite_addr_I                                                                ; 20c9: 1c          .
    !byte >sprite_addr_J                                                                ; 20ca: 1c          .
    !byte >sprite_addr_K                                                                ; 20cb: 1c          .
    !byte >sprite_addr_L                                                                ; 20cc: 1c          .
    !byte >sprite_addr_M                                                                ; 20cd: 1c          .
    !byte >sprite_addr_N                                                                ; 20ce: 1c          .
    !byte >sprite_addr_O                                                                ; 20cf: 1c          .
    !byte >sprite_addr_P                                                                ; 20d0: 1d          .
    !byte >sprite_addr_Q                                                                ; 20d1: 1d          .
    !byte >sprite_addr_R                                                                ; 20d2: 1d          .
    !byte >sprite_addr_S                                                                ; 20d3: 1d          .
    !byte >sprite_addr_T                                                                ; 20d4: 1d          .
    !byte >sprite_addr_U                                                                ; 20d5: 1d          .
    !byte >sprite_addr_V                                                                ; 20d6: 1d          .
    !byte >sprite_addr_W                                                                ; 20d7: 1d          .
    !byte >sprite_addr_X                                                                ; 20d8: 1e          .
    !byte >sprite_addr_Y                                                                ; 20d9: 1e          .
    !byte >sprite_addr_Z                                                                ; 20da: 1e          .
    !byte >sprite_addr_bomb
    !byte >sprite_addr_bomb3
    !byte >sprite_addr_bomb2
    !byte >sprite_addr_bomb1
    !byte >sprite_addr_bubble2
unused6
;    !byte $1e                                                                           ; 20db: 1e          .
;    !byte $1e                                                                           ; 20dc: 1e          .
;    !byte $1e                                                                           ; 20dd: 1e          .
;    !byte $1e                                                                           ; 20de: 1e          .
;    !byte $1e                                                                           ; 20df: 1e          .
sprite_titanium_addressC
    !byte >sprite_addr_titanium_wall1                                                   ; 20e0: 13          .

unused7
    !byte $14, $15, $18, $18, $19, $18, $14, $14, $20, $20, $20, $20, $20, $20, $20     ; 20e1: 14 15 18... ...
    !byte $21, $21, $21, $21, $21, $21, $21, $21, $22, $22, $22, $22, $22, $22, $22     ; 20f0: 21 21 21... !!!
    !byte $22                                                                           ; 20ff: 22          "

; *************************************************************************************
cell_types_that_rocks_or_diamonds_will_fall_off
    !byte 0                                                                             ; 2100: 00          .              ; map_space
    !byte 0                                                                             ; 2101: 00          .              ; map_earth
    !byte 1                                                                             ; 2102: 01          .              ; map_wall
    !byte 0                                                                             ; 2103: 00          .              ; map_titanium_wall
    !byte 1                                                                             ; 2104: 01          .              ; map_diamond
    !byte 1                                                                             ; 2105: 01          .              ; map_rock
    !byte 0                                                                             ; 2106: 00          .              ; map_firefly
    !byte 1                                                                             ; 2107: 01          .              ; map_amoeba
    !byte 0                                                                             ; 2108: 00          .              ; map_rockford_appearing_or_end_position
    !byte 0                                                                             ; 2109: 00          .              ; map_slime
    !byte 0                                                                             ; 210a: 00          .              ; map_explosion
    !byte 0                                                                             ; 210b: 00          .              ; map_bomb
    !byte 1                                                                             ; 210c: 01          .              ; map_growing_wall
    !byte 0                                                                             ; 210d: 00          .              ; map_magic_wall
    !byte 0                                                                             ; 210e: 00          .              ; map_butterfly
    !byte 0                                                                             ; 210f: 00          .              ; map_rockford

firefly_and_butterfly_next_direction_table
    !byte 2, 3, 4, 5, 6, 7, 0, 1                                                        ; 2110: 02 03 04... ...

firefly_and_butterfly_cell_values
    !byte   (map_unprocessed | map_anim_state3) | map_firefly                           ; 2118: b6          .
    !byte (map_unprocessed | map_anim_state3) | map_butterfly                           ; 2119: be          .
    !byte   (map_unprocessed | map_anim_state0) | map_firefly                           ; 211a: 86          .
    !byte (map_unprocessed | map_anim_state0) | map_butterfly                           ; 211b: 8e          .
    !byte   (map_unprocessed | map_anim_state1) | map_firefly                           ; 211c: 96          .
    !byte (map_unprocessed | map_anim_state1) | map_butterfly                           ; 211d: 9e          .
    !byte   (map_unprocessed | map_anim_state2) | map_firefly                           ; 211e: a6          .
    !byte (map_unprocessed | map_anim_state2) | map_butterfly                           ; 211f: ae          .

items_produced_by_the_magic_wall
    !byte 0                                                                             ; 2120: 00          .              ; map_space
    !byte 0                                                                             ; 2121: 00          .              ; map_earth
    !byte 0                                                                             ; 2122: 00          .              ; map_wall
    !byte 0                                                                             ; 2123: 00          .              ; map_titanium_wall
    !byte map_unprocessed | map_rock                                                    ; 2124: 85          .              ; map_diamond
    !byte map_unprocessed | map_diamond                                                 ; 2125: 84          .              ; map_rock
    !byte 0                                                                             ; 2126: 00          .              ; map_firefly
    !byte 0                                                                             ; 2127: 00          .              ; map_amoeba
    !byte 0                                                                             ; 2128: 00          .              ; map_rockford_appearing_or_end_position
    !byte 0                                                                             ; 2129: 00          .              ; map_slime
    !byte 0                                                                             ; 212a: 00          .              ; map_explosion
    !byte 0                                                                             ; 212b: 00          .              ; map_bomb
    !byte 0                                                                             ; 212c: 00          .              ; map_growing_wall
    !byte 0                                                                             ; 212d: 00          .              ; map_magic_wall
    !byte 0                                                                             ; 212e: 00          .              ; map_butterfly
    !byte 0                                                                             ; 212f: 00          .              ; map_rockford

cell_types_that_will_turn_into_diamonds
    !byte map_unprocessed | map_diamond                                                 ; 2130: 84          .              ; map_space
    !byte map_unprocessed | map_diamond                                                 ; 2131: 84          .              ; map_earth
    !byte map_unprocessed | map_diamond                                                 ; 2132: 84          .              ; map_wall
    !byte 0                                                                             ; 2133: 00          .              ; map_titanium_wall
    !byte map_unprocessed | map_diamond                                                 ; 2134: 84          .              ; map_diamond
    !byte map_unprocessed | map_diamond                                                 ; 2135: 84          .              ; map_rock
    !byte map_unprocessed | map_diamond                                                 ; 2136: 84          .              ; map_firefly
    !byte map_unprocessed | map_diamond                                                 ; 2137: 84          .              ; map_amoeba
    !byte 0                                                                             ; 2138: 00          .              ; map_rockford_appearing_or_end_position
    !byte map_unprocessed | map_diamond                                                 ; 2139: 00          .              ; map_slime
    !byte 0                                                                             ; 213a: 00          .              ; map_explosion
    !byte 0                                                                             ; 213b: 84          .              ; map_bomb
    !byte map_unprocessed | map_diamond                                                 ; 213c: 84          .              ; map_growing_wall
    !byte map_unprocessed | map_diamond                                                 ; 213d: 84          .              ; map_magic_wall
    !byte map_unprocessed | map_diamond                                                 ; 213e: 84          .              ; map_butterfly
    !byte $ff                                                                           ; 213f: ff          .              ; map_rockford

cell_types_that_will_turn_into_large_explosion
    !byte map_unprocessed | map_large_explosion_state3                                  ; 2140: b3          .              ; map_space
    !byte map_unprocessed | map_large_explosion_state3                                  ; 2141: b3          .              ; map_earth
    !byte map_unprocessed | map_large_explosion_state3                                  ; 2142: b3          .              ; map_wall
    !byte 0                                                                             ; 2143: 00          .              ; map_titanium_wall
    !byte map_unprocessed | map_large_explosion_state3                                  ; 2144: b3          .              ; map_diamond
    !byte map_unprocessed | map_large_explosion_state3                                  ; 2145: b3          .              ; map_rock
    !byte map_unprocessed | map_large_explosion_state3                                  ; 2146: b3          .              ; map_firefly
    !byte map_unprocessed | map_large_explosion_state3                                  ; 2147: b3          .              ; map_amoeba
    !byte 0                                                                             ; 2148: 00          .              ; map_rockford_appearing_or_end_position
    !byte map_unprocessed | map_large_explosion_state3                                  ; 2149: 00          .              ; map_slime
    !byte 0                                                                             ; 214a: 00          .              ; map_explosion
    !byte map_unprocessed | map_large_explosion_state3                                  ; 214b: b3          .              ; map_bomb
    !byte map_unprocessed | map_large_explosion_state3                                  ; 214c: b3          .              ; map_growing_wall
    !byte map_unprocessed | map_large_explosion_state3                                  ; 214d: b3          .              ; map_magic_wall
    !byte map_unprocessed | map_large_explosion_state3                                  ; 214e: b3          .              ; map_butterfly
    !byte $ff                                                                           ; 214f: ff          .              ; map_rockford

; these are the cell types (indices into the table 'cell_type_to_sprite') that update
; every tick due to animation
cell_types_that_always_animate
    !byte                   map_diamond                                                 ; 2150: 04          .
    !byte map_anim_state4 | map_diamond                                                 ; 2151: 44          D
    !byte                   map_firefly                                                 ; 2152: 06          .
    !byte map_anim_state1 | map_firefly                                                 ; 2153: 16          .
    !byte map_anim_state2 | map_firefly                                                 ; 2154: 26          &
    !byte map_anim_state3 | map_firefly                                                 ; 2155: 36          6
exit_cell_type
    !byte                  map_active_exit                                              ; 2156: 18          .
    !byte map_anim_state1 | map_magic_wall                                              ; 2157: 1d          .
    !byte                    map_butterfly                                              ; 2158: 0e          .
    !byte  map_anim_state1 | map_butterfly                                              ; 2159: 1e          .
    !byte  map_anim_state2 | map_butterfly                                              ; 215a: 2e          .
    !byte  map_anim_state3 | map_butterfly                                              ; 215b: 3e          >
    !byte  map_anim_state2 | map_rockford                                               ; 215c: 2f          /
    !byte  map_anim_state1 | map_rockford                                               ; 215d: 1f          .
    !byte  map_slime                                                                    ; 215e: 09          .

unused8
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0

items_allowed_through_slime
    !byte 0                                                                             ; map_space
    !byte 0                                                                             ; map_earth
    !byte 0                                                                             ; map_wall
    !byte 0                                                                             ; map_titanium_wall
    !byte map_unprocessed | map_diamond                                                 ; map_diamond
    !byte map_unprocessed | map_rock                                                    ; map_rock
    !byte 0                                                                             ; map_firefly
    !byte 0                                                                             ; map_amoeba
    !byte 0                                                                             ; map_rockford_appearing_or_end_position
    !byte 0                                                                             ; map_slime
    !byte 0                                                                             ; map_explosion
    !byte map_unprocessed | map_bomb                                                    ; map_bomb
    !byte 0                                                                             ; map_growing_wall
    !byte 0                                                                             ; map_magic_wall
    !byte 0                                                                             ; map_butterfly
    !byte 0                                                                             ; map_rockford

update_cell_type_when_below_a_falling_rock_or_diamond
    !byte 0                                                                             ; 2180: 00          .              ; map_space
    !byte 0                                                                             ; 2181: 00          .              ; map_earth
    !byte 0                                                                             ; 2182: 00          .              ; map_wall
    !byte 0                                                                             ; 2183: 00          .              ; map_titanium_wall
    !byte 0                                                                             ; 2184: 00          .              ; map_diamond
    !byte 0                                                                             ; 2185: 00          .              ; map_rock
    !byte map_start_large_explosion                                                     ; 2186: 46          F              ; map_firefly
    !byte 0                                                                             ; 2187: 00          .              ; map_amoeba
    !byte 0                                                                             ; 2188: 00          .              ; map_rockford_appearing_or_end_position
    !byte 0                                                                             ; 2189: 00          .              ; map_slime
    !byte 0                                                                             ; 218a: 00          .              ; map_explosion
    !byte map_start_large_explosion                                                     ; 218b: 7d          }              ; map_bomb
    !byte 0                                                                             ; 218c: 00          .              ; map_growing_wall
    !byte map_anim_state3 | map_magic_wall                                              ; 218d: 3d          =              ; map_magic_wall
    !byte map_anim_state4 | map_butterfly                                               ; 218e: 4e          N              ; map_butterfly
    !byte map_anim_state7 | map_rockford                                                ; 218f: 7f          .              ; map_rockford

unused9
    !byte $91, $a1, $e1,   0, $f1, $d1, $b6, $c1,   0,   0, $d1, $f1, $c1, $71,   0     ; 2190: 91 a1 e1... ...
    !byte $71,   0,   0,   0,   0, $83, $92, $85, $8a,   0,   0, $8b, $8a, $8a,   0     ; 219f: 71 00 00... q..
    !byte   0,   0,   1,   1,   1, $ff,   1,   1,   1, $ff, $ff, $ff,   0,   0, $ff     ; 21ae: 00 00 01... ...
    !byte $ff, $ff,   0                                                                 ; 21bd: ff ff 00    ...

; *************************************************************************************
handler_table_low
    !byte <handler_basics                                                               ; 21c0: a5          .              ; map_space
    !byte <handler_basics                                                               ; 21c1: a5          .              ; map_earth
    !byte <handler_basics                                                               ; 21c2: a5          .              ; map_wall
    !byte <handler_basics                                                               ; 21c3: a5          .              ; map_titanium_wall
    !byte 0                                                                             ; 21c4: 00          .              ; map_diamond
    !byte 0                                                                             ; 21c5: 00          .              ; map_rock
    !byte <handler_firefly_or_butterfly                                                 ; 21c6: 00          .              ; map_firefly
    !byte <handler_amoeba                                                               ; 21c7: 9e          .              ; map_amoeba
    !byte <handler_rockford_intro_or_exit                                               ; 21c8: e3          .              ; map_rockford_appearing_or_end_position
    !byte <handler_slime                                                                ; 21c9: ca          .              ; map_slime
    !byte <handler_rockford_intro_or_exit                                               ; 21ca: e3          .              ; map_explosion
    !byte 0                                                                                                                ; map_bomb (special handler)
    !byte <handler_growing_wall                                                         ; 21cc: f0          .              ; map_growing_wall
    !byte <handler_magic_wall                                                           ; 21cd: ae          .              ; map_magic_wall
    !byte <handler_firefly_or_butterfly                                                 ; 21ce: 00          .              ; map_butterfly
    !byte <handler_rockford                                                             ; 21cf: 00          .              ; map_rockford
handler_table_high
    !byte >handler_basics                                                               ; 21d0: 22          "              ; map_space
    !byte >handler_basics                                                               ; 21d1: 22          "              ; map_earth
    !byte >handler_basics                                                               ; 21d2: 22          "              ; map_wall
    !byte >handler_basics                                                               ; 21d3: 22          "              ; map_titanium_wall
    !byte 0                                                                             ; 21d4: 00          .              ; map_diamond
    !byte 0                                                                             ; 21d5: 00          .              ; map_rock
    !byte >handler_firefly_or_butterfly                                                 ; 21d6: 25          %              ; map_firefly
    !byte >handler_amoeba                                                               ; 21d7: 25          %              ; map_amoeba
    !byte >handler_rockford_intro_or_exit                                               ; 21d8: 26          &              ; map_rockford_appearing_or_end_position
    !byte >handler_slime                                                                ; 21d9: 2b          +              ; map_slime
    !byte >handler_rockford_intro_or_exit                                               ; 21da: 26          &              ; map_explosion
    !byte 0                                                                                                                ; map_bomb (special handler)
    !byte >handler_growing_wall                                                         ; 21dc: 23          #              ; map_growing_wall
    !byte >handler_magic_wall                                                           ; 21dd: 26          &              ; map_magic_wall
    !byte >handler_firefly_or_butterfly                                                 ; 21de: 25          %              ; map_butterfly
    !byte >handler_rockford                                                             ; 21df: 26          &              ; map_rockford

; *************************************************************************************
explosion_replacements
    !byte map_rockford | map_unprocessed                                                ; 21e0: 8f          .
    !byte map_rockford | map_unprocessed                                                ; 21e1: 8f          .
    !byte map_diamond | map_unprocessed                                                 ; 21e2: 84          .
    !byte map_space                                                                     ; 21e3: 00          .
    !byte $f1                                                                           ; 21e4: f1          .
    !byte $d1                                                                           ; 21e5: d1          .
    !byte $b6                                                                           ; 21e6: b6          .
    !byte $b1                                                                           ; 21e7: b1          .
    !byte $8f                                                                           ; 21e8: 8f          .
    !byte $8f                                                                           ; 21e9: 8f          .
    !byte $d1                                                                           ; 21ea: d1          .
    !byte $f1                                                                           ; 21eb: f1          .
    !byte $b1                                                                           ; 21ec: b1          .
    !byte $71                                                                           ; 21ed: 71          q
    !byte 0                                                                             ; 21ee: 00          .
    !byte $71                                                                           ; 21ef: 71          q

; Given a cell type, get the type of collision:
; $ff means rockford can move onto the cell freely (e.g. space, earth),
; $0 means no movement possible (e.g. wall), and
; $1 means move with a push (e.g rock)
collision_for_cell_type
    !byte $ff                                                                           ; 21f0: ff          .              ; map_space
    !byte $ff                                                                           ; 21f1: ff          .              ; map_earth
    !byte 0                                                                             ; 21f2: 00          .              ; map_wall
    !byte 0                                                                             ; 21f3: 00          .              ; map_titanium_wall
    !byte $ff                                                                           ; 21f4: ff          .              ; map_diamond
    !byte 1                                                                             ; 21f5: 01          .              ; map_rock
    !byte 0                                                                             ; 21f6: 00          .              ; map_firefly
    !byte 0                                                                             ; 21f7: 00          .              ; map_amoeba
    !byte 0                                                                             ; 21f8: 00          .              ; map_rockford_appearing_or_end_position
    !byte 0                                                                             ; 21f9: 00          .              ; map_slime
    !byte $ff                                                                           ; 21fa: ff          .              ; map_explosion
    !byte $ff                                                                           ; 21fb: 00          .              ; map_bomb
    !byte 0                                                                             ; 21fc: 00          .              ; map_growing_wall
    !byte 0                                                                             ; 21fd: 00          .              ; map_magic_wall
    !byte 0                                                                             ; 21fe: 00          .              ; map_butterfly
    !byte 1                                                                             ; 21ff: 01          .              ; map_rockford

neighbouring_cell_variable_from_direction_index
    !byte cell_right                                                                    ; 2200: 78          x
    !byte cell_left                                                                     ; 2201: 76          v
    !byte cell_above                                                                    ; 2202: 74          t
    !byte cell_below                                                                    ; 2203: 7a          z
; Given a direction (0-3), return an offset from the current position ($41) in the map
; to check is clear when moving a rock (or zero if direction is not possible):
;    00 01 02
; 3f 40 41 42 43
;    80 81 82
;       c1
check_for_rock_direction_offsets
    !byte $43, $3f,   0, $c1                                                            ; 2204: 43 3f 00... C?.

map_offset_for_direction
    !byte $42, $40,   1, $81                                                            ; 2208: 42 40 01... B@.

unused10
    !byte   0, $10, $20, $26, $40, $50, $60, $70, $80, $90, $a0, $b0,   1, $d0, $e0     ; 220c: 00 10 20... ..
    !byte $f0                                                                           ; 221b: f0          .

    ; Next table has even offsets progressing clockwise, odd offsets progress anti-
    ; clockwise
firefly_neighbour_variables
    !byte cell_left                                                                     ; 221c: 76          v
    !byte cell_right                                                                    ; 221d: 78          x
    !byte cell_above                                                                    ; 221e: 74          t
    !byte cell_above                                                                    ; 221f: 74          t
    !byte cell_right                                                                    ; 2220: 78          x
    !byte cell_left                                                                     ; 2221: 76          v
    !byte cell_below                                                                    ; 2222: 7a          z
    !byte cell_below                                                                    ; 2223: 7a          z

rockford_cell_value_for_direction
    !byte $af, $9f,   0,   0                                                            ; 2224: af 9f 00... ...

inkey_keys_table
    !byte inkey_key_escape                                                              ; 2228: 8f          .
    !byte inkey_key_space                                                               ; 2229: 9d          .
    !byte inkey_key_b                                                                   ; 222a: 9b          .
    !byte inkey_key_return                                                              ; 222b: b6          .
    !byte inkey_key_slash                                                               ; 222c: 97          .
    !byte inkey_key_colon                                                               ; 222d: b7          .
    !byte inkey_key_z                                                                   ; 222e: 9e          .
    !byte inkey_key_x                                                                   ; 222f: bd          .

unused11
    !byte 0, 0, 0, 0, 0, 0, 0, 0

; *************************************************************************************
increment_ptr_and_clear_carry
    inc ptr_low                                                                         ; 2238: e6 8c       ..
    bne skip_increment                                                                  ; 223a: d0 02       ..
    inc ptr_high                                                                        ; 223c: e6 8d       ..
skip_increment
    clc                                                                                 ; 223e: 18          .
    rts                                                                                 ; 223f: 60          `

; *************************************************************************************
add_a_to_ptr
    clc                                                                                 ; 2240: 18          .
    adc ptr_low                                                                         ; 2241: 65 8c       e.
    sta ptr_low                                                                         ; 2243: 85 8c       ..
    bcc return1                                                                         ; 2245: 90 02       ..
    inc ptr_high                                                                        ; 2247: e6 8d       ..
return1
    rts                                                                                 ; 2249: 60          `

; *************************************************************************************
; a small 'pseudo-random' number routine. Generates a sequence of 256 numbers.
get_next_random_byte
    lda random_seed                                                                     ; 224a: a5 88       ..
    asl                                                                                 ; 224c: 0a          .
    asl                                                                                 ; 224d: 0a          .
    asl                                                                                 ; 224e: 0a          .
    asl                                                                                 ; 224f: 0a          .
    sec                                                                                 ; 2250: 38          8
    adc random_seed                                                                     ; 2251: 65 88       e.
    sta random_seed                                                                     ; 2253: 85 88       ..
    rts                                                                                 ; 2255: 60          `

; *************************************************************************************
; Clears the entire map to initial_cell_fill_value.
; Clears the visible grid to $ff
clear_map_and_grid
    lda #<(tile_map_row_1-1)                                                            ; 2256: a9 3f       .?
    sta ptr_low                                                                         ; 2258: 85 8c       ..
    lda #>(tile_map_row_1-1)                                                            ; 225a: a9 50       .P
    sta ptr_high                                                                        ; 225c: 85 8d       ..
    ldy #0                                                                              ; 225e: a0 00       ..
    ; initial random seed
    ldx #20                                                                             ; 2260: a2 14       ..
    stx random_seed                                                                     ; 2262: 86 88       ..
clear_map_loop
    lda amount_to_increment_ptr_minus_one                                               ; 2264: a5 78       .x             ; variable is always zero in practice (see calling function)
    sta cell_current                                                                    ; 2274: 85 77       .w             ; loop counter
increment_ptr_using_40_bytes_out_of_every_64
    inc ptr_low                                                                         ; 2276: e6 8c       ..
    lda ptr_low                                                                         ; 2278: a5 8c       ..
    and #$3f                                                                            ; 227a: 29 3f       )?
    cmp #$28                                                                            ; 227c: c9 28       .(
    bcc skip_moving_to_next_row                                                         ; 227e: 90 08       ..
    lda #$18                                                                            ; 2280: a9 18       ..
    jsr add_a_to_ptr                                                                    ; 2282: 20 40 22     @"
    dex                                                                                 ; 2285: ca          .
    beq return1                                                                         ; 2286: f0 c1       ..
skip_moving_to_next_row
    dec cell_current                                                                    ; 2288: c6 77       .w
    bpl increment_ptr_using_40_bytes_out_of_every_64                                    ; 228a: 10 ea       ..
    lda value_to_clear_map_to                                                           ; 228c: a5 79       .y
    sta (ptr_low),y                                                                     ; 228e: 91 8c       ..
    bpl clear_map_loop                                                                  ; 2290: 10 d2       ..

reset_grid_of_sprites
    ldx #$f0                                                                            ; 2292: a2 f0       ..
    lda #$ff                                                                            ; 2294: a9 ff       ..
reset_grid_of_sprites_loop
    dex                                                                                 ; 2296: ca          .
    sta grid_of_currently_displayed_sprites,x                                           ; 2297: 9d 00 0c    ...
    bne reset_grid_of_sprites_loop                                                      ; 229a: d0 fa       ..
    ; clear the current status bar
    ldx #$14                                                                            ; 229c: a2 14       ..
clear_status_bar_loop
    dex                                                                                 ; 229e: ca          .
    sta current_status_bar_sprites,x                                                    ; 229f: 9d 28 50    .(P
    bne clear_status_bar_loop                                                           ; 22a2: d0 fa       ..
    rts                                                                                 ; 22a4: 60          `

; *************************************************************************************
handler_basics
    txa                                                                                 ; 22a5: 8a          .
    sec                                                                                 ; 22a6: 38          8
    sbc #$90                                                                            ; 22a7: e9 90       ..
    cmp #$10                                                                            ; 22a9: c9 10       ..
    bpl not_in_range_so_change_nothing                                                  ; 22ab: 10 04       ..
    ; cell is in the range $90-$9f (corresponding to $10 to $1f with the top bit set),
    ; so we look up the replacement in a table. This is used to replace the final step
    ; of an explosion, either with rockford during the introduction (offset $01), or a
    ; space for the outro (death) explosion (offset $03)
    tax                                                                                 ; 22ad: aa          .
    lda explosion_replacements,x                                                        ; 22ae: bd e0 21    ..!
not_in_range_so_change_nothing
    tax                                                                                 ; 22b1: aa          .
    rts                                                                                 ; 22b2: 60          `

; *************************************************************************************
reveal_or_hide_more_cells
    ldy #<tile_map_row_0                                                                ; 22b3: a0 00       ..
    sty ptr_low                                                                         ; 22b5: 84 8c       ..
    lda #>tile_map_row_0                                                                ; 22b7: a9 50       .P
    sta ptr_high                                                                        ; 22b9: 85 8d       ..
    ; loop over all the rows, X is the loop counter
    ldx #22                                                                             ; 22bb: a2 16       ..
loop_over_rows
    lda ptr_low                                                                         ; 22bd: a5 8c       ..
    ; rows are stored in the first 40 bytes of every 64 bytes, so skip if we have
    ; exceeded the right range
    and #63                                                                             ; 22bf: 29 3f       )?
    cmp #40                                                                             ; 22c1: c9 28       .(
    bpl skip_to_next_row                                                                ; 22c3: 10 17       ..
    ; progress a counter in a non-obvious pattern
    jsr get_next_random_byte                                                            ; 22c5: 20 4a 22     J"
    ; if it's early in the process (tick counter is low), then branch more often so we
    ; reveal/hide the cells in a non-obvious pattern over time
    lsr                                                                                 ; 22c8: 4a          J
    lsr                                                                                 ; 22c9: 4a          J
    lsr                                                                                 ; 22ca: 4a          J
    cmp tick_counter                                                                    ; 22cb: c5 5a       .Z
    bne skip_reveal_or_hide                                                             ; 22cd: d0 08       ..
    lda (ptr_low),y                                                                     ; 22cf: b1 8c       ..
    ; clear the top bit to reveal the cell...
    and #$7f                                                                            ; 22d1: 29 7f       ).
    ; ...or set the top bit to hide the cell
    ora dissolve_to_solid_flag                                                          ; 22d3: 05 72       .r
    sta (ptr_low),y                                                                     ; 22d5: 91 8c       ..
skip_reveal_or_hide
    jsr increment_ptr_and_clear_carry                                                   ; 22d7: 20 38 22     8"
    bcc loop_over_rows                                                                  ; 22da: 90 e1       ..
    ; move forward to next row. Each row is stored at 64 byte intervals. We have moved
    ; on 40 so far so add the remainder to get to the next row
skip_to_next_row
    lda #64-40                                                                          ; 22dc: a9 18       ..
    jsr add_a_to_ptr                                                                    ; 22de: 20 40 22     @"
    dex                                                                                 ; 22e1: ca          .
    bne loop_over_rows                                                                  ; 22e2: d0 d9       ..
    ; create some 'random' audio pitches to play while revealing/hiding the map. First
    ; multiply the data set pointer low byte by five and add one
    lda sound0_active_flag                                                              ; 22e4: a5 46       .F
    asl                                                                                 ; 22e6: 0a          .
    asl                                                                                 ; 22e7: 0a          .
    sec                                                                                 ; 22e8: 38          8
    adc sound0_active_flag                                                              ; 22e9: 65 46       eF
    sta sound0_active_flag                                                              ; 22eb: 85 46       .F
    ; add the cave number
    ora cave_number                                                                     ; 22ed: 05 87       ..
    ; just take some of the bits
    and #$9e                                                                            ; 22ef: 29 9e       ).
    ; use as the pitch
    tay                                                                                 ; 22f1: a8          .
    iny                                                                                 ; 22f2: c8          .
    ldx #$85                                                                            ; 22f3: a2 85       ..
    jsr play_sound_x_pitch_y                                                            ; 22f5: 20 2c 2c     ,,
    rts                                                                                 ; 22f8: 60          `

; *************************************************************************************
; draw a full grid of sprites, updating the current map position first
draw_grid_of_sprites
    jsr update_map_scroll_position                                                      ; 2300: 20 2c 2b     ,+
    jsr update_grid_animations                                                          ; 2303: 20 00 28     .(
    lda #>screen_addr_row_6                                                             ; 2306: a9 5f       ._
    sta screen_addr1_high                                                               ; 2308: 85 8b       ..
    ldy #<screen_addr_row_6                                                             ; 230a: a0 80       ..
    lda #opcode_lda_abs_y                                                               ; 230c: a9 b9       ..
    sta load_instruction                                                                ; 230e: 8d 57 23    .W#
    lda #<grid_of_currently_displayed_sprites                                           ; 2311: a9 00       ..
    sta grid_compare_address_low                                                        ; 2313: 8d 5c 23    .\#
    sta grid_write_address_low                                                          ; 2316: 8d 61 23    .a#
    lda #>grid_of_currently_displayed_sprites                                           ; 2319: a9 0c       ..
    sta grid_compare_address_high                                                       ; 231b: 8d 5d 23    .]#
    sta grid_write_address_high                                                         ; 231e: 8d 62 23    .b#
    ; X = number of cells to draw: 12 rows of 20 cells each (a loop counter)
    ldx #20*12                                                                          ; 2321: a2 f0       ..
    bne draw_grid                                                                       ; 2323: d0 25       .%             ; ALWAYS branch

; *************************************************************************************
draw_status_bar
    ldy #<start_of_grid_screen_address                                                  ; 2325: a0 c0       ..
    lda #>start_of_grid_screen_address                                                  ; 2327: a9 5b       .[
draw_single_row_of_sprites
    sta screen_addr1_high                                                               ; 2329: 85 8b       ..
    lda #>current_status_bar_sprites                                                    ; 232b: a9 50       .P
    ldx #<current_status_bar_sprites                                                    ; 232d: a2 28       .(
    stx grid_compare_address_low                                                        ; 232f: 8e 5c 23    .\#
    stx grid_write_address_low                                                          ; 2332: 8e 61 23    .a#
    sta grid_compare_address_high                                                       ; 2335: 8d 5d 23    .]#
    sta grid_write_address_high                                                         ; 2338: 8d 62 23    .b#
instruction_for_self_modification
status_text_address_high = instruction_for_self_modification+1
    lda #>regular_status_bar                                                            ; 233b: a9 32       .2
    sta tile_map_ptr_high                                                               ; 233d: 85 86       ..
    lda #opcode_ldy_abs                                                                 ; 233f: a9 ac       ..
    sta load_instruction                                                                ; 2341: 8d 57 23    .W#
    ; X is the cell counter (20 for a single row)
    ldx #20                                                                             ; 2344: a2 14       ..
    lda status_text_address_low                                                         ; 2346: a5 69       .i
    sta tile_map_ptr_low                                                                ; 2348: 85 85       ..
draw_grid
    sty screen_addr1_low                                                                ; 234a: 84 8a       ..
draw_grid_loop
    ldy #0                                                                              ; 234c: a0 00       ..
    sty grid_column_counter                                                             ; 234e: 84 73       .s
grid_draw_row_loop
    lda (tile_map_ptr_low),y                                                            ; 2350: b1 85       ..
    tay                                                                                 ; 2352: a8          .
    bpl load_instruction                                                                ; 2353: 10 02       ..
    ; Y=9 corresponds to the titanium wall sprite used while revealing the grid
    ldy #9                                                                              ; 2355: a0 09       ..
    ; this next instruction is either:
    ;     'ldy cell_type_to_sprite' which in this context is equivalent to a no-op,
    ; which is used during preprocessing OR
    ;     'lda cell_type_to_sprite,y'
    ; to convert the cell into a sprite (used during actual gameplay).
    ; Self-modifying code above sets which version is to be used.
load_instruction
    ldy cell_type_to_sprite                                                             ; 2357: ac 80 1f    ...
    dex                                                                                 ; 235a: ca          .
compare_instruction
grid_compare_address_low = compare_instruction+1
grid_compare_address_high = compare_instruction+2
    cmp current_status_bar_sprites,x                                                    ; 235b: dd 28 50    .(P
    beq skip_draw_sprite                                                                ; 235e: f0 49       .I
write_instruction
grid_write_address_low = write_instruction+1
grid_write_address_high = write_instruction+2
    sta current_status_bar_sprites,x                                                    ; 2360: 9d 28 50    .(P
    tay                                                                                 ; 2363: a8          .
    clc                                                                                 ; 2364: 18          .
    lda sprite_addresses_low,y                                                          ; 2365: b9 00 20    ..
    sta ptr_low                                                                         ; 2368: 85 8c       ..
    adc #$10                                                                            ; 236a: 69 10       i.
    sta next_ptr_low                                                                    ; 236c: 85 82       ..
    lda sprite_addresses_high,y                                                         ; 236e: b9 80 20    ..
    sta ptr_high                                                                        ; 2371: 85 8d       ..
    sta next_ptr_high                                                                   ; 2373: 85 83       ..
    ; Each sprite is two character rows tall. screen_addr2_low/high is the destination
    ; screen address for the second character row of the sprite
    lda screen_addr1_low                                                                ; 2375: a5 8a       ..
    adc #$40                                                                            ; 2377: 69 40       i@
    sta screen_addr2_low                                                                ; 2379: 85 80       ..
    lda screen_addr1_high                                                               ; 237b: a5 8b       ..
    adc #1                                                                              ; 237d: 69 01       i.
    sta screen_addr2_high                                                               ; 237f: 85 81       ..
    ; This next loop draws a single sprite in the grid.
    ; It draws two character rows at the same time, with 16 bytes in each row.
    ldy #$0f                                                                            ; 2381: a0 0f       ..
draw_sprite_loop
    lda (ptr_low),y                                                                     ; 2383: b1 8c       ..
    sta (screen_addr1_low),y                                                            ; 2385: 91 8a       ..
    lda (next_ptr_low),y                                                                ; 2387: b1 82       ..
    sta (screen_addr2_low),y                                                            ; 2389: 91 80       ..
    dey                                                                                 ; 238b: 88          .
    lda (ptr_low),y                                                                     ; 238c: b1 8c       ..
    sta (screen_addr1_low),y                                                            ; 238e: 91 8a       ..
    lda (next_ptr_low),y                                                                ; 2390: b1 82       ..
    sta (screen_addr2_low),y                                                            ; 2392: 91 80       ..
    dey                                                                                 ; 2394: 88          .
    lda (ptr_low),y                                                                     ; 2395: b1 8c       ..
    sta (screen_addr1_low),y                                                            ; 2397: 91 8a       ..
    lda (next_ptr_low),y                                                                ; 2399: b1 82       ..
    sta (screen_addr2_low),y                                                            ; 239b: 91 80       ..
    dey                                                                                 ; 239d: 88          .
    lda (ptr_low),y                                                                     ; 239e: b1 8c       ..
    sta (screen_addr1_low),y                                                            ; 23a0: 91 8a       ..
    lda (next_ptr_low),y                                                                ; 23a2: b1 82       ..
    sta (screen_addr2_low),y                                                            ; 23a4: 91 80       ..
    dey                                                                                 ; 23a6: 88          .
    bpl draw_sprite_loop                                                                ; 23a7: 10 da       ..
    ; move the screen pointer on 16 pixels to next column
skip_draw_sprite
    clc                                                                                 ; 23a9: 18          .
    lda screen_addr1_low                                                                ; 23aa: a5 8a       ..
    adc #$10                                                                            ; 23ac: 69 10       i.
    sta screen_addr1_low                                                                ; 23ae: 85 8a       ..
    bcc skip_high_byte2                                                                 ; 23b0: 90 02       ..
    inc screen_addr1_high                                                               ; 23b2: e6 8b       ..
skip_high_byte2
    inc grid_column_counter                                                             ; 23b4: e6 73       .s
    ldy grid_column_counter                                                             ; 23b6: a4 73       .s
    cpy #20                                                                             ; 23b8: c0 14       ..
    bne grid_draw_row_loop                                                              ; 23ba: d0 94       ..
    ; return if we have drawn all the rows (X=0)
    txa                                                                                 ; 23bc: 8a          .
    beq return2                                                                         ; 23bd: f0 1c       ..
    ; move screen pointer on to next row of sprites (two character rows)
    clc                                                                                 ; 23bf: 18          .
    lda screen_addr1_low                                                                ; 23c0: a5 8a       ..
    adc #$40                                                                            ; 23c2: 69 40       i@
    sta screen_addr1_low                                                                ; 23c4: 85 8a       ..
    lda screen_addr1_high                                                               ; 23c6: a5 8b       ..
    adc #1                                                                              ; 23c8: 69 01       i.
    sta screen_addr1_high                                                               ; 23ca: 85 8b       ..
    ; move tile pointer on to next row (64 bytes)
    lda tile_map_ptr_low                                                                ; 23cc: a5 85       ..
    adc #$40                                                                            ; 23ce: 69 40       i@
    sta tile_map_ptr_low                                                                ; 23d0: 85 85       ..
    lda tile_map_ptr_high                                                               ; 23d2: a5 86       ..
    adc #0                                                                              ; 23d4: 69 00       i.
    sta tile_map_ptr_high                                                               ; 23d6: 85 86       ..
    jmp draw_grid_loop                                                                  ; 23d8: 4c 4c 23    LL#

return2
    rts                                                                                 ; 23db: 60          `

; *************************************************************************************
; 
; This is the map processing that happens every tick during gameplay.
; The map is scanned to handle any changes required.
; 
; The offsets within the map are stored in the Y register, with the current entry
; having offset $41:
; 
;     00 01 02
;     40 41 42
;     80 81 82
; 
; *************************************************************************************
    ; set branch offset (self modifying code)
update_map
    ldy #update_rock_or_diamond_that_can_fall - branch_instruction - 2                  ; 2400: a0 5f       ._
    bne scan_map                                                                        ; 2402: d0 02       ..             ; ALWAYS branch
    ldy #mark_cell_above_as_processed_and_move_to_next_cell - branch_instruction - 2    ; 2404: a0 26       .&
scan_map
    sty branch_offset                                                                   ; 2406: 8c 3a 24    .:$
    ; twenty rows
    lda #20                                                                             ; 2409: a9 14       ..
    sta tile_y                                                                          ; 240b: 85 85       ..
    lda #>tile_map_row_0                                                                ; 240d: a9 50       .P
    sta ptr_high                                                                        ; 240f: 85 8d       ..
    lda #<tile_map_row_0                                                                ; 2411: a9 00       ..
    sta ptr_low                                                                         ; 2413: 85 8c       ..
    ; Each row is stored in the first 40 bytes of every 64 bytes. Here we set Y to
    ; start on the second row, after the titanium wall border
    ldy #$40                                                                            ; 2415: a0 40       .@
    ; loop through the twenty rows of map
tile_map_y_loop
    lda #38                                                                             ; 2417: a9 26       .&             ; 38 columns (cells per row)
    sta tile_x                                                                          ; 2419: 85 86       ..
    lda (ptr_low),y                                                                     ; 241b: b1 8c       ..
    sta cell_left                                                                       ; 241d: 85 76       .v
    ; move to the next cell
    iny                                                                                 ; 241f: c8          .
    ; read current cell contents into X
    lda (ptr_low),y                                                                     ; 2420: b1 8c       ..
    tax                                                                                 ; 2422: aa          .
    ; loop through the 38 cells in a row of map
    ; read next cell contents into cell_right
tile_map_x_loop
    ldy #$42                                                                            ; 2423: a0 42       .B
    lda (ptr_low),y                                                                     ; 2425: b1 8c       ..
    sta cell_right                                                                      ; 2427: 85 78       .x
    cpx #map_diamond                                                                    ; 2429: e0 04       ..
    bmi mark_cell_above_as_processed_and_move_to_next_cell                              ; 242b: 30 34       04

    ; read cells into cell_above and cell_below variables
    ldy #1                                                                              ; 2444: a0 01       ..
    lda (ptr_low),y                                                                     ; 2446: b1 8c       ..
    sta cell_above                                                                      ; 2448: 85 74       .t
    ldy #$81                                                                            ; 244a: a0 81       ..
    lda (ptr_low),y                                                                     ; 244c: b1 8c       ..
    sta cell_below                                                                      ; 244e: 85 7a       .z

    ; if current cell is already processed (top bit set), then skip to next cell
    txa                                                                                 ; 242d: 8a          .
    bmi mark_cell_above_as_processed_and_move_to_next_cell                              ; 242e: 30 31       01
    ; mark current cell as processed (set top bit)
    ora #$80                                                                            ; 2430: 09 80       ..
    tax                                                                                 ; 2432: aa          .
    ; the lower four bits are the type, each of which has a handler to process it
    and #$0f                                                                            ; 2433: 29 0f       ).
    tay                                                                                 ; 2435: a8          .
    lda handler_table_high,y                                                            ; 2436: b9 d0 21    ..!
    ; if we have no handler for this cell type then branch (destination was set
    ; depending on where we entered this routine)
branch_instruction
branch_offset = branch_instruction+1
    beq update_rock_or_diamond_that_can_fall                                            ; 2439: f0 5f       ._
    sta handler_high                                                                    ; 243b: 8d 52 24    .R$
    lda handler_table_low,y                                                             ; 243e: b9 c0 21    ..!
    sta handler_low                                                                     ; 2441: 8d 51 24    .Q$
    ; call the handler for the cell based on the type (0-15)
jsr_handler_instruction
handler_low = jsr_handler_instruction+1
handler_high = jsr_handler_instruction+2
    jsr handler_firefly_or_butterfly                                                    ; 2450: 20 00 25     .%
    ; the handler may have changed the surrounding cells, store the new cell below
    lda cell_below                                                                      ; 2453: a5 7a       .z
    ldy #$81                                                                            ; 2455: a0 81       ..
    sta (ptr_low),y                                                                     ; 2457: 91 8c       ..
    ; store the new cell above
    lda cell_above                                                                      ; 2459: a5 74       .t
    and #$7f                                                                            ; 245b: 29 7f       ).
    ldy #1                                                                              ; 245d: a0 01       ..
    bpl move_to_next_cell                                                               ; 245f: 10 06       ..             ; ALWAYS branch

; *************************************************************************************
; 
; This is part of the preprocessing step prior to gameplay, when we find a space in the
; map
; 
; *************************************************************************************
mark_cell_above_as_processed_and_move_to_next_cell
    ldy #1                                                                              ; 2461: a0 01       ..
    lda (ptr_low),y                                                                     ; 2463: b1 8c       ..
    and #$7f                                                                            ; 2465: 29 7f       ).
move_to_next_cell
    sta (ptr_low),y                                                                     ; 2467: 91 8c       ..
    ; store the new cell left back into the map
    lda cell_left                                                                       ; 2469: a5 76       .v
    ldy #$40                                                                            ; 246b: a0 40       .@
    sta (ptr_low),y                                                                     ; 246d: 91 8c       ..
    ; update cell_left with the current cell value (in X)
    stx cell_left                                                                       ; 246f: 86 76       .v
    ; update the current cell value x from the cell_right variable
    ldx cell_right                                                                      ; 2471: a6 78       .x
    ; move ptr to next position
    inc ptr_low                                                                         ; 2473: e6 8c       ..
    ; loop back for the rest of the cells in the row
    dec tile_x                                                                          ; 2475: c6 86       ..
    bne tile_map_x_loop                                                                 ; 2477: d0 aa       ..
    ; store the final previous_cell for the row
    lda cell_left                                                                       ; 2479: a5 76       .v
    sta (ptr_low),y                                                                     ; 247b: 91 8c       ..
    ; move ptr to the start of the next row. Stride is 64, 38 entries done, so
    ; remainder to add is 64-38=26
    lda #26                                                                             ; 247d: a9 1a       ..
    jsr add_a_to_ptr                                                                    ; 247f: 20 40 22     @"
    ; loop back for the rest of the rows
    dec tile_y                                                                          ; 2482: c6 85       ..
    bne tile_map_y_loop                                                                 ; 2484: d0 91       ..
    ; clear top bit in final row
    ldy #38                                                                             ; 2486: a0 26       .&
clear_top_bit_on_final_row_loop
    lda tile_map_row_20,y                                                               ; 2488: b9 00 55    ..U
    and #$7f                                                                            ; 248b: 29 7f       ).
    sta tile_map_row_20,y                                                               ; 248d: 99 00 55    ..U
    dey                                                                                 ; 2490: 88          .
    bne clear_top_bit_on_final_row_loop                                                 ; 2491: d0 f5       ..
    ; clear top bit on end position
    lda (map_rockford_end_position_addr_low),y                                          ; 2493: b1 6a       .j
    and #$7f                                                                            ; 2495: 29 7f       ).
    sta (map_rockford_end_position_addr_low),y                                          ; 2497: 91 6a       .j
    rts                                                                                 ; 2499: 60          `

; *************************************************************************************
; Update for rock/diamond/bomb elements
;
update_rock_or_diamond_that_can_fall

    cpy #map_bomb
    bne not_a_bomb
    jsr handler_bomb  ;handle the bomb timer before continuing so it behaves like a rock/diamond
not_a_bomb
    lda gravity_timer
    beq gravity_on_as_normal
    ;gravity is off, so a rock/diamond/bomb can float
    cpy #map_rock
    bne mark_cell_above_as_processed_and_move_to_next_cell  ;only want to transition the rock
    ldx #map_rock | map_unprocessed | map_anim_state1  ;switch to a bubble sprite
    lda gravity_timer
    cmp #4
    bcs mark_cell_above_as_processed_and_move_to_next_cell
    ldx #map_rock | map_unprocessed | map_anim_state2  ;switch to a bubble-transition-to-rock sprite instead
    jmp mark_cell_above_as_processed_and_move_to_next_cell  ;bypass rock/diamond/bomb falling when gravity is off
gravity_on_as_normal
    cpx #map_rock | map_unprocessed | map_anim_state2
    bne not_a_rock
    ldx #map_rock | map_unprocessed  ;switch back to rock
not_a_rock
    ldy #$81                                                                            ; 249a: a0 81       ..
    lda (ptr_low),y                                                                     ; 249c: b1 8c       ..
    beq cell_below_is_a_space                                                           ; 249e: f0 34       .4
    ; check current cell
    cpx #map_deadly                                                                     ; 24a0: e0 c0       ..
    bmi not_c0_or_above                                                                 ; 24a2: 30 03       0.
    jsr process_c0_or_above                                                             ; 24a4: 20 db 24     .$
not_c0_or_above
    and #$4f                                                                            ; 24a7: 29 4f       )O
    tay                                                                                 ; 24a9: a8          .
    asl                                                                                 ; 24aa: 0a          .
    bmi process_next_cell                                                               ; 24ab: 30 b4       0.
    lda cell_types_that_rocks_or_diamonds_will_fall_off,y                               ; 24ad: b9 00 21    ..!
    beq process_next_cell                                                               ; 24b0: f0 af       ..
    lda cell_left                                                                       ; 24b2: a5 76       .v
    bne check_if_cell_right_is_empty                                                    ; 24b4: d0 06       ..
    ; cell left is empty, now check below left cell
    ldy #$80                                                                            ; 24b6: a0 80       ..
    lda (ptr_low),y                                                                     ; 24b8: b1 8c       ..
    beq rock_or_diamond_can_fall_left_or_right                                          ; 24ba: f0 0a       ..
check_if_cell_right_is_empty
    lda cell_right                                                                      ; 24bc: a5 78       .x
    bne process_next_cell                                                               ; 24be: d0 a1       ..
    ; cell right is empty, now check below right cell
    ldy #$82                                                                            ; 24c0: a0 82       ..
    lda (ptr_low),y                                                                     ; 24c2: b1 8c       ..
    bne process_next_cell                                                               ; 24c4: d0 9b       ..
    ; take the rock or diamond, and set bit 6 to indicate it has been moved this scan
    ; (so it won't be moved again). Then store it in the below left or below right cell
rock_or_diamond_can_fall_left_or_right
    txa                                                                                 ; 24c6: 8a          .
    ora #$40                                                                            ; 24c7: 09 40       .@
    ; Store in either cell_below_left or cell_below_right depending on Y=$80 or $82,
    ; since $fff6 = cell_below_left - $80
    sta lfff6,y                                                                         ; 24c9: 99 f6 ff    ...
    ; below left or right is set to $80, still a space, but marked as unprocessed
    lda #$80                                                                            ; 24cc: a9 80       ..
    sta (ptr_low),y                                                                     ; 24ce: 91 8c       ..
set_to_unprocessed_space
    ldx #$80                                                                            ; 24d0: a2 80       ..
    bne process_next_cell                                                               ; 24d2: d0 8d       ..             ; ALWAYS branch

    ; take the rock or diamond, and set bit 6 to indicate it has been moved this scan
    ; (so it won't be moved again). Then store it in the cell below.
cell_below_is_a_space
    txa                                                                                 ; 24d4: 8a          .
    ora #$40                                                                            ; 24d5: 09 40       .@
    sta (ptr_low),y                                                                     ; 24d7: 91 8c       ..
    bne set_to_unprocessed_space                                                        ; 24d9: d0 f5       ..             ; ALWAYS branch

process_c0_or_above
    pha                                                                                 ; 24db: 48          H
    ; look up table based on type
    and #$0f                                                                            ; 24dc: 29 0f       ).
    tay                                                                                 ; 24de: a8          .
    lda update_cell_type_when_below_a_falling_rock_or_diamond,y                         ; 24df: b9 80 21    ..!
    beq play_rock_or_diamond_fall_sound                                                 ; 24e2: f0 04       ..
    ; store in cell below
    ldy #$81                                                                            ; 24e4: a0 81       ..
    sta (ptr_low),y                                                                     ; 24e6: 91 8c       ..
play_rock_or_diamond_fall_sound
    txa                                                                                 ; 24e8: 8a          .
    and #1                                                                              ; 24e9: 29 01       ).
    eor #sound5_active_flag                                                             ; 24eb: 49 4b       IK
    tay                                                                                 ; 24ed: a8          .
    ; store $4b or $4c (i.e. a non-zero value) in location $4b or $4c. i.e. activate
    ; sound5_active_flag or sound6_active_flag
    sta page_0,y                                                                        ; 24ee: 99 00 00    ...
    ; mask off bit 6 for the current cell value
    txa                                                                                 ; 24f1: 8a          .
    and #$bf                                                                            ; 24f2: 29 bf       ).
    tax                                                                                 ; 24f4: aa          .
    pla                                                                                 ; 24f5: 68          h
    rts                                                                                 ; 24f6: 60          `

;Needed because subroutine is out of range to branch to
process_next_cell
    jmp mark_cell_above_as_processed_and_move_to_next_cell

; *************************************************************************************
handler_firefly_or_butterfly
    cpx #map_deadly                                                                     ; 2500: e0 c0       ..
    bpl show_large_explosion                                                            ; 2502: 10 3e       .>
    ; check directions in order: cell_below, cell_right, cell_left, cell_up
    ldy #8                                                                              ; 2504: a0 08       ..
look_for_amoeba_or_player_loop
    lda cell_above_left-1,y                                                             ; 2506: b9 72 00    .r.
;    bne unnecessary_branch                                                              ; 2509: d0 00       ..             ; redundant instruction
;unnecessary_branch
    and #7                                                                              ; 250b: 29 07       ).
    eor #7                                                                              ; 250d: 49 07       I.
    beq show_large_explosion                                                            ; 250f: f0 31       .1
    dey                                                                                 ; 2511: 88          .
    dey                                                                                 ; 2512: 88          .
    bne look_for_amoeba_or_player_loop                                                  ; 2513: d0 f1       ..
    ; calculate direction to move in Y
    txa                                                                                 ; 2515: 8a          .
    lsr                                                                                 ; 2516: 4a          J
    lsr                                                                                 ; 2517: 4a          J
    lsr                                                                                 ; 2518: 4a          J
    and #7                                                                              ; 2519: 29 07       ).
    tay                                                                                 ; 251b: a8          .
    ; branch if the desired direction is empty
    ldx firefly_neighbour_variables,y                                                   ; 251c: be 1c 22    .."
    lda page_0,x                                                                        ; 251f: b5 00       ..
    beq set_firefly_or_butterfly                                                        ; 2521: f0 11       ..
    ; get the next direction in Y
    lda firefly_and_butterfly_next_direction_table,y                                    ; 2523: b9 10 21    ..!
    tay                                                                                 ; 2526: a8          .
    ; branch if the second desired direction is empty
    ldx firefly_neighbour_variables,y                                                   ; 2527: be 1c 22    .."
    lda page_0,x                                                                        ; 252a: b5 00       ..
    beq set_firefly_or_butterfly                                                        ; 252c: f0 06       ..
    ; set X=0 to force the use of the final possible direction
    ldx #0                                                                              ; 252e: a2 00       ..
    ; get the last cardinal direction that isn't a u-turn
    lda firefly_and_butterfly_next_direction_table,y                                    ; 2530: b9 10 21    ..!
    tay                                                                                 ; 2533: a8          .
set_firefly_or_butterfly
    lda firefly_and_butterfly_cell_values,y                                             ; 2534: b9 18 21    ..!
    cpx #0                                                                              ; 2537: e0 00       ..
    bne store_firefly_and_clear_current_cell                                            ; 2539: d0 02       ..
    tax                                                                                 ; 253b: aa          .
    rts                                                                                 ; 253c: 60          `

store_firefly_and_clear_current_cell
    sta page_0,x                                                                        ; 253d: 95 00       ..
    ldx #0                                                                              ; 253f: a2 00       ..
    rts                                                                                 ; 2541: 60          `

show_large_explosion
    txa                                                                                 ; 2542: 8a          .
    ldx #<cell_types_that_will_turn_into_large_explosion                                ; 2543: a2 40       .@
    and #8                                                                              ; 2545: 29 08       ).
    beq set_explosion_type                                                              ; 2547: f0 02       ..
    ldx #<cell_types_that_will_turn_into_diamonds                                       ; 2549: a2 30       .0
set_explosion_type
    stx lookup_table_address_low                                                        ; 254b: 8e 72 25    .r%
    ; activate explosion sound
    stx sound6_active_flag                                                              ; 254e: 86 4c       .L
    ; read above left cell
    ldy #0                                                                              ; 2550: a0 00       ..
    lda (ptr_low),y                                                                     ; 2552: b1 8c       ..
    sta cell_above_left                                                                 ; 2554: 85 73       .s
    ; reset current cell to zero
    sty cell_current                                                                    ; 2556: 84 77       .w
    ; read above right cell
    ldy #2                                                                              ; 2558: a0 02       ..
    lda (ptr_low),y                                                                     ; 255a: b1 8c       ..
    sta cell_above_right                                                                ; 255c: 85 75       .u
    ; read below left cell
    ldy #$80                                                                            ; 255e: a0 80       ..
    lda (ptr_low),y                                                                     ; 2560: b1 8c       ..
    sta cell_below_left                                                                 ; 2562: 85 79       .y
    ; read below right cell
    ldy #$82                                                                            ; 2564: a0 82       ..
    lda (ptr_low),y                                                                     ; 2566: b1 8c       ..
    sta cell_below_right                                                                ; 2568: 85 7b       .{
    ; loop 9 times to replace all the neighbour cells with diamonds or large explosion
    ldx #9                                                                              ; 256a: a2 09       ..
replace_neighbours_loop
    lda cell_above_left-1,x                                                             ; 256c: b5 72       .r
    and #$0f                                                                            ; 256e: 29 0f       ).
    tay                                                                                 ; 2570: a8          .
read_from_table_instruction
lookup_table_address_low = read_from_table_instruction+1
    lda cell_types_that_will_turn_into_large_explosion,y                                ; 2571: b9 40 21    .@!
    beq skip_storing_explosion_into_cell                                                ; 2574: f0 02       ..
    sta cell_above_left-1,x                                                             ; 2576: 95 72       .r
skip_storing_explosion_into_cell
    dex                                                                                 ; 2578: ca          .
    bne replace_neighbours_loop                                                         ; 2579: d0 f1       ..
    ; write new values back into the corner cells
    ; write to above left cell
    ldy #0                                                                              ; 257b: a0 00       ..
    lda cell_above_left                                                                 ; 257d: a5 73       .s
    and #$7f                                                                            ; 257f: 29 7f       ).
    sta (ptr_low),y                                                                     ; 2581: 91 8c       ..
    ; write to above right cell
    ldy #2                                                                              ; 2583: a0 02       ..
    lda cell_above_right                                                                ; 2585: a5 75       .u
    sta (ptr_low),y                                                                     ; 2587: 91 8c       ..
    ; write to below left cell
    ldy #$80                                                                            ; 2589: a0 80       ..
    lda cell_below_left                                                                 ; 258b: a5 79       .y
    sta (ptr_low),y                                                                     ; 258d: 91 8c       ..
    ; write to below right cell
    ldy #$82                                                                            ; 258f: a0 82       ..
    lda cell_below_right                                                                ; 2591: a5 7b       .{
    sta (ptr_low),y                                                                     ; 2593: 91 8c       ..
    ldx cell_current                                                                    ; 2595: a6 77       .w
    rts                                                                                 ; 2597: 60          `

; *************************************************************************************
handler_amoeba
    lda amoeba_replacement                                                              ; 259e: a5 54       .T
    beq update_amoeba                                                                   ; 25a0: f0 04       ..
    ; play amoeba sound
    tax                                                                                 ; 25a2: aa          .
    sta sound6_active_flag                                                              ; 25a3: 85 4c       .L
    rts                                                                                 ; 25a5: 60          `

update_amoeba
    inc number_of_amoeba_cells_found                                                    ; 25a6: e6 56       .V
    ; check for surrounding space or earth allowing the amoeba to grow
    lda #$0e                                                                            ; 25a8: a9 0e       ..
    bit cell_above                                                                      ; 25aa: 24 74       $t
    beq amoeba_can_grow                                                                 ; 25ac: f0 0c       ..
    bit cell_left                                                                       ; 25ae: 24 76       $v
    beq amoeba_can_grow                                                                 ; 25b0: f0 08       ..
    bit cell_right                                                                      ; 25b2: 24 78       $x
    beq amoeba_can_grow                                                                 ; 25b4: f0 04       ..
    bit cell_below                                                                      ; 25b6: 24 7a       $z
    bne return3                                                                         ; 25b8: d0 3b       .;
amoeba_can_grow
    stx current_amoeba_cell_type                                                        ; 25ba: 86 60       .`
    stx sound0_active_flag                                                              ; 25bc: 86 46       .F
    inc amoeba_counter                                                                  ; 25be: e6 57       .W
    lda amoeba_counter                                                                  ; 25c0: a5 57       .W
    cmp amoeba_growth_interval                                                          ; 25c2: c5 55       .U
    bne return3                                                                         ; 25c4: d0 2f       ./
    lda #0                                                                              ; 25c6: a9 00       ..
    sta amoeba_counter                                                                  ; 25c8: 85 57       .W
    ; calculate direction to grow based on current amoeba state in top bits
    txa                                                                                 ; 25ca: 8a          .
    lsr                                                                                 ; 25cb: 4a          J
    lsr                                                                                 ; 25cc: 4a          J
    lsr                                                                                 ; 25cd: 4a          J
    and #6                                                                              ; 25ce: 29 06       ).
    ; Y is set to 0,2,4, or 6 for the compass directions
    tay                                                                                 ; 25d0: a8          .
    cpx #map_deadly                                                                     ; 25d1: e0 c0       ..
    bmi check_for_space_or_earth                                                        ; 25d3: 30 0d       0.
    ; get cell value for direction Y
    lda cell_above,y                                                                    ; 25d5: b9 74 00    .t.
    beq found_space_or_earth_to_grow_into                                               ; 25d8: f0 0f       ..
    ; move amoeba onto next state (add 16)
increment_top_nybble_of_amoeba
    txa                                                                                 ; 25da: 8a          .
    clc                                                                                 ; 25db: 18          .
    adc #$10                                                                            ; 25dc: 69 10       i.
    and #$7f                                                                            ; 25de: 29 7f       ).
    tax                                                                                 ; 25e0: aa          .
    rts                                                                                 ; 25e1: 60          `

    ; get cell value for direction Y
check_for_space_or_earth
    lda cell_above,y                                                                    ; 25e2: b9 74 00    .t.
    ; branch if 0 or 1 (space or earth)
    and #$0e                                                                            ; 25e5: 29 0e       ).
    bne increment_top_nybble_of_amoeba                                                  ; 25e7: d0 f1       ..
found_space_or_earth_to_grow_into
    lda tick_counter                                                                    ; 25e9: a5 5a       .Z
    lsr                                                                                 ; 25eb: 4a          J
    bcc store_x                                                                         ; 25ec: 90 03       ..
    jsr increment_top_nybble_of_amoeba                                                  ; 25ee: 20 da 25     .%
store_x
    txa                                                                                 ; 25f1: 8a          .
    sta cell_above,y                                                                    ; 25f2: 99 74 00    .t.
return3
    rts                                                                                 ; 25f5: 60          `

; *************************************************************************************
handler_rockford
    stx current_rockford_sprite                                                         ; 2600: 86 5b       .[
    lda rockford_explosion_cell_type                                                    ; 2602: a5 5f       ._
    bne start_large_explosion                                                           ; 2604: d0 03       ..
    inx                                                                                 ; 2606: e8          .
    bne check_for_direction_key_pressed                                                 ; 2607: d0 05       ..
start_large_explosion
    ldx #map_start_large_explosion                                                      ; 2609: a2 46       .F
    stx rockford_explosion_cell_type                                                    ; 260b: 86 5f       ._
    rts                                                                                 ; 260d: 60          `

check_for_direction_key_pressed
    lda keys_to_process                                                                 ; 260e: a5 62       .b
    and #$f0                                                                            ; 2610: 29 f0       ).
    bne direction_key_pressed                                                           ; 2612: d0 12       ..
    ; player is not moving in any direction
    ldx #map_rockford                                                                   ; 2614: a2 0f       ..
update_player_at_current_location
    lda #$41                                                                            ; 2616: a9 41       .A
play_movement_sound_and_update_current_position_address
    sta sound2_active_flag                                                              ; 2618: 85 48       .H
    clc                                                                                 ; 261a: 18          .
    adc ptr_low                                                                         ; 261b: 65 8c       e.
    sta map_rockford_current_position_addr_low                                          ; 261d: 85 70       .p
    lda ptr_high                                                                        ; 261f: a5 8d       ..
    adc #0                                                                              ; 2621: 69 00       i.
    sta map_rockford_current_position_addr_high                                         ; 2623: 85 71       .q
    rts                                                                                 ; 2625: 60          `

direction_key_pressed
    ldx #0                                                                              ; 2626: a2 00       ..
    stx ticks_since_last_direction_key_pressed                                          ; 2628: 86 58       .X
    dex                                                                                 ; 262a: ca          .
get_direction_index_loop
    inx                                                                                 ; 262b: e8          .
    asl                                                                                 ; 262c: 0a          .
    bcc get_direction_index_loop                                                        ; 262d: 90 fc       ..
    lda rockford_cell_value_for_direction,x                                             ; 262f: bd 24 22    .$"
    beq skip_storing_rockford_cell_type                                                 ; 2632: f0 02       ..
    sta rockford_cell_value                                                             ; 2634: 85 52       .R
skip_storing_rockford_cell_type
    ldy neighbouring_cell_variable_from_direction_index,x                               ; 2636: bc 00 22    .."
    sty neighbouring_cell_variable                                                      ; 2639: 84 73       .s
    ; read cell contents from the given neighbouring cell variable y
    lda page_0,y                                                                        ; 263b: b9 00 00    ...
    sta neighbour_cell_contents                                                         ; 263e: 85 64       .d
    and #$0f                                                                            ; 2640: 29 0f       ).
    tay                                                                                 ; 2642: a8          .
    ; branch if movement is not possible
    lda collision_for_cell_type,y                                                       ; 2643: b9 f0 21    ..!
    beq check_if_value_is_empty                                                         ; 2646: f0 2c       .,
    ; branch if movement is freely possible
    bmi check_for_return_pressed                                                        ; 2648: 30 1d       0.
    ; trying to move into something difficult to move (e.g. a rock)
    ldy check_for_rock_direction_offsets,x                                              ; 264a: bc 04 22    .."
    beq check_if_value_is_empty                                                         ; 264d: f0 25       .%
    cpy #$ee  ;Special value used to detect rock has been pushed up
    beq check_push_up
    lda (ptr_low),y                                                                     ; 264f: b1 8c       ..
    bne check_if_value_is_empty                                                         ; 2651: d0 21       .!
    lda neighbour_cell_contents                                                         ; 2653: a5 64       .d
    ; don't try pushing a rock that's just fallen this tick (bit 6 set at $24c7)
    cmp #$45                                                                            ; 2655: c9 45       .E
    beq check_if_value_is_empty                                                         ; 2657: f0 1b       ..
    dec delay_trying_to_push_rock                                                       ; 2659: c6 53       .S
    bne check_if_value_is_empty                                                         ; 265b: d0 17       ..
    ora #$80                                                                            ; 265d: 09 80       ..
    sta (ptr_low),y                                                                     ; 265f: 91 8c       ..
    lda #4                                                                              ; 2661: a9 04       ..
    sta delay_trying_to_push_rock                                                       ; 2663: 85 53       .S
    inc sound4_active_flag                                                              ; 2665: e6 4a       .J
check_for_return_pressed
    lda keys_to_process                                                                 ; 2667: a5 62       .b
    and #8                                                                              ; 2669: 29 08       ).
    beq store_rockford_cell_value_without_return_pressed                                ; 266b: f0 0b       ..
    ; return and direction is pressed. clear the appropriate cell
    jsr check_if_bombs_used  ;Returns accumulator used below
    ldy neighbouring_cell_variable
    sta page_0,y                                                                        ; 2671: 99 00 00    ...
check_if_value_is_empty
    ldx rockford_cell_value                                                             ; 2674: a6 52       .R
    bne update_player_at_current_location                                               ; 2676: d0 9e       ..
store_rockford_cell_value_without_return_pressed
    ldy neighbouring_cell_variable                                                      ; 2678: a4 73       .s
    lda rockford_cell_value                                                             ; 267a: a5 52       .R
    sta page_0,y                                                                        ; 267c: 99 00 00    ...
    lda map_offset_for_direction,x                                                      ; 267f: bd 08 22    .."
    dex                                                                                 ; 2682: ca          .
    beq play_movement_sound_and_update_current_position_address                         ; 2683: f0 93       ..
    ldx #$80                                                                            ; 2685: a2 80       ..
    bne play_movement_sound_and_update_current_position_address                         ; 2687: d0 8f       ..             ; ALWAYS branch

; *************************************************************************************
read_keys
    ldx #7                                                                              ; 2689: a2 07       ..
    stx cell_current                                                                    ; 268b: 86 77       .w
    ldx #0                                                                              ; 268d: a2 00       ..
    stx real_keys_pressed                                                               ; 268f: 86 7c       .|
read_keys_loop
    ldx cell_current                                                                    ; 2691: a6 77       .w
    lda inkey_keys_table,x                                                              ; 2693: bd 28 22    .("
    tax                                                                                 ; 2696: aa          .
    tay                                                                                 ; 2697: a8          .
    lda #osbyte_inkey                                                                   ; 2698: a9 81       ..
    jsr osbyte                                                                          ; 269a: 20 f4 ff     ..            ; Read key within time limit, or read a specific key, or read machine type
    inx                                                                                 ; 269d: e8          .
    rol real_keys_pressed                                                               ; 269e: 26 7c       &|
    dec cell_current                                                                    ; 26a0: c6 77       .w
    bpl read_keys_loop                                                                  ; 26a2: 10 ed       ..
    lda keys_to_process                                                                 ; 26a4: a5 62       .b
    ora real_keys_pressed                                                               ; 26a6: 05 7c       .|
    sta keys_to_process                                                                 ; 26a8: 85 62       .b
    rts                                                                                 ; 26aa: 60          `

;Subroutine to allow Rockford to push a rock upwards
;Needs to check there is a free space above the rock being pushed, allow for the push delay, then continue like other direction pushes
check_push_up
    lda ptr_high  ;store current line pointer high/low on stack
    pha
    lda ptr_low
    pha
    sec
	lda ptr_low
	sbc #$80  ;Need to point upwards 2 lines, so subtract (64 x 2 = 128) from pointer high/low
	sta ptr_low
    bcs no_up_ptr_high_change
    dec ptr_high
no_up_ptr_high_change
    ldy #$41  ;offset the line pointer with Rockford's position
    lda (ptr_low),y  ;this is the cell value 2 rows above Rockford
    bne end_check_up
    dec delay_trying_to_push_rock  ;ok to push up but delay
    bne end_check_up
    lda #map_rock | map_anim_state1  ;delay over, store a rock in the cell 2 rows above Rockford
    sta (ptr_low),y
    lda #4  ;reset the delay for next time
    sta delay_trying_to_push_rock
    inc sound4_active_flag
    pla  ;restore current line pointer high/low from stack
    sta ptr_low
    pla
    sta ptr_high
    jmp store_rockford_cell_value_without_return_pressed  ;continue like side/bottom pushes
end_check_up
    pla  ;restore current line pointer high/low from stack
    sta ptr_low
    pla
    sta ptr_high
    jmp check_if_value_is_empty  ;continue like side/bottom non-pushes

;Subroutine called when pressing return + key direction
;if bombs are allowed, place a bomb in the space of the direction, otherwise just clear the space given by the direction
check_if_bombs_used
    lda bomb_counter
    bne bombs_allowed
    lda #0
    rts
bombs_allowed
    lda neighbour_cell_contents
    beq check_bomb_delay
    lda #0
    rts
check_bomb_delay
    lda bomb_delay
    beq create_a_bomb
    lda #0
    rts
create_a_bomb
    lda #3  ;delay creation of next bomb
    sta bomb_delay
    dec bomb_counter  ;one less bomb to use
    ldy #4
    jsr decrement_status_bar_number  ;update status bar
    lda #map_bomb
    rts

; *************************************************************************************
handler_growing_wall
;Growing wall element introduced in Boulder Dash 2, allows a wall to extend horizontally if the item beside it is empty space
;Used in Boulder Dash 2 in cave O

    lda cell_left                                          ; read cell to the left of the growing wall
    and #$0f                                               ; getting the cell type from the lower nybble
    bne check_grow_right                                   ; If not zero (map_space) then examine cell to the right
    lda #map_unprocessed | map_growing_wall                ; Otherwise replace the left cell with another growing wall
    sta cell_left
check_grow_right
    lda cell_right                                         ; read cell to the right of the growing wall
    and #$0f                                               ; getting the cell type from the lower nybble
    bne grow_wall_return                                   ; If not zero (map_space) then end
    lda #map_unprocessed | map_growing_wall                ; Otherwise replace the right cell with another growing wall
    sta cell_right
grow_wall_return
    rts

; *************************************************************************************
handler_bomb
;Bomb element is not an original game element, introduced by raspberrypioneer in October 2024
;Rockford can lay a bomb in a space tile by holding down return and pressing a direction key
;The bomb has a fuse and when time is up, it explodes like a firefly / butterfly / Rockford can

    cpx #map_bomb | map_unprocessed | $40                  ;if bomb, unprocessed and falling then suspend countdown
    bcs bomb_return
    lda tick_counter
    and #7                                                 ;check only bits 0,1,2 of the tick counter
    cmp #7                                                 ;equals 7
    bne bomb_return                                        ;do nothing if not 7
    txa                                                    ;x register holds current cell value
    clc
    adc #map_anim_state1                                   ;add the next animation frame
    cmp #map_bomb | map_unprocessed | map_anim_state4      ;use last animation frame to check limit
    bcs bomb_explode                                       ;if past last frame, time to explode!
    tax                                                    ;x register holds current cell value, updated with animation frame
    rts
bomb_explode
    ldx #map_deadly                                        ;set the cell to deadly
    jsr show_large_explosion                               ;call the explosion routine

    lda cell_below                                         ;update cell below (as done by other 'standard' handlers)
    ldy #$81
    sta (ptr_low),y
    lda cell_above                                         ;update cell below (as done by other 'standard' handlers)
    ldy #1
    sta (ptr_low),y

bomb_return
    rts

; *************************************************************************************
handler_magic_wall
    txa                                                                                 ; 26ae: 8a          .
    ldx magic_wall_state                                                                ; 26af: a6 50       .P
    cmp #$bd                                                                            ; 26b1: c9 bd       ..
    bne check_if_magic_wall_is_active                                                   ; 26b3: d0 25       .%
    ; read what's above the wall, getting the cell type from the lower nybble
    lda cell_above                                                                      ; 26b5: a5 74       .t
    and #$0f                                                                            ; 26b7: 29 0f       ).
    tay                                                                                 ; 26b9: a8          .
    ; read what cell types are allowed to fall through and what is produced as a result
    ; (rocks turn into diamonds and vice versa)
    lda items_produced_by_the_magic_wall,y                                              ; 26ba: b9 20 21    . !
    beq skip_storing_space_above                                                        ; 26bd: f0 04       ..
    ; something will fall into the wall, clear the cell above
    ldy #map_unprocessed | map_space                                                    ; 26bf: a0 80       ..
    sty cell_above                                                                      ; 26c1: 84 74       .t
skip_storing_space_above
    cpx #$2d                                                                            ; 26c3: e0 2d       .-
    beq store_magic_wall_state                                                          ; 26c5: f0 10       ..
    ; if the cell below isn't empty, then don't store the item below
    ldy cell_below                                                                      ; 26c7: a4 7a       .z
    bne magic_wall_is_active                                                            ; 26c9: d0 02       ..
    ; store the item that has fallen through the wall below
    sta cell_below                                                                      ; 26cb: 85 7a       .z
magic_wall_is_active
    ldx #$1d                                                                            ; 26cd: a2 1d       ..
    inc sound1_active_flag                                                              ; 26cf: e6 47       .G
    ldy magic_wall_timer                                                                ; 26d1: a4 51       .Q
    bne store_magic_wall_state                                                          ; 26d3: d0 02       ..
    ; magic wall becomes inactive once the timer has run out
    ldx #$2d                                                                            ; 26d5: a2 2d       .-
store_magic_wall_state
    stx magic_wall_state                                                                ; 26d7: 86 50       .P
    rts                                                                                 ; 26d9: 60          `

check_if_magic_wall_is_active
    cpx #$1d                                                                            ; 26da: e0 1d       ..
    beq magic_wall_is_active                                                            ; 26dc: f0 ef       ..
    rts                                                                                 ; 26de: 60          `

; *************************************************************************************
    ; mark rockford cell as visible
handler_rockford_intro_or_exit
    txa                                                                                 ; 26e3: 8a          .
    and #$7f                                                                            ; 26e4: 29 7f       ).
    tax                                                                                 ; 26e6: aa          .
    ; branch if on exit
    cpx #map_active_exit                                                                ; 26e7: e0 18       ..
    beq return4                                                                         ; 26e9: f0 12       ..
    ; we have found the intro square
    lda #0                                                                              ; 26eb: a9 00       ..
    sta keys_to_process                                                                 ; 26ed: 85 62       .b
    ; wait for flashing rockford animation to finish
    lda tick_counter                                                                    ; 26ef: a5 5a       .Z
    cmp #$f0                                                                            ; 26f1: c9 f0       ..
    bpl return4                                                                         ; 26f3: 10 08       ..
    ; start the explosion just before gameplay starts
    ldx #$21                                                                            ; 26f5: a2 21       .!
    inc sound4_active_flag                                                              ; 26f7: e6 4a       .J
    lda #<regular_status_bar                                                            ; 26f9: a9 00       ..
    sta status_text_address_low                                                         ; 26fb: 85 69       .i
return4
    rts                                                                                 ; 26fd: 60          `

; *************************************************************************************
start_gameplay
    jsr reset_clock                                                                     ; 2700: 20 4d 2a     M*
    lda #1                                                                              ; 2703: a9 01       ..
    sta demo_key_duration                                                               ; 2705: 85 67       .g
    ; Set A=0
    lsr                                                                                 ; 2707: 4a          J
    sta zeroed_but_unused                                                               ; 2708: 85 66       .f
gameplay_loop
    lda #0                                                                              ; 270a: a9 00       ..
    ; clear sound
    ldx #7                                                                              ; 270c: a2 07       ..
zero_eight_bytes_loop
    sta sound0_active_flag,x                                                            ; 270e: 95 46       .F
    dex                                                                                 ; 2710: ca          .
    bpl zero_eight_bytes_loop                                                           ; 2711: 10 fb       ..
    ; zero variables
    sta status_text_address_low                                                         ; 2713: 85 69       .i
    sta current_amoeba_cell_type                                                        ; 2715: 85 60       .`
    sta neighbour_cell_contents                                                         ; 2717: 85 64       .d
    ; activate movement sound
    lda #$41                                                                            ; 2719: a9 41       .A
    sta sound2_active_flag                                                              ; 271b: 85 48       .H
    ; reset number of amoeba cells found, and if already zero then clear the
    ; amoeba_replacement
    ldx #0                                                                              ; 271d: a2 00       ..
    lda number_of_amoeba_cells_found                                                    ; 271f: a5 56       .V
    stx number_of_amoeba_cells_found                                                    ; 2721: 86 56       .V
    bne skip_clearing_amoeba_replacement                                                ; 2723: d0 02       ..
    stx amoeba_replacement                                                              ; 2725: 86 54       .T
skip_clearing_amoeba_replacement
    stx current_amoeba_cell_type                                                        ; 2727: 86 60       .`
    jsr wait_for_13_centiseconds_and_read_keys                                          ; 2729: 20 90 2b     .+
    ; branch if not in demo mode
    ldx demo_mode_tick_count                                                            ; 272c: a6 65       .e
    bmi update_gameplay                                                                 ; 272e: 30 22       0"
    ; if a key is pressed in demo mode, then return
    lda keys_to_process                                                                 ; 2730: a5 62       .b
    beq update_demo_mode                                                                ; 2732: f0 01       ..
    rts                                                                                 ; 2734: 60          `

update_demo_mode
    ldy #<regular_status_bar                                                            ; 2735: a0 00       ..
    ; flip between status bar and demo mode text every 16 ticks
    lda tick_counter                                                                    ; 2737: a5 5a       .Z
    and #$10                                                                            ; 2739: 29 10       ).
    beq skip_demo_mode_text                                                             ; 273b: f0 02       ..
    ldy #<demonstration_mode_text                                                       ; 273d: a0 a0       ..
skip_demo_mode_text
    sty status_text_address_low                                                         ; 273f: 84 69       .i
    lda demonstration_keys,x                                                            ; 2741: bd 00 31    ..1
    sta keys_to_process                                                                 ; 2744: 85 62       .b
    dec demo_key_duration                                                               ; 2746: c6 67       .g
    bne update_gameplay                                                                 ; 2748: d0 08       ..
    inc demo_mode_tick_count                                                            ; 274a: e6 65       .e
    inx                                                                                 ; 274c: e8          .
    lda demonstration_key_durations,x                                                   ; 274d: bd 60 31    .`1
    sta demo_key_duration                                                               ; 2750: 85 67       .g

update_gameplay
    jsr update_map                                                                      ; 2752: 20 00 24     .$
    ; get the contents of the cell that rockford is influencing. This can be the cell
    ; underneath rockford, or by holding the RETURN key down and pressing a direction
    ; key it can be one of the neighbouring cells.
    ; We clear the top bits to just extract the basic type.
    lda neighbour_cell_contents                                                         ; 2755: a5 64       .d
    and #$0f                                                                            ; 2757: 29 0f       ).
    sta neighbour_cell_contents                                                         ; 2759: 85 64       .d
    cmp #map_rockford_appearing_or_end_position                                         ; 275b: c9 08       ..
    bne rockford_is_not_at_end_position                                                 ; 275d: d0 03       ..
    jmp update_with_gameplay_not_active                                                 ; 275f: 4c 40 30    L@0

rockford_is_not_at_end_position
    jsr draw_grid_of_sprites                                                            ; 2762: 20 00 23     .#
    jsr draw_status_bar                                                                 ; 2765: 20 25 23     %#
    jsr update_amoeba_timing                                                            ; 2768: 20 00 30     .0
    ; check if the player is still alive by reading the current rockford sprite (branch
    ; if not)
    lda current_rockford_sprite                                                         ; 276b: a5 5b       .[
    beq check_for_earth                                                                 ; 276d: f0 18       ..
    ; update game timer (sub seconds)
    dec sub_second_ticks                                                                ; 276f: c6 5c       .\
    bpl check_for_earth                                                                 ; 2771: 10 14       ..
    ; each 'second' of game time has 11 game ticks
    ldx #11                                                                             ; 2773: a2 0b       ..
    stx sub_second_ticks                                                                ; 2775: 86 5c       .\
    ; decrement time remaining ('seconds') on the status bar and in the separate
    ; variable
    ldy #12                                                                             ; 2777: a0 0c       ..
    jsr decrement_status_bar_number                                                     ; 2779: 20 aa 28     .(
    dec time_remaining                                                                  ; 277c: c6 6d       .m
    ; branch if there's still time left
    bne check_for_earth                                                                 ; 277e: d0 07       ..
    ; out of time
    lda #<out_of_time_message                                                           ; 2780: a9 b4       ..
    sta status_text_address_low                                                         ; 2782: 85 69       .i
    jmp update_with_gameplay_not_active                                                 ; 2784: 4c 40 30    L@0

check_for_earth
    lda neighbour_cell_contents                                                         ; 2787: a5 64       .d
    cmp #1                                                                              ; 2789: c9 01       ..
    bne skip_earth                                                                      ; 278b: d0 02       ..
    ; got earth. play sound 3
    inc sound3_active_flag                                                              ; 278d: e6 49       .I
skip_earth
    cmp #4                                                                              ; 278f: c9 04       ..
    bne skip_got_diamond                                                                ; 2791: d0 11       ..
    ; got diamond. play sounds
    ldx #$85                                                                            ; 2793: a2 85       ..
    ldy #$f0                                                                            ; 2795: a0 f0       ..
    jsr play_sound_x_pitch_y                                                            ; 2797: 20 2c 2c     ,,
    ldx #$85                                                                            ; 279a: a2 85       ..
    ldy #$d2                                                                            ; 279c: a0 d2       ..
    jsr play_sound_x_pitch_y                                                            ; 279e: 20 2c 2c     ,,
    jsr got_diamond_so_update_status_bar                                                ; 27a1: 20 00 2f     ./
skip_got_diamond
    jsr update_sounds                                                                   ; 27a4: 20 80 2c     .,
    ; update game tick
    dec tick_counter                                                                    ; 27a7: c6 5a       .Z
    lda tick_counter                                                                    ; 27a9: a5 5a       .Z
    and #7                                                                              ; 27ab: 29 07       ).
    bne update_death_explosion                                                          ; 27ad: d0 08       ..
    ;update bomb delay timer
    lda bomb_delay
    beq end_update_bomb_delay
    dec bomb_delay
end_update_bomb_delay
    ; update gravity timer
    lda gravity_timer
    beq end_update_gravity_timer  ;stop at zero
    cmp #$ff
    beq end_update_gravity_timer  ;gravity is always on if set to #$ff
    dec gravity_timer
    bne end_update_gravity_timer
    lda #0
    sta check_for_rock_direction_offsets+2
end_update_gravity_timer
    ; update magic wall timer
    lda magic_wall_state                                                                ; 27af: a5 50       .P
    cmp #$1d                                                                            ; 27b1: c9 1d       ..
    bne update_death_explosion                                                          ; 27b3: d0 02       ..
    dec magic_wall_timer                                                                ; 27b5: c6 51       .Q
update_death_explosion
    ldx rockford_explosion_cell_type                                                    ; 27b7: a6 5f       ._
    beq check_for_escape_key_pressed_to_die                                             ; 27b9: f0 0d       ..
    inx                                                                                 ; 27bb: e8          .
    stx rockford_explosion_cell_type                                                    ; 27bc: 86 5f       ._
    cpx #$4b                                                                            ; 27be: e0 4b       .K
    bmi check_for_escape_key_pressed_to_die                                             ; 27c0: 30 06       0.
    ; if key is pressed at end of the death explosion sequence, then return
    lda keys_to_process                                                                 ; 27c2: a5 62       .b
    bne return5                                                                         ; 27c4: d0 29       .)
    dec rockford_explosion_cell_type                                                    ; 27c6: c6 5f       ._
    ; branch if escape not pressed
check_for_escape_key_pressed_to_die
    lda keys_to_process                                                                 ; 27c8: a5 62       .b
    lsr                                                                                 ; 27ca: 4a          J
    bcc check_if_pause_is_available                                                     ; 27cb: 90 08       ..
    ; branch if explosion already underway
    lda rockford_explosion_cell_type                                                    ; 27cd: a5 5f       ._
    bne check_if_pause_is_available                                                     ; 27cf: d0 04       ..
    ; start death explosion
    lda #map_start_large_explosion                                                      ; 27d1: a9 46       .F
    sta rockford_explosion_cell_type                                                    ; 27d3: 85 5f       ._
    ; branch if on a bonus stage (no pause available)
check_if_pause_is_available
    lda cave_number                                                                     ; 27d5: a5 87       ..
    cmp #16                                                                             ; 27d7: c9 10       ..
    bpl gameplay_loop_local                                                             ; 27d9: 10 11       ..
    ; check for up, down, and right keys pressed together. If all pressed, don't check
    ; for SPACE BAR for pause [is this protection against ghost key matrix presses?]
    lda previous_direction_keys                                                         ; 27db: a5 5d       .]
    and #$b0                                                                            ; 27dd: 29 b0       ).
    eor #$b0                                                                            ; 27df: 49 b0       I.
    beq gameplay_loop_local                                                             ; 27e1: f0 09       ..
    ; check if pause pressed
    lda keys_to_process                                                                 ; 27e3: a5 62       .b
    and #2                                                                              ; 27e5: 29 02       ).
    beq gameplay_loop_local                                                             ; 27e7: f0 03       ..
    jsr update_with_gameplay_not_active                                                 ; 27e9: 20 40 30     @0
gameplay_loop_local
    jmp gameplay_loop                                                                   ; 27ec: 4c 0a 27    L.'

return5
    rts                                                                                 ; 27ef: 60          `

; *************************************************************************************
update_grid_animations
    ldx #$0e                                                                            ; 2800: a2 0e       ..
    stx cell_current                                                                    ; 2802: 86 77       .w
update_sprites_to_use_loop
    ldy cell_types_that_always_animate,x                                                ; 2804: bc 50 21    .P!
    ldx cell_type_to_sprite,y                                                           ; 2807: be 80 1f    ...
    ; look up the next sprite in the animation sequence
    lda sprite_to_next_sprite,x                                                         ; 280a: bd 00 1f    ...
    sta cell_type_to_sprite,y                                                           ; 280d: 99 80 1f    ...
    dec cell_current                                                                    ; 2810: c6 77       .w
    ldx cell_current                                                                    ; 2812: a6 77       .w
    bpl update_sprites_to_use_loop                                                      ; 2814: 10 ee       ..

    ; use the tick counter (bottom two bits scaled up by 16) to update amoeba animation (and apply to slime as well)
    lda tick_counter                                                                    ; 2816: a5 5a       .Z
    and #3                                                                              ; 2818: 29 03       ).
    asl                                                                                 ; 281a: 0a          .
    asl                                                                                 ; 281b: 0a          .
    asl                                                                                 ; 281c: 0a          .
    asl                                                                                 ; 281d: 0a          .
    tax                                                                                 ; 281e: aa          .
    lda amoeba_animated_sprite0,x                                                       ; 281f: bd 87 1f    ...
    eor #1                                                                              ; 2822: 49 01       I.
    sta amoeba_animated_sprite0,x                                                       ; 2824: 9d 87 1f    ...
    sta slime_animated_sprite0,x                                                        ; 3
    lda amoeba_animated_sprites4,x                                                      ; 2827: bd c7 1f    ...
    eor #1                                                                              ; 282a: 49 01       I.
    sta amoeba_animated_sprites4,x                                                      ; 282c: 9d c7 1f    ...
    sta slime_animated_sprite1,x                                                        ; 3
    ; animate exit
    lda exit_cell_type                                                                  ; 282f: ad 56 21    .V!
    eor #$10                                                                            ; 2832: 49 10       I.
    sta exit_cell_type                                                                  ; 2834: 8d 56 21    .V!
    ; update rockford idle animation
    lda ticks_since_last_direction_key_pressed                                          ; 2837: a5 58       .X
    tay                                                                                 ; 2839: a8          .
    and #$3f                                                                            ; 283a: 29 3f       )?
    tax                                                                                 ; 283c: aa          .
    lda idle_animation_data,x                                                           ; 283d: bd 80 1e    ...
    ; check for nearing the end of the idle animation (range $c0-$ff).
    ; Use the top nybbles of the data if so.
    cpy #$c0                                                                            ; 2840: c0 c0       ..
    bcc extract_lower_nybble                                                            ; 2842: 90 04       ..
    ; Near the end of the idle animation. Shift the upper nybble into the bottom nybble
    ; to get more idle sprites
    lsr                                                                                 ; 2844: 4a          J
    lsr                                                                                 ; 2845: 4a          J
    lsr                                                                                 ; 2846: 4a          J
    lsr                                                                                 ; 2847: 4a          J
extract_lower_nybble
    and #$0f                                                                            ; 2848: 29 0f       ).
    ; set the rockford sprite
    ora #sprite_rockford_blinking1                                                      ; 284a: 09 20       .
    sta rockford_sprite                                                                 ; 284c: 8d 8f 1f    ...
    inc ticks_since_last_direction_key_pressed                                          ; 284f: e6 58       .X
    rts                                                                                 ; 2851: 60          `

; *************************************************************************************
read_keys_and_resolve_direction_keys
    jsr read_keys                                                                       ; 2860: 20 89 26     .&
    ; just get the direction keys (top nybble)
    lda keys_to_process                                                                 ; 2863: a5 62       .b
    and #$f0                                                                            ; 2865: 29 f0       ).
    tax                                                                                 ; 2867: aa          .
    tay                                                                                 ; 2868: a8          .
    ; look for any changes of direction. If so use the just pressed directions as input
    eor previous_direction_keys                                                         ; 2869: 45 5d       E]
    bne direction_keys_changed                                                          ; 286b: d0 05       ..
    ; no new directions were pressed, so use the previous directions from last time.
    lda just_pressed_direction_keys                                                     ; 286d: a5 5e       .^
    jmp store_active_direction_keys                                                     ; 286f: 4c 77 28    Lw(

direction_keys_changed
    and keys_to_process                                                                 ; 2872: 25 62       %b
    bne store_active_direction_keys                                                     ; 2874: d0 01       ..
    ; nothing was just pressed, so just use the currently pressed keys
    txa                                                                                 ; 2876: 8a          .
store_active_direction_keys
    tax                                                                                 ; 2877: aa          .
    stx just_pressed_direction_keys                                                     ; 2878: 86 5e       .^
    ; remember the special (non-direction keys) only
    lda keys_to_process                                                                 ; 287a: a5 62       .b
    and #$0f                                                                            ; 287c: 29 0f       ).
    sta keys_to_process                                                                 ; 287e: 85 62       .b
    ; recall the active direction keys, and combine with the special keys
    txa                                                                                 ; 2880: 8a          .
    and #$f0                                                                            ; 2881: 29 f0       ).
    ora keys_to_process                                                                 ; 2883: 05 62       .b
    sta keys_to_process                                                                 ; 2885: 85 62       .b
    sty previous_direction_keys                                                         ; 2887: 84 5d       .]
    rts                                                                                 ; 2889: 60          `

; *************************************************************************************
increment_status_bar_number
    lda regular_status_bar,y                                                            ; 2898: b9 00 32    ..2
    clc                                                                                 ; 289b: 18          .
    adc #1                                                                              ; 289c: 69 01       i.
    cmp #$3c                                                                            ; 289e: c9 3c       .<
    bmi finished_change                                                                 ; 28a0: 30 1a       0.
    lda #sprite_0                                                                       ; 28a2: a9 32       .2
    sta regular_status_bar,y                                                            ; 28a4: 99 00 32    ..2
    dey                                                                                 ; 28a7: 88          .
    bpl increment_status_bar_number                                                     ; 28a8: 10 ee       ..
decrement_status_bar_number
    lda regular_status_bar,y                                                            ; 28aa: b9 00 32    ..2
    sec                                                                                 ; 28ad: 38          8
    sbc #1                                                                              ; 28ae: e9 01       ..
    cmp #sprite_0                                                                       ; 28b0: c9 32       .2
    bpl finished_change                                                                 ; 28b2: 10 08       ..
    lda #$3b                                                                            ; 28b4: a9 3b       .;
    sta regular_status_bar,y                                                            ; 28b6: 99 00 32    ..2
    dey                                                                                 ; 28b9: 88          .
    bpl decrement_status_bar_number                                                     ; 28ba: 10 ee       ..
finished_change
    sta regular_status_bar,y                                                            ; 28bc: 99 00 32    ..2
    rts                                                                                 ; 28bf: 60          `

; *************************************************************************************
add_a_to_status_bar_number_at_y
    sty real_keys_pressed                                                               ; 28c0: 84 7c       .|
    sta amount_to_increment_status_bar                                                  ; 28c2: 85 72       .r
    cmp #0                                                                              ; 28c4: c9 00       ..
    beq finished_add                                                                    ; 28c6: f0 09       ..
increment_number_loop
    jsr increment_status_bar_number                                                     ; 28c8: 20 98 28     .(
    ldy real_keys_pressed                                                               ; 28cb: a4 7c       .|
    dec amount_to_increment_status_bar                                                  ; 28cd: c6 72       .r
    bne increment_number_loop                                                           ; 28cf: d0 f7       ..
finished_add
    ldy real_keys_pressed                                                               ; 28d1: a4 7c       .|
    rts                                                                                 ; 28d3: 60          `

; *************************************************************************************

unused13
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0

; *************************************************************************************
; Set palette using cave parameter values
;
set_palette
    ldx #1
    lda param_colours
    jsr set_palette_colour_ax

    ldx #2
    lda param_colours+1
    jsr set_palette_colour_ax

    ldx #3
    lda param_colours+2
    jsr set_palette_colour_ax
    rts

; *************************************************************************************
; Set initial palette for menu
;
set_initial_palette
    ldx #1
    lda #5                             ;Purple
    jsr set_palette_colour_ax

    ldx #2
    lda #1                             ;Red
    jsr set_palette_colour_ax

    ldx #3
    lda #7                             ;White
    jsr set_palette_colour_ax
    rts

; *************************************************************************************
increment_map_ptr
    inc ptr_low                                                                         ; 2a00: e6 8c       ..
    lda ptr_low                                                                         ; 2a02: a5 8c       ..
    and #$3f                                                                            ; 2a04: 29 3f       )?
    cmp #$28                                                                            ; 2a06: c9 28       .(
    bne return6                                                                         ; 2a08: d0 0f       ..
    lda ptr_low                                                                         ; 2a0a: a5 8c       ..
    and #$c0                                                                            ; 2a0c: 29 c0       ).
    clc                                                                                 ; 2a0e: 18          .
    adc #$40                                                                            ; 2a0f: 69 40       i@
    sta ptr_low                                                                         ; 2a11: 85 8c       ..
    bcc skip_increment_high_byte2                                                       ; 2a13: 90 02       ..
    inc ptr_high                                                                        ; 2a15: e6 8d       ..
skip_increment_high_byte2
    dec x_loop_counter                                                                  ; 2a17: c6 7c       .|
return6
    rts                                                                                 ; 2a19: 60          `

; *************************************************************************************
set_ptr_to_start_of_map
    lda #<tile_map_row_1                                                                ; 2a1a: a9 40       .@
set_ptr_high_to_start_of_map_with_offset_a
    sta ptr_low                                                                         ; 2a1c: 85 8c       ..
set_ptr_high_to_start_of_map
    lda #>tile_map_row_1                                                                ; 2a1e: a9 50       .P
    sta ptr_high                                                                        ; 2a20: 85 8d       ..
    lda #20                                                                             ; 2a22: a9 14       ..
    sta x_loop_counter                                                                  ; 2a24: 85 7c       .|
    ldy #0                                                                              ; 2a26: a0 00       ..
    rts                                                                                 ; 2a28: 60          `

; *************************************************************************************
palette_block
    !byte 0                                                                             ; 2a29: 00          .              ; logical colour
    !byte 0                                                                             ; 2a2a: 00          .              ; physical colour
    !byte 0                                                                             ; 2a2b: 00          .              ; zero
    !byte 0                                                                             ; 2a2c: 00          .              ; zero
    !byte 0                                                                             ; 2a2d: 00          .              ; zero

; *************************************************************************************
increment_next_ptr
    inc next_ptr_low                                                                    ; 2a2e: e6 82       ..
    bne return6                                                                         ; 2a30: d0 e7       ..
    inc next_ptr_high                                                                   ; 2a32: e6 83       ..
    rts                                                                                 ; 2a34: 60          `

; *************************************************************************************
set_palette_colour_ax
    sta palette_block+1                                                                 ; 2a35: 8d 2a 2a    .**
    txa                                                                                 ; 2a38: 8a          .
    pha                                                                                 ; 2a39: 48          H
    stx palette_block                                                                   ; 2a3a: 8e 29 2a    .)*
    tya                                                                                 ; 2a3d: 98          .
    pha                                                                                 ; 2a3e: 48          H
    ldx #<(palette_block)                                                               ; 2a3f: a2 29       .)
    ldy #>(palette_block)                                                               ; 2a41: a0 2a       .*
    lda #osword_write_palette                                                           ; 2a43: a9 0c       ..
    jsr osword                                                                          ; 2a45: 20 f1 ff     ..            ; Write palette
    pla                                                                                 ; 2a48: 68          h
    tay                                                                                 ; 2a49: a8          .
    pla                                                                                 ; 2a4a: 68          h
    tax                                                                                 ; 2a4b: aa          .
    rts                                                                                 ; 2a4c: 60          `

; *************************************************************************************
reset_clock
    ldy #>(initial_clock_value)                                                         ; 2a4d: a0 13       ..
    ldx #<(initial_clock_value)                                                         ; 2a4f: a2 00       ..
    lda #osword_write_clock                                                             ; 2a51: a9 02       ..
    jmp osword                                                                          ; 2a53: 4c f1 ff    L..            ; Write system clock

; *************************************************************************************
; 
; Animate the flashing spaces on the grid.
; Calculate and set palette colour 3 over a number of frames
; Also checks for awarding a bonus life.
; 
; Sequence of colours to show.
; countdown_while_changing_palette    physical colour to set
;     7                                       7 (white)
;     6                                       6 (cyan)
;     5                                       5 (magenta)
;     4                                       3 (yellow)
;     3                                       7 (white)
;     2                                       6 (cyan)
;     1                                       5 (magenta)
;     0                                       -
; 
animate_flashing_spaces_and_check_for_bonus_life
    lda countdown_while_switching_palette                                               ; 2a56: a5 59       .Y
    beq check_for_bonus_life                                                            ; 2a58: f0 1f       ..
    inc sound6_active_flag                                                              ; 2a5a: e6 4c       .L
    ldx #3                                                                              ; 2a5c: a2 03       ..
    lda countdown_while_switching_palette                                               ; 2a5e: a5 59       .Y
    and #7                                                                              ; 2a60: 29 07       ).
    ora #4                                                                              ; 2a62: 09 04       ..
    cmp #4                                                                              ; 2a64: c9 04       ..
    bne skip_setting_physical_colour_to_three                                           ; 2a66: d0 02       ..
    ; set logical colour three
    lda #3                                                                              ; 2a68: a9 03       ..
skip_setting_physical_colour_to_three
    jsr set_palette_colour_ax                                                           ; 2a6a: 20 35 2a     5*
    dec countdown_while_switching_palette                                               ; 2a6d: c6 59       .Y
    bne check_for_bonus_life                                                            ; 2a6f: d0 08       ..
    ; restore to spaces
    lda #0                                                                              ; 2a71: a9 00       ..
    sta cell_type_to_sprite                                                             ; 2a73: 8d 80 1f    ...
    jsr set_palette                                                                     ; 2a76: 20 ac 29     .)

    ; a bonus life is awarded every 500 points
check_for_bonus_life
    lda hundreds_digit_of_score_on_status_bar                                           ; 2a79: ad 11 32    ..2
    cmp #sprite_0                                                                       ; 2a7c: c9 32       .2
    beq zero_or_five_in_hundreds_column                                                 ; 2a7e: f0 09       ..
    cmp #sprite_5                                                                       ; 2a80: c9 37       .7
    beq zero_or_five_in_hundreds_column                                                 ; 2a82: f0 05       ..
    ; a bonus life only becomes possible after the score *doesn't* have a zero or five
    ; in the hundreds column
    lda #$ff                                                                            ; 2a84: a9 ff       ..
    sta bonus_life_available_flag                                                       ; 2a86: 85 6f       .o
    rts                                                                                 ; 2a88: 60          `

zero_or_five_in_hundreds_column
    ldy #17                                                                             ; 2a89: a0 11       ..
check_for_non_zero_in_top_digits
    lda regular_status_bar,y                                                            ; 2a8b: b9 00 32    ..2
    cmp #sprite_0                                                                       ; 2a8e: c9 32       .2
    bne non_zero_digit_found_in_hundreds_column_or_above                                ; 2a90: d0 0a       ..
    dey                                                                                 ; 2a92: 88          .
    cpy #13                                                                             ; 2a93: c0 0d       ..
    bne check_for_non_zero_in_top_digits                                                ; 2a95: d0 f4       ..
    ; all the top digits are zero, including the hundreds column, which means we are
    ; not 500 or more, so not eligible for a bonus life
    lda #0                                                                              ; 2a97: a9 00       ..
    sta bonus_life_available_flag                                                       ; 2a99: 85 6f       .o
    rts                                                                                 ; 2a9b: 60          `

non_zero_digit_found_in_hundreds_column_or_above
    lda bonus_life_available_flag                                                       ; 2a9c: a5 6f       .o
    beq return7                                                                         ; 2a9e: f0 14       ..
    ; award bonus life
    lda #0                                                                              ; 2aa0: a9 00       ..
    sta bonus_life_available_flag                                                       ; 2aa2: 85 6f       .o
    ; set sprite for space to pathway
    lda #sprite_pathway                                                                 ; 2aa4: a9 1f       ..
    sta cell_type_to_sprite                                                             ; 2aa6: 8d 80 1f    ...
    ; start animating colour three
    lda #7                                                                              ; 2aa9: a9 07       ..
    sta countdown_while_switching_palette                                               ; 2aab: 85 59       .Y
    ; add one to the MEN count
    inc men_number_on_regular_status_bar                                                ; 2aad: ee 1e 32    ..2
    ; show bonus life text (very briefly)
    lda #<bonus_life_text                                                               ; 2ab0: a9 64       .d
    sta status_text_address_low                                                         ; 2ab2: 85 69       .i
return7
    rts                                                                                 ; 2ab4: 60          `

; *************************************************************************************
draw_big_rockford
    lda #>big_rockford_destination_screen_address                                       ; 2ab5: a9 58       .X
    sta ptr_high                                                                        ; 2ab7: 85 8d       ..
    ldy #<big_rockford_destination_screen_address                                       ; 2ab9: a0 00       ..
    sty ptr_low                                                                         ; 2abb: 84 8c       ..
    lda #>big_rockford_sprite                                                           ; 2abd: a9 34       .4
    sta next_ptr_high                                                                   ; 2abf: 85 83       ..
    sty next_ptr_low                                                                    ; 2ac1: 84 82       ..
draw_big_rockford_loop
    ldx #1                                                                              ; 2ac3: a2 01       ..
    jsr get_next_ptr_byte                                                               ; 2ac5: 20 eb 2a     .*
    ldy #6                                                                              ; 2ac8: a0 06       ..
check_if_byte_is_an_rle_byte_loop
    cmp rle_bytes_table,y                                                               ; 2aca: d9 f8 2a    ..*
    beq get_repeat_count                                                                ; 2acd: f0 05       ..
    dey                                                                                 ; 2acf: 88          .
    bne check_if_byte_is_an_rle_byte_loop                                               ; 2ad0: d0 f8       ..
    beq copy_x_bytes_in_rle_loop                                                        ; 2ad2: f0 08       ..             ; ALWAYS branch

; *************************************************************************************
get_repeat_count
    ldy #0                                                                              ; 2ad4: a0 00       ..
    pha                                                                                 ; 2ad6: 48          H
    jsr get_next_ptr_byte                                                               ; 2ad7: 20 eb 2a     .*
    tax                                                                                 ; 2ada: aa          .
    pla                                                                                 ; 2adb: 68          h
copy_x_bytes_in_rle_loop
    sta (ptr_low),y                                                                     ; 2adc: 91 8c       ..
    inc ptr_low                                                                         ; 2ade: e6 8c       ..
    bne skip_inc_high                                                                   ; 2ae0: d0 04       ..
    inc ptr_high                                                                        ; 2ae2: e6 8d       ..
    bmi return8                                                                         ; 2ae4: 30 0d       0.
skip_inc_high
    dex                                                                                 ; 2ae6: ca          .
    bne copy_x_bytes_in_rle_loop                                                        ; 2ae7: d0 f3       ..
    beq draw_big_rockford_loop                                                          ; 2ae9: f0 d8       ..             ; ALWAYS branch

; *************************************************************************************
get_next_ptr_byte
    lda (next_ptr_low),y                                                                ; 2aeb: b1 82       ..
    inc next_ptr_low                                                                    ; 2aed: e6 82       ..
    bne return8                                                                         ; 2aef: d0 02       ..
    inc next_ptr_high                                                                   ; 2af1: e6 83       ..
return8
    rts                                                                                 ; 2af3: 60          `

rle_bytes_table
    !byte $85, $48, $10, $ec, $ff, $0f,   0                                             ; 2af8: 85 48 10... .H.

unused34
    !byte 0, 0, 0, 0, 0

; *************************************************************************************
map_address_to_map_xy_position
    lda map_address_high                                                                ; 2b00: a5 8d       ..
    and #7                                                                              ; 2b02: 29 07       ).
    sta map_y                                                                           ; 2b04: 85 8b       ..
    lda map_address_low                                                                 ; 2b06: a5 8c       ..
    asl                                                                                 ; 2b08: 0a          .
    rol map_y                                                                           ; 2b09: 26 8b       &.
    asl                                                                                 ; 2b0b: 0a          .
    rol map_y                                                                           ; 2b0c: 26 8b       &.
    lda map_address_low                                                                 ; 2b0e: a5 8c       ..
    and #$3f                                                                            ; 2b10: 29 3f       )?
    sta map_x                                                                           ; 2b12: 85 8a       ..
    rts                                                                                 ; 2b14: 60          `

; *************************************************************************************
map_xy_position_to_map_address
    lda #0                                                                              ; 2b15: a9 00       ..
    sta map_address_low                                                                 ; 2b17: 85 8c       ..
    lda map_y                                                                           ; 2b19: a5 8b       ..
    lsr                                                                                 ; 2b1b: 4a          J
    ror map_address_low                                                                 ; 2b1c: 66 8c       f.
    lsr                                                                                 ; 2b1e: 4a          J
    ror map_address_low                                                                 ; 2b1f: 66 8c       f.
    ora #$50                                                                            ; 2b21: 09 50       .P
    sta map_address_high                                                                ; 2b23: 85 8d       ..
    lda map_x                                                                           ; 2b25: a5 8a       ..
    ora map_address_low                                                                 ; 2b27: 05 8c       ..
    sta map_address_low                                                                 ; 2b29: 85 8c       ..
    rts                                                                                 ; 2b2b: 60          `

; *************************************************************************************
; Scrolls the map by setting the tile_map_ptr and visible_top_left_map_x and y
update_map_scroll_position
    lda map_rockford_current_position_addr_low                                          ; 2b2c: a5 70       .p
    sta map_address_low                                                                 ; 2b2e: 85 8c       ..
    lda map_rockford_current_position_addr_high                                         ; 2b30: a5 71       .q
    sta map_address_high                                                                ; 2b32: 85 8d       ..
    jsr map_address_to_map_xy_position                                                  ; 2b34: 20 00 2b     .+
    sec                                                                                 ; 2b37: 38          8
    sbc visible_top_left_map_x                                                          ; 2b38: e5 7e       .~
    ldx visible_top_left_map_x                                                          ; 2b3a: a6 7e       .~
    cmp #17                                                                             ; 2b3c: c9 11       ..
    bmi check_for_need_to_scroll_left                                                   ; 2b3e: 30 05       0.
    cpx #20                                                                             ; 2b40: e0 14       ..
    bpl check_for_need_to_scroll_down                                                   ; 2b42: 10 0a       ..
    inx                                                                                 ; 2b44: e8          .
check_for_need_to_scroll_left
    cmp #3                                                                              ; 2b45: c9 03       ..
    bpl check_for_need_to_scroll_down                                                   ; 2b47: 10 05       ..
    cpx #1                                                                              ; 2b49: e0 01       ..
    bmi check_for_need_to_scroll_down                                                   ; 2b4b: 30 01       0.
    dex                                                                                 ; 2b4d: ca          .
check_for_need_to_scroll_down
    ldy visible_top_left_map_y                                                          ; 2b4e: a4 7f       ..
    lda map_y                                                                           ; 2b50: a5 8b       ..
    sec                                                                                 ; 2b52: 38          8
    sbc visible_top_left_map_y                                                          ; 2b53: e5 7f       ..
    cmp #9                                                                              ; 2b55: c9 09       ..
    bmi check_for_need_to_scroll_up                                                     ; 2b57: 30 05       0.
    cpy #$0a                                                                            ; 2b59: c0 0a       ..
    bpl check_for_bonus_stages                                                          ; 2b5b: 10 0a       ..
    iny                                                                                 ; 2b5d: c8          .
check_for_need_to_scroll_up
    cmp #3                                                                              ; 2b5e: c9 03       ..
    bpl check_for_bonus_stages                                                          ; 2b60: 10 05       ..
    cpy #1                                                                              ; 2b62: c0 01       ..
    bmi check_for_bonus_stages                                                          ; 2b64: 30 01       0.
    dey                                                                                 ; 2b66: 88          .
check_for_bonus_stages
    lda cave_number                                                                     ; 2b67: a5 87       ..
    cmp #$10                                                                            ; 2b69: c9 10       ..
    bmi skip_bonus_stage                                                                ; 2b6b: 30 04       0.
    ; bonus stage is always situated in top left corner
    lda #0                                                                              ; 2b6d: a9 00       ..
    tax                                                                                 ; 2b6f: aa          .
    tay                                                                                 ; 2b70: a8          .
skip_bonus_stage
    stx visible_top_left_map_x                                                          ; 2b71: 86 7e       .~
    stx map_x                                                                           ; 2b73: 86 8a       ..
    sty visible_top_left_map_y                                                          ; 2b75: 84 7f       ..
    sty map_y                                                                           ; 2b77: 84 8b       ..
    jsr map_xy_position_to_map_address                                                  ; 2b79: 20 15 2b     .+
    lda map_address_low                                                                 ; 2b7c: a5 8c       ..
    sta tile_map_ptr_low                                                                ; 2b7e: 85 85       ..
    lda map_address_high                                                                ; 2b80: a5 8d       ..
    sta tile_map_ptr_high                                                               ; 2b82: 85 86       ..
    rts                                                                                 ; 2b84: 60          `

unused35
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

; *************************************************************************************
wait_for_13_centiseconds_and_read_keys
    lda #$0d                                                                            ; 2b90: a9 0d       ..
wait_for_a_centiseconds_and_read_keys
    sta wait_delay_centiseconds                                                         ; 2b92: 85 84       ..
wait_for_centiseconds_and_read_keys
    lda #0                                                                              ; 2b94: a9 00       ..
    sta keys_to_process                                                                 ; 2b96: 85 62       .b
wait_loop
    jsr read_keys_and_resolve_direction_keys                                            ; 2b98: 20 60 28     `(
    ldy #>(set_clock_value)                                                             ; 2b9b: a0 1e       ..
    ldx #<(set_clock_value)                                                             ; 2b9d: a2 70       .p
    lda #osword_read_clock                                                              ; 2b9f: a9 01       ..
    jsr osword                                                                          ; 2ba1: 20 f1 ff     ..            ; Read system clock
    lda set_clock_value                                                                 ; 2ba4: ad 70 1e    .p.
    cmp wait_delay_centiseconds                                                         ; 2ba7: c5 84       ..
    bmi wait_loop                                                                       ; 2ba9: 30 ed       0.
    lda keys_to_process                                                                 ; 2bab: a5 62       .b
    and #$f0                                                                            ; 2bad: 29 f0       ).
    sta keys_to_process                                                                 ; 2baf: 85 62       .b
    jsr read_keys_and_resolve_direction_keys                                            ; 2bb1: 20 60 28     `(
    jsr animate_flashing_spaces_and_check_for_bonus_life                                ; 2bb4: 20 56 2a     V*
    jsr reset_clock                                                                     ; 2bb7: 20 4d 2a     M*
    ldx #0                                                                              ; 2bba: a2 00       ..
    txa                                                                                 ; 2bbc: 8a          .
    jmp set_palette_colour_ax                                                           ; 2bbd: 4c 35 2a    L5*

; *************************************************************************************
handler_slime
;Slime element introduced in Boulder Dash 2, allows rocks and diamonds to pass through it but nothing else
;Used in Boulder Dash 2 in caves E (no pass-through delay) and M (random delay)
;The slime permeability cave parameter controls how quickly rocks and diamonds can pass through it

    lda cell_above                     ; read what's above the wall, getting the cell type from the lower nybble
    and #$0f
    tay
    lda items_allowed_through_slime,y  ; read which cell types are allowed to fall through
    beq slime_return                   ; If not the right type (rock or diamond) then end
    sta item_allowed
    lda cell_below
    bne slime_return                   ; If no space below the slime for a rock or diamond to fall then end
    lda param_slime_permeability
    beq slime_pass_through             ; If slime permeability is zero, no delay in pass through
    lda #0                             ; Otherwise continue and determine random delay
    sta random_seed1
    lda random_seed2
    bne slime_delay                    ; If random_seed2 is not zero, use it for pseudo_random calculation
    lda param_slime_permeability       ; Otherwise set random_seed2 to slime permeability value
    sta random_seed2
slime_delay
    jsr pseudo_random                  ; Call pseudo-random routine returning random_seed1 in the accumulator
    cmp #$04                           ; A suitable delay-comparison value
    bcc slime_pass_through             ; If random_seed1 is less than delay-comparison value then let the item pass through
    rts                                ; Otherwise skip the item. Next time in loop, will use the last random_seed2 value and eventually pass through
slime_pass_through
    lda #map_unprocessed | map_space   ; something will fall into the wall, clear the cell above
    sta cell_above
    lda item_allowed
    sta cell_below                     ; store the item that has fallen through the wall below
slime_return
    rts

item_allowed
    !byte 0

unused37
    !byte 0, 0, 0, 0, 0, 0, 0

; *************************************************************************************
; Sound data packed into single bytes: channel, amplitude, pitch, duration
; Sound 0 = amoeba ambient sound
; Sound 1 = Magic wall sound
; Sound 2 = Movement sound
; Sound 3 = Got earth sound
; Sound 4 = Rock landing / rockford appearing sound
; Sound 5 = Diamond landing
; Sound 6 = Got all required diamonds / rockford exploding sound
; Sound 7 = amoeba sound
in_game_sound_data
    !byte $12,   5,   8,   5                                                            ; 2c00: 12 05 08... ...
    !byte $12, $f7, $c8,   1                                                            ; 2c04: 12 f7 c8... ...
    !byte   0, $fe,   4,   1                                                            ; 2c08: 00 fe 04... ...
    !byte   0, $fb,   4,   1                                                            ; 2c0c: 00 fb 04... ...
    !byte $10,   2,   5,   7                                                            ; 2c10: 10 02 05... ...
    !byte $13,   1, $dc,   1                                                            ; 2c14: 13 01 dc... ...
    !byte $10,   4,   7, $1e                                                            ; 2c18: 10 04 07... ...
    !byte $11,   3, $ff, $28                                                            ; 2c1c: 11 03 ff... ...
    !byte $12,   1, $c8,   2                                                            ; 2c20: 12 01 c8... ...
in_game_sound_block
    !word $13                                                                           ; 2c24: 13 00       ..             ; Channel (2 bytes)
in_game_sound_amplitude
    !word 1                                                                             ; 2c26: 01 00       ..             ; Amplitude (2 bytes)
in_game_sound_pitch
    !word $8f                                                                           ; 2c28: 8f 00       ..             ; Pitch (2 bytes)
in_game_sound_duration
    !word 1                                                                             ; 2c2a: 01 00       ..             ; Duration (2 bytes)

; *************************************************************************************
; If X is negative, then play sound (X AND 127) with pitch Y.
; If X is non-negative, play sound X with default pitch.
play_sound_x_pitch_y
    txa                                                                                 ; 2c2c: 8a          .
    bmi skip_using_default_pitch1                                                       ; 2c2d: 30 02       0.
    ldy #0                                                                              ; 2c2f: a0 00       ..
skip_using_default_pitch1
    and #$7f                                                                            ; 2c31: 29 7f       ).
    tax                                                                                 ; 2c33: aa          .
    cpx #6                                                                              ; 2c34: e0 06       ..
    bne play_raw_sound_x_pitch_y                                                        ; 2c36: d0 05       ..
    ; sound 6 also plays sound 7
    jsr play_raw_sound_x_pitch_y                                                        ; 2c38: 20 3d 2c     =,
    ldx #7                                                                              ; 2c3b: a2 07       ..
play_raw_sound_x_pitch_y
    txa                                                                                 ; 2c3d: 8a          .
    asl                                                                                 ; 2c3e: 0a          .
    asl                                                                                 ; 2c3f: 0a          .
    tax                                                                                 ; 2c40: aa          .
    lda #0                                                                              ; 2c41: a9 00       ..
    sta in_game_sound_amplitude+1                                                       ; 2c43: 8d 27 2c    .',
    lda in_game_sound_data,x                                                            ; 2c46: bd 00 2c    ..,
    sta in_game_sound_block                                                             ; 2c49: 8d 24 2c    .$,
    lda in_game_sound_data+1,x                                                          ; 2c4c: bd 01 2c    ..,
    sta in_game_sound_amplitude                                                         ; 2c4f: 8d 26 2c    .&,
    bpl skip_negative_amplitude                                                         ; 2c52: 10 05       ..
    lda #$ff                                                                            ; 2c54: a9 ff       ..
    sta in_game_sound_amplitude+1                                                       ; 2c56: 8d 27 2c    .',
skip_negative_amplitude
    tya                                                                                 ; 2c59: 98          .
    bne skip_using_default_pitch2                                                       ; 2c5a: d0 03       ..
    ; use default pitch
    lda in_game_sound_data+2,x                                                          ; 2c5c: bd 02 2c    ..,
skip_using_default_pitch2
    sta in_game_sound_pitch                                                             ; 2c5f: 8d 28 2c    .(,
    lda in_game_sound_data+3,x                                                          ; 2c62: bd 03 2c    ..,
    sta in_game_sound_duration                                                          ; 2c65: 8d 2a 2c    .*,
    ldy #>(in_game_sound_block)                                                         ; 2c68: a0 2c       .,
    ldx #<(in_game_sound_block)                                                         ; 2c6a: a2 24       .$
    lda #osword_sound                                                                   ; 2c6c: a9 07       ..
    jmp osword                                                                          ; 2c6e: 4c f1 ff    L..            ; SOUND command

unused38
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0                                   ; 2c71: 00 00 00... ...

; *************************************************************************************
update_sounds
    lda sound2_active_flag                                                              ; 2c80: a5 48       .H
    eor #$41                                                                            ; 2c82: 49 41       IA
    sta sound2_active_flag                                                              ; 2c84: 85 48       .H
    lda time_remaining                                                                  ; 2c86: a5 6d       .m
    cmp #$0b                                                                            ; 2c88: c9 0b       ..
    bcs skip_playing_countdown_sounds                                                   ; 2c8a: b0 14       ..
    lda sub_second_ticks                                                                ; 2c8c: a5 5c       .\
    cmp #$0b                                                                            ; 2c8e: c9 0b       ..
    bne skip_playing_countdown_sounds                                                   ; 2c90: d0 0e       ..
    ; play rising pitch as time up is approaching
    lda #$dc                                                                            ; 2c92: a9 dc       ..
    sbc time_remaining                                                                  ; 2c94: e5 6d       .m
    sbc time_remaining                                                                  ; 2c96: e5 6d       .m
    sbc time_remaining                                                                  ; 2c98: e5 6d       .m
    tay                                                                                 ; 2c9a: a8          .
    ldx #$88                                                                            ; 2c9b: a2 88       ..
    jsr play_sound_x_pitch_y                                                            ; 2c9d: 20 2c 2c     ,,
skip_playing_countdown_sounds
    jsr get_next_random_byte                                                            ; 2ca0: 20 4a 22     J"
    and #$0c                                                                            ; 2ca3: 29 0c       ).
    sta in_game_sound_data+2                                                            ; 2ca5: 8d 02 2c    ..,
    ldx #5                                                                              ; 2ca8: a2 05       ..
    jsr play_sound_if_needed                                                            ; 2caa: 20 e8 2c     .,
    lda tick_counter                                                                    ; 2cad: a5 5a       .Z
    lsr                                                                                 ; 2caf: 4a          J
    bcc skip_sound_0                                                                    ; 2cb0: 90 05       ..
    ldx #0                                                                              ; 2cb2: a2 00       ..
    jsr play_sound_if_needed                                                            ; 2cb4: 20 e8 2c     .,
skip_sound_0
    ldx #1                                                                              ; 2cb7: a2 01       ..
    jsr play_sound_if_needed                                                            ; 2cb9: 20 e8 2c     .,
    ldx #6                                                                              ; 2cbc: a2 06       ..
    jsr play_sound_if_needed                                                            ; 2cbe: 20 e8 2c     .,
    lda sound6_active_flag                                                              ; 2cc1: a5 4c       .L
    bne return10                                                                        ; 2cc3: d0 2a       .*
    ldx #4                                                                              ; 2cc5: a2 04       ..
    jsr play_sound_if_needed                                                            ; 2cc7: 20 e8 2c     .,
    lda sound4_active_flag                                                              ; 2cca: a5 4a       .J
    bne return10                                                                        ; 2ccc: d0 21       .!
    ldy #$19                                                                            ; 2cce: a0 19       ..
    ldx #$fb                                                                            ; 2cd0: a2 fb       ..
    lda #osbyte_read_adc_or_get_buffer_status                                           ; 2cd2: a9 80       ..
    jsr osbyte                                                                          ; 2cd4: 20 f4 ff     ..            ; Read number of spaces remaining in sound channel 0 (X=251)
    cpx #$0b                                                                            ; 2cd7: e0 0b       ..             ; X is the number of spaces remaining in sound channel 0
    bmi return10                                                                        ; 2cd9: 30 14       0.
    lda sound4_active_flag                                                              ; 2cdb: a5 4a       .J
    ora sound6_active_flag                                                              ; 2cdd: 05 4c       .L
    bne return10                                                                        ; 2cdf: d0 0e       ..
    ldx #2                                                                              ; 2ce1: a2 02       ..
    jsr play_sound_if_needed                                                            ; 2ce3: 20 e8 2c     .,
    ldx #3                                                                              ; 2ce6: a2 03       ..
play_sound_if_needed
    lda sound0_active_flag,x                                                            ; 2ce8: b5 46       .F
    beq return10                                                                        ; 2cea: f0 03       ..
    jmp play_sound_x_pitch_y                                                            ; 2cec: 4c 2c 2c    L,,

return10
    rts                                                                                 ; 2cef: 60          `

unused39
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

; *************************************************************************************
play_one_life

    ; Load cave parameters and map from file
    jsr load_cave_file
    ; Set colour palette using parameters
    jsr set_palette                                                                     ; 2e00: 20 00 29     .)

    ; a bonus life only becomes possible after the score *doesn't* have a zero or five
    ; in the hundreds column
    lda #0                                                                              ; 2e03: a9 00       ..
    sta bonus_life_available_flag                                                       ; 2e05: 85 6f       .o
    sta cell_type_to_sprite                                                             ; 2e07: 8d 80 1f    ...
    ldx #<players_and_men_status_bar                                                    ; 2e0a: a2 14       ..
    lda cave_number                                                                     ; 2e0c: a5 87       ..
    cmp #16                                                                             ; 2e0e: c9 10       ..
    bmi skip_bonus_life_text                                                            ; 2e10: 30 02       0.
    ldx #<bonus_life_text                                                               ; 2e12: a2 64       .d
skip_bonus_life_text
    stx status_text_address_low                                                         ; 2e14: 86 69       .i
    ; check if we are in demo mode
    lda demo_mode_tick_count                                                            ; 2e16: a5 65       .e
    bmi skip_setting_demo_mode_text                                                     ; 2e18: 30 04       0.
    lda #<demonstration_mode_text                                                       ; 2e1a: a9 a0       ..
    sta status_text_address_low                                                         ; 2e1c: 85 69       .i
    ; initialise variables $50-$5f
skip_setting_demo_mode_text
    ldx #$0f                                                                            ; 2e1e: a2 0f       ..
initialise_variables_loop
    lda initial_values_of_variables_from_0x50,x                                         ; 2e20: bd 60 1e    .`.
    cmp #99                                                                             ; 2e23: c9 63       .c
    beq skip_setting_variable                                                           ; 2e25: f0 02       ..
    sta magic_wall_state,x                                                              ; 2e27: 95 50       .P
skip_setting_variable
    dex                                                                                 ; 2e29: ca          .
    bpl initialise_variables_loop                                                       ; 2e2a: 10 f4       ..

    ; Populate the cave map from loaded data
    jsr populate_cave_from_file
    ; Populate the cave map using the pseudo-random method, using applicable cave parameters
    jsr populate_cave_tiles_pseudo_random

    ; map complete: draw titanium wall borders
    jsr set_ptr_to_start_of_map                                                         ; 2e3c: 20 1a 2a     .*
    ; loop over all rows
    ldx #22                                                                             ; 2e3f: a2 16       ..
write_left_and_right_borders_loop
    ldy #39                                                                             ; 2e41: a0 27       .'
    ; write the right hand border
    lda #$83                                                                            ; 2e43: a9 83       ..
    sta (ptr_low),y                                                                     ; 2e45: 91 8c       ..
    dey                                                                                 ; 2e47: 88          .
hide_cells_loop
    lda (ptr_low),y                                                                     ; 2e48: b1 8c       ..
    ora #$80                                                                            ; 2e4a: 09 80       ..
    sta (ptr_low),y                                                                     ; 2e4c: 91 8c       ..
    dey                                                                                 ; 2e4e: 88          .
    bne hide_cells_loop                                                                 ; 2e4f: d0 f7       ..
    ; write the left hand border
    lda #$83                                                                            ; 2e51: a9 83       ..
    sta (ptr_low),y                                                                     ; 2e53: 91 8c       ..
    lda #$40                                                                            ; 2e55: a9 40       .@
    jsr add_a_to_ptr                                                                    ; 2e57: 20 40 22     @"
    dex                                                                                 ; 2e5a: ca          .
    bne write_left_and_right_borders_loop                                               ; 2e5b: d0 e4       ..
    ; write the top and bottom borders
    lda #$83                                                                            ; 2e5d: a9 83       ..
    ldx #39                                                                             ; 2e5f: a2 27       .'
write_top_and_bottom_borders_loop
    sta tile_map_row_0,x                                                                ; 2e61: 9d 00 50    ..P
    sta tile_map_row_21,x                                                               ; 2e64: 9d 40 55    .@U
    dex                                                                                 ; 2e67: ca          .
    bpl write_top_and_bottom_borders_loop                                               ; 2e68: 10 f7       ..
    jsr initialise_stage                                                                ; 2e6a: 20 50 2f     P/
    jsr play_screen_dissolve_effect                                                     ; 2e6d: 20 bf 2e     ..
    jsr start_gameplay                                                                  ; 2e70: 20 00 27     .'
    lda neighbour_cell_contents                                                         ; 2e73: a5 64       .d
    cmp #8                                                                              ; 2e75: c9 08       ..
    beq play_screen_dissolve_to_solid                                                   ; 2e77: f0 44       .D
    dec men_number_on_regular_status_bar                                                ; 2e79: ce 1e 32    ..2
    lda men_number_on_regular_status_bar                                                ; 2e7c: ad 1e 32    ..2
    cmp #sprite_0                                                                       ; 2e7f: c9 32       .2
    bne play_screen_dissolve_to_solid                                                   ; 2e81: d0 3a       .:
    lda player_number_on_regular_status_bar                                             ; 2e83: ad 1b 32    ..2
    sta player_number_on_game_over_text                                                 ; 2e86: 8d 9e 32    ..2
    lda #<game_over_text                                                                ; 2e89: a9 8c       ..
    sta status_text_address_low                                                         ; 2e8b: 85 69       .i
    ldx #<highscore_high_status_bar                                                     ; 2e8d: a2 50       .P
    lda player_number_on_regular_status_bar                                             ; 2e8f: ad 1b 32    ..2
    cmp #sprite_1                                                                       ; 2e92: c9 33       .3
    beq got_pointer_to_score                                                            ; 2e94: f0 02       ..
    ldx #<highscore_for_player_2                                                        ; 2e96: a2 5e       .^
got_pointer_to_score
    stx which_status_bar_address1_low                                                   ; 2e98: 8e aa 2e    ...
    stx which_status_bar_address2_low                                                   ; 2e9b: 8e b8 2e    ...
    ldx #0                                                                              ; 2e9e: a2 00       ..
    ldy #0                                                                              ; 2ea0: a0 00       ..
compare_highscores_loop
    lda score_on_regular_status_bar,x                                                   ; 2ea2: bd 0e 32    ..2
    cpy #0                                                                              ; 2ea5: c0 00       ..
    bne store_in_status_bar                                                             ; 2ea7: d0 0e       ..
compare
which_status_bar_address1_low = compare+1
    cmp highscore_high_status_bar,x                                                     ; 2ea9: dd 50 32    .P2
    bmi play_screen_dissolve_to_solid                                                   ; 2eac: 30 0f       0.
    bne store_in_status_bar                                                             ; 2eae: d0 07       ..
goto_next_digit
    inx                                                                                 ; 2eb0: e8          .
    cpx #6                                                                              ; 2eb1: e0 06       ..
    bne compare_highscores_loop                                                         ; 2eb3: d0 ed       ..
    beq play_screen_dissolve_to_solid                                                   ; 2eb5: f0 06       ..             ; ALWAYS branch

store_in_status_bar
which_status_bar_address2_low = store_in_status_bar+1
    sta highscore_high_status_bar,x                                                     ; 2eb7: 9d 50 32    .P2
    iny                                                                                 ; 2eba: c8          .
    bne goto_next_digit                                                                 ; 2ebb: d0 f3       ..

play_screen_dissolve_to_solid
    lda #$80                                                                            ; 2ebd: a9 80       ..
play_screen_dissolve_effect
    sta dissolve_to_solid_flag                                                          ; 2ebf: 85 72       .r
    lda #$21                                                                            ; 2ec1: a9 21       .!
    sta tick_counter                                                                    ; 2ec3: 85 5a       .Z
    lda cave_number                                                                     ; 2ec5: a5 87       ..
    sta cell_current                                                                    ; 2ec7: 85 77       .w
screen_dissolve_loop
    jsr reveal_or_hide_more_cells                                                       ; 2ec9: 20 b3 22     ."
    jsr draw_grid_of_sprites                                                            ; 2ecc: 20 00 23     .#
    jsr draw_status_bar                                                                 ; 2ecf: 20 25 23     %#
    lda tick_counter                                                                    ; 2ed2: a5 5a       .Z
    asl                                                                                 ; 2ed4: 0a          .
    and #$0f                                                                            ; 2ed5: 29 0f       ).
    ora #$e0                                                                            ; 2ed7: 09 e0       ..
    sta sprite_titanium_addressA                                                        ; 2ed9: 8d 07 20    ..
    sta sprite_titanium_addressB                                                        ; 2edc: 8d 60 20    .`
    dec tick_counter                                                                    ; 2edf: c6 5a       .Z
    bpl screen_dissolve_loop                                                            ; 2ee1: 10 e6       ..
    rts                                                                                 ; 2ee3: 60          `

unused45
    !byte 0, 0, 0, 0, 0, 0, 0
    !byte $60, $20, $c6, $5a, $10, $e6, $60, $28, $25, $26, $25, $28, $25, $26, $27     ; 2ee4: 60 20 c6... ` .
    !byte $28, $25, $25, $25, $26, $20, $20, $23, $24, $24, $24, $23, $20               ; 2ef3: 28 25 25... (%%

; *************************************************************************************
got_diamond_so_update_status_bar
    ldy #8                                                                              ; 2f00: a0 08       ..
    jsr increment_status_bar_number                                                     ; 2f02: 20 98 28     .(
    lda total_diamonds_on_status_bar_high_digit                                         ; 2f05: ad 03 32    ..2
    sec                                                                                 ; 2f08: 38          8
    sbc #sprite_0                                                                       ; 2f09: e9 32       .2
    ldy #$12                                                                            ; 2f0b: a0 12       ..
    jsr add_a_to_status_bar_number_at_y                                                 ; 2f0d: 20 c0 28     .(
    lda total_diamonds_on_status_bar_low_digit                                          ; 2f10: ad 04 32    ..2
    sec                                                                                 ; 2f13: 38          8
    sbc #sprite_0                                                                       ; 2f14: e9 32       .2
    iny                                                                                 ; 2f16: c8          .
    jsr add_a_to_status_bar_number_at_y                                                 ; 2f17: 20 c0 28     .(
    dec diamonds_required                                                               ; 2f1a: c6 6c       .l
    bne return12                                                                        ; 2f1c: d0 29       .)
    ;got all the diamonds
    lda #7                                                                              ; 2f1e: a9 07       ..
    ldx #0                                                                              ; 2f20: a2 00       ..
    jsr set_palette_colour_ax                                                           ; 2f22: 20 35 2a     5*
    lda #3                                                                              ; 2f25: a9 03       ..
    sta regular_status_bar                                                              ; 2f27: 8d 00 32    ..2
    sta required_diamonds_on_status_bar                                                 ; 2f2a: 8d 01 32    ..2
    ; open the exit
    ldy #0                                                                              ; 2f2d: a0 00       ..
    lda #map_active_exit                                                                ; 2f2f: a9 18       ..
    sta (map_rockford_end_position_addr_low),y                                          ; 2f31: 91 6a       .j
    ; set total diamonds to zero
    lda #sprite_0                                                                       ; 2f33: a9 32       .2
    sta total_diamonds_on_status_bar_high_digit                                         ; 2f35: 8d 03 32    ..2
    sta total_diamonds_on_status_bar_low_digit                                          ; 2f38: 8d 04 32    ..2

    ;if bombs are used, skip diamond value/extra value update
    ldy #4                                                                              ; 2f40: a0 04       ..
    lda param_bombs
    bne skip_diamond_value_change
    ; show score per diamond on status bar
    lda param_diamond_extra_value                                                       ; 2f3d: bd 14 4b    ..K
skip_diamond_value_change
    jsr add_a_to_status_bar_number_at_y                                                 ; 2f42: 20 c0 28     .(

    ; play sound 6
    inc sound6_active_flag                                                              ; 2f45: e6 4c       .L
return12
    rts                                                                                 ; 2f47: 60          `

unused46
    !byte 0, 0, 0, 0, 0, 0

; *************************************************************************************
initialise_stage
    lda #20                                                                             ; 2f50: a9 14       ..
    sta visible_top_left_map_x                                                          ; 2f52: 85 7e       .~
    lsr                                                                                 ; 2f54: 4a          J
    sta visible_top_left_map_y                                                          ; 2f55: 85 7f       ..
    ldy #$0d                                                                            ; 2f57: a0 0d       ..
empty_status_bar_loop
    lda zeroed_status_bar,y                                                             ; 2f59: b9 f0 32    ..2
    sta regular_status_bar,y                                                            ; 2f5c: 99 00 32    ..2
    dey                                                                                 ; 2f5f: 88          .
    bpl empty_status_bar_loop                                                           ; 2f60: 10 f7       ..

    ;if are bombs used, replace diamond value/extra value with number of bombs left (2 digits) and bomb sprite
    ldy #4                                                                              ; 2f67: a0 04       ..
    lda param_bombs
    sta bomb_counter
    beq keep_diamond_value_on_status
    jsr add_a_to_status_bar_number_at_y
    ldy #5
    lda #sprite_bomb1
    sta regular_status_bar,y
    jmp next_parameter    
keep_diamond_value_on_status
    lda param_diamond_value                                                             ; 2f64: bd 00 4b    ..K
    jsr add_a_to_status_bar_number_at_y                                                 ; 2f69: 20 c0 28     .(
next_parameter

    ; show cave letter on status bar
    lda cave_number                                                                                 ; 2f6c: 8a          .
    clc                                                                                 ; 2f6d: 18          .
    adc #'A'                                                                            ; 2f6e: 69 41       iA
    sta cave_letter_on_regular_status_bar                                               ; 2f70: 8d 25 32    .%2

    ; show difficulty level on status bar
    lda difficulty_level                                                                ; 2f73: a5 89       ..
    clc                                                                                 ; 2f75: 18          .
    adc #sprite_0                                                                       ; 2f76: 69 32       i2
    sta difficulty_level_on_regular_status_bar                                          ; 2f78: 8d 27 32    .'2

    ; set the delay between amoeba growth
    lda param_amoeba_magic_wall_time                                                    ; 2f7b: bd 54 4c    .TL
    sta amoeba_growth_interval                                                          ; 2f7e: 85 55       .U
    sta magic_wall_timer                                                                ; 2f80: 85 51       .Q

    ; set the gravity timer
    ldy #0
    lda param_zero_gravity_time
    beq dont_allow_rock_push_up
    ldy #$ee  ;Special value used to detect rock has been pushed up, only applies when gravity is off
dont_allow_rock_push_up
    sta gravity_timer
    sty check_for_rock_direction_offsets+2

    ; initialise random seed for possible use with slime permeability
    lda #0
    sta random_seed2

    ; put the end tile on the map
    lda param_rockford_end                                                              ; 2f82: bd 18 4c    ..L
    sta map_y                                                                           ; 2f85: 85 8b       ..
    lda param_rockford_end+1                                                            ; 2f87: bd 2c 4c    .,L
    sta map_x                                                                           ; 2f8a: 85 8a       ..
    jsr map_xy_position_to_map_address                                                  ; 2f8c: 20 15 2b     .+
    ldy #0                                                                              ; 2f8f: a0 00       ..
    lda #3                                                                              ; 2f91: a9 03       ..
    sta (map_address_low),y                                                             ; 2f93: 91 8c       ..
    lda map_address_low                                                                 ; 2f95: a5 8c       ..
    sta map_rockford_end_position_addr_low                                              ; 2f97: 85 6a       .j
    lda map_address_high                                                                ; 2f99: a5 8d       ..
    sta map_rockford_end_position_addr_high                                             ; 2f9b: 85 6b       .k

    ; put the start tile on the map
    lda param_rockford_start                                                            ; 2f9d: bd f0 4b    ..K
    sta map_y                                                                           ; 2fa0: 85 8b       ..
    lda param_rockford_start+1                                                          ; 2fa2: bd 04 4c    ..L
    sta map_x                                                                           ; 2fa5: 85 8a       ..
    jsr map_xy_position_to_map_address                                                  ; 2fa7: 20 15 2b     .+
    ldy #0                                                                              ; 2faa: a0 00       ..
    lda #8                                                                              ; 2fac: a9 08       ..
    sta (map_address_low),y                                                             ; 2fae: 91 8c       ..
    lda map_address_low                                                                 ; 2fb0: a5 8c       ..
    sta map_rockford_current_position_addr_low                                          ; 2fb2: 85 70       .p
    lda map_address_high                                                                ; 2fb4: a5 8d       ..
    sta map_rockford_current_position_addr_high                                         ; 2fb6: 85 71       .q

    ; set and show diamonds required on status bar
    ldx difficulty_level
    dex
    lda param_diamonds_required,x                                                       ; 2fc6: bd 28 4b    .(K
    sta diamonds_required                                                               ; 2fc9: 85 6c       .l
    ldy #1                                                                              ; 2fcb: a0 01       ..
    jsr add_a_to_status_bar_number_at_y                                                 ; 2fcd: 20 c0 28     .(

    ; set and show time remaining on status bar
    lda param_cave_time,x                                                               ; 2fd0: bd 3c 4b    .<K
    sta time_remaining                                                                  ; 2fd3: 85 6d       .m
    ldy #$0c                                                                            ; 2fd5: a0 0c       ..
    jsr add_a_to_status_bar_number_at_y                                                 ; 2fd7: 20 c0 28     .(

    ; return zero
    lda #0                                                                              ; 2fda: a9 00       ..
    rts                                                                                 ; 2fdc: 60          `

unused47
    !byte 0, 0, 0, 0, 0, 0, 0

; *************************************************************************************
update_amoeba_timing
    lda number_of_amoeba_cells_found                                                    ; 3000: a5 56       .V
    beq check_for_amoeba_timeout                                                        ; 3002: f0 14       ..
    sta sound0_active_flag                                                              ; 3004: 85 46       .F
    ldy current_amoeba_cell_type                                                        ; 3006: a4 60       .`
    bne found_amoeba                                                                    ; 3008: d0 06       ..
    inc sound7_active_flag                                                              ; 300a: e6 4d       .M
    ldx #(map_unprocessed | map_anim_state1) | map_wall                                 ; 300c: a2 92       ..
    bne amoeba_replacement_found                                                        ; 300e: d0 06       ..             ; ALWAYS branch

found_amoeba
    adc #$38                                                                            ; 3010: 69 38       i8
    bcc check_for_amoeba_timeout                                                        ; 3012: 90 04       ..
    ; towards the end of the level time the amoeba turns into rock
    ldx #map_unprocessed | map_rock                                                     ; 3014: a2 85       ..
amoeba_replacement_found
    stx amoeba_replacement                                                              ; 3016: 86 54       .T
check_for_amoeba_timeout
    lda time_remaining                                                                  ; 3018: a5 6d       .m
    cmp #50                                                                             ; 301a: c9 32       .2
    bne return13                                                                        ; 301c: d0 0d       ..
    lda sub_second_ticks                                                                ; 301e: a5 5c       .\
    cmp #7                                                                              ; 3020: c9 07       ..
    bne return13                                                                        ; 3022: d0 07       ..
    lda #1                                                                              ; 3024: a9 01       ..
    sta amoeba_growth_interval                                                          ; 3026: 85 55       .U
    ; Set A=0 and zero the amoeba counter
    lsr                                                                                 ; 3028: 4a          J
    sta amoeba_counter                                                                  ; 3029: 85 57       .W
return13
    rts                                                                                 ; 302b: 60          `

unused48
    !byte $85, $57, $60, $1c, $1f, $1f, $1f, $1f, $1f, $1f, $1f, $1f, $1f, $1f, $1f     ; 302c: 85 57 60... .W`
    !byte $1f, $1f, $1f, $1f, $1f                                                       ; 303b: 1f 1f 1f... ...

; *************************************************************************************
; 
; update while paused, or out of time, or at end position (i.e. when gameplay started
; but is not currently active)
; 
; *************************************************************************************
    ; check for pause key
update_with_gameplay_not_active
    lda keys_to_process                                                                 ; 3040: a5 62       .b
    and #2                                                                              ; 3042: 29 02       ).
    beq check_if_end_position_reached                                                   ; 3044: f0 26       .&
    ; pause mode. show pause message.
    lda #<pause_message                                                                 ; 3046: a9 c8       ..
    sta status_text_address_low                                                         ; 3048: 85 69       .i
    lda #0                                                                              ; 304a: a9 00       ..
    sta pause_counter                                                                   ; 304c: 85 4e       .N
update_while_initially_pressing_pause_loop
    jsr update_during_pause_mode                                                        ; 304e: 20 dd 30     .0
    bne update_while_initially_pressing_pause_loop                                      ; 3051: d0 fb       ..
pause_loop
    inc pause_counter                                                                   ; 3053: e6 4e       .N
    ldx #<pause_message                                                                 ; 3055: a2 c8       ..
    ; toggle between showing pause message and regular status bar every 16 ticks
    lda pause_counter                                                                   ; 3057: a5 4e       .N
    and #$10                                                                            ; 3059: 29 10       ).
    beq skip_showing_players_and_men                                                    ; 305b: f0 02       ..
    ldx #<players_and_men_status_bar                                                    ; 305d: a2 14       ..
skip_showing_players_and_men
    stx status_text_address_low                                                         ; 305f: 86 69       .i
    jsr update_during_pause_or_out_of_time                                              ; 3061: 20 cf 30     .0
    beq pause_loop                                                                      ; 3064: f0 ed       ..
update_while_finally_pressing_unpause_loop
    jsr update_during_pause_mode                                                        ; 3066: 20 dd 30     .0
    bne update_while_finally_pressing_unpause_loop                                      ; 3069: d0 fb       ..
    rts                                                                                 ; 306b: 60          `

check_if_end_position_reached
    lda neighbour_cell_contents                                                         ; 306c: a5 64       .d
    ; check if end position has been reached
    cmp #map_rockford_appearing_or_end_position                                         ; 306e: c9 08       ..
    beq rockford_reached_end_position                                                   ; 3070: f0 12       ..
    ; show out of time message for a while, then return
    lda #$0e                                                                            ; 3072: a9 0e       ..
    sta out_of_time_message_countdown                                                   ; 3074: 85 74       .t
    lda #<out_of_time_message                                                           ; 3076: a9 b4       ..
    sta status_text_address_low                                                         ; 3078: 85 69       .i
out_of_time_loop
    jsr update_during_pause_or_out_of_time                                              ; 307a: 20 cf 30     .0
    bne return14                                                                        ; 307d: d0 5d       .]
    dec out_of_time_message_countdown                                                   ; 307f: c6 74       .t
    bne out_of_time_loop                                                                ; 3081: d0 f7       ..
    rts                                                                                 ; 3083: 60          `

    ; clear rockford's final position, and set rockford on end position
rockford_reached_end_position
    ldy #0                                                                              ; 3084: a0 00       ..
    lda (map_rockford_current_position_addr_low),y                                      ; 3086: b1 70       .p
    and #$7f                                                                            ; 3088: 29 7f       ).
    tax                                                                                 ; 308a: aa          .
    tya                                                                                 ; 308b: 98          .
    sta (map_rockford_current_position_addr_low),y                                      ; 308c: 91 70       .p
    txa                                                                                 ; 308e: 8a          .
    sta (map_rockford_end_position_addr_low),y                                          ; 308f: 91 6a       .j
    jsr draw_grid_of_sprites                                                            ; 3091: 20 00 23     .#
    lda time_remaining                                                                  ; 3094: a5 6d       .m
    beq skip_bonus                                                                      ; 3096: f0 33       .3
count_up_bonus_at_end_of_stage_loop
    ldy #$13                                                                            ; 3098: a0 13       ..
    jsr increment_status_bar_number                                                     ; 309a: 20 98 28     .(
    ldy #$0c                                                                            ; 309d: a0 0c       ..
    jsr decrement_status_bar_number                                                     ; 309f: 20 aa 28     .(
    ldx #5                                                                              ; 30a2: a2 05       ..
    stx sound5_active_flag                                                              ; 30a4: 86 4b       .K
    lda #0                                                                              ; 30a6: a9 00       ..
    sta sound6_active_flag                                                              ; 30a8: 85 4c       .L
    sta status_text_address_low                                                         ; 30aa: 85 69       .i
    lda time_remaining                                                                  ; 30ac: a5 6d       .m
    and #$1c                                                                            ; 30ae: 29 1c       ).
    tay                                                                                 ; 30b0: a8          .
    iny                                                                                 ; 30b1: c8          .
    ldx #$88                                                                            ; 30b2: a2 88       ..
    jsr play_sound_x_pitch_y                                                            ; 30b4: 20 2c 2c     ,,
    jsr animate_flashing_spaces_and_check_for_bonus_life                                ; 30b7: 20 56 2a     V*
    jsr draw_grid_of_sprites                                                            ; 30ba: 20 00 23     .#
    jsr draw_status_bar                                                                 ; 30bd: 20 25 23     %#
    lda #2                                                                              ; 30c0: a9 02       ..
    sta wait_delay_centiseconds                                                         ; 30c2: 85 84       ..
    jsr wait_for_centiseconds_and_read_keys                                             ; 30c4: 20 94 2b     .+
    dec time_remaining                                                                  ; 30c7: c6 6d       .m
    bne count_up_bonus_at_end_of_stage_loop                                             ; 30c9: d0 cd       ..
skip_bonus
    lda #<regular_status_bar                                                            ; 30cb: a9 00       ..
    sta status_text_address_low                                                         ; 30cd: 85 69       .i
update_during_pause_or_out_of_time
    jsr draw_grid_of_sprites                                                            ; 30cf: 20 00 23     .#
    jsr draw_status_bar                                                                 ; 30d2: 20 25 23     %#
    jsr wait_for_13_centiseconds_and_read_keys                                          ; 30d5: 20 90 2b     .+
    lda keys_to_process                                                                 ; 30d8: a5 62       .b
    and #2                                                                              ; 30da: 29 02       ).
return14
    rts                                                                                 ; 30dc: 60          `

; *************************************************************************************
update_during_pause_mode
    jsr draw_status_bar                                                                 ; 30dd: 20 25 23     %#
    lda #0                                                                              ; 30e0: a9 00       ..
    sta wait_delay_centiseconds                                                         ; 30e2: 85 84       ..
    jsr wait_for_centiseconds_and_read_keys                                             ; 30e4: 20 94 2b     .+
    ; check for pause key
    lda keys_to_process                                                                 ; 30e7: a5 62       .b
    and #2                                                                              ; 30e9: 29 02       ).
    rts                                                                                 ; 30eb: 60          `

unused49
    !byte $62, $29,   2, $60,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0     ; 30ec: 62 29 02... b).
    !byte   0,   0,   0,   0,   0                                                       ; 30fb: 00 00 00... ...

; *************************************************************************************
demonstration_keys
    !byte   0,   0,   8,   0, $10, $80,   0, $20,   0, $10, $80, $20, $40,   0, $80     ; 3100: 00 00 08... ...
    !byte $10, $80,   0, $40,   0, $80, $20, $80,   0, $10,   0, $40,   0, $10, $80     ; 310f: 10 80 00... ...
    !byte   0, $10, $80,   0, $10,   0, $40, $10, $40,   0, $10, $40,   0, $20, $80     ; 311e: 00 10 80... ...
    !byte $10,   0, $20, $40, $10, $40, $20, $40, $10, $40, $20, $40, $20, $40, $10     ; 312d: 10 00 20... ..
    !byte $40, $10,   0,   8, $88,   8, $10,   0, $80,   0, $10, $40,   0, $80, $20     ; 313c: 40 10 00... @..
    !byte $80, $20,   0, $80, $10, $80, $20, $80,   0, $10, $80,   0, $20, $80,   0     ; 314b: 80 20 00... . .
    !byte $10,   0, $80, $ff, $ff, $ff                                                  ; 315a: 10 00 80... ...
demonstration_key_durations
    !byte $14, $22,   2, $12,   1,   7,   2,   2,   6,   1, $0b,   1,   2,   2,   5     ; 3160: 14 22 02... .".
    !byte   4,   2,   6,   2,   1,   3,   3, $0b,   5,   2,   5,   2,   5,   3,   2     ; 316f: 04 02 06... ...
    !byte   7,   3,   3,   4,   1,   3,   3,   1,   4,   5,   2,   3,   6,   2,   3     ; 317e: 07 03 03... ...
    !byte   2,   1,   2,   3,   1,   2,   4,   5,   4,   3,   2,   8,   2,   9,   1     ; 318d: 02 01 02... ...
    !byte   2,   4,   3,   1,   2,   3,   2,   1,   2,   1,   5,   2,   1,   5,   4     ; 319c: 02 04 03... ...
    !byte   5,   2,   5,   6,   5,   5,   3,   6, $10,   3,   5, $0c,   4,   3, $1f     ; 31ab: 05 02 05... ...
    !byte   1, $14, $64, $ff, $ff, $ff                                                  ; 31ba: 01 14 64... ..d

; *************************************************************************************
; 
; Entry point
; 
; *************************************************************************************
    ; copy 256 bytes which is the credits text into a different location. Since both
    ; source and destination are within the bounds of this file, there is no reason why
    ; this couldn't just be loaded in the correct location to start with.
entry_point
    ldx #0                                                                              ; 31c0: a2 00       ..
copy_credits_loop
    lda tile_map_row_16,x                                                               ; 31c2: bd 00 54    ..T
    sta copy_of_credits,x                                                               ; 31c5: 9d 00 33    ..3
    dex                                                                                 ; 31c8: ca          .
    bne copy_credits_loop                                                               ; 31c9: d0 f7       ..
main_menu_loop
    lda #>regular_status_bar                                                            ; 31cb: a9 32       .2
    sta status_text_address_high                                                        ; 31cd: 8d 3c 23    .<#
    jsr show_menu                                                                       ; 31d0: 20 00 3a     .:
    ; show credits
    ; increment to point to credits text at $3300
    inc status_text_address_high                                                        ; 31d3: ee 3c 23    .<#
    lda #<regular_status_bar                                                            ; 31d6: a9 00       ..
    sta status_text_address_low                                                         ; 31d8: 85 69       .i
show_credits_loop
    jsr draw_status_bar                                                                 ; 31da: 20 25 23     %#
    jsr wait_for_13_centiseconds_and_read_keys                                          ; 31dd: 20 90 2b     .+
    inc status_text_address_low                                                         ; 31e0: e6 69       .i
    bne show_credits_loop                                                               ; 31e2: d0 f6       ..
    jmp main_menu_loop                                                                  ; 31e4: 4c cb 31    L.1

unused50
    !byte $31, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff     ; 31e7: 31 ff ff... 1..
    !byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff                              ; 31f6: ff ff ff... ...

; *************************************************************************************
regular_status_bar
    !byte sprite_4                                                                      ; 3200: 36          6
required_diamonds_on_status_bar
    !byte sprite_2                                                                      ; 3201: 34          4
    !byte sprite_diamond1                                                               ; 3202: 03          .
total_diamonds_on_status_bar_high_digit
    !byte sprite_1                                                                      ; 3203: 33          3
total_diamonds_on_status_bar_low_digit
    !byte sprite_0                                                                      ; 3204: 32          2
    !byte sprite_space                                                                  ; 3205: 00          .
    !byte sprite_0                                                                      ; 3206: 32          2
    !byte sprite_0                                                                      ; 3207: 32          2
    !byte sprite_0                                                                      ; 3208: 32          2
    !byte sprite_space                                                                  ; 3209: 00          .
    !byte sprite_1                                                                      ; 320a: 33          3
    !byte sprite_3                                                                      ; 320b: 35          5
    !byte sprite_3                                                                      ; 320c: 35          5
    !byte sprite_space                                                                  ; 320d: 00          .
score_on_regular_status_bar
    !byte sprite_0                                                                      ; 320e: 32          2
    !byte sprite_0                                                                      ; 320f: 32          2
    !byte sprite_7                                                                      ; 3210: 39          9
hundreds_digit_of_score_on_status_bar
    !byte sprite_9                                                                      ; 3211: 3b          ;
    !byte sprite_7                                                                      ; 3212: 39          9
    !byte sprite_8                                                                      ; 3213: 3a          :

; *************************************************************************************
players_and_men_status_bar
    !text "PLAYER"                                                                      ; 3214: 50 4c 41... PLA
    !byte sprite_space                                                                  ; 321a: 00          .
player_number_on_regular_status_bar
    !byte sprite_1                                                                      ; 321b: 33          3
    !byte sprite_comma                                                                  ; 321c: 3f          ?
    !byte sprite_space                                                                  ; 321d: 00          .
men_number_on_regular_status_bar
    !byte sprite_0                                                                      ; 321e: 32          2
    !byte sprite_space                                                                  ; 321f: 00          .
    !text "MEN"                                                                         ; 3220: 4d 45 4e    MEN
    !byte sprite_space                                                                  ; 3223: 00          .
    !byte sprite_space                                                                  ; 3224: 00          .
cave_letter_on_regular_status_bar
    !text "N"                                                                           ; 3225: 4e          N
    !byte sprite_slash                                                                  ; 3226: 3e          >
difficulty_level_on_regular_status_bar
    !byte sprite_4                                                                      ; 3227: 36          6

; *************************************************************************************
inactive_players_regular_status_bar
    !byte sprite_6                                                                      ; 3228: 38          8
    !byte sprite_0                                                                      ; 3229: 32          2
    !byte sprite_diamond1                                                               ; 322a: 03          .
    !byte sprite_0                                                                      ; 322b: 32          2
    !byte sprite_5                                                                      ; 322c: 37          7
    !byte sprite_space                                                                  ; 322d: 00          .
    !byte sprite_0                                                                      ; 322e: 32          2
    !byte sprite_0                                                                      ; 322f: 32          2
    !byte sprite_0                                                                      ; 3230: 32          2
    !byte sprite_space                                                                  ; 3231: 00          .
    !byte sprite_1                                                                      ; 3232: 33          3
    !byte sprite_5                                                                      ; 3233: 37          7
    !byte sprite_0                                                                      ; 3234: 32          2
    !byte sprite_space                                                                  ; 3235: 00          .
score_on_inactive_players_regular_status_bar
    !byte sprite_0                                                                      ; 3236: 32          2
    !byte sprite_0                                                                      ; 3237: 32          2
    !byte sprite_0                                                                      ; 3238: 32          2
    !byte sprite_0                                                                      ; 3239: 32          2
    !byte sprite_0                                                                      ; 323a: 32          2
    !byte sprite_0                                                                      ; 323b: 32          2

; *************************************************************************************
inactive_players_and_men_status_bar
    !text "PLAYER"                                                                      ; 323c: 50 4c 41... PLA
    !byte sprite_space                                                                  ; 3242: 00          .
player_number_on_inactive_players_and_men_status_bar
    !byte sprite_2                                                                      ; 3243: 34          4
    !byte sprite_comma                                                                  ; 3244: 3f          ?
    !byte sprite_space                                                                  ; 3245: 00          .
number_of_men_on_inactive_players_and_men_status_bar
    !byte sprite_0                                                                      ; 3246: 32          2
    !byte sprite_space                                                                  ; 3247: 00          .
    !text "MEN"                                                                         ; 3248: 4d 45 4e    MEN
    !byte sprite_space                                                                  ; 324b: 00          .
    !byte sprite_space                                                                  ; 324c: 00          .
cave_letter_on_inactive_players_and_men_status_bar
    !byte 'B'                                                                           ; 324d: 42          B
    !byte sprite_slash                                                                  ; 324e: 3e          >
difficulty_level_on_inactive_players_and_men_status_bar
    !byte sprite_4                                                                      ; 324f: 36          6

; *************************************************************************************
highscore_high_status_bar
    !byte sprite_0                                                                      ; 3250: 32          2
    !byte sprite_0                                                                      ; 3251: 32          2
    !byte sprite_0                                                                      ; 3252: 32          2
    !byte sprite_0                                                                      ; 3253: 32          2
    !byte sprite_0                                                                      ; 3254: 32          2
    !byte sprite_0                                                                      ; 3255: 32          2
    !byte sprite_space                                                                  ; 3256: 00          .
    !byte sprite_space                                                                  ; 3257: 00          .
    !text "HIGH"                                                                        ; 3258: 48 49 47... HIG
    !byte sprite_space                                                                  ; 325c: 00          .
    !byte sprite_space                                                                  ; 325d: 00          .
highscore_for_player_2
    !byte sprite_0                                                                      ; 325e: 32          2
    !byte sprite_0                                                                      ; 325f: 32          2
    !byte sprite_0                                                                      ; 3260: 32          2
    !byte sprite_0                                                                      ; 3261: 32          2
    !byte sprite_0                                                                      ; 3262: 32          2
    !byte sprite_0                                                                      ; 3263: 32          2

; *************************************************************************************
bonus_life_text
    !text "B"                                                                           ; 3264: 42          B
    !byte sprite_space                                                                  ; 3265: 00          .
    !text "O"                                                                           ; 3266: 4f          O
    !byte sprite_space                                                                  ; 3267: 00          .
    !text "N"                                                                           ; 3268: 4e          N
    !byte sprite_space                                                                  ; 3269: 00          .
    !text "U"                                                                           ; 326a: 55          U
    !byte sprite_space                                                                  ; 326b: 00          .
    !text "S"                                                                           ; 326c: 53          S
    !byte sprite_space                                                                  ; 326d: 00          .
    !byte sprite_space                                                                  ; 326e: 00          .
    !byte sprite_space                                                                  ; 326f: 00          .
    !byte sprite_space                                                                  ; 3270: 00          .
    !text "L"                                                                           ; 3271: 4c          L
    !byte sprite_space                                                                  ; 3272: 00          .
    !text "I"                                                                           ; 3273: 49          I
    !byte sprite_space                                                                  ; 3274: 00          .
    !text "F"                                                                           ; 3275: 46          F
    !byte sprite_space                                                                  ; 3276: 00          .
    !text "E"                                                                           ; 3277: 45          E

; *************************************************************************************
number_of_players_status_bar
    !byte sprite_1                                                                      ; 3278: 33          3
    !byte sprite_space                                                                  ; 3279: 00          .
    !text "PLAYER"                                                                      ; 327a: 50 4c 41... PLA
plural_for_player
    !byte sprite_space                                                                  ; 3280: 00          .
    !byte sprite_space                                                                  ; 3281: 00          .
    !byte sprite_space                                                                  ; 3282: 00          .
    !byte sprite_space                                                                  ; 3283: 00          .
    !text "CAVE="                                                                       ; 3284: 43 41 56... CAV
cave_letter
    !text "A"                                                                           ; 3289: 41          A
    !byte sprite_slash                                                                  ; 328a: 3e          >
number_of_players_status_bar_difficulty_level
    !byte sprite_1                                                                      ; 328b: 33          3

; *************************************************************************************
game_over_text
    !byte sprite_space                                                                  ; 328c: 00          .
    !text "GAME"                                                                        ; 328d: 47 41 4d... GAM
    !byte sprite_space                                                                  ; 3291: 00          .
    !text "OVER"                                                                        ; 3292: 4f 56 45... OVE
    !byte sprite_space                                                                  ; 3296: 00          .
    !text "PLAYER"                                                                      ; 3297: 50 4c 41... PLA
    !byte sprite_space                                                                  ; 329d: 00          .
player_number_on_game_over_text
    !byte sprite_1                                                                      ; 329e: 33          3
    !byte sprite_space                                                                  ; 329f: 00          .

; *************************************************************************************
demonstration_mode_text
    !byte sprite_space                                                                  ; 32a0: 00          .
    !text "DEMONSTRATION"                                                               ; 32a1: 44 45 4d... DEM
    !byte sprite_space                                                                  ; 32ae: 00          .
    !text "MODE"                                                                        ; 32af: 4d 4f 44... MOD
    !byte sprite_space                                                                  ; 32b3: 00          .

; *************************************************************************************
out_of_time_message
    !text "O"                                                                           ; 32b4: 4f          O
    !byte sprite_space                                                                  ; 32b5: 00          .
    !text "U"                                                                           ; 32b6: 55          U
    !byte sprite_space                                                                  ; 32b7: 00          .
    !text "T"                                                                           ; 32b8: 54          T
    !byte sprite_space                                                                  ; 32b9: 00          .
    !byte sprite_space                                                                  ; 32ba: 00          .
    !text "O"                                                                           ; 32bb: 4f          O
    !byte sprite_space                                                                  ; 32bc: 00          .
    !text "F"                                                                           ; 32bd: 46          F
    !byte sprite_space                                                                  ; 32be: 00          .
    !byte sprite_space                                                                  ; 32bf: 00          .
    !byte sprite_space                                                                  ; 32c0: 00          .
    !text "T"                                                                           ; 32c1: 54          T
    !byte sprite_space                                                                  ; 32c2: 00          .
    !text "I"                                                                           ; 32c3: 49          I
    !byte sprite_space                                                                  ; 32c4: 00          .
    !text "M"                                                                           ; 32c5: 4d          M
    !byte sprite_space                                                                  ; 32c6: 00          .
    !text "E"                                                                           ; 32c7: 45          E

; *************************************************************************************
pause_message
    !text "HIT"                                                                         ; 32c8: 48 49 54    HIT
    !byte sprite_space                                                                  ; 32cb: 00          .
    !text "SPACE"                                                                       ; 32cc: 53 50 41... SPA
    !byte sprite_space                                                                  ; 32d1: 00          .
    !byte sprite_space                                                                  ; 32d2: 00          .
    !text "TO"                                                                          ; 32d3: 54 4f       TO
    !byte sprite_space                                                                  ; 32d5: 00          .
    !text "RESUME"                                                                      ; 32d6: 52 45 53... RES

; *************************************************************************************
score_last_status_bar
    !byte sprite_0                                                                      ; 32dc: 32          2
    !byte sprite_0                                                                      ; 32dd: 32          2
    !byte sprite_0                                                                      ; 32de: 32          2
    !byte sprite_0                                                                      ; 32df: 32          2
    !byte sprite_0                                                                      ; 32e0: 32          2
    !byte sprite_0                                                                      ; 32e1: 32          2
    !byte sprite_space                                                                  ; 32e2: 00          .
    !byte sprite_space                                                                  ; 32e3: 00          .
    !text "LAST"                                                                        ; 32e4: 4c 41 53... LAS
    !byte sprite_space                                                                  ; 32e8: 00          .
    !byte sprite_space                                                                  ; 32e9: 00          .
    !byte sprite_0                                                                      ; 32ea: 32          2
    !byte sprite_0                                                                      ; 32eb: 32          2
    !byte sprite_0                                                                      ; 32ec: 32          2
    !byte sprite_0                                                                      ; 32ed: 32          2
    !byte sprite_0                                                                      ; 32ee: 32          2
    !byte sprite_0                                                                      ; 32ef: 32          2

; *************************************************************************************
zeroed_status_bar
    !byte sprite_0                                                                      ; 32f0: 32          2
    !byte sprite_0                                                                      ; 32f1: 32          2
    !byte sprite_diamond1                                                               ; 32f2: 03          .
    !byte sprite_0                                                                      ; 32f3: 32          2
    !byte sprite_0                                                                      ; 32f4: 32          2
    !byte sprite_space                                                                  ; 32f5: 00          .
    !byte sprite_0                                                                      ; 32f6: 32          2
    !byte sprite_0                                                                      ; 32f7: 32          2
    !byte sprite_0                                                                      ; 32f8: 32          2
    !byte sprite_space                                                                  ; 32f9: 00          .
    !byte sprite_0                                                                      ; 32fa: 32          2
    !byte sprite_0                                                                      ; 32fb: 32          2
    !byte sprite_0                                                                      ; 32fc: 32          2
    !byte sprite_space                                                                  ; 32fd: 00          .
    !byte sprite_0                                                                      ; 32fe: 32          2
    !byte sprite_0                                                                      ; 32ff: 32          2

; *************************************************************************************
; 
; Basic program for debugging purposes. Starts the game.
; On startup, this is immediately overwritten by the credits text.
; 
; 10*KEY 1 MO.4|M PAGE=13056 |M|N
; 20 MODE 5
; 30 VDU 23;8202;0;0;0;       (turns off the cursor)
; 40 *FX 178,0,0              (disables keyboard interrupts)
; 50 CALL 12736               (start the code at the regular entry_point)
; 60 *FX 178,255,0            (enables keyboard interrupts)
; 
copy_of_credits
    !byte $0d,   0, $0a                                                                 ; 3300: 0d 00 0a    ...
    !text " *KEY1 MO.4|M PAGE=13056 |M|N"                                               ; 3303: 20 2a 4b...  *K
    !byte $0d,   0, $14,   7, $20, $eb, $35, $0d,   0, $1e, $15, $20, $ef               ; 3320: 0d 00 14... ...
    !text " 23;8202;0;0;0;"                                                             ; 332d: 20 32 33...  23
    !byte $0d,   0, $28, $10                                                            ; 333c: 0d 00 28... ..(
    !text " *FX 178,0,0"                                                                ; 3340: 20 2a 46...  *F
    !byte $0d,   0, $32, $0c, $20, $d6                                                  ; 334c: 0d 00 32... ..2
    !text " 12736"                                                                      ; 3352: 20 31 32...  12
    !byte $0d,   0, $3c, $12                                                            ; 3358: 0d 00 3c... ..<
    !text " *FX 178,255,0"                                                              ; 335c: 20 2a 46...  *F
    !byte $0d, $ff                                                                      ; 336a: 0d ff       ..

; 
; A fragment of the original source code.
; 
; 80 JSR 10829
; 90 JSR 8850:LDA #220:STA 105
; 100 LDA #123:LDY #0:JSR 9001
; 110 JSR 8850:LDA #80:STA 105
; 120 LDA #125:LDY #128:JSR 9001
; 130 JSR 8850:LDX
; 
; Note there are no hex literals, everything's decimal. Which is unusual.
; 
; Translating this to hex form, we see this is the code at &3a06
; 80 JSR &2A4D
; 90 JSR &2292:LDA #&DC:STA &69
; 100 LDA #&7B:LDY #0:JSR &2329
; 110 JSR &2292:LDA #&50:STA &69
; 120 LDA #&7D:LDY #&80:JSR &2329
; 130 JSR &2292:LDX
; 
    !byte $50, $0e                                                                      ; 336c: 50 0e       P.
    !text " JSR 10829"                                                                  ; 336e: 20 4a 53...  JS
    !byte $0d,   0, $5a, $1e                                                            ; 3378: 0d 00 5a... ..Z
    !text " JSR 8850:LDA #220:STA 105"                                                  ; 337c: 20 4a 53...  JS
    !byte $0d,   0, $64, $1d                                                            ; 3396: 0d 00 64... ..d
    !text " LDA #123:LDY #0:JSR 9001"                                                   ; 339a: 20 4c 44...  LD
    !byte $0d,   0, $6e, $1d                                                            ; 33b3: 0d 00 6e... ..n
    !text " JSR 8850:LDA #80:STA 105"                                                   ; 33b7: 20 4a 53...  JS
    !byte $0d,   0, $78, $1f                                                            ; 33d0: 0d 00 78... ..x
    !text " LDA #125:LDY #128:JSR 9001"                                                 ; 33d4: 20 4c 44...  LD
    !byte $0d,   0, $82, $1b                                                            ; 33ef: 0d 00 82... ...
    !text " JSR 8850:LDX"                                                               ; 33f3: 20 4a 53...  JS

; *************************************************************************************
big_rockford_sprite
    !byte   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0     ; 3400: 00 00 00... ...
    !byte   0,   0,   0,   0, $1a, $10,   1, $11,   0,   2,   3, $21,   0,   2,   8     ; 340f: 00 00 00... ...
    !byte   6, $ca, $cb, $87, $69,   0,   3, $37, $8f, $2d, $6b, $0f,   1,   0,   4     ; 341e: 06 ca cb... ...
    !byte $6c, $3e, $96, $fc,   0,   4, $63, $c7, $96, $f3,   0,   3, $ce, $1f, $4b     ; 342d: 6c 3e 96... l>.
    !byte $6d, $0f,   1,   0,   2,   1, $12, $35, $3d, $1e, $69,   0,   2, $80, $88     ; 343c: 6d 0f 01... m..
    !byte   0,   2, $0c, $68,   0, $fd, $10,   1,   0,   2, $32, $11,   1,   7, $69     ; 344b: 00 02 0c... ...
    !byte $32, $b1, $52, $7e, $97, $cb, $4f, $2d, $3c, $78, $e1, $2d, $3e, $97, $ad     ; 345a: 32 b1 52... 2.R
    !byte $78, $f0, $0f,   1, $69, $3e, $1e, $5a, $7c, $3e, $96, $78, $0f,   1, $c7     ; 3469: 78 f0 0f... x..
    !byte $87, $a5, $e3, $c7, $96, $e1, $0f,   1, $4b, $c7, $9e, $5b, $e1, $f0, $0f     ; 3478: 87 a5 e3... ...
    !byte   1, $69, $e7, $9e, $3d, $2f, $4b, $c3, $e1, $78, $c4, $88,   8, $0e, $3e     ; 3487: 01 69 e7... .i.
    !byte $2d, $c4, $8e,   0,   6,   8,   0, $f3,   1,   0,   4,   1, $47, $4b, $32     ; 3496: 2d c4 8e... -..
    !byte $17,   7, $2d, $3e, $5a, $cb, $5a, $96, $87, $96, $96, $1e, $1e, $f0, $96     ; 34a5: 17 07 2d... ..-
    !byte $69, $96, $1e, $4b, $1e, $69, $0f,   1, $87, $4b, $0f,   1, $87, $87, $87     ; 34b4: 69 96 1e... i..
    !byte $4b, $0f,   1, $1e, $1e, $2d, $1e, $1e, $1e, $1e, $f0, $96, $69, $96, $1e     ; 34c3: 4b 0f 01... K..
    !byte $4b, $1e, $69, $0f,   1, $87, $87, $0f,   1, $87, $87, $87, $4b, $3e, $2d     ; 34d2: 4b 1e 69... K.i
    !byte $c4, $8e, $0e, $4b, $c7, $a5,   0,   2,   8,   0,   4,   8,   0, $f0,   1     ; 34e1: c4 8e 0e... ...
    !byte   1, $12, $13, $10,   4, $e1, $cb, $87, $87, $0f,   4, $2d, $3c, $3c, $3d     ; 34f0: 01 12 13... ...
    !byte $3d, $3d, $3d, $3d, $f6, $ff,   2, $ee, $dc, $dc, $b8, $b9, $4b, $87, $87     ; 34ff: 3d 3d 3d... ===
    !byte $87, $87, $87, $96, $87, $2d, $3c, $3c, $3d, $3d, $3d, $b5, $79, $f6, $ff     ; 350e: 87 87 87... ...
    !byte   2, $ee, $dc, $dc, $b8, $b9, $4b, $87, $87, $87, $87, $87, $87, $87, $78     ; 351d: 02 ee dc... ...
    !byte $3d, $1e, $1e, $0f,   4,   8,   8, $84, $8c, $80, $80, $80, $80,   0, $f0     ; 352c: 3d 1e 1e... =..
    !byte $21, $21, $21, $21, $21, $21, $21, $21, $0f,   8, $3d, $1e, $0f,   6, $b9     ; 353b: 21 21 21... !!!
    !byte $b8, $e1, $0f,   5, $97, $0f,   2, $4b, $4b, $2d, $1e, $0f,   1, $79, $bc     ; 354a: b8 e1 0f... ...
    !byte $ad, $2d, $4b, $4b, $87, $0f,   1, $b9, $b8, $e1, $0f,   5, $87, $0f,   5     ; 3559: ad 2d 4b... .-K
    !byte $a5, $4b, $0f,   8, $48,   8,   0, $f0, $10,   3,   0,   5, $0f,   3, $87     ; 3568: a5 4b 0f... .K.
    !byte $87, $43, $21, $10,   1, $0f,   7, $87, $4b, $c3, $4b, $a5, $1e, $0f,   7     ; 3577: 87 43 21... .C!
    !byte $87, $78, $0f,   6, $3c, $c3, $0f,   4, $1e, $69, $87, $0f,   3, $69, $87     ; 3586: 87 78 0f... .x.
    !byte $0f,   5, $1e, $0f,   3, $1e, $1e, $2c, $48,   1, $80, $80, $80, $80,   0     ; 3595: 0f 05 1e... ...
    !byte   0,   0,   5, $52, $30,   0,   6, $0f,   2, $87, $43, $21, $21, $10,   1     ; 35a4: 00 00 05... ...
    !byte   0,   1, $0f,   7, $87, $0f,   7, $1e, $0f,   2, $1e, $2c, $48,   2, $80     ; 35b3: 00 01 0f... ...
    !byte   0,   1, $a4, $c0,   0, $33, $11, $33, $77,   0,   4, $88, $cc, $ee, $ff     ; 35c2: 00 01 a4... ...
    !byte   1,   0, $d5, $10,   2, $31,   0,   3, $70, $f6, $ff,   3,   0,   1, $10     ; 35d1: 01 00 d5... ...
    !byte   1, $f1, $3d, $fc, $f6, $fe, $f7, $f0, $8f, $8f, $cb, $fc, $ff,   2, $f3     ; 35e0: 01 f1 3d... ..=
    !byte $f0, $3d, $3d, $3d, $f3, $ff,   2, $fc,   0,   1, $80, $c8, $e8, $fa, $f5     ; 35ef: f0 3d 3d... .==
    !byte $f7, $9f,   0,   5, $80, $80, $c8,   0, $1d, $11, $33, $77,   0,   1, $11     ; 35fe: f7 9f 00... ...
    !byte $33, $77, $ff,   1, $dd, $bb, $cc, $ff,   1, $55, $aa, $ff,   2, $55,   0     ; 360d: 33 77 ff... 3w.
    !byte   1, $a0, $ee, $55, $bb, $ff,   2, $77, $55, $20, $88, $44, $ee, $ff,   2     ; 361c: 01 a0 ee... ...
    !byte $ee, $bb, $e0,   0,   4, $88, $cc, $22, $73,   0, $bb, $10,   2, $21, $73     ; 362b: ee bb e0... ...
    !byte $73, $43, $43, $87, $0f,   3, $8f, $cf, $ff,   2, $7e, $3d, $3c, $7a, $d4     ; 363a: 73 43 43... sCC
    !byte $f6, $ff,   1, $87, $87, $87, $4b, $4b, $2d, $b5, $fc, $7f, $0f,   5, $ff     ; 3649: f6 ff 01... ...
    !byte   1, $e3, $8f, $0f,   4, $1f, $ff,   1, $1e, $1f, $1e, $0f,   1, $3e, $6f     ; 3658: 01 e3 8f... ...
    !byte $fe, $ff,   1, $c8, $48,   1, $2c, $2c, $2c, $2c, $fe, $fe,   0, $18, $55     ; 3667: fe ff 01... ...
    !byte $44, $44, $44, $22, $11, $10,   1, $31, $b8, $a8, $55, $33, $11,   0,   1     ; 3676: 44 44 44... DDD
    !byte $b0, $f3,   0,   1, $aa, $55, $ff,   2, $fe, $f5, $fb, $90, $31, $75, $fb     ; 3685: b0 f3 00... ...
    !byte $fb, $f3, $fd, $ff,   1, $fe, $fe, $fe, $fd, $ed, $ed, $cb, $da, $a3, $47     ; 3694: fb f3 fd... ...
    !byte $8f, $1f, $78, $f6, $f6, $fe, $80, $c8, $c8, $c8, $80,   0, $aa, $10,   1     ; 36a3: 8f 1f 78... ..x
    !byte   0,   1, $10,   2, $21, $43, $43, $87, $0f,   1, $f7, $ff,   2, $3f, $1f     ; 36b2: 00 01 10... ...
    !byte $1f, $1e, $1e, $fe, $fe, $fd, $ec,   1, $fb, $c0, $72, $31, $dc, $b9,   0     ; 36c1: 1f 1e 1e... ...
    !byte   1, $fb, $32, $d5, $fe, $64, $96, $da, $cb, $40, $d8, $b1, $73, $f7, $ff     ; 36d0: 01 fb 32... ..2
    !byte   2, $f5, $f4, $fb, $db, $c5, $b7, $ff,   3, $ef, $87, $cb, $ed, $be, $fe     ; 36df: 02 f5 f4... ...
    !byte $ff,   1, $9e, $1e, $1e, $1e, $0e, $0e, $fe, $ff,   1, $ef, $8f, $0f,   2     ; 36ee: ff 01 9e... ...
    !byte $87, $87,   0,   1, $80, $80, $80, $48,   4,   0,   5, $10,   1, $31, $f3     ; 36fd: 87 87 00... ...
    !byte   0,   2, $10,   1, $21, $c3, $cf, $cf, $cf, $73, $72, $f6, $f6, $f6, $f6     ; 370c: 00 02 10... ...
    !byte $f7, $7b, $f7, $ff,   4, $fd, $d0, $80, $fb, $ff,   4, $fe, $e0,   0,   1     ; 371b: f7 7b f7... .{.
    !byte $ff,   1, $fe, $fd, $f9, $90,   0,   3, $f5, $fa, $ff,   3, $f0,   0,   2     ; 372a: ff 01 fe... ...
    !byte $fe, $ec,   2, $c8, $80,   0, $ab, $10,   1, $31, $73, $73, $73, $f7, $f7     ; 3739: fe ec 02... ...
    !byte $e7, $0f,   1, $cf, $ef, $ef, $fe, $fc, $ef, $0f,   1, $2c, $48,   2, $80     ; 3748: e7 0f 01... ...
    !byte   0,   1, $10,   1, $b1, $7b, $31, $10,   1, $31, $73, $e7, $df, $af, $ce     ; 3757: 00 01 10... ...
    !byte $d8, $a1, $c3, $cb, $29, $36, $5e, $fe, $1e, $1e, $2d, $3d, $6b, $ea, $c6     ; 3766: d8 a1 c3... ...
    !byte $e7, $9b, $af, $77, $3f, $df, $7f, $fc, $7b, $9f, $cf, $9d, $0d, $9b, $3e     ; 3775: e7 9b af... ...
    !byte $1a, $e5, $f6, $a6, $96, $96, $96, $3c, $3c, $7a, $97, $b7, $73, $73, $73     ; 3784: 1a e5 f6... ...
    !byte $71, $31, $10,   1, $f8, $cb, $c7, $cf, $c7, $ef, $ef, $f4, $3f, $1f, $1f     ; 3793: 71 31 10... q1.
    !byte $1f, $1e, $2c, $c0,   0,   1, $ef, $fe, $ec,   1, $c0,   0,   4, $78, $80     ; 37a2: 1f 1e 2c... ..,
    !byte   0, $d6, $e7, $43, $43, $21, $31, $10,   1,   0,   2, $0f,   3, $3f, $ff     ; 37b1: 00 d6 e7... ...
    !byte   2, $f7, $73, $2d, $7e, $fe, $ff,   2, $ef, $cf, $8f, $9b, $8d, $3b, $d6     ; 37c0: 02 f7 73... ..s
    !byte $79, $6a, $3c, $3d, $bc, $fa, $f7, $bb, $55, $e2, $ec,   1, $fa, $df, $8d     ; 37cf: 79 6a 3c... yj<
    !byte $d6, $fa, $fd, $fd, $f3, $ff,   1, $f7, $f6, $fe, $fd, $fd, $fa, $fa, $e1     ; 37de: d6 fa fd... ...
    !byte $e5, $cb, $cb, $96, $96, $3c, $3d, $79, $5a, $96, $96, $1e, $d2, $fc, $fc     ; 37ed: e5 cb cb... ...
    !byte $fc,   0,   8, $c0,   0, $f7, $31, $10,   1,   0,   6, $0f,   2, $87, $52     ; 37fc: fc 00 08... ...
    !byte $30, $31, $31, $31, $7b, $f7, $f6, $fe, $fd, $fd, $fb, $fb, $fb, $f7, $ff     ; 380b: 30 31 31... 011
    !byte $0e, $ed, $fe, $fe, $ff,   5, $7b, $f7, $ff,   3, $fe, $fc, $f9, $fa, $fa     ; 381a: 0e ed fe... ...
    !byte $da, $96, $b5, $f3, $ff,   2,   0,   4, $80, $80, $80, $80,   0,   0, $31     ; 3829: da 96 b5... ...
    !byte $31, $31, $10,   1,   0,   4, $fb, $fb, $fb, $b0, $31, $31, $31, $31, $ff     ; 3838: 31 31 10... 11.
    !byte   4, $f7, $fb, $fd, $fe, $ff,   4, $fd, $fe, $ff,   2, $f6, $f9, $ff,   3     ; 3847: 04 f7 fb... ...
    !byte $f0, $ff,   2, $f5, $fd, $fd, $fb, $f7, $f7, $f7, $f7, $ff,   2, $fe, $fe     ; 3856: f0 ff 02... ...
    !byte $fe, $fe, $fe, $fe, $80, $80,   0,   0,   0, $0e, $31, $31, $31, $31, $31     ; 3865: fe fe fe... ...
    !byte $10,   3, $ff,   8, $f7, $f9, $fe, $ff,   1, $fe, $fe, $fe, $ec,   1, $fe     ; 3874: 10 03 ff... ...
    !byte $fd, $f3, $b1, $10,   2,   0,   2, $ff,   6, $f7, $f7, $ec,   8,   0,   0     ; 3883: fd f3 b1... ...
    !byte   0, $10, $10,   8, $ff,   8, $ec,   8,   0,   8, $f7, $f7, $f7, $f7, $f7     ; 3892: 00 10 10... ...
    !byte $f7, $f7, $f7, $ec,   6, $e4, $ec,   1,   0,   0,   0, $10, $10,   8, $ff     ; 38a1: f7 f7 f7... ...
    !byte   8, $ec,   8,   0,   8, $f7, $f7, $f7, $f7, $f7, $f7, $f7, $f7, $ec,   8     ; 38b0: 08 ec 08... ...
    !byte   0,   0,   0, $10, $10,   8, $ff,   8, $ec,   7, $fe,   0,   4, $10,   4     ; 38bf: 00 00 00... ...
    !byte $f7, $f7, $f7, $f7, $ff,   4, $ec,   4, $fe, $fe, $fe, $ec,   1,   0,   0     ; 38ce: f7 f7 f7... ...
    !byte   0, $0e, $10,   1, $31, $31, $31, $31, $31, $12, $f1, $fd, $f2, $ff,   5     ; 38dd: 00 0e 10... ...
    !byte $f0, $ff,   1, $f8, $fe, $fe, $fe, $fe, $ec,   1, $d2, $da, $87,   0,   4     ; 38ec: f0 ff 01... ...
    !byte $10,   3, $90, $f7, $70, $f3, $b4, $0f,   1, $2d, $4b, $4b, $fc, $f3, $f4     ; 38fb: 10 03 90... ...
    !byte $f5, $f5, $f5, $f6, $f6, $d0, $ff,   1, $f5, $f2, $e5, $f0, $f5, $f5,   0     ; 390a: f5 f5 f5... ...
    !byte   1, $80, $88,   0,   1, $c0, $f8, $f5, $f2,   0,   5, $80, $f0, $7a,   0     ; 3919: 01 80 88... ...
    !byte   7, $80,   0, $dc, $11, $12, $61, $f6,   0,   2, $61, $f2, $fc, $f4, $f4     ; 3928: 07 80 00... ...
    !byte $7a, $72, $f3, $f5, $f5, $da, $da, $cb, $f0, $7a, $f2, $b5, $f9, $da, $f2     ; 3937: 7a 72 f3... zr.
    !byte $f2, $7b, $e5, $e5, $e5, $cb, $cb, $87, $0f,   1, $2d, $0f,   1, $2d, $1e     ; 3946: f2 7b e5... .{.
    !byte $1e, $1e, $2d, $0f,   2, $a1, $a1, $a1, $69, $78, $79, $58, $c0, $87, $87     ; 3955: 1e 1e 2d... ..-
    !byte $4b, $0f,   2, $c3, $fc, $f3, $69, $0f,   4, $4b, $d3, $fc, $7a, $7a, $e5     ; 3964: 4b 0f 02... K..
    !byte $e5, $69, $ed, $db, $f3, $f5, $f4, $e5, $e5, $69, $ed, $db, $b7, $e5, $e5     ; 3973: e5 69 ed... .i.
    !byte $e5, $e5, $e5, $c3, $da, $96, $c0, $78, $f3, $f4, $f6, $f4, $fe, $e8,   0     ; 3982: e5 e5 e5... ...
    !byte $d8, $f2, $f6, $f2, $f6, $f1, $f7, $70, $73, $7a, $78, $79, $79, $96, $96     ; 3991: d8 f2 f6... ...
    !byte $f9, $fa, $7b, $3d, $96, $96, $f8, $f3, $fc, $c0, $b5, $b5, $da, $f8, $f7     ; 39a0: f9 fa 7b... ..{
    !byte $f8, $80,   0,   1, $1e, $1e, $f1, $fe, $e0,   0,   3, $3c, $f3, $fc, $c0     ; 39af: f8 80 00... ...
    !byte   0,   4, $c8, $80,   0,   6, $30,   0,   7, $f3, $30,   0,   6, $fc, $f3     ; 39be: 00 04 c8... ...
    !byte $31, $10,   1,   0,   4, $7e, $f0, $ff,   1, $f0,   0,   4, $3d, $f3, $fe     ; 39cd: 31 10 01... 1..
    !byte $f0,   0,   4, $ec,   1, $c0, $80,   0,   0,   0,   0,   0,   0,   0,   0     ; 39dc: f0 00 04... ...
    !byte   0,   0,   0, $9d, $50,   0, $fd, $39, $4f, $42, $4f, $4e,   0, $8e, $38     ; 39eb: 00 00 00... ...
    !byte $50,   0,   0, $12, $3a, $4f                                                  ; 39fa: 50 00 00... P..

; *************************************************************************************
show_menu
    jsr draw_big_rockford                                                               ; 3a00: 20 b5 2a     .*
    jsr reset_tune                                                                      ; 3a03: 20 00 57     .W
    jsr reset_clock                                                                     ; 3a06: 20 4d 2a     M*
    ; show last score line
    jsr reset_grid_of_sprites                                                           ; 3a09: 20 92 22     ."
    lda #<score_last_status_bar                                                         ; 3a0c: a9 dc       ..
    sta status_text_address_low                                                         ; 3a0e: 85 69       .i
    lda #>screen_addr_row_28                                                            ; 3a10: a9 7b       .{
    ldy #<screen_addr_row_28                                                            ; 3a12: a0 00       ..
    jsr draw_single_row_of_sprites                                                      ; 3a14: 20 29 23     )#
    ; show highscore line
    jsr reset_grid_of_sprites                                                           ; 3a17: 20 92 22     ."
    lda #<highscore_high_status_bar                                                     ; 3a1a: a9 50       .P
    sta status_text_address_low                                                         ; 3a1c: 85 69       .i
    lda #>screen_addr_row_30                                                            ; 3a1e: a9 7d       .}
    ldy #<screen_addr_row_30                                                            ; 3a20: a0 80       ..
    jsr draw_single_row_of_sprites                                                      ; 3a22: 20 29 23     )#
    jsr reset_grid_of_sprites                                                           ; 3a25: 20 92 22     ."
    ; set cave letter and difficulty level number
    ldx #0                                                                              ; 3a28: a2 00       ..
    ldy #1                                                                              ; 3a2a: a0 01       ..
handle_menu_loop
    lda #0                                                                              ; 3a2c: a9 00       ..
    sta timeout_until_demo_mode                                                         ; 3a2e: 85 6a       .j
    stx cave_number                                                                     ; 3a30: 86 87       ..
    sty difficulty_level                                                                ; 3a32: 84 89       ..
    txa                                                                                 ; 3a34: 8a          .
    clc                                                                                 ; 3a35: 18          .
    adc #'A'                                                                            ; 3a36: 69 41       iA
    sta cave_letter                                                                     ; 3a38: 8d 89 32    ..2
    tya                                                                                 ; 3a3b: 98          .
    clc                                                                                 ; 3a3c: 18          .
    adc #sprite_0                                                                       ; 3a3d: 69 32       i2
    sta number_of_players_status_bar_difficulty_level                                   ; 3a3f: 8d 8b 32    ..2
    jsr set_initial_palette                                                             ; 3a42: 20 ac 29     .)
waiting_for_demo_loop
    lda #<number_of_players_status_bar                                                  ; 3a45: a9 78       .x
    sta status_text_address_low                                                         ; 3a47: 85 69       .i
    jsr draw_status_bar                                                                 ; 3a49: 20 25 23     %#
    jsr update_tune                                                                     ; 3a4c: 20 13 57     .W
    lda #9                                                                              ; 3a4f: a9 09       ..
    jsr wait_for_a_centiseconds_and_read_keys                                           ; 3a51: 20 92 2b     .+
    jsr update_tune                                                                     ; 3a54: 20 13 57     .W
    lda #5                                                                              ; 3a57: a9 05       ..
    jsr wait_for_a_centiseconds_and_read_keys                                           ; 3a59: 20 92 2b     .+
    ldx cave_number                                                                     ; 3a5c: a6 87       ..
    ldy difficulty_level                                                                ; 3a5e: a4 89       ..
    lda #opcode_inx                                                                     ; 3a60: a9 e8       ..
    sta self_modify_move_left_or_right                                                  ; 3a62: 8d 9e 3a    ..:
    lda keys_to_process                                                                 ; 3a65: a5 62       .b
    asl                                                                                 ; 3a67: 0a          .
    bcs self_modify_move_left_or_right                                                  ; 3a68: b0 34       .4
    asl                                                                                 ; 3a6a: 0a          .
    bcs menu_move_left_to_change_cave                                                   ; 3a6b: b0 2c       .,
    asl                                                                                 ; 3a6d: 0a          .
    bcs increase_difficulty_level                                                       ; 3a6e: b0 3f       .?
    asl                                                                                 ; 3a70: 0a          .
    bcs decrease_difficulty_level                                                       ; 3a71: b0 44       .D
    asl                                                                                 ; 3a73: 0a          .
    bcs toggle_one_or_two_players                                                       ; 3a74: b0 48       .H
    asl                                                                                 ; 3a76: 0a          .
    bcs return15                                                                        ; 3a77: b0 68       .h
    asl                                                                                 ; 3a79: 0a          .
    bcs show_rockford_again_and_play_game                                               ; 3a7a: b0 55       .U
    dec timeout_until_demo_mode                                                         ; 3a7c: c6 6a       .j
    bne waiting_for_demo_loop                                                           ; 3a7e: d0 c5       ..

    ; demo mode
    ldx #5                                                                              ; 3a80: a2 05       ..
    lda #sprite_0                                                                       ; 3a82: a9 32       .2
zero_score_on_status_bar_loop
    sta score_on_regular_status_bar,x                                                   ; 3a84: 9d 0e 32    ..2
    dex                                                                                 ; 3a87: ca          .
    bpl zero_score_on_status_bar_loop                                                   ; 3a88: 10 fa       ..
    ldx #0                                                                              ; 3a8a: a2 00       ..
    stx cave_number                                                                     ; 3a8c: 86 87       ..
    stx demo_mode_tick_count                                                            ; 3a8e: 86 65       .e
    inx                                                                                 ; 3a90: e8          .
    stx difficulty_level                                                                ; 3a91: 86 89       ..
    jsr play_one_life                                                                   ; 3a93: 20 00 2e     ..
    jmp show_menu                                                                       ; 3a96: 4c 00 3a    L.:

menu_move_left_to_change_cave
    lda #opcode_dex                                                                     ; 3a99: a9 ca       ..
    sta self_modify_move_left_or_right                                                  ; 3a9b: 8d 9e 3a    ..:
self_modify_move_left_or_right
    inx                                                                                 ; 3a9e: e8          .
    txa                                                                                 ; 3a9f: 8a          .
    and #$0f                                                                            ; 3aa0: 29 0f       ).
    tax                                                                                 ; 3aa2: aa          .
store_new_difficulty_level_selected
    sty difficulty_level                                                                ; 3aa3: 84 89       ..
    lda number_of_difficuly_levels_available_in_menu_for_each_cave,x                    ; 3aa5: bd 68 4c    .hL
    cmp difficulty_level                                                                ; 3aa8: c5 89       ..
    bcc self_modify_move_left_or_right                                                  ; 3aaa: 90 f2       ..
    jmp handle_menu_loop                                                                ; 3aac: 4c 2c 3a    L,:

increase_difficulty_level
    iny                                                                                 ; 3aaf: c8          .
    cpy #6                                                                              ; 3ab0: c0 06       ..
    bne store_new_difficulty_level_selected                                             ; 3ab2: d0 ef       ..
    dey                                                                                 ; 3ab4: 88          .
    bne store_new_difficulty_level_selected                                             ; 3ab5: d0 ec       ..
decrease_difficulty_level
    dey                                                                                 ; 3ab7: 88          .
    bne dont_go_below_one                                                               ; 3ab8: d0 01       ..
    iny                                                                                 ; 3aba: c8          .
dont_go_below_one
    jmp handle_menu_loop                                                                ; 3abb: 4c 2c 3a    L,:

toggle_one_or_two_players
    lda number_of_players_status_bar                                                    ; 3abe: ad 78 32    .x2
    eor #sprite_1 XOR sprite_2                                                          ; 3ac1: 49 07       I.
    sta number_of_players_status_bar                                                    ; 3ac3: 8d 78 32    .x2
    lda plural_for_player                                                               ; 3ac6: ad 80 32    ..2
    eor #'S'                                                                            ; 3ac9: 49 53       IS
    sta plural_for_player                                                               ; 3acb: 8d 80 32    ..2
    jmp handle_menu_loop                                                                ; 3ace: 4c 2c 3a    L,:

show_rockford_again_and_play_game
    jsr draw_big_rockford                                                               ; 3ad1: 20 b5 2a     .*
    jsr reset_grid_of_sprites                                                           ; 3ad4: 20 92 22     ."
    lda #$ff                                                                            ; 3ad7: a9 ff       ..
    sta demo_mode_tick_count                                                            ; 3ad9: 85 65       .e
    jsr initialise_and_play_game                                                        ; 3adb: 20 00 3b     .;
    jmp show_menu                                                                       ; 3ade: 4c 00 3a    L.:

return15
    rts                                                                                 ; 3ae1: 60          `

unused51
    !byte $65, $20,   0, $3b, $4c,   0, $3a, $60, $ff, $ff, $ff, $ff, $ff, $ff, $ff     ; 3ae2: 65 20 00... e .
    !byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff     ; 3af1: ff ff ff... ...

; *************************************************************************************
initialise_and_play_game
    ldx #19                                                                             ; 3b00: a2 13       ..
copy_status_bar_loop
    lda default_status_bar,x                                                            ; 3b02: bd 68 50    .hP
    sta players_and_men_status_bar,x                                                    ; 3b05: 9d 14 32    ..2
    sta inactive_players_and_men_status_bar,x                                           ; 3b08: 9d 3c 32    .<2
    dex                                                                                 ; 3b0b: ca          .
    bpl copy_status_bar_loop                                                            ; 3b0c: 10 f4       ..
    lda #sprite_2                                                                       ; 3b0e: a9 34       .4
    sta player_number_on_inactive_players_and_men_status_bar                            ; 3b10: 8d 43 32    .C2
    cmp number_of_players_status_bar                                                    ; 3b13: cd 78 32    .x2
    beq set_cave_letter_on_status_bar                                                   ; 3b16: f0 05       ..
    lda #sprite_0                                                                       ; 3b18: a9 32       .2
    sta number_of_men_on_inactive_players_and_men_status_bar                            ; 3b1a: 8d 46 32    .F2
set_cave_letter_on_status_bar
    lda cave_letter                                                                     ; 3b1d: ad 89 32    ..2
    sta cave_letter_on_regular_status_bar                                               ; 3b20: 8d 25 32    .%2
    sta cave_letter_on_inactive_players_and_men_status_bar                              ; 3b23: 8d 4d 32    .M2
    ; copy difficuly level to other status bars
    ldx number_of_players_status_bar_difficulty_level                                   ; 3b26: ae 8b 32    ..2
    stx difficulty_level_on_regular_status_bar                                          ; 3b29: 8e 27 32    .'2
    stx difficulty_level_on_inactive_players_and_men_status_bar                         ; 3b2c: 8e 4f 32    .O2
    jsr set_cave_number_and_difficulty_level_from_status_bar                            ; 3b2f: 20 c1 3b     .;
    ; zero scores on status bars
    lda #sprite_0                                                                       ; 3b32: a9 32       .2
    ldx #5                                                                              ; 3b34: a2 05       ..
zero_score_loop
    sta score_on_regular_status_bar,x                                                   ; 3b36: 9d 0e 32    ..2
    sta score_on_inactive_players_regular_status_bar,x                                  ; 3b39: 9d 36 32    .62
    dex                                                                                 ; 3b3c: ca          .
    bpl zero_score_loop                                                                 ; 3b3d: 10 f7       ..
    ; add current stage to menu availablility
play_next_life
    ldx cave_number                                                                     ; 3b3f: a6 87       ..
    lda difficulty_level                                                                ; 3b41: a5 89       ..
    cmp number_of_difficuly_levels_available_in_menu_for_each_cave,x                    ; 3b43: dd 68 4c    .hL
    bmi skip_adding_new_difficulty_level_to_menu                                        ; 3b46: 30 03       0.
    ; add new difficulty level to menu
    sta number_of_difficuly_levels_available_in_menu_for_each_cave,x                    ; 3b48: 9d 68 4c    .hL
skip_adding_new_difficulty_level_to_menu
    jsr play_one_life                                                                   ; 3b4b: 20 00 2e     ..
    ; save results after life
    ; first find the position of the score to copy from the status bar (which depends
    ; on the player number)
    ldy #5                                                                              ; 3b4e: a0 05       ..
    ; check if player one or two
    lda player_number_on_regular_status_bar                                             ; 3b50: ad 1b 32    ..2
    lsr                                                                                 ; 3b53: 4a          J
    bcs copy_score                                                                      ; 3b54: b0 02       ..
    ; copy score from player two
    ldy #19                                                                             ; 3b56: a0 13       ..
copy_score
    ldx #5                                                                              ; 3b58: a2 05       ..
copy_score_to_last_score_loop
    lda score_on_regular_status_bar,x                                                   ; 3b5a: bd 0e 32    ..2
    sta score_last_status_bar,y                                                         ; 3b5d: 99 dc 32    ..2
    dey                                                                                 ; 3b60: 88          .
    dex                                                                                 ; 3b61: ca          .
    bpl copy_score_to_last_score_loop                                                   ; 3b62: 10 f6       ..
    lda neighbour_cell_contents                                                         ; 3b64: a5 64       .d
    cmp #8                                                                              ; 3b66: c9 08       ..
    beq calculate_next_cave_number_and_difficuly_level                                  ; 3b68: f0 37       .7
    lda cave_number                                                                     ; 3b6a: a5 87       ..
    cmp #16                                                                             ; 3b6c: c9 10       ..
    bpl calculate_next_cave_number_and_difficuly_level                                  ; 3b6e: 10 31       .1
    ; check for zero men left for the current player
    lda #sprite_0                                                                       ; 3b70: a9 32       .2
    cmp men_number_on_regular_status_bar                                                ; 3b72: cd 1e 32    ..2
    bne swap_status_bars_with_inactive_player_versions                                  ; 3b75: d0 05       ..
    ; check for zero men left for other player
    cmp number_of_men_on_inactive_players_and_men_status_bar                            ; 3b77: cd 46 32    .F2
    beq return16                                                                        ; 3b7a: f0 50       .P
swap_status_bars_with_inactive_player_versions
    ldx #39                                                                             ; 3b7c: a2 27       .'
swap_loop
    lda regular_status_bar,x                                                            ; 3b7e: bd 00 32    ..2
    ldy inactive_players_regular_status_bar,x                                           ; 3b81: bc 28 32    .(2
    sta inactive_players_regular_status_bar,x                                           ; 3b84: 9d 28 32    .(2
    tya                                                                                 ; 3b87: 98          .
    sta regular_status_bar,x                                                            ; 3b88: 9d 00 32    ..2
    dex                                                                                 ; 3b8b: ca          .
    bpl swap_loop                                                                       ; 3b8c: 10 f0       ..
    lda men_number_on_regular_status_bar                                                ; 3b8e: ad 1e 32    ..2
    cmp #sprite_0                                                                       ; 3b91: c9 32       .2
    beq swap_status_bars_with_inactive_player_versions                                  ; 3b93: f0 e7       ..
    lda cave_letter_on_regular_status_bar                                               ; 3b95: ad 25 32    .%2
    ldx difficulty_level_on_regular_status_bar                                          ; 3b98: ae 27 32    .'2
    jsr set_cave_number_and_difficulty_level_from_status_bar                            ; 3b9b: 20 c1 3b     .;
    jmp play_next_life                                                                  ; 3b9e: 4c 3f 3b    L?;

calculate_next_cave_number_and_difficuly_level
    ldx cave_number                                                                     ; 3ba1: a6 87       ..
    ldy difficulty_level                                                                ; 3ba3: a4 89       ..
    lda cave_play_order,x                                                               ; 3ba5: bd 40 4c    .@L
    sta cave_number                                                                     ; 3ba8: 85 87       ..
    bne store_cave_number_and_difficulty_level                                          ; 3baa: d0 07       ..
    iny                                                                                 ; 3bac: c8          .
    cpy #6                                                                              ; 3bad: c0 06       ..
    bne store_cave_number_and_difficulty_level                                          ; 3baf: d0 02       ..
    ldy #1                                                                              ; 3bb1: a0 01       ..
store_cave_number_and_difficulty_level
    sty difficulty_level                                                                ; 3bb3: 84 89       ..
    sta cave_number                                                                     ; 3bb5: 85 87       ..
    cmp #$10                                                                            ; 3bb7: c9 10       ..
    bmi play_next_life                                                                  ; 3bb9: 30 84       0.
    ; bonus life awarded on bonus level
    inc men_number_on_regular_status_bar                                                ; 3bbb: ee 1e 32    ..2
    jmp play_next_life                                                                  ; 3bbe: 4c 3f 3b    L?;

set_cave_number_and_difficulty_level_from_status_bar
    sec                                                                                 ; 3bc1: 38          8
    sbc #'A'                                                                            ; 3bc2: e9 41       .A
    sta cave_number                                                                     ; 3bc4: 85 87       ..
    txa                                                                                 ; 3bc6: 8a          .
    sec                                                                                 ; 3bc7: 38          8
    sbc #sprite_0                                                                       ; 3bc8: e9 32       .2
    sta difficulty_level                                                                ; 3bca: 85 89       ..
return16
    rts                                                                                 ; 3bcc: 60          `

unused_following_replacement_with_load_cave_file
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

;Updated - all caves, all difficulty levels are selectable from the menu by default
number_of_difficuly_levels_available_in_menu_for_each_cave
    !byte 5                                                                             ; 4c68: 05          .              ; Cave A
    !byte 5                                                                             ; 4c69: 00          .              ; Cave B
    !byte 5                                                                             ; 4c6a: 00          .              ; Cave C
    !byte 5                                                                             ; 4c6b: 00          .              ; Cave D
    !byte 5                                                                             ; 4c6c: 03          .              ; Cave E
    !byte 5                                                                             ; 4c6d: 00          .              ; Cave F
    !byte 5                                                                             ; 4c6e: 00          .              ; Cave G
    !byte 5                                                                             ; 4c6f: 00          .              ; Cave H
    !byte 5                                                                             ; 4c70: 03          .              ; Cave I
    !byte 5                                                                             ; 4c71: 00          .              ; Cave J
    !byte 5                                                                             ; 4c72: 00          .              ; Cave K
    !byte 5                                                                             ; 4c73: 00          .              ; Cave L
    !byte 5                                                                             ; 4c74: 03          .              ; Cave M
    !byte 5                                                                             ; 4c75: 00          .              ; Cave N
    !byte 5                                                                             ; 4c76: 00          .              ; Cave O
    !byte 5                                                                             ; 4c77: 00          .              ; Cave P
    !byte $80                                                                           ; 4c78: 80          .              ; Cave Q
    !byte $80                                                                           ; 4c79: 80          .              ; Cave R
    !byte $80                                                                           ; 4c7a: 80          .              ; Cave S
    !byte $80                                                                           ; 4c7b: 80          .              ; Cave T

cave_play_order
    !byte 1                                                                             ; 4c40: 01          .              ; Cave A
    !byte 2                                                                             ; 4c41: 02          .              ; Cave B
    !byte 3                                                                             ; 4c42: 03          .              ; Cave C
    !byte 16                                                                            ; 4c43: 10          .              ; Cave D
    !byte 5                                                                             ; 4c44: 05          .              ; Cave E
    !byte 6                                                                             ; 4c45: 06          .              ; Cave F
    !byte 7                                                                             ; 4c46: 07          .              ; Cave G
    !byte 17                                                                            ; 4c47: 11          .              ; Cave H
    !byte 9                                                                             ; 4c48: 09          .              ; Cave I
    !byte 10                                                                            ; 4c49: 0a          .              ; Cave J
    !byte 11                                                                            ; 4c4a: 0b          .              ; Cave K
    !byte 18                                                                            ; 4c4b: 12          .              ; Cave L
    !byte 13                                                                            ; 4c4c: 0d          .              ; Cave M
    !byte 14                                                                            ; 4c4d: 0e          .              ; Cave N
    !byte 15                                                                            ; 4c4e: 0f          .              ; Cave O
    !byte 19                                                                            ; 4c4f: 13          .              ; Cave P
    !byte 4                                                                             ; 4c50: 04          .              ; Cave Q
    !byte 8                                                                             ; 4c51: 08          .              ; Cave R
    !byte 12                                                                            ; 4c52: 0c          .              ; Cave S
    !byte 0                                                                             ; 4c53: 00          .              ; Cave T

; ****************************************************************************************************
; Populate the cave with tiles using the pseudo-random method
;   Tiles are applied to the map if the tile already there is a 'null' tile (from populate_cave_from_file)
;   These tiles may be the cave default (often dirt) or a tile determined in a pseudo-random fashion
;   A pseudo-random value is calculated by a function using the seed value for the cave difficulty level
;   The pseudo-random value is returned in random_seed1
;   This value is compared with each of the 4 tile probability values for the cave
;   If random_seed1 is not less than the probability value, the corresponding tile is plotted
;   For Boulder Dash 2, a second tile may be required below the pseudo-random one
;   These tiles are held in a 'beneath' row, populated with second tile values from cave parameters
;   If non-zero, the 'beneath' row tile will override random tiles (when on the next row)
; ****************************************************************************************************
populate_cave_tiles_pseudo_random

    ldx difficulty_level               ; Use difficulty_level (values 1 to 5) for the random seed value to use
    dex
    lda param_random_seeds,x           ; Set random_seed2 to cave random seed       
    sta random_seed2
    lda #$00                           ; Set random_seed1 to 0
    sta random_seed1

    lda #$16                           ; Set number of rows to 22 (includes steel top and bottom rows)
    sta populate_row_counter
    lda #<tile_map_row_1               ; Point to start of map (low)
    sta map_address_low
    lda #>tile_map_row_1               ; Point to start of map (high)
    sta map_address_high
populate_cave_row
    ldy #$00                           ; Set column start to 1 (skip first column - steel wall)
populate_cave_tile
    lda tile_below_store_row,y         ; Needed for BD2 caves G, K, get previously stored tile
    sta tile_override                  ; The override tile might need to replace the random tile

    ldx param_initial_fill_tile        ; Set cave fill tile
    jsr pseudo_random                  ; Call pseudo-random routine returning random_seed1 in the accumulator
    cmp param_tile_probability         ; Compare pseudo-random value with first cave probability parameter
    bcs check_next_probability1        ; If random_seed1 is not less than cave random compare parameter, don't plot the cave random object, try next one
    ldx param_tile_for_probability     ; Set the designated cave random tile
    lda param_tile_for_prob_below      ; Needed for BD2 caves G, K, set the tile below current one
    sta tile_below_store_row,y         ; to the parameter value for it (this value is 0 for most caves)

check_next_probability1
    lda random_seed1
    cmp param_tile_probability+1       ; Compare pseudo-random value with second cave probability parameter
    bcs check_next_probability2        ; If random_seed1 is not less than cave random compare parameter, don't plot the cave random object, try next one
    ldx param_tile_for_probability+1   ; Set the designated cave random tile
    lda param_tile_for_prob_below+1    ; Needed for BD2 caves G, K, set the tile below current one
    sta tile_below_store_row,y         ; to the parameter value for it (this value is 0 for most caves)

check_next_probability2
    lda random_seed1
    cmp param_tile_probability+2       ; Compare pseudo-random value with third cave probability parameter
    bcs check_next_probability3        ; If random_seed1 is not less than cave random compare parameter, don't plot the cave random object, try next one
    ldx param_tile_for_probability+2   ; Set the designated cave random tile
    lda param_tile_for_prob_below+2    ; Needed for BD2 caves G, K, set the tile below current one
    sta tile_below_store_row,y         ; to the parameter value for it (this value is 0 for most caves)

check_next_probability3
    lda random_seed1
    cmp param_tile_probability+3       ; Compare pseudo-random value with forth cave probability parameter
    bcs check_probability_end          ; If random_seed1 is not less than cave random compare parameter, don't plot the cave random object, continue
    ldx param_tile_for_probability+3   ; Set the designated cave random tile
    lda param_tile_for_prob_below+3    ; Needed for BD2 caves G, K, set the tile below current one
    sta tile_below_store_row,y         ; to the parameter value for it (this value is 0 for most caves)

check_probability_end
    lda (map_address_low),y            ; Get the map tile added when the cave was loaded
    cmp #$0f                           ; Check if a null tile #$0f. This occurs at this late stage to preserve the ongoing random seed calculations
    beq apply_random_tile_ok           ; Allow replacement with the random tile where is currently null
    lda #0                             ; Needed for BD2 caves G, K, reset the tile below current one
    sta tile_below_store_row,y         ; It must not be used later for override
    jmp check_tile_override            ; Now check for a previous override

apply_random_tile_ok
    txa                                ; The loaded map tile was a null, so replace with the random tile instead
    sta (map_address_low),y

check_tile_override
    lda tile_override
    beq skip_below_tile                ; Needed for BD2 caves G, K, check the override tile is 0
    sta (map_address_low),y            ; If not then apply the override tile
    lda #0                             ; Reset the tile below current one for next time
    sta tile_below_store_row,y

skip_below_tile
    iny                                ; Add 1 to column count
    cpy #$28                           ; Check if 40 columns plotted
    bne populate_cave_tile             ; Continue if not
    lda #$40                           ; Add 64 to map_address_low
    jsr add_a_to_ptr
    dec populate_row_counter
    lda populate_row_counter
    beq populate_cave_end              ; Rows are zero, so end
    jmp populate_cave_row              ; Continue to plot the next cave row
populate_cave_end
    rts

populate_row_counter
    !byte 0

tile_override
    !byte 0

; ****************************************************************************************************
; Pseudo-random function
;   Using a seed value, apply various operations to provide a value in random_seed1 used above
;   This value is not random, for a given seed value, the returned value is always predictable
; ****************************************************************************************************
pseudo_random
    lda random_seed1
    ror
    ror
    and #$80
    sta seeded_rand_temp1

    lda random_seed2
    ror
    and #$7f
    sta seeded_rand_temp2

    lda random_seed2
    ror
    ror
    and #$80
    clc 
    adc random_seed2
    adc #$13
    sta random_seed2
    lda random_seed1
    adc seeded_rand_temp1
    adc seeded_rand_temp2
    sta random_seed1
    rts

random_seed1
    !byte 0
random_seed2
    !byte 0
seeded_rand_temp1
    !byte 0
seeded_rand_temp2
    !byte 0

; ****************************************************************************************************
; Cave file load
;   Convert the cave number to a letter from A-T which is the name of the cave to load
;   Load this this file using a system method
; ****************************************************************************************************
load_cave_file
    lda cave_number
    cmp load_cave_number_stored        ; Check if the cave is already stored
    beq cave_already_loaded            ; Skip if already loaded

    clc
    adc #'A'                           ; Add letter 'A' to get the cave letter for the cave number
    sta load_cave_letter               ; Store the cave letter for the LOAD command
    ldy #>system_load_command          ; Set x,y for system LOAD command address
    ldx #<system_load_command          ; Set x,y for system LOAD command address
    jsr oscli_instruction_for_load     ; Call the LOAD command with the cave letter (next address after LOAD command address)
                                       ; The load address on the SSD file points to where the data should be located (e.g. 4e70)
    lda cave_number
    sta load_cave_number_stored

cave_already_loaded
    rts

load_cave_number_stored
    !byte $ff                          ; Initially cave $ff isn't a valid cave, so will always loads cave A
system_load_command
    !byte $4c, $4f, $2e                ; Is "LO." for the short system LOAD command
load_cave_letter
    !byte $3f                          ; Cave letter for the LOAD command
system_load_end
    !byte $0d                          ; Termination for LOAD command

; ****************************************************************************************************
; Populate Cave from file loaded data. Split bytes into 2 nibbles, each one representing a tile value
; ****************************************************************************************************
populate_cave_from_file
    lda #>cave_map_data                ; Point to cave address 4e70 (high byte)
    sta plot_cave_tiles_x2+2           ; Store in self-modifying code location
    lda #<cave_map_data                ; Point to cave address 4e70 (low byte)
    sta plot_cave_tiles_x2+1           ; Store in self-modifying code location

    lda #$14                           ; Set row counter to 20 (excluding steel top and bottom rows)
    sta load_row_counter
    lda #<tile_map_row_1               ; Point to start of map (low)
    sta map_address_low
    lda #>tile_map_row_1               ; Point to start of map (high)
    sta map_address_high

load_plot_cave_row
    ldy #$00                           ; Set column start to 0
plot_cave_tiles_x2
    lda cave_map_data                  ; The cave_map_data value after LDA is changed in this routine (self-modifying code)
    pha                                ; Store the byte (equates to 2 tiles) on the stack
    lsr                                ; left shift bits x 4 to get the nibble
    lsr
    lsr
    lsr
    sta (map_address_low),y            ; Store nibble as tile value to map
    iny                                ; Add 1 for next tile position
    pla                                ; Pull the byte off the stack
    and #$0f                           ; Get the second nibble
    sta (map_address_low),y            ; Store nibble as tile value to map
    iny                                ; Add 1 for next tile position
    inc plot_cave_tiles_x2+1           ; Move onto the next byte, calculating the high bytes as well
    lda plot_cave_tiles_x2+1
    bne load_skip_inc_high_byte
    inc plot_cave_tiles_x2+2
load_skip_inc_high_byte
    cpy #$28                           ; Check if 40 tiles plotted
    bne plot_cave_tiles_x2             ; Continue if not
    lda #$40                           ; Add 64 to map_address_low
    jsr add_a_to_ptr
    dec load_row_counter               ; Decrease row counter by 1
    lda load_row_counter
    beq populate_cave_from_file_end    ; If no more rows (counter is zero), go to end of routine
    jmp load_plot_cave_row             ; Continue to plot the next cave row

populate_cave_from_file_end
    rts

load_row_counter
    !byte 0

; ****************************************************************************************************
; Loaded data is placed here for cave parameters and map
; ****************************************************************************************************
cave_parameter_data                    ; Starts at address 4e40
param_diamond_value
    !byte 0                            ; Diamond value
param_diamond_extra_value
    !byte 0                            ; Diamond extra value
param_diamonds_required
    !byte 0, 0, 0, 0, 0                ; Diamonds required for each difficulty level x5
param_cave_time
    !byte 0, 0, 0, 0, 0                ; Cave time for each difficulty level x5
param_amoeba_magic_wall_time
    !byte 0                            ; Amoeba or Magic Wall time
param_initial_fill_tile
    !byte 0                            ; Initial fill tile - usually dirt, sometimes space
param_random_seeds
    !byte 0, 0, 0, 0, 0                ; Random seed for pseudo-random routine for each difficulty level x5
param_tile_probability
    !byte 0, 0, 0, 0                   ; Tile probability for up to four tiles / objects x4
param_tile_for_probability
    !byte 0, 0, 0, 0                   ; Tile / object related to the probability x4
param_intermission
    !byte 0                            ; Intermission indicator (0 for normal cave, 1 for intermission / bonus cave)
param_colours
    !byte 0, 0, 0                      ; Cave colour scheme x3 colours
param_rockford_start
    !byte 0, 0                         ; Rockford start row and column
param_rockford_end
    !byte 0, 0                         ; Rockford exit row and column
param_slime_permeability
    !byte $0a                          ; Slime permeability used in Boulder Dash 2 engine
param_tile_for_prob_below
    !byte 0, 0, 0, 0                   ; For Boulder Dash 2 caves C, K. Additional tile below the one generated by pseudo-random routine
param_bombs                            ; New element used to control use of bombs or not
    !byte 0                            ; 0 = no bombs, otherwise allow use of bombs
param_zero_gravity_time                ; New feature used to control use of gravity (whether rocks/diamonds fall)
    !byte 0                            ; 0 = no zero-gravity time (always gravity/normal), 1-$fe = time until gravity back on, $ff = always zero gravity
param_unused
    !byte 0, 0, 0, 0, 0, 0             ; Currently unused, potential future use (cannot be removed)

cave_map_data                          ; Empty cave (earth and side steel walls)
    !byte $31, $11, $11, $10, $11, $41, $50, $11, $11, $15, $15, $11, $11, $11, $10, $11  ; 4e70
    !byte $11, $51, $11, $13, $31, $51, $51, $11, $11, $10, $11, $11, $11, $11, $15, $41  ; 4e80
    !byte $11, $11, $11, $11, $11, $11, $11, $13, $31, $11, $11, $11, $11, $11, $11, $11  ; 4e90
    !byte $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $13, $31, $11, $11, $11  ; 4ea0
    !byte $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $13  ; 4eb0
    !byte $31, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11  ; 4ec0
    !byte $11, $11, $11, $13, $31, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11  ; 4ed0
    !byte $11, $11, $11, $11, $11, $11, $11, $13, $31, $11, $11, $11, $11, $11, $11, $11  ; 4ee0
    !byte $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $13, $31, $11, $11, $11  ; 4ef0
    !byte $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $13  ; 4f00
    !byte $31, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11  ; 4f10
    !byte $11, $11, $11, $13, $31, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11  ; 4f20
    !byte $11, $11, $11, $11, $11, $11, $11, $13, $31, $11, $11, $11, $11, $11, $11, $11  ; 4f30
    !byte $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $13, $31, $11, $11, $11  ; 4f40
    !byte $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $13  ; 4f50
    !byte $31, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11  ; 4f60
    !byte $11, $11, $11, $13, $31, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11  ; 4f70
    !byte $11, $11, $11, $11, $11, $11, $11, $13, $31, $11, $11, $11, $11, $11, $11, $11  ; 4f80
    !byte $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $13, $31, $11, $11, $11  ; 4f90
    !byte $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $13  ; 4fa0
    !byte $31, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11  ; 4fb0
    !byte $11, $11, $11, $13, $31, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11  ; 4fc0
    !byte $11, $11, $11, $11, $11, $11, $11, $13, $31, $11, $11, $11, $11, $11, $11, $11  ; 4fd0
    !byte $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $13, $31, $11, $11, $11  ; 4fe0
    !byte $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $13  ; 4ff0

; End of loaded data
; *************************************************************************************
tile_map_row_0
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83, $83                              ; 5000: 83 83 83... ...
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83, $83                              ; 500a: 83 83 83... ...
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83, $83                              ; 5014: 83 83 83... ...
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83, $83                              ; 501e: 83 83 83... ...

current_status_bar_sprites
    !byte sprite_1                                                                      ; 5028: 33          3
    !byte sprite_slash                                                                  ; 5029: 3e          >
    !text "A=EVAC"                                                                      ; 502a: 41 3d 45... A=E
    !byte sprite_space                                                                  ; 5030: 00          .
    !byte sprite_space                                                                  ; 5031: 00          .
    !byte sprite_space                                                                  ; 5032: 00          .
    !byte sprite_space                                                                  ; 5033: 00          .
    !text "REYALP"                                                                      ; 5034: 52 45 59... REY
    !byte sprite_space                                                                  ; 503a: 00          .
    !byte sprite_1                                                                      ; 503b: 33          3
unused59
    !byte $83, $83, $83,   1                                                            ; 503c: 83 83 83... ...

; *************************************************************************************
tile_map_row_1
    !byte $83, $81, $81, $80, $80, $80, $80, $80, $80, $80                              ; 5040: 83 81 81... ...
    !byte $80, $81, $81, $81, $81, $81, $81, $81, $81, $81                              ; 504a: 80 81 81... ...
    !byte $81, $81, $81, $81, $81, $81, $81, $81, $81, $81                              ; 5054: 81 81 81... ...
    !byte $81, $81, $81, $81, $81, $81, $81, $81, $81, $83                              ; 505e: 81 81 81... ...

default_status_bar
    !text "PLAYER"                                                                      ; 5068: 50 4c 41... PLA
    !byte sprite_space                                                                  ; 506e: 00          .
    !byte sprite_1                                                                      ; 506f: 33          3
    !byte sprite_comma                                                                  ; 5070: 3f          ?
    !byte sprite_space                                                                  ; 5071: 00          .
    !byte sprite_3                                                                      ; 5072: 35          5
    !byte sprite_space                                                                  ; 5073: 00          .
    !text "MEN"                                                                         ; 5074: 4d 45 4e    MEN
    !byte sprite_space                                                                  ; 5077: 00          .
    !byte sprite_space                                                                  ; 5078: 00          .
    !text "A"                                                                           ; 5079: 41          A
    !byte sprite_slash                                                                  ; 507a: 3e          >
    !byte sprite_2                                                                      ; 507b: 34          4
unused60
    !byte $83, $83, $83, $83                                                            ; 507c: 83 83 83... ...

; *************************************************************************************
tile_map_row_2
    !byte $83, $81, $81, $81, $81, $81, $81, $81, $81, $81                              ; 5080: 83 81 81... ...
    !byte $80, $81, $81, $81, $81, $81, $81, $81, $81, $81                              ; 508a: 80 81 81... ...
    !byte $81, $81, $81, $81, $81, $81, $81, $81, $81, $81                              ; 5094: 81 81 81... ...
    !byte $81, $81, $81, $81, $81, $81, $81, $81, $81, $83                              ; 509e: 81 81 81... ...

unused61
    !byte   1, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83     ; 50a8: 01 83 83... ...
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83                                   ; 50b7: 83 83 83... ...

; *************************************************************************************
tile_map_row_3
    !byte $83, $81, $81, $81, $81, $81, $81, $81, $81, $81                              ; 50c0: 83 81 81... ...
    !byte $80, $81, $81, $81, $81, $81, $81, $81, $81, $81                              ; 50ca: 80 81 81... ...
    !byte $81, $81, $81, $81, $81, $81, $81, $81, $81, $81                              ; 50d4: 81 81 81... ...
    !byte $81, $81, $81, $81, $81, $81, $81, $81, $81, $83                              ; 50de: 81 81 81... ...

unused62
    !byte   1, $83, $83, $83, $83, $83, $83,   8, $83, $83,   2, $83, $83, $83, $83     ; 50e8: 01 83 83... ...
    !byte $83,   5, $83,   5,   4, $83, $83, $83, $83                                   ; 50f7: 83 05 83... ...

; *************************************************************************************
tile_map_row_4
    !byte $83, $81, $81, $81, $81, $81, $81, $81, $81, $81                              ; 5100: 83 81 81... ...
    !byte $80, $81, $81, $81, $81, $81, $81, $81, $81, $81                              ; 510a: 80 81 81... ...
    !byte $81, $81, $81, $81, $81, $81, $81, $81, $81, $81                              ; 5114: 81 81 81... ...
    !byte $81, $81, $81, $81, $81, $81, $81, $81, $81, $83                              ; 511e: 81 81 81... ...

unused_fragment_of_basic1
    !text "|M|N"                                                                        ; 5128: 7c 4d 7c... |M|
    !byte $0d,   0, $1e, $23                                                            ; 512c: 0d 00 1e... ...
    !text "*KEY7 *SAVE C.GA"                                                            ; 5130: 2a 4b 45... *KE

; *************************************************************************************
tile_map_row_5
    !byte $83, $81, $81, $81, $81, $81, $81, $81, $81, $81                              ; 5140: 83 81 81... ...
    !byte $80, $81, $81, $81, $81, $81, $81, $81, $81, $81                              ; 514a: 80 81 81... ...
    !byte $81, $81, $96, $81, $96, $81, $96, $81, $96, $81                              ; 5154: 81 81 96... ...
    !byte $96, $81, $96, $81, $81, $81, $81, $81, $81, $83                              ; 515e: 96 81 96... ...

unused_fragment_of_basic2
    !text ";0;"                                                                         ; 5168: 3b 30 3b    ;0;
    !byte $0d,   0, $3c, $10                                                            ; 516b: 0d 00 3c... ..<
    !text " *FX 178,0,0"                                                                ; 516f: 20 2a 46...  *F
    !byte $0d,   0, $46, $0c, $20                                                       ; 517b: 0d 00 46... ..F

; *************************************************************************************
tile_map_row_6
    !byte $83, $81, $81, $81, $81, $81, $81, $81, $81, $81                              ; 5180: 83 81 81... ...
    !byte $80, $81, $81, $81, $81, $81, $81, $81, $80, $80                              ; 518a: 80 81 81... ...
    !byte $80, $81, $85, $81, $85, $81, $85, $81, $85, $81                              ; 5194: 80 81 85... ...
    !byte $85, $81, $85, $81, $81, $81, $81, $81, $81, $83                              ; 519e: 85 81 85... ...

unused63
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83     ; 51a8: 83 83 83... ...
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83                                   ; 51b7: 83 83 83... ...

; *************************************************************************************
tile_map_row_7
    !byte $83, $81, $81, $81, $81, $81, $81, $81, $81, $81                              ; 51c0: 83 81 81... ...
    !byte $80, $81, $81, $81, $81, $81, $81, $81, $80, $80                              ; 51ca: 80 81 81... ...
    !byte $80, $81, $81, $81, $81, $81, $81, $81, $81, $81                              ; 51d4: 80 81 81... ...
    !byte $81, $81, $81, $81, $81, $81, $81, $81, $81, $83                              ; 51de: 81 81 81... ...

unused64
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83     ; 51e8: 83 83 83... ...
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83                                   ; 51f7: 83 83 83... ...

; *************************************************************************************
tile_map_row_8
    !byte $83, $81, $81, $81, $81, $81, $81, $81, $81, $81                              ; 5200: 83 81 81... ...
    !byte $80, $80, $80, $8e, $9e, $9e, $80, $80, $80, $80                              ; 520a: 80 80 80... ...
    !byte $80, $81, $81, $81, $81, $81, $81, $81, $81, $81                              ; 5214: 80 81 81... ...
    !byte $81, $81, $81, $81, $81, $81, $81, $81, $81, $83                              ; 521e: 81 81 81... ...

unused65
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83     ; 5228: 83 83 83... ...
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83                                   ; 5237: 83 83 83... ...

; *************************************************************************************
tile_map_row_9
    !byte $83, $81, $81, $81, $81, $81, $81, $81, $81, $81                              ; 5240: 83 81 81... ...
    !byte $81, $80, $81, $80, $81, $80, $81, $80, $84, $80                              ; 524a: 81 80 81... ...
    !byte $84, $80, $81, $81, $81, $81, $81, $81, $81, $81                              ; 5254: 84 80 81... ...
    !byte $81, $81, $81, $81, $81, $81, $81, $81, $81, $83                              ; 525e: 81 81 81... ...

unused66
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83     ; 5268: 83 83 83... ...
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83                                   ; 5277: 83 83 83... ...

; *************************************************************************************
tile_map_row_10
    !byte $83, $81, $81, $81, $81, $81, $81, $81, $81, $81                              ; 5280: 83 81 81... ...
    !byte $81, $8e, $81, $80, $81, $80, $81, $80, $81, $80                              ; 528a: 81 8e 81... ...
    !byte $81, $80, $81, $81, $81, $81, $81, $81, $81, $81                              ; 5294: 81 80 81... ...
    !byte $81, $81, $81, $81, $81, $81, $81, $81, $81, $83                              ; 529e: 81 81 81... ...

unused67
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83     ; 52a8: 83 83 83... ...
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83                                   ; 52b7: 83 83 83... ...

; *************************************************************************************
tile_map_row_11
    !byte $83, $81, $81, $81, $81, $81, $81, $81, $81, $81                              ; 52c0: 83 81 81... ...
    !byte $81, $80, $81, $80, $81, $80, $81, $80, $81, $80                              ; 52ca: 81 80 81... ...
    !byte $81, $80, $81, $81, $81, $81, $81, $81, $81, $81                              ; 52d4: 81 80 81... ...
    !byte $81, $81, $81, $81, $81, $81, $81, $81, $81, $83                              ; 52de: 81 81 81... ...

unused68
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83     ; 52e8: 83 83 83... ...
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83                                   ; 52f7: 83 83 83... ...

; *************************************************************************************
tile_map_row_12
    !byte $83, $81, $81, $81, $81, $81, $81, $81, $81, $81                              ; 5300: 83 81 81... ...
    !byte $81, $80, $81, $80, $81, $80, $81, $80, $81, $80                              ; 530a: 81 80 81... ...
    !byte $81, $80, $81, $81, $81, $81, $81, $81, $81, $81                              ; 5314: 81 80 81... ...
    !byte $81, $81, $81, $81, $81, $81, $81, $81, $81, $83                              ; 531e: 81 81 81... ...

unused69
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83     ; 5328: 83 83 83... ...
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83                                   ; 5337: 83 83 83... ...

; *************************************************************************************
tile_map_row_13
    !byte $83, $81, $81, $81, $81, $81, $81, $81, $81, $81                              ; 5340: 83 81 81... ...
    !byte $81, $80, $81, $80, $81, $80, $81, $80, $81, $80                              ; 534a: 81 80 81... ...
    !byte $81, $80, $81, $81, $81, $81, $81, $81, $81, $81                              ; 5354: 81 80 81... ...
    !byte $81, $81, $81, $81, $81, $81, $81, $81, $81, $83                              ; 535e: 81 81 81... ...

unused70
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83     ; 5368: 83 83 83... ...
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83                                   ; 5377: 83 83 83... ...

; *************************************************************************************
tile_map_row_14
    !byte $83, $81, $81, $81, $81, $81, $81, $81, $81, $81                              ; 5380: 83 81 81... ...
    !byte $81, $80, $81, $80, $81, $80, $81, $80, $81, $c4                              ; 538a: 81 80 81... ...
    !byte $81, $80, $81, $81, $81, $81, $81, $81, $81, $81                              ; 5394: 81 80 81... ...
    !byte $81, $81, $81, $81, $81, $81, $81, $81, $81, $83                              ; 539e: 81 81 81... ...

unused71
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83     ; 53a8: 83 83 83... ...
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83                                   ; 53b7: 83 83 83... ...

; *************************************************************************************
tile_map_row_15
    !byte $83, $81, $81, $81, $81, $81, $81, $81, $81, $81                              ; 53c0: 83 81 81... ...
    !byte $81, $80, $81, $80, $81, $80, $81, $80, $81, $80                              ; 53ca: 81 80 81... ...
    !byte $81, $80, $81, $81, $81, $81, $81, $81, $81, $81                              ; 53d4: 81 80 81... ...
    !byte $81, $81, $81, $81, $81, $81, $81, $81, $81, $83                              ; 53de: 81 81 81... ...

unused72
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83     ; 53e8: 83 83 83... ...
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83                                   ; 53f7: 83 83 83... ...

; *************************************************************************************
tile_map_row_16
credits
    !byte sprite_full_stop                                                              ; 5400: 40          @
    !byte sprite_full_stop                                                              ; 5401: 40          @
    !byte sprite_full_stop                                                              ; 5402: 40          @
    !byte sprite_full_stop                                                              ; 5403: 40          @
    !text "BOULDERDASH"                                                                 ; 5404: 42 4f 55... BOU
    !byte sprite_full_stop                                                              ; 540f: 40          @
    !byte sprite_full_stop                                                              ; 5410: 40          @
    !byte sprite_full_stop                                                              ; 5411: 40          @
    !text "WRITTEN"                                                                     ; 5412: 57 52 49... WRI
    !byte sprite_space                                                                  ; 5419: 00          .
    !text "BY"                                                                          ; 541a: 42 59       BY
    !byte sprite_space                                                                  ; 541c: 00          .
    !text "A"                                                                           ; 541d: 41          A
    !byte sprite_full_stop                                                              ; 541e: 40          @
    !text "G"                                                                           ; 541f: 47          G
    !byte sprite_full_stop                                                              ; 5420: 40          @
    !text "BENNETT"                                                                     ; 5421: 42 45 4e... BEN
    !byte sprite_space                                                                  ; 5428: 00          .
    !byte sprite_1                                                                      ; 5429: 33          3
    !byte sprite_9                                                                      ; 542a: 3b          ;
    !byte sprite_8                                                                      ; 542b: 3a          :
    !byte sprite_8                                                                      ; 542c: 3a          :
    !byte sprite_full_stop                                                              ; 542d: 40          @
    !byte sprite_full_stop                                                              ; 542e: 40          @
    !byte sprite_full_stop                                                              ; 542f: 40          @
    !text "DEDICATED"                                                                   ; 5430: 44 45 44... DED
    !byte sprite_space                                                                  ; 5439: 00          .
    !text "TO"                                                                          ; 543a: 54 4f       TO
    !byte sprite_space                                                                  ; 543c: 00          .
    !text "J"                                                                           ; 543d: 4a          J
    !byte sprite_full_stop                                                              ; 543e: 40          @
    !text "M"                                                                           ; 543f: 4d          M
tile_map_row_17
    !byte sprite_full_stop                                                              ; 5440: 40          @
    !text "BARNES"                                                                      ; 5441: 42 41 52... BAR
    !byte sprite_comma                                                                  ; 5447: 3f          ?
    !text "DEBBIE"                                                                      ; 5448: 44 45 42... DEB
    !byte sprite_comma                                                                  ; 544e: 3f          ?
    !text "MARK"                                                                        ; 544f: 4d 41 52... MAR
    !byte sprite_space                                                                  ; 5453: 00          .
    !text "BENNETT"                                                                     ; 5454: 42 45 4e... BEN
    !byte sprite_comma                                                                  ; 545b: 3f          ?
    !text "OUR"                                                                         ; 545c: 4f 55 52    OUR
    !byte sprite_space                                                                  ; 545f: 00          .
    !text "MAM"                                                                         ; 5460: 4d 41 4d    MAM
    !byte sprite_comma                                                                  ; 5463: 3f          ?
    !text "MIC"                                                                         ; 5464: 4d 49 43    MIC
    !byte sprite_comma                                                                  ; 5467: 3f          ?
    !text "BURNY"                                                                       ; 5468: 42 55 52... BUR
    !byte sprite_comma                                                                  ; 546d: 3f          ?
    !text "N"                                                                           ; 546e: 4e          N
    !byte sprite_full_stop                                                              ; 546f: 40          @
    !text "JENNISON"                                                                    ; 5470: 4a 45 4e... JEN
    !byte sprite_comma                                                                  ; 5478: 3f          ?
    !text "CRAIG"                                                                       ; 5479: 43 52 41... CRA
    !byte sprite_space                                                                  ; 547e: 00          .
l547f
tile_map_row_18 = l547f+1
    !text "DARRELL"                                                                     ; 547f: 44 41 52... DAR
    !byte sprite_comma                                                                  ; 5486: 3f          ?
    !text "T"                                                                           ; 5487: 54          T
    !byte sprite_full_stop                                                              ; 5488: 40          @
    !text "SECKER"                                                                      ; 5489: 53 45 43... SEC
    !byte sprite_comma                                                                  ; 548f: 3f          ?
    !text "TONY"                                                                        ; 5490: 54 4f 4e... TON
    !byte sprite_space                                                                  ; 5494: 00          .
    !text "FROM"                                                                        ; 5495: 46 52 4f... FRO
    !byte sprite_space                                                                  ; 5499: 00          .
    !text "THE"                                                                         ; 549a: 54 48 45    THE
    !byte sprite_space                                                                  ; 549d: 00          .
    !text "PALACE"                                                                      ; 549e: 50 41 4c... PAL
    !byte sprite_comma                                                                  ; 54a4: 3f          ?
    !text "TONY"                                                                        ; 54a5: 54 4f 4e... TON
    !byte sprite_space                                                                  ; 54a9: 00          .
    !text "FROM"                                                                        ; 54aa: 46 52 4f... FRO
    !byte sprite_space                                                                  ; 54ae: 00          .
    !text "LEAZES"                                                                      ; 54af: 4c 45 41... LEA
    !byte sprite_comma                                                                  ; 54b5: 3f          ?
    !text "SOLAR"                                                                       ; 54b6: 53 4f 4c... SOL
    !byte sprite_space                                                                  ; 54bb: 00          .
l54bc
tile_map_row_19 = l54bc+4
    !text "WORKSHOP"                                                                    ; 54bc: 57 4f 52... WOR
    !byte sprite_comma                                                                  ; 54c4: 3f          ?
    !text "ELSIE"                                                                       ; 54c5: 45 4c 53... ELS
    !byte sprite_comma                                                                  ; 54ca: 3f          ?
    !text "PRIMROSE"                                                                    ; 54cb: 50 52 49... PRI
    !byte sprite_comma                                                                  ; 54d3: 3f          ?
    !text "STRANGE"                                                                     ; 54d4: 53 54 52... STR
    !byte sprite_space                                                                  ; 54db: 00          .
    !text "SCIENCE"                                                                     ; 54dc: 53 43 49... SCI
    !byte sprite_space                                                                  ; 54e3: 00          .
    !text "PINBALL"                                                                     ; 54e4: 50 49 4e... PIN
    !byte sprite_space                                                                  ; 54eb: 00          .
    !text "AND"                                                                         ; 54ec: 41 4e 44    AND
    !byte sprite_space                                                                  ; 54ef: 00          .
    !text "COSMIC"                                                                      ; 54f0: 43 4f 53... COS
    !byte sprite_space                                                                  ; 54f6: 00          .
    !text "MONSTERS"                                                                    ; 54f7: 4d 4f 4e... MON
    !byte sprite_full_stop                                                              ; 54ff: 40          @

; *************************************************************************************
tile_map_row_20
    !byte $83, $81, $81, $81, $81, $81, $81, $81, $81, $81                              ; 5500: 83 81 81... ...
    !byte $81, $81, $81, $81, $81, $81, $81, $81, $81, $81                              ; 550a: 81 81 81... ...
    !byte $81, $81, $81, $81, $81, $81, $81, $81, $81, $81                              ; 5514: 81 81 81... ...
    !byte $81, $81, $81, $81, $81, $81, $81, $81, $81, $83                              ; 551e: 81 81 81... ...

unused73
    !byte   1, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83     ; 5528: 01 83 83... ...
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83                                   ; 5537: 83 83 83... ...

; *************************************************************************************
tile_map_row_21
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83, $83                              ; 5540: 83 83 83... ...
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83, $83                              ; 554a: 83 83 83... ...
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83, $83                              ; 5554: 83 83 83... ...
    !byte $83, $83, $83, $83, $83, $83, $83, $83, $83, $83                              ; 555e: 83 83 83... ...


; unused copy of routine at $5700
unused74
    lda #osbyte_flush_buffer_class                                                      ; 5568: a9 0f       ..
    ldx #0                                                                              ; 556a: a2 00       ..
    jsr osbyte                                                                          ; 556c: 20 f4 ff     ..            ; Flush all buffers (X=0)
    ldx #5                                                                              ; 556f: a2 05       ..
unused77
    lda tune_start_position_per_channel,x                                               ; 5571: bd e8 56    ..V
    sta tune_position_per_channel,x                                                     ; 5574: 9d d0 56    ..V
    dex                                                                                 ; 5577: ca          .
    bpl unused77                                                                        ; 5578: 10 f7       ..
    rts                                                                                 ; 557a: 60          `

unused78
    !byte $a9,   0, $85, $8e, $a9                                                       ; 557b: a9 00 85... ...

; *************************************************************************************
tile_map_row_22
    !byte $83, $b8, $e5, $8e, $aa, $a0, $ff, $a9, $80, $a0                              ; 5580: 83 b8 e5... ...
    !byte $f4, $ff, $8a, $f0, $e6, $a6, $8e, $8a, $8a, $8a                              ; 558a: f4 ff 8a... ...
    !byte $8a, $85, $8f, $bd, $d0, $d6, $a8, $e0, $80, $d0                              ; 5594: 8a 85 8f... ...
    !byte $84, $c0, $c1, $f0, $c5, $b9, $80, $d6, $c9, $83                              ; 559e: 84 c0 c1... ...

unused75
    !byte $90, $1a, $a8, $bd, $d3, $56, $d0,   6, $b9, $1a, $56, $9d, $d3, $56, $b9     ; 55a8: 90 1a a8... ...
    !byte $0e, $56, $48, $b9, $14, $56, $a8, $68, $de                                   ; 55b7: 0e 56 48... .VH

; *************************************************************************************
tile_map_row_23
    !byte $d3, $56, $10, $12, $48, $29,   3, $a8, $a9,   0                              ; 55c0: d3 56 10... .V.
    !byte $9d, $d3, $56, $b9, $ee, $56, $a8, $68, $29, $fc                              ; 55ca: 9d d3 56... ..V
    !byte   9,   1, $48, $bd, $d3, $56, $d0,   3, $fe, $d0                              ; 55d4: 09 01 48... ..H
    !byte $56, $68, $a6, $8f, $9d, $bc, $56, $98, $9d, $be                              ; 55de: 56 68 a6... Vh.

unused76
    !byte $56, $8a, $18, $69, $b8, $aa, $a0, $56, $a9,   7, $20, $f1, $ff, $e6, $8e     ; 55e8: 56 8a 18... V..
    !byte $26, $8e, $e0,   3, $d0, $82, $60, $83, $83                                   ; 55f7: 26 8e e0... &..

; *************************************************************************************
tune_pitches_and_commands
    !byte $48, $58, $5c, $64, $58, $5c, $64, $70, $5c, $64, $70, $78, $49, $45, $19     ; 5600: 48 58 5c... HX\
    !byte   5, $11, $24, $20, $19,   5, $13,   9, $25,   3,   5, $c8, $a8, $a8, $a8     ; 560f: 05 11 24... ..$
    !byte $a8, $18, $c9, $10, $c9, $18, $c9, $10, $c9, $18, $c9, $10, $c9, $18, $c9     ; 561e: a8 18 c9... ...
    !byte $10, $a8, $a8, $a8, $88, $a8, $94, $8c, $40, $58, $5c, $64, $70, $a8, $a0     ; 562d: 10 a8 a8... ...
    !byte $94, $8c, $88, $78, $70, $48, $58, $5c, $64, $58, $5c, $64, $70, $5c, $64     ; 563c: 94 8c 88... ...
    !byte $70, $78, $48, $b5, $b0, $18, $78,   5, $11, $80, $20, $18, $78,   5, $11     ; 564b: 70 78 48... pxH
    !byte $a9,   8, $78, $25,   1, $a9,   5, $c8, $ca, $58, $78, $64, $5c, $10, $28     ; 565a: a9 08 78... ..x
    !byte $2c, $34, $40, $78, $70, $64, $5c, $58, $48, $40, $48, $58, $5c, $64, $58     ; 5669: 2c 34 40... ,4@
    !byte $5c, $64, $70, $5c, $64, $70, $78, $48, $a9, $a4, $19,   5, $11, $24, $20     ; 5678: 5c 64 70... \dp
    !byte $19,   5, $13,   9, $25,   3,   5, $c8, $cb, $cd, $89, $8d, $89, $8d, $89     ; 5687: 19 05 13... ...
    !byte $8d, $81, $85, $a9, $a1, $9d, $95, $a1, $a1, $8d, $a1, $89, $8d, $89, $8d     ; 5696: 8d 81 85... ...
    !byte $89, $8d, $cc, $70, $94, $80, $78, $2c, $40, $48, $50, $5c, $94, $8c, $80     ; 56a5: 89 8d cc... ...
    !byte $78, $70, $64, $5c                                                            ; 56b4: 78 70 64... xpd

; *************************************************************************************
sound1
    !word 1                                                                             ; 56b8: 01 00       ..             ; channel   (2 bytes)
    !word 10                                                                            ; 56ba: 0a 00       ..             ; amplitude (2 bytes)
sound1_pitch
    !word 69                                                                            ; 56bc: 45 00       E.             ; pitch     (2 bytes)
sound1_duration
    !word 6                                                                             ; 56be: 06 00       ..             ; duration  (2 bytes)

sound2
    !word 2                                                                             ; 56c0: 02 00       ..             ; channel   (2 bytes)
    !word 11                                                                            ; 56c2: 0b 00       ..             ; amplitude (2 bytes)
    !word 181                                                                           ; 56c4: b5 00       ..             ; pitch     (2 bytes)
    !word 6                                                                             ; 56c6: 06 00       ..             ; duration  (2 bytes)

sound3
    !word 3                                                                             ; 56c8: 03 00       ..             ; channel   (2 bytes)
    !word 12                                                                            ; 56ca: 0c 00       ..             ; amplitude (2 bytes)
    !word 169                                                                           ; 56cc: a9 00       ..             ; pitch     (2 bytes)
    !word 6                                                                             ; 56ce: 06 00       ..             ; duration  (2 bytes)

tune_position_per_channel
    !byte $0e, $4f, $81                                                                 ; 56d0: 0e 4f 81    .O.
tune_note_repeat_per_channel
    !byte 0, 0, 0                                                                       ; 56d3: 00 00 00    ...
command_pitch
    !byte $19, $a9, $79, $79, $81, $79                                                  ; 56d6: 19 a9 79... ..y
command_note_durations
    !byte $12,   3,   3,   3,   8,   7                                                  ; 56dc: 12 03 03... ...
command_note_repeat_counts
    !byte   1,   7, $40, $0f,   1,   1                                                  ; 56e2: 01 07 40... ..@
tune_start_position_per_channel
    !byte   0, $41, $73                                                                 ; 56e8: 00 41 73    .As
    !byte 0, 0, 0                                                                       ; 56eb: 00 00 00    ...
tune_note_durations_table
    !byte  3,  6,  9, 12                                                                ; 56ee: 03 06 09... ...

unused79
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0                                      ; 56f2: 00 00 00... ...

; *************************************************************************************
reset_tune
    lda #osbyte_flush_buffer_class                                                      ; 5700: a9 0f       ..
    ldx #0                                                                              ; 5702: a2 00       ..
    jsr osbyte                                                                          ; 5704: 20 f4 ff     ..            ; Flush all buffers (X=0)
    ldx #5                                                                              ; 5707: a2 05       ..
reset_tune_loop
    lda tune_start_position_per_channel,x                                               ; 5709: bd e8 56    ..V
    sta tune_position_per_channel,x                                                     ; 570c: 9d d0 56    ..V
    dex                                                                                 ; 570f: ca          .
    bpl reset_tune_loop                                                                 ; 5710: 10 f7       ..
    rts                                                                                 ; 5712: 60          `

; *************************************************************************************
update_tune
    lda #0                                                                              ; 5713: a9 00       ..
    sta sound_channel                                                                   ; 5715: 85 8e       ..
update_channels_loop
    lda #$fa                                                                            ; 5717: a9 fa       ..
    sec                                                                                 ; 5719: 38          8
    sbc sound_channel                                                                   ; 571a: e5 8e       ..
    tax                                                                                 ; 571c: aa          .
    ldy #$ff                                                                            ; 571d: a0 ff       ..
    lda #osbyte_read_adc_or_get_buffer_status                                           ; 571f: a9 80       ..
    jsr osbyte                                                                          ; 5721: 20 f4 ff     ..            ; Read buffer status or ADC channel
    txa                                                                                 ; 5724: 8a          .
    beq move_to_next_tune_channel                                                       ; 5725: f0 66       .f
    ldx sound_channel                                                                   ; 5727: a6 8e       ..
    txa                                                                                 ; 5729: 8a          .
    asl                                                                                 ; 572a: 0a          .
    asl                                                                                 ; 572b: 0a          .
    asl                                                                                 ; 572c: 0a          .
    sta offset_to_sound                                                                 ; 572d: 85 8f       ..
    lda tune_position_per_channel,x                                                     ; 572f: bd d0 56    ..V
    tay                                                                                 ; 5732: a8          .
    cpx #0                                                                              ; 5733: e0 00       ..
    bne skip_end_of_tune_check                                                          ; 5735: d0 04       ..
    cpy #$41                                                                            ; 5737: c0 41       .A
    beq reset_tune                                                                      ; 5739: f0 c5       ..
skip_end_of_tune_check
    lda tune_pitches_and_commands,y                                                     ; 573b: b9 00 56    ..V
    cmp #200                                                                            ; 573e: c9 c8       ..
    bcc note_found                                                                      ; 5740: 90 1a       ..
    tay                                                                                 ; 5742: a8          .
    lda tune_note_repeat_per_channel,x                                                  ; 5743: bd d3 56    ..V
    bne skip_reset_note_repeat                                                          ; 5746: d0 06       ..
    lda command_note_repeat_counts-200,y                                                ; 5748: b9 1a 56    ..V
    sta tune_note_repeat_per_channel,x                                                  ; 574b: 9d d3 56    ..V
skip_reset_note_repeat
    lda command_pitch-200,y                                                             ; 574e: b9 0e 56    ..V
    pha                                                                                 ; 5751: 48          H
    lda command_note_durations - 200,y                                                  ; 5752: b9 14 56    ..V
    tay                                                                                 ; 5755: a8          .
    pla                                                                                 ; 5756: 68          h
    dec tune_note_repeat_per_channel,x                                                  ; 5757: de d3 56    ..V
    bpl c576e                                                                           ; 575a: 10 12       ..
note_found
    pha                                                                                 ; 575c: 48          H
    and #3                                                                              ; 575d: 29 03       ).
    tay                                                                                 ; 575f: a8          .
    lda #0                                                                              ; 5760: a9 00       ..
    sta tune_note_repeat_per_channel,x                                                  ; 5762: 9d d3 56    ..V
    lda tune_note_durations_table,y                                                     ; 5765: b9 ee 56    ..V
    tay                                                                                 ; 5768: a8          .
    pla                                                                                 ; 5769: 68          h
    and #$fc                                                                            ; 576a: 29 fc       ).
    ora #1                                                                              ; 576c: 09 01       ..
c576e
    pha                                                                                 ; 576e: 48          H
    lda tune_note_repeat_per_channel,x                                                  ; 576f: bd d3 56    ..V
    bne skip_increment_tune_position                                                    ; 5772: d0 03       ..
    inc tune_position_per_channel,x                                                     ; 5774: fe d0 56    ..V
skip_increment_tune_position
    pla                                                                                 ; 5777: 68          h
    ldx offset_to_sound                                                                 ; 5778: a6 8f       ..
    sta sound1_pitch,x                                                                  ; 577a: 9d bc 56    ..V
    tya                                                                                 ; 577d: 98          .
    sta sound1_duration,x                                                               ; 577e: 9d be 56    ..V
    txa                                                                                 ; 5781: 8a          .
    clc                                                                                 ; 5782: 18          .
    adc #<sound1                                                                        ; 5783: 69 b8       i.
    tax                                                                                 ; 5785: aa          .
    ldy #>sound1                                                                        ; 5786: a0 56       .V
    lda #osword_sound                                                                   ; 5788: a9 07       ..
    jsr osword                                                                          ; 578a: 20 f1 ff     ..            ; SOUND command
move_to_next_tune_channel
    inc sound_channel                                                                   ; 578d: e6 8e       ..
    ldx sound_channel                                                                   ; 578f: a6 8e       ..
    cpx #3                                                                              ; 5791: e0 03       ..
    bne update_channels_loop                                                            ; 5793: d0 82       ..
    rts                                                                                 ; 5795: 60          `

tile_below_store_row
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

unused80
    !byte   0,   0,   0,   0, $cb, $36,   5, $ff, $85, $18,   0,   0,   0, $85, $18     ; 57c3: 00 00 00... ...
    !byte   0,   0, $8f, $29, $80,   0,   0, $cb, $36,   5, $ff, $85, $18,   0,   0     ; 57d2: 00 00 8f... ...
    !byte   0, $c3, $36,   5, $ff, $82, $40,   0,   0,   0, $ef, $ff                    ; 57e1: 00 c3 36... ..6

big_rockford_destination_screen_address
pydis_end
!if ('A') != $41 {
    !error "Assertion failed: 'A' == $41"
}
!if ('B') != $42 {
    !error "Assertion failed: 'B' == $42"
}
!if ('S') != $53 {
    !error "Assertion failed: 'S' == $53"
}
!if ((map_unprocessed | map_anim_state0) | map_butterfly) != $8e {
    !error "Assertion failed: (map_unprocessed | map_anim_state0) | map_butterfly == $8e"
}
!if ((map_unprocessed | map_anim_state0) | map_firefly) != $86 {
    !error "Assertion failed: (map_unprocessed | map_anim_state0) | map_firefly == $86"
}
!if ((map_unprocessed | map_anim_state1) | map_butterfly) != $9e {
    !error "Assertion failed: (map_unprocessed | map_anim_state1) | map_butterfly == $9e"
}
!if ((map_unprocessed | map_anim_state1) | map_firefly) != $96 {
    !error "Assertion failed: (map_unprocessed | map_anim_state1) | map_firefly == $96"
}
!if ((map_unprocessed | map_anim_state1) | map_wall) != $92 {
    !error "Assertion failed: (map_unprocessed | map_anim_state1) | map_wall == $92"
}
!if ((map_unprocessed | map_anim_state2) | map_butterfly) != $ae {
    !error "Assertion failed: (map_unprocessed | map_anim_state2) | map_butterfly == $ae"
}
!if ((map_unprocessed | map_anim_state2) | map_firefly) != $a6 {
    !error "Assertion failed: (map_unprocessed | map_anim_state2) | map_firefly == $a6"
}
!if ((map_unprocessed | map_anim_state3) | map_butterfly) != $be {
    !error "Assertion failed: (map_unprocessed | map_anim_state3) | map_butterfly == $be"
}
!if ((map_unprocessed | map_anim_state3) | map_firefly) != $b6 {
    !error "Assertion failed: (map_unprocessed | map_anim_state3) | map_firefly == $b6"
}
!if (16*(sprite_rockford_blinking1-0x20) + sprite_rockford_blinking1-0x20) != $00 {
    !error "Assertion failed: 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_blinking1-0x20 == $00"
}
!if (16*(sprite_rockford_blinking1-0x20) + sprite_rockford_blinking2-0x20) != $01 {
    !error "Assertion failed: 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_blinking2-0x20 == $01"
}
!if (16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot1-0x20) != $05 {
    !error "Assertion failed: 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot1-0x20 == $05"
}
!if (16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot2-0x20) != $06 {
    !error "Assertion failed: 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot2-0x20 == $06"
}
!if (16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot4-0x20) != $08 {
    !error "Assertion failed: 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot4-0x20 == $08"
}
!if (16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot5-0x20) != $09 {
    !error "Assertion failed: 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot5-0x20 == $09"
}
!if (16*(sprite_rockford_blinking2-0x20) + sprite_rockford_blinking2-0x20) != $11 {
    !error "Assertion failed: 16*(sprite_rockford_blinking2-0x20) + sprite_rockford_blinking2-0x20 == $11"
}
!if (16*(sprite_rockford_blinking2-0x20) + sprite_rockford_tapping_foot2-0x20) != $16 {
    !error "Assertion failed: 16*(sprite_rockford_blinking2-0x20) + sprite_rockford_tapping_foot2-0x20 == $16"
}
!if (16*(sprite_rockford_blinking2-0x20) + sprite_rockford_tapping_foot5-0x20) != $19 {
    !error "Assertion failed: 16*(sprite_rockford_blinking2-0x20) + sprite_rockford_tapping_foot5-0x20 == $19"
}
!if (16*(sprite_rockford_blinking3-0x20) + sprite_rockford_blinking3-0x20) != $22 {
    !error "Assertion failed: 16*(sprite_rockford_blinking3-0x20) + sprite_rockford_blinking3-0x20 == $22"
}
!if (16*(sprite_rockford_blinking3-0x20) + sprite_rockford_tapping_foot1-0x20) != $25 {
    !error "Assertion failed: 16*(sprite_rockford_blinking3-0x20) + sprite_rockford_tapping_foot1-0x20 == $25"
}
!if (16*(sprite_rockford_blinking3-0x20) + sprite_rockford_tapping_foot3-0x20) != $27 {
    !error "Assertion failed: 16*(sprite_rockford_blinking3-0x20) + sprite_rockford_tapping_foot3-0x20 == $27"
}
!if (16*(sprite_rockford_blinking3-0x20) + sprite_rockford_tapping_foot4-0x20) != $28 {
    !error "Assertion failed: 16*(sprite_rockford_blinking3-0x20) + sprite_rockford_tapping_foot4-0x20 == $28"
}
!if (16*(sprite_rockford_tapping_foot1-0x20) + sprite_rockford_blinking1-0x20) != $50 {
    !error "Assertion failed: 16*(sprite_rockford_tapping_foot1-0x20) + sprite_rockford_blinking1-0x20 == $50"
}
!if (16*(sprite_rockford_tapping_foot1-0x20) + sprite_rockford_blinking3-0x20) != $52 {
    !error "Assertion failed: 16*(sprite_rockford_tapping_foot1-0x20) + sprite_rockford_blinking3-0x20 == $52"
}
!if (16*(sprite_rockford_tapping_foot1-0x20) + sprite_rockford_tapping_foot1-0x20) != $55 {
    !error "Assertion failed: 16*(sprite_rockford_tapping_foot1-0x20) + sprite_rockford_tapping_foot1-0x20 == $55"
}
!if (16*(sprite_rockford_tapping_foot1-0x20) + sprite_rockford_tapping_foot5-0x20) != $59 {
    !error "Assertion failed: 16*(sprite_rockford_tapping_foot1-0x20) + sprite_rockford_tapping_foot5-0x20 == $59"
}
!if (16*(sprite_rockford_tapping_foot2-0x20) + sprite_rockford_blinking1-0x20) != $60 {
    !error "Assertion failed: 16*(sprite_rockford_tapping_foot2-0x20) + sprite_rockford_blinking1-0x20 == $60"
}
!if (16*(sprite_rockford_tapping_foot2-0x20) + sprite_rockford_blinking2-0x20) != $61 {
    !error "Assertion failed: 16*(sprite_rockford_tapping_foot2-0x20) + sprite_rockford_blinking2-0x20 == $61"
}
!if (16*(sprite_rockford_tapping_foot2-0x20) + sprite_rockford_blinking3-0x20) != $62 {
    !error "Assertion failed: 16*(sprite_rockford_tapping_foot2-0x20) + sprite_rockford_blinking3-0x20 == $62"
}
!if (16*(sprite_rockford_tapping_foot2-0x20) + sprite_rockford_tapping_foot1-0x20) != $65 {
    !error "Assertion failed: 16*(sprite_rockford_tapping_foot2-0x20) + sprite_rockford_tapping_foot1-0x20 == $65"
}
!if (16*(sprite_rockford_tapping_foot3-0x20) + sprite_rockford_blinking1-0x20) != $70 {
    !error "Assertion failed: 16*(sprite_rockford_tapping_foot3-0x20) + sprite_rockford_blinking1-0x20 == $70"
}
!if (16*(sprite_rockford_tapping_foot3-0x20) + sprite_rockford_tapping_foot1-0x20) != $75 {
    !error "Assertion failed: 16*(sprite_rockford_tapping_foot3-0x20) + sprite_rockford_tapping_foot1-0x20 == $75"
}
!if (16*(sprite_rockford_tapping_foot3-0x20) + sprite_rockford_tapping_foot5-0x20) != $79 {
    !error "Assertion failed: 16*(sprite_rockford_tapping_foot3-0x20) + sprite_rockford_tapping_foot5-0x20 == $79"
}
!if (16*(sprite_rockford_tapping_foot4-0x20) + sprite_rockford_blinking1-0x20) != $80 {
    !error "Assertion failed: 16*(sprite_rockford_tapping_foot4-0x20) + sprite_rockford_blinking1-0x20 == $80"
}
!if (16*(sprite_rockford_tapping_foot4-0x20) + sprite_rockford_blinking2-0x20) != $81 {
    !error "Assertion failed: 16*(sprite_rockford_tapping_foot4-0x20) + sprite_rockford_blinking2-0x20 == $81"
}
!if (16*(sprite_rockford_tapping_foot5-0x20) + sprite_rockford_blinking1-0x20) != $90 {
    !error "Assertion failed: 16*(sprite_rockford_tapping_foot5-0x20) + sprite_rockford_blinking1-0x20 == $90"
}
!if (16*(sprite_rockford_tapping_foot5-0x20) + sprite_rockford_blinking2-0x20) != $91 {
    !error "Assertion failed: 16*(sprite_rockford_tapping_foot5-0x20) + sprite_rockford_blinking2-0x20 == $91"
}
!if (16*(sprite_rockford_tapping_foot5-0x20) + sprite_rockford_blinking3-0x20) != $92 {
    !error "Assertion failed: 16*(sprite_rockford_tapping_foot5-0x20) + sprite_rockford_blinking3-0x20 == $92"
}
!if (16*(sprite_rockford_tapping_foot5-0x20) + sprite_rockford_tapping_foot1-0x20) != $95 {
    !error "Assertion failed: 16*(sprite_rockford_tapping_foot5-0x20) + sprite_rockford_tapping_foot1-0x20 == $95"
}
!if (16*(sprite_rockford_winking1-0x20) + sprite_rockford_tapping_foot1-0x20) != $35 {
    !error "Assertion failed: 16*(sprite_rockford_winking1-0x20) + sprite_rockford_tapping_foot1-0x20 == $35"
}
!if (16*(sprite_rockford_winking1-0x20) + sprite_rockford_tapping_foot2-0x20) != $36 {
    !error "Assertion failed: 16*(sprite_rockford_winking1-0x20) + sprite_rockford_tapping_foot2-0x20 == $36"
}
!if (16*(sprite_rockford_winking2-0x20) + sprite_rockford_tapping_foot1-0x20) != $45 {
    !error "Assertion failed: 16*(sprite_rockford_winking2-0x20) + sprite_rockford_tapping_foot1-0x20 == $45"
}
!if (16*(sprite_rockford_winking2-0x20) + sprite_rockford_tapping_foot3-0x20) != $47 {
    !error "Assertion failed: 16*(sprite_rockford_winking2-0x20) + sprite_rockford_tapping_foot3-0x20 == $47"
}
!if (16*(sprite_rockford_winking2-0x20) + sprite_rockford_tapping_foot4-0x20) != $48 {
    !error "Assertion failed: 16*(sprite_rockford_winking2-0x20) + sprite_rockford_tapping_foot4-0x20 == $48"
}
!if (20*12) != $f0 {
    !error "Assertion failed: 20*12 == $f0"
}
!if (64-40) != $18 {
    !error "Assertion failed: 64-40 == $18"
}
!if (<(in_game_sound_block)) != $24 {
    !error <(in_game_sound_block)
    !error "Assertion failed: <(in_game_sound_block) == $24"
}
!if (<(palette_block)) != $29 {
    !error "Assertion failed: <(palette_block) == $29"
}
;!if (<(set_clock_value)) != $70 {
;    !error "Assertion failed: <(set_clock_value) == $70"
;}
!if (<(sprite_addr_space)) != $00 {
    !error "Assertion failed: <(sprite_addr_space) == $00"
}
!if (<(tile_map_row_1-1)) != $3f {
    !error <(tile_map_row_1-1)
    !error "Assertion failed: <(tile_map_row_1-1) == $3f"
}
!if (<big_rockford_destination_screen_address) != $00 {
    !error "Assertion failed: <big_rockford_destination_screen_address == $00"
}
!if (<bonus_life_text) != $64 {
    !error "Assertion failed: <bonus_life_text == $64"
}
;!if (<cell_types_that_will_turn_into_diamonds) != $30 {
;    !error "Assertion failed: <cell_types_that_will_turn_into_diamonds == $30"
;}
;!if (<cell_types_that_will_turn_into_large_explosion) != $40 {
;    !error "Assertion failed: <cell_types_that_will_turn_into_large_explosion == $40"
;}
!if (<current_status_bar_sprites) != $28 {
    !error "Assertion failed: <current_status_bar_sprites == $28"
}
!if (<demonstration_mode_text) != $a0 {
    !error "Assertion failed: <demonstration_mode_text == $a0"
}
!if (<game_over_text) != $8c {
    !error "Assertion failed: <game_over_text == $8c"
}
!if (<grid_of_currently_displayed_sprites) != $00 {
    !error "Assertion failed: <grid_of_currently_displayed_sprites == $00"
}
!if (<handler_slime) != $c0 {
    !error "Assertion failed: <handler_slime == $c0"
}
!if (<highscore_for_player_2) != $5e {
    !error "Assertion failed: <highscore_for_player_2 == $5e"
}
!if (<highscore_high_status_bar) != $50 {
    !error "Assertion failed: <highscore_high_status_bar == $50"
}
!if (<number_of_players_status_bar) != $78 {
    !error "Assertion failed: <number_of_players_status_bar == $78"
}
!if (<out_of_time_message) != $b4 {
    !error "Assertion failed: <out_of_time_message == $b4"
}
!if (<pause_message) != $c8 {
    !error "Assertion failed: <pause_message == $c8"
}
!if (<players_and_men_status_bar) != $14 {
    !error "Assertion failed: <players_and_men_status_bar == $14"
}
!if (<regular_status_bar) != $00 {
    !error "Assertion failed: <regular_status_bar == $00"
}
!if (<score_last_status_bar) != $dc {
    !error "Assertion failed: <score_last_status_bar == $dc"
}
!if (<screen_addr_row_28) != $00 {
    !error "Assertion failed: <screen_addr_row_28 == $00"
}
!if (<screen_addr_row_30) != $80 {
    !error "Assertion failed: <screen_addr_row_30 == $80"
}
!if (<screen_addr_row_6) != $80 {
    !error "Assertion failed: <screen_addr_row_6 == $80"
}
!if (<sound1) != $b8 {
    !error "Assertion failed: <sound1 == $b8"
}
!if (<sprite_addr_0) != $40 {
    !error "Assertion failed: <sprite_addr_0 == $40"
}
!if (<sprite_addr_1) != $60 {
    !error "Assertion failed: <sprite_addr_1 == $60"
}
!if (<sprite_addr_2) != $80 {
    !error "Assertion failed: <sprite_addr_2 == $80"
}
!if (<sprite_addr_3) != $a0 {
    !error "Assertion failed: <sprite_addr_3 == $a0"
}
!if (<sprite_addr_4) != $c0 {
    !error "Assertion failed: <sprite_addr_4 == $c0"
}
!if (<sprite_addr_5) != $e0 {
    !error "Assertion failed: <sprite_addr_5 == $e0"
}
!if (<sprite_addr_6) != $00 {
    !error "Assertion failed: <sprite_addr_6 == $00"
}
!if (<sprite_addr_7) != $20 {
    !error "Assertion failed: <sprite_addr_7 == $20"
}
!if (<sprite_addr_8) != $40 {
    !error "Assertion failed: <sprite_addr_8 == $40"
}
!if (<sprite_addr_9) != $60 {
    !error "Assertion failed: <sprite_addr_9 == $60"
}
!if (<sprite_addr_A) != $20 {
    !error "Assertion failed: <sprite_addr_A == $20"
}
!if (<sprite_addr_B) != $40 {
    !error "Assertion failed: <sprite_addr_B == $40"
}
!if (<sprite_addr_C) != $60 {
    !error "Assertion failed: <sprite_addr_C == $60"
}
!if (<sprite_addr_D) != $80 {
    !error "Assertion failed: <sprite_addr_D == $80"
}
!if (<sprite_addr_E) != $a0 {
    !error "Assertion failed: <sprite_addr_E == $a0"
}
!if (<sprite_addr_F) != $c0 {
    !error "Assertion failed: <sprite_addr_F == $c0"
}
!if (<sprite_addr_G) != $e0 {
    !error "Assertion failed: <sprite_addr_G == $e0"
}
!if (<sprite_addr_H) != $00 {
    !error "Assertion failed: <sprite_addr_H == $00"
}
!if (<sprite_addr_I) != $20 {
    !error "Assertion failed: <sprite_addr_I == $20"
}
!if (<sprite_addr_J) != $40 {
    !error "Assertion failed: <sprite_addr_J == $40"
}
!if (<sprite_addr_K) != $60 {
    !error "Assertion failed: <sprite_addr_K == $60"
}
!if (<sprite_addr_L) != $80 {
    !error "Assertion failed: <sprite_addr_L == $80"
}
!if (<sprite_addr_M) != $a0 {
    !error "Assertion failed: <sprite_addr_M == $a0"
}
!if (<sprite_addr_N) != $c0 {
    !error "Assertion failed: <sprite_addr_N == $c0"
}
!if (<sprite_addr_O) != $e0 {
    !error "Assertion failed: <sprite_addr_O == $e0"
}
!if (<sprite_addr_P) != $00 {
    !error "Assertion failed: <sprite_addr_P == $00"
}
!if (<sprite_addr_Q) != $20 {
    !error "Assertion failed: <sprite_addr_Q == $20"
}
!if (<sprite_addr_R) != $40 {
    !error "Assertion failed: <sprite_addr_R == $40"
}
!if (<sprite_addr_S) != $60 {
    !error "Assertion failed: <sprite_addr_S == $60"
}
!if (<sprite_addr_T) != $80 {
    !error "Assertion failed: <sprite_addr_T == $80"
}
!if (<sprite_addr_U) != $a0 {
    !error "Assertion failed: <sprite_addr_U == $a0"
}
!if (<sprite_addr_V) != $c0 {
    !error "Assertion failed: <sprite_addr_V == $c0"
}
!if (<sprite_addr_W) != $e0 {
    !error "Assertion failed: <sprite_addr_W == $e0"
}
!if (<sprite_addr_X) != $00 {
    !error "Assertion failed: <sprite_addr_X == $00"
}
!if (<sprite_addr_Y) != $20 {
    !error "Assertion failed: <sprite_addr_Y == $20"
}
!if (<sprite_addr_Z) != $40 {
    !error "Assertion failed: <sprite_addr_Z == $40"
}
!if (<sprite_addr_boulder1) != $20 {
    !error "Assertion failed: <sprite_addr_boulder1 == $20"
}
!if (<sprite_addr_boulder2) != $40 {
    !error "Assertion failed: <sprite_addr_boulder2 == $40"
}
!if (<sprite_addr_box) != $20 {
    !error "Assertion failed: <sprite_addr_box == $20"
}
!if (<sprite_addr_butterfly1) != $c0 {
    !error "Assertion failed: <sprite_addr_butterfly1 == $c0"
}
!if (<sprite_addr_butterfly2) != $e0 {
    !error "Assertion failed: <sprite_addr_butterfly2 == $e0"
}
!if (<sprite_addr_butterfly3) != $00 {
    !error "Assertion failed: <sprite_addr_butterfly3 == $00"
}
!if (<sprite_addr_comma) != $e0 {
    !error "Assertion failed: <sprite_addr_comma == $e0"
}
!if (<sprite_addr_dash) != $a0 {
    !error "Assertion failed: <sprite_addr_dash == $a0"
}
!if (<sprite_addr_diamond1) != $60 {
    !error "Assertion failed: <sprite_addr_diamond1 == $60"
}
!if (<sprite_addr_diamond2) != $80 {
    !error "Assertion failed: <sprite_addr_diamond2 == $80"
}
!if (<sprite_addr_diamond3) != $a0 {
    !error "Assertion failed: <sprite_addr_diamond3 == $a0"
}
!if (<sprite_addr_diamond4) != $c0 {
    !error "Assertion failed: <sprite_addr_diamond4 == $c0"
}
!if (<sprite_addr_earth1) != $a0 {
    !error "Assertion failed: <sprite_addr_earth1 == $a0"
}
!if (<sprite_addr_earth2) != $c0 {
    !error "Assertion failed: <sprite_addr_earth2 == $c0"
}
!if (<sprite_addr_explosion1) != $80 {
    !error "Assertion failed: <sprite_addr_explosion1 == $80"
}
!if (<sprite_addr_explosion2) != $a0 {
    !error "Assertion failed: <sprite_addr_explosion2 == $a0"
}
!if (<sprite_addr_explosion3) != $c0 {
    !error "Assertion failed: <sprite_addr_explosion3 == $c0"
}
!if (<sprite_addr_explosion4) != $e0 {
    !error "Assertion failed: <sprite_addr_explosion4 == $e0"
}
!if (<sprite_addr_firefly1) != $20 {
    !error "Assertion failed: <sprite_addr_firefly1 == $20"
}
!if (<sprite_addr_firefly2) != $40 {
    !error "Assertion failed: <sprite_addr_firefly2 == $40"
}
!if (<sprite_addr_firefly3) != $60 {
    !error "Assertion failed: <sprite_addr_firefly3 == $60"
}
!if (<sprite_addr_firefly4) != $80 {
    !error "Assertion failed: <sprite_addr_firefly4 == $80"
}
!if (<sprite_addr_full_stop) != $00 {
    !error "Assertion failed: <sprite_addr_full_stop == $00"
}
!if (<sprite_addr_amoeba1) != $80 {
    !error "Assertion failed: <sprite_addr_amoeba1 == $80"
}
!if (<sprite_addr_amoeba2) != $a0 {
    !error "Assertion failed: <sprite_addr_amoeba2 == $a0"
}
!if (<sprite_addr_magic_wall1) != $00 {
    !error "Assertion failed: <sprite_addr_magic_wall1 == $00"
}
!if (<sprite_addr_magic_wall2) != $20 {
    !error "Assertion failed: <sprite_addr_magic_wall2 == $20"
}
!if (<sprite_addr_magic_wall3) != $40 {
    !error "Assertion failed: <sprite_addr_magic_wall3 == $40"
}
!if (<sprite_addr_magic_wall4) != $60 {
    !error "Assertion failed: <sprite_addr_magic_wall4 == $60"
}
!if (<sprite_addr_pathway) != $e0 {
    !error "Assertion failed: <sprite_addr_pathway == $e0"
}
!if (<sprite_addr_rockford_blinking1) != $00 {
    !error "Assertion failed: <sprite_addr_rockford_blinking1 == $00"
}
!if (<sprite_addr_rockford_blinking2) != $20 {
    !error "Assertion failed: <sprite_addr_rockford_blinking2 == $20"
}
!if (<sprite_addr_rockford_blinking3) != $40 {
    !error "Assertion failed: <sprite_addr_rockford_blinking3 == $40"
}
!if (<sprite_addr_rockford_moving_down1) != $a0 {
    !error "Assertion failed: <sprite_addr_rockford_moving_down1 == $a0"
}
!if (<sprite_addr_rockford_moving_down2) != $c0 {
    !error "Assertion failed: <sprite_addr_rockford_moving_down2 == $c0"
}
!if (<sprite_addr_rockford_moving_down3) != $e0 {
    !error "Assertion failed: <sprite_addr_rockford_moving_down3 == $e0"
}
!if (<sprite_addr_rockford_moving_left1) != $40 {
    !error "Assertion failed: <sprite_addr_rockford_moving_left1 == $40"
}
!if (<sprite_addr_rockford_moving_left2) != $60 {
    !error "Assertion failed: <sprite_addr_rockford_moving_left2 == $60"
}
!if (<sprite_addr_rockford_moving_left3) != $80 {
    !error "Assertion failed: <sprite_addr_rockford_moving_left3 == $80"
}
!if (<sprite_addr_rockford_moving_left4) != $a0 {
    !error "Assertion failed: <sprite_addr_rockford_moving_left4 == $a0"
}
!if (<sprite_addr_rockford_moving_right1) != $c0 {
    !error "Assertion failed: <sprite_addr_rockford_moving_right1 == $c0"
}
!if (<sprite_addr_rockford_moving_right2) != $e0 {
    !error "Assertion failed: <sprite_addr_rockford_moving_right2 == $e0"
}
!if (<sprite_addr_rockford_moving_right3) != $00 {
    !error "Assertion failed: <sprite_addr_rockford_moving_right3 == $00"
}
!if (<sprite_addr_rockford_moving_right4) != $20 {
    !error "Assertion failed: <sprite_addr_rockford_moving_right4 == $20"
}
!if (<sprite_addr_rockford_moving_up1) != $00 {
    !error "Assertion failed: <sprite_addr_rockford_moving_up1 == $00"
}
!if (<sprite_addr_rockford_moving_up2) != $20 {
    !error "Assertion failed: <sprite_addr_rockford_moving_up2 == $20"
}
!if (<sprite_addr_rockford_winking1) != $60 {
    !error "Assertion failed: <sprite_addr_rockford_winking1 == $60"
}
!if (<sprite_addr_rockford_winking2) != $80 {
    !error "Assertion failed: <sprite_addr_rockford_winking2 == $80"
}
!if (<sprite_addr_slash) != $c0 {
    !error "Assertion failed: <sprite_addr_slash == $c0"
}
!if (<sprite_addr_space) != $00 {
    !error "Assertion failed: <sprite_addr_space == $00"
}
!if (<sprite_addr_titanium_wall1) != $e0 {
    !error "Assertion failed: <sprite_addr_titanium_wall1 == $e0"
}
!if (<sprite_addr_titanium_wall2) != $00 {
    !error "Assertion failed: <sprite_addr_titanium_wall2 == $00"
}
!if (<sprite_addr_wall1) != $40 {
    !error "Assertion failed: <sprite_addr_wall1 == $40"
}
!if (<sprite_addr_wall2) != $60 {
    !error "Assertion failed: <sprite_addr_wall2 == $60"
}
!if (<sprite_addr_white) != $80 {
    !error "Assertion failed: <sprite_addr_white == $80"
}
!if (<start_of_grid_screen_address) != $c0 {
    !error "Assertion failed: <start_of_grid_screen_address == $c0"
}
!if (<tile_map_row_0) != $00 {
    !error "Assertion failed: <tile_map_row_0 == $00"
}
!if (<tile_map_row_1) != $40 {
    !error "Assertion failed: <tile_map_row_1 == $40"
}
!if (>(in_game_sound_block)) != $2c {
    !error "Assertion failed: >(in_game_sound_block) == $2c"
}
!if (>(palette_block)) != $2a {
    !error "Assertion failed: >(palette_block) == $2a"
}
;!if (>(set_clock_value)) != $1e {
;    !error "Assertion failed: >(set_clock_value) == $1e"
;}
!if (>(sprite_addr_space)) != $13 {
    !error "Assertion failed: >(sprite_addr_space) == $13"
}
!if (>(tile_map_row_1-1)) != $50 {
    !error "Assertion failed: >(tile_map_row_1-1) == $50"
}
!if (>big_rockford_destination_screen_address) != $58 {
    !error "Assertion failed: >big_rockford_destination_screen_address == $58"
}
!if (>big_rockford_sprite) != $34 {
    !error "Assertion failed: >big_rockford_sprite == $34"
}
!if (>current_status_bar_sprites) != $50 {
    !error "Assertion failed: >current_status_bar_sprites == $50"
}
!if (>grid_of_currently_displayed_sprites) != $0c {
    !error "Assertion failed: >grid_of_currently_displayed_sprites == $0c"
}
!if (>regular_status_bar) != $32 {
    !error "Assertion failed: >regular_status_bar == $32"
}
!if (>screen_addr_row_28) != $7b {
    !error "Assertion failed: >screen_addr_row_28 == $7b"
}
!if (>screen_addr_row_30) != $7d {
    !error "Assertion failed: >screen_addr_row_30 == $7d"
}
!if (>screen_addr_row_6) != $5f {
    !error "Assertion failed: >screen_addr_row_6 == $5f"
}
!if (>sound1) != $56 {
    !error "Assertion failed: >sound1 == $56"
}
!if (>sprite_addr_0) != $19 {
    !error "Assertion failed: >sprite_addr_0 == $19"
}
!if (>sprite_addr_1) != $19 {
    !error "Assertion failed: >sprite_addr_1 == $19"
}
!if (>sprite_addr_2) != $19 {
    !error "Assertion failed: >sprite_addr_2 == $19"
}
!if (>sprite_addr_3) != $19 {
    !error "Assertion failed: >sprite_addr_3 == $19"
}
!if (>sprite_addr_4) != $19 {
    !error "Assertion failed: >sprite_addr_4 == $19"
}
!if (>sprite_addr_5) != $19 {
    !error "Assertion failed: >sprite_addr_5 == $19"
}
!if (>sprite_addr_6) != $1a {
    !error "Assertion failed: >sprite_addr_6 == $1a"
}
!if (>sprite_addr_7) != $1a {
    !error "Assertion failed: >sprite_addr_7 == $1a"
}
!if (>sprite_addr_8) != $1a {
    !error "Assertion failed: >sprite_addr_8 == $1a"
}
!if (>sprite_addr_9) != $1a {
    !error "Assertion failed: >sprite_addr_9 == $1a"
}
!if (>sprite_addr_A) != $1b {
    !error "Assertion failed: >sprite_addr_A == $1b"
}
!if (>sprite_addr_B) != $1b {
    !error "Assertion failed: >sprite_addr_B == $1b"
}
!if (>sprite_addr_C) != $1b {
    !error "Assertion failed: >sprite_addr_C == $1b"
}
!if (>sprite_addr_D) != $1b {
    !error "Assertion failed: >sprite_addr_D == $1b"
}
!if (>sprite_addr_E) != $1b {
    !error "Assertion failed: >sprite_addr_E == $1b"
}
!if (>sprite_addr_F) != $1b {
    !error "Assertion failed: >sprite_addr_F == $1b"
}
!if (>sprite_addr_G) != $1b {
    !error "Assertion failed: >sprite_addr_G == $1b"
}
!if (>sprite_addr_H) != $1c {
    !error "Assertion failed: >sprite_addr_H == $1c"
}
!if (>sprite_addr_I) != $1c {
    !error "Assertion failed: >sprite_addr_I == $1c"
}
!if (>sprite_addr_J) != $1c {
    !error "Assertion failed: >sprite_addr_J == $1c"
}
!if (>sprite_addr_K) != $1c {
    !error "Assertion failed: >sprite_addr_K == $1c"
}
!if (>sprite_addr_L) != $1c {
    !error "Assertion failed: >sprite_addr_L == $1c"
}
!if (>sprite_addr_M) != $1c {
    !error "Assertion failed: >sprite_addr_M == $1c"
}
!if (>sprite_addr_N) != $1c {
    !error "Assertion failed: >sprite_addr_N == $1c"
}
!if (>sprite_addr_O) != $1c {
    !error "Assertion failed: >sprite_addr_O == $1c"
}
!if (>sprite_addr_P) != $1d {
    !error "Assertion failed: >sprite_addr_P == $1d"
}
!if (>sprite_addr_Q) != $1d {
    !error "Assertion failed: >sprite_addr_Q == $1d"
}
!if (>sprite_addr_R) != $1d {
    !error "Assertion failed: >sprite_addr_R == $1d"
}
!if (>sprite_addr_S) != $1d {
    !error "Assertion failed: >sprite_addr_S == $1d"
}
!if (>sprite_addr_T) != $1d {
    !error "Assertion failed: >sprite_addr_T == $1d"
}
!if (>sprite_addr_U) != $1d {
    !error "Assertion failed: >sprite_addr_U == $1d"
}
!if (>sprite_addr_V) != $1d {
    !error "Assertion failed: >sprite_addr_V == $1d"
}
!if (>sprite_addr_W) != $1d {
    !error "Assertion failed: >sprite_addr_W == $1d"
}
!if (>sprite_addr_X) != $1e {
    !error "Assertion failed: >sprite_addr_X == $1e"
}
!if (>sprite_addr_Y) != $1e {
    !error "Assertion failed: >sprite_addr_Y == $1e"
}
!if (>sprite_addr_Z) != $1e {
    !error "Assertion failed: >sprite_addr_Z == $1e"
}
!if (>sprite_addr_boulder1) != $13 {
    !error "Assertion failed: >sprite_addr_boulder1 == $13"
}
!if (>sprite_addr_boulder2) != $13 {
    !error "Assertion failed: >sprite_addr_boulder2 == $13"
}
!if (>sprite_addr_box) != $14 {
    !error "Assertion failed: >sprite_addr_box == $14"
}
!if (>sprite_addr_butterfly1) != $15 {
    !error "Assertion failed: >sprite_addr_butterfly1 == $15"
}
!if (>sprite_addr_butterfly2) != $15 {
    !error "Assertion failed: >sprite_addr_butterfly2 == $15"
}
!if (>sprite_addr_butterfly3) != $16 {
    !error "Assertion failed: >sprite_addr_butterfly3 == $16"
}
!if (>sprite_addr_comma) != $1a {
    !error "Assertion failed: >sprite_addr_comma == $1a"
}
!if (>sprite_addr_dash) != $1a {
    !error "Assertion failed: >sprite_addr_dash == $1a"
}
!if (>sprite_addr_diamond1) != $13 {
    !error "Assertion failed: >sprite_addr_diamond1 == $13"
}
!if (>sprite_addr_diamond2) != $13 {
    !error "Assertion failed: >sprite_addr_diamond2 == $13"
}
!if (>sprite_addr_diamond3) != $13 {
    !error "Assertion failed: >sprite_addr_diamond3 == $13"
}
!if (>sprite_addr_diamond4) != $13 {
    !error "Assertion failed: >sprite_addr_diamond4 == $13"
}
!if (>sprite_addr_earth1) != $16 {
    !error "Assertion failed: >sprite_addr_earth1 == $16"
}
!if (>sprite_addr_earth2) != $16 {
    !error "Assertion failed: >sprite_addr_earth2 == $16"
}
!if (>sprite_addr_explosion1) != $14 {
    !error "Assertion failed: >sprite_addr_explosion1 == $14"
}
!if (>sprite_addr_explosion2) != $14 {
    !error "Assertion failed: >sprite_addr_explosion2 == $14"
}
!if (>sprite_addr_explosion3) != $14 {
    !error "Assertion failed: >sprite_addr_explosion3 == $14"
}
!if (>sprite_addr_explosion4) != $14 {
    !error "Assertion failed: >sprite_addr_explosion4 == $14"
}
!if (>sprite_addr_firefly1) != $16 {
    !error "Assertion failed: >sprite_addr_firefly1 == $16"
}
!if (>sprite_addr_firefly2) != $16 {
    !error "Assertion failed: >sprite_addr_firefly2 == $16"
}
!if (>sprite_addr_firefly3) != $16 {
    !error "Assertion failed: >sprite_addr_firefly3 == $16"
}
!if (>sprite_addr_firefly4) != $16 {
    !error "Assertion failed: >sprite_addr_firefly4 == $16"
}
!if (>sprite_addr_full_stop) != $1b {
    !error "Assertion failed: >sprite_addr_full_stop == $1b"
}
!if (>sprite_addr_amoeba1) != $15 {
    !error "Assertion failed: >sprite_addr_amoeba1 == $15"
}
!if (>sprite_addr_amoeba2) != $15 {
    !error "Assertion failed: >sprite_addr_amoeba2 == $15"
}
!if (>sprite_addr_magic_wall1) != $15 {
    !error "Assertion failed: >sprite_addr_magic_wall1 == $15"
}
!if (>sprite_addr_magic_wall2) != $15 {
    !error "Assertion failed: >sprite_addr_magic_wall2 == $15"
}
!if (>sprite_addr_magic_wall3) != $15 {
    !error "Assertion failed: >sprite_addr_magic_wall3 == $15"
}
!if (>sprite_addr_magic_wall4) != $15 {
    !error "Assertion failed: >sprite_addr_magic_wall4 == $15"
}
!if (>sprite_addr_pathway) != $16 {
    !error "Assertion failed: >sprite_addr_pathway == $16"
}
!if (>sprite_addr_rockford_blinking1) != $17 {
    !error "Assertion failed: >sprite_addr_rockford_blinking1 == $17"
}
!if (>sprite_addr_rockford_blinking2) != $17 {
    !error "Assertion failed: >sprite_addr_rockford_blinking2 == $17"
}
!if (>sprite_addr_rockford_blinking3) != $17 {
    !error "Assertion failed: >sprite_addr_rockford_blinking3 == $17"
}
!if (>sprite_addr_rockford_moving_down1) != $17 {
    !error "Assertion failed: >sprite_addr_rockford_moving_down1 == $17"
}
!if (>sprite_addr_rockford_moving_down2) != $17 {
    !error "Assertion failed: >sprite_addr_rockford_moving_down2 == $17"
}
!if (>sprite_addr_rockford_moving_down3) != $17 {
    !error "Assertion failed: >sprite_addr_rockford_moving_down3 == $17"
}
!if (>sprite_addr_rockford_moving_left1) != $18 {
    !error "Assertion failed: >sprite_addr_rockford_moving_left1 == $18"
}
!if (>sprite_addr_rockford_moving_left2) != $18 {
    !error "Assertion failed: >sprite_addr_rockford_moving_left2 == $18"
}
!if (>sprite_addr_rockford_moving_left3) != $18 {
    !error "Assertion failed: >sprite_addr_rockford_moving_left3 == $18"
}
!if (>sprite_addr_rockford_moving_left4) != $18 {
    !error "Assertion failed: >sprite_addr_rockford_moving_left4 == $18"
}
!if (>sprite_addr_rockford_moving_right1) != $18 {
    !error "Assertion failed: >sprite_addr_rockford_moving_right1 == $18"
}
!if (>sprite_addr_rockford_moving_right2) != $18 {
    !error "Assertion failed: >sprite_addr_rockford_moving_right2 == $18"
}
!if (>sprite_addr_rockford_moving_right3) != $19 {
    !error "Assertion failed: >sprite_addr_rockford_moving_right3 == $19"
}
!if (>sprite_addr_rockford_moving_right4) != $19 {
    !error "Assertion failed: >sprite_addr_rockford_moving_right4 == $19"
}
!if (>sprite_addr_rockford_moving_up1) != $18 {
    !error "Assertion failed: >sprite_addr_rockford_moving_up1 == $18"
}
!if (>sprite_addr_rockford_moving_up2) != $18 {
    !error "Assertion failed: >sprite_addr_rockford_moving_up2 == $18"
}
!if (>sprite_addr_rockford_winking1) != $17 {
    !error "Assertion failed: >sprite_addr_rockford_winking1 == $17"
}
!if (>sprite_addr_rockford_winking2) != $17 {
    !error "Assertion failed: >sprite_addr_rockford_winking2 == $17"
}
!if (>sprite_addr_slash) != $1a {
    !error "Assertion failed: >sprite_addr_slash == $1a"
}
!if (>sprite_addr_space) != $13 {
    !error "Assertion failed: >sprite_addr_space == $13"
}
!if (>sprite_addr_titanium_wall1) != $13 {
    !error "Assertion failed: >sprite_addr_titanium_wall1 == $13"
}
!if (>sprite_addr_titanium_wall2) != $14 {
    !error "Assertion failed: >sprite_addr_titanium_wall2 == $14"
}
!if (>sprite_addr_wall1) != $14 {
    !error "Assertion failed: >sprite_addr_wall1 == $14"
}
!if (>sprite_addr_wall2) != $14 {
    !error "Assertion failed: >sprite_addr_wall2 == $14"
}
!if (>sprite_addr_white) != $1a {
    !error "Assertion failed: >sprite_addr_white == $1a"
}
!if (>start_of_grid_screen_address) != $5b {
    !error "Assertion failed: >start_of_grid_screen_address == $5b"
}
!if (>tile_map_row_0) != $50 {
    !error "Assertion failed: >tile_map_row_0 == $50"
}
!if (>tile_map_row_1) != $50 {
    !error "Assertion failed: >tile_map_row_1 == $50"
}
!if (cell_above) != $74 {
    !error "Assertion failed: cell_above == $74"
}
!if (cell_above_left-1) != $72 {
    !error "Assertion failed: cell_above_left-1 == $72"
}
!if (cell_below) != $7a {
    !error "Assertion failed: cell_below == $7a"
}
!if (cell_left) != $76 {
    !error "Assertion failed: cell_left == $76"
}
!if (cell_right) != $78 {
    !error "Assertion failed: cell_right == $78"
}
!if (command_note_durations - 200) != $5614 {
    !error "Assertion failed: command_note_durations - 200 == $5614"
}
!if (command_note_repeat_counts-200) != $561a {
    !error "Assertion failed: command_note_repeat_counts-200 == $561a"
}
!if (command_pitch-200) != $560e {
    !error "Assertion failed: command_pitch-200 == $560e"
}
;!if (handler_table_high+12) != $21dc {
;    !error "Assertion failed: handler_table_high+12 == $21dc"
;}
!if (in_game_sound_data+1) != $2c01 {
    !error "Assertion failed: in_game_sound_data+1 == $2c01"
}
!if (in_game_sound_data+2) != $2c02 {
    !error "Assertion failed: in_game_sound_data+2 == $2c02"
}
!if (in_game_sound_data+3) != $2c03 {
    !error "Assertion failed: in_game_sound_data+3 == $2c03"
}
;!if (initial_values_of_variables_from_0x50) != $1e60 {
;    !error "Assertion failed: initial_values_of_variables_from_0x50 == $1e60"
;}
!if (inkey_key_b) != $9b {
    !error "Assertion failed: inkey_key_b == $9b"
}
!if (inkey_key_colon) != $b7 {
    !error "Assertion failed: inkey_key_colon == $b7"
}
!if (inkey_key_escape) != $8f {
    !error "Assertion failed: inkey_key_escape == $8f"
}
!if (inkey_key_return) != $b6 {
    !error "Assertion failed: inkey_key_return == $b6"
}
!if (inkey_key_slash) != $97 {
    !error "Assertion failed: inkey_key_slash == $97"
}
!if (inkey_key_space) != $9d {
    !error "Assertion failed: inkey_key_space == $9d"
}
!if (inkey_key_x) != $bd {
    !error "Assertion failed: inkey_key_x == $bd"
}
!if (inkey_key_z) != $9e {
    !error "Assertion failed: inkey_key_z == $9e"
}
!if (map_active_exit) != $18 {
    !error "Assertion failed: map_active_exit == $18"
}
!if (map_anim_state1 | map_butterfly) != $1e {
    !error "Assertion failed: map_anim_state1 | map_butterfly == $1e"
}
!if (map_anim_state1 | map_firefly) != $16 {
    !error "Assertion failed: map_anim_state1 | map_firefly == $16"
}
!if (map_anim_state1 | map_magic_wall) != $1d {
    !error "Assertion failed: map_anim_state1 | map_magic_wall == $1d"
}
!if (map_anim_state1 | map_rockford) != $1f {
    !error "Assertion failed: map_anim_state1 | map_rockford == $1f"
}
!if (map_anim_state2 | map_butterfly) != $2e {
    !error "Assertion failed: map_anim_state2 | map_butterfly == $2e"
}
!if (map_anim_state2 | map_firefly) != $26 {
    !error "Assertion failed: map_anim_state2 | map_firefly == $26"
}
!if (map_anim_state2 | map_rockford) != $2f {
    !error "Assertion failed: map_anim_state2 | map_rockford == $2f"
}
!if (map_anim_state3 | map_butterfly) != $3e {
    !error "Assertion failed: map_anim_state3 | map_butterfly == $3e"
}
!if (map_anim_state3 | map_firefly) != $36 {
    !error "Assertion failed: map_anim_state3 | map_firefly == $36"
}
!if (map_anim_state3 | map_magic_wall) != $3d {
    !error "Assertion failed: map_anim_state3 | map_magic_wall == $3d"
}
!if (map_anim_state4 | map_butterfly) != $4e {
    !error "Assertion failed: map_anim_state4 | map_butterfly == $4e"
}
!if (map_anim_state4 | map_diamond) != $44 {
    !error "Assertion failed: map_anim_state4 | map_diamond == $44"
}
!if (map_anim_state7 | map_magic_wall) != $7d {
    !error "Assertion failed: map_anim_state7 | map_magic_wall == $7d"
}
!if (map_anim_state7 | map_rockford) != $7f {
    !error "Assertion failed: map_anim_state7 | map_rockford == $7f"
}
!if (map_butterfly) != $0e {
    !error "Assertion failed: map_butterfly == $0e"
}
!if (map_butterfly | map_anim_state2) != $2e {
    !error "Assertion failed: map_butterfly | map_anim_state2 == $2e"
}
!if (map_deadly) != $c0 {
    !error "Assertion failed: map_deadly == $c0"
}
!if (map_diamond) != $04 {
    !error "Assertion failed: map_diamond == $04"
}
!if (map_diamond | map_unprocessed) != $84 {
    !error "Assertion failed: map_diamond | map_unprocessed == $84"
}
!if (map_earth) != $01 {
    !error "Assertion failed: map_earth == $01"
}
!if (map_firefly) != $06 {
    !error "Assertion failed: map_firefly == $06"
}
!if (map_slime) != $09 {
    !error "Assertion failed: map_slime == $09"
}
!if (map_rockford) != $0f {
    !error "Assertion failed: map_rockford == $0f"
}
!if (map_rockford | map_unprocessed) != $8f {
    !error "Assertion failed: map_rockford | map_unprocessed == $8f"
}
!if (map_rockford_appearing_or_end_position) != $08 {
    !error "Assertion failed: map_rockford_appearing_or_end_position == $08"
}
!if (map_space) != $00 {
    !error "Assertion failed: map_space == $00"
}
!if (map_start_large_explosion) != $46 {
    !error "Assertion failed: map_start_large_explosion == $46"
}
!if (map_unprocessed | map_diamond) != $84 {
    !error "Assertion failed: map_unprocessed | map_diamond == $84"
}
!if (map_unprocessed | map_large_explosion_state3) != $b3 {
    !error "Assertion failed: map_unprocessed | map_large_explosion_state3 == $b3"
}
!if (map_unprocessed | map_rock) != $85 {
    !error "Assertion failed: map_unprocessed | map_rock == $85"
}
!if (map_unprocessed | map_space) != $80 {
    !error "Assertion failed: map_unprocessed | map_space == $80"
}
!if (map_bomb) != $0b {
    !error "Assertion failed: map_bomb == $0b"
}
;!if (mark_cell_above_as_processed_and_move_to_next_cell - branch_instruction - 2) != $26 {
;    !error "Assertion failed: mark_cell_above_as_processed_and_move_to_next_cell - branch_instruction - 2 == $26"
;}
!if (opcode_dex) != $ca {
    !error "Assertion failed: opcode_dex == $ca"
}
!if (opcode_inx) != $e8 {
    !error "Assertion failed: opcode_inx == $e8"
}
!if (opcode_lda_abs_y) != $b9 {
    !error "Assertion failed: opcode_lda_abs_y == $b9"
}
!if (opcode_ldy_abs) != $ac {
    !error "Assertion failed: opcode_ldy_abs == $ac"
}
!if (osbyte_flush_buffer_class) != $0f {
    !error "Assertion failed: osbyte_flush_buffer_class == $0f"
}
!if (osbyte_inkey) != $81 {
    !error "Assertion failed: osbyte_inkey == $81"
}
!if (osbyte_read_adc_or_get_buffer_status) != $80 {
    !error "Assertion failed: osbyte_read_adc_or_get_buffer_status == $80"
}
!if (osword_read_clock) != $01 {
    !error "Assertion failed: osword_read_clock == $01"
}
!if (osword_sound) != $07 {
    !error "Assertion failed: osword_sound == $07"
}
!if (osword_write_clock) != $02 {
    !error "Assertion failed: osword_write_clock == $02"
}
!if (osword_write_palette) != $0c {
    !error "Assertion failed: osword_write_palette == $0c"
}
!if (sound0_active_flag) != $46 {
    !error "Assertion failed: sound0_active_flag == $46"
}
!if (sound5_active_flag) != $4b {
    !error "Assertion failed: sound5_active_flag == $4b"
}
!if (sprite_0) != $32 {
    !error "Assertion failed: sprite_0 == $32"
}
!if (sprite_1) != $33 {
    !error "Assertion failed: sprite_1 == $33"
}
!if (sprite_1 XOR sprite_2) != $07 {
    !error "Assertion failed: sprite_1 XOR sprite_2 == $07"
}
!if (sprite_2) != $34 {
    !error "Assertion failed: sprite_2 == $34"
}
!if (sprite_3) != $35 {
    !error "Assertion failed: sprite_3 == $35"
}
!if (sprite_4) != $36 {
    !error "Assertion failed: sprite_4 == $36"
}
!if (sprite_5) != $37 {
    !error "Assertion failed: sprite_5 == $37"
}
!if (sprite_6) != $38 {
    !error "Assertion failed: sprite_6 == $38"
}
!if (sprite_7) != $39 {
    !error "Assertion failed: sprite_7 == $39"
}
!if (sprite_8) != $3a {
    !error "Assertion failed: sprite_8 == $3a"
}
!if (sprite_9) != $3b {
    !error "Assertion failed: sprite_9 == $3b"
}
!if (sprite_boulder1) != $01 {
    !error "Assertion failed: sprite_boulder1 == $01"
}
!if (sprite_boulder2) != $02 {
    !error "Assertion failed: sprite_boulder2 == $02"
}
!if (sprite_box) != $09 {
    !error "Assertion failed: sprite_box == $09"
}
!if (sprite_butterfly1) != $16 {
    !error "Assertion failed: sprite_butterfly1 == $16"
}
!if (sprite_butterfly2) != $17 {
    !error "Assertion failed: sprite_butterfly2 == $17"
}
!if (sprite_comma) != $3f {
    !error "Assertion failed: sprite_comma == $3f"
}
!if (sprite_diamond1) != $03 {
    !error "Assertion failed: sprite_diamond1 == $03"
}
!if (sprite_diamond2) != $04 {
    !error "Assertion failed: sprite_diamond2 == $04"
}
!if (sprite_diamond3) != $05 {
    !error "Assertion failed: sprite_diamond3 == $05"
}
!if (sprite_diamond4) != $06 {
    !error "Assertion failed: sprite_diamond4 == $06"
}
!if (sprite_earth2) != $1e {
    !error "Assertion failed: sprite_earth2 == $1e"
}
!if (sprite_explosion1) != $0c {
    !error "Assertion failed: sprite_explosion1 == $0c"
}
!if (sprite_explosion2) != $0d {
    !error "Assertion failed: sprite_explosion2 == $0d"
}
!if (sprite_explosion3) != $0e {
    !error "Assertion failed: sprite_explosion3 == $0e"
}
!if (sprite_explosion4) != $0f {
    !error "Assertion failed: sprite_explosion4 == $0f"
}
!if (sprite_firefly2) != $1a {
    !error "Assertion failed: sprite_firefly2 == $1a"
}
!if (sprite_firefly4) != $1c {
    !error "Assertion failed: sprite_firefly4 == $1c"
}
!if (sprite_full_stop) != $40 {
    !error "Assertion failed: sprite_full_stop == $40"
}
!if (sprite_amoeba1) != $14 {
    !error "Assertion failed: sprite_amoeba1 == $14"
}
!if (sprite_amoeba2) != $15 {
    !error "Assertion failed: sprite_amoeba2 == $15"
}
!if (sprite_magic_wall1) != $10 {
    !error "Assertion failed: sprite_magic_wall1 == $10"
}
!if (sprite_magic_wall2) != $11 {
    !error "Assertion failed: sprite_magic_wall2 == $11"
}
!if (sprite_pathway) != $1f {
    !error "Assertion failed: sprite_pathway == $1f"
}
!if (sprite_rockford_blinking1) != $20 {
    !error "Assertion failed: sprite_rockford_blinking1 == $20"
}
!if (sprite_rockford_moving_left2) != $2b {
    !error "Assertion failed: sprite_rockford_moving_left2 == $2b"
}
!if (sprite_rockford_moving_left3) != $2c {
    !error "Assertion failed: sprite_rockford_moving_left3 == $2c"
}
!if (sprite_rockford_moving_right3) != $30 {
    !error "Assertion failed: sprite_rockford_moving_right3 == $30"
}
!if (sprite_rockford_moving_right4) != $31 {
    !error "Assertion failed: sprite_rockford_moving_right4 == $31"
}
!if (sprite_rockford_tapping_foot1) != $25 {
    !error "Assertion failed: sprite_rockford_tapping_foot1 == $25"
}
!if (sprite_rockford_tapping_foot4) != $28 {
    !error "Assertion failed: sprite_rockford_tapping_foot4 == $28"
}
!if (sprite_rockford_winking2) != $24 {
    !error "Assertion failed: sprite_rockford_winking2 == $24"
}
!if (sprite_slash) != $3e {
    !error "Assertion failed: sprite_slash == $3e"
}
!if (sprite_space) != $00 {
    !error "Assertion failed: sprite_space == $00"
}
!if (sprite_titanium_wall1) != $07 {
    !error "Assertion failed: sprite_titanium_wall1 == $07"
}
!if (sprite_titanium_wall2) != $08 {
    !error "Assertion failed: sprite_titanium_wall2 == $08"
}
!if (sprite_wall2) != $0b {
    !error "Assertion failed: sprite_wall2 == $0b"
}
!if (total_caves) != $14 {
    !error "Assertion failed: total_caves == $14"
}
;!if (update_rock_or_diamond_that_can_fall - branch_instruction - 2) != $5f {
;    !error "Assertion failed: update_rock_or_diamond_that_can_fall - branch_instruction - 2 == $5f"
;}
