--Used to calculate Cancellation $ value and Cancelled order count

create or replace view KSFPA.ONLINE_UGAM_PVT.CANCELLED_ORDERS_MAIN1(
	YEAR,
	PERIOD,
	WEEK,
	FY_PERIOD_WEEK,
	CANCELLED_DATE,
	COST,
	ORDER_COUNT,
	MOVING_COST,
	VAR,
	AVG_4_WEEKS,
	MOVING_COST_4_WEEKS,
	VAR_4_WEEKS,
	RETURN_REASON
) as 
SELECT 
ACCOUNTING_YEAR AS YEAR,
    ACCOUNTING_MONTH_NUMBER AS PERIOD,
    ACCOUNTING_WEEK_NUMBER AS WEEk,
CONCAT('FY',RIGHT(ACCOUNTING_YEAR,2),'P',ACCOUNTING_MONTH_NUMBER,'W',ACCOUNTING_WEEK_NUMBER) AS FY_PERIOD_WEEK,
Cancelled_Date,
cost,
Order_Count,
moving_cost,
var,
avg_4_weeks,
moving_cost_4_weeks,
var_4_weeks,
Return_Reason
FROM
(
select 
Cancelled_Date,
cost as cost,
Order_Count,
avg(cost) over (partition by Return_Reason order by Cancelled_Date rows between 84 preceding and 1 preceding) as moving_cost,
(cost/avg(cost) over (partition by Return_Reason order by Cancelled_Date rows between 84 preceding and 1 preceding))-1 as var,
avg(cost) over (partition by Return_Reason order by Cancelled_Date rows between 29 preceding and 1 preceding) as avg_4_weeks,
avg(cost) over (partition by Return_Reason order by Cancelled_Date rows between 28 preceding and 1 preceding) as moving_cost_4_weeks,
(cost/avg(cost) over (partition by Return_Reason order by Cancelled_Date rows between 28 preceding and 1 preceding))-1 as var_4_weeks,

Return_Reason
from
((

select 
Cancelled_Date,
sum(cost) as cost,
COUNT(DISTINCT(ExternalOrderID)) as Order_Count,
Return_Reason

FROM 
(
Select soi.ExternalOrderID,
soi.UnitPrice * soi.Quantity as Cost,
DATE(soi.DO_Cancelled) AS Cancelled_Date,
CASE WHEN DATEDIFF(minute, soi.OrderDate, soi.DO_Created) < 45 
AND (ParentShipmentID = '0' OR ParentShipmentID is null) THEN 'Upfront Rejection (HD)' 
			ELSE 'HD Store Rejection (Exception)' 
			END AS Return_Reason
from "KSFPA"."OMS"."STOREORDERITEMS" soi
WHERE
  soi.DO_Created > '2020-06-29 00:00:00'
  and soi.DO_Created <  CONCAT(CURRENT_DATE()-1, ' 23:59:59')
  and soi.str_id ='9999'
  and soi.DO_Cancelled is not null
  and soi.DO_Cancelled < CONCAT(CURRENT_DATE()-1, ' 23:59:59')
  
UNION ALL
  
Select soi.ExternalOrderID, 
soi.UnitPrice * soi.Quantity as Cost, 
DATE(soi.DO_Cancelled) AS Cancelled_Date ,
CASE WHEN LTRIM(RTRIM(ModificationDescription)) = 'Cancelled'  
      THEN (CASE WHEN DATEDIFF(minute, soi.OrderDate, soi.DO_Created) < 45 
      AND (ParentShipmentID = '0' OR ParentShipmentID is null) THEN 'Upfront Rejection (CC)'
      ELSE 'C&C Store Rejection (Exception)' END)
ELSE 'Click & Collect Store Rejection - Customer chose free delivery'
			END AS Return_Reason
from "KSFPA"."OMS"."STOREORDERITEMS" soi
WHERE
  soi.DO_Created > '2020-06-29 00:00:00'
  and soi.DO_Created < CONCAT(CURRENT_DATE()-1, ' 23:59:59')
  and soi.str_id ='9996'
  and soi.DO_Cancelled is not null
  and soi.DO_Cancelled < CONCAT(CURRENT_DATE()-1, ' 23:59:59')

UNION ALL
  
Select soi.ExternalOrderID, 
soi.UnitPrice * soi.Quantity as Cost, 
DATE(soi.DO_Cancelled) AS Cancelled_Date, 
'Ready to Collect Order Not Collected' AS Return_Reason
from  "KSFPA"."OMS"."STOREORDERITEMS" soi
WHERE
  soi.DO_Cancelled > '2020-06-29 00:00:00'
  and soi.DO_Cancelled < CONCAT(CURRENT_DATE()-1, ' 23:59:59')
  and LTRIM(RTRIM(soi.ShipStatus)) = 'ItemCancelled'
  and QuantityReadyToCollect > '0'
  and soi.DO_Cancelled is not null
) 
group by Cancelled_Date,Return_Reason
order by Cancelled_Date
)
UNION ALL 
(

select 
DISTINCT Cancelled_Date,
sum(cost) as cost,
COUNT(DISTINCT(ExternalOrderID)) as Order_Count,
'Total' AS Return_Reason

FROM 
(
Select soi.ExternalOrderID,
soi.UnitPrice * soi.Quantity as Cost,
DATE(soi.DO_Cancelled) AS Cancelled_Date,
CASE WHEN DATEDIFF(minute, soi.OrderDate, soi.DO_Created) < 45 
AND (ParentShipmentID = '0' OR ParentShipmentID is null) THEN 'Upfront Rejection (HD)' 
			ELSE 'HD Store Rejection (Exception)' 
			END AS Return_Reason
from "KSFPA"."OMS"."STOREORDERITEMS" soi
WHERE
  soi.DO_Created > '2020-06-29 00:00:00'
  and soi.DO_Created <  CONCAT(CURRENT_DATE()-1, ' 23:59:59')
  and soi.str_id ='9999'
  and soi.DO_Cancelled is not null
  and soi.DO_Cancelled < CONCAT(CURRENT_DATE()-1, ' 23:59:59')
  
UNION ALL
  
Select soi.ExternalOrderID, 
soi.UnitPrice * soi.Quantity as Cost, 
DATE(soi.DO_Cancelled) AS Cancelled_Date ,
CASE WHEN LTRIM(RTRIM(ModificationDescription)) = 'Cancelled'  
      THEN (CASE WHEN DATEDIFF(minute, soi.OrderDate, soi.DO_Created) < 45 
      AND (ParentShipmentID = '0' OR ParentShipmentID is null) THEN 'Upfront Rejection (CC)'
      ELSE 'C&C Store Rejection (Exception)' END)
ELSE 'Click & Collect Store Rejection - Customer chose free delivery'
			END AS Return_Reason
from "KSFPA"."OMS"."STOREORDERITEMS" soi
WHERE
  soi.DO_Created > '2020-06-29 00:00:00'
  and soi.DO_Created < CONCAT(CURRENT_DATE()-1, ' 23:59:59')
  and soi.str_id ='9996'
  and soi.DO_Cancelled is not null
  and soi.DO_Cancelled < CONCAT(CURRENT_DATE()-1, ' 23:59:59')

UNION ALL
  
Select soi.ExternalOrderID, 
soi.UnitPrice * soi.Quantity as Cost, 
DATE(soi.DO_Cancelled) AS Cancelled_Date ,
'Ready to Collect Order Not Collected' AS Return_Reason
from  "KSFPA"."OMS"."STOREORDERITEMS" soi
WHERE
  soi.DO_Cancelled > '2020-06-29 00:00:00'
  and soi.DO_Cancelled < CONCAT(CURRENT_DATE()-1, ' 23:59:59')
  and LTRIM(RTRIM(soi.ShipStatus)) = 'ItemCancelled'
  and QuantityReadyToCollect > '0'
  and soi.DO_Cancelled is not null
) 
group by Cancelled_Date
order by Cancelled_Date
))
) 
T1
LEFT JOIN KSF_SOPHIA_DATA_INTELLIGENCE_HUB_PROD.COMMON_DIMENSIONS.DIM_DATE DD ON T1.Cancelled_Date = DD.DATE
ORDER BY 5 DESC;


