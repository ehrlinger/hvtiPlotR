/*
// JOB ce.states.ST_toJohn.sas
sas8.2 ce.states.ST_toJohn.sas
//cp ce.states.ST_toJohn.l*\
//   /studies/cardiac/valves/aortic/replacement/partner_publication_office/partner1b/mortality_5y/graphs/.
//spool cont printer 'lptxt -l110 -s6 -f LetterGothic-Bold'
spool cont to email
splfile ce.states.ST_toJohn.l*
// FILE ce.states.ST_toJohn.sas
*/
*______________________________________________________________________________;
*                                                                              ;
* /graphs/ce.states.ST_toJohn.sas
*______________________________________________________________________________;
*                                                                              ;
  %let STUDY=/studies/cardiac/valves/aortic/replacement/partner_publication_office/partner1b/mortality_5y;
*______________________________________________________________________________;
*                                                                              ;
* Partner 1B: TAVR vs Standard Therapy (5 Year Events Data)
* Multi-Center n=358
*
* Analysis of 3 states: alive without stroke, death before stroke,
* and stroke
*
* Plot of competing events
*______________________________________________________________________________;
*                                                                              ;
  options pagesize=107 linesize=132 nofmterr;
  libname library "&STUDY/datasets";
  libname est     "&STUDY/estimates";
  libname graphs  "&STUDY/graphs";
  data built; set library.built;
    if TAVR = 0;
  run;
  title1 "Partner 1B: TAVR vs Standard Therapy (5 Year Events Data)";
  title2 "Multi-Center n=358";
  title3 "Competing Risks: Death Before Stroke and Stroke";
  title4 "States:  Alive, Dead before Stroke, and Stroke";
*******************************************************************************;
* Data transformations                                                         ;
/*  filename vars "&STUDY/datasets/vars.sas"; %inc vars; %vars;  */
*______________________________________________________________________________;
*                                                                              ;
*         M U L T I P L E   D E C R E M E N T   E S T I M A T E S              ;
*                                                                              ;
*             F R O M   L I F E   T A B L E   A N A L Y S I S                  ;
*______________________________________________________________________________;
*                                                                              ;
* Bring in multiple decrement macro                                            ;
  filename  greenwod  "!MACROS/markov.sas";  %inc  greenwod;
