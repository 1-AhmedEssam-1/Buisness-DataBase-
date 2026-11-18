-- SQLBook: Code
---Ahmed Essam Mohammed --64-21960 
-- Explanation: Select the project database for the following batches.
USE LocalDeliveryMarketplace_Team_135;

--Ahmed Essam 64-21960
GO
-- Explanation: End this batch; the following CREATE statement starts a new batch.
-- Explanation: Add an address and make it the customer's active address.
-- Explanation: Inputs: customer, description, zone. Changes Address rows; returns a procedure status code.
CREATE PROCEDURE dbo.Add_Customer_Address
-- Explanation: Inputs: customer ID, address description, and delivery zone ID.
@customer_id INT, @description VARCHAR (150), @zone_id INT
AS
-- Explanation: Reject a customer ID that is not present in Customer; invalid input returns -1.
IF NOT EXISTS (SELECT Customer.customer_id
               FROM   dbo.Customer AS Customer
               WHERE  Customer.customer_id = @customer_id)
    BEGIN
        PRINT 'Customer ID does not exist';
        RETURN -1;
    END
-- Explanation: Reject a NULL or empty description; invalid input returns -1.
IF @description IS NULL
   OR @description = ''
    BEGIN
        PRINT 'Address cannot be null or empty';
        RETURN -1;
    END
-- Explanation: Reject a zone ID that is not present in Zone; invalid input returns -1.
IF NOT EXISTS (SELECT Zone.zone_id
               FROM   dbo.Zone AS Zone
               WHERE  Zone.zone_id = @zone_id)
    BEGIN
        PRINT 'Zone ID does not exist';
        RETURN -1;
    END
-- Explanation: Handle SQL execution errors in the matching CATCH block.
BEGIN TRY
    -- Explanation: Start an atomic group of changes; commit them all or roll them back.
    BEGIN TRANSACTION;
    -- Explanation: Deactivate this customer's previous addresses before adding the new active one.
    UPDATE dbo.Address
    SET    is_active = 0
    WHERE  customer_id = @customer_id;
    -- Explanation: Insert the address; address_id is generated and is_active defaults to 1.
    INSERT  INTO dbo.Address (
        customer_id,
        description,
        zone_id
    )
    VALUES                   (@customer_id, @description, @zone_id);
    -- Explanation: Save every change made by this transaction.
    COMMIT TRANSACTION;
    -- Explanation: Report successful completion to the caller.
    RETURN 0;
END TRY
BEGIN CATCH
    -- Explanation: An execution error transfers control here; return the existing failure code.
    -- Explanation: Only attempt rollback when this connection still has an open transaction.
    IF @@TRANCOUNT > 0
        -- Explanation: Undo uncommitted transaction changes before returning.
        ROLLBACK;
    RETURN -1;
END CATCH


