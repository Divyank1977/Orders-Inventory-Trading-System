CREATE OR REPLACE VIEW vw_StockOnHand AS
SELECT 
    i.ItemId,
    i.Sku,
    i.Name,
    COALESCE(SUM(l.QtySigned),0) AS QtyOnHand
FROM Items i
LEFT JOIN InventoryLedger l ON i.ItemId = l.ItemId
GROUP BY i.ItemId, i.Sku, i.Name;


-- For fast stock queries
CREATE INDEX IX_InventoryLedger_Item_TxnDate
    ON InventoryLedger(ItemId, TxnDate);

-- For shipment detail lookups
CREATE INDEX IX_ShipmentLines_SoLineId
    ON ShipmentLines(SoLineId);
