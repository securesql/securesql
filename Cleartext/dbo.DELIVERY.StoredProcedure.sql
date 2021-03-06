USE [tpcc]
GO
/****** Object:  StoredProcedure [dbo].[DELIVERY]    Script Date: 5/15/2013 7:03:42 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DELIVERY]
@d_w_id INT, @d_o_carrier_id INT, @TIMESTAMP DATETIME2 (0)
AS
BEGIN
    DECLARE @d_no_o_id AS INT, 
@d_d_id AS INT, 
@d_c_id AS INT, 
@d_ol_total AS INT,
@d_c_balance as MONEY;
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @loop_counter AS INT;
        SET @loop_counter = 1;
        WHILE @loop_counter <= 10
            BEGIN
                SET @d_d_id = @loop_counter;
                SELECT TOP (1) @d_no_o_id = NEW_ORDER.NO_O_ID
                FROM   dbo.NEW_ORDER WITH (SERIALIZABLE, UPDLOCK)
                WHERE  NEW_ORDER.NO_W_ID = @d_w_id
                       AND NEW_ORDER.NO_D_ID = @d_d_id;
                DELETE dbo.NEW_ORDER
                WHERE  NO_W_ID = @d_w_id
                       AND NO_D_ID = @d_d_id
                       AND NO_O_ID = @d_no_o_id;
                SELECT @d_c_id = ORDERS.O_C_ID
                FROM   dbo.ORDERS
                WHERE  ORDERS.O_ID = @d_no_o_id
                       AND ORDERS.O_D_ID = @d_d_id
                       AND ORDERS.O_W_ID = @d_w_id;
                UPDATE  dbo.ORDERS
                    SET O_CARRIER_ID = @d_o_carrier_id
                WHERE   ORDERS.O_ID = @d_no_o_id
                        AND ORDERS.O_D_ID = @d_d_id
                        AND ORDERS.O_W_ID = @d_w_id;
                UPDATE  dbo.ORDER_LINE
                    SET OL_DELIVERY_D = @TIMESTAMP
                WHERE   ORDER_LINE.OL_O_ID = @d_no_o_id
                        AND ORDER_LINE.OL_D_ID = @d_d_id
                        AND ORDER_LINE.OL_W_ID = @d_w_id;
                SELECT @d_ol_total = sum(ORDER_LINE.OL_AMOUNT)
                FROM   dbo.ORDER_LINE
                WHERE  ORDER_LINE.OL_O_ID = @d_no_o_id
                       AND ORDER_LINE.OL_D_ID = @d_d_id
                       AND ORDER_LINE.OL_W_ID = @d_w_id;
				SELECT @d_c_balance = CUSTOMER.C_BALANCE
				FROM dbo.CUSTOMER
						WHERE   CUSTOMER.C_ID = @d_c_id
								AND CUSTOMER.C_D_ID = @d_d_id
								AND CUSTOMER.C_W_ID = @d_w_id;
				SELECT @d_c_balance = @d_c_balance + @d_ol_total
				UPDATE  dbo.CUSTOMER
					SET C_BALANCE = @d_c_balance
				WHERE   CUSTOMER.C_ID = @d_c_id
						AND CUSTOMER.C_D_ID = @d_d_id
						AND CUSTOMER.C_W_ID = @d_w_id;
                IF @@TRANCOUNT > 0
                    COMMIT TRANSACTION;
                PRINT 'D: ' + ISNULL(CAST (@d_d_id AS NVARCHAR (MAX)), '') + 'O: ' + ISNULL(CAST (@d_no_o_id AS NVARCHAR (MAX)), '') + 'time ' + ISNULL(CAST (@TIMESTAMP AS NVARCHAR (MAX)), '');
                SET @loop_counter = @loop_counter + 1;
            END
        SELECT @d_w_id AS N'@d_w_id',
               @d_o_carrier_id AS N'@d_o_carrier_id',
               @TIMESTAMP AS N'@TIMESTAMP';
    END TRY
    BEGIN CATCH
        SELECT ERROR_NUMBER() AS ErrorNumber,
               ERROR_SEVERITY() AS ErrorSeverity,
               ERROR_STATE() AS ErrorState,
               ERROR_PROCEDURE() AS ErrorProcedure,
               ERROR_LINE() AS ErrorLine,
               ERROR_MESSAGE() AS ErrorMessage;
        IF @@TRANCOUNT > 0
            ROLLBACK;
    END CATCH;
    IF @@TRANCOUNT > 0
        COMMIT TRANSACTION;
END
GO