GO
-- Explanation: End this batch; the following CREATE statement starts a new batch.
------------------------------------------------------FIRST PROCEDURE-------------------------------------------------------------
--checkout procedure
----Ahmed Essam Mohammed --64-21960
-- Explanation: Convert one active cart into an order, suborders, deliveries, and a payment.
-- Explanation: All checkout writes are committed together; any rejection in the transaction rolls back.
CREATE PROCEDURE Checkout_Cart
-- Explanation: Inputs: cart ID, optional voucher ID, payment method, and optional card ID.
@cart_id INT, @voucher_id INT, @payment_method VARCHAR (20), @card_id INT
AS
BEGIN
    ----validatiion
    -- Explanation: Reject a missing cart before looking up its address or items.
    IF NOT EXISTS (SELECT *
                   FROM   Cart
                   WHERE  cart_id = @cart_id)
        BEGIN
            PRINT 'Cart ID does not exist';
            RETURN -1;
        END
    -- Explanation: Only an Active cart can be checked out; Checked Out carts are frozen.
    IF NOT EXISTS (SELECT status
                   FROM   Cart
                   WHERE  cart_id = @cart_id
                          AND status = 'Active')
        BEGIN
            PRINT 'Cart is not active';
            RETURN -4;
        END
    -- Explanation: The selected cart must use an active address owned by the same customer.
    IF NOT EXISTS (SELECT A.is_active
                   FROM   Address AS A
                          INNER JOIN
                          Cart AS C
                          ON C.address_id = A.address_id
                   WHERE  C.cart_id = @cart_id
                          AND A.is_active = 1
                          AND A.customer_id = C.customer_id)
        BEGIN
            PRINT 'the cart address is not active  ';
            RETURN -4;
        END
    -- Explanation: Follow Cart.customer_id to Users.user_id to reject a Blacklisted customer.
    IF EXISTS (SELECT *
               FROM   dbo.Cart AS C
                      INNER JOIN
                      dbo.Users AS U
                      ON C.customer_id = U.user_id
               WHERE  C.cart_id = @cart_id
                      AND U.account_status = 'Blacklisted')
        BEGIN
            PRINT 'Customer is blacklisted';
            RETURN -3;
        END
    -- Reject an empty cart.
    -- Explanation: A cart with no CartItem rows has nothing to check out.
    IF NOT EXISTS (SELECT 1
                   FROM   dbo.CartItem
                   WHERE  cart_id = @cart_id)
        BEGIN
            PRINT 'Cart is empty';
            RETURN -9;
        END
    -- Explanation: Variables hold customer/zone/order IDs, money totals, and one checkout timestamp.
    DECLARE @customer_id AS INT;
    DECLARE @zone_id AS INT;
    DECLARE @order_id AS INT;
    DECLARE @subtotal AS DECIMAL (10, 2);
    DECLARE @delivery_fee AS DECIMAL (10, 2);
    DECLARE @discount AS DECIMAL (10, 2);
    DECLARE @total AS DECIMAL (10, 2);
    DECLARE @now AS DATETIME = GETDATE();
    DECLARE @current_time AS TIME = CAST (@now AS TIME);
    DECLARE @error AS INT = 0;
    -- Explanation: Handle SQL execution errors in the matching CATCH block.
    BEGIN TRY
        -- Explanation: Start an atomic group of changes; commit them all or roll them back.
        BEGIN TRANSACTION;
        -- Find the customer and delivery zone.
        -- Explanation: Read and lock the cart, address, and account used by this checkout.
        SELECT @customer_id = C.customer_id,
               @zone_id = A.zone_id
        FROM   dbo.Cart AS C WITH (UPDLOCK, HOLDLOCK)
               INNER JOIN
               dbo.Address AS A WITH (HOLDLOCK)
               ON A.address_id = C.address_id
               INNER JOIN
               dbo.Users AS U WITH (HOLDLOCK)
               ON U.user_id = C.customer_id
        WHERE  C.cart_id = @cart_id
               AND C.status = 'Active'
               AND A.is_active = 1
               AND A.customer_id = C.customer_id
               AND U.account_status = 'Active';
        -- Recheck inside the transaction in case data changed.
        -- Explanation: If the locked recheck finds no eligible row, reject using the existing -4 code.
        IF @customer_id IS NULL
            BEGIN
                -- Explanation: Undo uncommitted transaction changes before returning.
                ROLLBACK;
                RETURN -4;
            END
        -- Read the products and their businesses once.
        DECLARE @items TABLE (
            -- Explanation: This local table stores the selected items, current prices, and business details.
            product_id      INT            ,
            business_id     INT            ,
            quantity        INT            ,
            unit_price      DECIMAL (10, 2),
            is_available    BIT            ,
            business_status VARCHAR (20)   ,
            zone_id         INT            ,
            opening_hour    TIME           ,
            closing_hour    TIME           );
        -- Explanation: Populate the local item table using current product discounts and business information.
        INSERT INTO @items
        SELECT P.product_id,
               P.business_id,
               CI.quantity,
               P.price - P.discount_amount,
               P.is_available,
               B.status,
               B.zone_id,
               B.opening_hour,
               B.closing_hour
        FROM   dbo.CartItem AS CI WITH (UPDLOCK, HOLDLOCK)
               INNER JOIN
               dbo.Product AS P WITH (HOLDLOCK)
               ON P.product_id = CI.product_id
               INNER JOIN
               dbo.Business AS B WITH (HOLDLOCK)
               ON B.business_id = P.business_id
        WHERE  CI.cart_id = @cart_id;
        -- Explanation: Recheck that there are items inside the transaction.
        IF NOT EXISTS (SELECT 1
                       FROM   @items)
            SET @error = -9;
        -- Reject unavailable products or inactive businesses.
        -- Explanation: Unavailable products or non-Active businesses prevent checkout.
        IF @error = 0
           AND EXISTS (SELECT 1
                       FROM   @items
                       WHERE  is_available = 0
                              OR business_status <> 'Active')
            SET @error = -4;
        -- Reject a business outside the delivery zone.
        -- Explanation: Each product's business must serve the address zone.
        IF @error = 0
           AND EXISTS (SELECT 1
                       FROM   @items
                       WHERE  zone_id <> @zone_id)
            SET @error = -5;
        -- Reject closed businesses.
        -- Explanation: Equal opening/closing hours mean 24 hours; otherwise handle daytime and overnight hours.
        IF @error = 0
           AND EXISTS (SELECT 1
                       FROM   @items
                       WHERE  NOT (opening_hour = closing_hour
                                   OR (opening_hour < closing_hour
                                       AND @current_time >= opening_hour
                                       AND @current_time < closing_hour)
                                   OR (opening_hour > closing_hour
                                       AND (@current_time >= opening_hour
                                            OR @current_time < closing_hour))))
            SET @error = -4;
        -- A supplied voucher must belong to this customer
        -- and be unused and unexpired.
        -- Explanation: When supplied, a voucher must be owned, Unused, unexpired, and have a valid amount.
        IF @error = 0
           AND @voucher_id IS NOT NULL
           AND NOT EXISTS (SELECT 1
                           FROM   dbo.Voucher WITH (UPDLOCK, HOLDLOCK)
                           WHERE  voucher_id = @voucher_id
                                  AND customer_id = @customer_id
                                  AND status = 'Unused'
                                  AND expiry_date >= CAST (@now AS DATE)
                                  AND amount > 0
                                  AND (is_percentage = 0
                                       OR amount BETWEEN 1 AND 100))
            SET @error = -1;
        -- Explanation: Stop before writing order data if any previous validation recorded an error.
        IF @error <> 0
            BEGIN
                -- Explanation: Undo uncommitted transaction changes before returning.
                ROLLBACK;
                RETURN @error;
            END
        -- Calculate a product total for each business.
        -- Explanation: Store one product-price subtotal per distinct business, not per business type.
        DECLARE @business_totals TABLE (
            business_id INT            ,
            total_price DECIMAL (10, 2));
        -- Explanation: Group item quantities times effective unit prices by business ID.
        INSERT INTO @business_totals
        SELECT   business_id,
                 SUM(quantity * unit_price)
        FROM     @items
        GROUP BY business_id;
        -- Explanation: The order subtotal is the sum of the business product totals.
        SELECT @subtotal = SUM(total_price)
        FROM   @business_totals;
        -- Explanation: Read the current delivery fee of the selected zone and retain its read lock.
        SELECT @delivery_fee = delivery_fee
        FROM   dbo.Zone WITH (HOLDLOCK)
        WHERE  zone_id = @zone_id;
        -- Explanation: Use the scalar function to calculate the capped voucher discount.
        SET @discount = dbo.Calculate_Voucher_Discount(@voucher_id, @subtotal);
        -- Explanation: Total = subtotal + one delivery fee per business - voucher discount.
        SELECT @total = @subtotal + COUNT(*) * @delivery_fee - @discount
        FROM   @business_totals;
        -- Validate payment.
        -- Explanation: Only the three specified payment methods are accepted.
        IF @payment_method IS NULL
           OR @payment_method NOT IN ('Cash', 'Card', 'Wallet')
            SET @error = -1;
        -- Explanation: Validate card ownership and expiry only for Card payment.
        IF @error = 0
           AND @payment_method = 'Card'
            BEGIN
                -- Explanation: A Card payment needs an existing, unexpired card belonging to this customer.
                IF NOT EXISTS (SELECT 1
                               FROM   dbo.Card WITH (HOLDLOCK)
                               WHERE  card_id = @card_id
                                      AND customer_id = @customer_id
                                      AND expiration_date >= CAST (@now AS DATE))
                    SET @error = -7;
            END
        -- Explanation: Validate available wallet funds only for Wallet payment.
        IF @error = 0
           AND @payment_method = 'Wallet'
            BEGIN
                -- Explanation: Lock the wallet row and require enough balance for the whole total.
                IF NOT EXISTS (SELECT 1
                               FROM   dbo.Customer WITH (UPDLOCK, HOLDLOCK)
                               WHERE  customer_id = @customer_id
                                      AND wallet_balance >= @total)
                    SET @error = -7;
            END
        -- Find eligible riders and count their active deliveries.
        -- Explanation: This local table holds each eligible rider and their active-delivery count.
        DECLARE @riders TABLE (
            rider_id          INT,
            active_deliveries INT);
        -- Explanation: Eligible riders are available, Active users in the delivery zone.
        INSERT INTO @riders
        -- Explanation: Count only Assigned or Picked Up suborders as a rider's active deliveries.
        SELECT R.rider_id,
               (SELECT COUNT(*)
                FROM   dbo.Delivery AS D WITH (HOLDLOCK)
                       INNER JOIN
                       dbo.SubOrder AS S WITH (HOLDLOCK)
                       ON S.suborder_id = D.suborder_id
                WHERE  D.rider_id = R.rider_id
                       AND S.status IN ('Assigned', 'Picked Up'))
        FROM   dbo.Rider AS R WITH (UPDLOCK, HOLDLOCK)
               INNER JOIN
               dbo.Users AS U WITH (HOLDLOCK)
               ON U.user_id = R.rider_id
        WHERE  R.zone_id = @zone_id
               AND R.is_available = 1
               AND U.account_status = 'Active';
        -- Explanation: No eligible rider means checkout cannot assign its deliveries.
        IF @error = 0
           AND NOT EXISTS (SELECT 1
                           FROM   @riders)
            SET @error = -8;
        -- Explanation: Reject payment or rider failures before creating permanent checkout rows.
        IF @error <> 0
            BEGIN
                -- Explanation: Undo uncommitted transaction changes before returning.
                ROLLBACK;
                RETURN @error;
            END
        -- Freeze the item prices.
        -- Explanation: Freeze the effective price of each cart item for the order history.
        UPDATE CI
        SET    unit_price = I.unit_price
        FROM   dbo.CartItem AS CI
               INNER JOIN
               @items AS I
               ON I.product_id = CI.product_id
        WHERE  CI.cart_id = @cart_id;
        -- Create the order.
        -- Explanation: Create the main order in Placed status using the calculated, fixed totals.
        INSERT  INTO dbo.Orders (
            order_date,
            status,
            discount_amount,
            total_amount,
            cart_id,
            zone_id,
            voucher_id
        )
        VALUES                  (@now, 'Placed', @discount, @total, @cart_id, @zone_id, @voucher_id);
        -- Explanation: Capture the generated order_id immediately after inserting the order.
        SET @order_id = CAST (SCOPE_IDENTITY() AS INT);
        -- Create one suborder per business.
        -- Explanation: Create a separate Placed suborder for each business and store its delivery fee.
        INSERT INTO dbo.SubOrder (
            status,
            total_price,
            delivery_fee,
            order_id,
            business_id
        )
        SELECT 'Placed',
               total_price,
               @delivery_fee,
               @order_id,
               business_id
        FROM   @business_totals;
        -- Explanation: Variables identify the next suborder and the rider selected for it.
        -- Assign a rider to each new suborder.
        DECLARE @suborder_id AS INT;
        DECLARE @rider_id AS INT;
        -- Explanation: Repeat until every newly created suborder has a delivery assignment.
        WHILE EXISTS (SELECT 1
                      FROM   dbo.SubOrder
                      WHERE  order_id = @order_id
                             AND status = 'Placed')
            BEGIN
                -- Explanation: Choose the next unassigned suborder using the smallest suborder ID.
                SELECT @suborder_id = MIN(suborder_id)
                FROM   dbo.SubOrder
                WHERE  order_id = @order_id
                       AND status = 'Placed';
                -- Explanation: Choose the fewest active deliveries; break ties with the smallest rider ID.
                SELECT   TOP (1) @rider_id = rider_id
                FROM     @riders
                ORDER BY active_deliveries, rider_id;
                -- Explanation: Create the delivery record linking this suborder to the chosen rider.
                INSERT  INTO dbo.Delivery (
                    assigned_at,
                    suborder_id,
                    rider_id
                )
                VALUES                    (@now, @suborder_id, @rider_id);
                -- Explanation: Assignment changes the suborder from Placed to Assigned.
                UPDATE dbo.SubOrder
                SET    status = 'Assigned'
                WHERE  suborder_id = @suborder_id;
                -- Explanation: Increase the local workload so the next assignment includes this new delivery.
                UPDATE @riders
                SET    active_deliveries = active_deliveries + 1
                WHERE  rider_id = @rider_id;
            END
        -- Save a card reference only for Card payment.
        -- Explanation: Non-Card payments leave Payment.card_id NULL even if an input card was supplied.
        DECLARE @charged_card_id AS INT = NULL;
        IF @payment_method = 'Card'
            SET @charged_card_id = @card_id;
        -- Explanation: Record one payment for the whole order, initially with no refunds.
        INSERT  INTO dbo.Payment (
            amount,
            currency,
            method,
            transaction_date,
            refunded_amount,
            order_id,
            card_id
        )
        VALUES                   (@total, 'EGP', @payment_method, @now, 0, @order_id, @charged_card_id);
        -- Explanation: Deduct funds only for Wallet payment; Cash and Card do not debit the wallet.
        IF @payment_method = 'Wallet'
            BEGIN
                UPDATE dbo.Customer
                SET    wallet_balance = wallet_balance - @total
                WHERE  customer_id = @customer_id;
            END
        -- Explanation: Consume the supplied voucher only after successful order creation.
        IF @voucher_id IS NOT NULL
            BEGIN
                UPDATE dbo.Voucher
                SET    status = 'Used'
                WHERE  voucher_id = @voucher_id;
            END
        -- Explanation: Freeze the cart so its checked-out item list cannot be edited.
        UPDATE dbo.Cart
        SET    status = 'Checked Out'
        WHERE  cart_id = @cart_id;
        -- Explanation: Save every change made by this transaction.
        COMMIT TRANSACTION;
        -- Explanation: Report successful completion to the caller.
        RETURN 0;
    END TRY
    BEGIN CATCH
        -- Explanation: An execution error transfers control here; return the existing failure code.
        -- Explanation: Only attempt rollback when this connection still has an open transaction.
        IF @@TRANCOUNT > 0
            -- Explanation: Undo uncommitted transaction changes before returning.
            ROLLBACK;
        RETURN -1;
    END CATCH
