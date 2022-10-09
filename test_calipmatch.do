cscript "calipmatch" adofile calipmatch

program define test_calipmatch

	syntax [if] [in], GENerate(name) CASEvar(varname) MAXmatches(integer) CALIPERMatch(varlist numeric) CALIPERWidth(numlist >0) [EXACTmatch(varlist)]
	
	calipmatch `if' `in', generate(`generate') casevar(`casevar') maxmatches(`maxmatches') calipermatch(`calipermatch') ///
						  caliperwidth(`caliperwidth') exactmatch(`exactmatch')
						  
	if (_rc==0) {
	
		* Store returned objects
		local cases_total=r(cases_total)
		local cases_matched=r(cases_matched)
		local match_rate=r(match_rate)
		matrix matches=r(matches)
	
		* Exactly one case per matchgroup
		egen casecount=sum(`casevar'), by(`generate')
		qui assert casecount==1 if !mi(`generate')
		
		* Highest matchgroup value = number of matched cases
		sum `generate', meanonly
		if (r(N)>0) assert r(max)==`cases_matched'
		else assert `cases_matched'==0
	
		* All matched obs are within caliper width
		local c=0
		foreach var of varlist `calipermatch' {
		
			local ++c
			local width : word `c' of `caliperwidth'

			qui gen caseval=`var' if `casevar'==1 & !mi(`generate')
			qui egen matchval=mean(caseval), by(`generate')
			
			qui gen valdiff=`var'-matchval
			sum valdiff, meanonly
			if r(N)>0 {
				assert r(min)>=-`width'
				assert r(max)<=`width'
			}
			
			drop caseval matchval valdiff

		}
		
		* All matched obs have same value for exact matching vars
		if ("`exactmatch'"!="") {
			foreach var of varlist `exactmatch' {
			
				qui gen caseval=`var' if `casevar'==1 & !mi(`generate')
				qui egen matchval=mean(caseval), by(`generate')
				
				qui gen valdiff=`var'-matchval
				sum valdiff, meanonly
				if r(N)>0 {
					assert r(min)==0
					assert r(max)==0
				}
				
				drop caseval matchval valdiff
				
			}
		}
		
		* Total cases correctly reported
		sum `casevar' `if' `in', meanonly
		assert r(sum)==`cases_total'
		
		* Matched cases correctly reported
		qui gen matched_case = `casevar' if !mi(`generate')
		sum matched_case `if' `in', meanonly
		assert r(sum)==`cases_matched'
		
		* Tabulation of number of controls matched to each case reported correctly
		qui gen control=1-`casevar'
		qui egen matched_controls=sum(control), by(`generate')
		qui replace matched_controls=0 if mi(`generate')
		qui replace matched_controls=. if `casevar'!=1
		
		forvalues m=0/`maxmatches' {
			 qui count if matched_controls==`m'
			 assert r(N)==matches[`=`m'+1',1]
		}
				
	}
	
end


*** One caliper matching variable
clear
set seed 4585239

set obs 200
gen byte case=(_n<=20)
gen byte income_percentile=ceil(runiform() * 100)

* Valid test
test_calipmatch, gen(matchgroup) case(case) maxmatches(1) ///
	calipermatch(income_percentile) caliperwidth(5)
keep case income_percentile

* if statement that matches no observations
rcof `"test_calipmatch if income_percentile>100, gen(matchgroup) case(case) maxmatches(1) calipermatch(income_percentile) caliperwidth(5)"' ///
	== 2000

***NEW TEST * maximum matches is positive, but not an integer	
rcof `"test_calipmatch, gen(matchgroup) case(case) maxmatches(.3) calipermatch(income_percentile) caliperwidth(5)"' ///
	== 198

***NEW TEST * caliper variable is ambiguous
gen byte income_percentile2=ceil(rnormal() * 100)
rcof `"test_calipmatch, gen(matchgroup) case(case) maxmatches(1) calipermatch(income_perc) caliperwidth(5)"' ///
	== 111
drop income_percentile2

***NEW TEST * caliper variable is does not exist
rcof `"test_calipmatch, gen(matchgroup) case(case) maxmatches(1) calipermatch(nonsense) caliperwidth(5)"' ///
	== 111

***NEW TEST * caliper width is negative
rcof `"test_calipmatch, gen(matchgroup) case(case) maxmatches(1) calipermatch(income_percentile) caliperwidth(-5)"' ///
	== 125

* no controls
replace case=1
rcof `"test_calipmatch, gen(matchgroup) case(case) maxmatches(1) calipermatch(income_percentile) caliperwidth(5)"' ///
	== 2001
	
* no cases
replace case=0
rcof `"test_calipmatch, gen(matchgroup) case(case) maxmatches(1) calipermatch(income_percentile) caliperwidth(5)"' ///
	== 2001
	
* generate a variable that already exists
gen matchgroup=.
rcof `"test_calipmatch, gen(matchgroup) case(case) maxmatches(1) calipermatch(income_percentile) caliperwidth(5)"' ///
	== 110
drop matchgroup

* case/control variable not always 0 or 1 in sample
replace case=(_n<=20)
replace case=2 in 1
rcof `"test_calipmatch, gen(matchgroup) case(case) maxmatches(1) calipermatch(income_percentile) caliperwidth(5)"' ///
	== 198

* case/control variable not always 0 or 1, but not in sample
test_calipmatch in 2/200, gen(matchgroup) case(case) maxmatches(1) calipermatch(income_percentile) caliperwidth(5)
keep case income_percentile

*** One caliper matching variable and one exact matching variable

gen byte sex=round(runiform())
replace case=(_n<=20)

* Valid test
test_calipmatch, gen(matchgroup) case(case) maxmatches(1) ///
	calipermatch(income_percentile) caliperwidth(5) exactmatch(sex)
keep case income_percentile sex

* no controls among one matching group
replace case=1 if sex==1
test_calipmatch, gen(matchgroup) case(case) maxmatches(1) ///
	calipermatch(income_percentile) caliperwidth(5) exactmatch(sex)
keep case income_percentile sex
	
* no cases among one matching group
replace case=0 if sex==1
test_calipmatch, gen(matchgroup) case(case) maxmatches(1) ///
	calipermatch(income_percentile) caliperwidth(5) exactmatch(sex)
keep case income_percentile sex
	
* no matching groups with both cases and controls
replace case=1 if sex==0
test_calipmatch, gen(matchgroup) case(case) maxmatches(1) ///
	calipermatch(income_percentile) caliperwidth(5) exactmatch(sex)
assert matchgroup==.
keep case income_percentile sex

* string case variable
drop case
gen case=cond(_n<=20,"case","ctrl")
rcof `"test_calipmatch, gen(matchgroup) case(case) maxmatches(1) calipermatch(income_percentile) caliperwidth(5) exactmatch(sex)"' ///
	== 109
	
drop case
gen byte case=(_n<=20)

* float exact matching variable
recast float sex
rcof `"test_calipmatch, gen(matchgroup) case(case) maxmatches(1) calipermatch(income_percentile) caliperwidth(5) exactmatch(sex)"' ///
	== 198
	
* string exact matching variable
rename sex sex_numeric
gen sex=cond(sex_numeric==0,"M","F")
rcof `"test_calipmatch, gen(matchgroup) case(case) maxmatches(1) calipermatch(income_percentile) caliperwidth(5) exactmatch(sex)"' ///
	== 198

drop sex
rename sex_numeric sex
recast byte sex

*** Many caliper and exact matching variables, m:1 match

clear
set obs 50000

gen byte case=(_n<=5000)
gen byte sex=round(runiform())
gen byte age = 44 + ceil(runiform()*17)
gen byte self_emp = (runiform()<0.1)
gen byte prov = ceil(runiform()*9)
gen byte income_percentile=ceil(runiform() * 100)

* Valid test
test_calipmatch, gen(matchgroup) case(case) maxmatches(5) ///
	exactmatch(sex self_emp prov) calipermatch(age income_percentile) caliperwidth(3 5)
keep case sex age self_emp prov income_percentile

* Not enough caliper widths
rcof `"test_calipmatch, gen(matchgroup) case(case) maxmatches(5) exactmatch(sex self_emp prov) calipermatch(age income_percentile) caliperwidth(3)"' ///
	== 122

* Too many caliper widths
rcof `"test_calipmatch, gen(matchgroup) case(case) maxmatches(5) exactmatch(sex self_emp prov) calipermatch(age income_percentile) caliperwidth(3 5 5)"' ///
	== 123