----Total Sales by Order Type.
--Used as Denominator to calculate % of Cancellation Sales
create or replace view KSFPA.ONLINE_UGAM_PVT.CANCELLED_ORDERS_CC_HD_SALES(
	ORDER_DATE,
	CC_SALES,
	HD_SALES,
	TOTAL_SALES
) as
SELECT Order_Date
      ,SUM(CASE WHEN CUSTOMERORDERTYPE = 'CAC' THEN Sales END) AS CC_Sales
      ,SUM(CASE WHEN CUSTOMERORDERTYPE = 'STD' THEN Sales END) AS HD_Sales
      ,SUM(Sales) AS Total_Sales
FROM (
    SELECT DISTINCT EXTERNALORDERID
   ,ORDDATE AS Order_Date
   ,CUSTOMERORDERTYPE
   , AVG(co.ORDERTOTAL) AS Sales
    FROM "KSFPA"."OMS"."CUSTOMERORDER" co
    WHERE co.DO_CREATED > '2020-06-29 00:00:00'
        AND co.DO_CREATED < CONCAT(CURRENT_DATE()-1, ' 23:59:59')
//        AND co.CUSTOMERORDERTYPE = 'CAC'
    GROUP BY 1,2,3
) AS subquery
GROUP BY Order_Date
ORDER BY Order_Date ASC;


