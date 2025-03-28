; *************************************************************************************
; Sprite handler routine addresses
;
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
;TODO: part of sprite_to_next_sprite data
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
sprite_titanium_addressB
    !byte <sprite_addr_titanium_wall1                                                   ; 2060: e0          .
;TODO: These are used but unclear what for
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
sprite_titanium_addressC
    !byte >sprite_addr_titanium_wall1                                                   ; 20e0: 13          .
;TODO: These are used but unclear what for
    !byte $14, $15, $18, $18, $19, $18, $14, $14, $20, $20, $20, $20, $20, $20, $20     ; 20e1: 14 15 18... ...
    !byte $21, $21, $21, $21, $21, $21, $21, $21, $22, $22, $22, $22, $22, $22, $22     ; 20f0: 21 21 21... !!!
    !byte $22                                                                           ; 20ff: 22          "

; *************************************************************************************
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

rockford_cell_value_for_direction
    !byte $af, $9f,   0,   0                                                            ; 2224: af 9f 00... ...

neighbouring_cell_variable_from_direction_index
    !byte cell_right                                                                    ; 2200: 78          x
    !byte cell_left                                                                     ; 2201: 76          v
    !byte cell_above                                                                    ; 2202: 74          t
    !byte cell_below                                                                    ; 2203: 7a          z

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

; Next table has even offsets progressing clockwise, odd offsets progress anti-clockwise
firefly_neighbour_variables
    !byte cell_left                                                                     ; 221c: 76          v
    !byte cell_right                                                                    ; 221d: 78          x
    !byte cell_above                                                                    ; 221e: 74          t
    !byte cell_above                                                                    ; 221f: 74          t
    !byte cell_right                                                                    ; 2220: 78          x
    !byte cell_left                                                                     ; 2221: 76          v
    !byte cell_below                                                                    ; 2222: 7a          z
    !byte cell_below                                                                    ; 2223: 7a          z

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
; IMPORTANT: this section must start at a page boundary
;
!align 255, 0
regular_status_bar
    !byte sprite_4                                                                      ; 3200: 36          6
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
; IMPORTANT: this section must start at a page boundary
;
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
inkey_keys_table
    !byte inkey_key_escape                                                              ; 2228: 8f          .
    !byte inkey_key_space                                                               ; 2229: 9d          .
    !byte inkey_key_b                                                                   ; 222a: 9b          .
    !byte inkey_key_return                                                              ; 222b: b6          .
    !byte inkey_key_slash                                                               ; 222c: 97          .
    !byte inkey_key_colon                                                               ; 222d: b7          .
    !byte inkey_key_z                                                                   ; 222e: 9e          .
    !byte inkey_key_x                                                                   ; 222f: bd          .

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

end_of_vars