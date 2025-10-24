SELECT
    rx.Number AS order_id,
    loc.OeSite AS site_id,
    rx.EnterDate AS enter_date,
    rx.EnterTime AS enter_time,
    rx.DcDate AS orig_stop_dt,
    rx.DcTime AS orig_stop_tm,
    rx.StartDate AS order_start_dt,
    rx.StartTime AS order_start_tm,
    rx.FirstDoseDate AS first_dose_date,
    rx.FirstDoseTime AS first_dose_time,
    rx.StopDate AS order_stop_dt,
    rx.StopTime AS order_stop_tm,
    rx.Status AS order_status,
    rx.OrderType AS order_type
FROM FHA_ANALYTICS.FHA.F_MeditechPHARxMain AS rx
INNER JOIN FHA_ANALYTICS.FHA.D_MeditechMISLocnMain AS loc ON loc.Mnemonic = rx.Location;