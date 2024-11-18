10REM -------------------------------------------------------------------------- 
20REM Boulder Dash cave editor by cybershark - 05/04/24
30REM with thanks to billcarr2005 for the cave display assembly routine
40REM edited by raspberrypioneer 19/04/24 adding pseudo-random cave generation
50REM --------------------------------------------------------------------------
60MODE1
70HIMEM=&2F80
80*FX229,1
90*FX4,1
100REM print is the hex start address of the print sprite assembler routine
110print=&BC0
120VDU23,251,0,16,56,124,16,16,16,0
130VDU23,252,0,16,16,16,124,56,16,0
140VDU23,253,0,0,16,48,126,48,16,0
150VDU23,254,0,0,8,12,126,12,8,0
160VDU23,255,255,255,255,255,255,255,255,255
170VDU23;8202;0;0;0;
180REM Load sprites into &900
190*L.SPRITES 900
200REM Setup assembler routines
210PROCass
220REM Display basic cave editor layout
230PROCdisp
240REM Load editor part 2 (main)
250CHAIN"EDITOR2"
260REM --------------------------------------------------------------------------
270REM Procedure to call assembler routine to display sprites
280REM --------------------------------------------------------------------------
290DEFPROCspr(sp%,addr%)
300!&70=addr%:!&74=sp%
310CALLprint
320ENDPROC
330REM --------------------------------------------------------------------------
340REM Procedure to display the editor screen basics (steel walls, labels, tiles)
350REM &930 = steel walls, &940 = diamond, &970 = magic wall
360REM &990 = amoeba, &9E0 = half-steel wall
370REM --------------------------------------------------------------------------
380DEFPROCdisp
390FORBR%=0TO39
400PROCspr(&930,&3000+BR%*&10)
410PROCspr(&930,&6480+BR%*&10)
420PROCspr(&930,&6980+BR%*&10)
430PROCspr(&9E0,&7380+BR%*&10)
440PROCspr(&9E0,&7B00+BR%*&10)
450NEXT
460PROCspr(&930,&6750)
470PROCspr(&930,&68A0)
480GCOL0,0
490MOVE0,252:MOVE0,268
500PLOT85,1280,252:PLOT85,1280,268
510MOVE160,288:MOVE160,316
520PLOT85,172,288:PLOT85,172,316
530MOVE850,288:MOVE850,316
540PLOT85,862,288:PLOT85,862,316
550FORsp%=1TO12
560PROCspr(&900+sp%*&10,&7D90+sp%*&20)
570NEXT
580GCOL0,1
590PRINTTAB(2,24)"SCORE:        BONUS:       /  TIME:"
600PROCspr(&940,&6C00)
610PROCspr(&940,&6CE0)
620PROCspr(&990,&6DC0)
630PROCspr(&970,&6DE0)
640PRINT"  REQUIRED 1:    2:    3:    4:    5:"
650PROCspr(&940,&6E80)
660PRINT"TIME LIMIT 1:    2:    3:    4:    5:"
670PRINT'"SEED VALUE 1:    2:    3:    4:    5:"
680PRINT"OBJ/PROB %  :100  :     :     :     :"
690PROCspr(&940,&6700)
700VDU31,1,22,58
710PRINTTAB(27,22)"COLOURS:";
720COLOUR0
730FORN%=0TO2
740COLOUR129+N%
750PRINTTAB(35+N%*2,22)CHR$(49+N%);
760NEXT
770COLOUR129
780PRINTTAB(6,22)"CAVE  :             ";
790COLOUR128:COLOUR3
800ENDPROC
810REM --------------------------------------------------------------------------
820REM Procedure for the assembler routines
830REM There are 3 entry points used by BASIC
840REM print - at the beginning, address &BC0, total 10 bytes
850REM   Get sprite in &74 and screen address in &70, populated in PROCspr 
860REM     and display sprite (16 bytes per sprite)
870REM level - labelled .rmd, address &BCA, total 119 bytes
880REM   Display the screen from data in address &A30 (see CALL level in editor2)
890REM   Use of CMP#4 and JSRadd is for counting the number of diamonds (tile = 4)
900REM     which is accumulated in 2FF0 and 2FF1
910REM   Table labelled sprtab is a sprite table of values 0 to 15 (16 values)
920REM     0 = space, &10 = dirt, &20 = wall, &30 = steel, &40 = diamond, 
930REM     &50 = boulder, &60 = firefly, &70 = amoeba, &80 = rockford, 
940REM     &90 = butterfly, &C0 = null
950REM     The 0 'gaps' between letters are for unused table entries (set to space)
960REM pseudo - labelled .pseudo, address &C5A, many bytes!
970REM   Loop through loaded cave map from &0A30 (2 loops used), 1 byte = 2 tiles
972REM   Get pseudo-random tile, replace loaded tiles with them only if load tiles = #&0F
974REM   Addresses &2FF3/4 = random seeds 1/2; &2FF5/6 = temp random seeds 1, 2
975REM   Parameters &0A0D = cave fill tile; &0A13-&0A16 = tile probability for four tiles; 
977REM     &0A17-&0A1A = tiles related to the probability values
979REM   prand - standard pseudo-random routine, returns predictable value for given seed
980REM --------------------------------------------------------------------------
990DEFPROCass
1000FORI%=0TO2STEP2
1010P%=print
1020[OPTI%
1030LDY#15
1040.loop
1050LDA(&74),Y:STA(&70),Y
1060DEY:BPLloop
1070RTS
1080.rmd
1090LDA&A30
1100PHA
1110LSR A:LSR A:LSR A:LSR A
1120CMP#4:BNEskiph
1130JSRadd
1140LDA#4
1150.skiph
1160JSR putit
1170PLA
1180AND#15
1190CMP#4:BNEskipl
1200JSRadd
1210LDA#4
1220.skipl
1230JSR putit
1240CLC
1250LDA rmd+1
1260ADC#1
1270BCCsir
1280INC rmd+2
1290.sir
1300STA rmd+1
1310LDA rmd+1
1320CMP#&C0:BEQ checkforB
1330.goagain
1340JMP rmd
1350.checkforB
1360LDA rmd+2:CMP#&0B:BNE goagain
1370RTS
1380.putit
1390TAY
1400CLC
1410LDA sprtab,Y
1420STA drawloop+1
1430LDY#0
1440.drawloop
1450LDA&900,Y
1460STA&3280,Y
1470INY
1480CPY#16
1490BNE drawloop
1500CLC
1510LDA drawloop+4
1520ADC#&10
1530BCC stadl
1540INC drawloop+5
1550.stadl
1560STA drawloop+4
1570RTS
1580.add
1590CLC
1600LDA&2FF0
1610ADC#1
1620STA&2FF0
1630CMP#0:BEQcarry
1640RTS
1650.carry
1660CLC
1670LDA&2FF1
1680ADC#1
1690STA&2FF1
1700RTS
1710.sprtab
1720EQUB 0
1730EQUB &10
1740EQUB &20
1750EQUB &30
1760EQUB &40
1770EQUB &50
1780EQUB &60
1790EQUB &70
1800EQUB 0
1810EQUB &80
1820EQUB 0
1830EQUB 0
1840EQUB 0
1850EQUB &90
1860EQUB &80
1870EQUB &C0
1890.pseudo
1900LDA #10
1910STA &2FF4
1920LDY #&00
1925STY &2FF3
1930.loop1
1940JSR xtile
1950LDA &0A30,Y
1960JSR setnibt
1970STA &0A30,Y
1980INY
1990CPY #&C8
2000BNE loop1
2010LDY #&00
2020.loop2
2030JSR xtile
2040LDA &0AF8,Y
2050JSR setnibt
2060STA &0AF8,Y
2070INY
2080CPY #&C8
2090BNE loop2
2100RTS
2110.setnibt
2120PHA
2130LSR A:LSR A:LSR A:LSR A
2140CMP #&0F
2150BNE here1
2160TXA
2170.here1
2190ASL A:ASL A:ASL A:ASL A
2200STA &2FF2
2210JSR xtile
2220PLA
2230AND #&0F
2240CMP #&0F
2250BNE here2
2260TXA
2270.here2
2280ORA &2FF2
2290RTS
2300.xtile
2310LDX &0A0D
2320JSR prand
2330CMP &0A13
2340BCS nprob1
2350LDX &0A17
2360.nprob1
2370CMP &0A14
2380BCS nprob2
2390LDX &0A18
2400.nprob2
2410CMP &0A15
2420BCS nprob3
2430LDX &0A19
2440.nprob3
2450CMP &0A16
2460BCS nproe
2470LDX &0A1A
2480.nproe
2490RTS
2500.prand
2510LDA &2FF3
2530ROR A: ROR A
2540AND #&80
2550STA &2FF5
2560LDA &2FF4
2570ROR A
2580AND #&7F
2590STA &2FF6
2600LDA &2FF4
2610ROR A: ROR A
2620AND #&80
2630CLC
2640ADC &2FF4
2650ADC #&13
2660STA &2FF4
2670LDA &2FF3
2680ADC &2FF5
2690ADC &2FF6
2700STA &2FF3
2710RTS
2720]
2730NEXT
2740ENDPROC
