Avoiding a datastep and a sort when you have a smart key or groupformat

   Three solutions

      1. By processing using the first two characters of a long key
         Same results WPS and SAS

      2. Using GROUPFORMAT  and functions in formats
         WPS does not support FCMP
           ERROR: Procedure FCMP not known

      3. Using substring in proc sql group by  (diff problem to demonstrate)
         Same results WPS and SAS


https://goo.gl/Zcbxbj
https://communities.sas.com/t5/Base-SAS-Programming/How-to-operate-variables-according-to-certain-condition-of/m-p/429865

novinosrin profile ( changed his solution by eliminating the first datastep)
https://communities.sas.com/t5/user/viewprofilepage/user-id/138205

You can use the first character in ID for the SAS forum problem on the by statements.
I have removed some of the noise and changed the ID but the technique is quite general.
I also removed age because I just wanted to show

INPUT
=====

  Algorithm

     1. Sum weight by state. For AL sum=179
     2. if last state divide the last weight by the total in state  89/179


    WEIGHT     ID     |   RULES
                      |
      90      AL13    |
      89      AL43    |   Sum weight 90+89=179
                      |   If last.state then grpsubtot/grptot  89/179 = 0.49584
      91      VTAA    |
      91      VTDD    |   WANT
                      |     ID    GRPTOT    WEIGHT      WANT
      88      NY23    |
      87      NY33    |     AL      179       89      0.49721  89/179 = 0.49584
                      |     VT      182       91      0.50000
      92      TXCC    |     NY      175       87      0.49714
      92      TXBB    |     TX      184       92      0.50000



    * we need this format for the 'by GROUPFORMAT' option;

    * functions in formata Rick Langston;
    proc fcmp outlib=work.functions.locase;
      function keycut(key $) $4;
        cutkey=substr(key,1,2);    ** could use any function here;
      return(cutkey);
    endsub;
    run;quit;

    options cmplib=(work.functions);
    proc format;
      value $cutkey other=[keycut()];
    run;quit;


PROCESS
=======

  1. By processing using the first two characters of a long key

     data want;

       length id $2;  *** this limits the key to first two charactrs;
                      *** which is the state;
       grptot=0;
       do until(last.id);
          set have;
          by id notsorted;
          grptot+weight;
       end;

       do until(last.id);
          set have ;
          by id notsorted;
          if last.id then do;
              want=weight/grptot;
              output;
          end;
       end;

     run;quit;


  2. Using groupformat and functions in formats

     data want;

       format id $cutkey.;  *** this uses the first two chars bur could use any part of the smart key;
                            *** which is the state;
       grptot=0;

       do until(last.id);
          set have;
          by id notsorted GROUPFORMAT; ** notice groupformat;
          grptot+weight;
       end;

       do until(last.id);
          set have ;
          by id notsorted GROUPFORMAT; ** notice groupformat;
          if last.id then do;
              want=weight/grptot;
              output;
          end;
       end;

     run;quit;

  3. Using substring in proc sql group by  (diff problem to demonstrate)

     proc sql;
        create
            table want as
        select
            max(id) length=2 as cutkey
           ,sum(weight)    as tot_wgt
           ,max(weight) / calculated tot_wgt
        from
           have
        group
           by substr(id,1,2)
     ;quit;

*                _              _       _
 _ __ ___   __ _| | _____    __| | __ _| |_ __ _
| '_ ` _ \ / _` | |/ / _ \  / _` |/ _` | __/ _` |
| | | | | | (_| |   <  __/ | (_| | (_| | || (_| |
|_| |_| |_|\__,_|_|\_\___|  \__,_|\__,_|\__\__,_|

;


data have;
input Weight ID $;
cards4;
 90 AL13
 89 AL43
 91 VTAA
 91 VTDD
 88 NY23
 87 NY33
 92 TXCC
 92 TXBB
;;;;
run;quit;


* functions in formata Rick Langston;
proc fcmp outlib=work.functions.locase;
  function keycut(key $) $4;
    cutkey=substr(key,1,2);
  return(cutkey);
endsub;
run;quit;

options cmplib=(work.functions);
proc format;
  value $cutkey other=[keycut()];
run;quit;

*          _       _   _
 ___  ___ | |_   _| |_(_) ___  _ __  ___
/ __|/ _ \| | | | | __| |/ _ \| '_ \/ __|
\__ \ (_) | | |_| | |_| | (_) | | | \__ \
|___/\___/|_|\__,_|\__|_|\___/|_| |_|___/

 _ __ ___  ___| |_ _ __(_) ___| |_   | | ___ _ __   __ _| |_| |__
| '__/ _ \/ __| __| '__| |/ __| __|  | |/ _ \ '_ \ / _` | __| '_ \
| | |  __/\__ \ |_| |  | | (__| |_   | |  __/ | | | (_| | |_| | | |
|_|  \___||___/\__|_|  |_|\___|\__|  |_|\___|_| |_|\__, |\__|_| |_|
                                                   |___/
;

1. By processing using the first two characters of a long key

   %utl_submit_wps64('

   libname wrk sas7bdat "%sysfunc(pathname(work))";

   data wrk.want;

     length id $2;  *** this limits the key to first two charactrs;
                    *** which is the state;
     grptot=0;
     do until(last.id);
        set wrk.have;
        by id notsorted;
        grptot+weight;
     end;

     do until(last.id);
        set wrk.have ;
        by id notsorted;
        if last.id then do;
            want=weight/grptot;
            output;
        end;
     end;

   run;quit;
   ');

*                             __                            _
  __ _ _ __ ___  _   _ _ __  / _| ___  _ __ _ __ ___   __ _| |_
 / _` | '__/ _ \| | | | '_ \| |_ / _ \| '__| '_ ` _ \ / _` | __|
| (_| | | | (_) | |_| | |_) |  _| (_) | |  | | | | | | (_| | |_
 \__, |_|  \___/ \__,_| .__/|_|  \___/|_|  |_| |_| |_|\__,_|\__|
 |___/                |_|
;

  2. Using groupformat and functions in formats

    data want;

      format id $cutkey.;  *** this uses the first two chars bur could use any part of the smart key;
                           *** which is the state;
      grptot=0;

      do until(last.id);
         set have;
         by id notsorted GROUPFORMAT; ** notice groupformat;
         grptot+weight;
      end;

      do until(last.id);
         set have ;
         by id notsorted GROUPFORMAT; ** notice groupformat;
         if last.id then do;
             want=weight/grptot;
             output;
         end;
      end;

    run;quit;

*          _
 ___  __ _| |
/ __|/ _` | |
\__ \ (_| | |
|___/\__, |_|
        |_|
;


  3. Using substring in proc sql group by  (diff problem to demonstrate)

%utl_submit_wps64('
     libname wrk sas7bdat "%sysfunc(pathname(work))";
     proc sql;
        create
            table wrk.wantwps as
        select
            max(id) length=2 as cutkey
           ,sum(weight)    as tot_wgt
           ,max(weight) / calculated tot_wgt
        from
           wrk.have
        group
           by substr(id,1,2)
     ;quit;
');

