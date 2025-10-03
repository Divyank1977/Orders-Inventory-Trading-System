SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE InventoryLedger;
TRUNCATE TABLE ShipmentLines;
TRUNCATE TABLE Shipments;
TRUNCATE TABLE SalesOrderLines;
TRUNCATE TABLE SalesOrders;
TRUNCATE TABLE ReceiptLines;
TRUNCATE TABLE Receipts;
TRUNCATE TABLE PurchaseOrderLines;
TRUNCATE TABLE PurchaseOrders;
TRUNCATE TABLE Customers;
TRUNCATE TABLE Vendors;
TRUNCATE TABLE Items;
TRUNCATE TABLE Users;

SET FOREIGN_KEY_CHECKS = 1;

-- Vendors
INSERT INTO Vendors(Name, City) VALUES
('Alpha Traders', 'Delhi'),
('Beta Supplies', 'Mumbai');

-- Customers
INSERT INTO Customers(Name, City, Segment) VALUES
('RetailMart', 'Gurgaon', 'Retail'),
('WholesaleCo', 'Delhi', 'Wholesale'),
('ShopOne', 'Faridabad', 'Retail'),
('DistributorX', 'Noida', 'Wholesale'),
('OnlineBuyer', 'Gurgaon', 'Online');



-- Items
INSERT INTO Items(Sku, Name, Category, UnitPrice, Active) VALUES
('SKU-100', 'Widget A', 'Gadgets', 150.00, TRUE),
('SKU-101', 'Widget B', 'Gadgets', 200.00, TRUE),
('SKU-200', 'Cable 1m', 'Accessories', 50.00, TRUE);

-- Purchase Order
INSERT INTO PurchaseOrders(PoNo, VendorId, PoDate, Status) 
VALUES ('PO-1001', 1, '2025-09-05', 'Closed');
SET @po1 = LAST_INSERT_ID();

INSERT INTO PurchaseOrderLines(PoId, ItemId, QtyOrdered, UnitCost) 
VALUES (@po1, 1, 100, 90.00), 
       (@po1, 2, 50, 120.00);

-- Receipt
INSERT INTO Receipts(PoId, ReceiptDate) VALUES (@po1, '2025-09-07');
SET @r1 = LAST_INSERT_ID();

INSERT INTO ReceiptLines(ReceiptId, PoLineId, QtyReceived) 
SELECT @r1, PoLineId, QtyOrdered 
FROM PurchaseOrderLines WHERE PoId=@po1;

-- Sales Order
INSERT INTO SalesOrders(SoNo, CustomerId, SoDate, Status) 
VALUES ('SO-9001', 1, '2025-09-10', 'Open');
SET @so1 = LAST_INSERT_ID();

INSERT INTO SalesOrderLines(SoId, ItemId, QtyOrdered, UnitPrice) 
VALUES (@so1, 1, 10, 150.00);

-- Shipment
INSERT INTO Shipments(SoId, ShipDate) VALUES (@so1, '2025-09-11');
SET @sh1 = LAST_INSERT_ID();

INSERT INTO ShipmentLines(ShipId, SoLineId, QtyShipped) 
SELECT @sh1, SoLineId, QtyOrdered 
FROM SalesOrderLines WHERE SoId=@so1;

-- Post transactions
CALL usp_PostReceipt(@r1);
CALL usp_PostShipment(@sh1);

select* from receipts
