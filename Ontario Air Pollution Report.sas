libname air '/home/u61039516/test1 ';
run;

/* load table environment*/
data air.environment;
	infile '/home/u61039516/test1/Environment source data.csv' dlm=','  firstobs=2;
	length Station_Name $50;
  format Station_Name $50. ;
  informat Station_Name $50.;
	input Station_Id Station_Name $ Latitude Longitude Pollutant $ Measure_Date yymmdd10.  Hourofday  month Day_name $ Pollution AQI P $ Pollutants $50.;
	format Measure_Date yymmdd10.;
	p = strip(tranwrd(Pollutant,'"', ''));
	if P='Sulphur' then Pollutants='Sulphur Oxide';
	else if P='Nitroge' then Pollutants='Nitrogen Oxides';
	else if P='Fine Pa' then Pollutants='Fine Particle Matters';
	else Pollutants = P;
	Station = strip(tranwrd(Station_Name,'"', ''));
	drop Station_Name;
	drop Pollutant;
	drop P;
	
run;


/* create table composition*/
proc SQL;
create table air.composition as 
	select Pollutants,
			round(sum1*100/sum(sum1),0.01) as pollution_perc
			
	from(
		select Pollutants,
				SUM(Pollution) as sum1
		from air.environment
		group by Pollutants
		) as sub1
	;
quit;



/* Print Composition to a Report*/
ODS PDF file = "/home/u61039516/test2/Pollution Composition Report.PDF";


ODS layout start;

/* Print Composition Pie Chart*/
ODS region x = 1 in y = 1 in height = 4 in width = 5.4 in;
proc template;
	define statgraph SASStudio.Pie;
		begingraph;
		entrytitle "Ontario Air Pollution Composition in General" / 
			textattrs=(size=14);
		layout region;
		piechart category=Pollutants response=pollution_perc / 
			datalabellocation=outside datalabelattrs=(size=8) 
			fillattrs=(transparency=0.5);
		endlayout;
		endgraph;
	end;
proc sgrender template=SASStudio.Pie data=AIR.COMPOSITION;
run;

/* Print Composition Dataset*/
ODS region x=1 in y=5.5 in height = 4.5 in width = 5.5 in;
proc print data=air.composition;
run;

ODS layout end;
ODS PDF close; 
quit;


/* create table daytime change*/
proc SQL;
create table air.Daytime_change as 
	select  Hourofday,
			Pollutants,
			AVG(Pollution) as Daily_Pollution
		from air.environment
		group by Pollutants, Hourofday
	;
quit;

/* Print Daytime Change to a Report*/
ODS PDF file = "/home/u61039516/test2/Pollution Daytime Change Report.PDF";

proc sort data=AIR.DAYTIME_CHANGE out=_SeriesPlotTaskData;
	by Hourofday;
run;
/* Print Daytime Change Series Chart*/
proc sgplot data=_SeriesPlotTaskData;
	title height=14pt "Pollution Change over a Day";
	series x=Hourofday y=Daily_Pollution / group=Pollutants 
		lineattrs=(thickness=4) transparency=0.5;
	xaxis max=24 grid;
	yaxis grid;
run;

/* Print Daytime Table */
proc print data=air.Daytime_change;
run;
ODS PDF close; 
quit;

/* create table Geographical Pollution Distribution*/
proc SQL;
create table air.GeoPollution as 
	select  Station,
			avg(Latitude) as Latitude,
			avg(Longitude) as Longitude,
			AVG(Pollution) as Geo_Pollution
		from air.environment
		group by Station
	;
quit;


/* Print Geographical Pollution Distribution a Report*/
ODS PDF file = "/home/u61039516/test2/Geographical Pollution Distribution.PDF";

/* Print Geographical Pollution Distribution map*/
ods graphics / reset width=6.4in height=4.8in;

proc sgmap plotdata=AIR.GEOPOLLUTION;
	esrimap url='http://server.arcgisonline.com/arcgis/rest/services/World_Street_Map/MapServer';
	title 'Air Pollution Distribution in Ontario';
	bubble x=Longitude y=Latitude size=Geo_Pollution/ group=Station 
		transparency=0.37 name="bubblePlot";
	keylegend "bubblePlot" / title='Station';
run;

/* Print Geographical Distribution Table*/
proc print data=air.GeoPollution;
run;
ODS PDF close; 
quit;


/* create table Top 10 Pollution Regions*/
proc SQL;
create table air.Region as 
	select  Station,
			
			AVG(Pollution) as Region_Pollution
		from air.environment
		group by Station
		order by Region_Pollution desc
		
	;

quit;
data air.Ten_Region;
	set air.Region(obs=10);
run;

/* Print Ten_Region to a Report*/
ODS PDF file = "/home/u61039516/test2/Ten Polluted Region Report.PDF";


ODS layout start;

/* Print Ten Polluted Region Bar Chart*/
proc sgplot data=AIR.TEN_REGION;
	title height=14pt "Ten Most Polluted Regions";
	hbar Station / response=Region_Pollution fillattrs=(color=CX326cc4 
		transparency=0.5);
	xaxis grid;
run;

ods graphics / reset;
title;

/* Print Ten Polluted Region Dataset*/
ODS region x=1 in y=5.5 in height = 4.5 in width = 5.5 in;
proc print data=air.Ten_Region;
run;

ODS layout end;
ODS PDF close; 
quit;


