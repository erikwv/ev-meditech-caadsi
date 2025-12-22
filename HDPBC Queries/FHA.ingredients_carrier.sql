SELECT
    car.CarrierQ AS carrier_number,
    drug_car.NdcDinNumber AS carrier_din,
    car.Carrier AS carrier_id,
    drug5_car.DrugId AS carrier_desc,
    car.CarrierVolume AS carrier_volume,
    drug_car.DispenseForm AS carrier_disp_form
FROM FHA_ANALYTICS.FHA.F_MeditechPHARxCarriers AS car
LEFT JOIN FHA_ANALYTICS.FHA.D_MeditechPHADrugMain AS drug_car ON drug_car.Mnemonic = car.Carrier COLLATE DATABASE_DEFAULT
LEFT JOIN FHA_ANALYTICS.FHA.D_MeditechPHADrugMain5 AS drug5_car ON drug5_car.Mnemonic = car.Carrier COLLATE DATABASE_DEFAULT;