*______________________________________________________________________________;
*                                                                              ;
*               D E S C R I P T I O N   O F   P A R A M E T E R S              ;
*______________________________________________________________________________;
*                                                                              ;
*  Input data set:  SAS dataset or view  Unchanged by the algorithm            ;
*                                                                              ;
*  Output data set:  New SAS data set, whose name is a macro parameter         ;
*                                                                              ;
*  Other interactions:  Creates data sets temp and tempset.  These are not     ;
*      needed at end of execution of the macro.                                ;
*                                                                              ;
*******************************************************************************;
*  Input data set variables used                                               ;
*                                                                              ;
*      The variable names are passed as parameters to the macro. The values of ;
*      the variables are as further stated below.                              ;
*      below.                                                                  ;
*                                                                              ;
*  &timevar    The numeric variable containing outcome times.  There will be   ;
*              exactly one outcome for each time.  Multiple outcomes are       ;
*              handled by multiple records, with the same value of the outcome ;
*              time.                                                           ;
*                                                                              ;
*  &eventvar   the numeric variable containing event info.  Values:            ;
*                   1 --- &lastevnt   transitions to a new state               ;
*                   others            censored, for this use of the macro      ;
*              THE CODE ASSUMES THAT EVENTVAR CONTAINS INTEGERS ONLY, AND DOES ;
*              NOT CHECK FOR THIS CONDITION.  IF THE CONDITION IS VIOLATED,    ;
*              THE RESULTS ARE UNDEFINED.                                      ;
*                                                                              ;
*  &lastevnt   The highest event value that will be analyzed.  This must be an ;
*              integer >= 1. The SAS statements in the code will in principle  ;
*              allow values of &lastevnt <= 99, but the number of variables    ;
*              will become so large as to cause poor execution long before     ;
*              that time.  (Interpretation of large values of &lastevnt is     ;
*              questionable, so this limitation is one of form, rather than    ;
*              substance.)                                                     ;
*                                                                              ;
*              In a typical use of the macro, event 1 will be an event of      ;
*              primary interest, such as structural valve failure, event 2     ;
*              will be death, and other values will represent different forms  ;
*              of censoring.  Using the macro with &lastevnt = 1 will produce  ;
*              the ordinary Kaplan-Meier analysis with death being just one    ;
*              form of censoring.  Using the macro with &lastevnt = 2 will     ;
*              produce the actual incidence of the event of interest, as well  ;
*              as the actual incidence of death.                               ;
*                                                                              ;
*******************************************************************************;
*  Output  Variable names are fixed in the macro, and some labels are          ;
*              supplied.                                                       ;
*                                                                              ;
*  &timevar    The same name as in the input data set. There is one output     ;
*              record for each distinct value in the input data set, as long   ;
*              as there is at least one event occurring at that time.  Other   ;
*              times are ignored.                                              ;
*                                                                              ;
*  atrisk      The number of patients at risk at the time                      ;
*                                                                              ;
*  event1      event&lastevnt                                                  ;
*              The number of events of that type at that time.                 ;
*                                                                              ;
*  censored    The number of censored observations.                            ;
*                                                                              ;
*  incid0      The estimated probability of remaining in state 0.  This is the ;
*              ordinary Kaplan-Meier estimate of freedom from all events.      ;
*                                                                              ;
*  incid1      incid&lastevnt                                                  ;
*              The incidence of that event, up to and including the time.      ;
*              Freedom from event is 1 - incidence.                            ;
*                                                                              ;
*  error0      error&lastevnt                                                  ;
*              The standard errors of each incidence estimate.  These are the  ;
*              square roots of the corresponding entries of the variance       ;
*              matrix.  The user may capture the entire variance matrix for    ;
*              other use.                                                      ;
*______________________________________________________________________________;
*                                                                              ;
  data built; set built;
  title6 "Greenwood Multiple Decrements";
  event=0;
  if st_dead then event=1;
  if st_strk then event=2;
  %greenwod(inset=built, outset=green, timevar=iv_state, eventvar=event,
            lastevnt=2);
  data green; set green(where=(event1>0 or event2>0));
  checksum=pk0_0+pk0_1+pk0_2;
  sginit=pk0_0;
  sgdead=pk0_1;
  sgstrk=pk0_2;
*******************************************************************************;
* Confidence limits from SEs                                                   ;
  stlinit=1; stuinit=1;
  if sginit<1 then do;
    sinit=error0/(sginit*(1-sginit));
    stuinit=1/(1 + ((1-sginit)/sginit)*exp(-sinit));
    stlinit=1/(1 + ((1-sginit)/sginit)*exp(sinit));
  end;

  stldead=0; studead=0;
  if sgdead>0 then do;
    sdead=error1/(sgdead*(1-sgdead));
    studead=1/(1+((1-sgdead)/sgdead)*exp(-sdead));
    stldead=1/(1+((1-sgdead)/sgdead)*exp(sdead));
  end;

  stlstrk=0; stustrk=0;
  if sgstrk>0 then do;
    sstrk=error2/(sgstrk*(1-sgstrk));
    stustrk=1/(1+((1-sgstrk)/sgstrk)*exp(-sstrk));
    stlstrk=1/(1+((1-sgstrk)/sgstrk)*exp(sstrk));
  end;
