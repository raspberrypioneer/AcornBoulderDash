; *************************************************************************************
; Sprite handler routine addresses
;
handler_table_low
    !byte <handler_basics                                   ; map_space
    !byte <handler_basics                                   ; map_earth
    !byte <handler_basics                                   ; map_wall
    !byte <handler_basics                                   ; map_titanium_wall
    !byte 0                                                 ; map_diamond
    !byte 0                                                 ; map_rock
    !byte <handler_firefly_or_butterfly                     ; map_firefly
    !byte <handler_amoeba                                   ; map_amoeba
    !byte <handler_rockford_intro_or_exit                   ; map_rockford_appearing_or_end_position
    !byte <handler_slime                                    ; map_slime
    !byte <handler_rockford_intro_or_exit                   ; map_explosion
    !byte 0                                                 ; map_bomb (special handler)
    !byte <handler_growing_wall                             ; map_growing_wall
    !byte <handler_magic_wall                               ; map_magic_wall
    !byte <handler_firefly_or_butterfly                     ; map_butterfly
    !byte <handler_rockford                                 ; map_rockford
handler_table_high
    !byte >handler_basics                                   ; map_space
    !byte >handler_basics                                   ; map_earth
    !byte >handler_basics                                   ; map_wall
    !byte >handler_basics                                   ; map_titanium_wall
    !byte 0                                                 ; map_diamond
    !byte 0                                                 ; map_rock
    !byte >handler_firefly_or_butterfly                     ; map_firefly
    !byte >handler_amoeba                                   ; map_amoeba
    !byte >handler_rockford_intro_or_exit                   ; map_rockford_appearing_or_end_position
    !byte >handler_slime                                    ; map_slime
    !byte >handler_rockford_intro_or_exit                   ; map_explosion
    !byte 0                                                 ; map_bomb (special handler)
    !byte >handler_growing_wall                             ; map_growing_wall
    !byte >handler_magic_wall                               ; map_magic_wall
    !byte >handler_firefly_or_butterfly                     ; map_butterfly
    !byte >handler_rockford                                 ; map_rockford

; *************************************************************************************
sprite_to_next_sprite
    !byte sprite_space
    !byte sprite_boulder1
    !byte sprite_boulder2
    !byte sprite_diamond2
    !byte sprite_diamond3
    !byte sprite_diamond4
    !byte sprite_diamond1
    !byte $60
    !byte sprite_titanium_wall2
    !byte $67
    !byte $61
    !byte sprite_wall2
    !byte sprite_explosion1
    !byte sprite_explosion2
    !byte sprite_explosion3
;TODO: part of sprite_to_next_sprite data
    !byte $0f, $11, $12, $13, $10, $14, $15, $17, $18, $62, $1a, $1b, $1c, $1a, $1d
    !byte $68, $1f, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2b, $2c, $2d
    !byte $63, $2f, $30, $31, $65

    !byte sprite_0
    !byte sprite_0
    !byte sprite_diamond1
    !byte sprite_0
    !byte sprite_0
    !byte $0a
    !byte sprite_8
    !byte sprite_2
    !byte sprite_2
    !byte sprite_space
    !byte sprite_0
    !byte sprite_0
    !byte sprite_0
    !byte sprite_space
    !byte sprite_7
    !byte sprite_7
    !byte sprite_6
    !byte sprite_4
    !byte sprite_7
    !byte sprite_6
    !text "PLAYER"
    !byte sprite_space
    !byte sprite_1
    !byte sprite_comma
    !byte sprite_space
    !byte sprite_3
    !byte sprite_space
    !text "MEN"
    !byte sprite_space
    !text "A"
    !byte sprite_slash
    !byte sprite_1
    !byte sprite_space

    !byte $5a, $5b, $5c, $5d, $5e, $5f,   7, $0a, $16, $64, $2a, $66, $2e,   9, $1e
    !byte $69, $6a, $6b, $6c, $6d, $6e, $6f, $70, $71, $72, $73, $74, $75, $76, $77
    !byte $78, $79, $7a, $7b, $7c, $7d, $7e, $7f

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
    !byte sprite_space                                      ; cell type $00 = map_space
    !byte sprite_earth2                                     ; cell type $01 = map_earth
    !byte sprite_wall2                                      ; cell type $02 = map_wall
    !byte sprite_titanium_wall2                             ; cell type $03 = map_titanium_wall
    !byte sprite_diamond1                                   ; cell type $04 = map_diamond
    !byte sprite_boulder1                                   ; cell type $05 = map_rock
    !byte sprite_firefly4                                   ; cell type $06 = map_firefly
amoeba_animated_sprite0
    !byte sprite_amoeba1                                    ; cell type $07 = map_amoeba
    !byte sprite_earth2                                     ; cell type $08 = map_rockford_appearing_or_end_position
slime_animated_sprite0
    !byte sprite_amoeba1                                    ; cell type $09 = map_slime
    !byte $4c                                               ; cell type $0A = map_explosion
    !byte sprite_bomb1                                      ; cell type $0B = map_bomb
    !byte sprite_magic_wall1                                ; cell type $0C = map_growing_wall
    !byte sprite_wall2                                      ; cell type $0D = map_magic_wall
    !byte sprite_butterfly1                                 ; cell type $0E = map_butterfly
