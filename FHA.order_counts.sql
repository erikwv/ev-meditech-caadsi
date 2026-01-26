-- FHA Order Counts Query
-- Purpose: Count total orders by System (MC/CS) and Site
-- Created: 2026-01-26
-- 
-- This query provides ORDER COUNTS ONLY (not individual order details)
-- Use this to get accurate denominators for percentage calculations
-- Much faster and lighter than full order export

DECLARE @StartDate DATETIME = '2025-01-19 00:00:00';
DECLARE @EndDate   DATETIME = '2025-01-20 00:00:00';

-- Get order counts by System and Site
SELECT 
    site.Mnemonic AS Site,
    CASE WHEN rx.SYSSystemID = 'MC' THEN 'CS' ELSE rx.SYSSystemID END AS [System],
    COUNT(DISTINCT rx.PK_MeditechPHARxMain) AS TotalOrders
FROM FHA_ANALYTICS.FHA.F_MeditechPHARxMain rx
JOIN FHA_ANALYTICS.FHA.F_MeditechADMPatMain pat
  ON rx.Patient COLLATE DATABASE_DEFAULT = pat.Urn COLLATE DATABASE_DEFAULT
JOIN FHA_ANALYTICS.FHA.D_MeditechMISLocnMain loc
  ON loc.Mnemonic COLLATE DATABASE_DEFAULT = pat.Location COLLATE DATABASE_DEFAULT
JOIN FHA_ANALYTICS.FHA.D_MeditechPHASiteDictionary site
  ON site.Mnemonic COLLATE DATABASE_DEFAULT = loc.OeSite COLLATE DATABASE_DEFAULT
WHERE rx.Sig <> '.STK-MED'
  AND rx.EnterDate >= @StartDate
  AND rx.EnterDate <  @EndDate
GROUP BY 
    site.Mnemonic,
    CASE WHEN rx.SYSSystemID = 'MC' THEN 'CS' ELSE rx.SYSSystemID END
ORDER BY 
    CASE WHEN rx.SYSSystemID = 'MC' THEN 'CS' ELSE rx.SYSSystemID END,
    site.Mnemonic;

-- Also get system totals
SELECT 
    CASE WHEN rx.SYSSystemID = 'MC' THEN 'CS' ELSE rx.SYSSystemID END AS [System],
    COUNT(DISTINCT rx.PK_MeditechPHARxMain) AS TotalOrders
FROM FHA_ANALYTICS.FHA.F_MeditechPHARxMain rx
JOIN FHA_ANALYTICS.FHA.F_MeditechADMPatMain pat
  ON rx.Patient COLLATE DATABASE_DEFAULT = pat.Urn COLLATE DATABASE_DEFAULT
JOIN FHA_ANALYTICS.FHA.D_MeditechMISLocnMain loc
  ON loc.Mnemonic COLLATE DATABASE_DEFAULT = pat.Location COLLATE DATABASE_DEFAULT
JOIN FHA_ANALYTICS.FHA.D_MeditechPHASiteDictionary site
  ON site.Mnemonic COLLATE DATABASE_DEFAULT = loc.OeSite COLLATE DATABASE_DEFAULT
WHERE rx.Sig <> '.STK-MED'
  AND rx.EnterDate >= @StartDate
  AND rx.EnterDate <  @EndDate
GROUP BY 
    CASE WHEN rx.SYSSystemID = 'MC' THEN 'CS' ELSE rx.SYSSystemID END
ORDER BY 
    CASE WHEN rx.SYSSystemID = 'MC' THEN 'CS' ELSE rx.SYSSystemID END;

-- And grand total
SELECT 
    COUNT(DISTINCT rx.PK_MeditechPHARxMain) AS GrandTotalOrders
FROM FHA_ANALYTICS.FHA.F_MeditechPHARxMain rx
JOIN FHA_ANALYTICS.FHA.F_MeditechADMPatMain pat
  ON rx.Patient COLLATE DATABASE_DEFAULT = pat.Urn COLLATE DATABASE_DEFAULT
JOIN FHA_ANALYTICS.FHA.D_MeditechMISLocnMain loc
  ON loc.Mnemonic COLLATE DATABASE_DEFAULT = pat.Location COLLATE DATABASE_DEFAULT
JOIN FHA_ANALYTICS.FHA.D_MeditechPHASiteDictionary site
  ON site.Mnemonic COLLATE DATABASE_DEFAULT = loc.OeSite COLLATE DATABASE_DEFAULT
WHERE rx.Sig <> '.STK-MED'
  AND rx.EnterDate >= @StartDate
  AND rx.EnterDate <  @EndDate;
