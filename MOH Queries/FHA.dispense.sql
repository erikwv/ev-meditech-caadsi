SELECT
    rx_tx.TxnDate AS disp_date,
    drug_disp.Mnemonic AS disp_drug_mnemonic,
    drug_disp.NdcDinNumber AS disp_din,
    rx_tx.TxnDoses AS disp_num_doses,
    rx_tx.TxnItems AS disp_qty,
    rx_tx.TxnInventory AS disp_inventory,
    rx_tx.TxnCost AS cost,
    rx_tx.TxnChargeType AS charge_type,
    rx_tx.TxnLocation AS disp_loc,
    rx_tx.TxnEntered AS disp_start_timedate,
    rx_tx.TxnComplete AS disp_fin_timedate,
    rx_tx.TxnOrderType AS disp_med_type,
    drug_disp.DispenseForm AS disp_form,
    drug_disp.DispenseSize AS disp_size,
    drug_disp5.DrugId AS med_desc
FROM FHA_ANALYTICS.FHA.F_MeditechPHARxTransactions AS rx_tx
LEFT JOIN FHA_ANALYTICS.FHA.D_MeditechPHADrugMain AS drug_disp ON drug_disp.Mnemonic = rx_tx.TxnMed COLLATE DATABASE_DEFAULT
LEFT JOIN FHA_ANALYTICS.FHA.D_MeditechPHADrugMain5 AS drug_disp5 ON drug_disp5.Mnemonic = rx_tx.TxnMed COLLATE DATABASE_DEFAULT;