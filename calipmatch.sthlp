{smcl}
{* *! version 1.1.0  26oct2022}{...}
{viewerjumpto "Syntax" "calipmatch##syntax"}{...}
{viewerjumpto "Description" "calipmatch##description"}{...}
{viewerjumpto "Options" "calipmatch##options"}{...}
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
[{opth exactm:atch(varlist)} {bf: nostandardize}]


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
{synopt :{bf:nostandardize}} distance using sum of squares; default is standardized sum of squares {p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:calipmatch} matches case observations to control observations using "calipers",
generating a new variable with a unique value for each group of matched cases and controls. It
performs 1:1 or 1:m matching without replacement.

{pstd}
Matched observations must have values within +/- the caliper
width for every caliper matching variable. Matched observations must also have identical values
for every exact matching variable, if any exact matching variables are specified.

{pstd}
Controls are matched to cases without replacement, using an efficient (greedy) algorithm that approximately maximizes 
the number of successful matches, while minimizing the sum of squared differences in the caliper matching
variables when multiple valid matches exist.

{pstd}
The cases are processed in random order. For each case, {cmd:calipmatch} searches for matching controls. If
any valid matches exist, it selects the matching control which minimizes the standardized sum of squared differences across
caliper matching variables. If {opt maxmatches(#)}>1, then after completing the search for a first matching
control observation for each case, the algorithm will search for a second matching control observation for
each case, etc.


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}{opth gen:erate(newvar)} specifies a new variable to be generated,
indicating groups of matched cases and controls. If {it:M} case observations
were successfully matched to control observations, then this new variable
will take values {1, ..., {it:M}}. Each of the matched case observations will
be assigned a unique value. Each of the matched control observations
will be assigned the same value as the case it is matched to.

{phang}{opth case:var(varname)} specifies the binary variable that indicates whether
each observation is a case (=1) or a control (=0). Observations with a
missing value are excluded from matching.

{phang}{opt max:matches(#)} sets the maximum number of controls to be matched
with each case. Setting {opt maxmatches(1)} performs a 1:1 match where {cmd:calipmatch}
searches for one matching control observation for each case observation. By setting
{opt maxmatches(#)} greater than 1 {cmd:calipmatch} will try to assign
a first valid matching control observation for every case observation, then search
for a second matching control observation, and onward.

{phang}{opth caliperm:atch(varlist)} is a list of one or more numeric variables to
use for caliper matching. Matched observations must have values within +/- the caliper
width for every caliper matching variable listed.

{phang}{opth caliperw:idth(numlist)} is a list of positive numbers to use as caliper
widths. The widths are associated with caliper matching variables using the order they are
listed in: the first number will be used as the width for the first caliper
matching variable, etc.

{dlgtab:Optional}

{phang}{opth exactm:atch(varlist)} is a list of one or more integer-valued variables to use
for exact matching. When specified, matched observations must not only match on the caliper
matching variables, they must also have identical values for every exact matching variable.

{pmore}Exact matching variables must have a {help data_types:data type} of {it:byte},
{it:int} or {it:long}. This enables speedy exact matching, by ensuring that
all values are stored as precise integers.

{phang}{bf:nostandardize} calculates distance between cases and controls using the sum of squared differences.
When specified, matches will be sensitive to the scale of caliper variables. This can be used to weight caliper variables.

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

{pstd}{bf:{browse "https://michaelstepner.com":Michael Stepner}}{p_end}
{pstd}software@michaelstepner.com{p_end}

{pstd}{bf:Allan Garland}{p_end}
{pstd}University of Manitoba Faculty of Medicine{p_end}
{pstd}agarland@hsc.mb.ca{p_end}

