// JOB plot.samplelines.sas
sas plot.samplelines.sas
spool cont to email
//spool cont printer 'lptxt -l115 -s6 -f LetterGothic-Bold'
splfile plot.samplelines.l*
// FILE plot.samplelines.sas
*______________________________________________________________________________;
*                                                                              ;
* /programs/apps/sas/macro.library/plot.samplelines.sas
*
* Plots sample of SAS Graph lines according to number
*
* NOTE:  The width and spacing of dashes appears to change with versions,
*        platforms, and drivers
*______________________________________________________________________________;
*                                                                              ;
  options pagesize=107 linesize=132 nofmterr;
  data temp; x=0; y=0;
  run;
*______________________________________________________________________________;
*                                                                              ;
*                                P L O T S                                     ;
*______________________________________________________________________________;
*                                                                              ;
* Bring in plot macro                                                          ;
  filename plt "!MACROS/plot"; %inc plt;
  libname graphs '/programs/apps/sas/macro.library';
  filename gsasfile
    '/programs/apps/sas/macro.library/plot.samplelines.ps';
*******************************************************************************;
* Generate a line per SAS Graph line number                                    ;
  %plot(
        id l="samplelines", end;
        labely l="Line Type", end;
        axisx order=(0 to 10 by 10), minor=(number=1), end;
        axisy order=(0 to 50 by 5), minor=(number=4), end;
        tuple set=temp, x=x, y=y, symbsize=0, end;
        connect line=1,width=.5,points=(0,1,10,1),end;
        connect line=2,width=.5,points=(0,2,10,2),end;
        connect line=3,width=.5,points=(0,3,10,3),end;
        connect line=4,width=.5,points=(0,4,10,4),end;
        connect line=5,width=.5,points=(0,5,10,5),end;
        connect line=6,width=.5,points=(0,6,10,6),end;
        connect line=7,width=.5,points=(0,7,10,7),end;
        connect line=8,width=.5,points=(0,8,10,8),end;
        connect line=9,width=.5,points=(0,9,10,9),end;
        connect line=10,width=.5,points=(0,10,10,10),end;
        connect line=11,width=.5,points=(0,11,10,11),end;
        connect line=12,width=.5,points=(0,12,10,12),end;
        connect line=13,width=.5,points=(0,13,10,13),end;
        connect line=14,width=.5,points=(0,14,10,14),end;
        connect line=15,width=.5,points=(0,15,10,15),end;
        connect line=16,width=.5,points=(0,16,10,16),end;
        connect line=17,width=.5,points=(0,17,10,17),end;
        connect line=18,width=.5,points=(0,18,10,18),end;
        connect line=19,width=.5,points=(0,19,10,19),end;
        connect line=20,width=.5,points=(0,20,10,20),end;
        connect line=21,width=.5,points=(0,21,10,21),end;
        connect line=22,width=.5,points=(0,22,10,22),end;
        connect line=23,width=.5,points=(0,23,10,23),end;
        connect line=24,width=.5,points=(0,24,10,24),end;
        connect line=25,width=.5,points=(0,25,10,25),end;
        connect line=26,width=.5,points=(0,26,10,26),end;
        connect line=27,width=.5,points=(0,27,10,27),end;
        connect line=28,width=.5,points=(0,28,10,28),end;
        connect line=29,width=.5,points=(0,29,10,29),end;
        connect line=30,width=.5,points=(0,30,10,30),end;
        connect line=31,width=.5,points=(0,31,10,31),end;
        connect line=32,width=.5,points=(0,32,10,32),end;
        connect line=33,width=.5,points=(0,33,10,33),end;
        connect line=34,width=.5,points=(0,34,10,34),end;
        connect line=35,width=.5,points=(0,35,10,35),end;
        connect line=36,width=.5,points=(0,36,10,36),end;
        connect line=37,width=.5,points=(0,37,10,37),end;
        connect line=38,width=.5,points=(0,38,10,38),end;
        connect line=39,width=.5,points=(0,39,10,39),end;
        connect line=40,width=.5,points=(0,40,10,40),end;
        connect line=41,width=.5,points=(0,41,10,41),end;
        connect line=42,width=.5,points=(0,42,10,42),end;
        connect line=43,width=.5,points=(0,43,10,43),end;
        connect line=44,width=.5,points=(0,44,10,44),end;
        connect line=45,width=.5,points=(0,45,10,45),end;
        connect line=46,width=.5,points=(0,46,10,46),end;
        );
        run;
*******************************************************************************;
* Generate a line per SAS Graph line number, full width                        ;
  %plot(
        id l="samplelines", end;
        labely l="Line Type", end;
        axisx order=(0 to 10 by 10), minor=(number=1), end;
        axisy order=(0 to 50 by 5), minor=(number=4), end;
        tuple set=temp, x=x, y=y, symbsize=0, end;
        connect line=1,points=(0,1,10,1),end;
        connect line=2,points=(0,2,10,2),end;
        connect line=3,points=(0,3,10,3),end;
        connect line=4,points=(0,4,10,4),end;
        connect line=5,points=(0,5,10,5),end;
        connect line=6,points=(0,6,10,6),end;
        connect line=7,points=(0,7,10,7),end;
        connect line=8,points=(0,8,10,8),end;
        connect line=9,points=(0,9,10,9),end;
        connect line=10,points=(0,10,10,10),end;
        connect line=11,points=(0,11,10,11),end;
        connect line=12,points=(0,12,10,12),end;
        connect line=13,points=(0,13,10,13),end;
        connect line=14,points=(0,14,10,14),end;
        connect line=15,points=(0,15,10,15),end;
        connect line=16,points=(0,16,10,16),end;
        connect line=17,points=(0,17,10,17),end;
        connect line=18,points=(0,18,10,18),end;
        connect line=19,points=(0,19,10,19),end;
        connect line=20,points=(0,20,10,20),end;
        connect line=21,points=(0,21,10,21),end;
        connect line=22,points=(0,22,10,22),end;
        connect line=23,points=(0,23,10,23),end;
        connect line=24,points=(0,24,10,24),end;
        connect line=25,points=(0,25,10,25),end;
        connect line=26,points=(0,26,10,26),end;
        connect line=27,points=(0,27,10,27),end;
        connect line=28,points=(0,28,10,28),end;
        connect line=29,points=(0,29,10,29),end;
        connect line=30,points=(0,30,10,30),end;
        connect line=31,points=(0,31,10,31),end;
        connect line=32,points=(0,32,10,32),end;
        connect line=33,points=(0,33,10,33),end;
        connect line=34,points=(0,34,10,34),end;
        connect line=35,points=(0,35,10,35),end;
        connect line=36,points=(0,36,10,36),end;
        connect line=37,points=(0,37,10,37),end;
        connect line=38,points=(0,38,10,38),end;
        connect line=39,points=(0,39,10,39),end;
        connect line=40,points=(0,40,10,40),end;
        connect line=41,points=(0,41,10,41),end;
        connect line=42,points=(0,42,10,42),end;
        connect line=43,points=(0,43,10,43),end;
        connect line=44,points=(0,44,10,44),end;
        connect line=45,points=(0,45,10,45),end;
        connect line=46,points=(0,46,10,46),end;
        );
        run;
*******************************************************************************;