----Total Order Count by Order Type.
--Used as Denominator to calculate % of Cancelled Customer Orders
create or replace view KSFPA.ONLINE_UGAM_PVT.CANCELLED_ORDERS_CC_HD_ORDER_COUNT(
	ORDER_DATE,
	CC_COUNT,
	HD_COUNT,
	TOTAL_ORDER_COUNT
) as
SELECT TO_DATE(DO_PACKING) AS Order_Date
      ,COUNT(DISTINCT(CASE WHEN CUSTOMERORDERTYPE = 'CAC' THEN so.EXTERNALORDERID END)) AS CC_Count
      ,COUNT(DISTINCT(CASE WHEN CUSTOMERORDERTYPE = 'STD' THEN so.EXTERNALORDERID END)) AS HD_Count
      ,COUNT(DISTINCT so.EXTERNALORDERID) AS Total_Order_Count
FROM "KSFPA"."OMS"."CUSTOMERORDER" co
JOIN "KSFPA"."OMS"."STOREORDER" so
ON co.ORDERID = so.ORDERID
WHERE so.DO_PACKING > '2020-06-29 00:00:00'
      AND so.DO_PACKING < CONCAT(CURRENT_DATE()-1, ' 23:59:59')
//  and co.CustomerOrderType = 'CAC'
GROUP BY 1
ORDER BY 1 ASC;

--USed to calculate fully cancelled orders
--USed as numerator for % of fully cancelled customer orders
create or replace view KSFPA.ONLINE_UGAM_PVT.TOTAL_CANCELLATIONS(
	CANCELLED_DATE,
	RETURN_REASON,
	ORDER_COUNT
) as
SELECT Cancelled_Date,
       Return_Reason,
       ORDER_COUNT
