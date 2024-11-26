$onMulti

$IMPORT functions.gms;
$IMPORT settings.gms

$IMPORT sets/time.sets.gms
$IMPORT sets/input_output.sets.gms
$IMPORT sets/output.sets.gms
$IMPORT sets/production.sets.gms
$IMPORT sets/emissions.sets.gms
$IMPORT sets/energy_taxes_and_emissions.sets.gms

set_time_periods(%first_data_year%, %terminal_year%);

# ------------------------------------------------------------------------------
# Select modules
# ------------------------------------------------------------------------------
$FUNCTION import_from_modules(stage_key):
  $SETGLOBAL stage stage_key;
  $IMPORT submodel_template.gms
  # $IMPORT test_module.gms
  # $IMPORT labor_market.gms
  # $IMPORT energy_markets.gms; 
  # $IMPORT industries_CES_energydemand.gms; 
  # $IMPORT production.gms; 
  # $IMPORT emissions.gms; 
  # $IMPORT energy_and_emissions_taxes.gms; 
  # $IMPORT input_output.gms
  # $IMPORT aggregates.gms
  # $IMPORT imports.gms
  # $IMPORT households.gms
$ENDFUNCTION

# ------------------------------------------------------------------------------
# Define variables and dummies
# ------------------------------------------------------------------------------
# Group of all variables, identical to ALL group, except containing only elements that exist (not dummied out)
$Group all_variables ; # All variables in the model
$Group main_endogenous ;
$Group data_covered_variables ; # Variables that are covered by data
$Group G_flat_after_last_data_year ; # Variables that are extended with "flat forecast" after last data year
$SetGroup SG_flat_after_last_data_year ; # Dummies that are extended with "flat forecast" after last data year

@import_from_modules("variables")

$IMPORT growth_adjustments.gms
@inf_growth_adjust()

# ------------------------------------------------------------------------------
# Define equations
# ------------------------------------------------------------------------------
model main;
model calibration;
@import_from_modules("equations")

# ------------------------------------------------------------------------------
# Import data and set parameters
# ------------------------------------------------------------------------------
@import_from_modules("exogenous_values")
@set(data_covered_variables, _data, .l) # Save values of data covered variables prior to calibration
$IMPORT exist_dummies.gms

# ------------------------------------------------------------------------------
# Calibrate model
# ------------------------------------------------------------------------------
$Group calibration_endogenous ;
@import_from_modules("calibration")
$IMPORT calibration.gms

# ------------------------------------------------------------------------------
# Tests
# ------------------------------------------------------------------------------
# $import sanitychecks.gms
@import_from_modules("tests")
# Data check  -  Abort if any data covered variables have been changed by the calibration
@assert_no_difference(data_covered_variables, 1e-6, _data, .l, "data_covered_variables was changed by calibration.")

# Zero shock  -  Abort if a zero shock changes any variables significantly
@set(all_variables, _saved, .l)
$FIX all_variables; $UNFIX main_endogenous;
Solve main using CNS;
@assert_no_difference(all_variables, 1e-6, .l, _saved, "Zero shock changed variables significantly.");

# ------------------------------------------------------------------------------
# Shock model
# ------------------------------------------------------------------------------
# #Shock
# tCO2_Emarg.l[em,es,e,i,t] = 1.1 * tCO2_Emarg.l[em,es,e,i,t]; #Increase in CO2-tax of 10%
# $FIX all_variables;
# $UNFIX main_endogenous;
# Solve main using CNS;
# execute_unload 'shock.gdx';

