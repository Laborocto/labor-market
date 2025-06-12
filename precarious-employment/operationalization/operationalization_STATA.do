//This is the Swedish Register-based Operationalization of Precarious Employment v 2.0



//1//CONTRACTUAL RELATIONSHIP INSECURITY: contractual_insecurity 
//first step: create the var with all the self-employed
tab yrkstalln 
gen contractual = 0 if yrkstalln == 2 | yrkstalln == 1
replace contractual = 1 if contractual == 0 & astsni2002 == 74502 | astsni2007 == 78200 | astsni2007 == 78300
replace contractual = 2 if yrkstalln == 4 | yrkstalln == 5 
//label define contractual 0 "direct employed" 1 "employed by agency" 2 "self-employed" 
label values contractual contractual
tab contractual


//second step: create the var differentiating self-employed (solo, non-solo self-employed)
egen count_employees = count(lopnr), by(lopnr_peorgnr year)
gen contractual_insecurity = 0 if contractual == 0 
replace contractual_insecurity = 1 if contractual == 1
replace contractual_insecurity = 3 if contractual == 2 & count_employees ==1 
replace contractual_insecurity = 4 if contractual == 2 & count_employees >1
/// What if the other employee is also a "selfemployd". Then it is selfemployed with partner not selfemployed with employees. What is the ILO definition here? Should we go for more than 3 employees?

//label define contract_L 0 "direct employed" 1 "employed by agency"  3 "solo-self employed" 4 "non-solo self-employed"
label values contractual_insecurity contract_L
tab contractual_insecurity 

							
//2//CONTRACTUAL TEMPORARINESS: temporariness

gen temporariness = 0 if lopnr_peorgnr == lopnr_peorgnr_1y_ago & lopnr_peorgnr == lopnr_peorgnr_2y_ago
replace temporariness = 1 if temporariness == .
//label define tempo_L 0 "stable" 1 "unstable" 
label values temporariness tempo_L
tab temporariness //results:



//3//MULTIPLE JOBS
//Generate the multiplejobs variable (No= 1-2employers or Yes=3 employers using income from third largest employer more than 0SEK)

mark multijobs if ku3ink  >0

				  
//4//INCOME LEVEL: income_level_cat
//adjusting for average social security income coverage of 80%

generate income = ((forvers-forvink) * 1.25) + (arblos*1.25) + forvink
gen income_cat = 0

foreach year of numlist 1992(5)2017{
	summarize income if year == `year', detail
	scalar sixty = r(p50)*0.6
	scalar eighty = r(p50)*0.8
	scalar htwenty = r(p50)*1.2
	scalar twohund = r(p50)*2.0
	scalar max = r(max)
	egen income_cat_`year'  = cut(income), at(0,`=sixty',`=eighty',`=htwenty',`=twohund',500000000) icodes, if year == `year'
	replace income_cat = income_cat_`year' if year == `year'
}


//5//COLLECTIVE BARGAINING AGREEMENT: cba_cat
//first step:create variable number employees
egen antalsys_cat = cut(count_employees), at(1,2,6,11,51,101,100000) icodes
egen companysize = cut(count_employees), at(1,2,10,50,250,100000) 

// Using data from Per Gustavsson: Vem får avsättningar till tjänstepension? https://inspsf.se/publikationer/rapporter/2018/2018-09-04-vem-far-avsattningar-till-tjanstepension
merge m:1 kon sni_g year antalsys_cat using "cba.dta", keep(match master) nogenerate

//second step:create variable for sector (public/private)
replace p_cba =1 if sektorkod < 20
replace p_cba =1 if sni_g==10 & year<2007
replace p_cba =1 if sni_g==12 & year>2006
gen cba = p_cba*100
egen cba_cat = cut(cba), at(0,70,90,101) icodes


//6// Creating the score

replace income_cat = income_cat-2
replace multijobs = -1 if multijobs ==1
replace contractual_insecurity = -1 if contractual_insecurity ==4
replace contractual_insecurity = -1 if contractual_insecurity ==1
replace contractual_insecurity = -2 if contractual_insecurity ==3
replace temporariness = -2 if temporariness==1
replace cba_cat = cba_cat-2

gen precarious_score = income_cat + multijobs + contractual_insecurity + temporariness + cba_cat
tab precarious_score year, col

gen precarious = 0
replace precarious =1 if precarious_score < -2