rockford_sprite
    !byte sprite_rockford_tapping_foot1                     ; cell type $0F = map_rockford

    !byte sprite_explosion4                                 ; cell type $10 = map_space | map_anim_state1
    !byte sprite_explosion4                                 ; cell type $11 = map_earth | map_anim_state1
    !byte sprite_explosion4                                 ; cell type $12 = map_wall | map_anim_state1
    !byte sprite_explosion4                                 ; cell type $13 = map_large_explosion_state1
    !byte sprite_rockford_winking2                          ; cell type $14 = map_diamond | map_anim_state1
    !byte sprite_boulder2                                   ; cell type $15 = map_rock | map_anim_state1
    !byte sprite_firefly4                                   ; cell type $16 = map_firefly | map_anim_state1
    !byte sprite_amoeba1                                    ; cell type $17 = map_amoeba | map_anim_state1
    !byte sprite_box                                        ; cell type $18 = map_active_exit
    !byte sprite_amoeba1                                    ; cell type $19 = map_slime | map_anim_state1
    !byte sprite_firefly4                                   ; cell type $1A = map_explosion | map_anim_state1
    !byte sprite_bomb2                                      ; cell type $1B = map_bomb | map_anim_state1
    !byte sprite_magic_wall1                                ; cell type $1C = map_growing_wall | map_anim_state1
    !byte sprite_magic_wall1                                ; cell type $1D = map_magic_wall | map_anim_state1
    !byte sprite_butterfly1                                 ; cell type $1E = map_butterfly | map_anim_state1
    !byte sprite_rockford_moving_left3                      ; cell type $1F = map_rockford | map_anim_state1

    !byte sprite_explosion3                                 ; cell type $20 = map_space | map_anim_state2
    !byte sprite_explosion3                                 ; cell type $21 = map_earth | map_anim_state2
    !byte sprite_explosion3                                 ; cell type $22 = map_wall | map_anim_state2
    !byte sprite_explosion3                                 ; cell type $23 = map_large_explosion_state2
    !byte sprite_diamond2                                   ; cell type $24 = map_diamond | map_anim_state2
    !byte sprite_bubble1                                    ; cell type $25 = map_rock | map_anim_state2
    !byte sprite_firefly4                                   ; cell type $26 = map_firefly | map_anim_state2
    !byte sprite_amoeba2                                    ; cell type $27 = map_amoeba | map_anim_state2
    !byte sprite_firefly2                                   ; cell type $28 = map_rockford_appearing_or_end_position | map_anim_state2
    !byte sprite_amoeba2                                    ; cell type $29 = map_slime | map_anim_state2
    !byte $46                                               ; cell type $2A = map_explosion | map_anim_state2
    !byte sprite_bomb3                                      ; cell type $2B = map_bomb | map_anim_state2
    !byte sprite_magic_wall1                                ; cell type $2C = map_growing_wall | map_anim_state2
    !byte sprite_wall2                                      ; cell type $2D = map_magic_wall | map_anim_state2
    !byte sprite_butterfly1                                 ; cell type $2E = map_butterfly | map_anim_state2
    !byte sprite_rockford_moving_right4                     ; cell type $2F = map_rockford | map_anim_state2

    !byte sprite_explosion2                                 ; cell type $30 = map_space | map_anim_state3
    !byte sprite_explosion2                                 ; cell type $31 = map_earth | map_anim_state3
    !byte sprite_explosion2                                 ; cell type $32 = map_wall | map_anim_state3
    !byte sprite_explosion2                                 ; cell type $33 = map_large_explosion_state3
    !byte sprite_diamond2                                   ; cell type $34 = map_diamond | map_anim_state3
    !byte sprite_boulder1                                   ; cell type $35 = map_rock | map_anim_state3
    !byte sprite_firefly4                                   ; cell type $36 = map_firefly | map_anim_state3
    !byte sprite_amoeba2                                    ; cell type $37 = map_amoeba | map_anim_state3
    !byte sprite_firefly2                                   ; cell type $38 = map_rockford_appearing_or_end_position | map_anim_state3
    !byte sprite_amoeba2                                    ; cell type $39 = map_slime | map_anim_state3
    !byte sprite_firefly4                                   ; cell type $3A = map_explosion | map_anim_state3
    !byte sprite_bomb4                                      ; cell type $3B = map_bomb | map_anim_state3
    !byte sprite_magic_wall1                                ; cell type $3C = map_growing_wall | map_anim_state3
    !byte sprite_wall2                                      ; cell type $3D = map_magic_wall | map_anim_state3
    !byte sprite_butterfly1                                 ; cell type $3E = map_butterfly | map_anim_state3
    !byte sprite_rockford_tapping_foot4                     ; cell type $3F = map_rockford | map_anim_state3

    !byte sprite_explosion1                                 ; cell type $40 = map_space | map_anim_state4
    !byte sprite_explosion1                                 ; cell type $41 = map_earth | map_anim_state4
    !byte sprite_explosion1                                 ; cell type $42 = map_wall | map_anim_state4
    !byte sprite_explosion1                                 ; cell type $43 = map_titanium_wall | map_anim_state4
    !byte sprite_diamond1                                   ; cell type $44 = map_diamond | map_anim_state4
    !byte sprite_boulder1                                   ; cell type $45 = map_rock | map_anim_state4
    !byte sprite_explosion1                                 ; cell type $46 = map_start_large_explosion
amoeba_animated_sprites4
    !byte sprite_amoeba2                                    ; cell type $47 = map_amoeba | map_anim_state4
    !byte sprite_rockford_moving_right4                     ; cell type $48 = map_rockford_appearing_or_end_position | map_anim_state4
slime_animated_sprite1
    !byte sprite_amoeba2                                    ; cell type $49 = map_slime | map_anim_state4
    !byte sprite_firefly4                                   ; cell type $4A = map_explosion | map_anim_state4
    !byte sprite_bomb1                                      ; cell type $4B = map_bomb | map_anim_state4
    !byte sprite_magic_wall1                                ; cell type $4D = map_growing_wall | map_anim_state4
    !text "A"                                               ; cell type $4C = map_magic_wall | map_anim_state4
    !byte sprite_butterfly2                                 ; cell type $4E = map_butterfly | map_anim_state4
    !byte sprite_rockford_moving_right3                     ; cell type $4F = map_rockford | map_anim_state4

    !byte sprite_explosion2                                 ; cell type $50 = map_space | map_anim_state5
    !byte sprite_explosion2                                 ; cell type $51 = map_earth | map_anim_state5
    !byte sprite_explosion2                                 ; cell type $52 = map_wall | map_anim_state5
    !byte sprite_explosion2                                 ; cell type $53 = map_titanium_wall | map_anim_state5
    !byte sprite_rockford_winking2                          ; cell type $54 = map_diamond | map_anim_state5
    !byte sprite_boulder1                                   ; cell type $55 = map_rock | map_anim_state5
    !byte sprite_firefly2                                   ; cell type $56 = map_firefly | map_anim_state5
    !byte sprite_amoeba1                                    ; cell type $57 = map_amoeba | map_anim_state5
    !byte sprite_rockford_moving_right4                     ; cell type $58 = map_rockford_appearing_or_end_position | map_anim_state5
    !byte sprite_amoeba1                                    ; cell type $59 = map_slime | map_anim_state5
    !byte sprite_firefly4                                   ; cell type $5A = map_explosion | map_anim_state5
    !byte sprite_bomb2                                      ; cell type $5B = map_bomb | map_anim_state5
    !byte sprite_magic_wall1                                ; cell type $5C = map_growing_wall | map_anim_state5
    !byte sprite_magic_wall2                                ; cell type $5D = map_magic_wall | map_anim_state5
    !byte sprite_butterfly2                                 ; cell type $5E = map_butterfly | map_anim_state5
    !byte sprite_rockford_moving_left2                      ; cell type $5F = map_rockford | map_anim_state5

    !byte sprite_explosion3                                 ; cell type $60 = map_space | map_anim_state6
    !byte sprite_explosion3                                 ; cell type $61 = map_earth | map_anim_state6
    !byte sprite_explosion3                                 ; cell type $62 = map_wall | map_anim_state6
    !byte sprite_explosion3                                 ; cell type $63 = map_titanium_wall | map_anim_state6
    !byte sprite_diamond1                                   ; cell type $64 = map_diamond | map_anim_state6
    !byte sprite_boulder1                                   ; cell type $65 = map_rock | map_anim_state6
    !byte sprite_firefly2                                   ; cell type $66 = map_firefly | map_anim_state6
    !byte sprite_amoeba1                                    ; cell type $67 = map_amoeba | map_anim_state6
    !byte sprite_rockford_moving_right4                     ; cell type $68 = map_rockford_appearing_or_end_position | map_anim_state6
    !byte sprite_amoeba1                                    ; cell type $69 = map_slime | map_anim_state6
    !byte sprite_firefly4                                   ; cell type $6A = map_explosion | map_anim_state6
    !byte sprite_bomb3                                      ; cell type $6B = map_bomb | map_anim_state6
    !byte sprite_magic_wall1                                ; cell type $6C = map_growing_wall | map_anim_state6
    !byte sprite_explosion2                                 ; cell type $6D = map_magic_wall | map_anim_state6
    !byte sprite_butterfly2                                 ; cell type $6E = map_butterfly | map_anim_state6
    !byte sprite_rockford_tapping_foot4                     ; cell type $6F = map_rockford | map_anim_state6

    !byte sprite_explosion4                                 ; cell type $70 = map_space | map_anim_state7
    !byte sprite_explosion4                                 ; cell type $71 = map_earth | map_anim_state7
    !byte sprite_explosion4                                 ; cell type $72 = map_wall | map_anim_state7
    !byte sprite_explosion4                                 ; cell type $73 = map_titanium_wall | map_anim_state7
    !byte sprite_diamond1                                   ; cell type $74 = map_diamond | map_anim_state7
    !byte sprite_boulder1                                   ; cell type $75 = map_rock | map_anim_state7
    !byte sprite_firefly2                                   ; cell type $76 = map_firefly | map_anim_state7
    !byte sprite_amoeba2                                    ; cell type $77 = map_amoeba | map_anim_state7
    !byte sprite_rockford_moving_right4                     ; cell type $78 = map_rockford_appearing_or_end_position | map_anim_state7
    !byte sprite_amoeba2                                    ; cell type $79 = map_slime | map_anim_state7
    !byte sprite_firefly4                                   ; cell type $7A = map_explosion | map_anim_state7
    !byte sprite_bomb4                                      ; cell type $7B = map_bomb | map_anim_state7
    !byte sprite_magic_wall1                                ; cell type $7C = map_growing_wall | map_anim_state7
    !byte sprite_explosion1                                 ; cell type $7D = map_magic_wall | map_anim_state7
    !byte sprite_butterfly2                                 ; cell type $7E = map_butterfly | map_anim_state7
    !byte sprite_explosion1                                 ; cell type $7F = map_rockford | map_anim_state7

