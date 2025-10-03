DELIMITER $$

CREATE PROCEDURE usp_PostReceipt(IN p_ReceiptId INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error posting receipt';
    END;

    START TRANSACTION;

    -- Validate receipt exists
    IF NOT EXISTS(SELECT 1 FROM Receipts WHERE ReceiptId = p_ReceiptId) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Receipt not found';
    END IF;

    -- Insert inventory movements
    INSERT INTO InventoryLedger (ItemId, TxnType, QtySigned, TxnRef, TxnDate)
    SELECT 
        pol.ItemId,
        'R',
        rl.QtyReceived,
        CONCAT('Receipt:', r.ReceiptId),
        NOW()
    FROM ReceiptLines rl
    JOIN Receipts r ON rl.ReceiptId = r.ReceiptId
    JOIN PurchaseOrderLines pol ON rl.PoLineId = pol.PoLineId
    WHERE rl.ReceiptId = p_ReceiptId;

    COMMIT;
END$$

DELIMITER ;
