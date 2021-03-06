USE [tpcc]
GO
/****** Object:  StoredProcedure [dbo].[OSTAT]    Script Date: 5/15/2013 7:03:42 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[OSTAT]
@os_w_id INT, @os_d_id INT, @os_c_id INT, @byname INT, @os_c_last CHAR (20)
AS
BEGIN
DECLARE 
@os_c_first AS CHAR (16), 
@os_c_middle AS CHAR (2), 
@os_c_balance AS MONEY, 
@os_o_id AS INT, 
@os_entdate AS DATETIME2 (0), 
@os_o_carrier_id AS INT, 
@os_ol_i_id AS INT, 
@os_ol_supply_w_id AS INT, 
@os_ol_quantity AS INT, 
@os_ol_amount AS INT, 
@os_ol_delivery_d AS DATE, 
@namecnt AS INT, 
@i AS INT, 
@os_ol_i_id_array AS VARCHAR (200), 
@os_ol_supply_w_id_array AS VARCHAR (200), 
@os_ol_quantity_array AS VARCHAR (200), 
@os_ol_amount_array AS VARCHAR (200), 
@os_ol_delivery_d_array AS VARCHAR (210);
    BEGIN TRANSACTION;
    BEGIN TRY
        SET @os_ol_i_id_array = 'CSV,';
        SET @os_ol_supply_w_id_array = 'CSV,';
        SET @os_ol_quantity_array = 'CSV,';
        SET @os_ol_amount_array = 'CSV,';
        SET @os_ol_delivery_d_array = 'CSV,';
        IF (@byname = 1)
            BEGIN
                SELECT @namecnt = count_big(CUSTOMER.C_ID)
                FROM   dbo.CUSTOMER
                WHERE  CUSTOMER.C_LAST = @os_c_last
                       AND CUSTOMER.C_D_ID = @os_d_id
                       AND CUSTOMER.C_W_ID = @os_w_id;
                IF ((@namecnt % 2) = 1)
                    SET @namecnt = (@namecnt + 1);
                DECLARE c_name CURSOR LOCAL
                    FOR SELECT   CUSTOMER.C_BALANCE,
                                 CUSTOMER.C_FIRST,
                                 CUSTOMER.C_MIDDLE,
                                 CUSTOMER.C_ID
                        FROM     dbo.CUSTOMER
                        WHERE    CUSTOMER.C_LAST = @os_c_last
                                 AND CUSTOMER.C_D_ID = @os_d_id
                                 AND CUSTOMER.C_W_ID = @os_w_id;
                        -- ORDER BY CUSTOMER.C_FIRST;
                OPEN c_name;
                BEGIN
                    DECLARE @loop_counter AS INT;
                    SET @loop_counter = 0;
                    DECLARE @loop$bound AS INT;
                    SET @loop$bound = (@namecnt / 2);
                    WHILE @loop_counter <= @loop$bound
                        BEGIN
                            FETCH c_name INTO @os_c_balance, @os_c_first, @os_c_middle, @os_c_id;
                            SET @loop_counter = @loop_counter + 1;
                        END
                END
                CLOSE c_name;
                DEALLOCATE c_name;
            END
        ELSE
            BEGIN
                SELECT @os_c_balance = CUSTOMER.C_BALANCE,
                       @os_c_first = CUSTOMER.C_FIRST,
                       @os_c_middle = CUSTOMER.C_MIDDLE,
                       @os_c_last = CUSTOMER.C_LAST
                FROM   dbo.CUSTOMER WITH (REPEATABLEREAD)
                WHERE  CUSTOMER.C_ID = @os_c_id
                       AND CUSTOMER.C_D_ID = @os_d_id
                       AND CUSTOMER.C_W_ID = @os_w_id;
            END
        BEGIN
            SELECT TOP (1) @os_o_id = fci.O_ID,
                           @os_o_carrier_id = fci.O_CARRIER_ID,
                           @os_entdate = fci.O_ENTRY_D
            FROM   (SELECT   TOP 9223372036854775807 ORDERS.O_ID,
                                                     ORDERS.O_CARRIER_ID,
                                                     ORDERS.O_ENTRY_D
                    FROM     dbo.ORDERS WITH (SERIALIZABLE)
                    WHERE    ORDERS.O_D_ID = @os_d_id
                             AND ORDERS.O_W_ID = @os_w_id
                             AND ORDERS.O_C_ID = @os_c_id
                    ORDER BY ORDERS.O_ID DESC) AS fci;
            IF @@ROWCOUNT = 0
                PRINT 'No orders for customer';
        END
        SET @i = 0;
        DECLARE c_line CURSOR LOCAL FORWARD_ONLY
            FOR SELECT ORDER_LINE.OL_I_ID,
                       ORDER_LINE.OL_SUPPLY_W_ID,
                       ORDER_LINE.OL_QUANTITY,
                       ORDER_LINE.OL_AMOUNT,
                       ORDER_LINE.OL_DELIVERY_D
                FROM   dbo.ORDER_LINE WITH (REPEATABLEREAD)
                WHERE  ORDER_LINE.OL_O_ID = @os_o_id
                       AND ORDER_LINE.OL_D_ID = @os_d_id
                       AND ORDER_LINE.OL_W_ID = @os_w_id;
        OPEN c_line;
        WHILE 1 = 1
            BEGIN
                FETCH c_line INTO @os_ol_i_id, @os_ol_supply_w_id, @os_ol_quantity, @os_ol_amount, @os_ol_delivery_d;
                IF @@FETCH_STATUS = -1
                    BREAK;
                SET @os_ol_i_id_array += CAST (@i AS CHAR) + ',' + CAST (@os_ol_i_id AS CHAR);
                SET @os_ol_supply_w_id_array += CAST (@i AS CHAR) + ',' + CAST (@os_ol_supply_w_id AS CHAR);
                SET @os_ol_quantity_array += CAST (@i AS CHAR) + ',' + CAST (@os_ol_quantity AS CHAR);
                SET @os_ol_amount_array += CAST (@i AS CHAR) + ',' + CAST (@os_ol_amount AS CHAR);
                SET @os_ol_delivery_d_array += CAST (@i AS CHAR) + ',' + CAST (@os_ol_delivery_d AS CHAR);
                SET @i = @i + 1;
            END
        CLOSE c_line;
        DEALLOCATE c_line;
        SELECT @os_c_id AS N'@os_c_id',
               @os_c_last AS N'@os_c_last',
               @os_c_first AS N'@os_c_first',
               @os_c_middle AS N'@os_c_middle',
               @os_c_balance AS N'@os_c_balance',
               @os_o_id AS N'@os_o_id',
               @os_entdate AS N'@os_entdate',
               @os_o_carrier_id AS N'@os_o_carrier_id';
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