*******************************************************************************;
* Print and plot results                                                       ;
  proc print label data=green;
       var iv_state event1 event2 censored atrisk sginit error0 stlinit
           stuinit 
           sgdead error1 stldead studead 
           sgstrk error2 stlstrk stustrk 
           checksum;
  proc plot;
       plot sginit*iv_state='A' sgdead*iv_state='D' sgstrk*iv_state='S'
            checksum*iv_state='T'
            /overlay vaxis=0 to 1 by 0.1;
  run;
*______________________________________________________________________________;
*                                                                              ;
*    P A R A M E T R I C   C O M P E T I N G   R I S K   E S T I M A T E S     ;
*______________________________________________________________________________;
*                                                                              ;
* Generate and output time points                                              ;
* NOTE:  We need plenty of points since we are not using a robust integration  ;
* NOTE:  algorithm.                                                            ;
  title6 "Parametric Cumulative Incidence Estimates";
  data predict;
  max=log(5); min=-15; inc=(max-min)/999.9;
  do ln_time=min to max by inc, max; years=exp(ln_time); output; end;
  drop min max inc ln_time;

  data pred2;
  max=5; min=0.01; inc=(max-min)/999.9;
  do years=min to max by inc; output; end;
  
  data predict; set predict pred2;
  months=years*12;
  
  proc sort; by years;
  data predict; set predict;
  retain prevtime 0;
  if (years-prevtime)=0 then delete; else prevtime=years;
*______________________________________________________________________________;
*                                                                              ;
* Death before stroke                                                 ;
*______________________________________________________________________________;
*                                                                              ;
* Do predictions for death before stroke                               ;
  %hazpred(
  proc hazpred data=predict inhaz=est.hzstdeadst out=preddead; time years; );
*******************************************************************************;
* Save the computations we have, and keep only what is necessary, since        ;
* PROC HAZPRED does not want to find variables in the input data set that are  ;
* reserved for itself (it will not write over such variables). Also compute    ;
* variance of the survivorship function.                                       ;
  data preddead; set preddead;
  sedeath=_surviv; sldeath=_cllsurv; sudeath=_clusurv;
  hedeath=_hazard; hldeath=_cllhaz; hudeath=_cluhaz;
  zsurv=log((1/_surviv)-1);
    cluz=log((1/_clusurv)-1);
    vedeath=(cluz-zsurv)**2;
  keep months years sedeath sldeath sudeath hedeath hldeath hudeath vedeath;
* proc print;
*______________________________________________________________________________;
*                                                                              ;
* Stroke                                                ;
*______________________________________________________________________________;
*                                                                              ;
* Do predictions for CABG as first reintervention                              ;
  %hazpred(
  proc hazpred data=predict inhaz=est.hzststrkst out=predstrk; time years; );
  data predstrk; set predstrk;
  sestrk=_surviv; slstrk=_cllsurv; sustrk=_clusurv;
  hestrk=_hazard; hlstrk=_cllhaz; hustrk=_cluhaz;
  zsurv=log((1/_surviv)-1);
    cluz=log((1/_clusurv)-1);
    vestrk=(cluz-zsurv)**2;
  keep months years sestrk slstrk sustrk hestrk hlstrk hustrk vestrk;
* proc print;
*______________________________________________________________________________;
*                                                                              ;
* Cumulative incidence calculations                                            ;
*______________________________________________________________________________;
*                                                                              ;
* Merge all predictions                                                        ;
  data all; merge preddead predstrk;
  time=years;
* proc print;
*******************************************************************************;
* Calculate cumulative incidences                                              ;
  data all; set all;
  retain lag_time 0 no1init  100;
  retain tx1death 0 no1death   0;
  retain tx1strk  0 no1strk    0;
*******************************************************************************;
* Patients alive and without a completed repair (joint survival distribution)  ;
  noinit=sedeath*sestrk*100;
*******************************************************************************;
* Transition (TX) from initial state to each terminating state is the product  ;
* of the hazard function by the number of individuals at risk (the same for all;
* these states, since everyone gets there from the initial state).             ;
  txdeath=no1init*hedeath;
  txstrk =no1init*hestrk;
