; *************************************************************************************
; Boulder Dash version 2 by raspberrypioneer 2024
; Keyboard input precision fixes by TobyLobster Nov 2024
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
; Additions to support the Boulder Dash +1 game
;   - New bomb element and new zero-gravity behaviour introduced
;   - Bombs are set by Rockford by pressing return + direction in an empty cell. The bombs run
;     on a short timer and clear the surrounding tiles when they detonate (except for steel
;     walls, start/exit). They can be used to clear tiles, destroy butterflies, fireflies and
;     the amoeba. They are lethal to Rockford if standing too close! They fall just like rocks,
;     diamonds do, pausing the timer when this happens. They explode if something lands on them
;   - The number of bombs available to Rockford are defined in the cave parameters. Each time
;     Rockford uses a bomb, the number remaining is briefly shown in the status bar
;   - Zero-gravity behaviour means rocks, diamonds and bombs do not fall; they remain suspended
;     instead. Diamonds can still be collected and bombs used, but rocks turn into bubbles which
;     can be pushed around in all directions. Rocks switch to a transitional state when
;     zero-gravity is about to run out
;   - A cave parameter is used for this behaviour. For normal mode (with gravity) it is 0, for
;     continuous zero-gravity 255, and numbers between are a timer when zero-gravity is in effect
;   - For asthetics, the cave borders can now be changed. The cave side-borders defined in the
;     cave map are used now, previously being replaced with the steelwall border. The cave
;     top and bottom borders are not held in the cave map file but can now be defined by setting
;     the border tile cave parameter
;   - New caves have been created with these new features.
;   - These changes do not affect the Boulder Dash 1 or 2 game engines.
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
; Memory map
; grid_of_currently_displayed_sprites    $0c00 to $1300
; sprite definitions                     $1300 to $1f00
; program code and variables             $1f00 to 'end_of_vars' label address
; load area for group of 10 caves        $3e80 to $5000 (4480 bytes for 10 caves at 448 bytes each)
; tiles map (with variables)             $5000 to $5640 (25 rows at 64 bytes per row - 40 bytes used, 24 sometimes used)
; single cave used in game play          $5640 to $5800 (448 bytes, moved from load area when used in game play)
; hires screen                           $5800 to $8000 (Mode 5 layout)
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
option_left_edge = $40

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
temp_keys                               = $8e
offset_to_sound                         = $8f
keys_to_test                            = $8f


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
!source "spr.asm"
; *************************************************************************************
; Entry point for the start of the program
; IMPORTANT: Below is needed to point to the correct execution memory address
;
* = $1f00

;Select version to play
select_version_to_play
    ;Clear screen
    lda #<big_rockford_destination_screen_address  ;set screen memory as target
    sta screen_addr2_low  ;target low
    lda #>big_rockford_destination_screen_address
    sta screen_addr2_high  ;target high
    lda #$00  ;size is $8000 - $5800 = $2800 (hires screen size)
    sta clear_size  
    lda #$28
    sta clear_size+1
    lda #0  ;clear to 0
    sta clear_to
    jsr clear_memory  ;clear target for given size and value

    ;Plot each option using tables of data and screen addresses
    ldx #0
plot_version_option
    stx temp_keys
    lda #$ff
    jsr reset_status_bar
    ldx temp_keys
    lda version_option_text_high,x
    sta status_text_address_high
    lda version_option_text_low,x
    sta status_text_address_low
    ldy #option_left_edge
    lda version_option_screen_high,x
    jsr draw_single_row_of_sprites
    ldx temp_keys
    inx
    cpx #6
    bne plot_version_option

version_select_loop
    jsr wait_for_13_centiseconds_and_read_keys
    lda keys_to_process
    asl
    bcs version_option_down
    asl
    bcs version_option_up
    asl
    bcs version_option_up
    asl
    bcs version_option_down
    asl
    ;#bcs = enter key
    asl
    ;#bcs = "b" key
    asl
    bcs select_sprites_to_use  ;space key is pressed to use selected version
    jmp version_select_loop

version_option_up
    lda #sprite_space
    sta version_option_sprite_to_plot+1
    jsr plot_sprite_next_to_version_option

    dec bd_version_to_play
    lda bd_version_to_play
    bpl update_version_on_screen
    lda #5
    jmp update_version_on_screen

version_option_down
    lda #sprite_space
    sta version_option_sprite_to_plot+1
    jsr plot_sprite_next_to_version_option

    inc bd_version_to_play
    lda bd_version_to_play
    cmp #6
    bne update_version_on_screen
    lda #0
update_version_on_screen
    sta bd_version_to_play

    lda #sprite_rockford_blinking1
    sta version_option_sprite_to_plot+1
    jsr plot_sprite_next_to_version_option

    lda #$ff  ;reset last group and cave values to ensure load of new version caves
    sta load_group_stored
    sta load_cave_number_stored
    jmp version_select_loop

plot_sprite_next_to_version_option
    lda #$ff
    jsr reset_status_bar
    ldx bd_version_to_play
    lda version_option_text_high,x
    sta status_text_address_high
    sta screen_addr2_high
    lda version_option_text_low,x
    sta status_text_address_low
    sta screen_addr2_low
version_option_sprite_to_plot
    lda #sprite_rockford_blinking1
    ldy #1
    sta (screen_addr2_low),y
    ldy #option_left_edge
    lda version_option_screen_high,x
    jsr draw_single_row_of_sprites
    rts

;Select sprite set to use in game
select_sprites_to_use
    ;Plot each option using tables of data and screen addresses
    ldx #0
plot_sprites_option
    stx temp_keys
    lda #$ff
    jsr reset_status_bar
    ldx temp_keys
    lda sprite_text_high,x
    sta status_text_address_high
    lda sprite_text_low,x
    sta status_text_address_low
    ldy #option_left_edge
    lda sprites_on_screen_high,x
    jsr draw_single_row_of_sprites
    ldx temp_keys
    inx
    cpx #6
    bne plot_sprites_option

sprites_select_loop
    jsr wait_for_13_centiseconds_and_read_keys
    lda keys_to_process
    asl
    bcs sprites_option_down
    asl
    bcs sprites_option_up
    asl
    bcs sprites_option_up
    asl
    bcs sprites_option_down
    asl
    ;#bcs = enter key
    asl
    ;#bcs = "b" key
    asl
    bcs main_menu_loop  ;space key is pressed to start selected version with sprite set chosen
    jmp sprites_select_loop

sprites_option_up
    lda #sprite_space
    sta sprite_option_sprite_to_plot+1
    jsr plot_sprite_next_to_spriteset_option

    dec bd_sprites_to_use
    lda bd_sprites_to_use
    bpl update_spriteset_on_screen
    lda #5
    jmp update_spriteset_on_screen

sprites_option_down
    lda #sprite_space
    sta sprite_option_sprite_to_plot+1
    jsr plot_sprite_next_to_spriteset_option

    inc bd_sprites_to_use
    lda bd_sprites_to_use
    cmp #6
    bne update_spriteset_on_screen
    lda #0
update_spriteset_on_screen
    sta bd_sprites_to_use

    lda #sprite_rockford_blinking1
    sta sprite_option_sprite_to_plot+1
    jsr plot_sprite_next_to_spriteset_option

    lda #$ff  ;reset sprites set stored to ensure load of set
    sta sprite_set_stored
    jmp sprites_select_loop

plot_sprite_next_to_spriteset_option
    lda #$ff
    jsr reset_status_bar
    ldx bd_sprites_to_use
    lda sprite_text_high,x
    sta status_text_address_high
    sta screen_addr2_high
    lda sprite_text_low,x
    sta status_text_address_low
    sta screen_addr2_low
sprite_option_sprite_to_plot
    lda #sprite_rockford_blinking1
    ldy #1
    sta (screen_addr2_low),y
    ldy #option_left_edge
    lda sprites_on_screen_high,x
    jsr draw_single_row_of_sprites
    rts

;Standard game menu
main_menu_loop
    lda #>regular_status_bar
    sta status_text_address_high
    lda #<regular_status_bar
    sta status_text_address_low
    jsr show_menu

    ; show credits
    lda #>game_credits
    sta status_text_address_high
    lda #<game_credits
    sta status_text_address_low
show_credits_loop
    jsr draw_status_bar
    jsr wait_for_13_centiseconds_and_read_keys
    inc status_text_address_low
    lda status_text_address_low
    cmp #<end_of_credits-19
    bne show_credits_loop
    jmp main_menu_loop

; *************************************************************************************
increment_ptr_and_clear_carry
    inc ptr_low
    bne skip_increment
    inc ptr_high
skip_increment
    clc
    rts

; *************************************************************************************
add_a_to_ptr
    clc
    adc ptr_low
    sta ptr_low
    bcc return1
    inc ptr_high
return1
    rts

; *************************************************************************************
; a small 'pseudo-random' number routine. Generates a sequence of 256 numbers.
get_next_random_byte
    lda random_seed
    asl
    asl
    asl
    asl
    sec
    adc random_seed
    sta random_seed
    rts

; *************************************************************************************
reset_grid_of_sprites
    ldx #$f0
    lda #$ff
reset_grid_of_sprites_loop
    dex
    sta grid_of_currently_displayed_sprites,x
    bne reset_grid_of_sprites_loop

reset_status_bar  ; clear the current status bar
    ldx #$14
clear_status_bar_loop
    dex
    sta current_status_bar_sprites,x
    bne clear_status_bar_loop
    rts

; *************************************************************************************
handler_basics
    txa
    sec
    sbc #$90
    cmp #$10
    bpl not_in_range_so_change_nothing
    ; cell is in the range $90-$9f (corresponding to $10 to $1f with the top bit set),
    ; so we look up the replacement in a table. This is used to replace the final step
    ; of an explosion, either with rockford during the introduction (offset $01), or a
    ; space for the outro (death) explosion (offset $03)
    tax
    lda explosion_replacements,x
not_in_range_so_change_nothing
    tax
    rts

; *************************************************************************************
reveal_or_hide_more_cells
    ldy #<tile_map_row_0
    sty ptr_low
    lda #>tile_map_row_0
    sta ptr_high
    ; loop over all the rows, X is the loop counter
    ldx #22
