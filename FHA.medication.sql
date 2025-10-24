SELECT
    med.Med AS product_mnemonic,
    drug_main5.DrugId AS generic_name,
    drug_main.Mnemonic AS drug_mnemonic,
    drug_main.NdcDinNumber AS din,
    med.Dose AS strength_dose,
    drug_main.DispenseUnit AS strength_dose_unit,
    drug_main.DispenseForm AS dosage_form,
    drug_main.DispenseSize AS main_disp_size,
    med.Volume AS volume_dose
FROM FHA_ANALYTICS.FHA.F_MeditechPHARxInpatientMedications AS med
INNER JOIN FHA_ANALYTICS.FHA.D_MeditechPHADrugMain AS drug_main ON drug_main.Mnemonic = med.Med COLLATE DATABASE_DEFAULT
INNER JOIN FHA_ANALYTICS.FHA.D_MeditechPHADrugMain5 AS drug_main5 ON drug_main5.Mnemonic = med.Med COLLATE DATABASE_DEFAULT;