*******************************************************************************;
* Get increment of time for the integration (DT)                               ;
  no1init=noinit;
  dt=time-lag_time;
  lag_time=time;
*******************************************************************************;
* Cumulative incidence (number) in each state by integration (trapezoid rule)  ;
* This will be the integration of the transition rate.                         ;
  nodeath=no1death + dt*(txdeath + tx1death)/2;
  nostrk =no1strk  + dt*(txstrk  + tx1strk) /2;
*******************************************************************************;
* Lags for next integration (NO1 and TX1 will then be the previous values)     ;
  no1death=nodeath; tx1death=txdeath;
  no1strk =nostrk;  tx1strk =txstrk;
*******************************************************************************;
* All cumulative incidences should add to the original number (or 1), and      ;
* should be similar to SEINITL*(1 or original number)                          ;
  check=noinit + nodeath + nostrk;
*******************************************************************************;
* Confidence limits for the estimates                                          ;
  cldeath=0; cudeath=0;
  if nodeath>0 then do;
    z=-log((100/nodeath)-1);
    sez=sqrt(vedeath);
    cluz=z-sez; cllz=z+sez;
    cldeath=100/(1 + exp(-cluz));
    cudeath=100/(1 + exp(-cllz));
  end;

  clstrk=0; custrk=0;
  if nostrk>0 then do;
    z=-log((100/nostrk)-1);
    sez=sqrt(vestrk);
    cluz=z-sez; cllz=z+sez;
    clstrk=100/(1 + exp(-cluz));
    custrk=100/(1 + exp(-cllz));
  end;

  clinit=1; cuinit=1;
  if noinit<100 then do;
    z=log((100/noinit)-1);
    sez=sqrt((vedeath+vestrk)/3);
    cluz=z+sez; cllz=z-sez;
    clinit=100/(1 + exp(cluz));
    cuinit=100/(1 + exp(cllz));
  end;
*******************************************************************************;
* Print result                                                                 ;
  proc print; var time sedeath hedeath txdeath nodeath
                       sestrk hestrk txstrk nostrk check;
  proc print; var time nodeath cldeath cudeath
                       nostrk clstrk custrk
                       noinit clinit cuinit;
*******************************************************************************;
* Plot result                                                                  ;
  proc plot;
       plot noinit*time='A' nodeath*time='D' nostrk*time='S'
      /overlay vaxis=0 to 100 by 10 haxis=0 to 5 by 1;
  run;
*______________________________________________________________________________;
*                                                                              ;
*                              P L O T S
*______________________________________________________________________________;
*                                                                              ;
* Scale nonparametric estimates                                                ;
 data green; set green;
  sginit=sginit*100; stlinit=.; stuinit=.;

  sgdead1=sgdead*100; sgstrk1=sgstrk*100; sgptca1=sgptca*100; 
  stldead1=.; studead1=.; stlstrk1=.; stustrk1=.; stlptca1=.; stuptca1=.;
  

  /* for dead before reop*/
   if atrisk in (121, 85, 48, 20, 12, 5)
    then do;
    stldead1=stldead*100;
    studead1=studead*100;
    sgdead1=sgdead*100;
   end;

 /* for reop cabg*/
  if atrisk in (122, 100, 9)
    then do;
    stlstrk1=stlstrk*100;
    stustrk1=stustrk*100;
  end;


  if event1=0 then do; sgdead1=.; end;
  if event2=0 then do; sgstrk1=.; end;

  run;

  run;
*******************************************************************************;
* Scale parametric estimates                                                   ;
  data predstrk; set predstrk;
  sestrk=100*sestrk; slstrk=100*slstrk; sustrk=100*sustrk;
  hestrk=100*hestrk; hlstrk=100*hlstrk; hustrk=100*hustrk;

  data preddead; set preddead;
  sedeath=100*sedeath; sldeath=100*sldeath; sudeath=100*sudeath;
  hedeath=100*hedeath; hldeath=100*hldeath; hudeath=100*hudeath;

  data all; set all;
  cestrk=100-nostrk;