; *************************************************************************************
sprite_addresses_low
    !byte <sprite_addr_space
    !byte <sprite_addr_boulder1
    !byte <sprite_addr_boulder2
    !byte <sprite_addr_diamond1
    !byte <sprite_addr_diamond2
    !byte <sprite_addr_diamond3
    !byte <sprite_addr_diamond4
sprite_titanium_addressA
    !byte <sprite_addr_titanium_wall1
    !byte <sprite_addr_titanium_wall2
    !byte <sprite_addr_box
    !byte <sprite_addr_wall1
    !byte <sprite_addr_wall2
    !byte <sprite_addr_explosion1
    !byte <sprite_addr_explosion2
    !byte <sprite_addr_explosion3
    !byte <sprite_addr_explosion4
    !byte <sprite_addr_magic_wall1
    !byte <sprite_addr_magic_wall2
    !byte <sprite_addr_magic_wall3
    !byte <sprite_addr_magic_wall4
    !byte <sprite_addr_amoeba1
    !byte <sprite_addr_amoeba2
    !byte <sprite_addr_butterfly1
    !byte <sprite_addr_butterfly2
    !byte <sprite_addr_butterfly3
    !byte <sprite_addr_firefly1
    !byte <sprite_addr_firefly2
    !byte <sprite_addr_firefly3
    !byte <sprite_addr_firefly4
    !byte <sprite_addr_earth1
    !byte <sprite_addr_earth2
    !byte <sprite_addr_pathway
    !byte <sprite_addr_rockford_blinking1
    !byte <sprite_addr_rockford_blinking2
    !byte <sprite_addr_rockford_blinking3
    !byte <sprite_addr_rockford_winking1
    !byte <sprite_addr_rockford_winking2
    !byte <sprite_addr_rockford_moving_down1
    !byte <sprite_addr_rockford_moving_down2
    !byte <sprite_addr_rockford_moving_down3
    !byte <sprite_addr_rockford_moving_up1
    !byte <sprite_addr_rockford_moving_up2
    !byte <sprite_addr_rockford_moving_left1
    !byte <sprite_addr_rockford_moving_left2
    !byte <sprite_addr_rockford_moving_left3
    !byte <sprite_addr_rockford_moving_left4
    !byte <sprite_addr_rockford_moving_right1
    !byte <sprite_addr_rockford_moving_right2
    !byte <sprite_addr_rockford_moving_right3
    !byte <sprite_addr_rockford_moving_right4
    !byte <sprite_addr_0
    !byte <sprite_addr_1
    !byte <sprite_addr_2
    !byte <sprite_addr_3
    !byte <sprite_addr_4
    !byte <sprite_addr_5
    !byte <sprite_addr_6
    !byte <sprite_addr_7
    !byte <sprite_addr_8
    !byte <sprite_addr_9
    !byte <sprite_addr_white
    !byte <sprite_addr_dash
    !byte <sprite_addr_slash
    !byte <sprite_addr_comma
    !byte <sprite_addr_full_stop
    !byte <sprite_addr_A
    !byte <sprite_addr_B
    !byte <sprite_addr_C
    !byte <sprite_addr_D
    !byte <sprite_addr_E
    !byte <sprite_addr_F
    !byte <sprite_addr_G
    !byte <sprite_addr_H
    !byte <sprite_addr_I
    !byte <sprite_addr_J
    !byte <sprite_addr_K
    !byte <sprite_addr_L
    !byte <sprite_addr_M
    !byte <sprite_addr_N
    !byte <sprite_addr_O
    !byte <sprite_addr_P
    !byte <sprite_addr_Q
    !byte <sprite_addr_R
    !byte <sprite_addr_S
    !byte <sprite_addr_T
    !byte <sprite_addr_U
    !byte <sprite_addr_V
    !byte <sprite_addr_W
    !byte <sprite_addr_X
    !byte <sprite_addr_Y
    !byte <sprite_addr_Z
    !byte <sprite_addr_bomb
    !byte <sprite_addr_bomb3
    !byte <sprite_addr_bomb2
    !byte <sprite_addr_bomb1
    !byte <sprite_addr_bubble2
sprite_titanium_addressB
    !byte <sprite_addr_titanium_wall1
;TODO: These are used but unclear what for
    !byte $40, $e0, $80, $60,   0, $e0,   0,   0, $20, $40, $60, $80, $a0, $c0, $e0
    !byte   0, $20, $40, $60, $80, $a0, $c0, $e0,   0, $20, $40, $60, $80, $a0, $c0
    !byte $e0

; *************************************************************************************
sprite_addresses_high
    !byte >sprite_addr_space
    !byte >sprite_addr_boulder1
    !byte >sprite_addr_boulder2
    !byte >sprite_addr_diamond1
    !byte >sprite_addr_diamond2
    !byte >sprite_addr_diamond3
    !byte >sprite_addr_diamond4
    !byte >sprite_addr_titanium_wall1
    !byte >sprite_addr_titanium_wall2
    !byte >sprite_addr_box
    !byte >sprite_addr_wall1
    !byte >sprite_addr_wall2
    !byte >sprite_addr_explosion1
    !byte >sprite_addr_explosion2
    !byte >sprite_addr_explosion3
    !byte >sprite_addr_explosion4
    !byte >sprite_addr_magic_wall1
    !byte >sprite_addr_magic_wall2
    !byte >sprite_addr_magic_wall3
    !byte >sprite_addr_magic_wall4
    !byte >sprite_addr_amoeba1
    !byte >sprite_addr_amoeba2
    !byte >sprite_addr_butterfly1
    !byte >sprite_addr_butterfly2
    !byte >sprite_addr_butterfly3
    !byte >sprite_addr_firefly1
    !byte >sprite_addr_firefly2
    !byte >sprite_addr_firefly3
    !byte >sprite_addr_firefly4
    !byte >sprite_addr_earth1
    !byte >sprite_addr_earth2
    !byte >sprite_addr_pathway
    !byte >sprite_addr_rockford_blinking1
    !byte >sprite_addr_rockford_blinking2
    !byte >sprite_addr_rockford_blinking3
    !byte >sprite_addr_rockford_winking1
    !byte >sprite_addr_rockford_winking2
    !byte >sprite_addr_rockford_moving_down1
    !byte >sprite_addr_rockford_moving_down2
    !byte >sprite_addr_rockford_moving_down3
    !byte >sprite_addr_rockford_moving_up1
    !byte >sprite_addr_rockford_moving_up2
    !byte >sprite_addr_rockford_moving_left1
    !byte >sprite_addr_rockford_moving_left2
    !byte >sprite_addr_rockford_moving_left3
    !byte >sprite_addr_rockford_moving_left4
    !byte >sprite_addr_rockford_moving_right1
    !byte >sprite_addr_rockford_moving_right2
    !byte >sprite_addr_rockford_moving_right3
    !byte >sprite_addr_rockford_moving_right4
    !byte >sprite_addr_0
    !byte >sprite_addr_1
    !byte >sprite_addr_2
    !byte >sprite_addr_3
    !byte >sprite_addr_4
    !byte >sprite_addr_5
    !byte >sprite_addr_6
    !byte >sprite_addr_7
    !byte >sprite_addr_8
    !byte >sprite_addr_9
    !byte >sprite_addr_white
    !byte >sprite_addr_dash
    !byte >sprite_addr_slash
    !byte >sprite_addr_comma
    !byte >sprite_addr_full_stop
    !byte >sprite_addr_A
    !byte >sprite_addr_B
    !byte >sprite_addr_C
    !byte >sprite_addr_D
    !byte >sprite_addr_E
    !byte >sprite_addr_F
    !byte >sprite_addr_G
    !byte >sprite_addr_H
    !byte >sprite_addr_I
    !byte >sprite_addr_J
    !byte >sprite_addr_K
    !byte >sprite_addr_L
    !byte >sprite_addr_M
    !byte >sprite_addr_N
    !byte >sprite_addr_O
    !byte >sprite_addr_P
    !byte >sprite_addr_Q
    !byte >sprite_addr_R
    !byte >sprite_addr_S
    !byte >sprite_addr_T
    !byte >sprite_addr_U
    !byte >sprite_addr_V
    !byte >sprite_addr_W
    !byte >sprite_addr_X
    !byte >sprite_addr_Y
    !byte >sprite_addr_Z
    !byte >sprite_addr_bomb
    !byte >sprite_addr_bomb3
    !byte >sprite_addr_bomb2
    !byte >sprite_addr_bomb1
    !byte >sprite_addr_bubble2
