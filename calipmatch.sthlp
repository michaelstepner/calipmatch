{smcl}
{* *! version 0.0.1  27apr2017}{...}
{viewerjumpto "Syntax" "calipmatch##syntax"}{...}
{viewerjumpto "Description" "calipmatch##description"}{...}
{viewerjumpto "Saved results" "calipmatch##saved_results"}{...}
{viewerjumpto "Authors" "calipmatch##author"}{...}
{title:Title}

{p2colset 5 19 21 2}{...}
{p2col :{hi:calipmatch} {hline 2}}General caliper matching, without replacement{p_end}
{p2colreset}{...}

{marker syntax}{title:Syntax}

{phang}
Create a variable indicating groups of matched cases and controls

{p 8 15 2}
{cmd:calipmatch}
{ifin}{cmd:,}
{opth gen:erate(newvar)}
{opth case:var(varname)}
{opt max:matches(#)}
{opth caliperm:atch(varlist)}
{opth caliperw:idth(numlist)}
[{opth exactm:atch(varlist)}]


{synoptset 23 tabbed}{...}
{synopthdr :options}
{synoptline}
{syntab :Required}
{synopt :{opth gen:erate(newvar)}}variable to generate
indicating groups of matched cases and controls{p_end}
{synopt :{opth case:var(varname)}}binary variable with cases=1 and controls=0
{p_end}
{synopt :{opt max:matches(#)}}maximum number of controls to match with each case
{p_end}
{synopt :{opth caliperm:atch(varlist)}}list of numeric variables to match on using
calipers{p_end}
{synopt :{opth caliperw:idth(numlist)}}list of caliper widths to use for caliper
matching{p_end}

{syntab :Optional}
{synopt :{opth exactm:atch(varlist)}}list of integer variables to match on exactly{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:calipmatch} matches case observations to control observations using "calipers",
generating a new variable with a unique value for each group of matched cases and controls.
It performs 1:1 or 1:m matching without replacement.

{pstd}
Matched observations must have values within +/- the caliper
width for every caliper matching variable. Matched observations must also have identical values
for every exact matching variable, if any exact matching variables are specified.

{pstd}
Controls are randomly matched to cases without replacement. For each case, {cmd:calipmatch}
searches for matching controls until it either finds the pre-specified maximum number of
matches or runs out of controls. The search is performed greedily: it is possible that
some cases end up unmatched because all possible matching controls have already been matched with
another case.


{marker saved_results}{...}
{title:Saved results}

{pstd}
{cmd:calipmatch} saves the following in {cmd:r()}:

{synoptset 18 tabbed}{...}
{p2col 5 10 14 2:Scalars}{p_end}
{synopt:{bf:r(cases_total)}}number of cases in sample{p_end}
{synopt:{bf:r(cases_matched)}}number of matched cases in sample{p_end}
{synopt:{bf:r(match_rate)}}fraction of cases matched to controls{p_end}

{p2col 5 10 14 2:Matrices}{p_end}
{synopt:{cmd:r(matches)}}tabulation of number of controls matched to each case{p_end}
{p2colreset}{...}


{marker author}{...}
{title:Authors}

{pstd}Michael Stepner{p_end}
{pstd}Massachusetts Institute of Technology{p_end}
{pstd}stepner@mit.edu{p_end}

{pstd}Allan Garland, M.D. M.A.{p_end}
{pstd}University of Manitoba Faculty of Medicine{p_end}
{pstd}agarland@hsc.mb.ca{p_end}