loop_over_rows
    lda ptr_low
    ; rows are stored in the first 40 bytes of every 64 bytes, so skip if we have
    ; exceeded the right range
    and #63
    cmp #40
    bpl skip_to_next_row
    ; progress a counter in a non-obvious pattern
    jsr get_next_random_byte
    ; if it's early in the process (tick counter is low), then branch more often so we
    ; reveal/hide the cells in a non-obvious pattern over time
    lsr
    lsr
    lsr
    cmp tick_counter
    bne skip_reveal_or_hide
    lda (ptr_low),y
    ; clear the top bit to reveal the cell...
    and #$7f
    ; ...or set the top bit to hide the cell
    ora dissolve_to_solid_flag
    sta (ptr_low),y
skip_reveal_or_hide
    jsr increment_ptr_and_clear_carry
    bcc loop_over_rows
    ; move forward to next row. Each row is stored at 64 byte intervals. We have moved
    ; on 40 so far so add the remainder to get to the next row
skip_to_next_row
    lda #64-40
    jsr add_a_to_ptr
    dex
    bne loop_over_rows
    ; create some 'random' audio pitches to play while revealing/hiding the map. First
    ; multiply the data set pointer low byte by five and add one
    lda sound0_active_flag
    asl
    asl
    sec
    adc sound0_active_flag
    sta sound0_active_flag
    ; add the cave number
    ora cave_number
    ; just take some of the bits
    and #$9e
    ; use as the pitch
    tay
    iny
    ldx #$85
    jsr play_sound_x_pitch_y
    rts

; *************************************************************************************
; draw a full grid of sprites, updating the current map position first
draw_grid_of_sprites
    jsr update_map_scroll_position
    jsr update_grid_animations
    lda #>screen_addr_row_6
    sta screen_addr1_high
    ldy #<screen_addr_row_6
    lda #opcode_lda_abs_y
    sta load_instruction
    lda #<grid_of_currently_displayed_sprites
    sta grid_compare_address_low
    sta grid_write_address_low
    lda #>grid_of_currently_displayed_sprites
    sta grid_compare_address_high
    sta grid_write_address_high
    ; X = number of cells to draw: 12 rows of 20 cells each (a loop counter)
    ldx #20*12
    bne draw_grid

; *************************************************************************************
draw_status_bar
    ldy #<start_of_grid_screen_address
    lda #>start_of_grid_screen_address
draw_single_row_of_sprites
    sta screen_addr1_high
    lda #>current_status_bar_sprites
    ldx #<current_status_bar_sprites
    stx grid_compare_address_low
    stx grid_write_address_low
    sta grid_compare_address_high
    sta grid_write_address_high
instruction_for_self_modification
status_text_address_high = instruction_for_self_modification+1
    lda #>regular_status_bar
    sta tile_map_ptr_high
    lda #opcode_ldy_abs
    sta load_instruction
    ldx #20                             ; X is the cell counter (20 for a single row)
    lda status_text_address_low
    sta tile_map_ptr_low
draw_grid
    sty screen_addr1_low
draw_grid_loop
    ldy #0
    sty grid_column_counter
grid_draw_row_loop
    lda (tile_map_ptr_low),y
    tay
    bpl load_instruction
    ; Y=9 corresponds to the titanium wall sprite used while revealing the grid
    ldy #9
    ; this next instruction is either:
    ;     'ldy cell_type_to_sprite' which in this context is equivalent to a no-op,
    ; which is used during preprocessing OR
    ;     'lda cell_type_to_sprite,y'
    ; to convert the cell into a sprite (used during actual gameplay).
    ; Self-modifying code above sets which version is to be used.
load_instruction
    ldy cell_type_to_sprite
    dex
compare_instruction
grid_compare_address_low = compare_instruction+1
grid_compare_address_high = compare_instruction+2
    cmp current_status_bar_sprites,x
    beq skip_draw_sprite
write_instruction
grid_write_address_low = write_instruction+1
grid_write_address_high = write_instruction+2
    sta current_status_bar_sprites,x
    tay
    clc
    lda sprite_addresses_low,y
    sta ptr_low
    adc #$10
    sta next_ptr_low
    lda sprite_addresses_high,y
    sta ptr_high
    sta next_ptr_high
    ; Each sprite is two character rows tall. screen_addr2_low/high is the destination
    ; screen address for the second character row of the sprite
    lda screen_addr1_low
    adc #$40
    sta screen_addr2_low
    lda screen_addr1_high
    adc #1
    sta screen_addr2_high
    ; This next loop draws a single sprite in the grid.
    ; It draws two character rows at the same time, with 16 bytes in each row.
    ldy #$0f
draw_sprite_loop
    lda (ptr_low),y
    sta (screen_addr1_low),y
    lda (next_ptr_low),y
    sta (screen_addr2_low),y
    dey
    lda (ptr_low),y
    sta (screen_addr1_low),y
    lda (next_ptr_low),y
    sta (screen_addr2_low),y
    dey
    lda (ptr_low),y
    sta (screen_addr1_low),y
    lda (next_ptr_low),y
    sta (screen_addr2_low),y
    dey
    lda (ptr_low),y
    sta (screen_addr1_low),y
    lda (next_ptr_low),y
    sta (screen_addr2_low),y
    dey
    bpl draw_sprite_loop
    ; move the screen pointer on 16 pixels to next column
skip_draw_sprite
    clc
    lda screen_addr1_low
    adc #$10
    sta screen_addr1_low
    bcc skip_high_byte2
    inc screen_addr1_high
skip_high_byte2
    inc grid_column_counter
    ldy grid_column_counter
    cpy #20
    bne grid_draw_row_loop
    ; return if we have drawn all the rows (X=0)
    txa
    beq return2
    ; move screen pointer on to next row of sprites (two character rows)
    clc
    lda screen_addr1_low
    adc #$40
    sta screen_addr1_low
    lda screen_addr1_high
    adc #1
    sta screen_addr1_high
    
    lda tile_map_ptr_low
    adc #$40                            ; move tile pointer on to next row (64 bytes)
    sta tile_map_ptr_low
    lda tile_map_ptr_high
    adc #0
    sta tile_map_ptr_high
    jmp draw_grid_loop

return2
    rts

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
    ldy #update_rock_or_diamond_that_can_fall - branch_instruction - 2
    bne scan_map                        ; ALWAYS branch
    ldy #mark_cell_above_as_processed_and_move_to_next_cell - branch_instruction - 2
scan_map
    sty branch_offset
    lda #20                             ; twenty rows
    sta tile_y
    lda #>tile_map_row_0
    sta ptr_high
    lda #<tile_map_row_0
    sta ptr_low
    ; Each row is stored in the first 40 bytes of every 64 bytes. Here we set Y to
    ; start on the second row, after the titanium wall border
    ldy #$40
    ; loop through the twenty rows of map
tile_map_y_loop
    lda #38                             ; 38 columns (cells per row)
    sta tile_x
    lda (ptr_low),y
    sta cell_left
    ; move to the next cell
    iny
    ; read current cell contents into X
    lda (ptr_low),y
    tax
    ; loop through the 38 cells in a row of map
    ; read next cell contents into cell_right
tile_map_x_loop
    ldy #$42
    lda (ptr_low),y
    sta cell_right
    cpx #map_diamond
    bmi mark_cell_above_as_processed_and_move_to_next_cell

    ; read cells into cell_above and cell_below variables
    ldy #1
    lda (ptr_low),y
    sta cell_above
    ldy #$81
    lda (ptr_low),y
    sta cell_below

    ; if current cell is already processed (top bit set), then skip to next cell
    txa
    bmi mark_cell_above_as_processed_and_move_to_next_cell
    ; mark current cell as processed (set top bit)
    ora #$80
    tax
    ; the lower four bits are the type, each of which has a handler to process it
    and #$0f
    tay
    lda handler_table_high,y
    ; if we have no handler for this cell type then branch (destination was set
    ; depending on where we entered this routine)
branch_instruction
branch_offset = branch_instruction+1
    beq update_rock_or_diamond_that_can_fall
    sta handler_high
    lda handler_table_low,y
    sta handler_low
    ; call the handler for the cell based on the type (0-15)
jsr_handler_instruction
handler_low = jsr_handler_instruction+1
handler_high = jsr_handler_instruction+2
    jsr handler_firefly_or_butterfly
    ; the handler may have changed the surrounding cells, store the new cell below
    lda cell_below
    ldy #$81
    sta (ptr_low),y
    ; store the new cell above
    lda cell_above
    and #$7f
    ldy #1
    bpl move_to_next_cell               ; ALWAYS branch

; *************************************************************************************
;
; This is part of the preprocessing step prior to gameplay, when we find a space in the
; map
;
; *************************************************************************************
mark_cell_above_as_processed_and_move_to_next_cell
    ldy #1
    lda (ptr_low),y
    and #$7f
move_to_next_cell
    sta (ptr_low),y
    ; store the new cell left back into the map
    lda cell_left
    ldy #$40
    sta (ptr_low),y
    ; update cell_left with the current cell value (in X)
    stx cell_left
    ; update the current cell value x from the cell_right variable
    ldx cell_right
    ; move ptr to next position
    inc ptr_low
    ; loop back for the rest of the cells in the row
    dec tile_x
    bne tile_map_x_loop
    ; store the final previous_cell for the row
    lda cell_left
    sta (ptr_low),y
    ; move ptr to the start of the next row. Stride is 64, 38 entries done, so
    ; remainder to add is 64-38=26
    lda #26
    jsr add_a_to_ptr
    ; loop back for the rest of the rows
    dec tile_y
    bne tile_map_y_loop
    ; clear top bit in final row
    ldy #38
clear_top_bit_on_final_row_loop
    lda tile_map_row_20,y
    and #$7f
    sta tile_map_row_20,y
    dey
    bne clear_top_bit_on_final_row_loop
    ; clear top bit on end position
    lda (map_rockford_end_position_addr_low),y
    and #$7f
    sta (map_rockford_end_position_addr_low),y
    rts

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
    ldy #$81
    lda (ptr_low),y
    beq cell_below_is_a_space
    ; check current cell
    cpx #map_deadly
    bmi not_c0_or_above
    jsr process_c0_or_above