END


GO
-- Explanation: End this batch; the following CREATE statement starts a new batch.
----------------------------------------------Update_Delete_Customer_Address --------------------
--Ahmed Essam Mohammed Abdallah 64-21960
-- Explanation: Update an owned address or remove it when carts and ongoing orders allow it.
-- Explanation: Shared ownership/order checks run before either Update or Remove.
CREATE PROCEDURE Update_Delete_Customer_Address
-- Explanation: Inputs identify the customer/address, replacement values, and Update or Remove action.
@customer_id INT, @address_id INT, @description VARCHAR (150), @zone_id INT, @action VARCHAR (20)
AS
BEGIN
    -- Explanation: Reject a NULL action or any action other than Update, Remove, and Delete.
    IF @action IS NULL
       OR @action NOT IN ('Update', 'Remove', 'Delete')
        BEGIN
            RETURN -1;
        END
    -- Explanation: Check that the supplied customer and address IDs exist independently.
    IF @customer_id NOT IN (SELECT customer_id
                            FROM   Customer)
       OR @address_id NOT IN (SELECT address_id
                              FROM   Address)
        RETURN -1;
    -- Explanation: Then check ownership: both IDs must match the same Address row.
    IF NOT EXISTS (SELECT 1
                   FROM   dbo.Address
                   WHERE  address_id = @address_id
                          AND customer_id = @customer_id)
        BEGIN
            RETURN -3;
        END
    -- Explanation: Orders reach their delivery address through Cart; ongoing orders block either action.
    IF EXISTS (SELECT address_id
               FROM   dbo.Cart AS C
                      INNER JOIN
                      dbo.Orders AS O
                      ON O.cart_id = C.cart_id
               WHERE  C.address_id = @address_id
                      AND O.status IN ('Placed', 'In Progress'))
        BEGIN
            RETURN -4;
        END
    -- Explanation: Removal is also forbidden whenever any cart still references this address.
    IF @action IN ('Remove', 'Delete')
       AND EXISTS (SELECT *
                   FROM   dbo.Cart
                   WHERE  address_id = @address_id)
        BEGIN
            RETURN -4;
        END
    -- Explanation: Only the Update branch needs replacement description and zone values.
    IF @action = 'Update'
        BEGIN
            -- Explanation: Reject NULL replacement values required by the Address schema.
            IF @description IS NULL
               OR @zone_id IS NULL
                BEGIN
                    RETURN -1;
                END
            -- Explanation: The replacement zone must exist before changing the address.
            IF NOT EXISTS (SELECT 1
                           FROM   dbo.Zone
                           WHERE  zone_id = @zone_id)
                BEGIN
                    RETURN -1;
                END
            -- Explanation: Update only the specified owned address; preserve its current active flag.
            UPDATE dbo.Address
            SET    description = @description,
                   zone_id     = @zone_id
            WHERE  address_id = @address_id
                   AND customer_id = @customer_id;
            -- Explanation: Report successful completion to the caller.
            RETURN 0;
        END
    -- Explanation: The Remove/Delete branch deletes an address after the earlier reference/ownership checks.
    IF @action IN ('Remove', 'Delete')
        BEGIN
            -- Explanation: Delete an Address row using its table alias A; this is not a column deletion.
            DELETE A
            FROM   dbo.address AS A
            WHERE  A.address_id = @address_id;
            -- Explanation: Report successful completion to the caller.
            RETURN 0;
        END
