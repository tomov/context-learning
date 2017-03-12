All regressors apply to the training trials only (except for Model 2 which is discarded)

Model 1 -- main effect @ feedback:

    Regressor #1: context role (irrelevant, additive, or modulatory) @ feedback (outcome) time
    Regressor #2: constant @ trial onset (to account for visual activation)

    Contrasts:
        ccnl_view(contextExpt(), 1, 'modulatory - irrelevant');
        ccnl_view(contextExpt(), 1, 'modulatory - additive');
        ccnl_view(contextExpt(), 1, 'additive - irrelevant');

    Hypothesis: hippocampus would show greater activiation in the modulatory vs. the irrelevant or additive conditions

    Result: 

Model 28 -- main effect @ trial onset:

    Regressor #1: context role (irrelevant, additive, or modulatory) @ trial onset time
    Regressor #2: constant @ trial onset (to account for visual activation)

    Contrasts:
        ccnl_view(contextExpt(), 1, 'modulatory - irrelevant');
        ccnl_view(contextExpt(), 1, 'modulatory - additive');
        ccnl_view(contextExpt(), 1, 'additive - irrelevant');

    Hypothesis: hippocampus would show greater activiation in the modulatory vs. the irrelevant or additive conditions

    Result: 

Model 29 -- main effect @ trial onset, no visual regressor:

    Regressor #1: context role (irrelevant, additive, or modulatory) @ trial onset time

    Contrasts:
        ccnl_view(contextExpt(), 1, 'modulatory - irrelevant');
        ccnl_view(contextExpt(), 1, 'modulatory - additive');
        ccnl_view(contextExpt(), 1, 'additive - irrelevant');

    Hypothesis: hippocampus would show greater activiation in the modulatory vs. the irrelevant or additive conditions

    Result: 

Model 27 -- M2 posterior:

    Regressor #1: Pmod = posterior for modulatory (M2) context role @ feedback (outcome) time
    Regressor #2: constant @ trial onset (to account for visual activation)

    Contrasts:
        ccnl_view(contextExpt(), 27, 'M2_posterior'); 

    Hypothesis: the hippocampus tracks the modulatory role of context => it should light up

    Result:

Model 8 -- M3 posterior:

    Regressor #1: Pmod = posterior for additive (M3) context role @ feedback (outcome) time
    Regressor #2: constant @ trial onset (to account for visual activation)

    Contrasts:
        ccnl_view(contextExpt(), 8, 'M3_posterior'); 

    Hypothesis: 

    Result:

Model 9 -- M1 posterior:

    Regressor #1: Pmod = posterior for irrelevant (M1) context role @ feedback (outcome) time
    Regressor #2: constant @ trial onset (to account for visual activation)

    Contrasts:
        ccnl_view(contextExpt(), 9, 'M1_posterior'); 

    Hypothesis: 

    Result:

Model 10 -- posterior entropy:

    Regressor #1: Pmod = entropy of the posterior over context roles @ feedback (outcome) time
    Regressor #2: constant @ trial onset (to account for visual activation)

    Contrasts:
        ccnl_view(contextExpt(), 10, 'posterior_entropy'); 

    Hypothesis: 

    Result:

Model 14 -- posterior std:

    Regressor #1: Pmod = standard deviation of the posterior over context roles @ feedback (outcome) time
    Regressor #2: constant @ trial onset (to account for visual activation)

    Contrasts:
        ccnl_view(contextExpt(), 14, 'posterior_std'); 

    Hypothesis: 

    Result:

Model 18 -- M1 & M2 posteriors, not orthogonalized

    Regressor #1: Pmod 1) = posterior for modulatory (M2) context role @ feedback (outcome) time
                  Pmod 2) = posterior for irrelevant (M1) context role @ feedback (outcome) time
                  they are NOT orthogonalized
    Regressor #2: constant @ trial onset (to account for visual activation)

    Contrasts:
        ccnl_view(contextExpt(), 18, 'M2_posterior'); 
        ccnl_view(contextExpt(), 18, 'M1_posterior'); 

    Hypothesis: 

    Result:

