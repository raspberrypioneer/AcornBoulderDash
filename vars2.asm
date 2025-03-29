; *************************************************************************************
tile_map_row_0
    !fill 40,0
current_status_bar_sprites
    !byte sprite_1
    !byte sprite_slash
    !text "A=EVAC"
    !byte sprite_space
    !byte sprite_space
    !byte sprite_space
    !byte sprite_space
    !text "REYALP"
    !byte sprite_space
    !byte sprite_1
    !fill 4,0

; *************************************************************************************
tile_map_row_1
    !fill 40,0
default_status_bar
    !text "PLAYER"
    !byte sprite_space
    !byte sprite_1
    !byte sprite_comma
    !byte sprite_space
    !byte sprite_3
    !byte sprite_space
    !text "MEN"
    !byte sprite_space
    !byte sprite_space
    !text "A"
    !byte sprite_slash
    !byte sprite_2
    !fill 4,0

; *************************************************************************************
tile_map_row_2
    !fill 40,0
; these are the cell types (indices into the table 'cell_type_to_sprite') that update
; every tick due to animation
cell_types_that_always_animate
    !byte                   map_diamond
    !byte map_anim_state4 | map_diamond
    !byte                   map_firefly
    !byte map_anim_state1 | map_firefly
    !byte map_anim_state2 | map_firefly
    !byte map_anim_state3 | map_firefly
exit_cell_type
    !byte                   map_active_exit
    !byte map_anim_state1 | map_magic_wall
    !byte                   map_butterfly
    !byte map_anim_state1 | map_butterfly
    !byte map_anim_state2 | map_butterfly
    !byte map_anim_state3 | map_butterfly
    !byte map_anim_state2 | map_rockford
    !byte map_anim_state1 | map_rockford
    !byte map_slime
    !byte 0
    !fill 8,0

; *************************************************************************************
tile_map_row_3
    !fill 40,0
; Given a cell type, get the type of collision:
; $ff means rockford can move onto the cell freely (e.g. space, earth),
; $0 means no movement possible (e.g. wall), and
; $1 means move with a push (e.g rock)
collision_for_cell_type
    !byte $ff                                               ; map_space
    !byte $ff                                               ; map_earth
    !byte 0                                                 ; map_wall
    !byte 0                                                 ; map_titanium_wall
    !byte $ff                                               ; map_diamond
    !byte 1                                                 ; map_rock
    !byte 0                                                 ; map_firefly
    !byte 0                                                 ; map_amoeba
    !byte 0                                                 ; map_rockford_appearing_or_end_position
    !byte 0                                                 ; map_slime
    !byte $ff                                               ; map_explosion
    !byte 0                                                 ; map_bomb
    !byte 0                                                 ; map_growing_wall
    !byte 0                                                 ; map_magic_wall
    !byte 0                                                 ; map_butterfly
    !byte 1                                                 ; map_rockford
    !fill 8,0

; *************************************************************************************
tile_map_row_4
    !fill 40,0
cell_types_that_rocks_or_diamonds_will_fall_off
    !byte 0                                                 ; map_space
    !byte 0                                                 ; map_earth
    !byte 1                                                 ; map_wall
    !byte 0                                                 ; map_titanium_wall
    !byte 1                                                 ; map_diamond
    !byte 1                                                 ; map_rock
    !byte 0                                                 ; map_firefly
    !byte 1                                                 ; map_amoeba
    !byte 0                                                 ; map_rockford_appearing_or_end_position
    !byte 0                                                 ; map_slime
    !byte 0                                                 ; map_explosion
    !byte 0                                                 ; map_bomb
    !byte 1                                                 ; map_growing_wall
    !byte 0                                                 ; map_magic_wall
    !byte 0                                                 ; map_butterfly
    !byte 0                                                 ; map_rockford
    !fill 8,0

; *************************************************************************************
tile_map_row_5
    !fill 40,0
update_cell_type_when_below_a_falling_rock_or_diamond
    !byte 0                                                 ; map_space
    !byte 0                                                 ; map_earth
    !byte 0                                                 ; map_wall
    !byte 0                                                 ; map_titanium_wall
    !byte 0                                                 ; map_diamond
    !byte 0                                                 ; map_rock
    !byte map_start_large_explosion                         ; map_firefly
    !byte 0                                                 ; map_amoeba
    !byte 0                                                 ; map_rockford_appearing_or_end_position
    !byte 0                                                 ; map_slime
    !byte 0                                                 ; map_explosion
    !byte map_start_large_explosion                         ; map_bomb
    !byte 0                                                 ; map_growing_wall
    !byte map_anim_state3 | map_magic_wall                  ; map_magic_wall
    !byte map_anim_state4 | map_butterfly                   ; map_butterfly
    !byte map_anim_state7 | map_rockford                    ; map_rockford
    !fill 8,0

; *************************************************************************************
tile_map_row_6
    !fill 40,0