END


GO
-- Explanation: End this batch; the following CREATE statement starts a new batch.
-------------------------------------------Change_Active_Address ------------------------------
---Ahmed Essam 64-21960
-- Explanation: Switch the customer's active address while retaining carts at other addresses.
-- Explanation: Two address updates form one transaction; existing carts keep their original address IDs.
CREATE PROCEDURE Change_Active_Address
@customer_id INT, @new_address_id INT
AS
BEGIN
    -- Explanation: Reject an address that is not owned by this customer.
    IF NOT EXISTS (SELECT 1
                   FROM   dbo.Address
                   WHERE  address_id = @new_address_id
                          AND customer_id = @customer_id)
        BEGIN
            RETURN -3;
        END
    -- Explanation: Handle SQL execution errors in the matching CATCH block.
    BEGIN TRY
        -- Explanation: Start an atomic group of changes; commit them all or roll them back.
        BEGIN TRANSACTION;
        -- Explanation: Deactivate only this customer's addresses; leave other customers untouched.
        UPDATE A
        SET    is_active = 0
        FROM   dbo.Address AS A
               INNER JOIN
               Customer AS C
               ON C.customer_id = A.customer_id
        WHERE  C.customer_id = @customer_id;
        -- Explanation: Activate the selected owned address so only it remains active for this customer.
        UPDATE A
        SET    is_active = 1
        FROM   dbo.Address AS A
               INNER JOIN
               Customer AS C
               ON C.customer_id = A.customer_id
        WHERE  A.address_id = @new_address_id
               AND C.customer_id = @customer_id;
        -- Explanation: Save every change made by this transaction.
        COMMIT TRANSACTION;
        -- Explanation: Report successful completion to the caller.
        RETURN 0;
    END TRY
    BEGIN CATCH
        -- Explanation: An execution error transfers control here; return the existing failure code.
        -- Explanation: Only attempt rollback when this connection still has an open transaction.
        IF @@TRANCOUNT > 0
            -- Explanation: Undo uncommitted transaction changes before returning.
            ROLLBACK;
        RETURN -1;
    END CATCH
END