FROM
    (SELECT Cancelled_Date,
           Return_Reason,
           COUNT(DISTINCT ExternalOrderID ) AS ORDER_COUNT
    FROM
        ((SELECT A.Cancelled_Date
               ,A.Return_Reason
               ,B.ExternalOrderID
               ,SUM(ORIGINALQUANTITY)
               ,SUM(Quantity)
        FROM
            (Select soi.ExternalOrderID,Quantity,
            soi.UnitPrice * soi.Quantity as Cost,
            DATE(soi.DO_Cancelled) AS Cancelled_Date,
            DATE(soi.DO_CREATED) AS OrderDate,
            CASE WHEN DATEDIFF(minute, soi.OrderDate, soi.DO_Created) < 45 
            AND (ParentShipmentID = '0' OR ParentShipmentID is null) THEN 'Upfront Rejection (HD)' 
                        ELSE 'HD Store Rejection (Exception)' 
                        END AS Return_Reason
            from "KSFPA"."OMS"."STOREORDERITEMS" soi
            WHERE
              soi.DO_Created > '2020-06-29 00:00:00'
              and soi.DO_Created <  CONCAT(CURRENT_DATE()-1, ' 23:59:59')
              and soi.str_id ='9999'
              and soi.DO_Cancelled is not null
              and soi.DO_Cancelled < CONCAT(CURRENT_DATE()-1, ' 23:59:59')
    //        AND ExternalOrderID = 354237152
            )A
        INNER JOIN
            (Select soi.ExternalOrderID,
    //                DATE(soi.DO_Cancelled) AS Cancelled_Date,
                    DATE(soi.DO_CREATED) AS OrderDate,
                    SUM(ORIGINALQUANTITY) as ORIGINALQUANTITY
             from "KSFPA"."OMS"."STOREORDERITEMS" soi
             WHERE soi.DO_Created > '2020-06-29 00:00:00'
                   and soi.DO_Created <  CONCAT(CURRENT_DATE()-1, ' 23:59:59')
                   AND COALESCE(PARENTSHIPMENTID ,0) = 0
    //         AND ExternalOrderID = 354237152
             GROUP BY 1,2)B
        ON A.ExternalOrderID= B.ExternalOrderID 
        AND A.OrderDate = B.OrderDate 
        WHERE Quantity=ORIGINALQUANTITY
        GROUP BY 1,2,3
        ORDER BY 1 DESC)
    UNION

        (SELECT A.Cancelled_Date
               ,A.Return_Reason
               ,B.ExternalOrderID
               ,SUM(ORIGINALQUANTITY)
               ,SUM(Quantity)
         FROM
              (Select soi.ExternalOrderID,
                      Quantity,
                      soi.UnitPrice * soi.Quantity as Cost, 
                      DATE(soi.DO_Cancelled) AS Cancelled_Date, 
                      DATE(soi.DO_CREATED) AS OrderDate,
                      CASE WHEN LTRIM(RTRIM(ModificationDescription)) = 'Cancelled'  
                           THEN (CASE WHEN DATEDIFF(minute, soi.OrderDate, soi.DO_Created) < 45 
                                      AND (ParentShipmentID = '0' OR ParentShipmentID is null) THEN 'Upfront Rejection (CC)'
                                      ELSE 'C&C Store Rejection (Exception)' END)
                            ELSE 'Click & Collect Store Rejection - Customer chose free delivery'
			          END AS Return_Reason
               FROM "KSFPA"."OMS"."STOREORDERITEMS" soi
               WHERE soi.DO_Created > '2020-06-29 00:00:00'
                  and soi.DO_Created < CONCAT(CURRENT_DATE()-1, ' 23:59:59')
                  and soi.str_id ='9996'
                  and soi.DO_Cancelled is not null
                  and soi.DO_Cancelled < CONCAT(CURRENT_DATE()-1, ' 23:59:59')
    //          AND ExternalOrderID =350470457 
               --339719862
              )A
        INNER JOIN 
            (Select soi.ExternalOrderID, 
                    SUM(ORIGINALQUANTITY) AS ORIGINALQUANTITY,
                    DATE(soi.DO_CREATED) AS OrderDate
             from "KSFPA"."OMS"."STOREORDERITEMS" soi
             WHERE soi.DO_Created >'2020-06-29 00:00:00'
               and soi.DO_Created < CONCAT(CURRENT_DATE()-1, ' 23:59:59')
               AND COALESCE(PARENTSHIPMENTID ,0) = 0
             GROUP BY 1,3)B
        ON A.ExternalOrderID= B.ExternalOrderID 
        AND A.OrderDate = B.OrderDate 
        WHERE Quantity=ORIGINALQUANTITY
        GROUP BY 1,2,3
        ORDER BY 1 DESC))
    GROUP BY 1,2
    ORDER BY 1 DESC)
