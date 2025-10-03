-- Drop in correct order if re-running
DROP TABLE IF EXISTS InventoryLedger, ShipmentLines, Shipments, SalesOrderLines, SalesOrders,
    ReceiptLines, Receipts, PurchaseOrderLines, PurchaseOrders,
    Users, Customers, Vendors, Items;

-- Items
CREATE TABLE Items (
  ItemId INT AUTO_INCREMENT PRIMARY KEY,
  Sku VARCHAR(50) NOT NULL UNIQUE,
  Name VARCHAR(200) NOT NULL,
  Category VARCHAR(100),
  UnitPrice DECIMAL(12,2),
  Active BOOLEAN NOT NULL DEFAULT TRUE
);

-- Vendors
CREATE TABLE Vendors (
  VendorId INT AUTO_INCREMENT PRIMARY KEY,
  Name VARCHAR(200) NOT NULL,
  City VARCHAR(100)
);

-- Customers
CREATE TABLE Customers (
  CustomerId INT AUTO_INCREMENT PRIMARY KEY,
  Name VARCHAR(200) NOT NULL,
  City VARCHAR(100),
  Segment VARCHAR(50)
);

-- Purchase Orders
CREATE TABLE PurchaseOrders (
  PoId INT AUTO_INCREMENT PRIMARY KEY,
  PoNo VARCHAR(50) NOT NULL UNIQUE,
  VendorId INT NOT NULL,
  PoDate DATE NOT NULL,
  Status VARCHAR(20) NOT NULL DEFAULT 'Open',
  FOREIGN KEY (VendorId) REFERENCES Vendors(VendorId)
);

-- Purchase Order Lines
CREATE TABLE PurchaseOrderLines (
  PoLineId INT AUTO_INCREMENT PRIMARY KEY,
  PoId INT NOT NULL,
  ItemId INT NOT NULL,
  QtyOrdered INT NOT NULL,
  UnitCost DECIMAL(12,2) NOT NULL,
  FOREIGN KEY (PoId) REFERENCES PurchaseOrders(PoId) ON DELETE CASCADE,
  FOREIGN KEY (ItemId) REFERENCES Items(ItemId)
);

-- Receipts
CREATE TABLE Receipts (
  ReceiptId INT AUTO_INCREMENT PRIMARY KEY,
  PoId INT NOT NULL,
  ReceiptDate DATE NOT NULL,
  FOREIGN KEY (PoId) REFERENCES PurchaseOrders(PoId)
);

-- Receipt Lines
CREATE TABLE ReceiptLines (
  ReceiptLineId INT AUTO_INCREMENT PRIMARY KEY,
  ReceiptId INT NOT NULL,
  PoLineId INT NOT NULL,
  QtyReceived INT NOT NULL,
  FOREIGN KEY (ReceiptId) REFERENCES Receipts(ReceiptId) ON DELETE CASCADE,
  FOREIGN KEY (PoLineId) REFERENCES PurchaseOrderLines(PoLineId)
);

-- Sales Orders
CREATE TABLE SalesOrders (
  SoId INT AUTO_INCREMENT PRIMARY KEY,
  SoNo VARCHAR(50) NOT NULL UNIQUE,
  CustomerId INT NOT NULL,
  SoDate DATE NOT NULL,
  Status VARCHAR(20) NOT NULL DEFAULT 'Open',
  FOREIGN KEY (CustomerId) REFERENCES Customers(CustomerId)
);

-- Sales Order Lines
CREATE TABLE SalesOrderLines (
  SoLineId INT AUTO_INCREMENT PRIMARY KEY,
  SoId INT NOT NULL,
  ItemId INT NOT NULL,
  QtyOrdered INT NOT NULL,
  UnitPrice DECIMAL(12,2) NOT NULL,
  FOREIGN KEY (SoId) REFERENCES SalesOrders(SoId) ON DELETE CASCADE,
  FOREIGN KEY (ItemId) REFERENCES Items(ItemId)
);

-- Shipments
CREATE TABLE Shipments (
  ShipId INT AUTO_INCREMENT PRIMARY KEY,
  SoId INT NOT NULL,
  ShipDate DATE NOT NULL,
  FOREIGN KEY (SoId) REFERENCES SalesOrders(SoId)
);

-- Shipment Lines
CREATE TABLE ShipmentLines (
  ShipLineId INT AUTO_INCREMENT PRIMARY KEY,
  ShipId INT NOT NULL,
  SoLineId INT NOT NULL,
  QtyShipped INT NOT NULL,
  FOREIGN KEY (ShipId) REFERENCES Shipments(ShipId) ON DELETE CASCADE,
  FOREIGN KEY (SoLineId) REFERENCES SalesOrderLines(SoLineId)
);

-- Inventory Ledger
CREATE TABLE InventoryLedger (
  LedgerId BIGINT AUTO_INCREMENT PRIMARY KEY,
  ItemId INT NOT NULL,
  TxnType ENUM('R','S','A') NOT NULL, -- Receipt, Shipment, Adjustment
  QtySigned INT NOT NULL,
  TxnRef VARCHAR(100),
  TxnDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (ItemId) REFERENCES Items(ItemId)
);

-- Users
CREATE TABLE Users (
  UserId INT AUTO_INCREMENT PRIMARY KEY,
  Username VARCHAR(100) NOT NULL UNIQUE,
  PasswordHash VARBINARY(255) NOT NULL,
  Role VARCHAR(20) NOT NULL
);