GO
-- Explanation: End this batch; the following CREATE statement starts a new batch.
-----------------------------Add_Card----------------------------------------------------
--Ahmed Essam 64-21960
-- Explanation: Save a payment card for a customer without charging it.
-- Explanation: Cards are stored for later payment; adding a card does not change wallet funds.
CREATE PROCEDURE Add_Card
@customer_id INT, @card_no CHAR (16), @card_holder_name VARCHAR (100), @expiration_date DATE
AS
BEGIN
    -- Explanation: Reject a missing or empty card-holder name.
    IF @card_holder_name IS NULL
       OR @card_holder_name = ''
        BEGIN
            RETURN -1;
        END
    -- Explanation: Reject NULL values for any of the required card inputs.
    IF @customer_id IS NULL
       OR @card_no IS NULL
       OR @card_holder_name IS NULL
       OR @expiration_date IS NULL
        BEGIN
            RETURN -1;
        END
    -- Reject short, space-padded, or non-digit card numbers before inserting.
    IF LEN(@card_no) <> 16
       OR @card_no COLLATE Latin1_General_100_BIN2 LIKE '%[^0-9]%'
    BEGIN
        RETURN -1;
    END;

    -- Explanation: A card expires when its expiration date is before today; today is accepted.
    IF CAST (GETDATE() AS DATE) > @expiration_date
        BEGIN
            RETURN -1;
        END
    -- Explanation: Duplicate means the same card number is already saved by this same customer.
    IF EXISTS (SELECT 1
               FROM   CARD AS C
               WHERE  C.customer_id = @customer_id
                      AND C.card_no = @card_no)
        BEGIN
            RETURN -2;
        END
    -- Explanation: Handle SQL execution errors in the matching CATCH block.
    BEGIN TRY
        -- Explanation: Save the card details; SQL Server generates the identity card_id.
        INSERT  INTO dbo.Card (
            card_no,
            card_holder_name,
            expiration_date,
            customer_id
        )
        VALUES                (@card_no, @card_holder_name, @expiration_date, @customer_id);
        -- Explanation: Report successful completion to the caller.
        RETURN 0;
    END TRY
    BEGIN CATCH
        -- Explanation: An execution error transfers control here; return the existing failure code.
        RETURN -1;
    END CATCH
END


GO
-- Explanation: End this batch; the following CREATE statement starts a new batch.
------------------------Create_Cart--------------------------------------------------
-- Explanation: Create an empty Active cart using the customer's active address automatically.
-- Explanation: The new cart starts empty and uses the active address rather than an address parameter.
-- Explanation: Ahmed Essam 64-21960
CREATE PROCEDURE Create_Cart
@customer_id INT
AS
BEGIN
    -- Explanation: A NULL customer ID is invalid input.
    IF @customer_id IS NULL
        RETURN -1;
    -- Explanation: A Blacklisted account cannot create a cart.
    IF EXISTS (SELECT 1
               FROM   dbo.Users
               WHERE  user_id = @customer_id
                      AND account_status = 'Blacklisted')
        BEGIN
            RETURN -3;
        END
    -- Explanation: Keep the active address ID for duplicate detection and insertion.
    DECLARE @address_id AS INT;
    -- Explanation: Read the active address; the caller does not supply an address ID.
    SELECT @address_id = address_id
    FROM   dbo.Address
    WHERE  customer_id = @customer_id
           AND is_active = 1;
    -- Explanation: Reject when no active address was found.
    IF @address_id IS NULL
        BEGIN
            RETURN -1;
        END
    -- Explanation: Prevent another Active cart for the same customer/address in this check.
    IF EXISTS (SELECT 1
               FROM   dbo.Cart
               WHERE  customer_id = @customer_id
                      AND address_id = @address_id
                      AND status = 'Active')
        BEGIN
            RETURN -2;
        END
    -- Explanation: Handle SQL execution errors in the matching CATCH block.
    BEGIN TRY
        -- Explanation: Insert the empty cart; ID, Active status, and creation time use table defaults.
        INSERT  INTO dbo.Cart (
            customer_id,
            address_id
        )
        VALUES                (@customer_id, @address_id);
        -- Explanation: Report successful completion to the caller.
        RETURN 0;
    END TRY
    BEGIN CATCH
        -- Explanation: An execution error transfers control here; return the existing failure code.
        RETURN -1;
    END CATCH
END


GO
-- Explanation: End this batch; the following CREATE statement starts a new batch.
--------------------------------------------Remove_From_Cart------------------
--Ahmed Essam 64-21960
-- Explanation: Remove one product from an editable cart without deleting the cart.
-- Explanation: CartItem uses the pair (cart_id, product_id) to identify the one item to remove.
CREATE PROCEDURE Remove_From_Cart
@cart_id INT, @product_id INT
AS
BEGIN
    -- Explanation: Only an Active cart can be edited.
    IF NOT EXISTS (SELECT 1
                   FROM   Cart AS C
                   WHERE  C.status = 'Active'
                          AND C.cart_id = @cart_id)
        BEGIN
            RETURN -4;
        END
    -- Explanation: The cart must belong to its address owner and use that owner's active address.
    IF NOT EXISTS (SELECT 1
                   FROM   Cart AS C
                          INNER JOIN
                          Address AS A
                          ON A.address_id = C.address_id
                             AND C.cart_id = @cart_id
                             AND A.customer_id = C.customer_id
                   WHERE  A.is_active = 1)
        BEGIN
            RETURN -4;
        END
    -- Explanation: Handle SQL execution errors in the matching CATCH block.
    BEGIN TRY
        -- Explanation: Delete only the selected product in the selected cart; absent items delete zero rows.
        DELETE dbo.CartItem
        WHERE  cart_id = @cart_id
               AND product_id = @product_id;
        -- Explanation: Report successful completion to the caller.
        RETURN 0;
    END TRY
    BEGIN CATCH
        -- Explanation: An execution error transfers control here; return the existing failure code.
        RETURN -1;
    END CATCH
END