UNION ALL
   (SELECT Cancelled_Date,
           'Total' AS Return_Reason,
           COUNT(DISTINCT ExternalOrderID ) AS ORDER_COUNT
    FROM
        ((SELECT A.Cancelled_Date
               ,A.Return_Reason
               ,B.ExternalOrderID
               ,SUM(ORIGINALQUANTITY)
               ,SUM(Quantity)
        FROM
            (Select soi.ExternalOrderID,Quantity,
            soi.UnitPrice * soi.Quantity as Cost,
            DATE(soi.DO_Cancelled) AS Cancelled_Date,
            DATE(soi.DO_CREATED) AS OrderDate,
            CASE WHEN DATEDIFF(minute, soi.OrderDate, soi.DO_Created) < 45 
            AND (ParentShipmentID = '0' OR ParentShipmentID is null) THEN 'Upfront Rejection (HD)' 
                        ELSE 'HD Store Rejection (Exception)' 
                        END AS Return_Reason
            from "KSFPA"."OMS"."STOREORDERITEMS" soi
            WHERE
              soi.DO_Created > '2020-06-29 00:00:00'
              and soi.DO_Created <  CONCAT(CURRENT_DATE()-1, ' 23:59:59')
              and soi.str_id ='9999'
              and soi.DO_Cancelled is not null
              and soi.DO_Cancelled < CONCAT(CURRENT_DATE()-1, ' 23:59:59')
            )A
        INNER JOIN
            (Select soi.ExternalOrderID,
                    DATE(soi.DO_CREATED) AS OrderDate,
                    SUM(ORIGINALQUANTITY) as ORIGINALQUANTITY
             from "KSFPA"."OMS"."STOREORDERITEMS" soi
             WHERE soi.DO_Created > '2020-06-29 00:00:00'
                   and soi.DO_Created <  CONCAT(CURRENT_DATE()-1, ' 23:59:59')
                   AND COALESCE(PARENTSHIPMENTID ,0) = 0
             GROUP BY 1,2)B
        ON A.ExternalOrderID= B.ExternalOrderID 
        AND A.OrderDate = B.OrderDate 
        WHERE Quantity=ORIGINALQUANTITY
        GROUP BY 1,2,3
        ORDER BY 1 DESC)
    UNION

        (SELECT A.Cancelled_Date
               ,A.Return_Reason
               ,B.ExternalOrderID
               ,SUM(ORIGINALQUANTITY)
               ,SUM(Quantity)
         FROM
              (Select soi.ExternalOrderID,
                      Quantity,
                      soi.UnitPrice * soi.Quantity as Cost, 
                      DATE(soi.DO_Cancelled) AS Cancelled_Date, 
                      DATE(soi.DO_CREATED) AS OrderDate,
                      CASE WHEN LTRIM(RTRIM(ModificationDescription)) = 'Cancelled'  
                           THEN (CASE WHEN DATEDIFF(minute, soi.OrderDate, soi.DO_Created) < 45 
                                      AND (ParentShipmentID = '0' OR ParentShipmentID is null) THEN 'Upfront Rejection (CC)'
                                      ELSE 'C&C Store Rejection (Exception)' END)
                            ELSE 'Click & Collect Store Rejection - Customer chose free delivery'
			          END AS Return_Reason
               FROM "KSFPA"."OMS"."STOREORDERITEMS" soi
               WHERE soi.DO_Created > '2020-06-29 00:00:00'
                  and soi.DO_Created < CONCAT(CURRENT_DATE()-1, ' 23:59:59')
                  and soi.str_id ='9996'
                  and soi.DO_Cancelled is not null
                  and soi.DO_Cancelled < CONCAT(CURRENT_DATE()-1, ' 23:59:59')
              )A
        INNER JOIN 
            (Select soi.ExternalOrderID,
                    SUM(ORIGINALQUANTITY) AS ORIGINALQUANTITY,
                    DATE(soi.DO_CREATED) AS OrderDate
             from "KSFPA"."OMS"."STOREORDERITEMS" soi
             WHERE soi.DO_Created >'2020-06-29 00:00:00'
                   and soi.DO_Created < CONCAT(CURRENT_DATE()-1, ' 23:59:59')
                   AND COALESCE(PARENTSHIPMENTID ,0) = 0
             GROUP BY 1,3)B
        ON A.ExternalOrderID= B.ExternalOrderID 
        AND A.OrderDate = B.OrderDate 
        WHERE Quantity=ORIGINALQUANTITY
        GROUP BY 1,2,3
        ORDER BY 1 DESC))
    GROUP BY 1,2
    ORDER BY 1 DESC);
	
	