sprite_titanium_addressC
    !byte >sprite_addr_titanium_wall1
;TODO: These are used but unclear what for
    !byte $14, $15, $18, $18, $19, $18, $14, $14, $20, $20, $20, $20, $20, $20, $20
    !byte $21, $21, $21, $21, $21, $21, $21, $21, $22, $22, $22, $22, $22, $22, $22
    !byte $22

; *************************************************************************************
; Given a direction (0-3), return an offset from the current position ($41) in the map
; to check is clear when moving a rock (or zero if direction is not possible):
;    00 01 02
; 3f 40 41 42 43
;    80 81 82
;       c1
check_for_rock_direction_offsets
    !byte $43, $3f,   0, $c1

map_offset_for_direction
    !byte $42, $40,   1, $81

rockford_cell_value_for_direction
    !byte $af, $9f,   0,   0

neighbouring_cell_variable_from_direction_index
    !byte cell_right
    !byte cell_left
    !byte cell_above
    !byte cell_below

firefly_and_butterfly_next_direction_table
    !byte 2, 3, 4, 5, 6, 7, 0, 1

firefly_and_butterfly_cell_values
    !byte   (map_unprocessed | map_anim_state3) | map_firefly
    !byte (map_unprocessed | map_anim_state3) | map_butterfly
    !byte   (map_unprocessed | map_anim_state0) | map_firefly
    !byte (map_unprocessed | map_anim_state0) | map_butterfly
    !byte   (map_unprocessed | map_anim_state1) | map_firefly
    !byte (map_unprocessed | map_anim_state1) | map_butterfly
    !byte   (map_unprocessed | map_anim_state2) | map_firefly
    !byte (map_unprocessed | map_anim_state2) | map_butterfly

; Next table has even offsets progressing clockwise, odd offsets progress anti-clockwise
firefly_neighbour_variables
    !byte cell_left
    !byte cell_right
    !byte cell_above
    !byte cell_above
    !byte cell_right
    !byte cell_left
    !byte cell_below
    !byte cell_below

; *************************************************************************************
sound1
    !word 1                                                 ; channel   (2 bytes)
    !word 10                                                ; amplitude (2 bytes)
sound1_pitch
    !word 69                                                ; pitch     (2 bytes)
sound1_duration
    !word 6                                                 ; duration  (2 bytes)

sound2
    !word 2                                                 ; channel   (2 bytes)
    !word 11                                                ; amplitude (2 bytes)
    !word 181                                               ; pitch     (2 bytes)
    !word 6                                                 ; duration  (2 bytes)

sound3
    !word 3                                                 ; channel   (2 bytes)
    !word 12                                                ; amplitude (2 bytes)
    !word 169                                               ; pitch     (2 bytes)
    !word 6                                                 ; duration  (2 bytes)

tune_position_per_channel
    !byte $0e, $4f, $81
tune_note_repeat_per_channel
    !byte 0, 0, 0
command_pitch
    !byte $19, $a9, $79, $79, $81, $79
command_note_durations
    !byte $12,   3,   3,   3,   8,   7
command_note_repeat_counts
    !byte   1,   7, $40, $0f,   1,   1
tune_start_position_per_channel
    !byte   0, $41, $73
    !byte 0, 0, 0
tune_note_durations_table
    !byte  3,  6,  9, 12

; *************************************************************************************
set_clock_value
    !byte 5, 0, 0, 0, 0                ; Five byte clock value (low byte to high byte)

initial_clock_value                    ; Five byte clock value (low byte to high byte)
    !byte 0, 0, 0, 0, 0

; *************************************************************************************
; IMPORTANT: this section must start at a page boundary
;
!align 255, 0
demonstration_keys
    !byte   0,   0,   8,   0, $10, $80,   0, $20,   0, $10, $80, $20, $40,   0, $80
    !byte $10, $80,   0, $40,   0, $80, $20, $80,   0, $10,   0, $40,   0, $10, $80
    !byte   0, $10, $80,   0, $10,   0, $40, $10, $40,   0, $10, $40,   0, $20, $80
    !byte $10,   0, $20, $40, $10, $40, $20, $40, $10, $40, $20, $40, $20, $40, $10
    !byte $40, $10,   0,   8, $88,   8, $10,   0, $80,   0, $10, $40,   0, $80, $20
    !byte $80, $20,   0, $80, $10, $80, $20, $80,   0, $10, $80,   0, $20, $80,   0
    !byte $10,   0, $80, $ff, $ff, $ff
demonstration_key_durations
    !byte $14, $22,   2, $12,   1,   7,   2,   2,   6,   1, $0b,   1,   2,   2,   5
    !byte   4,   2,   6,   2,   1,   3,   3, $0b,   5,   2,   5,   2,   5,   3,   2
    !byte   7,   3,   3,   4,   1,   3,   3,   1,   4,   5,   2,   3,   6,   2,   3
    !byte   2,   1,   2,   3,   1,   2,   4,   5,   4,   3,   2,   8,   2,   9,   1
    !byte   2,   4,   3,   1,   2,   3,   2,   1,   2,   1,   5,   2,   1,   5,   4
    !byte   5,   2,   5,   6,   5,   5,   3,   6, $10,   3,   5, $0c,   4,   3, $1f
    !byte   1, $14, $64, $ff, $ff, $ff