Model 19 -- M1 & M3 posteriors, not orthogonalized

    Regressor #1: Pmod 1) = posterior for additive (M3) context role @ feedback (outcome) time
                  Pmod 2) = posterior for irrelevant (M1) context role @ feedback (outcome) time
                  they are NOT orthogonalized
    Regressor #2: constant @ trial onset (to account for visual activation)

    Contrasts:
        ccnl_view(contextExpt(), 19, 'M3_posterior'); 
        ccnl_view(contextExpt(), 19, 'M1_posterior'); 

    Hypothesis: 

    Result:

Model 20 -- M2 & M3 posteriors, not orthogonalized

    Regressor #1: Pmod 1) = posterior for additive (M3) context role @ feedback (outcome) time
                  Pmod 2) = posterior for modulatory (M2) context role @ feedback (outcome) time
                  they are NOT orthogonalized
    Regressor #2: constant @ trial onset (to account for visual activation)

    Contrasts:
        ccnl_view(contextExpt(), 20, 'M3_posterior'); 
        ccnl_view(contextExpt(), 20, 'M2_posterior'); 

    Hypothesis: 

    Result:

Model 25 -- prediction & outcome

    Regressor #1: Pmod = expected outcome @ reaction time
    Regressor #2: Pmod = outcome (1 = sick, 0 = not sick) @ feedback (outcome) time
    Regressor #3: constant @ trial onset (to account for visual activation)

    Contrasts:
        ccnl_view(contextExpt(), 20, 'expected'); 
        ccnl_view(contextExpt(), 20, 'actual'); 

    Hypothesis: 

    Result:

Model 26 -- prediction error

    Regressor #1: Pmod = prediction error = outcome - expected outcome @ feedback (outcome) time 
    Regressor #2: constant @ trial onset (to account for visual activation)

    Contrasts:
        ccnl_view(contextExpt(), 20, 'actual'); 

    Hypothesis: 

    Result:

Model 5 -- outcome:

    Regressor #1: constant @ feedback (outcome) time for "sick" trials only (outcome = 1)
    Regressor #2: constant @ feedback (outcome) time for "not sick" trials only (outcome = 2)
    Regressor #3: constant @ trial onset (to account for visual activation)

    Contrasts:
        ccnl_view(contextExpt(), 5, 'sick - not sick');

    Hypothesis: sanity check (see Model 6)

    Result: differential activation in L Cuneus for "sick" vs. R Cuneus for "not sick" (disappears with Cluster FWE)

    Discussion: on "sick" trials, the sick face shows up on the right side of the screen; on "not sick" trials, the happy face shows up on the left;
                otherwise the trials are identical => maybe that accounts for it?

Model 6 -- outcome:

    Regressor #1: pmod = outcome (1 = sick, 0 = not sick) @ feedback (outcome) time
    Regressor #2: constant @ trial onset (to account for visual activation)

    Contrasts:
        ccnl_view(contextExpt(), 6, 'outcome');

    Hypothesis: sanity check -- should look just like Model 5

    Result: looks just like Model 5

Model 2 is wrong; was supposed to be the M2 posterior @ feedback (outcome) time but have extra regressors for the test trials that mess things up--

Model 3 is wrong; it had a pmod = 1 if the response was correct, 0 if not @ feedback (outcome) time

Model 4 is wrong; it had a prediction error pmod but it was calculated incorrectly

Model 7 is wrong; it is the choice probability pmod

Models 11, 12, 13 are for Momchil's own entertainment

Models 15, 16, 17 are for Momchil's own entertainment

Model 21 tried to capture motor stuff with a pmod = 1 if subject pressed sick, 0 otherwise

Models 22, 23, 24 are for Momchil's own entertainment

