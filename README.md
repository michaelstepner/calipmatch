## Installation

Install **calipmatch** in Stata from the SSC repository: `ssc install calipmatch`

## Stata help file

This documentation was converted automatically from the Stata help file by running `log html calipmatch.sthlp calipmatch.md` in Stata.

The help file looks best when viewed in Stata using `help calipmatch`.

<pre>
<b><u>Title</u></b>
<p>
    <b>calipmatch</b> -- General caliper matching, without replacement
<p>
<a name="syntax"></a><b><u>Syntax</u></b>
<p>
    Create a variable indicating groups of matched cases and controls
<p>
        <b>calipmatch</b> [<i>if</i>] [<i>in</i>]<b>,</b> <b><u>gen</u></b><b>erate(</b><i>newvar</i><b>)</b> <b><u>case</u></b><b>var(</b><i>varname</i><b>)</b> <b><u>max</u></b><b>matches(</b><i>#</i><b>)</b>
               <b><u>caliperm</u></b><b>atch(</b><i>varlist</i><b>)</b> <b><u>caliperw</u></b><b>idth(</b><i>numlist</i><b>)</b> [<b><u>exactm</u></b><b>atch(</b>
               <i>varlist</i><b>)</b>]
<p>
<p>
    <i>options</i>                  Description
    -------------------------------------------------------------------------
    Required
      <b><u>gen</u></b><b>erate(</b><i>newvar</i><b>)</b>       variable to generate indicating groups of
                               matched cases and controls
      <b><u>case</u></b><b>var(</b><i>varname</i><b>)</b>       binary variable with cases=1 and controls=0
      <b><u>max</u></b><b>matches(</b><i>#</i><b>)</b>          maximum number of controls to match with each
                               case
      <b><u>caliperm</u></b><b>atch(</b><i>varlist</i><b>)</b>  list of numeric variables to match on using
                               calipers
      <b><u>caliperw</u></b><b>idth(</b><i>numlist</i><b>)</b>  list of caliper widths to use for caliper
                               matching
<p>
    Optional
      <b><u>exactm</u></b><b>atch(</b><i>varlist</i><b>)</b>    list of integer variables to match on exactly
    -------------------------------------------------------------------------
<p>
<p>
<a name="description"></a><b><u>Description</u></b>
<p>
    <b>calipmatch</b> matches case observations to control observations using
    "calipers", generating a new variable with a unique value for each group
    of matched cases and controls.  It performs 1:1 or 1:m matching without
    replacement.
<p>
    Matched observations must have values within +/- the caliper width for
    every caliper matching variable. Matched observations must also have
    identical values for every exact matching variable, if any exact matching
    variables are specified.
<p>
    Controls are randomly matched to cases without replacement. For each
    case, <b>calipmatch</b> searches for matching controls until it either finds the
    pre-specified maximum number of matches or runs out of controls. The
    search is performed greedily: it is possible that some cases end up
    unmatched because all possible matching controls have already been
    matched with another case.
<p>
<p>
<a name="options"></a><b><u>Options</u></b>
<p>
        +----------+
    ----+ Required +---------------------------------------------------------
<p>
    <b><u>gen</u></b><b>erate(</b><i>newvar</i><b>)</b> specifies a new variable to be generated, indicating
        groups of matched cases and controls. If <i>M</i> case observations were
        successfully matched to control observations, then this new variable
        will take values {1, ..., <i>M</i>}. Each of the matched case observations
        will be assigned a unique value. Each of the matched control
        observations will be assigned the same value as the case it is
        matched to.
<p>
    <b><u>case</u></b><b>var(</b><i>varname</i><b>)</b> specifies the binary variable that indicates whether
        each observation is a case (=1) or a control (=0). Observations with
        a missing value are excluded from matching.
<p>
    <b><u>max</u></b><b>matches(</b><i>#</i><b>)</b> sets the maximum number of controls to be matched with each
        case. Setting <b>maxmatches(</b><i>1</i><b>)</b> performs a 1:1 matching: <b>calipmatch</b>
        searches for one matching control observation for each case
        observation.
<p>
        By setting <b>maxmatches(</b><i>#</i><b>)</b> greater than 1, <b>calipmatch</b> will proceed in
        random order through the cases and search for matching control
        observations until it either finds the maximum number of matches or
        runs out of controls. The search is performed greedily: it is
        possible that some cases end up unmatched because all possible
        matching controls have already been matched with another case.
<p>
    <b><u>caliperm</u></b><b>atch(</b><i>varlist</i><b>)</b> is a list of one or more numeric variables to use
        for caliper matching. Matched observations must have values within
        +/- the caliper width for every caliper matching variable listed.
<p>
    <b><u>caliperw</u></b><b>idth(</b><i>numlist</i><b>)</b> is a list of positive numbers to use as caliper
        widths. The widths are associated with caliper matching variables
        using the order they are listed in: the first number will be used as
        the width for the first caliper matching variable, etc.
<p>
        +----------+
    ----+ Optional +---------------------------------------------------------
<p>
    <b><u>exactm</u></b><b>atch(</b><i>varlist</i><b>)</b> is a list of one or more integer-valued variables to
        use for exact matching. When specified, matched observations must not
        only match on the caliper matching variables, they must also have
        identical values for every exact matching variable.
<p>
        Exact matching variables must have a data type of <i>byte</i>, <i>int</i> or <i>long</i>.
        This enables speedy exact matching, by ensuring that all values are
        stored as precise integers.
<p>
<p>
<a name="saved_results"></a><b><u>Saved results</u></b>
<p>
    <b>calipmatch</b> saves the following in <b>r()</b>:
<p>
    Scalars
      <b>r(cases_total)</b>    number of cases in sample
      <b>r(cases_matched)</b>  number of matched cases in sample
      <b>r(match_rate)</b>     fraction of cases matched to controls
<p>
    Matrices
      <b>r(matches)</b>        tabulation of number of controls matched to each case
<p>
<p>
<a name="author"></a><b><u>Authors</u></b>
<p>
    Michael Stepner
    Massachusetts Institute of Technology
    stepner@mit.edu
<p>
    Allan Garland, M.D. M.A.
    University of Manitoba Faculty of Medicine
    agarland@hsc.mb.ca
<p>
</pre>