; *************************************************************************************
; Sprites to use for idle animation of rockford. They are encoded into the nybbles of
; each byte. First it cycles through the bottom nybbles until near the end of the idle
; animation, then cycles through through the top nybbles
idle_animation_data
    !byte 16*(sprite_rockford_tapping_foot4-0x20) + sprite_rockford_blinking1-0x20
    !byte 16*(sprite_rockford_tapping_foot3-0x20) + sprite_rockford_blinking1-0x20
    !byte 16*(sprite_rockford_tapping_foot2-0x20) + sprite_rockford_blinking1-0x20
    !byte 16*(sprite_rockford_tapping_foot3-0x20) + sprite_rockford_blinking1-0x20
    !byte 16*(sprite_rockford_tapping_foot4-0x20) + sprite_rockford_blinking2-0x20
    !byte 16*(sprite_rockford_tapping_foot1-0x20) + sprite_rockford_blinking3-0x20
    !byte 16*(sprite_rockford_tapping_foot2-0x20) + sprite_rockford_blinking2-0x20
    !byte 16*(sprite_rockford_tapping_foot1-0x20) + sprite_rockford_blinking1-0x20
    !byte 16*(sprite_rockford_tapping_foot3-0x20) + sprite_rockford_blinking1-0x20
    !byte 16*(sprite_rockford_tapping_foot5-0x20) + sprite_rockford_blinking1-0x20
    !byte 16*(sprite_rockford_tapping_foot5-0x20) + sprite_rockford_blinking3-0x20
    !byte 16*(sprite_rockford_tapping_foot3-0x20) + sprite_rockford_blinking1-0x20
    !byte 16*(sprite_rockford_tapping_foot1-0x20) + sprite_rockford_blinking3-0x20
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_blinking1-0x20
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_blinking1-0x20
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_blinking1-0x20
    !byte 16*(sprite_rockford_blinking2-0x20) + sprite_rockford_blinking2-0x20
    !byte 16*(sprite_rockford_blinking3-0x20) + sprite_rockford_blinking3-0x20
    !byte 16*(sprite_rockford_blinking2-0x20) + sprite_rockford_blinking2-0x20
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_blinking1-0x20
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_blinking1-0x20
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_blinking2-0x20
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot5-0x20
    !byte 16*(sprite_rockford_blinking3-0x20) + sprite_rockford_tapping_foot3-0x20
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot1-0x20
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot1-0x20
    !byte 16*(sprite_rockford_blinking3-0x20) + sprite_rockford_tapping_foot1-0x20
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot1-0x20
    !byte 16*(sprite_rockford_tapping_foot1-0x20) + sprite_rockford_tapping_foot1-0x20
    !byte 16*(sprite_rockford_tapping_foot3-0x20) + sprite_rockford_tapping_foot5-0x20
    !byte 16*(sprite_rockford_tapping_foot5-0x20) + sprite_rockford_tapping_foot1-0x20
    !byte 16*(sprite_rockford_tapping_foot3-0x20) + sprite_rockford_tapping_foot1-0x20
    !byte 16*(sprite_rockford_tapping_foot1-0x20) + sprite_rockford_tapping_foot1-0x20
    !byte 16*(sprite_rockford_blinking3-0x20) + sprite_rockford_tapping_foot4-0x20
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot1-0x20
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot2-0x20
    !byte 16*(sprite_rockford_blinking3-0x20) + sprite_rockford_tapping_foot3-0x20
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot1-0x20
    !byte 16*(sprite_rockford_blinking3-0x20) + sprite_rockford_tapping_foot1-0x20
    !byte 16*(sprite_rockford_tapping_foot1-0x20) + sprite_rockford_tapping_foot1-0x20
    !byte 16*(sprite_rockford_tapping_foot1-0x20) + sprite_rockford_tapping_foot1-0x20
    !byte 16*(sprite_rockford_tapping_foot1-0x20) + sprite_rockford_tapping_foot5-0x20
    !byte 16*(sprite_rockford_tapping_foot1-0x20) + sprite_rockford_tapping_foot1-0x20
    !byte 16*(sprite_rockford_tapping_foot2-0x20) + sprite_rockford_tapping_foot1-0x20
    !byte 16*(sprite_rockford_tapping_foot5-0x20) + sprite_rockford_blinking2-0x20
    !byte 16*(sprite_rockford_tapping_foot2-0x20) + sprite_rockford_blinking3-0x20
    !byte 16*(sprite_rockford_tapping_foot5-0x20) + sprite_rockford_blinking2-0x20
    !byte 16*(sprite_rockford_tapping_foot2-0x20) + sprite_rockford_blinking1-0x20
    !byte 16*(sprite_rockford_tapping_foot3-0x20) + sprite_rockford_blinking1-0x20
    !byte 16*(sprite_rockford_blinking3-0x20) + sprite_rockford_tapping_foot1-0x20
    !byte 16*(sprite_rockford_blinking2-0x20) + sprite_rockford_tapping_foot2-0x20
    !byte 16*(sprite_rockford_blinking2-0x20) + sprite_rockford_tapping_foot5-0x20
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot4-0x20
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot5-0x20
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot2-0x20
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot1-0x20
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot2-0x20
    !byte 16*(sprite_rockford_blinking1-0x20) + sprite_rockford_tapping_foot1-0x20
    !byte 16*(sprite_rockford_winking1-0x20) + sprite_rockford_tapping_foot2-0x20
    !byte 16*(sprite_rockford_winking2-0x20) + sprite_rockford_tapping_foot1-0x20
    !byte 16*(sprite_rockford_winking2-0x20) + sprite_rockford_tapping_foot4-0x20
    !byte 16*(sprite_rockford_winking2-0x20) + sprite_rockford_tapping_foot3-0x20
    !byte 16*(sprite_rockford_winking1-0x20) + sprite_rockford_tapping_foot2-0x20
    !byte 16*(sprite_rockford_winking1-0x20) + sprite_rockford_tapping_foot1-0x20

; *************************************************************************************
; IMPORTANT: this section must start at a page boundary
;
!align 255, 0
regular_status_bar
    !byte sprite_4
    !byte sprite_2
    !byte sprite_diamond1
total_diamonds_on_status_bar_high_digit
    !byte sprite_1
total_diamonds_on_status_bar_low_digit
    !byte sprite_0
    !byte sprite_space
    !byte sprite_0
    !byte sprite_0
    !byte sprite_0
    !byte sprite_space
    !byte sprite_1
    !byte sprite_3
    !byte sprite_3
    !byte sprite_space
score_on_regular_status_bar
    !byte sprite_0
    !byte sprite_0
    !byte sprite_7
hundreds_digit_of_score_on_status_bar
    !byte sprite_9
    !byte sprite_7
    !byte sprite_8

; *************************************************************************************
players_and_men_status_bar
    !text "PLAYER"
    !byte sprite_space
player_number_on_regular_status_bar
    !byte sprite_1
    !byte sprite_comma
    !byte sprite_space
men_number_on_regular_status_bar
    !byte sprite_0
    !byte sprite_space
    !text "MEN"
    !byte sprite_space
    !byte sprite_space
cave_letter_on_regular_status_bar
    !text "N"
    !byte sprite_slash
difficulty_level_on_regular_status_bar
    !byte sprite_4

; *************************************************************************************
inactive_players_regular_status_bar
    !byte sprite_6
    !byte sprite_0
    !byte sprite_diamond1
    !byte sprite_0
    !byte sprite_5
    !byte sprite_space
    !byte sprite_0
    !byte sprite_0
    !byte sprite_0
    !byte sprite_space
    !byte sprite_1
    !byte sprite_5
    !byte sprite_0
    !byte sprite_space
score_on_inactive_players_regular_status_bar
    !fill 6, sprite_0

; *************************************************************************************
inactive_players_and_men_status_bar
    !text "PLAYER"
    !byte sprite_space
player_number_on_inactive_players_and_men_status_bar
    !byte sprite_2
    !byte sprite_comma
    !byte sprite_space
number_of_men_on_inactive_players_and_men_status_bar
    !byte sprite_0
    !byte sprite_space
    !text "MEN"
    !byte sprite_space
    !byte sprite_space
cave_letter_on_inactive_players_and_men_status_bar
    !byte 'B'
    !byte sprite_slash
