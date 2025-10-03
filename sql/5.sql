DELIMITER $$

CREATE PROCEDURE usp_TopItemsByMargin(
    IN p_StartDate DATE, 
    IN p_EndDate DATE, 
    IN p_TopN INT
)
BEGIN
    SELECT 
        i.ItemId,
        i.Sku,
        i.Name,
        SUM(sol.UnitPrice * sol.QtyOrdered) AS TotalRevenue,
        SUM(IFNULL(po.UnitCost,0) * sol.QtyOrdered) AS TotalCost,
        SUM(sol.UnitPrice * sol.QtyOrdered) - SUM(IFNULL(po.UnitCost,0) * sol.QtyOrdered) AS RealizedMargin
    FROM SalesOrders so
    JOIN SalesOrderLines sol ON so.SoId = sol.SoId
    JOIN Items i ON i.ItemId = sol.ItemId
    LEFT JOIN (
        SELECT pol.ItemId, pol.UnitCost
        FROM PurchaseOrderLines pol
        JOIN PurchaseOrders po ON pol.PoId = po.PoId
        WHERE (po.PoDate, pol.ItemId) IN (
            SELECT MAX(po2.PoDate), pol2.ItemId
            FROM PurchaseOrders po2
            JOIN PurchaseOrderLines pol2 ON po2.PoId = pol2.PoId
            GROUP BY pol2.ItemId
        )
    ) po ON po.ItemId = i.ItemId
    WHERE so.SoDate BETWEEN p_StartDate AND p_EndDate
    GROUP BY i.ItemId, i.Sku, i.Name
    ORDER BY RealizedMargin DESC
    LIMIT p_TopN;
END$$

DELIMITER ;
