*! version 1.1.0  26oct2022  Michael Stepner and Allan Garland, software@michaelstepner.com

/* CC0 license information:
To the extent possible under law, the author has dedicated all copyright and related and neighboring rights
to this software to the public domain worldwide. This software is distributed without any warranty.

This code is licensed under the CC0 1.0 Universal license.  The full legal text as well as a
human-readable summary can be accessed at http://creativecommons.org/publicdomain/zero/1.0/
*/

* Why did I include a formal license? Jeff Atwood gives good reasons: https://blog.codinghorror.com/pick-a-license-any-license/

program define calipmatch, sortpreserve rclass
	version 13.0
	syntax [if] [in], GENerate(name) CASEvar(varname numeric) MAXmatches(numlist integer >0 max=1) CALIPERMatch(varlist numeric) CALIPERWidth(numlist >0) [EXACTmatch(varlist)] [brief]
		
	* Verify there are same number of caliper vars as caliper widths
	if (`: word count `calipermatch'' != `: word count `caliperwidth'') {
		di as error "must specify the same number of caliper widths as caliper matching variables."
		if (`: word count `calipermatch'' < `: word count `caliperwidth'') exit 123
		else exit 122
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
			if _rc==0 di as error "Use the {help recast} command or caliper matching for variable: `var'."
			else di as error "Use the {help destring} command or another method to change the datatype for variable: `var'."
			
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
		di as error "casevar() must always be 0 or 1 in the sample."
		exit 198
	}
	error _rc
	
	* Sort into groups for caliper matching, randomizing order of cases and controls
	tempvar rand
	gen float `rand'=runiform()
	sort `touse' `exactmatch' `casevar' `rand'
	
	* Count the number of total obs and cases in sample
	qui count if `touse'==1
	local insample_total = r(N)
	if (`insample_total'==0) {
		di as error "no observations in sample"
		exit 2000
	}
	
	qui count if `casevar'==1 in `=_N-`insample_total'+1'/`=_N'
	local cases_total = r(N)
	if (`insample_total'==`cases_total') {
		di as error "no control observations in sample"
		exit 2001
	}
	if (`cases_total'==0) {
		di as error "no case observations in sample"
		exit 2001
	}
	
	* Find group boundaries within exact-match groups
	mata: boundaries=find_group_boundaries("`exactmatch'", "`casevar'", `=_N-`insample_total'+1', `=_N')
	
	* Perform caliper matching within each exact-match group
	qui gen long `generate' = .
	tempname case_matches
	
	if r(no_matches)==0 {

		if ("`brief'"=="") {
			foreach var of varlist `calipermatch' {
				tempvar std_`var'
				qui egen `std_`var'' = std(`var') if `touse' == 1
				local std_calipermatch `std_calipermatch' `std_`var''
			}
			mata: _calipmatch(boundaries,"`generate'",`maxmatches',"`calipermatch'","`caliperwidth'", "`std_calipermatch'")	
		}	
		else {
			mata: _calipmatch(boundaries,"`generate'",`maxmatches',"`calipermatch'","`caliperwidth'")			
		}

		qui compress `generate'
		matrix `case_matches' = r(matchsuccess)
		matrix `case_matches' = (`cases_total' - `case_matches''* J(rowsof(`case_matches'),1,1)) \ `case_matches'
	}
	else {
		matrix `case_matches'=`cases_total' \ J(`maxmatches', 1, 0)
	}
	
	* Print report on match rate
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

void _calipmatch(real matrix boundaries, string scalar genvar, real scalar maxmatch, string scalar calipvars, string scalar calipwidth,
| string scalar std_calipvars) {
	// Objective:
	//		Perform caliper matching using the specified caliper variables and caliper widths, matching each case observation to one or
	//		many controls. Identify the matches within pre-specified groups, and store a variable containing integers that define a group
	//		of matched cases and controls.
	//
	// Inputs:
	//		Dataset with the same sort order as it had when `find_group_boundaries`' was run.
	//		- boundaries: G x 4 matrix output by find_group_boundaries()
	//		- genvar: variable containing all missing values, which will be populated with matching groups
	//		- maxmatch: a positive integer indicating the maximum number of control obs to match to each case obs
	//		- calipvars: a list of numeric variables for caliper matching
	//		- calipwidth: a list of caliper widths, specifying the maximum distance between case and control variables in each calipvar
	//
	//	Outputs:
	//		The values of "genvar" are filled with integers that describe each group of matched cases and controls.
	//		- r(matchsuccess) is a Stata return matrix tabulating the number of cases successfully matched to {1, ..., maxmatch} controls

	real scalar matchgrp
	matchgrp = st_varindex(genvar)
	
	real rowvector matchvars
	matchvars = st_varindex(tokens(calipvars))

	real rowvector tolerance
	tolerance = strtoreal(tokens(calipwidth))
	
	real scalar curmatch
	curmatch = 0

	real scalar highestmatch
	highestmatch = 0
	
	real colvector matchsuccess
	matchsuccess = J(maxmatch, 1, 0)
	
	real scalar brow
	real rowvector casematchcount
	real scalar caseindex
	real colvector matchedcontrolindex
	real matrix minties
	real scalar caseobs
	real scalar controlobs
	real scalar matchattempt
	real rowvector matchvals
	real matrix controlvals
	real matrix diffvals

	if (args() > 5) {
		real rowvector std_matchvars
		std_matchvars = st_varindex(tokens(std_calipvars))
		
		real rowvector std_matchvals
		real matrix std_controlvals
		real matrix std_diffvals
	}
	
	for (brow=1; brow<=rows(boundaries); brow++) {
	
		casematchcount = J(boundaries[brow,4] - boundaries[brow,3] + 1, 1, 0)
	
		for (matchattempt=1; matchattempt<=maxmatch; matchattempt++) {
	
			for (caseobs=boundaries[brow,3]; caseobs<=boundaries[brow,4]; caseobs++) {
			
				caseindex = caseobs - boundaries[brow,3] + 1
			
				// Set the value of the match group
				if (matchattempt==1) {
					highestmatch++
					curmatch = highestmatch
					_st_store(caseobs, matchgrp, curmatch)
				}
				else {
					if (casematchcount[caseindex,1] < matchattempt - 1) continue
					curmatch = _st_data(caseobs, matchgrp)
				}
				
				// Store matchvar values for the case and for the controls that have not yet been matched, and calculate difference
				matchvals = st_data(caseobs, matchvars)
				controlvals = st_data((boundaries[brow,1], boundaries[brow,2]), matchvars) :* editvalue(st_data((boundaries[brow,1], boundaries[brow,2]), matchgrp):==., 0, .)
				diffvals = (controlvals :- matchvals)

				// Find closest control to match
				if (args() >5) {
					std_matchvals = st_data(caseobs, std_matchvars)
					std_controlvals = st_data((boundaries[brow,1], boundaries[brow,2]), std_matchvars) :* editvalue(st_data((boundaries[brow,1], boundaries[brow,2]), matchgrp):==., 0, .)
					std_diffvals = (std_controlvals :- std_matchvals) :* editvalue(abs(diffvals) :<= tolerance, 0, .)
					minindex(rowsum(std_diffvals :^2, 1), 1, matchedcontrolindex, minties)
				}
				else {
					diffvals = diffvals :* editvalue(abs(diffvals) :<= tolerance, 0, .)
					minindex(rowsum(diffvals :^2, 1), 1, matchedcontrolindex, minties)
				}
				
				// If a match is found, store it
				if (rows(matchedcontrolindex)>0) {
					casematchcount[caseindex,1] = casematchcount[caseindex,1] + 1
					_st_store(boundaries[brow,1] + matchedcontrolindex[1,1] - 1, matchgrp, curmatch)
				}
				
				// If zero matches were found for a case, remove its matchgrp value and reuse it for the next case
				if (matchattempt==1 & casematchcount[caseindex,1]==0) {
					highestmatch--
					_st_store(caseobs, matchgrp, .)
				}
			
			}
		}
		
		for (caseindex=1; caseindex <= boundaries[brow,4] - boundaries[brow,3] + 1; caseindex++) {
			matchattempt = casematchcount[caseindex,1]
			if (matchattempt > 0) {
				matchsuccess[matchattempt,1] = matchsuccess[matchattempt,1] + 1
			}
		}
	
	}
	
	stata("return clear")
	st_matrix("r(matchsuccess)",matchsuccess)

}

real matrix find_group_boundaries(string scalar grpvars, string scalar casevar, real scalar startobs, real scalar endobs) {
	// Objective:
	//		For each set of distinct values of "grpvars", identify the starting and ending observation for cases and controls.
	//
	// Inputs:
	//		Dataset sorted by the variables specified by "grpvars casevar" within the rows [startobs, endobs]
	//
	//		- grpvars: one or more variables for which each distinct set of values constitutes a group
	//		- casevar: a variable which takes values {0,1}
	//		- startobs: the first observation to process
	//		- endobs: the last observation to process
	//
	//	Outputs:
	//		Return a matrix with dimensions G x 4, where G is the number of distinct groups containing both cases and controls.
	//		Col 1 = the first obs in a group with casevar==0
	//		Col 2 = the last obs in a group with casevar==0
	//		Col 3 = the first obs in a group with casevar==1
	//		Col 4 = the last obs in a group with casevar==1


	real matrix boundaries
	boundaries = (startobs, ., ., .)
	
	real scalar nextcol
	nextcol=2
	
	real scalar currow
	currow=1
	
	real rowvector groupvars
	groupvars = st_varindex(tokens(grpvars))
	
	real scalar casevarnum
	casevarnum = st_varindex(casevar)
	
	real scalar obs
	for (obs=startobs+1; obs<=endobs; obs++) {
		if (st_data(obs, groupvars)!=st_data(obs-1, groupvars)) {
			if (nextcol==4) {
				boundaries[currow,4]=obs-1
				boundaries=boundaries\(obs, ., ., .)
				nextcol=2
				currow=currow+1
			}
			else {  // only one value of casevar (all controls or all cases) in prev group --> skip group
				boundaries[currow,1]=obs
			}
		}
		else if (_st_data(obs, casevarnum)!=_st_data(obs-1, casevarnum)) {
			boundaries[currow,2]=obs-1
			boundaries[currow,3]=obs
			nextcol=4
		}
	}
	
	stata("return clear")
	st_numscalar("r(no_matches)",0)
	if (nextcol==4) {
		boundaries[currow,nextcol]=endobs
		return (boundaries)
	}
	else {
		if (currow>1) return (boundaries[1..rows(boundaries)-1, .])
		else st_numscalar("r(no_matches)",1)
	}

}

end