not_c0_or_above
    and #$4f
    tay
    asl
    bmi process_next_cell
    lda cell_types_that_rocks_or_diamonds_will_fall_off,y
    beq process_next_cell
    lda cell_left
    bne check_if_cell_right_is_empty
    ; cell left is empty, now check below left cell
    ldy #$80
    lda (ptr_low),y
    beq rock_or_diamond_can_fall_left_or_right
check_if_cell_right_is_empty
    lda cell_right
    bne process_next_cell
    ; cell right is empty, now check below right cell
    ldy #$82
    lda (ptr_low),y
    bne process_next_cell
    ; take the rock or diamond, and set bit 6 to indicate it has been moved this scan
    ; (so it won't be moved again). Then store it in the below left or below right cell
rock_or_diamond_can_fall_left_or_right
    txa
    ora #$40
    ; Store in either cell_below_left or cell_below_right depending on Y=$80 or $82,
    ; since $fff6 = cell_below_left - $80
    sta lfff6,y
    ; below left or right is set to $80, still a space, but marked as unprocessed
    lda #$80
    sta (ptr_low),y
set_to_unprocessed_space
    ldx #$80
    bne process_next_cell               ; ALWAYS branch

    ; take the rock or diamond, and set bit 6 to indicate it has been moved this scan
    ; (so it won't be moved again). Then store it in the cell below.
cell_below_is_a_space
    txa
    ora #$40
    sta (ptr_low),y
    bne set_to_unprocessed_space        ; ALWAYS branch

process_c0_or_above
    pha
    ; look up table based on type
    and #$0f
    tay
    lda update_cell_type_when_below_a_falling_rock_or_diamond,y
    beq play_rock_or_diamond_fall_sound
    ; store in cell below
    ldy #$81
    sta (ptr_low),y
play_rock_or_diamond_fall_sound
    txa
    and #1
    eor #sound5_active_flag
    tay
    ; store $4b or $4c (i.e. a non-zero value) in location $4b or $4c. i.e. activate
    ; sound5_active_flag or sound6_active_flag
    sta page_0,y
    ; mask off bit 6 for the current cell value
    txa
    and #$bf
    tax
    pla
    rts

;Needed because subroutine is out of range to branch to
process_next_cell
    jmp mark_cell_above_as_processed_and_move_to_next_cell

; *************************************************************************************
handler_firefly_or_butterfly
    cpx #map_deadly
    bpl show_large_explosion
    ; check directions in order: cell_below, cell_right, cell_left, cell_up
    ldy #8
look_for_amoeba_or_player_loop
    lda cell_above_left-1,y
    and #7
    eor #7
    beq show_large_explosion
    dey
    dey
    bne look_for_amoeba_or_player_loop
    ; calculate direction to move in Y
    txa
    lsr
    lsr
    lsr
    and #7
    tay
    ; branch if the desired direction is empty
    ldx firefly_neighbour_variables,y
    lda page_0,x
    beq set_firefly_or_butterfly
    ; get the next direction in Y
    lda firefly_and_butterfly_next_direction_table,y
    tay
    ; branch if the second desired direction is empty
    ldx firefly_neighbour_variables,y
    lda page_0,x
    beq set_firefly_or_butterfly
    ; set X=0 to force the use of the final possible direction
    ldx #0
    ; get the last cardinal direction that isn't a u-turn
    lda firefly_and_butterfly_next_direction_table,y
    tay
set_firefly_or_butterfly
    lda firefly_and_butterfly_cell_values,y
    cpx #0
    bne store_firefly_and_clear_current_cell
    tax
    rts

store_firefly_and_clear_current_cell
    sta page_0,x
    ldx #0
    rts

show_large_explosion
    txa
    ldx #<cell_types_that_will_turn_into_large_explosion
    and #8
    beq set_explosion_type
    ldx #<cell_types_that_will_turn_into_diamonds
set_explosion_type
    stx lookup_table_address_low
    ; activate explosion sound
    stx sound6_active_flag
    ; read above left cell
    ldy #0
    lda (ptr_low),y
    sta cell_above_left
    ; reset current cell to zero
    sty cell_current
    ; read above right cell
    ldy #2
    lda (ptr_low),y
    sta cell_above_right
    ; read below left cell
    ldy #$80
    lda (ptr_low),y
    sta cell_below_left
    ; read below right cell
    ldy #$82
    lda (ptr_low),y
    sta cell_below_right
    ; loop 9 times to replace all the neighbour cells with diamonds or large explosion
    ldx #9
replace_neighbours_loop
    lda cell_above_left-1,x
    and #$0f
    tay
read_from_table_instruction
lookup_table_address_low = read_from_table_instruction+1
    lda cell_types_that_will_turn_into_large_explosion,y
    beq skip_storing_explosion_into_cell
    sta cell_above_left-1,x
skip_storing_explosion_into_cell
    dex
    bne replace_neighbours_loop
    ; write new values back into the corner cells
    ; write to above left cell
    ldy #0
    lda cell_above_left
    and #$7f
    sta (ptr_low),y
    ; write to above right cell
    ldy #2
    lda cell_above_right
    sta (ptr_low),y
    ; write to below left cell
    ldy #$80
    lda cell_below_left
    sta (ptr_low),y
    ; write to below right cell
    ldy #$82
    lda cell_below_right
    sta (ptr_low),y
    ldx cell_current
    rts

; *************************************************************************************
handler_amoeba
    lda amoeba_replacement
    beq update_amoeba
    ; play amoeba sound
    tax
    sta sound6_active_flag
    rts

update_amoeba
    inc number_of_amoeba_cells_found
    ; check for surrounding space or earth allowing the amoeba to grow
    lda #$0e
    bit cell_above
    beq amoeba_can_grow
    bit cell_left
    beq amoeba_can_grow
    bit cell_right
    beq amoeba_can_grow
    bit cell_below
    bne return3
amoeba_can_grow
    stx current_amoeba_cell_type
    stx sound0_active_flag
    inc amoeba_counter
    lda amoeba_counter
    cmp amoeba_growth_interval
    bne return3
    lda #0
    sta amoeba_counter
    ; calculate direction to grow based on current amoeba state in top bits
    txa
    lsr
    lsr
    lsr
    and #6
    ; Y is set to 0,2,4, or 6 for the compass directions
    tay
    cpx #map_deadly
    bmi check_for_space_or_earth
    ; get cell value for direction Y
    lda cell_above,y
    beq found_space_or_earth_to_grow_into
    ; move amoeba onto next state (add 16)
increment_top_nybble_of_amoeba
    txa
    clc
    adc #$10
    and #$7f
    tax
    rts

    ; get cell value for direction Y
check_for_space_or_earth
    lda cell_above,y
    ; branch if 0 or 1 (space or earth)
    and #$0e
    bne increment_top_nybble_of_amoeba
found_space_or_earth_to_grow_into
    lda tick_counter
    lsr
    bcc store_x
    jsr increment_top_nybble_of_amoeba
store_x
    txa
    sta cell_above,y
return3
    rts

; *************************************************************************************
handler_rockford
    stx current_rockford_sprite
    lda rockford_explosion_cell_type
    bne start_large_explosion
    inx
    bne check_for_direction_key_pressed
start_large_explosion
    ldx #map_start_large_explosion
    stx rockford_explosion_cell_type
    rts

check_for_direction_key_pressed
    lda keys_to_process
    and #$f0
    bne direction_key_pressed
    ; player is not moving in any direction
    ldx #map_rockford
update_player_at_current_location
    lda #$41
play_movement_sound_and_update_current_position_address
    sta sound2_active_flag
    clc
    adc ptr_low
    sta map_rockford_current_position_addr_low
    lda ptr_high
    adc #0
    sta map_rockford_current_position_addr_high
    rts

direction_key_pressed
    ldx #0
    stx ticks_since_last_direction_key_pressed
    dex
get_direction_index_loop
    inx
    asl
    bcc get_direction_index_loop
    lda rockford_cell_value_for_direction,x
    beq skip_storing_rockford_cell_type
    sta rockford_cell_value
skip_storing_rockford_cell_type
    ldy neighbouring_cell_variable_from_direction_index,x
    sty neighbouring_cell_variable
    ; read cell contents from the given neighbouring cell variable y
    lda page_0,y
    sta neighbour_cell_contents
    and #$0f
    tay
    ; branch if movement is not possible
    lda collision_for_cell_type,y
    beq check_if_value_is_empty
    ; branch if movement is freely possible
    bmi check_for_return_pressed
    ; trying to move into something difficult to move (e.g. a rock)
    ldy check_for_rock_direction_offsets,x
    beq check_if_value_is_empty
    cpy #$ee  ;Special value used to detect rock has been pushed up
    beq check_push_up
    lda (ptr_low),y
    bne check_if_value_is_empty
    lda neighbour_cell_contents
    ; don't try pushing a rock that's just fallen this tick (bit 6 set at $24c7)
    cmp #$45
    beq check_if_value_is_empty
    dec delay_trying_to_push_rock
    bne check_if_value_is_empty
    ora #$80
    sta (ptr_low),y
    lda #4
    sta delay_trying_to_push_rock
    inc sound4_active_flag
check_for_return_pressed
    lda keys_to_process
    and #8
    beq store_rockford_cell_value_without_return_pressed
    ; return and direction is pressed. clear the appropriate cell
    jsr check_if_bombs_used  ;Returns accumulator used below
    ldy neighbouring_cell_variable
    sta page_0,y
check_if_value_is_empty
    ldx rockford_cell_value
    bne update_player_at_current_location
store_rockford_cell_value_without_return_pressed
    ldy neighbouring_cell_variable
    lda rockford_cell_value
    sta page_0,y
    lda map_offset_for_direction,x
    dex
    beq play_movement_sound_and_update_current_position_address
    ldx #$80
    bne play_movement_sound_and_update_current_position_address                 ; ALWAYS branch

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
    txa
    ldx magic_wall_state
    cmp #$bd
    bne check_if_magic_wall_is_active
    ; read what's above the wall, getting the cell type from the lower nybble
    lda cell_above
    and #$0f
    tay
    ; read what cell types are allowed to fall through and what is produced as a result
    ; (rocks turn into diamonds and vice versa)
    lda items_produced_by_the_magic_wall,y
    beq skip_storing_space_above
    ; something will fall into the wall, clear the cell above
    ldy #map_unprocessed | map_space
    sty cell_above
skip_storing_space_above
    cpx #$2d
    beq store_magic_wall_state
    ; if the cell below isn't empty, then don't store the item below
    ldy cell_below
    bne magic_wall_is_active
    ; store the item that has fallen through the wall below
    sta cell_below
magic_wall_is_active
    ldx #$1d
    inc sound1_active_flag
    ldy magic_wall_timer
    bne store_magic_wall_state
    ; magic wall becomes inactive once the timer has run out
    ldx #$2d
store_magic_wall_state
    stx magic_wall_state
    rts

check_if_magic_wall_is_active
    cpx #$1d
    beq magic_wall_is_active
    rts

; *************************************************************************************
    ; mark rockford cell as visible
handler_rockford_intro_or_exit
    txa
    and #$7f
    tax
    ; branch if on exit
    cpx #map_active_exit
    beq return4
    ; we have found the intro square
    lda #0
    sta keys_to_process
    ; wait for flashing rockford animation to finish
    lda tick_counter
    cmp #$f0
    bpl return4
    ; start the explosion just before gameplay starts
    ldx #$21
    inc sound4_active_flag
    lda #<regular_status_bar
    sta status_text_address_low
return4
    rts

; *************************************************************************************
start_gameplay
    jsr reset_clock
    lda #1
    sta demo_key_duration
    ; Set A=0
    lsr
    sta zeroed_but_unused
gameplay_loop
    lda #0
    ; clear sound
    ldx #7
zero_eight_bytes_loop
    sta sound0_active_flag,x
    dex
    bpl zero_eight_bytes_loop
    ; zero variables

    ;allow the number of bombs left to be shown briefly in place of number of diamonds required
    lda bomb_delay
    beq end_change_status_bar
    ;zero the first 2 status bar tiles, will be adding to them below
    lda #sprite_0
    sta regular_status_bar
    sta regular_status_bar+1
    ;now update to the bomb counter or diamonds required
    lda bomb_delay
    cmp #1  ;on the final delay so switch back to diamonds required
    beq back_to_show_diamonds_required
    ldy #1
    lda bomb_counter
    jsr add_a_to_status_bar_number_at_y  ;show the bomb counter
    lda #sprite_bomb1  ;also include the bomb sprite
    sta regular_status_bar+2
    jmp end_change_status_bar
back_to_show_diamonds_required
    lda #sprite_diamond1
    sta regular_status_bar+2  ;replace bomb sprite back to diamond
    ldy #0
    lda (map_rockford_end_position_addr_low),y  ;check if Rockford exit is active (got all diamonds)
    cmp #map_active_exit  ;cannot use diamonds_required, decremented each time a diamond is collected
    bne add_diamonds_required
    lda #sprite_diamond1  ;got all diamonds so reset back to 3 diamonds in status
    sta regular_status_bar
    sta regular_status_bar+1
    jmp end_change_status_bar
add_diamonds_required
    ldy difficulty_level
    dey
    lda param_diamonds_required, y
    ldy #1
    jsr add_a_to_status_bar_number_at_y  ;show the diamonds required again
end_change_status_bar
    lda #0

    sta status_text_address_low
    sta current_amoeba_cell_type
    sta neighbour_cell_contents
    ; activate movement sound
    lda #$41
    sta sound2_active_flag
    ; reset number of amoeba cells found, and if already zero then clear the
    ; amoeba_replacement
    ldx #0
    lda number_of_amoeba_cells_found
    stx number_of_amoeba_cells_found
    bne skip_clearing_amoeba_replacement
    stx amoeba_replacement
skip_clearing_amoeba_replacement
    stx current_amoeba_cell_type
    jsr wait_for_13_centiseconds_and_read_keys
    ; branch if not in demo mode
    ldx demo_mode_tick_count
    bmi update_gameplay
    ; if a key is pressed in demo mode, then return
    lda keys_to_process
    beq update_demo_mode
    rts

update_demo_mode
    ldy #<regular_status_bar
    ; flip between status bar and demo mode text every 16 ticks
    lda tick_counter
    and #$10
    beq skip_demo_mode_text
    ldy #<demonstration_mode_text
skip_demo_mode_text
    sty status_text_address_low
    lda demonstration_keys,x
    sta keys_to_process
    dec demo_key_duration
    bne update_gameplay
    inc demo_mode_tick_count
    inx
    lda demonstration_key_durations,x
    sta demo_key_duration

update_gameplay
    jsr update_map
    ; get the contents of the cell that rockford is influencing. This can be the cell
    ; underneath rockford, or by holding the RETURN key down and pressing a direction
    ; key it can be one of the neighbouring cells.
    ; We clear the top bits to just extract the basic type.
    lda neighbour_cell_contents
    and #$0f
    sta neighbour_cell_contents
    cmp #map_rockford_appearing_or_end_position
    bne rockford_is_not_at_end_position
    jmp update_with_gameplay_not_active

rockford_is_not_at_end_position
    jsr draw_grid_of_sprites
    jsr draw_status_bar
    jsr update_amoeba_timing
    ; check if the player is still alive by reading the current rockford sprite (branch
    ; if not)
    lda current_rockford_sprite
    beq check_for_earth
    ; update game timer (sub seconds)
    dec sub_second_ticks
    bpl check_for_earth
    ; each 'second' of game time has 11 game ticks
    ldx #11
    stx sub_second_ticks
    ; decrement time remaining ('seconds') on the status bar and in the separate
    ; variable
    ldy #12
    jsr decrement_status_bar_number
    dec time_remaining
    ; branch if there's still time left
    bne check_for_earth
    ; out of time
    lda #<out_of_time_message
    sta status_text_address_low
    jmp update_with_gameplay_not_active

check_for_earth
    lda neighbour_cell_contents
    cmp #1
    bne skip_earth
    ; got earth. play sound 3
    inc sound3_active_flag
skip_earth
    cmp #4
    bne skip_got_diamond
    ; got diamond. play sounds
    ldx #$85
    ldy #$f0
    jsr play_sound_x_pitch_y
    ldx #$85
    ldy #$d2
    jsr play_sound_x_pitch_y
    jsr got_diamond_so_update_status_bar
skip_got_diamond
    jsr update_sounds
    ; update game tick
    dec tick_counter
    lda tick_counter
    and #7
    bne update_death_explosion
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
    lda magic_wall_state
    cmp #$1d
    bne update_death_explosion
    dec magic_wall_timer
update_death_explosion
    ldx rockford_explosion_cell_type
    beq check_for_escape_key_pressed_to_die
    inx
    stx rockford_explosion_cell_type
    cpx #$4b
    bmi check_for_escape_key_pressed_to_die
    ; if key is pressed at end of the death explosion sequence, then return
    lda keys_to_process
    bne return5
    dec rockford_explosion_cell_type
    ; branch if escape not pressed
check_for_escape_key_pressed_to_die
    lda keys_to_process
    lsr
    bcc check_if_pause_is_available
    ; branch if explosion already underway
    lda rockford_explosion_cell_type
    bne check_if_pause_is_available
    ; start death explosion
    lda #map_start_large_explosion
    sta rockford_explosion_cell_type
    ; branch if on a bonus stage (no pause available)
check_if_pause_is_available
    lda cave_number
    cmp #16
    bpl gameplay_loop_local
    ; check if pause pressed
    lda keys_to_process
    and #2
    beq gameplay_loop_local
    jsr update_with_gameplay_not_active
gameplay_loop_local
    jmp gameplay_loop

return5
    rts

; *************************************************************************************
update_grid_animations
    ldx #$0e
    stx cell_current
update_sprites_to_use_loop
    ldy cell_types_that_always_animate,x
    ldx cell_type_to_sprite,y
    ; look up the next sprite in the animation sequence
    lda sprite_to_next_sprite,x
    sta cell_type_to_sprite,y
    dec cell_current
    ldx cell_current
    bpl update_sprites_to_use_loop

    ; use the tick counter (bottom two bits scaled up by 16) to update amoeba animation (and apply to slime as well)
    lda tick_counter
    and #3
    asl
    asl
    asl
    asl
    tax
    lda amoeba_animated_sprite0,x
    eor #1
    sta amoeba_animated_sprite0,x
    sta slime_animated_sprite0,x
    lda amoeba_animated_sprites4,x
    eor #1
    sta amoeba_animated_sprites4,x
    sta slime_animated_sprite1,x
    ; animate exit
    lda exit_cell_type
    eor #$10
    sta exit_cell_type
    ; update rockford idle animation
    lda ticks_since_last_direction_key_pressed
    tay
    and #$3f
    tax
    lda idle_animation_data,x
    ; check for nearing the end of the idle animation (range $c0-$ff).
    ; Use the top nybbles of the data if so.
    cpy #$c0
    bcc extract_lower_nybble
    ; Near the end of the idle animation. Shift the upper nybble into the bottom nybble
    ; to get more idle sprites
    lsr
    lsr
    lsr
    lsr
extract_lower_nybble
    and #$0f
    ; set the rockford sprite
    ora #sprite_rockford_blinking1
    sta rockford_sprite
    inc ticks_since_last_direction_key_pressed
    rts

keys_pressed_last_tick
    !byte 0

; *************************************************************************************
read_repeat_keys
    lda keys_pressed_last_tick        ; a mask of the keys to look for - in this case any keys pressed on the previous game tick

read_some_keys
    sta temp_keys
    ldx #7
    stx cell_current
    ldx #0
    stx real_keys_pressed
read_some_keys_loop
    ldx cell_current
    asl temp_keys
    bcc next_key
    lda inkey_keys_table,x
    tax
;To detect individual keys, x is the key to check and y is usually set to #$ff and checked afterwards
;However os code for OSBYTE 129 (read key with time limit) just checks for negative y (>127) which it is, so 'tay' is fine
;See https://tobylobster.github.io/mos/mos/S-s15.html#SP16
    tay
    lda #osbyte_inkey
    jsr osbyte
;Continuing from above, the carry flag is set to 1 if the key was pressed, otherwise is 0
;So with 'rol real_keys_pressed', real_keys_pressed is built into an 8 bit number using the carry flag for each of the 8 keys tested
;E.g. slash (down) and z (left) are both pressed, real_keys_pressed is 01010000 (starts checking keys in the inkey_keys_table bottom to top)
next_key
    rol real_keys_pressed
    dec cell_current
    bpl read_some_keys_loop
    lda keys_to_process
    ora real_keys_pressed
    sta keys_to_process
    rts

; *************************************************************************************
increment_status_bar_number
    lda regular_status_bar,y
    clc
    adc #1
    cmp #$3c
    bmi finished_change
    lda #sprite_0
    sta regular_status_bar,y
    dey
    bpl increment_status_bar_number
decrement_status_bar_number
    lda regular_status_bar,y
    sec
    sbc #1
    cmp #sprite_0
    bpl finished_change
    lda #$3b
    sta regular_status_bar,y
    dey
    bpl decrement_status_bar_number
finished_change
    sta regular_status_bar,y
    rts

; *************************************************************************************
add_a_to_status_bar_number_at_y
    sty real_keys_pressed
    sta amount_to_increment_status_bar
    cmp #0
    beq finished_add
increment_number_loop
    jsr increment_status_bar_number
    ldy real_keys_pressed
    dec amount_to_increment_status_bar
    bne increment_number_loop
finished_add
    ldy real_keys_pressed
    rts

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
    inc ptr_low
    lda ptr_low
    and #$3f
    cmp #$28
    bne return6
    lda ptr_low
    and #$c0
    clc
    adc #$40
    sta ptr_low
    bcc skip_increment_high_byte2
    inc ptr_high
skip_increment_high_byte2
    dec x_loop_counter
return6
    rts

; *************************************************************************************
set_ptr_to_start_of_map
    lda #<tile_map_row_1
set_ptr_high_to_start_of_map_with_offset_a
    sta ptr_low
set_ptr_high_to_start_of_map
    lda #>tile_map_row_1
    sta ptr_high
    lda #20
    sta x_loop_counter
    ldy #0
    rts

; *************************************************************************************
palette_block
    !byte 0                            ; logical colour
    !byte 0                            ; physical colour
    !byte 0                            ; zero
    !byte 0                            ; zero
    !byte 0                            ; zero

; *************************************************************************************
increment_next_ptr
    inc next_ptr_low
    bne return6
    inc next_ptr_high
    rts

; *************************************************************************************
set_palette_colour_ax
    sta palette_block+1
    txa
    pha
    stx palette_block
    tya
    pha
    ldx #<(palette_block)
    ldy #>(palette_block)
    lda #osword_write_palette
    jsr osword                         ; Write palette
    pla
    tay
    pla
    tax
    rts

; *************************************************************************************
reset_clock
    ldy #>(initial_clock_value)
    ldx #<(initial_clock_value)
    lda #osword_write_clock
    jmp osword                         ; Write system clock

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
    lda countdown_while_switching_palette
    beq check_for_bonus_life
    inc sound6_active_flag
    ldx #3
    lda countdown_while_switching_palette
    and #7
    ora #4
    cmp #4
    bne skip_setting_physical_colour_to_three
    ; set logical colour three
    lda #3
skip_setting_physical_colour_to_three
    jsr set_palette_colour_ax
    dec countdown_while_switching_palette
    bne check_for_bonus_life
    ; restore to spaces
    lda #0
    sta cell_type_to_sprite
    jsr set_palette

    ; a bonus life is awarded every 500 points
check_for_bonus_life
    lda hundreds_digit_of_score_on_status_bar
    cmp #sprite_0
    beq zero_or_five_in_hundreds_column
    cmp #sprite_5
    beq zero_or_five_in_hundreds_column
    ; a bonus life only becomes possible after the score *doesn't* have a zero or five
    ; in the hundreds column
    lda #$ff
    sta bonus_life_available_flag
    rts

zero_or_five_in_hundreds_column
    ldy #17
check_for_non_zero_in_top_digits
    lda regular_status_bar,y
    cmp #sprite_0
    bne non_zero_digit_found_in_hundreds_column_or_above
    dey
    cpy #13
    bne check_for_non_zero_in_top_digits
    ; all the top digits are zero, including the hundreds column, which means we are
    ; not 500 or more, so not eligible for a bonus life
    lda #0
    sta bonus_life_available_flag
    rts

non_zero_digit_found_in_hundreds_column_or_above
    lda bonus_life_available_flag
    beq return7
    ; award bonus life
    lda #0
    sta bonus_life_available_flag
    ; set sprite for space to pathway
    lda #sprite_pathway
    sta cell_type_to_sprite
    ; start animating colour three
    lda #7
    sta countdown_while_switching_palette
    ; add one to the MEN count
    inc men_number_on_regular_status_bar
    ; show bonus life text (very briefly)
    lda #<bonus_life_text
    sta status_text_address_low
return7
    rts

; *************************************************************************************
draw_big_rockford
    lda #>big_rockford_destination_screen_address
    sta ptr_high
    ldy #<big_rockford_destination_screen_address
    sty ptr_low
    lda #>big_rockford_sprite
    sta next_ptr_high
    sty next_ptr_low
draw_big_rockford_loop
    ldx #1
    jsr get_next_ptr_byte
    ldy #6
check_if_byte_is_an_rle_byte_loop
    cmp rle_bytes_table,y
    beq get_repeat_count
    dey
    bne check_if_byte_is_an_rle_byte_loop
    beq copy_x_bytes_in_rle_loop       ; ALWAYS branch

; *************************************************************************************
get_repeat_count
    ldy #0
    pha
    jsr get_next_ptr_byte
    tax
    pla
copy_x_bytes_in_rle_loop
    sta (ptr_low),y
    inc ptr_low
    bne skip_inc_high
    inc ptr_high
    bmi return8
skip_inc_high
    dex
    bne copy_x_bytes_in_rle_loop
    beq draw_big_rockford_loop         ; ALWAYS branch

; *************************************************************************************
get_next_ptr_byte
    lda (next_ptr_low),y
    inc next_ptr_low
    bne return8
    inc next_ptr_high
return8
    rts

rle_bytes_table
    !byte $85, $48, $10, $ec, $ff, $0f,   0

; *************************************************************************************
map_address_to_map_xy_position
    lda map_address_high
    and #7
    sta map_y
    lda map_address_low
    asl
    rol map_y
    asl
    rol map_y
    lda map_address_low
    and #$3f
    sta map_x
    rts

; *************************************************************************************
map_xy_position_to_map_address
    lda #0
    sta map_address_low
    lda map_y
    lsr
    ror map_address_low
    lsr
    ror map_address_low
    ora #>tile_map_row_0
    sta map_address_high
    lda map_x
    ora map_address_low
    sta map_address_low
    rts

; *************************************************************************************
; Scrolls the map by setting the tile_map_ptr and visible_top_left_map_x and y
update_map_scroll_position
    lda map_rockford_current_position_addr_low
    sta map_address_low
    lda map_rockford_current_position_addr_high
    sta map_address_high
    jsr map_address_to_map_xy_position
    sec
    sbc visible_top_left_map_x
    ldx visible_top_left_map_x
    cmp #17
    bmi check_for_need_to_scroll_left
    cpx #20
    bpl check_for_need_to_scroll_down
    inx
check_for_need_to_scroll_left
    cmp #3
    bpl check_for_need_to_scroll_down
    cpx #1
    bmi check_for_need_to_scroll_down
    dex
check_for_need_to_scroll_down
    ldy visible_top_left_map_y
    lda map_y
    sec
    sbc visible_top_left_map_y
    cmp #9
    bmi check_for_need_to_scroll_up
    cpy #$0a
    bpl check_for_bonus_stages
    iny
check_for_need_to_scroll_up
    cmp #3
    bpl check_for_bonus_stages
    cpy #1
    bmi check_for_bonus_stages
    dey
check_for_bonus_stages
    lda param_intermission
    beq skip_bonus_stage
    ; bonus stage is always situated in top left corner
    lda #0
    tax
    tay
skip_bonus_stage
    stx visible_top_left_map_x
    stx map_x
    sty visible_top_left_map_y
    sty map_y
    jsr map_xy_position_to_map_address
    lda map_address_low
    sta tile_map_ptr_low
    lda map_address_high
    sta tile_map_ptr_high
    rts

; *************************************************************************************
wait_for_13_centiseconds_and_read_keys
    lda #$0d
wait_for_a_centiseconds_and_read_keys
    sta wait_delay_centiseconds
wait_for_centiseconds_and_read_keys
    ; look for *new* keypresses, i.e. keys that are not already down from the previous game update
    jsr invert_keys_to_test

    ; start the loop with no keys pressed, and OR in bits as we find new keypresses
    lda #0
    sta keys_to_process
wait_loop
    ; read any new keypresses
    lda keys_to_test            ; a mask of the keys to look for - in this case any keys not pressed in the previous game tick
    jsr read_some_keys
    ldy #>(set_clock_value)
    ldx #<(set_clock_value)
    lda #osword_read_clock
    jsr osword
    lda set_clock_value
    cmp wait_delay_centiseconds
    bmi wait_loop
    jsr reset_clock
    jsr animate_flashing_spaces_and_check_for_bonus_life
    ldx #0
    txa
    jsr set_palette_colour_ax

    ; read any keys that were already pressed on the previous game update
    jmp read_repeat_keys

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
    !byte $12,   5,   8,   5
    !byte $12, $f7, $c8,   1
    !byte   0, $fe,   4,   1
    !byte   0, $fb,   4,   1
    !byte $10,   2,   5,   7
    !byte $13,   1, $dc,   1
    !byte $10,   4,   7, $1e
    !byte $11,   3, $ff, $28
    !byte $12,   1, $c8,   2
in_game_sound_block
    !word $13                          ; Channel (2 bytes)
in_game_sound_amplitude
    !word 1                            ; Amplitude (2 bytes)
in_game_sound_pitch
    !word $8f                          ; Pitch (2 bytes)
in_game_sound_duration
    !word 1                            ; Duration (2 bytes)

; *************************************************************************************
; If X is negative, then play sound (X AND 127) with pitch Y.
; If X is non-negative, play sound X with default pitch.
play_sound_x_pitch_y
    txa
    bmi skip_using_default_pitch1
    ldy #0
skip_using_default_pitch1
    and #$7f
    tax
    cpx #6
    bne play_raw_sound_x_pitch_y
    ; sound 6 also plays sound 7
    jsr play_raw_sound_x_pitch_y
    ldx #7
play_raw_sound_x_pitch_y
    txa
    asl
    asl
    tax
    lda #0
    sta in_game_sound_amplitude+1
    lda in_game_sound_data,x
    sta in_game_sound_block
    lda in_game_sound_data+1,x
    sta in_game_sound_amplitude
    bpl skip_negative_amplitude
    lda #$ff
    sta in_game_sound_amplitude+1
skip_negative_amplitude
    tya
    bne skip_using_default_pitch2
    ; use default pitch
    lda in_game_sound_data+2,x
skip_using_default_pitch2
    sta in_game_sound_pitch
    lda in_game_sound_data+3,x
    sta in_game_sound_duration
    ldy #>(in_game_sound_block)
    ldx #<(in_game_sound_block)
    lda #osword_sound
    jmp osword                         ; SOUND command

; *************************************************************************************
update_sounds
    lda sound2_active_flag
    eor #$41
    sta sound2_active_flag
    lda time_remaining
    cmp #$0b
    bcs skip_playing_countdown_sounds
    lda sub_second_ticks
    cmp #$0b
    bne skip_playing_countdown_sounds
    ; play rising pitch as time up is approaching
    lda #$dc
    sbc time_remaining
    sbc time_remaining
    sbc time_remaining
    tay
    ldx #$88
    jsr play_sound_x_pitch_y
skip_playing_countdown_sounds
    jsr get_next_random_byte
    and #$0c
    sta in_game_sound_data+2
    ldx #5
    jsr play_sound_if_needed
    lda tick_counter
    lsr
    bcc skip_sound_0
    ldx #0
    jsr play_sound_if_needed
skip_sound_0
    ldx #1
    jsr play_sound_if_needed
    ldx #6
    jsr play_sound_if_needed
    lda sound6_active_flag
    bne return10
    ldx #4
    jsr play_sound_if_needed
    lda sound4_active_flag
    bne return10
    ldy #$19
    ldx #$fb
    lda #osbyte_read_adc_or_get_buffer_status
    jsr osbyte                          ; Read number of spaces remaining in sound channel 0 (X=251)
    cpx #$0b                            ; X is the number of spaces remaining in sound channel 0
    bmi return10
    lda sound4_active_flag
    ora sound6_active_flag
    bne return10
    ldx #2
    jsr play_sound_if_needed
    ldx #3
play_sound_if_needed
    lda sound0_active_flag,x
    beq return10
    jmp play_sound_x_pitch_y

return10
    rts

invert_keys_to_test
    lda keys_to_process         ; get which keys were down on the previous tick of the game
    sta keys_pressed_last_tick
    eor #255                    ; invert the bits so we test only the keys that were not down last tick
    sta keys_to_test
    rts

; *************************************************************************************
play_one_life

    ; Load cave parameters and map from file
    jsr load_cave_file
    ; Set colour palette using parameters
    jsr set_palette

    ; a bonus life only becomes possible after the score *doesn't* have a zero or five
    ; in the hundreds column
    lda #0
    sta bonus_life_available_flag
    sta cell_type_to_sprite
    ldx #<players_and_men_status_bar
    lda cave_number
    cmp #16
    bmi skip_bonus_life_text
    ldx #<bonus_life_text
skip_bonus_life_text
    stx status_text_address_low
    ; check if we are in demo mode
    lda demo_mode_tick_count
    bmi skip_setting_demo_mode_text
    lda #<demonstration_mode_text
    sta status_text_address_low
    ; initialise variables $50-$5f
skip_setting_demo_mode_text
    ldx #$0f
initialise_variables_loop
    lda initial_values_of_variables_from_0x50,x
    cmp #99
    beq skip_setting_variable
    sta magic_wall_state,x
skip_setting_variable
    dex
    bpl initialise_variables_loop

    ; Populate the cave map from loaded data
    jsr populate_cave_from_file
    ; Populate the cave map using the pseudo-random method, using applicable cave parameters
    jsr populate_cave_tiles_pseudo_random

    ; map complete: draw cave borders
    jsr set_ptr_to_start_of_map
    ; loop over all rows, plotting side borders from the cave file
    ldx #22
write_left_and_right_borders_loop
    ldy #39
hide_cells_loop
    lda (ptr_low),y
    ora #$80
    sta (ptr_low),y
    dey
    bne hide_cells_loop
    lda (ptr_low),y
    ora #$80
    sta (ptr_low),y
    lda #$40
    jsr add_a_to_ptr
    dex
    bne write_left_and_right_borders_loop
    ; write the top and bottom borders using param_border_tile (steelwall if zero)
    lda param_border_tile
    ora #$80
    ldx #39
write_top_and_bottom_borders_loop
    sta tile_map_row_0,x
    sta tile_map_row_21,x
    dex
    bpl write_top_and_bottom_borders_loop
    jsr initialise_stage
    jsr play_screen_dissolve_effect
    jsr start_gameplay
    lda neighbour_cell_contents
    cmp #8
    beq play_screen_dissolve_to_solid
    dec men_number_on_regular_status_bar
    lda men_number_on_regular_status_bar
    cmp #sprite_0
    bne play_screen_dissolve_to_solid
    lda player_number_on_regular_status_bar
    sta player_number_on_game_over_text
    lda #<game_over_text
    sta status_text_address_low
    ldx #<highscore_high_status_bar
    lda player_number_on_regular_status_bar
    cmp #sprite_1
    beq got_pointer_to_score
    ldx #<highscore_for_player_2
got_pointer_to_score
    stx which_status_bar_address1_low
    stx which_status_bar_address2_low
    ldx #0
    ldy #0
compare_highscores_loop
    lda score_on_regular_status_bar,x
    cpy #0
    bne store_in_status_bar
compare
which_status_bar_address1_low = compare+1
    cmp highscore_high_status_bar,x
    bmi play_screen_dissolve_to_solid
    bne store_in_status_bar
goto_next_digit
    inx
    cpx #6
    bne compare_highscores_loop
    beq play_screen_dissolve_to_solid   ; ALWAYS branch

store_in_status_bar
which_status_bar_address2_low = store_in_status_bar+1
    sta highscore_high_status_bar,x
    iny
    bne goto_next_digit

play_screen_dissolve_to_solid
    lda #$80
play_screen_dissolve_effect
    sta dissolve_to_solid_flag
    lda #$21
    sta tick_counter
    lda cave_number
    sta cell_current
screen_dissolve_loop
    jsr reveal_or_hide_more_cells
    jsr draw_grid_of_sprites
    jsr draw_status_bar
    lda tick_counter
    asl
    and #$0f
    ora #$e0
    sta sprite_titanium_addressA
    sta sprite_titanium_addressB
    dec tick_counter
    bpl screen_dissolve_loop
    rts

; *************************************************************************************
got_diamond_so_update_status_bar
    ldy #8
    jsr increment_status_bar_number
    lda total_diamonds_on_status_bar_high_digit
    sec
    sbc #sprite_0
    ldy #$12
    jsr add_a_to_status_bar_number_at_y
    lda total_diamonds_on_status_bar_low_digit
    sec
    sbc #sprite_0
    iny
    jsr add_a_to_status_bar_number_at_y
    dec diamonds_required
    bne return12
    ;got all the diamonds
    lda #7
    ldx #0
    jsr set_palette_colour_ax
    lda #sprite_diamond1
    sta regular_status_bar
    sta regular_status_bar+1
    ; open the exit
    ldy #0
    lda #map_active_exit
    sta (map_rockford_end_position_addr_low),y
    ; set total diamonds to zero
    lda #sprite_0
    sta total_diamonds_on_status_bar_high_digit
    sta total_diamonds_on_status_bar_low_digit
    ; show score per diamond on status bar
    lda param_diamond_extra_value
    ldy #4
    jsr add_a_to_status_bar_number_at_y
    ; play sound 6
    inc sound6_active_flag
return12
    rts

; *************************************************************************************
initialise_stage
    lda #20
    sta visible_top_left_map_x
    lsr
    sta visible_top_left_map_y
    ldy #$0d
empty_status_bar_loop
    lda zeroed_status_bar,y
    sta regular_status_bar,y
    dey
    bpl empty_status_bar_loop

    ; set and show initial diamond score amount on status bar
    lda param_diamond_value
    ldy #4
    jsr add_a_to_status_bar_number_at_y

    ; show cave letter on status bar
    lda cave_number
    clc
    adc #'A'
    sta cave_letter_on_regular_status_bar

    ; show difficulty level on status bar
    lda difficulty_level
    clc
    adc #sprite_0
    sta difficulty_level_on_regular_status_bar

    ; set the delay between amoeba growth
    lda param_amoeba_magic_wall_time
    sta amoeba_growth_interval
    sta magic_wall_timer

    ; set the number of bombs available
    lda param_bombs
    sta bomb_counter

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
    lda param_rockford_end
    sta map_y
    lda param_rockford_end+1
    sta map_x
    jsr map_xy_position_to_map_address
    ldy #0
    lda #3
    sta (map_address_low),y
    lda map_address_low
    sta map_rockford_end_position_addr_low
    lda map_address_high
    sta map_rockford_end_position_addr_high

    ; put the start tile on the map
    lda param_rockford_start
    sta map_y
    lda param_rockford_start+1
    sta map_x
    jsr map_xy_position_to_map_address
    ldy #0
    lda #8
    sta (map_address_low),y
    lda map_address_low
    sta map_rockford_current_position_addr_low
    lda map_address_high
    sta map_rockford_current_position_addr_high

    ; set and show diamonds required on status bar
    ldx difficulty_level
    dex
    lda param_diamonds_required,x
    sta diamonds_required
    ldy #1
    jsr add_a_to_status_bar_number_at_y

    ; set and show time remaining on status bar
    lda param_cave_time,x
    sta time_remaining
    ldy #$0c
    jsr add_a_to_status_bar_number_at_y

    ; return zero
    lda #0
    rts

; *************************************************************************************
update_amoeba_timing
    lda number_of_amoeba_cells_found
    beq check_for_amoeba_timeout
    sta sound0_active_flag
    ldy current_amoeba_cell_type
    bne found_amoeba
    inc sound7_active_flag
    ldx #(map_unprocessed | map_anim_state1) | map_wall
    bne amoeba_replacement_found        ; ALWAYS branch

found_amoeba
    adc #$38
    bcc check_for_amoeba_timeout
    ; towards the end of the level time the amoeba turns into rock
    ldx #map_unprocessed | map_rock
amoeba_replacement_found
    stx amoeba_replacement
check_for_amoeba_timeout
    lda time_remaining
    cmp #50
    bne return13
    lda sub_second_ticks
    cmp #7
    bne return13
    lda #1
    sta amoeba_growth_interval
    ; Set A=0 and zero the amoeba counter
    lsr
    sta amoeba_counter
return13
    rts

; *************************************************************************************
;
; update while paused, or out of time, or at end position (i.e. when gameplay started
; but is not currently active)
;
; *************************************************************************************
    ; check for pause key
update_with_gameplay_not_active
    lda keys_to_process
    and #2
    beq check_if_end_position_reached
    ; pause mode. show pause message.
    lda #<pause_message
    sta status_text_address_low
    lda #0
    sta pause_counter
update_while_initially_pressing_pause_loop
    jsr update_during_pause_mode
    bne update_while_initially_pressing_pause_loop
pause_loop
    inc pause_counter
    ldx #<pause_message
    ; toggle between showing pause message and regular status bar every 16 ticks
    lda pause_counter
    and #$10
    beq skip_showing_players_and_men
    ldx #<players_and_men_status_bar
skip_showing_players_and_men
    stx status_text_address_low
    jsr update_during_pause_or_out_of_time
    beq pause_loop
update_while_finally_pressing_unpause_loop
    jsr update_during_pause_mode
    bne update_while_finally_pressing_unpause_loop
    rts

check_if_end_position_reached
    lda neighbour_cell_contents
    ; check if end position has been reached
    cmp #map_rockford_appearing_or_end_position
    beq rockford_reached_end_position
    ; show out of time message for a while, then return
    lda #$0e
    sta out_of_time_message_countdown
    lda #<out_of_time_message
    sta status_text_address_low
out_of_time_loop
    jsr update_during_pause_or_out_of_time
    bne return14
    dec out_of_time_message_countdown
    bne out_of_time_loop
    rts

    ; clear rockford's final position, and set rockford on end position
rockford_reached_end_position
    ldy #0
    lda (map_rockford_current_position_addr_low),y
    and #$7f
    tax
    tya
    sta (map_rockford_current_position_addr_low),y
    txa
    sta (map_rockford_end_position_addr_low),y
    jsr draw_grid_of_sprites
    lda time_remaining
    beq skip_bonus
count_up_bonus_at_end_of_stage_loop
    ldy #$13
    jsr increment_status_bar_number
    ldy #$0c
    jsr decrement_status_bar_number
    ldx #5
    stx sound5_active_flag
    lda #0
    sta sound6_active_flag
    sta status_text_address_low
    lda time_remaining
    and #$1c
    tay
    iny
    ldx #$88
    jsr play_sound_x_pitch_y
    jsr animate_flashing_spaces_and_check_for_bonus_life
    jsr draw_grid_of_sprites
    jsr draw_status_bar
    lda #2
    sta wait_delay_centiseconds
    jsr wait_for_centiseconds_and_read_keys
    dec time_remaining
    bne count_up_bonus_at_end_of_stage_loop
skip_bonus
    lda #<regular_status_bar
    sta status_text_address_low
update_during_pause_or_out_of_time
    jsr draw_grid_of_sprites
    jsr draw_status_bar
    jsr wait_for_13_centiseconds_and_read_keys
    lda keys_to_process
    and #2
return14
    rts

; *************************************************************************************
update_during_pause_mode
    jsr draw_status_bar
    lda #0
    sta wait_delay_centiseconds
    jsr wait_for_centiseconds_and_read_keys
    ; check for pause key
    lda keys_to_process
    and #2
    rts

; *************************************************************************************
show_menu

    jsr draw_big_rockford
    jsr reset_tune
    jsr reset_clock
    ; show last score line
    jsr reset_grid_of_sprites
    lda #<score_last_status_bar
    sta status_text_address_low
    lda #>screen_addr_row_28
    ldy #<screen_addr_row_28
    jsr draw_single_row_of_sprites
    ; show highscore line
    jsr reset_grid_of_sprites
    lda #<highscore_high_status_bar
    sta status_text_address_low
    lda #>screen_addr_row_30
    ldy #<screen_addr_row_30
    jsr draw_single_row_of_sprites
    jsr reset_grid_of_sprites
    ; set cave letter and difficulty level number
    ldx #0
    ldy #1
handle_menu_loop
    lda #0
    sta timeout_until_demo_mode
    stx cave_number
    sty difficulty_level
    txa
    clc
    adc #'A'
    sta cave_letter
    tya
    clc
    adc #sprite_0
    sta number_of_players_status_bar_difficulty_level
    jsr set_initial_palette
waiting_for_demo_loop
    lda #<number_of_players_status_bar
    sta status_text_address_low
    jsr draw_status_bar
    jsr update_tune
    lda #9
    jsr wait_for_a_centiseconds_and_read_keys
    jsr update_tune
    lda #5
    jsr wait_for_a_centiseconds_and_read_keys
    ldx cave_number
    ldy difficulty_level
    lda #opcode_inx
    sta self_modify_move_left_or_right
    lda keys_to_process
    asl
    bcs self_modify_move_left_or_right
    asl
    bcs menu_move_left_to_change_cave
    asl
    bcs increase_difficulty_level
    asl
    bcs decrease_difficulty_level
    asl
    bcs toggle_one_or_two_players  ;enter key toggles the number of players
    asl
    bcs return15  ;"b" key returns and displays scrolling credits
    asl
    bcs show_rockford_again_and_play_game  ;space key starts game
    asl
    bcs return_to_version_selection  ;escape key returns to version selection screen
    dec timeout_until_demo_mode
    bne waiting_for_demo_loop

    ; demo mode
    ldx #5
    lda #sprite_0
zero_score_on_status_bar_loop
    sta score_on_regular_status_bar,x
    dex
    bpl zero_score_on_status_bar_loop
    ldx #0
    stx cave_number
    stx demo_mode_tick_count
    inx
    stx difficulty_level
    jsr play_one_life
    jmp show_menu

menu_move_left_to_change_cave
    lda #opcode_dex
    sta self_modify_move_left_or_right
self_modify_move_left_or_right
    inx
    txa
    and #$0f
    tax
store_new_difficulty_level_selected
    sty difficulty_level
    lda number_of_difficulty_levels_available_in_menu_for_each_cave,x
    cmp difficulty_level
    bcc self_modify_move_left_or_right
    jmp handle_menu_loop

increase_difficulty_level
    iny
    cpy #6
    bne store_new_difficulty_level_selected
    dey
    bne store_new_difficulty_level_selected
decrease_difficulty_level
    dey
    bne dont_go_below_one
    iny
dont_go_below_one
    jmp handle_menu_loop

toggle_one_or_two_players
    lda number_of_players_status_bar
    eor #sprite_1 XOR sprite_2
    sta number_of_players_status_bar
    lda plural_for_player
    eor #'S'
    sta plural_for_player
    jmp handle_menu_loop

show_rockford_again_and_play_game
    jsr draw_big_rockford
    jsr reset_grid_of_sprites
    lda #$ff
    sta demo_mode_tick_count
    jsr load_spriteset
    jsr initialise_and_play_game
    jmp show_menu

return15
    rts

return_to_version_selection
    jmp select_version_to_play

; *************************************************************************************
initialise_and_play_game
    ldx #19
copy_status_bar_loop
    lda default_status_bar,x
    sta players_and_men_status_bar,x
    sta inactive_players_and_men_status_bar,x
    dex
    bpl copy_status_bar_loop
    lda #sprite_2
    sta player_number_on_inactive_players_and_men_status_bar
    cmp number_of_players_status_bar
    beq set_cave_letter_on_status_bar
    lda #sprite_0
    sta number_of_men_on_inactive_players_and_men_status_bar
set_cave_letter_on_status_bar
    lda cave_letter
    sta cave_letter_on_regular_status_bar
    sta cave_letter_on_inactive_players_and_men_status_bar
    ; copy difficulty level to other status bars
    ldx number_of_players_status_bar_difficulty_level
    stx difficulty_level_on_regular_status_bar
    stx difficulty_level_on_inactive_players_and_men_status_bar
    jsr set_cave_number_and_difficulty_level_from_status_bar
    ; zero scores on status bars
    lda #sprite_0
    ldx #5
zero_score_loop
    sta score_on_regular_status_bar,x
    sta score_on_inactive_players_regular_status_bar,x
    dex
    bpl zero_score_loop
    ; add current stage to menu availablility
play_next_life
    ldx cave_number
    lda difficulty_level
    cmp number_of_difficulty_levels_available_in_menu_for_each_cave,x
    bmi skip_adding_new_difficulty_level_to_menu
    ; add new difficulty level to menu
    sta number_of_difficulty_levels_available_in_menu_for_each_cave,x
skip_adding_new_difficulty_level_to_menu
    jsr play_one_life
    ; save results after life
    ; first find the position of the score to copy from the status bar (which depends
    ; on the player number)
    ldy #5
    ; check if player one or two
    lda player_number_on_regular_status_bar
    lsr
    bcs copy_score
    ; copy score from player two
    ldy #19
copy_score
    ldx #5
copy_score_to_last_score_loop
    lda score_on_regular_status_bar,x
    sta score_last_status_bar,y
    dey
    dex
    bpl copy_score_to_last_score_loop
    lda neighbour_cell_contents
    cmp #8
    beq calculate_next_cave_number_and_difficulty_level
    lda cave_number
    cmp #16
    bpl calculate_next_cave_number_and_difficulty_level
    ; check for zero men left for the current player
    lda #sprite_0
    cmp men_number_on_regular_status_bar
    bne swap_status_bars_with_inactive_player_versions
    ; check for zero men left for other player
    cmp number_of_men_on_inactive_players_and_men_status_bar
    beq return16
swap_status_bars_with_inactive_player_versions
    ldx #39
swap_loop
    lda regular_status_bar,x
    ldy inactive_players_regular_status_bar,x
    sta inactive_players_regular_status_bar,x
    tya
    sta regular_status_bar,x
    dex
    bpl swap_loop
    lda men_number_on_regular_status_bar
    cmp #sprite_0
    beq swap_status_bars_with_inactive_player_versions
    lda cave_letter_on_regular_status_bar
    ldx difficulty_level_on_regular_status_bar
    jsr set_cave_number_and_difficulty_level_from_status_bar
    jmp play_next_life

calculate_next_cave_number_and_difficulty_level
    ldx cave_number
    ldy difficulty_level
    lda cave_play_order,x
    sta cave_number
    bne store_cave_number_and_difficulty_level
    iny
    cpy #6
    bne store_cave_number_and_difficulty_level
    ldy #1
store_cave_number_and_difficulty_level
    sty difficulty_level
    sta cave_number
    cmp #$10
    bmi play_next_life
    ; bonus life awarded on bonus level
    inc men_number_on_regular_status_bar
    jmp play_next_life

set_cave_number_and_difficulty_level_from_status_bar
    sec
    sbc #'A'
    sta cave_number
    txa
    sec
    sbc #sprite_0
    sta difficulty_level
return16
    rts

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
    ldy #$00                           ; Set column start to 0
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
; For a given cave number and selected BD version, find the cave group file to load from disk
; Load the file using a system method, then copy the cave data from the load area to the program useage area
;
load_cave_file
    ldy cave_number
    cpy load_cave_number_stored        ; Check if the cave is already stored
    beq cave_already_loaded            ; Skip if already loaded

    lda load_group_for_cave_number,y
    cmp load_group_stored              ; Check if the cave is in the group of caves (group 1 or 2) already loaded
    beq move_cave_to_usage_area        ; Move onto getting the cave contents if group is already loaded
    sta load_group_stored

    lda bd_version_to_play             ; Get the version file name offset from the version selected to play
    asl                                ; (multiply version number by 4 for the offset)
    asl
    tay
    ldx #0
set_version_filename                   ; Build the cave group file name using the version selected to play
    lda bd_version_files,y
    sta load_file_name,x
    iny
    inx
    cpx #4
    bne set_version_filename
    lda #"-"                           ; Add the suffix "-" and the cave group number, ending with a file name e.g. "BD01-1
    sta load_file_name,x
    inx
    lda load_group_stored              ; Turn the cave group number into a digit
    clc
    adc #48
    sta load_file_name,x

    ldy #>system_load_command          ; Set x,y for system LOAD command address
    ldx #<system_load_command          ; Set x,y for system LOAD command address
    jsr oscli_instruction_for_load     ; Call the LOAD command

move_cave_to_usage_area

    ; Copy cave from load area into area used in program
    ldy cave_number  ;cave number starts from zero
    sty load_cave_number_stored
    lda cave_load_slot,y  ;find which of the 10 'slots' the cave is located in
    tay

    lda cave_addr_low,y
    sta screen_addr1_low  ;source low
    lda cave_addr_high,y
    sta screen_addr1_high  ;source high

    lda #<cave_parameter_data
    sta screen_addr2_low  ;target low
    lda #>cave_parameter_data
    sta screen_addr2_high  ;target high

    ;size is always 448 bytes per cave
    lda #$c0
    sta copy_size  
    lda #1
    sta copy_size+1

    jsr copy_memory  ;copy from source to target for given size

cave_already_loaded
    rts

bd_version_to_play
    !byte 0
load_group_stored
    !byte $ff                          ; Always load cave group initially
load_cave_number_stored
    !byte $ff                          ; Initially cave $ff isn't a valid cave, so will always loads cave A
system_load_command
    !byte $4c, $4f, $2e                ; Is "LO." for the short system LOAD command
load_file_name
    !fill 6,0                          ; Cave group file name e.g. BD01-1 for Boulder Dash 1 cave group 1 (of 2)
system_load_end
    !byte $0d                          ; Termination for LOAD command

; ****************************************************************************************************
load_spriteset

    lda bd_sprites_to_use
    cmp sprite_set_stored
    beq spriteset_already_loaded
    sta sprite_set_stored
    asl                                ; (multiply version number by 8 for the offset)
    asl
    asl
    tay
    ldx #0
set_spriteset_filename                   ; Build the cave group file name using the version selected to play
    lda bd_sprites_files,y
    sta load_file_name,x
    iny
    inx
    cpx #6
    bne set_spriteset_filename

    ldy #>system_load_command          ; Set x,y for system LOAD command address
    ldx #<system_load_command          ; Set x,y for system LOAD command address
    jsr oscli_instruction_for_load     ; Call the LOAD command

spriteset_already_loaded
    rts

bd_sprites_to_use
    !byte 0
sprite_set_stored
    !byte 0

; *************************************************************************************
; Copy a number of bytes (in copy size variable) from source to target memory locations
copy_memory

    ldy #0
    ldx copy_size+1
    beq copy_remaining_bytes
copy_a_page
    lda (screen_addr1_low),y
    sta (screen_addr2_low),y
    iny
    bne copy_a_page
    inc screen_addr1_high
    inc screen_addr2_high
    dex
    bne copy_a_page
copy_remaining_bytes
    ldx copy_size
    beq copy_return
copy_a_byte
    lda (screen_addr1_low),y
    sta (screen_addr2_low),y
    iny
    dex
    bne copy_a_byte

copy_return
    rts

copy_size
    !byte 0, 0

; *************************************************************************************
; Clear a number of bytes in target memory locations, using clear_size and clear_to
clear_memory

    ldy #0
    ldx clear_size+1
    beq clear_remaining_bytes
clear_a_page
    lda clear_to
    sta (screen_addr2_low),y
    iny
    bne clear_a_page
    inc screen_addr2_high
    dex
    bne clear_a_page
clear_remaining_bytes
    ldx clear_size
    beq clear_return
clear_a_byte
    lda clear_to
    sta (screen_addr2_low),y
    iny
    dex
    bne clear_a_byte

clear_return
    rts

clear_size
    !byte 0, 0
clear_to
    !byte 0

; ****************************************************************************************************
; Populate Cave from file loaded data. Split bytes into 2 nibbles, each one representing a tile value
; ****************************************************************************************************
populate_cave_from_file
    lda #>cave_map_data                ; Point to cave address (high byte)
    sta plot_cave_tiles_x2+2           ; Store in self-modifying code location
    lda #<cave_map_data                ; Point to cave address (low byte)
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

; *************************************************************************************
reset_tune
    lda #osbyte_flush_buffer_class
    ldx #0
    jsr osbyte                         ; Flush all buffers (X=0)
    ldx #5
reset_tune_loop
    lda tune_start_position_per_channel,x
    sta tune_position_per_channel,x
    dex
    bpl reset_tune_loop
    rts

; *************************************************************************************
update_tune
    lda #0
    sta sound_channel
update_channels_loop
    lda #$fa
    sec
    sbc sound_channel
    tax
    ldy #$ff
    lda #osbyte_read_adc_or_get_buffer_status
    jsr osbyte                         ; Read buffer status or ADC channel
    txa
    beq move_to_next_tune_channel
    ldx sound_channel
    txa
    asl
    asl
    asl
    sta offset_to_sound
    lda tune_position_per_channel,x
    tay
    cpx #0
    bne skip_end_of_tune_check
    cpy #$41
    beq reset_tune
skip_end_of_tune_check
    lda tune_pitches_and_commands,y
    cmp #200
    bcc note_found
    tay
    lda tune_note_repeat_per_channel,x
    bne skip_reset_note_repeat
    lda command_note_repeat_counts-200,y
    sta tune_note_repeat_per_channel,x
skip_reset_note_repeat
    lda command_pitch-200,y
    pha
    lda command_note_durations - 200,y
    tay
    pla
    dec tune_note_repeat_per_channel,x
    bpl inc_tune
note_found
    pha
    and #3
    tay
    lda #0
    sta tune_note_repeat_per_channel,x
    lda tune_note_durations_table,y
    tay
    pla
    and #$fc
    ora #1
inc_tune
    pha
    lda tune_note_repeat_per_channel,x
    bne skip_increment_tune_position
    inc tune_position_per_channel,x
skip_increment_tune_position
    pla
    ldx offset_to_sound
    sta sound1_pitch,x
    tya
    sta sound1_duration,x
    txa
    clc
    adc #<sound1
    tax
    ldy #>sound1
    lda #osword_sound
    jsr osword                         ; SOUND command
move_to_next_tune_channel
    inc sound_channel
    ldx sound_channel
    cpx #3
    bne update_channels_loop
    rts

; *************************************************************************************
!source "vars1.asm"

; *************************************************************************************
; Load area for 10 caves. Caves for a BD version are stored in 2 groups of 10 caves each
;IMPORTANT: Address must not change as it corresponds to the SD file load address
* = $3e80

; *************************************************************************************
; Cave tile map. Each row has 40 bytes used for the tiles in the game 
; and 24 unused (repurposed with table variables to not waste memory)
; IMPORTANT: Address must be $4000, $5000 etc, not $4100 for example!
* = $5000
!source "vars2.asm"

; *************************************************************************************
; Cave data. Loaded data is placed here for cave parameters and map used in the game
* = $5640
!source "cavedata.asm"

; *************************************************************************************
; Screen memory. MODE 5 layout for graphics 160x256, colours 4, text 20x32
; Big Rockford splashscreen also loaded here
* = $5800
big_rockford_destination_screen_address
