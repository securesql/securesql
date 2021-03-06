USE [tpcc]
GO

/****** Object:  StoredProcedure [dbo].[PAYMENT]    Script Date: 5/15/2013 7:03:42 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PAYMENT]
@p_w_id INT, @p_d_id INT, @p_c_w_id INT, @p_c_d_id INT, @p_c_id INT, @byname INT, @p_h_amount NUMERIC (6, 2), @p_c_last CHAR (16), @TIMESTAMP DATETIME2 (0)
AS
BEGIN
DECLARE @p_w_street_1 AS CHAR (20), 
@p_w_street_2 AS CHAR (20), 
@p_w_city AS CHAR (20), 
@p_w_state AS CHAR (2), 
@p_w_zip AS CHAR (10), 
@p_d_street_1 AS CHAR (20), 
@p_d_street_2 AS CHAR (20), 
@p_d_city AS CHAR (20), 
@p_d_state AS CHAR (20), 
@p_d_zip AS CHAR (10), 
@p_c_first AS CHAR (16), 
@p_c_middle AS CHAR (2), 
@p_c_street_1 AS CHAR (20), 
@p_c_street_2 AS CHAR (20), 
@p_c_city AS CHAR (20), 
@p_c_state AS CHAR (20), 
@p_c_zip AS CHAR (9), 
@p_c_phone AS CHAR (16), 
@p_c_since AS DATETIME2 (0), 
@p_c_credit AS CHAR (32), 
@p_c_credit_lim AS NUMERIC (12, 2), 
@p_c_discount AS NUMERIC (4, 4), 
@p_c_balance AS NUMERIC (12, 2), 
@p_c_data AS VARCHAR (500), 
@namecnt AS INT, 
@p_d_name AS CHAR (11), 
@p_w_name AS CHAR (11), 
@p_c_new_data AS VARCHAR (500), 
@h_data AS VARCHAR (30)
    BEGIN TRANSACTION;
    BEGIN TRY
        UPDATE  dbo.WAREHOUSE
            SET W_YTD = WAREHOUSE.W_YTD + @p_h_amount
        WHERE   WAREHOUSE.W_ID = @p_w_id;
        SELECT @p_w_street_1 = WAREHOUSE.W_STREET_1,
               @p_w_street_2 = WAREHOUSE.W_STREET_2,
               @p_w_city = WAREHOUSE.W_CITY,
               @p_w_state = WAREHOUSE.W_STATE,
               @p_w_zip = WAREHOUSE.W_ZIP,
               @p_w_name = WAREHOUSE.W_NAME
        FROM   dbo.WAREHOUSE
        WHERE  WAREHOUSE.W_ID = @p_w_id;
        UPDATE  dbo.DISTRICT
            SET D_YTD = DISTRICT.D_YTD + @p_h_amount
        WHERE   DISTRICT.D_W_ID = @p_w_id
                AND DISTRICT.D_ID = @p_d_id;
        SELECT @p_d_street_1 = DISTRICT.D_STREET_1,
               @p_d_street_2 = DISTRICT.D_STREET_2,
               @p_d_city = DISTRICT.D_CITY,
               @p_d_state = DISTRICT.D_STATE,
               @p_d_zip = DISTRICT.D_ZIP,
               @p_d_name = DISTRICT.D_NAME
        FROM   dbo.DISTRICT
        WHERE  DISTRICT.D_W_ID = @p_w_id
               AND DISTRICT.D_ID = @p_d_id;
        IF (@byname = 1)
            BEGIN
                SELECT @namecnt = count(CUSTOMER.C_ID)
                FROM   dbo.CUSTOMER WITH (REPEATABLEREAD)
                WHERE  CUSTOMER.C_LAST = @p_c_last
                       AND CUSTOMER.C_D_ID = @p_c_d_id
                       AND CUSTOMER.C_W_ID = @p_c_w_id;
                DECLARE c_byname CURSOR LOCAL
                    FOR SELECT   CUSTOMER.C_FIRST,
                                 CUSTOMER.C_MIDDLE,
                                 CUSTOMER.C_ID,
                                 CUSTOMER.C_STREET_1,
                                 CUSTOMER.C_STREET_2,
                                 CUSTOMER.C_CITY,
                                 CUSTOMER.C_STATE,
                                 CUSTOMER.C_ZIP,
                                 CUSTOMER.C_PHONE,
                                 CUSTOMER.C_CREDIT,
                                 CUSTOMER.C_CREDIT_LIM,
                                 CUSTOMER.C_DISCOUNT,
                                 CUSTOMER.C_BALANCE,
                                 CUSTOMER.C_SINCE
                        FROM     dbo.CUSTOMER WITH (REPEATABLEREAD)
                        WHERE    CUSTOMER.C_W_ID = @p_c_w_id
                                 AND CUSTOMER.C_D_ID = @p_c_d_id
                                 AND CUSTOMER.C_LAST = @p_c_last;
                        -- ORDER BY CUSTOMER.C_FIRST;
                OPEN c_byname;
                IF ((@namecnt % 2) = 1)
                    SET @namecnt = (@namecnt + 1);
                BEGIN
                    DECLARE @loop_counter AS INT;
                    SET @loop_counter = 0;
                    DECLARE @loop$bound AS INT;
                    SET @loop$bound = (@namecnt / 2);
                    WHILE @loop_counter <= @loop$bound
                        BEGIN
                            FETCH c_byname INTO @p_c_first, @p_c_middle, @p_c_id, @p_c_street_1, @p_c_street_2, @p_c_city, @p_c_state, @p_c_zip, @p_c_phone, @p_c_credit, @p_c_credit_lim, @p_c_discount, @p_c_balance, @p_c_since;
                            SET @loop_counter = @loop_counter + 1;
                        END
                END
                CLOSE c_byname;
                DEALLOCATE c_byname;
            END
        ELSE
            BEGIN
                SELECT @p_c_first = CUSTOMER.C_FIRST,
                       @p_c_middle = CUSTOMER.C_MIDDLE,
                       @p_c_last = CUSTOMER.C_LAST,
                       @p_c_street_1 = CUSTOMER.C_STREET_1,
                       @p_c_street_2 = CUSTOMER.C_STREET_2,
                       @p_c_city = CUSTOMER.C_CITY,
                       @p_c_state = CUSTOMER.C_STATE,
                       @p_c_zip = CUSTOMER.C_ZIP,
                       @p_c_phone = CUSTOMER.C_PHONE,
                       @p_c_credit = CUSTOMER.C_CREDIT,
                       @p_c_credit_lim = CUSTOMER.C_CREDIT_LIM,
                       @p_c_discount = CUSTOMER.C_DISCOUNT,
                       @p_c_balance = CUSTOMER.C_BALANCE,
                       @p_c_since = CUSTOMER.C_SINCE
                FROM   dbo.CUSTOMER
                WHERE  CUSTOMER.C_W_ID = @p_c_w_id
                       AND CUSTOMER.C_D_ID = @p_c_d_id
                       AND CUSTOMER.C_ID = @p_c_id;
            END
        SET @p_c_balance = (@p_c_balance + @p_h_amount);
        IF @p_c_credit = 'BC'
            BEGIN
                SELECT @p_c_data = CUSTOMER.C_DATA
                FROM   dbo.CUSTOMER
                WHERE  CUSTOMER.C_W_ID = @p_c_w_id
                       AND CUSTOMER.C_D_ID = @p_c_d_id
                       AND CUSTOMER.C_ID = @p_c_id;
                SET @h_data = (ISNULL(@p_w_name, '') + ' ' + ISNULL(@p_d_name, ''));
                SET @p_c_new_data = (ISNULL(CAST (@p_c_id AS CHAR), '') + ' ' + ISNULL(CAST (@p_c_d_id AS CHAR), '') + ' ' + ISNULL(CAST (@p_c_w_id AS CHAR), '') + ' ' + ISNULL(CAST (@p_d_id AS CHAR), '') + ' ' + ISNULL(CAST (@p_w_id AS CHAR), '') + ' ' + ISNULL(CAST (@p_h_amount AS CHAR (8)), '') + ISNULL(CAST (@TIMESTAMP AS CHAR), '') + ISNULL(@h_data, ''));
                SET @p_c_new_data = substring((@p_c_new_data + @p_c_data), 1, 500 - LEN(@p_c_new_data));
                UPDATE  dbo.CUSTOMER
                    SET C_BALANCE = @p_c_balance,
						C_DATA    = @p_c_new_data
                WHERE   CUSTOMER.C_W_ID = @p_c_w_id
                        AND CUSTOMER.C_D_ID = @p_c_d_id
                        AND CUSTOMER.C_ID = @p_c_id;
            END
        ELSE
            UPDATE  dbo.CUSTOMER
                SET C_BALANCE = @p_c_balance
            WHERE   CUSTOMER.C_W_ID = @p_c_w_id
                    AND CUSTOMER.C_D_ID = @p_c_d_id
                    AND CUSTOMER.C_ID = @p_c_id;
        SET @h_data = (ISNULL(@p_w_name, '') + ' ' + ISNULL(@p_d_name, ''));
        INSERT  dbo.HISTORY (H_C_D_ID, H_C_W_ID, H_C_ID, H_D_ID, H_W_ID, H_DATE, H_AMOUNT, H_DATA)
        VALUES             (@p_c_d_id, @p_c_w_id, @p_c_id, @p_d_id, @p_w_id, @TIMESTAMP, @p_h_amount, @h_data);
        SELECT @p_c_id AS N'@p_c_id',
               @p_c_last AS N'@p_c_last',
               @p_w_street_1 AS N'@p_w_street_1',
               @p_w_street_2 AS N'@p_w_street_2',
               @p_w_city AS N'@p_w_city',
               @p_w_state AS N'@p_w_state',
               @p_w_zip AS N'@p_w_zip',
               @p_d_street_1 AS N'@p_d_street_1',
               @p_d_street_2 AS N'@p_d_street_2',
               @p_d_city AS N'@p_d_city',
               @p_d_state AS N'@p_d_state',
               @p_d_zip AS N'@p_d_zip',
               @p_c_first AS N'@p_c_first',
               @p_c_middle AS N'@p_c_middle',
               @p_c_street_1 AS N'@p_c_street_1',
               @p_c_street_2 AS N'@p_c_street_2',
               @p_c_city AS N'@p_c_city',
               @p_c_state AS N'@p_c_state',
               @p_c_zip AS N'@p_c_zip',
               @p_c_phone AS N'@p_c_phone',
               @p_c_since AS N'@p_c_since',
               @p_c_credit AS N'@p_c_credit',
               @p_c_credit_lim AS N'@p_c_credit_lim',
               @p_c_discount AS N'@p_c_discount',
               @p_c_balance AS N'@p_c_balance',
               @p_c_data AS N'@p_c_data';
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
