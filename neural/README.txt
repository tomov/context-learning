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

Model 29 -- main effect @ trial onset, no visual regressor:

    Regressor #1: context role (irrelevant, additive, or modulatory) @ trial onset time

    Contrasts:
        ccnl_view(contextExpt(), 29, 'modulatory - irrelevant');
        ccnl_view(contextExpt(), 29, 'modulatory - additive');
        ccnl_view(contextExpt(), 29, 'additive - irrelevant');

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

Model 28 -- context role & trial onset

    Regressor #1: context role (irrelevant, additive, or modulatory) @ trial onset time
    Regressor #2: constant @ trial onset (to account for visual activation)

    Contrasts:
        ccnl_view(contextExpt(), 28, 'modulatory - irrelevant');
        ccnl_view(contextExpt(), 28, 'modulatory - additive');
        ccnl_view(contextExpt(), 28, 'additive - irrelevant');

    Hypothesis: hippocampus would show greater activiation in the modulatory vs. the irrelevant or additive conditions

    Result: 

Model 31 -- value pmods @ trial onset

    Regressor #1: predicted values @ trial onset time
                 pmod 1) = predicted value for M1 (irrelevant)
                 pmod 2) = predicted value for M2 (modulatory)
                 pmod 3) = predicted value for M3 (additive)

    Contrasts:
        ccnl_view(contextExpt(), 31, 'M1_value');
        ccnl_view(contextExpt(), 31, 'M2_value');
        ccnl_view(contextExpt(), 31, 'M3_value');

    Hypothesis:

    Result: 

Model 33 -- value pmods @ trial onset (same as 30) + prediction error pmod @ outcome onset

    Regressor #1: predicted values @ trial onset time
                 pmod 1) = predicted value for M1 (irrelevant)
                 pmod 2) = predicted value for M2 (modulatory)
                 pmod 3) = predicted value for M3 (additive)
    Regressor #2: pmod = prediction error = outcome - predicted value @ feedback (outcome) onset

    Contrasts:
        ccnl_view(contextExpt(), 32, 'M1_value');
        ccnl_view(contextExpt(), 32, 'M2_value');
        ccnl_view(contextExpt(), 32, 'M3_value');
        ccnl_view(contextExpt(), 32, 'prediction_error');

    Hypothesis:

    Result: 

Model 37 -- M1 (irrelevant) value pmod @ trial onset + PE pmod for M1 only @ outcome onset

    Regressor #1: pmod = predicted value for M1 (irrelevant) @ trial onset time
    Regressor #2: pmod = prediction error = outcome - predicted value for M1 @ feedback (outcome) onset

    Contrasts:
        ccnl_view(contextExpt(), 34, 'M1_value');
        ccnl_view(contextExpt(), 34, 'prediction_error');

    Hypothesis:

    Result: 

Model 38 -- M2 (modulatory) value pmod @ trial onset + PE pmod for M2 only @ outcome onset (similar to 37)

Model 39 -- M3 (additive) value pmod @ trial onset + PE pmod for M3 only @ outcome onset (similar to 37)

Model 40 -- likelihood pmods @ outcome onset

    Regressor #1: outcome likelihood values @ feedback (outcome) onset time
                 pmod 1) = outcome likelihood for M1 (irrelevant)
                 pmod 2) = outcome likelihood for M2 (modulatory)
                 pmod 3) = outcome likelihood for M3 (additive)
    Regressor #2: constant @ trial onset (to account for visual activation)

    Contrasts:
        ccnl_view(contextExpt(), 40, 'M1_lik');
        ccnl_view(contextExpt(), 40, 'M2_lik');
        ccnl_view(contextExpt(), 40, 'M3_lik');

    Hypothesis:

    Result: 

Model 41 -- likelihood pmods @ outcome onset (same as 40) w/o the const regressor

Model 42 -- prediction error pmod @ outcome onset (same as 26)

    Regressor #1: pmod = prediction error = outcome - predicted value @ feedback (outcome) onset
    Regressor #2: constant @ trial onset (to account for visual activation)

    Contrasts:
        ccnl_view(contextExpt(), 42, 'prediction_error');

    Hypothesis:

    Result: 

Model 43 -- prediction error pmod @ outcome onset (same as 42) w/o the const regressor

Model 44 -- PE pmod for M1 only @ outcome onset

    Regressor #1: pmod = prediction error = outcome - predicted value for M1 @ feedback (outcome) onset
    Regressor #2: constant @ trial onset (to account for visual activation)

    Contrasts:
        ccnl_view(contextExpt(), 44, 'prediction_error');

    Hypothesis:

    Result: 

Model 45 -- PE pmod for M2 only @ outcome onset (similar to 44)

Model 46 -- PE pmod for M3 only @ outcome onset (similar to 44)

Model 47 -- PE pmod for M1 only @ outcome onset (same as 44) w/o the const regressor

Model 48 -- PE pmod for M2 only @ outcome onset (same as 45) w/o the const regressor

Model 49 -- PE pmod for M3 only @ outcome onset (same as 46) w/o the const regressor




Model 2 is wrong; was supposed to be the M2 posterior @ feedback (outcome) time but have extra regressors for the test trials that mess things up--

Model 3 is wrong; it had a pmod = 1 if the response was correct, 0 if not @ feedback (outcome) time

Model 4 is wrong; it had a prediction error pmod but it was calculated incorrectly

Model 7 is wrong; it is the choice probability pmod

Models 11, 12, 13 are for Momchil's own entertainment

Models 15, 16, 17 are for Momchil's own entertainment

Model 21 tried to capture motor stuff with a pmod = 1 if subject pressed sick, 0 otherwise

Models 22, 23, 24 are for Momchil's own entertainment

Model 28 is wrong; it has main effect @ trial onset (same as 29) + const @ trial onset; can't have two at the same onset

Model 30 is wrong; it has value pmods @ trial onset (same as 31) but with the const regressor => can't have two at same onset

Model 32 is wrong; it is value pmods @ trial onset + prediction error pmod @ outcome onset (same as 33) but with the const regressor => can't have two at same onset

Model 34 is wrong; M1 (irrelevant) value pmod @ trial onset + PE pmod for M1 only @ outcome onset (same as 37) w the const regressor => can't have two at same onset

Model 35 is wrong; M2 (modulatory) value pmod @ trial onset + PE pmod for M2 only @ outcome onset (same as 38) w the const regressor => can't have two at same onset

Model 36 is wrong; M3 (additive) value pmod @ trial onset + PE pmod for M3 only @ outcome onset (same as 39) w the const regressor => can't have two at same onset