; IMPORTANT: don't move this section
explosion_replacements
    !byte map_rockford | map_unprocessed
    !byte map_rockford | map_unprocessed
    !byte map_diamond | map_unprocessed
    !byte map_space
    !byte $f1
    !byte $d1
    !byte $b6
    !byte $b1
    !byte $8f
    !byte $8f
    !byte $d1
    !byte $f1
    !byte $b1
    !byte $71
    !byte 0
    !byte $71
    !fill 8,0

; *************************************************************************************
tile_map_row_7
    !fill 40,0
items_allowed_through_slime
    !byte 0                                                 ; map_space
    !byte 0                                                 ; map_earth
    !byte 0                                                 ; map_wall
    !byte 0                                                 ; map_titanium_wall
    !byte map_unprocessed | map_diamond                     ; map_diamond
    !byte map_unprocessed | map_rock                        ; map_rock
    !byte 0                                                 ; map_firefly
    !byte 0                                                 ; map_amoeba
    !byte 0                                                 ; map_rockford_appearing_or_end_position
    !byte 0                                                 ; map_slime
    !byte 0                                                 ; map_explosion
    !byte map_unprocessed | map_bomb                        ; map_bomb
    !byte 0                                                 ; map_growing_wall
    !byte 0                                                 ; map_magic_wall
    !byte 0                                                 ; map_butterfly
    !byte 0                                                 ; map_rockford
    !fill 8,0

; *************************************************************************************
tile_map_row_8
    !fill 40,0
cell_types_that_will_turn_into_diamonds
    !byte map_unprocessed | map_diamond                     ; map_space
    !byte map_unprocessed | map_diamond                     ; map_earth
    !byte map_unprocessed | map_diamond                     ; map_wall
    !byte 0                                                 ; map_titanium_wall
    !byte map_unprocessed | map_diamond                     ; map_diamond
    !byte map_unprocessed | map_diamond                     ; map_rock
    !byte map_unprocessed | map_diamond                     ; map_firefly
    !byte map_unprocessed | map_diamond                     ; map_amoeba
    !byte 0                                                 ; map_rockford_appearing_or_end_position
    !byte map_unprocessed | map_diamond                     ; map_slime
    !byte 0                                                 ; map_explosion
    !byte 0                                                 ; map_bomb
    !byte map_unprocessed | map_diamond                     ; map_growing_wall
    !byte map_unprocessed | map_diamond                     ; map_magic_wall
    !byte map_unprocessed | map_diamond                     ; map_butterfly
    !byte $ff                                               ; map_rockford
    !fill 8,0

; *************************************************************************************
tile_map_row_9
    !fill 40,0
items_produced_by_the_magic_wall
    !byte 0                                                 ; map_space
    !byte 0                                                 ; map_earth
    !byte 0                                                 ; map_wall
    !byte 0                                                 ; map_titanium_wall
    !byte map_unprocessed | map_rock                        ; map_diamond
    !byte map_unprocessed | map_diamond                     ; map_rock
    !byte 0                                                 ; map_firefly
    !byte 0                                                 ; map_amoeba
    !byte 0                                                 ; map_rockford_appearing_or_end_position
    !byte 0                                                 ; map_slime
    !byte 0                                                 ; map_explosion
    !byte 0                                                 ; map_bomb
    !byte 0                                                 ; map_growing_wall
    !byte 0                                                 ; map_magic_wall
    !byte 0                                                 ; map_butterfly
    !byte 0                                                 ; map_rockford
    !fill 8,0

; *************************************************************************************
tile_map_row_10
    !fill 40,0
cave_play_order
    !byte 1                                                 ; Cave A
    !byte 2                                                 ; Cave B
    !byte 3                                                 ; Cave C
    !byte 16                                                ; Cave D
    !byte 5                                                 ; Cave E
    !byte 6                                                 ; Cave F
    !byte 7                                                 ; Cave G
    !byte 17                                                ; Cave H
    !byte 9                                                 ; Cave I
    !byte 10                                                ; Cave J
    !byte 11                                                ; Cave K
    !byte 18                                                ; Cave L
    !byte 13                                                ; Cave M
    !byte 14                                                ; Cave N
    !byte 15                                                ; Cave O
    !byte 19                                                ; Cave P
    !byte 4                                                 ; Cave Q
    !byte 8                                                 ; Cave R
    !byte 12                                                ; Cave S
    !byte 0                                                 ; Cave T
    !fill 4,0

; *************************************************************************************
tile_map_row_11
    !fill 40,0