data green_j; set green; keep iv_state sginit stlinit stuinit
                                       sgdead1 stldead1 studead1
                                       sgstrk1 stlstrk1 stustrk1;
                              
libname out xport "&STUDY/datasets/npar_cst.xpt";
  data out.npar_cst;
           set green_j;
run;


data all_j; set all;  keep years   noinit clinit cuinit 
                                   nodeath cldeath cudeath 
                                   nostrk clstrk custrk  ;
                                                               
libname out xport "&STUDY/datasets/par_cst.xpt";
  data out.par_cst;
           set all;
run;

*******************************************************************************;
* Bring in PostScript plot macro                                               ;
  filename plt "!MACROS/plot.sas"; %inc plt;
  filename gsasfile pipe 'lp';
*______________________________________________________________________________;
*                                                                              ;
*                       P O S T S C R I P   P L O T S
*______________________________________________________________________________;
*                                                                              ;
* Multiple decrement, nonparametric and parametric                             ;
  filename gsasfile "&STUDY/graphs/ce.states.ST_toJohn.both.ps";
  %plot(goptions gsfmode=replace, device=pscolor, gaccess=gsasfile end;
    id l="&STUDY/graphs/ce.states.ST_toJohn.sas percent", end;
    labelx l="Years After Randomization", end;
      axisx order=(0 to 5 by 1), minor=none, end;
    labely l="Percent in Each Category (ST)", end;
      axisy order=(0 to 100 by 10), minor=none, end;


/******NON-PARAMETRIC: SYMBOLS AND CONFIDENCE BARS *******/
    tuple set=green, symbol=dot, symbsize=1/2, linepe=0, linecl=0,
      ebarsize=3/4, ebar=1,
      x=iv_state, y=sginit, cll=stlinit, clu=stuinit, color=black, end;
    tuple set=green, symbol=circle, symbsize=1/2, linepe=0, linecl=0,
      ebarsize=3/4, ebar=1,
      x=iv_state, y=sgdead1, cll=stldead1, clu=studead1, color=blue, end;
     tuple set=green, symbol=square, symbsize=1/2, linepe=0, linecl=0,
      ebarsize=3/4, ebar=1,
      x=iv_state, y=sgstrk1, cll=stlstrk1, clu=stustrk1, color=blue, end;
      

/**********PARAMETRIC : SOLID LINES AND CONFIDENCE INTERVALS**********/      
    tuple set=all, x=years, y=noinit, cll=clinit, clu=cuinit,
      width=0.5,color=black, end;

    tuple set=all, x=years, y=nodeath, cll=cldeath, clu=cudeath,
      width=0.5,color=blue, end;

    tuple set=all, x=years, y=nostrk, cll=clstrk, clu=custrk,
      linecl=2, width=0.5,color=blue, end;
  );
  run;
*******************************************************************************;

*______________________________________________________________________________;
*                                                                              ;
*       C G M   F I L E S   F O R   P O W E R P O I N T   S L I D E S
*______________________________________________________________________________;
*                                                                              ;
* Competing risks, parametric only                                             ;
  filename gsasfile "&STUDY/graphs/ce.states.ST_toJohn.cgm";
  %plot(goptions gsfmode=replace, device=cgmmppa, ftext=hwcgm001, end;
    axisx order=(0 to 5 by 1), minor=none, value=(height=2.4), end;
    axisy order=(0 to 100 by 20), minor=none, value=(height=2.4), 
      value=(height=2.4 j=r ' ' '20' '40' '60' '80' '100'), end;
    tuple set=all, x=years, y=noinit, width=3, color=gray, end;
    tuple set=all, x=years, y=nostrk, width=3, color=red, end;
    tuple set=all, x=years, y=nodeath, width=3, color=blue, end;
  );
  run;  