GO
-- Explanation: End this batch; the following CREATE statement starts a new batch.
--------------------------------Calculate_Voucher_Discount-------------------
-- Ahmed Essam 64-21960
-- Explanation: Return a voucher discount without modifying the voucher or any stored table.
-- Explanation: is_percentage = 1 means percent; 0 means fixed money. This function does not check caller ownership.
CREATE FUNCTION dbo.Calculate_Voucher_Discount
(-- Explanation: Inputs: optional voucher ID and subtotal; result is a decimal money amount.
@voucher_id INT, @order_subtotal DECIMAL (10, 2))
RETURNS DECIMAL (10, 2)
AS
BEGIN
    -- Explanation: Reject a NULL or negative subtotal with the existing scalar error code.
    IF @order_subtotal IS NULL
       OR @order_subtotal < 0
        RETURN -1;
    -- Explanation: No voucher means no discount.
    IF @voucher_id IS NULL
        BEGIN
            -- Explanation: Return zero discount.
            RETURN 0;
        END
    -- Explanation: A missing voucher also produces zero discount.
    IF NOT EXISTS (SELECT 1
                   FROM   dbo.Voucher
                   WHERE  voucher_id = @voucher_id)
        BEGIN
            -- Explanation: Return zero discount.
            RETURN 0;
        END
    -- Explanation: Expired or Used vouchers produce zero discount; expiry today remains valid.
    IF EXISTS (SELECT 1
               FROM   dbo.Voucher AS V
               WHERE  V.voucher_id = @voucher_id
                      AND (expiry_date < CAST (GETDATE() AS DATE)
                           OR status = 'Used'))
        BEGIN
            -- Explanation: Return zero discount.
            RETURN 0;
        END
    -- Explanation: Store the voucher amount and whether it represents a percentage.
    DECLARE @amount AS DECIMAL (10, 2);
    DECLARE @IsItPer AS BIT;
    -- Explanation: SELECT assignments copy values from the matching voucher into local variables.
    SELECT @amount = V.amount,
           @IsItPer = is_percentage
    FROM   Voucher AS V
    WHERE  @voucher_id = V.voucher_id;
    -- Explanation: The discount variable holds money, not the price remaining after discount.
    DECLARE @discount AS DECIMAL (10, 2);
    -- Explanation: Choose between percentage and fixed-amount voucher calculations.
    IF @IsItPer = 1
        BEGIN
            -- Explanation: Percentage discount = amount / 100 times subtotal; amount is a decimal.
            SET @discount = @amount / 100 * @order_subtotal;
        END
    ELSE
        BEGIN
            -- Explanation: A fixed voucher discounts the amount directly.
            SET @discount = @amount;
        END
    -- Explanation: Cap the discount so it cannot exceed the item subtotal.
    IF @discount > @order_subtotal
        BEGIN
            SET @discount = @order_subtotal;
        END
    RETURN @discount;
END


GO
-- Explanation: End this batch; the following CREATE statement starts a new batch.
----------------------------------My_Order_History-------------------------------------
-- Ahmed Essam 64-21960
-- Explanation: Return one history row per order belonging to the input customer.
-- Explanation: The Cart join identifies the customer; the function returns data rather than a procedure return code.
CREATE FUNCTION dbo.My_Order_History
(@customer_id INT)
RETURNS TABLE 
AS
RETURN -- Explanation: An inline table-valued function returns the rows of this SELECT.
-- Explanation: Return the required columns in their specified order.

    (SELECT   O.order_id,
              O.order_date,
              Z.zone_name,
              O.status,
              -- Explanation: Count joined suborders to report how many businesses were in each order.
              COUNT(S.suborder_id) AS number_of_suborders,
              O.discount_amount,
              O.total_amount,
              P.method AS payment_method,
              -- Explanation: Payment stores method; the alias gives the required output name payment_method.
              P.refunded_amount
     FROM     dbo.Orders AS O
              -- Explanation: Connect orders to suborders, customer-owned carts, delivery zones, and payments.
              INNER JOIN
              dbo.SubOrder AS S
              ON S.order_id = O.order_id
              INNER JOIN
              dbo.Cart AS C
              ON C.cart_id = O.cart_id
              INNER JOIN
              dbo.ZONE AS Z
              ON Z.zone_id = O.zone_id
              INNER JOIN
              dbo.Payment AS P
              ON P.order_id = O.order_id
     WHERE    C.customer_id = @customer_id
     -- Explanation: Filter by Cart.customer_id because Orders has no customer_id column.
     GROUP BY O.order_id, O.order_date, Z.zone_name, O.status, O.discount_amount, O.total_amount, P.method, P.refunded_amount)



GO
-- Explanation: Group every non-aggregated selected value so COUNT returns one result per order.
-- Explanation: End this batch; the following CREATE statement starts a new batch.
----------------------Add_To_Cart--------------------------------------------
--Ahmed Essam 64-21960
-- Explanation: Add a new product or increase an existing item in the current active-address cart.
-- Explanation: New notes replace existing notes only when the input is not NULL.
CREATE PROCEDURE Add_To_Cart
-- Explanation: Inputs: cart, product, added quantity, and optional replacement notes.
@cart_id INT, @product_id INT, @quantity INT, @notes VARCHAR (255)
AS
BEGIN
    -- Explanation: Reject a cart that is not Active.
    IF NOT EXISTS (SELECT 1
                   FROM   Cart AS C
                   WHERE  C.cart_id = @cart_id
                          AND C.status = 'Active')
        BEGIN
            PRINT 'the cart is not active';
            RETURN -4;
        END
    -- Explanation: The selected product must be available and its business must be Active.
    IF NOT EXISTS (SELECT 1
                   FROM   Product AS P
                          INNER JOIN
                          Business AS B
                          ON B.business_id = P.business_id
                   WHERE  P.product_id = @product_id
                          AND P.is_available = 1
                          AND B.status = 'Active')
        BEGIN
            RETURN -4;
        END
    -- Explanation: Compare the cart address zone with the selected product's business zone.
    IF EXISTS (SELECT 1
               FROM   dbo.Cart AS C
                      INNER JOIN
                      dbo.Address AS A
                      ON A.address_id = C.address_id
                      INNER JOIN
                      dbo.Product AS P
                      ON P.product_id = @product_id
                      INNER JOIN
                      dbo.Business AS B
                      ON B.business_id = P.business_id
               WHERE  C.cart_id = @cart_id
                      AND B.zone_id <> A.zone_id)
        BEGIN
            PRINT 'the zone is mismatched with the buisness';
            RETURN -5;
        END
    -- Explanation: Confirm that the cart uses an active address belonging to its customer.
    IF NOT EXISTS (SELECT 1
                   FROM   dbo.Cart AS C
                          INNER JOIN
                          dbo.Address AS A
                          ON A.address_id = C.address_id
                   WHERE  C.cart_id = @cart_id
                          AND A.customer_id = C.customer_id
                          AND A.is_active = 1)
        BEGIN
            PRINT 'the address is inactive ';
            RETURN -4;
        END
    -- Explanation: NULL, zero, and negative quantities are invalid input.
    IF @quantity IS NULL
       OR @quantity <= 0
        BEGIN
            RETURN -1;
        END
    ELSE
        -- Explanation: A requested quantity above ten already exceeds the per-item limit.
        IF @quantity > 10
            BEGIN
                RETURN -6;
            END
    -- Explanation: Handle SQL execution errors in the matching CATCH block.
    BEGIN TRY
        -- Explanation: Choose the update branch only if this product already exists in this cart.
        IF EXISTS (SELECT 1
                   FROM   dbo.CartItem
                   WHERE  cart_id = @cart_id
                          AND product_id = @product_id)
            BEGIN
                -- Explanation: Reject before updating if existing quantity plus requested quantity exceeds ten.
                IF EXISTS (SELECT 1
                           FROM   dbo.CartItem
                           WHERE  cart_id = @cart_id
                                  AND product_id = @product_id
                                  AND quantity + @quantity > 10)
                    BEGIN
                        RETURN -6;
                    END
                -- Explanation: A NULL notes parameter means preserve the item's current notes.
                IF @notes IS NULL
                    BEGIN
                        -- Explanation: Increase only the quantity when no replacement note was supplied.
                        UPDATE dbo.CartItem
                        SET    quantity = quantity + @quantity
                        WHERE  cart_id = @cart_id
                               AND product_id = @product_id;
                    END
                ELSE
                    BEGIN
                        -- Explanation: Increase quantity and replace notes when a new note was supplied.
                        UPDATE dbo.CartItem
                        SET    quantity = quantity + @quantity,
                               notes    = @notes
                        WHERE  cart_id = @cart_id
                               AND product_id = @product_id;
                    END
            END
        ELSE
            BEGIN
                -- Explanation: Insert a new item; unit_price remains NULL until checkout freezes its price.
                INSERT  INTO dbo.CartItem (
                    cart_id,
                    product_id,
                    quantity,
                    notes
                )
                VALUES                    (@cart_id, @product_id, @quantity, @notes);
            END
        -- Explanation: Report successful completion to the caller.
        RETURN 0;
    END TRY
    BEGIN CATCH
        -- Explanation: An execution error transfers control here; return the existing failure code.
        RETURN -1;
    END CATCH
