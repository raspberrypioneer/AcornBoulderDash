; *************************************************************************************
tile_map_row_0
    !fill 40,0
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
    !fill 4,0

; *************************************************************************************
tile_map_row_1
    !fill 40,0
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
    !fill 4,0

; *************************************************************************************
tile_map_row_2
    !fill 40,0
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
    !byte 0                                                                             ; 21fb: 00          .              ; map_bomb
    !byte 0                                                                             ; 21fc: 00          .              ; map_growing_wall
    !byte 0                                                                             ; 21fd: 00          .              ; map_magic_wall
    !byte 0                                                                             ; 21fe: 00          .              ; map_butterfly
    !byte 1                                                                             ; 21ff: 01          .              ; map_rockford
    !fill 8,0

; *************************************************************************************
tile_map_row_4
    !fill 40,0
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
    !fill 8,0

; *************************************************************************************
tile_map_row_5
    !fill 40,0
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
    !fill 8,0

; *************************************************************************************
tile_map_row_6
    !fill 40,0
; IMPORTANT: don't move this section
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
    !fill 8,0

; *************************************************************************************
tile_map_row_7
    !fill 40,0
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
    !fill 8,0

; *************************************************************************************
tile_map_row_8
    !fill 40,0
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
    !fill 8,0

; *************************************************************************************
tile_map_row_9
    !fill 40,0
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
    !fill 8,0

; *************************************************************************************
tile_map_row_10
    !fill 40,0
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
    !fill 4,0

; *************************************************************************************
tile_map_row_11
    !fill 40,0
; IMPORTANT: don't move this section
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
    !fill 8,0

; *************************************************************************************
tile_map_row_12
    !fill 40,0
;Updated - all caves, all difficulty levels are selectable from the menu by default
number_of_difficulty_levels_available_in_menu_for_each_cave
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
    !fill 4,0

; *************************************************************************************
tile_map_row_13
    !fill 40,0
load_group_for_cave_number
    !byte 1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,1,1,2,2  ;group 1 for A,B,C,D,E,F,G,H,Q,R and group 2 for I,J,K,L,M,N,O,P,S,T
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