; IMPORTANT: don't move this section
cell_types_that_will_turn_into_large_explosion
    !byte map_unprocessed | map_large_explosion_state3      ; map_space
    !byte map_unprocessed | map_large_explosion_state3      ; map_earth
    !byte map_unprocessed | map_large_explosion_state3      ; map_wall
    !byte 0                                                 ; map_titanium_wall
    !byte map_unprocessed | map_large_explosion_state3      ; map_diamond
    !byte map_unprocessed | map_large_explosion_state3      ; map_rock
    !byte map_unprocessed | map_large_explosion_state3      ; map_firefly
    !byte map_unprocessed | map_large_explosion_state3      ; map_amoeba
    !byte 0                                                 ; map_rockford_appearing_or_end_position
    !byte map_unprocessed | map_large_explosion_state3      ; map_slime
    !byte 0                                                 ; map_explosion
    !byte map_unprocessed | map_large_explosion_state3      ; map_bomb
    !byte map_unprocessed | map_large_explosion_state3      ; map_growing_wall
    !byte map_unprocessed | map_large_explosion_state3      ; map_magic_wall
    !byte map_unprocessed | map_large_explosion_state3      ; map_butterfly
    !byte $ff                                               ; map_rockford
    !fill 8,0

; *************************************************************************************
tile_map_row_12
    !fill 40,0
;Updated - all caves, all difficulty levels are selectable from the menu by default
number_of_difficulty_levels_available_in_menu_for_each_cave
    !fill 16, 5                                             ; Caves A to P
    !fill 4, $80                                            ; Intermission/Bonus caves Q to T
    !fill 4,0

; *************************************************************************************
tile_map_row_13
    !fill 40,0
load_group_for_cave_number
    !fill 8,1                                               ; group 1 for A,B,C,D,E,F,G,H,Q,R
    !fill 8,2                                               ; group 2 for I,J,K,L,M,N,O,P,S,T
    !byte 1,1,2,2
    !fill 4,0

; *************************************************************************************
tile_map_row_14
    !fill 40,0
bd_version_files  ;prefixes of cave file names for each version
    !scr "BD01"
    !scr "BD02"
    !scr "BD03"
    !scr "BDP1"
    !scr "AD01"
    !scr "BB01"

; *************************************************************************************
tile_map_row_15
    !fill 40,0
cave_load_slot
    !byte 0,1,2,3,4,5,6,7,0,1,2,3,4,5,6,7,8,9,8,9
    !fill 4,0

; *************************************************************************************
tile_map_row_16
    !fill 40,0
cave_addr_high
    !byte $3e, $40, $42, $43, $45, $47, $49, $4a, $4c, $4e
    !byte $3e, $40, $42, $43, $45, $47, $49, $4a, $4c, $4e
    !fill 4,0

; *************************************************************************************
tile_map_row_17
    !fill 40,0
cave_addr_low
    !byte $80, $40, $00, $c0, $80, $40, $00, $c0, $80, $40
    !byte $80, $40, $00, $c0, $80, $40, $00, $c0, $80, $40
    !fill 4,0

; *************************************************************************************
tile_map_row_18
    !fill 40,0
version_option_text_high
    !byte >version1_text, >version2_text, >version3_text, >version4_text, >version5_text, >version6_text
version_option_text_low
    !byte <version1_text, <version2_text, <version3_text, <version4_text, <version5_text, <version6_text
version_option_screen_high
sprites_on_screen_high
    !byte $5e, $63, $68, $6d, $72, $77
    !fill 6,0

; *************************************************************************************
tile_map_row_19
    !fill 40,0
version1_text
    !fill 1, sprite_space
    !byte sprite_rockford_blinking1
    !fill 1, sprite_space    
    !text "BOULDER"
    !byte sprite_space
    !text "DASH"
    !byte sprite_space
    !byte sprite_1
    !fill 2,sprite_space
    !fill 5,0

; *************************************************************************************
tile_map_row_20
    !fill 40,0
version2_text
    !fill 3, sprite_space
    !text "BOULDER"
    !byte sprite_space
    !text "DASH"
    !byte sprite_space
    !byte sprite_2
    !fill 3,sprite_space
    !fill 4,0

tile_map_row_21
    !fill 40,0
version3_text
    !fill 3, sprite_space
    !text "BOULDER"
    !byte sprite_space
    !text "DASH"
    !byte sprite_space
    !byte sprite_3
    !fill 3,sprite_space
    !fill 4,0

tile_map_row_22
    !fill 40,0
version4_text
    !fill 3, sprite_space
    !text "BOULDER"
    !byte sprite_space
    !text "DASH"
    !byte sprite_space
    !text "X"
    !byte sprite_1
    !fill 2,sprite_space
    !fill 4,0

tile_map_row_23
    !fill 40,0
version5_text
    !fill 3, sprite_space
    !text "ARNO"
    !byte sprite_space
    !text "DASH"
    !byte sprite_space
    !byte sprite_1
    !fill 6, sprite_space
    !fill 4,0

tile_below_store_row
    !fill 40,0
version6_text
    !fill 3, sprite_space
    !text "BONUS"
    !byte sprite_space
    !text "CAVES"
    !byte sprite_space
    !byte sprite_1
    !fill 4, sprite_space
    !fill 4,0