END


GO
-- Explanation: End this batch; the following CREATE statement starts a new batch.
----------------------------Reorder-------------------------------------------
-- Ahmed Essam 64-21960
-- Explanation: Build a new cart from order history, skipping items that no longer qualify.
-- Explanation: The original order and frozen prices remain untouched; new item prices are set at future checkout.
CREATE PROCEDURE Reorder
@order_id INT, @address_id INT
AS
-- Explanation: Keep the original order's customer and recorded zone for the subsequent checks.
BEGIN
    DECLARE @CUST AS INT;
    DECLARE @ZONE AS INT;
    -- Explanation: Find the customer through the old cart, and read the order's stored zone.
    SELECT @CUST = C.customer_id,
           @ZONE = O.zone_id
    FROM   Orders AS O
           INNER JOIN
           dbo.Cart AS C
           ON C.cart_id = O.cart_id
    WHERE  O.order_id = @order_id;
    -- Explanation: A Blacklisted customer cannot reorder.
    IF EXISTS (SELECT 1
               FROM   dbo.Users
               WHERE  user_id = @CUST
                      AND account_status = 'Blacklisted')
        BEGIN
            RETURN -3;
        END
    -- Explanation: The chosen destination address must belong to the original order's customer.
    IF NOT EXISTS (SELECT 1
                   FROM   dbo.Address AS A
                   WHERE  A.address_id = @address_id
                          AND A.customer_id = @CUST)
        BEGIN
            RETURN -3;
        END
    -- Explanation: The chosen address must remain in the original order's zone.
    IF NOT EXISTS (SELECT 1
                   FROM   Address AS A
                   WHERE  A.zone_id = @ZONE
                          AND A.address_id = @address_id)
        BEGIN
            RETURN -5;
        END
    -- Explanation: Reject if the destination address already has an Active cart.
    IF EXISTS (SELECT 1
               FROM   dbo.Cart AS C
               WHERE  C.customer_id = @CUST
                      AND C.address_id = @address_id
                      AND C.status = 'Active')
        BEGIN
            RETURN -2;
        END
    -- Explanation: Handle SQL execution errors in the matching CATCH block.
    BEGIN TRY
        -- Explanation: Start an atomic group of changes; commit them all or roll them back.
        BEGIN TRANSACTION;
        -- Collect eligible items from the original order.
        -- Explanation: Store copyable item IDs, quantities, and notes in a local table variable.
        DECLARE @items TABLE (
            product_id INT          ,
            quantity   INT          ,
            notes      VARCHAR (255));
        -- Explanation: Collect available products from Active businesses still serving the original zone.
        INSERT INTO @items (
            product_id,
            quantity,
            notes
        )
        SELECT CI.product_id,
               CI.quantity,
               CI.notes
        FROM   dbo.Orders AS O
               INNER JOIN
               dbo.CartItem AS CI
               ON CI.cart_id = O.cart_id
               INNER JOIN
               dbo.Product AS P
               ON P.product_id = CI.product_id
               INNER JOIN
               dbo.Business AS B
               ON B.business_id = P.business_id
        WHERE  O.order_id = @order_id
               AND P.is_available = 1
               AND B.status = 'Active'
               AND B.zone_id = @ZONE;
        -- Explanation: If no items qualify, abort before changing addresses or creating a cart.
        IF NOT EXISTS (SELECT 1
                       FROM   @items)
            BEGIN
                -- Explanation: Undo uncommitted transaction changes before returning.
                ROLLBACK;
                RETURN -9;
            END
        -- Activate the chosen address.
        -- Explanation: Deactivate the customer's other addresses before selecting the destination.
        UPDATE dbo.Address
        SET    is_active = 0
        WHERE  customer_id = @CUST;
        -- Explanation: Activate the chosen address belonging to the same customer.
        UPDATE dbo.Address
        SET    is_active = 1
        WHERE  address_id = @address_id
               AND customer_id = @CUST;
        -- Create the new cart.
        -- Explanation: Insert a new Active cart for that customer and destination address.
        INSERT  INTO dbo.Cart (
            customer_id,
            address_id
        )
        VALUES                (@CUST, @address_id);
        -- Explanation: Keep the new cart ID so copied items link to the new cart, not the old order.
        DECLARE @new_cart_id AS INT;
        -- Explanation: SCOPE_IDENTITY retrieves the identity generated by the preceding Cart insert.
        SET @new_cart_id = CAST (SCOPE_IDENTITY() AS INT);
        -- Copy items; unit_price remains NULL.
        -- Explanation: Copy product IDs, quantities, and notes; do not copy historical frozen prices.
        INSERT INTO dbo.CartItem (
            cart_id,
            product_id,
            quantity,
            notes
        )
        SELECT @new_cart_id,
               product_id,
               quantity,
               notes
        FROM   @items;
        -- Explanation: Save every change made by this transaction.
        COMMIT TRANSACTION;
        -- Explanation: Report successful completion to the caller.
        RETURN 0;
    END TRY
    BEGIN CATCH
        -- Explanation: An execution error transfers control here; return the existing failure code.
        -- Explanation: Only attempt rollback when this connection still has an open transaction.
        IF @@TRANCOUNT > 0
            -- Explanation: Undo uncommitted transaction changes before returning.
            ROLLBACK;
        RETURN -1;
    END CATCH