---USed to calculate Cancellation $ value at state level
create or replace view KSFPA.ONLINE_UGAM_PVT.CANCELLED_ORDERS_STATE_SPLIT(
	CANCELLED_DATE,
	RETURN_REASON,
	NEW_STATE,
	COST
) as
SELECT Cancelled_Date
      ,Return_Reason
      ,NEW_STATE
      ,SUM(Cost) AS Cost
FROM
(SELECT soi.EXTERNALORDERID
      ,soi.UNITPRICE * soi.QUANTITY AS Cost
      ,TO_DATE(soi.DO_CANCELLED) AS Cancelled_Date
      ,co.BILLSTATE as State 
	  ,CASE WHEN DATEDIFF(minute, soi.ORDERDATE, soi.DO_CREATED) < 45 
              AND (PARENTSHIPMENTID = '0' OR PARENTSHIPMENTID is null) THEN 'Upfront Rejection (HD)'
	        ELSE 'HD Store Rejection (Exception)' 
	   END AS Return_Reason 
	  ,CASE 
		    WHEN co.BILLSTATE in ('Victoria', 'VIC') THEN 'VIC'
            WHEN co.BILLSTATE in ('Perth', 'WA') THEN 'WA'
            WHEN co.BILLSTATE in ('Queensland', 'QLD') THEN 'QLD'
            WHEN co.BILLSTATE in ('Wales', 'NSW') THEN 'NSW'
            WHEN co.BILLSTATE in ('Territory', 'NT') THEN 'NT'
            WHEN co.BILLSTATE in ('TAS') THEN 'TAS'
            WHEN co.BILLSTATE in ('ACT') THEN 'ACT'
            WHEN co.BILLSTATE in ('SA', 'SOUTH') THEN 'SA'
            WHEN co.BILLCOUNTRY in ('NZ') THEN 'NZ'
	   END AS NEW_STATE
FROM "KSFPA"."OMS"."STOREORDERITEMS" soi, "KSFPA"."OMS"."CUSTOMERORDER" co
WHERE
  soi.DO_CREATED > TO_TIMEStAMP(DATEADD(DAY, -90, current_date()))
  AND soi.DO_CREATED < DATEADD(s, -1, TO_TIMESTAMP(current_date()))
  AND soi.STR_ID ='9999'
  AND soi.ORDERID = co.OrderID
  AND soi.DO_CANCELLED is not null
  AND soi.DO_CANCELLED < DATEADD(s, -1, TO_TIMESTAMP(current_date()))
UNION ALL
SELECT soi.EXTERNALORDERID
      ,soi.UNITPRICE * soi.QUANTITY AS Cost
      ,TO_DATE(soi.DO_CANCELLED) AS Cancelled_Date
      ,co.BILLSTATE as State 
      ,CASE WHEN LTRIM(RTRIM(ModificationDescription)) = 'Cancelled'  
            THEN (CASE WHEN DATEDIFF(minute, soi.OrderDate, soi.DO_Created) < 45 
                       AND (ParentShipmentID = '0' OR ParentShipmentID is null) THEN 'Upfront Rejection (CC)'
                       ELSE 'C&C Store Rejection (Exception)' END)
       ELSE 'Click & Collect Store Rejection - Customer chose free delivery'
			END AS Return_Reason
	  ,CASE 
		    WHEN co.BILLSTATE in ('Victoria', 'VIC') THEN 'VIC'
            WHEN co.BILLSTATE in ('Perth', 'WA') THEN 'WA'
            WHEN co.BILLSTATE in ('Queensland', 'QLD') THEN 'QLD'
            WHEN co.BILLSTATE in ('Wales', 'NSW') THEN 'NSW'
            WHEN co.BILLSTATE in ('Territory', 'NT') THEN 'NT'
            WHEN co.BILLSTATE in ('TAS') THEN 'TAS'
            WHEN co.BILLSTATE in ('ACT') THEN 'ACT'
            WHEN co.BILLSTATE in ('SA', 'SOUTH') THEN 'SA'
            WHEN co.BILLCOUNTRY in ('NZ') THEN 'NZ'
	   END AS NEW_STATE
FROM "KSFPA"."OMS"."STOREORDERITEMS" soi, "KSFPA"."OMS"."CUSTOMERORDER" co
WHERE soi.DO_CREATED > TO_TIMEStAMP(DATEADD(DAY, -90, current_date()))
  AND soi.DO_CREATED < DATEADD(s, -1, TO_TIMESTAMP(current_date()))
  AND soi.STR_ID ='9996'
  AND soi.ORDERID = co.ORDERID
  AND soi.DO_CANCELLED is not null
  AND soi.DO_CANCELLED < DATEADD(s, -1, TO_TIMESTAMP(current_date()))
UNION ALL
  SELECT soi.EXTERNALORDERID
      ,soi.UNITPRICE * soi.QUANTITY AS Cost
      ,TO_DATE(soi.DO_CANCELLED) AS Cancelled_Date
      ,co.BILLSTATE as State 
      ,'Ready to Collect Order Not Collected' AS Return_Reason
  	  ,CASE 
		    WHEN co.BILLSTATE in ('Victoria', 'VIC') THEN 'VIC'
            WHEN co.BILLSTATE in ('Perth', 'WA') THEN 'WA'
            WHEN co.BILLSTATE in ('Queensland', 'QLD') THEN 'QLD'
            WHEN co.BILLSTATE in ('Wales', 'NSW') THEN 'NSW'
            WHEN co.BILLSTATE in ('Territory', 'NT') THEN 'NT'
            WHEN co.BILLSTATE in ('TAS') THEN 'TAS'
            WHEN co.BILLSTATE in ('ACT') THEN 'ACT'
            WHEN co.BILLSTATE in ('SA', 'SOUTH') THEN 'SA'
            WHEN co.BILLCOUNTRY in ('NZ') THEN 'NZ'
	   END AS NEW_STATE
FROM "KSFPA"."OMS"."STOREORDERITEMS" soi, "KSFPA"."OMS"."CUSTOMERORDER" co
WHERE soi.DO_CANCELLED > TO_TIMEStAMP(DATEADD(DAY, -90, current_date()))
  AND soi.DO_CANCELLED <DATEADD(s, -1, TO_TIMESTAMP(current_date()))
  AND LTRIM(RTRIM(soi.SHIPSTATUS)) = 'ItemCancelled'
  AND LTRIM(RTRIM(QUANTITYREADYTOCOLLECT)) > 0
  AND soi.ORDERID = co.ORDERID
  AND soi.DO_CANCELLED is not null
ORDER BY 1 ASC)
GROUP BY 1,2,3;