difficulty_level_on_inactive_players_and_men_status_bar
    !byte sprite_4

; *************************************************************************************
highscore_high_status_bar
    !fill 6, sprite_0
    !byte sprite_space
    !byte sprite_space
    !text "HIGH"
    !byte sprite_space
    !byte sprite_space
highscore_for_player_2
    !fill 6, sprite_0

; *************************************************************************************
bonus_life_text
    !text "B"
    !byte sprite_space
    !text "O"
    !byte sprite_space
    !text "N"
    !byte sprite_space
    !text "U"
    !byte sprite_space
    !text "S"
    !fill 4, sprite_space
    !text "L"
    !byte sprite_space
    !text "I"
    !byte sprite_space
    !text "F"
    !byte sprite_space
    !text "E"

; *************************************************************************************
number_of_players_status_bar
    !byte sprite_1
    !byte sprite_space
    !text "PLAYER"
plural_for_player
    !fill 4, sprite_space
    !text "CAVE="
cave_letter
    !text "A"
    !byte sprite_slash
number_of_players_status_bar_difficulty_level
    !byte sprite_1

; *************************************************************************************
game_over_text
    !byte sprite_space
    !text "GAME"
    !byte sprite_space
    !text "OVER"
    !byte sprite_space
    !text "PLAYER"
    !byte sprite_space
player_number_on_game_over_text
    !byte sprite_1
    !byte sprite_space

; *************************************************************************************
demonstration_mode_text
    !byte sprite_space
    !text "DEMONSTRATION"
    !byte sprite_space
    !text "MODE"
    !byte sprite_space

; *************************************************************************************
out_of_time_message
    !text "O"
    !byte sprite_space
    !text "U"
    !byte sprite_space
    !text "T"
    !byte sprite_space
    !byte sprite_space
    !text "O"
    !byte sprite_space
    !text "F"
    !byte sprite_space
    !byte sprite_space
    !byte sprite_space
    !text "T"
    !byte sprite_space
    !text "I"
    !byte sprite_space
    !text "M"
    !byte sprite_space
    !text "E"

; *************************************************************************************
pause_message
    !text "HIT"
    !byte sprite_space
    !text "SPACE"
    !byte sprite_space
    !byte sprite_space
    !text "TO"
    !byte sprite_space
    !text "RESUME"

; *************************************************************************************
score_last_status_bar
    !fill 6, sprite_0
    !byte sprite_space
    !byte sprite_space
    !text "LAST"
    !byte sprite_space
    !byte sprite_space
    !fill 6, sprite_0

; *************************************************************************************
zeroed_status_bar
    !byte sprite_0
    !byte sprite_0
    !byte sprite_diamond1
    !byte sprite_0
    !byte sprite_0
    !byte sprite_space
    !byte sprite_0
    !byte sprite_0
    !byte sprite_0
    !byte sprite_space
    !byte sprite_0
    !byte sprite_0
    !byte sprite_0
    !byte sprite_space
    !byte sprite_0
    !byte sprite_0

; *************************************************************************************
; IMPORTANT: this section must start at a page boundary
;
!align 255, 0
game_credits
    !fill 3,sprite_full_stop
    !text "BOULDERDASH"
    !byte sprite_space
    !text "BY"
    !byte sprite_space
    !text "AG"
    !byte sprite_space
    !text "BENNETT"
    !byte sprite_space
    !byte sprite_1
    !byte sprite_9
    !byte sprite_8
    !byte sprite_8
    !byte sprite_space
    !text "ENHANCED"
    !byte sprite_space
    !byte sprite_2
    !byte sprite_0
    !byte sprite_2
    !byte sprite_4
    !byte sprite_space
    !text "RASPBERRYPIONEER"
end_of_credits

sprite_text_high
    !byte >sprites1_text, >sprites2_text, >sprites3_text, >sprites4_text, >sprites5_text, >sprites6_text

sprite_text_low
    !byte <sprites1_text, <sprites2_text, <sprites3_text, <sprites4_text, <sprites5_text, <sprites6_text

sprites1_text
    !fill 1, sprite_space
    !byte sprite_rockford_blinking1
    !fill 1, sprite_space    
    !text "ORIGINAL"
    !byte sprite_space
    !text "SPRITES"
    !fill 1,sprite_space

sprites2_text
    !fill 3, sprite_space    
    !text "BUBBLE"
    !byte sprite_space
    !text "BOBBLE"
    !fill 4,sprite_space

sprites3_text
    !fill 3, sprite_space    
    !text "EASTER"
    !byte sprite_space
    !text "EGGS"
    !fill 6,sprite_space

sprites4_text
    !fill 3, sprite_space    
    !text "MS"
    !byte sprite_full_stop
    !byte sprite_space
    !text "PACMAN"
    !fill 7,sprite_space

sprites5_text
    !fill 3, sprite_space    
    !text "ROBO"
    !byte sprite_space
    !text "TECH"
    !fill 8,sprite_space

sprites6_text
    !fill 3, sprite_space    
    !text "COMING"
    !byte sprite_space
    !text "SOON"
    !fill 6,sprite_space

bd_sprites_files
    !scr "ORISPR"
    !byte 0,0
    !scr "BUBBOB"
    !byte 0,0
    !scr "EASTER"
    !byte 0,0
    !scr "PACMAN"
    !byte 0,0
    !scr "ROBOTS"
    !byte 0,0
    !scr "ORISPR"  ;TODO: Need new set
    !byte 0,0
    !fill 12,0

