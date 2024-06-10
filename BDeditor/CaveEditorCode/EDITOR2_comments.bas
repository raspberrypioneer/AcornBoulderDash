   10 CA%=0
   20 DI%=0:T%=0
   21 REM print is the hex start address of the print sprite assembler routine
   22 REM level is the hex start address of the level sprite assembler routine
   30 print=&BC0: level=&BCA: pseudo=&C41
   
   40 DIM LR%(1),PV%(29),PX%(29),PY%(29),PM%(29),PA%(29),OB$(12)
   50 FOR r%=0 TO 29
   60   READ PA%(r%),PX%(r%),PY%(r%),PM%(r%)
   70   IF PM%(r%)=0 PM%(r%)=255
   80 NEXT
   90 FOR r%=0 TO 12
  100   READ OB$(r%)
  110 NEXT
  120 X%=0:CH%=0
  
  121 REM Display help screen
  130 PROChelp
  
  131 REM Dialog and actions to load/save cave
  140 PROCload
  
  141 REM Set colours
  150 PROCcol
  
  160 S%=0:OS%=1
  170 REPEAT
  171   REM Display cave contents
  180   PROCcave
  
  190   PROCstartend
  200   PROCstatus
  210   X%=1:Y%=1
  220   FP%=1:RL%=0
  230   PA%=3
  240   REPEAT
  250     VDU 5
  260     GCOL3,3
  270     MOVE X%*32,1023-Y%*32
  280     VDU 255,8,255,4
  
  281     REM key X to remove a tile 
  290     IF INKEY-90 PROCrepl(0)
  
  291     REM key X to plot a tile
  300     IF INKEY-99 OR INKEY-2 PROCrepl(S%)
  
  301     REM keys to move up/down/left/right
  310     IF INKEY-56 OR INKEY-58 Y%=(Y%+21) MOD 22
  320     IF INKEY-87 OR INKEY-42 Y%=(Y%+1) MOD 22
  330     IF INKEY-17 OR INKEY-26 X%=(X%+39) MOD 40
  340     IF INKEY-34 OR INKEY-122 X%=(X%+1) MOD 40
  
  341     REM key X to enter a cave name
  350     IF INKEY-83 PROCname
  
  360     IF INKEY-98 S%=(S%+12) MOD 13
  370     IF INKEY-67 S%=(S%+1) MOD 13
  
  371     REM keys to select tile
  380     IF INKEY-40 S%=0
  390     IF INKEY-49 S%=1
  400     IF INKEY-50 S%=2
  410     IF INKEY-18 S%=3
  420     IF INKEY-19 S%=4
  430     IF INKEY-20 S%=5
  440     IF INKEY-53 S%=6
  450     IF INKEY-37 S%=7
  460     IF INKEY-22 S%=8
  470     IF INKEY-39 S%=9
  480     IF INKEY-52 S%=10
  490     IF INKEY-68 S%=11
  500     IF INKEY-86 S%=12
  
  501     REM keys to select colour
  510     FOR i%=0 TO 2
  520       IF INKEY(-114-i%)PV%(i%)=PV%(i%) MOD 7+1:PROCcol:CH%=1
  530       NEXT
  540     IF FP%=1 FP%=0: GOTO 560
  550     IF S%<>OS% VDU31,OS%*2,31,32,9,32:OS%=S%: PRINTTAB(28,31)OB$(S%)STRING$(11-LENOB$(S%)," ");
  560     VDU 31,S%*2,31,91,9,93
  
  561     REM key X to fill entire cave with selected tile
  570     IF INKEY-1 AND (INKEY-99 OR INKEY-2) AND S%<15 PROCfill(S%)
  
  571     REM key X to clear the cave
  580     IF INKEY-1 AND INKEY-90 PROCfill(0)
  
  581     REM key X to show/hide start and exit
  590     IF INKEY-36 T%=ABS(T%-1):PROCstartend
  
  591     REM keys to show help, load, save, switch to parameter edit mode
  600     IF INKEY-85 PROChelp
  601     REM key M to map pseudo-random
  602     IF INKEY-102 dlev%=1:PROCpseudo
  603     IF INKEY-49 and INKEY-2 dlev%=1:PROCpseudo
  604     IF INKEY-50 and INKEY-2 dlev%=2:PROCpseudo
  605     IF INKEY-18 and INKEY-2 dlev%=3:PROCpseudo
  606     IF INKEY-19 and INKEY-2 dlev%=4:PROCpseudo
  607     IF INKEY-20 and INKEY-2 dlev%=5:PROCpseudo

  610     IF INKEY-1 AND INKEY-82 PROCsave
  620     IF INKEY-1 AND INKEY-87 PROCload
  630     IF INKEY-35 PROCparams
  640   UNTILRL%
  650 UNTIL0
  
  660 DEFPROCspr(sp%,addr%)
  670 !&70=addr%:!&74=sp%
  680 CALL print
  690 ENDPROC
  
  691 REM Plot tile
  700 DEFPROCrepl(s%)
  710 IF(X%=0 OR X%=39) AND (Y%=0 OR Y%=21) ENDPROC
  720 IF(X%=0 OR X%=39 OR Y%=0 OR Y%=21) AND (s%<10 OR s%>11) ENDPROC
  730 CH%=1
  740 m%=&A30+(Y%-1)*20+X%DIV2
  750 PROCspr(&900+s%*&10,&3000+Y%*&280+X%*&10)
  751 REM Special case for start/exit which need to update cave parameters
  760 IF s%=10 OR s%=11 T%=1: PROCstartend:T%=0
  770 IF s%=10 ?&A20=X%:?&A1F=Y%: GOTO 860
  780 IF s%=11 ?&A22=X%:?&A21=Y%: GOTO 860
  
  790 IF s%=8s%=&E
  800 IF s%=12s%=&F
  810 v%=?m%
  820 IF X%MOD2=0neighbour%=v%MOD16:old%=v%DIV16 ELSE neighbour%=v%DIV16:old%=v%MOD16
  830 IF old%<>4 AND s%=4DI%=DI%+1: PROCdia
  840 IF old%=4 AND s%<>4DI%=DI%-1: PROCdia
  850 IF X%MOD2=0 ?m%=s%*16+neighbour% ELSE ?m%=neighbour%*16+s%
  860 IF(X%=?&A20 AND Y%=?&A1F) OR (X%=?&A22 AND Y%=?&A21) PROCstartend
  870 ENDPROC
  
  880 DEFPROCfill(s%)
  890 IF s%=10 OR s%=11 ENDPROC
  900 CH%=1
  910 IF s%=4 DI%=760 ELSE DI%=0   
  920 IF s%=8 s%=&E
  930 IF s%=12 s%=&F
  940 PROCdia
  950 FOR y%=0 TO 19
  960   ?(&A30+y%*20)=48+s%
  970   ?(&A43+y%*20)=s%*16+3
  980   FOR x%= 1 TO 18
  990     ?(&A30+y%*20+x%)=s%*17
 1000   NEXT
 1010   PROCcave
 1020   PROCstartend
 1030 ENDPROC
 
 1031 REM ################################################################################
 1040 DEFPROCload
 1050   VDU 28,10,15,31,7,12
 1060   COLOUR 129
 1070   VDU 28,9,14,30,6,12
 1080   COLOUR 128
 1090   VDU 28,10,13,29,7,12
 1100   IF CH%=0 GOTO 1190
 1110   PRINT'''" SAVE CHANGES(Y/N)?";
 1120   *FX15
 1130   REPEAT
 1140     G=GET
 1150     IF G=27 ENDPROC
 1160     UNTIL G=89 OR G=78 OR G=27
 1170   IF G=89 PROCsave
 1180   CLS
 1190   PRINT'''" LOAD CAVE (A-T)? ";
 1200   *FX15
 1210   REPEAT
 1220     G=GET
 1230     UNTIL G>64 ANDG <85 OR((G=13 OR G=27) AND X%>0)
 1240   IF G=13 OR G=27 VDU26:RL%=1: ENDPROC
 1250   VDU G,26
 1260   CA%=G-65
 1270   FOR r%=3 TO 29
 1280     VDU31,PX%(r%),PY%(r%),32
 1290     IF r%=21 OR r%=22 OR r%=24 OR r%=26 OR r%=28 OR r%<3 GOTO 1310
 1300     VDU32,32
 1310   NEXT
 1320   VDU 31,2,22,32,32,32
 1330   COLOUR 129:COLOUR 0
 1340   VDU 31,11,22,32
 1350   PRINTTAB(12,22)SPC(13)
 
 1351   REM Load the cave file from the letter value in G$
 1352   REM TODO: What is the hex address A00 used for? Note this is also the address in editor 780 LDA&A00?
 1360   OSCLI "LOAD "+CHR$G+" A00"
 1370   FOR r%=0 TO 29
 1380     PV%(r%)=?(&A00+PA%(r%))
 1390   NEXT
 1400   RL%=1:CH%=0
 1410   CA$=$&A23
 1420   IF LENCA$>13 CA$=LEFT$(CA$,13)
 1430   PRINTTAB(11,22)CHR$G":"CA$
 1440   COLOUR 128: COLOUR 3
 1450 ENDPROC
 
 1460 DEFPROCsave
 1470   OSCLI "SAVE "+CHR$(65+CA%)+" A00 +1C0 4E40 4E40"
 1480   CH%=0
 1490 ENDPROC
 
 1500 DEFFNnum(v%)
 1510   LOCAL s$,l%
 1520   s$=STR$v%
 1530   l%=LENSTR$PM%(r%)
 1540 =STRING$(l%-LENs$,"0")+s$
 
 1550 DEFPROCdia
 1560   r%=4
 1570   PRINTTAB(2,22)FNnum(DI%)
 1580 ENDPROC
 
 1581 REM Display cave start and exit tiles using their cave parameter values
 1590 DEFPROCstartend
 1600   IF T%=1 GOTO 1650
 1610   IF?&A1F=?&A21 AND ?&A20=?&A22 PROCspr(&9D0,&3000+?&A1F*&280+?&A20*&10): ENDPROC
 1620   PROCspr(&9A0,&3000+?&A1F*&280+?&A20*&10)
 1630   PROCspr(&9B0,&3000+?&A21*&280+?&A22*&10)
 1640   ENDPROC
 1650   FOR p%=0 TO 1
 1660     IF p%=0pv1%=?&A1F:pv2%=?&A20 ELSE pv1%=?&A21:pv2%=?&A22
 1670     IF pv1%=0ORpv1%=21 v%=3: GOTO 1720
 1680     m%=&A30+(pv1%-1)*20+pv2%DIV2
 1690     IF pv2%MOD2=0v%=?m%DIV16 ELSE v%=?m%MOD 16
 1700     IF v%=&Ev%=8
 1710     IF v%=&Fv%=12
 1720     PROCspr(&900+v%*&10,&3000+pv1%*&280+pv2%*&10)
 1730   NEXT
 1740 ENDPROC
 
 1750 DEFPROCcol
 1760   FOR r%=0 TO 2
 1770     VDU19,r%+1,PV%(r%);0;
 1780   NEXT
 1790 ENDPROC
 
 1791 REM ################################################################################
 1800 DEFPROCcave
 1801   REM Set the cave data start address, replacing the "&A00" value in editor 780 LDA&A00
 1802   REM This becomes address &0A30, skipping the &30 (48) bytes for the cave parameters
 1810   ?(level+1)=&30:?(level+2)=&0A
 1811   REM TODO: Looks like replaces editor 1150 STA&3280,Y address "&3280" but not sure why
 1820   ?(level+&51)=&80:?(level+&52)=&32
 1821   REM Set count of number of diamonds to zero
 1830   ?&2FF0=0:?&2FF1=0
 1831   REM Call the assembler routine to display the cave map data
 1840   CALL level
 1841   REM Set variable to hold the count of number of diamonds
 1850   DI%=?&2FF1*256+?&2FF0
 1860 ENDPROC
 
 1861 REM ################################################################################
 1870 DEFPROChelp
 1880   VDU 28,5,20,36,3,12
 1890   COLOUR 129
 1900   VDU 28,4,19,35,2,12
 1910   COLOUR 128
 1920   VDU 28,5,18,34,3,12
 1930   COLOUR 2
 1940   PRINT"Q/W/P/L or ›œž"
 1950   PRINT" CTRL or SPACE"'"    DELETE"
 1960   PRINT"   SHIFT+CTRL"'"   SHIFT+DELETE"
 1970   PRINT'" T"'"    Z/X"'"  0-9/R/F/N"'" F1-F3"
 1980   PRINT"   E"'"     C"''" SHIFT+S"'"SHIFT+L"'"   H";
 1990   COLOUR3:PRINTTAB(16,0)"- move cursor"
 2000   PRINTTAB(15,1)"- place sprite"
 2010   PRINTTAB(11,2)"- remove sprite"
 2020   PRINTTAB(14,3)"- sprite fill"
 2030   PRINTTAB(16,4)"- wipe cave"
 2040   PRINTTAB(3,6)"- toggle start/end visible"
 2050   PRINTTAB(8,7)"- sprite selection"'" ("
 2060   PRINTTAB(12,8)"- shortcut keys)"
 2070   PRINTTAB(7,9)"- change cave colours"
 2080   PRINTTAB(5,10)"- edit cave parameters"
 2090   PRINTTAB(7,11)"- change cave name"
 2100   PRINTTAB(9,13)"- save cave to disk"
 2110   PRINTTAB(8,14)"- load cave from disk"
 2120   PRINTTAB(5,15)"- view this help page";
 2130   *FX15
 2140   G=GET
 2150   IF X%<1 VDU28,0,20,39,1,12,26: ENDPROC
 2160   VDU 26
 2170   PROCcave
 2180   PROCstartend
 2190 ENDPROC
 
 2200 DEFPROCstatus
 2210   PROCcol
 2220   COLOUR2
 2230   FOR r%=3 TO 29
 2240     IF r%=21 OR r%=22 OR r%=24 OR r%=26 OR r%=28 PROCspr(&900+PV%(r%)*&10,&3000+PY%(r%)*&280+PX%(r%)*&10) ELSE PRINTTAB(PX%(r%),PY%(r%))FNnum(PV%(r%))
 2250   NEXT
 2260   COLOUR 3
 2270   PROCdia
 2280 ENDPROC
 
 2290 DEFPROCparams
 2300   LOCAL step%,min%
 2310   REPEAT
 2320     IF INKEY-17 OR INKEY-26 PA%=(PA%+29) MOD 30
 2330     IF INKEY-34 OR INKEY-122 PA%=(PA%+1) MOD 30
 2340     r%=PA%
 2350     IF INKEY-36 T%=ABS(T%-1): PROCstartend
 2360     min%=0: IF r%<16min%=1
 2370     step%=1:IF INKEY-1 step%=10
 2380     IF(INKEY-56 OR INKEY-58) PV%(r%)=PV%(r%)+step%:CH%=1
 2390     IF(INKEY-87 OR INKEY-42) PV%(r%)=PV%(r%)-step%:CH%=1
 2400     IF PV%(r%)>PM%(r%)PV%(r%)=PM%(r%)
 2410     IF PV%(r%)<min%PV%(r%)=min%
 2420     COLOUR 130:COLOUR 0
 2430     PRINTTAB(PX%(r%),PY%(r%));
 2440     IF r%<3COLOURr%+1:COLOUR 128:PRINTSTR$(r%+1):GOTO 2470
 2450     IF r%=21 OR r%=22 OR r%=24 OR r%=26 OR r%=28 COLOUR 3:VDU 31,PX%(r%),PY%(r%),255: GOTO 2470
 2460     PRINTFNnum(PV%(r%));
 2470     COLOUR 128:COLOUR 2
 2480     PRINTTAB(PX%(r%),PY%(r%));
 2490     IF r%<3 COLOUR 129+r%:COLOUR 0:PRINTSTR$(r%+1): GOTO 2520
 2500     IF r%=21 O Rr%=22 OR r%=24 OR r%=26 OR r%=28 PROCspr(&900+PV%(r%)*&10,&3000+PY%(r%)*&280+PX%(r%)*&10): GOTO 2520
 2510     PRINTFNnum(PV%(r%))
 2520     IF r%<3 VDU19,r%+1,PV%(r%);0;
 2530     UNTIL INKEY-35 OR INKEY-113
 2540   COLOUR 128:COLOUR 3
 2550 ENDPROC
 
 2551 REM Enter cave name
 2560 DEFPROCname
 2570   LOCAL L%,S$,ST$
 2580   ST$=" 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
 2590   *FX15
 2600   COLOUR 129:COLOUR 3
 2610   PRINTTAB(13,22)CA$;
 2620   S$=CA$
 2630   REPEAT
 2640     G=GET
 2650     L%=LENS$
 2660     IF INSTR(ST$,CHR$G)>0 AND L%<13S$=S$+CHR$G: VDU G
 2670     IF G=127ANDL%>0S$=LEFT$(S$,L%-1): VDU G
 2680     UNTIL G=13 OR G=27
 2690   IF G=27 S$=""
 2700   IF S$="" GOTO 2770
 2710   COLOUR 3
 2720   CA$=S$
 2730   t%=?&A40
 2740   $&A23=CA$
 2750   ?&A40=t%
 2760   CH%=1
 2770   COLOUR 0:PRINTTAB(13,22)CA$
 2780   COLOUR 128: COLOUR 3
 2790 ENDPROC
 
 2791 REM Pseudo-random generation of tiles
 2800 DEF PROCpseudo
 2805   REM Set DIFFICULTY_LEVEL (currently 1 below)
 2806   REM Get PV%(16) onwards for the seed value
 2810   ?(pseudo+1)=PV%(16)
 2820   CALL pseudo
 2830   PROCcave
 3700 ENDPROC
 
 3791 REM Data for parameters
 3800   DATA &1C,35,22,7,&1D,37,22,7,&1E,39,22,7
 3810   DATA &00,8,24,0,&01,22,24,0,&0C,37,24,0
 3820   DATA &02,13,25,0,&03,19,25,0,&04,25,25,0,&05,31,25,0,&06,37,25,0
 3830   DATA &07,13,26,0,&08,19,26,0,&09,25,26,0,&0A,31,26,0,&0B,37,26,0
 3840   DATA &0E,13,28,0,&0F,19,28,0,&10,25,28,0,&11,31,28,0,&12,37,28,0
 3850   DATA &0D,11,29,9
 3860   DATA &17,17,29,9,&13,19,29,100
 3870   DATA &18,23,29,9,&14,25,29,100
 3880   DATA &19,29,29,9,&15,31,29,100
 3890   DATA &1A,35,29,9,&16,37,29,100
 3900   DATA Blank Space,Dirt,Brick Wall,Steel Wall,Diamond,Boulder,Firefly,Amoeba,Butterfly,Magic Wall,Start Point,Exit Square,Null Tile
