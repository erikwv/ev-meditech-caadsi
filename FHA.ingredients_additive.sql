SELECT
    addi.AdditiveQ AS additive_num,
    drug_add.NdcDinNumber AS additive_din,
    addi.Additive AS additive_id,
    drug5_add.DrugId AS additive_desc,
    addi.AdditiveDose AS additive_dose,
    drug_add.DispenseForm AS additive_dose_units
FROM FHA_ANALYTICS.FHA.F_MeditechPHARxIvAdditives AS addi
LEFT JOIN FHA_ANALYTICS.FHA.D_MeditechPHADrugMain AS drug_add ON drug_add.Mnemonic = addi.Additive COLLATE DATABASE_DEFAULT
LEFT JOIN FHA_ANALYTICS.FHA.D_MeditechPHADrugMain5 AS drug5_add ON drug5_add.Mnemonic = addi.Additive COLLATE DATABASE_DEFAULT;