END


GO
-- Explanation: End this batch; the following CREATE statement starts a new batch.
----------------------------------------------------------------------Cancel_Order--------------------
-- Ahmed Essam 64-21960
-- Explanation: Cancel an order before pickup and refund only its remaining unrefunded payment.
-- Explanation: Delivery has no status column: delivery cancellation follows its SubOrder status.
CREATE PROCEDURE dbo.Cancel_Order
@order_id INT
AS
BEGIN
    -- Explanation: Handle SQL execution errors in the matching CATCH block.
    BEGIN TRY
        -- Explanation: Start an atomic group of changes; commit them all or roll them back.
        BEGIN TRANSACTION;
        -- 1. Check that the order exists.
        -- Explanation: Lock and validate the order before cancellation to serialize competing changes.
        IF NOT EXISTS (SELECT 1
                       FROM   dbo.Orders WITH (UPDLOCK, HOLDLOCK)
                       WHERE  order_id = @order_id)
            BEGIN
                -- Explanation: Undo uncommitted transaction changes before returning.
                ROLLBACK;
                RETURN -1;
            END
        -- 2. Reject an already cancelled order.
        -- Explanation: Reject a previously Cancelled order to avoid processing cancellation twice.
        IF EXISTS (SELECT 1
                   FROM   dbo.Orders
                   WHERE  order_id = @order_id
                          AND status = 'Cancelled')
            BEGIN
                -- Explanation: Undo uncommitted transaction changes before returning.
                ROLLBACK;
                RETURN -4;
            END
        -- 3. Reject if anything was picked up or delivered.
        -- Explanation: Any Picked Up or Delivered suborder blocks cancellation of the whole order.
        IF EXISTS (SELECT 1
                   FROM   dbo.SubOrder WITH (UPDLOCK, HOLDLOCK)
                   WHERE  order_id = @order_id
                          AND status IN ('Picked Up', 'Delivered'))
            BEGIN
                -- Explanation: Undo uncommitted transaction changes before returning.
                ROLLBACK;
                RETURN -4;
            END
        -- 4. Read the customer, voucher, and payment details.
        -- Explanation: Keep the owner, optional voucher, payment method, and remaining refund amount.
        DECLARE @customer_id AS INT;
        DECLARE @voucher_id AS INT;
        DECLARE @method AS VARCHAR (20);
        DECLARE @refund AS DECIMAL (10, 2);
        -- Explanation: Find the customer through Cart and remember the order's voucher reference.
        SELECT @customer_id = C.customer_id,
               @voucher_id = O.voucher_id
        FROM   dbo.Orders AS O
               INNER JOIN
               dbo.Cart AS C
               ON C.cart_id = O.cart_id
        WHERE  O.order_id = @order_id;
        -- Explanation: Remaining refund = original payment amount minus previous refunds.
        SELECT @method = P.method,
               @refund = P.amount - P.refunded_amount
        FROM   dbo.Payment AS P WITH (UPDLOCK, HOLDLOCK)
        WHERE  P.order_id = @order_id;
        -- Explanation: Reject missing payment information or an invalid negative remaining refund.
        IF @method IS NULL
           OR @refund IS NULL
           OR @refund < 0
            BEGIN
                -- Explanation: Undo uncommitted transaction changes before returning.
                ROLLBACK;
                RETURN -7;
            END
        -- 5. Cancel the remaining suborders and the order.
        -- Explanation: Cancel only Placed or Assigned suborders; already Cancelled rows stay unchanged.
        UPDATE dbo.SubOrder
        SET    status = 'Cancelled'
        WHERE  order_id = @order_id
               AND status IN ('Placed', 'Assigned');
        -- Explanation: All remaining suborders are cancelled, so the parent order becomes Cancelled.
        UPDATE dbo.Orders
        SET    status = 'Cancelled'
        WHERE  order_id = @order_id;
        -- 6. Record the remaining refund.
        -- Explanation: Add the remaining refund without changing the original charged amount.
        UPDATE dbo.Payment
        SET    refunded_amount = refunded_amount + @refund
        WHERE  order_id = @order_id;
        -- 7. Non-cash refunds go to the customer's wallet.
        -- Explanation: Only Card and Wallet refunds are credited to the customer's wallet.
        IF @method <> 'Cash'
            BEGIN
                -- Explanation: Credit the remaining refund to the owning customer's wallet balance.
                UPDATE dbo.Customer
                SET    wallet_balance = wallet_balance + @refund
                WHERE  customer_id = @customer_id;
            END
        -- 8. Restore the voucher, if one was used.
        -- Explanation: If a voucher was used, restore it and detach it from the cancelled order.
        IF @voucher_id IS NOT NULL
            BEGIN
                -- Explanation: Allow the previously used voucher to be used again, subject to future validation.
                UPDATE dbo.Voucher
                SET    status = 'Unused'
                WHERE  voucher_id = @voucher_id;
                -- Explanation: Clear only the voucher reference; preserve the historical order totals.
                UPDATE dbo.Orders
                SET    voucher_id = NULL
                WHERE  order_id = @order_id;
            END
        -- Explanation: Save every change made by this transaction.
        COMMIT TRANSACTION;
        -- Explanation: Report successful completion to the caller.
        RETURN 0;
    END TRY
    BEGIN CATCH
        -- Explanation: An execution error transfers control here; return the existing failure code.
        -- Explanation: Only attempt rollback when this connection still has an open transaction.
        IF @@TRANCOUNT > 0
            -- Explanation: Undo uncommitted transaction changes before returning.
            ROLLBACK;
        RETURN -1;
    END CATCH
END