; *************************************************************************************
; IMPORTANT: this section must start at a page boundary
;
big_rockford_sprite
    !byte   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0
    !byte   0,   0,   0,   0, $1a, $10,   1, $11,   0,   2,   3, $21,   0,   2,   8
    !byte   6, $ca, $cb, $87, $69,   0,   3, $37, $8f, $2d, $6b, $0f,   1,   0,   4
    !byte $6c, $3e, $96, $fc,   0,   4, $63, $c7, $96, $f3,   0,   3, $ce, $1f, $4b
    !byte $6d, $0f,   1,   0,   2,   1, $12, $35, $3d, $1e, $69,   0,   2, $80, $88
    !byte   0,   2, $0c, $68,   0, $fd, $10,   1,   0,   2, $32, $11,   1,   7, $69
    !byte $32, $b1, $52, $7e, $97, $cb, $4f, $2d, $3c, $78, $e1, $2d, $3e, $97, $ad
    !byte $78, $f0, $0f,   1, $69, $3e, $1e, $5a, $7c, $3e, $96, $78, $0f,   1, $c7
    !byte $87, $a5, $e3, $c7, $96, $e1, $0f,   1, $4b, $c7, $9e, $5b, $e1, $f0, $0f
    !byte   1, $69, $e7, $9e, $3d, $2f, $4b, $c3, $e1, $78, $c4, $88,   8, $0e, $3e
    !byte $2d, $c4, $8e,   0,   6,   8,   0, $f3,   1,   0,   4,   1, $47, $4b, $32
    !byte $17,   7, $2d, $3e, $5a, $cb, $5a, $96, $87, $96, $96, $1e, $1e, $f0, $96
    !byte $69, $96, $1e, $4b, $1e, $69, $0f,   1, $87, $4b, $0f,   1, $87, $87, $87
    !byte $4b, $0f,   1, $1e, $1e, $2d, $1e, $1e, $1e, $1e, $f0, $96, $69, $96, $1e
    !byte $4b, $1e, $69, $0f,   1, $87, $87, $0f,   1, $87, $87, $87, $4b, $3e, $2d
    !byte $c4, $8e, $0e, $4b, $c7, $a5,   0,   2,   8,   0,   4,   8,   0, $f0,   1
    !byte   1, $12, $13, $10,   4, $e1, $cb, $87, $87, $0f,   4, $2d, $3c, $3c, $3d
    !byte $3d, $3d, $3d, $3d, $f6, $ff,   2, $ee, $dc, $dc, $b8, $b9, $4b, $87, $87
    !byte $87, $87, $87, $96, $87, $2d, $3c, $3c, $3d, $3d, $3d, $b5, $79, $f6, $ff
    !byte   2, $ee, $dc, $dc, $b8, $b9, $4b, $87, $87, $87, $87, $87, $87, $87, $78
    !byte $3d, $1e, $1e, $0f,   4,   8,   8, $84, $8c, $80, $80, $80, $80,   0, $f0
    !byte $21, $21, $21, $21, $21, $21, $21, $21, $0f,   8, $3d, $1e, $0f,   6, $b9
    !byte $b8, $e1, $0f,   5, $97, $0f,   2, $4b, $4b, $2d, $1e, $0f,   1, $79, $bc
    !byte $ad, $2d, $4b, $4b, $87, $0f,   1, $b9, $b8, $e1, $0f,   5, $87, $0f,   5
    !byte $a5, $4b, $0f,   8, $48,   8,   0, $f0, $10,   3,   0,   5, $0f,   3, $87
    !byte $87, $43, $21, $10,   1, $0f,   7, $87, $4b, $c3, $4b, $a5, $1e, $0f,   7
    !byte $87, $78, $0f,   6, $3c, $c3, $0f,   4, $1e, $69, $87, $0f,   3, $69, $87
    !byte $0f,   5, $1e, $0f,   3, $1e, $1e, $2c, $48,   1, $80, $80, $80, $80,   0
    !byte   0,   0,   5, $52, $30,   0,   6, $0f,   2, $87, $43, $21, $21, $10,   1
    !byte   0,   1, $0f,   7, $87, $0f,   7, $1e, $0f,   2, $1e, $2c, $48,   2, $80
    !byte   0,   1, $a4, $c0,   0, $33, $11, $33, $77,   0,   4, $88, $cc, $ee, $ff
    !byte   1,   0, $d5, $10,   2, $31,   0,   3, $70, $f6, $ff,   3,   0,   1, $10
    !byte   1, $f1, $3d, $fc, $f6, $fe, $f7, $f0, $8f, $8f, $cb, $fc, $ff,   2, $f3
    !byte $f0, $3d, $3d, $3d, $f3, $ff,   2, $fc,   0,   1, $80, $c8, $e8, $fa, $f5
    !byte $f7, $9f,   0,   5, $80, $80, $c8,   0, $1d, $11, $33, $77,   0,   1, $11
    !byte $33, $77, $ff,   1, $dd, $bb, $cc, $ff,   1, $55, $aa, $ff,   2, $55,   0
    !byte   1, $a0, $ee, $55, $bb, $ff,   2, $77, $55, $20, $88, $44, $ee, $ff,   2
    !byte $ee, $bb, $e0,   0,   4, $88, $cc, $22, $73,   0, $bb, $10,   2, $21, $73
    !byte $73, $43, $43, $87, $0f,   3, $8f, $cf, $ff,   2, $7e, $3d, $3c, $7a, $d4
    !byte $f6, $ff,   1, $87, $87, $87, $4b, $4b, $2d, $b5, $fc, $7f, $0f,   5, $ff
    !byte   1, $e3, $8f, $0f,   4, $1f, $ff,   1, $1e, $1f, $1e, $0f,   1, $3e, $6f
    !byte $fe, $ff,   1, $c8, $48,   1, $2c, $2c, $2c, $2c, $fe, $fe,   0, $18, $55
    !byte $44, $44, $44, $22, $11, $10,   1, $31, $b8, $a8, $55, $33, $11,   0,   1
    !byte $b0, $f3,   0,   1, $aa, $55, $ff,   2, $fe, $f5, $fb, $90, $31, $75, $fb
    !byte $fb, $f3, $fd, $ff,   1, $fe, $fe, $fe, $fd, $ed, $ed, $cb, $da, $a3, $47
    !byte $8f, $1f, $78, $f6, $f6, $fe, $80, $c8, $c8, $c8, $80,   0, $aa, $10,   1
    !byte   0,   1, $10,   2, $21, $43, $43, $87, $0f,   1, $f7, $ff,   2, $3f, $1f
    !byte $1f, $1e, $1e, $fe, $fe, $fd, $ec,   1, $fb, $c0, $72, $31, $dc, $b9,   0
    !byte   1, $fb, $32, $d5, $fe, $64, $96, $da, $cb, $40, $d8, $b1, $73, $f7, $ff
    !byte   2, $f5, $f4, $fb, $db, $c5, $b7, $ff,   3, $ef, $87, $cb, $ed, $be, $fe
    !byte $ff,   1, $9e, $1e, $1e, $1e, $0e, $0e, $fe, $ff,   1, $ef, $8f, $0f,   2
    !byte $87, $87,   0,   1, $80, $80, $80, $48,   4,   0,   5, $10,   1, $31, $f3
    !byte   0,   2, $10,   1, $21, $c3, $cf, $cf, $cf, $73, $72, $f6, $f6, $f6, $f6
    !byte $f7, $7b, $f7, $ff,   4, $fd, $d0, $80, $fb, $ff,   4, $fe, $e0,   0,   1
    !byte $ff,   1, $fe, $fd, $f9, $90,   0,   3, $f5, $fa, $ff,   3, $f0,   0,   2
    !byte $fe, $ec,   2, $c8, $80,   0, $ab, $10,   1, $31, $73, $73, $73, $f7, $f7
    !byte $e7, $0f,   1, $cf, $ef, $ef, $fe, $fc, $ef, $0f,   1, $2c, $48,   2, $80
    !byte   0,   1, $10,   1, $b1, $7b, $31, $10,   1, $31, $73, $e7, $df, $af, $ce
    !byte $d8, $a1, $c3, $cb, $29, $36, $5e, $fe, $1e, $1e, $2d, $3d, $6b, $ea, $c6
    !byte $e7, $9b, $af, $77, $3f, $df, $7f, $fc, $7b, $9f, $cf, $9d, $0d, $9b, $3e
    !byte $1a, $e5, $f6, $a6, $96, $96, $96, $3c, $3c, $7a, $97, $b7, $73, $73, $73
    !byte $71, $31, $10,   1, $f8, $cb, $c7, $cf, $c7, $ef, $ef, $f4, $3f, $1f, $1f
    !byte $1f, $1e, $2c, $c0,   0,   1, $ef, $fe, $ec,   1, $c0,   0,   4, $78, $80
    !byte   0, $d6, $e7, $43, $43, $21, $31, $10,   1,   0,   2, $0f,   3, $3f, $ff
    !byte   2, $f7, $73, $2d, $7e, $fe, $ff,   2, $ef, $cf, $8f, $9b, $8d, $3b, $d6
    !byte $79, $6a, $3c, $3d, $bc, $fa, $f7, $bb, $55, $e2, $ec,   1, $fa, $df, $8d
    !byte $d6, $fa, $fd, $fd, $f3, $ff,   1, $f7, $f6, $fe, $fd, $fd, $fa, $fa, $e1
    !byte $e5, $cb, $cb, $96, $96, $3c, $3d, $79, $5a, $96, $96, $1e, $d2, $fc, $fc
    !byte $fc,   0,   8, $c0,   0, $f7, $31, $10,   1,   0,   6, $0f,   2, $87, $52
    !byte $30, $31, $31, $31, $7b, $f7, $f6, $fe, $fd, $fd, $fb, $fb, $fb, $f7, $ff
    !byte $0e, $ed, $fe, $fe, $ff,   5, $7b, $f7, $ff,   3, $fe, $fc, $f9, $fa, $fa
    !byte $da, $96, $b5, $f3, $ff,   2,   0,   4, $80, $80, $80, $80,   0,   0, $31
    !byte $31, $31, $10,   1,   0,   4, $fb, $fb, $fb, $b0, $31, $31, $31, $31, $ff
    !byte   4, $f7, $fb, $fd, $fe, $ff,   4, $fd, $fe, $ff,   2, $f6, $f9, $ff,   3
    !byte $f0, $ff,   2, $f5, $fd, $fd, $fb, $f7, $f7, $f7, $f7, $ff,   2, $fe, $fe
    !byte $fe, $fe, $fe, $fe, $80, $80,   0,   0,   0, $0e, $31, $31, $31, $31, $31
    !byte $10,   3, $ff,   8, $f7, $f9, $fe, $ff,   1, $fe, $fe, $fe, $ec,   1, $fe
    !byte $fd, $f3, $b1, $10,   2,   0,   2, $ff,   6, $f7, $f7, $ec,   8,   0,   0
    !byte   0, $10, $10,   8, $ff,   8, $ec,   8,   0,   8, $f7, $f7, $f7, $f7, $f7
    !byte $f7, $f7, $f7, $ec,   6, $e4, $ec,   1,   0,   0,   0, $10, $10,   8, $ff
    !byte   8, $ec,   8,   0,   8, $f7, $f7, $f7, $f7, $f7, $f7, $f7, $f7, $ec,   8
    !byte   0,   0,   0, $10, $10,   8, $ff,   8, $ec,   7, $fe,   0,   4, $10,   4
    !byte $f7, $f7, $f7, $f7, $ff,   4, $ec,   4, $fe, $fe, $fe, $ec,   1,   0,   0
    !byte   0, $0e, $10,   1, $31, $31, $31, $31, $31, $12, $f1, $fd, $f2, $ff,   5
    !byte $f0, $ff,   1, $f8, $fe, $fe, $fe, $fe, $ec,   1, $d2, $da, $87,   0,   4
    !byte $10,   3, $90, $f7, $70, $f3, $b4, $0f,   1, $2d, $4b, $4b, $fc, $f3, $f4
    !byte $f5, $f5, $f5, $f6, $f6, $d0, $ff,   1, $f5, $f2, $e5, $f0, $f5, $f5,   0
    !byte   1, $80, $88,   0,   1, $c0, $f8, $f5, $f2,   0,   5, $80, $f0, $7a,   0
    !byte   7, $80,   0, $dc, $11, $12, $61, $f6,   0,   2, $61, $f2, $fc, $f4, $f4
    !byte $7a, $72, $f3, $f5, $f5, $da, $da, $cb, $f0, $7a, $f2, $b5, $f9, $da, $f2
    !byte $f2, $7b, $e5, $e5, $e5, $cb, $cb, $87, $0f,   1, $2d, $0f,   1, $2d, $1e
    !byte $1e, $1e, $2d, $0f,   2, $a1, $a1, $a1, $69, $78, $79, $58, $c0, $87, $87
    !byte $4b, $0f,   2, $c3, $fc, $f3, $69, $0f,   4, $4b, $d3, $fc, $7a, $7a, $e5
    !byte $e5, $69, $ed, $db, $f3, $f5, $f4, $e5, $e5, $69, $ed, $db, $b7, $e5, $e5
    !byte $e5, $e5, $e5, $c3, $da, $96, $c0, $78, $f3, $f4, $f6, $f4, $fe, $e8,   0
    !byte $d8, $f2, $f6, $f2, $f6, $f1, $f7, $70, $73, $7a, $78, $79, $79, $96, $96
    !byte $f9, $fa, $7b, $3d, $96, $96, $f8, $f3, $fc, $c0, $b5, $b5, $da, $f8, $f7
    !byte $f8, $80,   0,   1, $1e, $1e, $f1, $fe, $e0,   0,   3, $3c, $f3, $fc, $c0
    !byte   0,   4, $c8, $80,   0,   6, $30,   0,   7, $f3, $30,   0,   6, $fc, $f3
    !byte $31, $10,   1,   0,   4, $7e, $f0, $ff,   1, $f0,   0,   4, $3d, $f3, $fe
    !byte $f0,   0,   4, $ec,   1, $c0, $80,   0,   0,   0,   0,   0,   0,   0,   0
    !byte   0,   0,   0, $9d, $50,   0, $fd, $39, $4f, $42, $4f, $4e,   0, $8e, $38
    !byte $50,   0,   0, $12, $3a, $4f

