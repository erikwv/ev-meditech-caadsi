SELECT
    comp.IngredientQ AS ingred_number,
    drug_comp.NdcDinNumber AS ingred_din,
    comp.Ingredient AS ingred_id,
    drug5_comp.DrugId AS ingred_desc,
    comp.IngredientDose AS ingred_dose,
    drug_comp.DispenseForm AS ingred_dose_units
FROM FHA_ANALYTICS.FHA.F_MeditechPHARxCompoundIngredients AS comp
LEFT JOIN FHA_ANALYTICS.FHA.D_MeditechPHADrugMain AS drug_comp
    ON drug_comp.Mnemonic = comp.Ingredient COLLATE DATABASE_DEFAULT
LEFT JOIN FHA_ANALYTICS.FHA.D_MeditechPHADrugMain5 AS drug5_comp
    ON drug5_comp.Mnemonic = comp.Ingredient COLLATE DATABASE_DEFAULT;