create or replace view KSFPA.ONLINE_UGAM_PVT.CANCELLED_ORDERS_AMOUNT_ORDERSHARE(
	YEAR,
	PERIOD,
	WEEK,
	CANCELLED_DATE,
	FY_PERIOD_WEEK,
	STORE_CANCELLATION_AMOUNT,
	STORE_CANCELLATION_ORDERSHARE,
	UPFRONT_CANCELLATION_AMOUT,
	UPFRONT_CANCELLATION_ORDERSHARE,
	TOTAL_STORE_UPFRONT_CANCELLATION_AMOUNT,
	TOTAL_STORE_UPFRONT_CANCELLATION_ORDERSHARE
) as
SELECT T1.YEAR,
T1.PERIOD,
T1.WEEK,
T1.CANCELLED_DATE,
CONCAT('FY',RIGHT(T1.YEAR,2),'P',T1.PERIOD,'W',T1.WEEK) AS FY_PERIOD_WEEK,
coalesce(T3.STORE_CANCELLATION_AMOUNT,0) as STORE_CANCELLATION_AMOUNT,
coalesce(T1.STORE_CANCELLATION_ORDERSHARE,0) as STORE_CANCELLATION_ORDERSHARE,
coalesce(T3.UPFRONT_CANCELLATION_AMOUT,0) as UPFRONT_CANCELLATION_AMOUT,
coalesce(T2.UPFRONT_CANCELLATION_ORDERSHARE,0) as UPFRONT_CANCELLATION_ORDERSHARE,
SUM(T3.STORE_CANCELLATION_AMOUNT+T3.UPFRONT_CANCELLATION_AMOUT) AS TOTAL_STORE_UPFRONT_CANCELLATION_AMOUNT,
SUM(coalesce(T1.STORE_CANCELLATION_ORDERSHARE,0)+coalesce(T2.UPFRONT_CANCELLATION_ORDERSHARE,0))
    AS TOTAL_STORE_UPFRONT_CANCELLATION_ORDERSHARE