; *************************************************************************************
; IMPORTANT: this section must start at a page boundary
;
tune_pitches_and_commands
    !byte $48, $58, $5c, $64, $58, $5c, $64, $70, $5c, $64, $70, $78, $49, $45, $19
    !byte   5, $11, $24, $20, $19,   5, $13,   9, $25,   3,   5, $c8, $a8, $a8, $a8
    !byte $a8, $18, $c9, $10, $c9, $18, $c9, $10, $c9, $18, $c9, $10, $c9, $18, $c9
    !byte $10, $a8, $a8, $a8, $88, $a8, $94, $8c, $40, $58, $5c, $64, $70, $a8, $a0
    !byte $94, $8c, $88, $78, $70, $48, $58, $5c, $64, $58, $5c, $64, $70, $5c, $64
    !byte $70, $78, $48, $b5, $b0, $18, $78,   5, $11, $80, $20, $18, $78,   5, $11
    !byte $a9,   8, $78, $25,   1, $a9,   5, $c8, $ca, $58, $78, $64, $5c, $10, $28
    !byte $2c, $34, $40, $78, $70, $64, $5c, $58, $48, $40, $48, $58, $5c, $64, $58
    !byte $5c, $64, $70, $5c, $64, $70, $78, $48, $a9, $a4, $19,   5, $11, $24, $20
    !byte $19,   5, $13,   9, $25,   3,   5, $c8, $cb, $cd, $89, $8d, $89, $8d, $89
    !byte $8d, $81, $85, $a9, $a1, $9d, $95, $a1, $a1, $8d, $a1, $89, $8d, $89, $8d
    !byte $89, $8d, $cc, $70, $94, $80, $78, $2c, $40, $48, $50, $5c, $94, $8c, $80
    !byte $78, $70, $64, $5c

; *************************************************************************************
inkey_keys_table
    !byte inkey_key_escape
    !byte inkey_key_space
    !byte inkey_key_b
    !byte inkey_key_return
    !byte inkey_key_slash
    !byte inkey_key_colon
    !byte inkey_key_z
    !byte inkey_key_x

initial_values_of_variables_from_0x50
    !byte $0d                                               ; magic_wall_state
    !byte 99                                                ; magic_wall_timer
    !byte $9f                                               ; rockford_cell_value
    !byte 4                                                 ; delay_trying_to_push_rock
    !byte 0                                                 ; amoeba_replacement
    !byte 99                                                ; amoeba_growth_interval
    !byte 0                                                 ; number_of_amoeba_cells_found
    !byte 1                                                 ; amoeba_counter
    !byte 240                                               ; ticks_since_last_direction_key_pressed
    !byte 0                                                 ; countdown_while_switching_palette
    !byte 31                                                ; tick_counter
    !byte 0                                                 ; current_rockford_sprite
    !byte 12                                                ; sub_second_ticks
    !byte 0                                                 ; previous_direction_keys
    !byte 0                                                 ; just_pressed_direction_keys
    !byte 0                                                 ; rockford_explosion_cell_type

end_of_vars