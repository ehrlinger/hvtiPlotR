// JOB hp.dead.sas
sas8.2 hp.dead.sas
//cp  hp.dead.l*\
//   /studies/cardiac/valves/size/aortic/metasize/graphs/.
//spool cont printer 'lptxt -l115 -s6 -f LetterGothic-Bold'
spool cont to email
splfile hp.dead.l*
// FILE hp.dead.sas
*______________________________________________________________________________;
*                                                                              ;
* /studies/cardiac/valves/aortic/size/metasize/distributions/ac.dead.sas
*______________________________________________________________________________;
*                                                                              ;
  %let STUDY=/studies/cardiac/valves/aortic/size/metasize;
*______________________________________________________________________________;
*                                                                              ;
* Aortic Valve Replacement
* Meta-Analysis of Individual Series
*
* Plot hazard function for death
*______________________________________________________________________________;
*                                                                              ;
  options pagesize=107 linesize=132;
  libname library "&STUDY/datasets";
  libname est v6  "&STUDY/estimates";
  libname graphs  "&STUDY/graphs";
  data built; set library.meta;
  title1 "Aortic Valve Replacement";
  title2 "Meta-Analysis of Multiple Experiences";
  title3 "Life Table and Hazard Function Analyses";
*******************************************************************************;
* Data transformations                                                         ;
  filename vars "&STUDY/datasets/vars.sas";
  %inc vars; %vars(in=built, out=built);
*______________________________________________________________________________;
*                                                                              ;
*           N O N - P A R A M E T R I C   E S T I M A T E S                    ;
*______________________________________________________________________________;
*                                                                              ;
  filename kaplan "!MACROS/kaplan"; %inc kaplan;
  %kaplan(in=built, interval=iv_dead, event=dead, pevent=1, out=plout,
          oevent=0, plots=0, plotc=0, nolist=0,
          hlabel=Years After Aortic Valve Replacement, elabel=Death);
*******************************************************************************;
* Pick from the Kaplan-Meier estimates those events at "nice" time points for  ;
* depiction of confidence limits.  Set the remaining to missing.  This is      ;
* aided, if no listing available, by making nolist=1 in the macro call.        ;
  data plout; set plout; if dead;
  cum_surv=cum_surv*100;
  bar=0; cl_lower=cl_lower*100; cl_upper=cl_upper*100;
  if number in (10040,5908,2573,600) then bar=1;
  if bar=0 then do; cl_lower=.; cl_upper=.; end;
  run;
*______________________________________________________________________________;
*                                                                              ;
*                 P A R A M E T R I C   E S T I M A T E S                      ;
*______________________________________________________________________________;
*                                                                              ;
* Generate and output time points                                              ;
  data predict; digital=0;
  max=log(15); min=-5; inc=(max-min)/999.9;
  do ln_time=min to max by inc, max;
    years=exp(ln_time);
    output;
  end;
  drop min max inc ln_time;
*******************************************************************************;
* Generate time points at "nice" intervals for tabular (digital) depiction     ;
  data digital; digital=1;
  do years=30/365.2425,1 to 15 by 1; output; end;
*******************************************************************************;
* Transformations of variables                                                 ;
  data predict; set predict digital;
*******************************************************************************;
* Do predictions                                                               ;
  %hazpred(
  proc hazpred data=predict inhaz=est.hzdead out=predict; time years; );
*******************************************************************************;
* Digital nomogram                                                             ;
  data digital; set predict; if digital=1;
  proc sort; by years;
  proc print d; var years
       _surviv _cllsurv _clusurv _hazard _cllhaz _cluhaz;
  run;
*______________________________________________________________________________;
*                                                                              ;
*                               P L O T S                                      ;
*______________________________________________________________________________;
*                                                                              ;
* Printer plot survival and hazard                                             ;
  proc plot data=predict;
       plot _surviv*years='d' _cllsurv*years='.' _clusurv*years='.'
          /overlay vaxis=0 to 1 by 0.1;
       plot _hazard*years='d' _cllhaz*years='.' _cluhaz*years='.'/overlay;
  run;
*******************************************************************************;
* Scale plot output (after getting rid of digital nomogram points)             ;
  data predict; set predict; if digital=0;
  ssurviv=_surviv*100;
  scllsurv=_cllsurv*100;
  sclusurv=_clusurv*100;

  shazard=_hazard*100;
  scllhaz=_cllhaz*100;
  scluhaz=_cluhaz*100;

  proc means;
  run;
*******************************************************************************;
* Bring in PostScript plot macro                                               ;
  filename plot "!MACROS/plot.sas"; %inc plot;
*______________________________________________________________________________;
*                                                                              ;
*                     P O S T S C R I P T   P L O T S                          ;
*______________________________________________________________________________;
*                                                                              ;
* Survival                                                                     ;
  filename gsasfile "&STUDY/graphs/hp.dead.survival.test.ps";
* %plot(goptions gout=graphs.ptdead ftext=swiss, end;
  options mprint mlogic;
  %plot(goptions ftext=swiss, end;
    id l="&STUDY/graphs/hp.dead.sas survival", end;
    labelx l="Years",end;
      axisx order=(0 to 15 by 5), minor=(number=4), end;
    labely l="Percent Survival",end;
      axisy order=(0 to 100 by 10), minor=none, end;
    tuple set=plout, symbol=circle, symbsize=3/4, ebar=1, ebarsize=3/4,
      linepe=0, linecl=0,
      x=iv_dead, y=cum_surv, cll=cl_lower, clu=cl_upper, end;
    tuple set=predict, x=years, y=ssurviv, cll=scllsurv, clu=sclusurv, end;
  );
  run;
  %macro plots;
*______________________________________________________________________________;
*                                                                              ;
*                            C G M   P L O T S                                 ;
*______________________________________________________________________________;
*                                                                              ;
* Survival                                                                     ;
  filename gsasfile "&STUDY/graphs/hp.dead.surv.cgm";
  %plot(goptions gsfmode=replace, device=cgmmppa, ftext=hwcgm001, end;
    axisx order=(0 to 15 by 5), minor=none, value=(height=2.4), end;
    axisy order=(0 to 100 by 20), minor=none, value=(height=2.4), end;
    tuple set=predict, x=years, y=ssurviv, color=yellow, width=3, end;
  );
  run;
*******************************************************************************;
  %mend;
  quit;
