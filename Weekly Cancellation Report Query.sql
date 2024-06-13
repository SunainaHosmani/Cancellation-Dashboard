create or replace view KSFPA.ONLINE_UGAM_PVT.CANCELLED_ORDERS_MAIN_KEYCODE_LEVEL(
	CANCELLED_DATE,
	CANCELLED_DATETIME,
	ORDERID,
	STR_ID,
	LOCATION_NAME,
	PRODUCT_KEYCODE,
	PRODUCT_DESCRIPTION,
	RBU_DESCRIPTION,
	DEPARTMENT_DESCRIPTION,
	DEPARTMENT_CODE,
	RBU_CODE,
	EXTERNALORDERID,
	STATE,
	RETURN_REASON,
	COST,
	UNITS
) as
SELECT 
CANCELLED_DATE,
Cancelled_DateTime,
ORDERID,
STR_ID,
LOCATION_NAME,
PRODUCT_KEYCODE,
PRODUCT_DESCRIPTION,
PROD.RBU_DESCRIPTION,
PROD.DEPARTMENT_DESCRIPTION,
DEPARTMENT_CODE,
RBU_CODE,
EXTERNALORDERID,
A.STATE,
RETURN_REASON,
SUM(COST) AS COST,
SUM(UNITS) AS UNITS
FROM
(
select 
Cancelled_Date,
Cancelled_DateTime,
ExternalOrderID,
ORDERID,
str_id,
STATE,
SKU,
sum(cost) as cost,
sum(units) as units,
Return_Reason

FROM 
(
Select soi.ExternalOrderID,
soi.ORDERID,
soi.str_id ,
cust.shipstate as STATE,
soi.SKU,
QUANTITY as units,
soi.UnitPrice * soi.Quantity as Cost,
DATE(soi.DO_Cancelled) AS Cancelled_Date,
TO_VARCHAR(soi.DO_Cancelled,'YYYY/MM/DD HH24:MI:SS') AS Cancelled_DateTime,
CASE WHEN DATEDIFF(minute, soi.OrderDate, soi.DO_Created) < 45 
AND (ParentShipmentID = '0' OR ParentShipmentID is null) THEN 'Upfront Rejection (HD)' 
			ELSE 'HD Store Rejection (Exception)' 
			END AS Return_Reason
from "KSFPA"."OMS"."STOREORDERITEMS" soi
LEFT JOIN KSFPA.OMS.CUSTOMERORDER cust
ON soi.EXTERNALORDERID = cust.EXTERNALORDERID
    AND soi.ORDERID = cust.ORDERID
WHERE
  soi.DO_Created > '2023-06-26 00:00:00'
  and soi.DO_Created <  CONCAT(CURRENT_DATE()-1, ' 23:59:59')
  and soi.str_id ='9999'
  and soi.DO_Cancelled is not null
  and soi.DO_Cancelled < CONCAT(CURRENT_DATE()-1, ' 23:59:59')
  
UNION ALL
  
Select soi.ExternalOrderID,
soi.ORDERID,
soi.STR_ID,
cust.shipstate as STATE,
soi.SKU, 
quantity as units,
soi.UnitPrice * soi.Quantity as Cost, 
DATE(soi.DO_Cancelled) AS Cancelled_Date ,
TO_VARCHAR(soi.DO_Cancelled,'YYYY/MM/DD HH24:MI:SS') AS Cancelled_DateTime,
CASE WHEN LTRIM(RTRIM(ModificationDescription)) = 'Cancelled'  
      THEN (CASE WHEN DATEDIFF(minute, soi.OrderDate, soi.DO_Created) < 45 
      AND (ParentShipmentID = '0' OR ParentShipmentID is null) THEN 'Upfront Rejection (CC)'
      ELSE 'C&C Store Rejection (Exception)' END)
ELSE 'Click & Collect Store Rejection - Customer chose free delivery'
			END AS Return_Reason
from "KSFPA"."OMS"."STOREORDERITEMS" soi
LEFT JOIN KSFPA.OMS.CUSTOMERORDER cust
ON soi.EXTERNALORDERID = cust.EXTERNALORDERID
    AND soi.ORDERID = cust.ORDERID
WHERE
  soi.DO_Created > '2023-06-26 00:00:00'
  and soi.DO_Created < CONCAT(CURRENT_DATE()-1, ' 23:59:59')
  and soi.str_id ='9996'
  and soi.DO_Cancelled is not null
  and soi.DO_Cancelled < CONCAT(CURRENT_DATE()-1, ' 23:59:59')
) 
group by Cancelled_Date,
Cancelled_DateTime,
ExternalOrderID,
ORDERID,
str_id,
STATE,
SKU,
Return_Reason
order by Cancelled_Date
)A
LEFT JOIN KSF_SOPHIA_DATA_INTELLIGENCE_HUB_PROD.COMMON_DIMENSIONS.DIM_PRODUCT PROD
ON TO_VARCHAR(A.SKU) = TO_VARCHAR(PROD.PRODUCT_KEYCODE)
LEFT JOIN KSF_SOPHIA_DATA_INTELLIGENCE_HUB_PROD.COMMON_DIMENSIONS.DIM_LOCATION LOC
ON TO_VARCHAR(A.STR_ID) = TO_VARCHAR(LOC.LOCATION_CODE)
-- LEFT JOIN KSF_SOPHIA_DATA_INTELLIGENCE_HUB_PROD.COMMON_DIMENSIONS.DIM_DATE DAT
-- ON A.CANCELLED_DATE = DAT.DATE
WHERE TO_VARCHAR(PRODUCT_KEYCODE) != ('undefined')
AND TO_VARCHAR(LOC.LOCATION_CODE) != ('undefined')
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14
ORDER BY 1;


---Used to get the recieved units for the orders that are cancelled
create or replace view KSFPA.ONLINE_UGAM_PVT.CANCELLED_ORDERS_RECD_UNITS(
	CANCELLED_DATE,
	EXTERNALORDERID,
	ORDERID,
	PRODUCT_KEYCODE,
	ORIGINALQUANTITY
) as
SELECT DISTINCT can.CANCELLED_DATE,can.EXTERNALORDERID,can.ORDERID,can.PRODUCT_KEYCODE,soi.ORIGINALQUANTITY
FROM KSFPA.ONLINE_UGAM_PVT.CANCELLED_ORDERS_MAIN_KEYCODE_LEVEL can
LEFT JOIN KSFPA.OMS.STOREORDERITEMS soi
ON can.externalorderid = soi.externalorderid
-- AND can.orderid = soi.orderid
AND can.PRODUCT_KEYCODE = soi.SKU
WHERE (PARENTSHIPMENTID = '0' 
OR PARENTSHIPMENTID = NULL)
AND can.CANCELLED_DATE > '2023-06-26'
AND can.CANCELLED_DATE < CURRENT_DATE()-1
AND soi.STR_ID NOT IN ('9996','9999');