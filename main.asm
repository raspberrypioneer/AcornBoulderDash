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
reset_grid_of_sprites
    ldx #$f0                                                                            ; 2292: a2 f0       ..
    lda #$ff                                                                            ; 2294: a9 ff       ..
reset_grid_of_sprites_loop
    dex                                                                                 ; 2296: ca          .
    sta grid_of_currently_displayed_sprites,x                                           ; 2297: 9d 00 0c    ...
    bne reset_grid_of_sprites_loop                                                      ; 229a: d0 fa       ..

reset_status_bar  ; clear the current status bar
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
    ora #>tile_map_row_0
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
    lda param_intermission
    beq skip_bonus_stage
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

; *************************************************************************************
wait_for_13_centiseconds_and_read_keys
    lda #$0d                                                                            ; 2b90: a9 0d       ..
wait_for_a_centiseconds_and_read_keys
    sta wait_delay_centiseconds                                                         ; 2b92: 85 84       ..
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

    ; map complete: draw cave borders
    jsr set_ptr_to_start_of_map                                                         ; 2e3c: 20 1a 2a     .*
    ; loop over all rows, plotting side borders from the cave file
    ldx #22                                                                             ; 2e3f: a2 16       ..
write_left_and_right_borders_loop
    ldy #39                                                                             ; 2e41: a0 27       .'
hide_cells_loop
    lda (ptr_low),y                                                                     ; 2e48: b1 8c       ..
    ora #$80                                                                            ; 2e4a: 09 80       ..
    sta (ptr_low),y                                                                     ; 2e4c: 91 8c       ..
    dey                                                                                 ; 2e4e: 88          .
    bne hide_cells_loop                                                                 ; 2e4f: d0 f7       ..
    lda (ptr_low),y
    ora #$80
    sta (ptr_low),y                                                                     ; 2e53: 91 8c       ..
    lda #$40                                                                            ; 2e55: a9 40       .@
    jsr add_a_to_ptr                                                                    ; 2e57: 20 40 22     @"
    dex                                                                                 ; 2e5a: ca          .
    bne write_left_and_right_borders_loop                                               ; 2e5b: d0 e4       ..
    ; write the top and bottom borders using param_border_tile (steelwall if zero)
    lda param_border_tile
    ora #$80
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
    lda #sprite_diamond1                                                                ; 2f25: a9 03       ..
    sta regular_status_bar                                                              ; 2f27: 8d 00 32    ..2
    sta regular_status_bar+1                                                            ; 2f2a: 8d 01 32    ..2
    ; open the exit
    ldy #0                                                                              ; 2f2d: a0 00       ..
    lda #map_active_exit                                                                ; 2f2f: a9 18       ..
    sta (map_rockford_end_position_addr_low),y                                          ; 2f31: 91 6a       .j
    ; set total diamonds to zero
    lda #sprite_0                                                                       ; 2f33: a9 32       .2
    sta total_diamonds_on_status_bar_high_digit                                         ; 2f35: 8d 03 32    ..2
    sta total_diamonds_on_status_bar_low_digit                                          ; 2f38: 8d 04 32    ..2
    ; show score per diamond on status bar
    lda param_diamond_extra_value                                                       ; 2f3d: bd 14 4b    ..K
    ldy #4                                                                              ; 2f40: a0 04       ..
    jsr add_a_to_status_bar_number_at_y                                                 ; 2f42: 20 c0 28     .(
    ; play sound 6
    inc sound6_active_flag                                                              ; 2f45: e6 4c       .L
return12
    rts                                                                                 ; 2f47: 60          `

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

    ; set and show initial diamond score amount on status bar
    lda param_diamond_value                                                             ; 2f64: bd 00 4b    ..K
    ldy #4                                                                              ; 2f67: a0 04       ..
    jsr add_a_to_status_bar_number_at_y                                                 ; 2f69: 20 c0 28     .(

    ; show cave letter on status bar
    lda cave_number                                                                     ; 2f6c: 8a          .
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
    bcs toggle_one_or_two_players  ;enter key toggles the number of players
    asl                                                                                 ; 3a76: 0a          .
    bcs return15  ;"b" key returns and displays scrolling credits
    asl                                                                                 ; 3a79: 0a          .
    bcs show_rockford_again_and_play_game  ;space key starts game
    asl
    bcs return_to_version_selection  ;escape key returns to version selection screen
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
    lda number_of_difficulty_levels_available_in_menu_for_each_cave,x                   ; 3aa5: bd 68 4c    .hL
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
    jsr load_spriteset
    jsr initialise_and_play_game                                                        ; 3adb: 20 00 3b     .;
    jmp show_menu                                                                       ; 3ade: 4c 00 3a    L.:

return15
    rts                                                                                 ; 3ae1: 60          `

return_to_version_selection
    jmp select_version_to_play

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
    ; copy difficulty level to other status bars
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
    cmp number_of_difficulty_levels_available_in_menu_for_each_cave,x                   ; 3b43: dd 68 4c    .hL
    bmi skip_adding_new_difficulty_level_to_menu                                        ; 3b46: 30 03       0.
    ; add new difficulty level to menu
    sta number_of_difficulty_levels_available_in_menu_for_each_cave,x                   ; 3b48: 9d 68 4c    .hL
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
    beq calculate_next_cave_number_and_difficulty_level                                 ; 3b68: f0 37       .7
    lda cave_number                                                                     ; 3b6a: a5 87       ..
    cmp #16                                                                             ; 3b6c: c9 10       ..
    bpl calculate_next_cave_number_and_difficulty_level                                 ; 3b6e: 10 31       .1
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

calculate_next_cave_number_and_difficulty_level
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