FROM KSFPA.ONLINE_UGAM_PVT.CANCELLED_ORDERS_STORE_CANCELLATION_ORDERSHARE T1
LEFT JOIN KSFPA.ONLINE_UGAM_PVT.CANCELLED_ORDERS_UPFRONT_CANCELLATION_ORDERSHARE T2 ON T1.CANCELLED_DATE=T2.CANCELLED_DATE
INNER JOIN (SELECT  CANCELLED_DATE,
SUM(CASE WHEN Return_Reason IN ('HD Store Rejection (Exception)',
                            'Click & Collect Store Rejection - Customer chose free delivery',
                           'C&C Store Rejection (Exception)',
						   'Ready to Collect Order Not Collected') THEN cost END ) AS STORE_CANCELLATION_AMOUNT,
coalesce(SUM(CASE WHEN Return_Reason IN ('Upfront Rejection (HD)') THEN cost END ), 0) AS UPFRONT_CANCELLATION_AMOUT
FROM KSFPA.ONLINE_UGAM_PVT.CANCELLED_ORDERS_MAIN
GROUP BY CANCELLED_DATE) T3 ON T1.CANCELLED_DATE=T3.CANCELLED_DATE
GROUP BY T1.YEAR,
T1.PERIOD,
T1.WEEK,
T1.CANCELLED_DATE,
T3.STORE_CANCELLATION_AMOUNT,
T1.STORE_CANCELLATION_ORDERSHARE,
T3.UPFRONT_CANCELLATION_AMOUT,
T2.UPFRONT_CANCELLATION_ORDERSHARE
;

create or replace view KSFPA.ONLINE_UGAM_PVT.CANCELLED_ORDERS_DIM_TABLE(
	CANCELLED_DATE,
	YEAR,
	WEEK,
	PERIOD,
	PERIOD_WEEK,
	FY_PERIOD_WEEK,
	PERIOD_NUMBER
) as 
SELECT CANCELLED_DATE,
YEAR,
WEEK,
PERIOD,
CONCAT('P',PERIOD,' - ','W',WEEK) AS PERIOD_WEEK,
CONCAT('FY',RIGHT(YEAR,2),'P',PERIOD,'W',WEEK) AS FY_PERIOD_WEEK,
CONCAT('P',PERIOD) AS PERIOD_NUMBER
FROM 
(
SELECT DISTINCT T1.CANCELLED_DATE,T1.YEAR,T1.WEEK,T1.PERIOD
  
FROM KSFPA.ONLINE_UGAM_PVT.CANCELLED_ORDERS_MAIN T1
LEFT JOIN  KSFPA.ONLINE_UGAM_PVT.CANCELLED_ORDERS_STORE_CANCELLATION_ORDERSHARE T2 ON T1.CANCELLED_DATE=T2.CANCELLED_DATE
LEFT JOIN  KSFPA.ONLINE_UGAM_PVT.CANCELLED_ORDERS_UPFRONT_CANCELLATION_ORDERSHARE T3 ON T1.CANCELLED_DATE=T3.CANCELLED_DATE);