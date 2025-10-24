SELECT
    -- Order Info
    rx.SYSSystemID AS system_id,
    rx.Number AS order_id,
    rx.Patient AS patient_urn,
    rx.EnterDate AS enter_date,
    rx.StartDate AS order_start_dt,
    rx.StopDate AS order_stop_dt,
    rx.Status AS order_status,
    rx.OrderType AS order_type,

    -- Additive Info
    addi.AdditiveQ AS additive_num,
    addi.Additive AS additive_id,
    drug_add.NdcDinNumber AS additive_din,
    drug5_add.DrugId AS additive_desc,
    addi.AdditiveDose AS additive_dose,
    drug_add.DispenseForm AS additive_dose_units,

    -- Carrier Info
    car.CarrierQ AS carrier_number,
    car.Carrier AS carrier_id,
    drug_car.NdcDinNumber AS carrier_din,
    drug5_car.DrugId AS carrier_desc,
    car.CarrierVolume AS carrier_volume,
    drug_car.DispenseForm AS carrier_disp_form

FROM FHA_ANALYTICS.FHA.F_MeditechPHARxMain AS rx

-- Additives Join
LEFT JOIN FHA_ANALYTICS.FHA.F_MeditechPHARxIvAdditives AS addi
    ON addi.Urn = rx.Urn COLLATE DATABASE_DEFAULT
LEFT JOIN FHA_ANALYTICS.FHA.D_MeditechPHADrugMain AS drug_add
    ON drug_add.Mnemonic = addi.Additive COLLATE DATABASE_DEFAULT
LEFT JOIN FHA_ANALYTICS.FHA.D_MeditechPHADrugMain5 AS drug5_add
    ON drug5_add.Mnemonic = addi.Additive COLLATE DATABASE_DEFAULT

-- Carriers Join
LEFT JOIN FHA_ANALYTICS.FHA.F_MeditechPHARxCarriers AS car
    ON car.Urn = rx.Urn COLLATE DATABASE_DEFAULT
LEFT JOIN FHA_ANALYTICS.FHA.D_MeditechPHADrugMain AS drug_car
    ON drug_car.Mnemonic = car.Carrier COLLATE DATABASE_DEFAULT
LEFT JOIN FHA_ANALYTICS.FHA.D_MeditechPHADrugMain5 AS drug5_car
    ON drug5_car.Mnemonic = car.Carrier COLLATE DATABASE_DEFAULT

WHERE rx.EnterDate >= '20170101' AND rx.EnterDate < '20170201'
  AND rx.SYSSystemID LIKE 'MC';