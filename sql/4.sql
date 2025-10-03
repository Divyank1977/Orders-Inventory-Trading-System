DROP PROCEDURE IF EXISTS usp_PostShipment;
DELIMITER $$
CREATE PROCEDURE usp_PostShipment(IN p_ShipId INT)
BEGIN
  DECLARE v_count INT DEFAULT 0;
  DECLARE v_itemId INT;
  DECLARE v_msg TEXT;

  -- Any SQL error will jump to EXIT HANDLER
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error posting shipment';
  END;

  START TRANSACTION;

  IF NOT EXISTS(SELECT 1 FROM Shipments WHERE ShipId = p_ShipId) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Shipment not found';
  END IF;

  -- Temporary aggregated changes per item
  CREATE TEMPORARY TABLE IF NOT EXISTS tmp_changes (
    ItemId INT NOT NULL PRIMARY KEY,
    QtyChange INT NOT NULL
  ) ENGINE=MEMORY;

  TRUNCATE TABLE tmp_changes;

  INSERT INTO tmp_changes (ItemId, QtyChange)
  SELECT sol.ItemId, SUM(-sl.QtyShipped) AS QtyChange
  FROM ShipmentLines sl
  JOIN SalesOrderLines sol ON sl.SoLineId = sol.SoLineId
  WHERE sl.ShipId = p_ShipId
  GROUP BY sol.ItemId;

  -- Check any item would go negative if we apply the change
  SELECT COUNT(*) INTO v_count
  FROM (
    SELECT t.ItemId,
           COALESCE(il.CurrentQty,0) + t.QtyChange AS NewQty
    FROM tmp_changes t
    LEFT JOIN (
      SELECT ItemId, COALESCE(SUM(QtySigned),0) AS CurrentQty
      FROM InventoryLedger
      GROUP BY ItemId
    ) il ON il.ItemId = t.ItemId
  ) x
  WHERE x.NewQty < 0;

  IF v_count > 0 THEN
    -- get first failing item for a useful message
    SELECT t.ItemId INTO v_itemId
    FROM tmp_changes t
    LEFT JOIN (
      SELECT ItemId, COALESCE(SUM(QtySigned),0) AS CurrentQty
      FROM InventoryLedger
      GROUP BY ItemId
    ) il ON il.ItemId = t.ItemId
    WHERE (COALESCE(il.CurrentQty,0) + t.QtyChange) < 0
    LIMIT 1;

    SET v_msg = CONCAT('Insufficient stock for ItemId=', v_itemId);
    DROP TEMPORARY TABLE IF EXISTS tmp_changes;
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  -- Safe to insert ledger entries (one statement)
  INSERT INTO InventoryLedger (ItemId, TxnType, QtySigned, TxnRef, TxnDate)
  SELECT sol.ItemId, 'S', -sl.QtyShipped, CONCAT('Shipment:', p_ShipId), NOW()
  FROM ShipmentLines sl
  JOIN SalesOrderLines sol ON sl.SoLineId = sol.SoLineId
  WHERE sl.ShipId = p_ShipId;

  DROP TEMPORARY TABLE IF EXISTS tmp_changes;
  COMMIT;
END$$
DELIMITER ;
