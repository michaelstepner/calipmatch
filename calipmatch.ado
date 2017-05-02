*! version 0.0.2  1may2017  Michael Stepner and Allan Garland, stepner@mit.edu
program define calipmatch, sortpreserve rclass
	version 13.0
	syntax [if] [in], GENerate(name) CASEvar(varname) MAXmatches(integer) CALIPERMatch(varlist numeric) CALIPERWidth(numlist >0) [EXACTmatch(varlist)]
		
	* Verify there are same number of caliper vars as caliper widths
	local caliper_var_count : word count `calipermatch'
	local caliper_width_count : word count `caliperwidth'
	if (`caliper_var_count'!=`caliper_width_count') {
		di as error "You must specify the same number of caliper widths as caliper matching variables."
		exit 198
	}
	
	* Verify that all exact matching variables have integer data tyes
	if ("`exactmatch'"!="") {
		foreach var of varlist `exactmatch' {
			cap confirm byte variable `var', exact
			if _rc==0 continue
			cap confirm int variable `var', exact
			if _rc==0 continue
			cap confirm long variable `var', exact
			if _rc==0 continue
			
			di as error "Exact matching variables must have data type {it:byte}, {it:int}, or {it:long}."
			
			cap confirm numeric variable `var', exact
			if _rc==0 di as error "Use the {bf:recast} command or caliper matching for variable: `var'."
			else di as error "Use the {bf:destring} command or another method to change the datatype to a numeric integer for variable: `var'."
			
			exit 198
		}
	}
	
	* Verify that we can create the new variable specified
	confirm new variable `generate', exact
	
	* Mark the sample with necessary vars non-missing
	marksample touse
	markout `touse' `casevar' `calipermatch' `exactmatch'
	
	* Verify that case/control var is always 0 or 1 in sample
	cap assert `casevar'==0 | `casevar'==1 if `touse'==1
	if _rc==9 {
		di as error "The casevar() must always be 0 or 1 in the sample."
		exit 198
	}
	else if _rc!=0 {
		error _rc
	}
	
	* Sort into groups for caliper matching, randomizing order of cases and controls
	tempvar rand
	gen double `rand'=runiform()
	sort `touse' `exactmatch' `casevar' `rand'
	
	* Find group boundaries
	qui count if `touse'==1
	mata: boundaries=find_group_boundaries("`exactmatch'", "`casevar'", `=_N-r(N)+1', `=_N')
	
	* Perform matching within each group
	qui gen long `generate'=.
	
	return clear
	mata: _calipmatch(boundaries,"`generate'",`maxmatches',"`calipermatch'","`caliperwidth'")
	qui compress `generate'
	
	* Print report on match rate
	tempname case_matches cases_total
	matrix `case_matches'=r(case_matches)
	matrix `cases_total'=`case_matches''* J(rowsof(`case_matches'),1,1)
	local cases_total = `cases_total'[1,1]
	local cases_matched = `cases_total'-`case_matches'[1,1]
	local match_rate_print = string(`cases_matched'/`cases_total'*100,"%9.1f")

	di `"`match_rate_print'% match rate."'
	di `"`=string(`cases_matched',"%16.0fc")' out of `=string(`cases_total',"%16.0fc")' cases matched."'
	di ""
	di "Successful matches for each case"
	di "--------------------------------"
	forvalues m=0/`maxmatches' {
		local count=`case_matches'[`m'+1,1]
		local percent=string(`count'/`cases_total'*100,"%9.1f")
		local rownames `rownames' `m'
		
		di "`m' matched control obs: `count' (`percent'%)"
	}
	
	* Return match success rate
	matrix rownames `case_matches' = `rownames'
	matrix colnames `case_matches' = "count"
	
	return clear
	return scalar match_rate = `cases_matched'/`cases_total'
	return scalar cases_matched = `cases_matched'
	return scalar cases_total = `cases_total'
	return matrix matches = `case_matches'

end


version 13.0
set matastrict on

mata:

void _calipmatch(real matrix boundaries, string scalar genvar, real scalar maxmatch, string scalar calipvars, string scalar calipwidth) {

	real scalar matchgrp
	matchgrp = st_varindex(genvar)
	
	real rowvector matchvars
	matchvars = st_varindex(tokens(calipvars))

	real rowvector tolerance
	tolerance = strtoreal(tokens(calipwidth))
	
	real scalar curmatch
	curmatch = 0
	
	real colvector matchsuccess
	matchsuccess = J(maxmatch+1, 1, 0)
	
	real scalar brow
	real scalar caseobs
	real scalar controlobs
	real scalar casematchcount
	real rowvector matchvals
	real rowvector controlvals
	real matrix matchbounds
	
	for (brow=1; brow<=rows(boundaries); brow++) {
	
		for (caseobs=boundaries[brow,3]; caseobs<=boundaries[brow,4]; caseobs++) {
		
			curmatch++
			casematchcount=0
			_st_store(caseobs, matchgrp, curmatch)
			
			matchvals = st_data(caseobs, matchvars)
			matchbounds = (matchvals-tolerance)\(matchvals+tolerance)
			
			for (controlobs=boundaries[brow,1]; controlobs<=boundaries[brow,2]; controlobs++) {
			
				if (_st_data(controlobs, matchgrp)!=.) continue
				
				controlvals = st_data(controlobs, matchvars)
				
				if (controlvals>=matchbounds[1,.] & controlvals<=matchbounds[2,.]) {
					casematchcount++
					_st_store(controlobs, matchgrp, curmatch)
				}
				
				if (casematchcount==maxmatch) break
			
			}
			
			matchsuccess[casematchcount+1,1] = matchsuccess[casematchcount+1,1]+1
			
			if (casematchcount==0) {
				curmatch--
				_st_store(caseobs, matchgrp, .)
			}
		
		}
	
	}
	
	st_matrix("r(case_matches)",matchsuccess)

}

real matrix find_group_boundaries(string scalar byvars, string scalar casevar, real scalar startobs, real scalar endobs) {

	real matrix boundaries
	boundaries = (startobs, ., ., .)
	
	real scalar nextcol
	nextcol=2
	
	real scalar currow
	currow=1
	
	real rowvector groupvars
	groupvars = st_varindex(tokens(byvars))
	
	real scalar casevarnum
	casevarnum = st_varindex(casevar)
	
	real scalar obs
	for (obs=startobs+1; obs<=endobs; obs++) {
		if (st_data(obs, groupvars)!=st_data(obs-1, groupvars)) {
			if (nextcol==2) {
				boundaries[currow,1]=obs
			}
			else if (nextcol==4) {
				boundaries[currow,4]=obs-1
				boundaries=boundaries\(obs, ., ., .)
				nextcol=2
				currow=currow+1
			}
		}
		else if (_st_data(obs, casevarnum)!=_st_data(obs-1, casevarnum)) {
			// XX mark error if nextcol!=2?
			boundaries[currow,2]=obs-1
			boundaries[currow,3]=obs
			nextcol=4
		}
	}
	
	if (nextcol==4) {
		boundaries[currow,nextcol]=endobs
		return (boundaries)
	}
	else return (boundaries[1..rows(boundaries)-1, .])

}

end
