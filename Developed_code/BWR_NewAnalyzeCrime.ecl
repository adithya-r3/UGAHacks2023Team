IMPORT $,STD;
Crime    := $.File_Crimes.File;
CrimeRec := $.File_Crimes.Layout;

// bestrecord := STD.DataPatterns.BestRecordStructure(Crime);
// OUTPUT(bestrecord,ALL);

// Use this code to profile the Crime dataset:
// profileResults := STD.DataPatterns.Profile(Crime):PERSIST('~UGA::Persist::CrimeProfile');
// OUTPUT(profileResults, ALL, NAMED('profileResults'));


// Cross-Tab by State, Average of all years 1979-2020, ROUND to nearest INTEGER
CTRec := RECORD
  Crime.state_abbr;
  PopAvg          := ROUND(AVE(GROUP,Crime.population));
  ViolentCrimeAvg := ROUND(AVE(GROUP,Crime.violent_crime));
  HomicideAvg     := ROUND(AVE(GROUP,Crime.homicide));
  RapeAvg         := ROUND(AVE(GROUP,Crime.rape_legacy));
  RobberyAvg      := ROUND(AVE(GROUP,Crime.Robbery));
  agg_assaultAvg  := ROUND(AVE(GROUP,Crime.aggravated_assault));
  prop_crimeAvg   := ROUND(AVE(GROUP,Crime.property_crime));
  burglaryAvg     := ROUND(AVE(GROUP,Crime.burglary));
  larcenyAvg      := ROUND(AVE(GROUP,Crime.larceny));
  veh_theftAvg    := ROUND(AVE(GROUP,Crime.motor_vehicle_theft));
END;

AveCrimeTBL := TABLE(Crime(state_abbr <> ''),CtRec,State_abbr);
OUTPUT(SORT(AveCrimeTBL,state_abbr),NAMED('AVE_AllYears'));


//Generate ratios for Paradise Service

RatioRec := RECORD
 STRING2 State;
 DECIMAL5_4   ViolentCrimeRatio;
 DECIMAL5_4   HomicideRat;
 DECIMAL5_4   RapeRat;
 DECIMAL5_4   Agg_AssaultRat;       
 DECIMAL5_4   ViolentCompRat; //Average of Homicide and Rape
 DECIMAL5_4   RobberyRat;    
 DECIMAL5_4   Prop_CrimeRat; 
 DECIMAL5_4   BurglaryRat;   
 DECIMAL5_4   LarcenyRat;    
 DECIMAL5_4   Veh_TheftRat;  
 DECIMAL5_4   PropCompRat;    //Average of all Property Crimes
END;

RatioRec CalcRatios(AveCrimeTBL Le) := TRANSFORM
 SELF.State             := Le.State_Abbr;
 SELF.ViolentCrimeRatio := (Le.ViolentCrimeAvg/Le.PopAvg)*100;
 SELF.HomicideRat       := (Le.HomicideAvg/Le.PopAvg)*100;
 SELF.RapeRat           := (Le.RapeAvg/Le.PopAvg)*100;
 SELF.Agg_AssaultRat    := (Le.Agg_AssaultAvg/Le.PopAvg*100);
 SELF.ViolentCompRat    := (((Le.ViolentCrimeAvg+Le.HomicideAvg+Le.RapeAvg+Le.Agg_AssaultAvg)/4)/Le.PopAvg)*100;
 SELF.RobberyRat        := (Le.RobberyAvg/Le.PopAvg)*100;
 SELF.Prop_CrimeRat     := (Le.Prop_CrimeAvg/Le.PopAvg)*100;
 SELF.BurglaryRat       := (Le.BurglaryAvg/Le.PopAvg)*100;
 SELF.LarcenyRat        := (Le.LarcenyAvg/Le.PopAvg)*100;
 SELF.Veh_TheftRat      := (Le.Veh_TheftAvg/Le.PopAvg)*100;
 SELF.PropCompRat       := (((Le.RobberyAvg+Le.Prop_CrimeAvg+Le.BurglaryAvg+Le.LarcenyAvg+Le.Veh_TheftAvg)/5)/Le.PopAvg)*100;
END;

BuildRatios := PROJECT(AveCrimeTBL,CalcRatios(LEFT));
// OUTPUT(PROJECT(AveCrimeTBL,CalcRatios(LEFT)));
OUTPUT(BuildRatios,,'~UGA::Main::Hacks::CrimeRates',NAMED('CrimeRatiosByPopulation'),OVERWRITE);

scoreRec := RECORD
  AveCrimeTBL.state_abbr;
  Score := (((((AveCrimeTBL.ViolentCrimeAvg+AveCrimeTBL.HomicideAvg+AveCrimeTBL.RapeAvg+AveCrimeTBL.Agg_AssaultAvg)/4)/AveCrimeTBL.PopAvg)*100)*0.6)+(((((AveCrimeTBL.RobberyAvg+AveCrimeTBL.Prop_CrimeAvg+AveCrimeTBL.BurglaryAvg+AveCrimeTBL.LarcenyAvg+AveCrimeTBL.Veh_TheftAvg)/5)/AveCrimeTBL.PopAvg)*100)*0.4);
END;

  scoreTbl := TABLE(AveCrimeTBL,scoreRec,state_abbr);
  
scoreRec1 := RECORD
  scoreTbl.state_abbr;
  DECIMAL4 Score := 100 - ((scoreTbl.Score - Min(scoreTbl,Score))*100)/(MAX(scoreTbl,Score) - MIN(scoreTbl,Score));
End;

  scoreTbl1 := TABLE(scoreTbl,ScoreRec1,state_abbr);
  
  OUTPUT(scoreTbl,ScoreRec1,NAMED('Scores'));
  
  