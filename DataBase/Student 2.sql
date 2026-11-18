USE LocalDeliveryMarketplace_Team_135;
GO 

-- Student 2: [Mohamed Omar] | [64-6795]
CREATE VIEW allBusinessProfiles AS
SELECT B.business_id,
       B.name AS business_name,
       CASE WHEN R.business_id IS NOT NULL THEN 'Restaurant' ELSE 'Pharmacy' END AS business_type,
       Z.zone_name,
       U.first_name + ' ' + U.last_name AS partner_name,
       B.status,
       B.opening_hour,
       B.closing_hour
FROM Business AS B
INNER JOIN Zone AS Z ON B.zone_id = Z.zone_id
INNER JOIN Partner AS P ON B.partner_id = P.partner_id
INNER JOIN Users AS U ON P.partner_id = U.user_id
LEFT JOIN Restaurant AS R ON B.business_id = R.business_id;
GO

-- Student 2: [Mohamed Omar] | [64-6795]
CREATE VIEW PendingBusinessApprovals AS
SELECT B.business_id,
       B.name AS business_name,
       CASE WHEN R.business_id IS NOT NULL THEN 'Restaurant' ELSE 'Pharmacy' END AS business_type,
       Z.zone_name,
       U.first_name + ' ' + U.last_name AS partner_name
FROM Business AS B
INNER JOIN Zone AS Z ON B.zone_id = Z.zone_id
INNER JOIN Users AS U ON B.partner_id = U.user_id
LEFT JOIN Restaurant AS R ON B.business_id = R.business_id
WHERE B.status = 'Pending';
GO

-- Student 2: [Mohamed Omar] | [64-6795]
CREATE VIEW TopSellingProducts AS
SELECT TOP (10)
       P.product_id,
       P.name AS product_name,
       B.name AS business_name,
       CASE WHEN R.business_id IS NOT NULL THEN 'Restaurant' ELSE 'Pharmacy' END AS business_type,
       SUM(CI.quantity) AS units_sold,
       SUM(CI.quantity * CI.unit_price) AS total_revenue
FROM Product AS P
INNER JOIN Business AS B ON B.business_id = P.business_id
LEFT JOIN Restaurant AS R ON R.business_id = B.business_id
INNER JOIN CartItem AS CI ON CI.product_id = P.product_id
INNER JOIN Orders AS O ON O.cart_id = CI.cart_id
INNER JOIN SubOrder AS S ON S.order_id = O.order_id
                         AND S.business_id = B.business_id
WHERE S.status <> 'Cancelled'
GROUP BY P.product_id, P.name, B.name, R.business_id
ORDER BY SUM(CI.quantity) DESC, P.product_id ASC;
GO

-- Student 2: [Mohamed Omar] | [64-6795]
CREATE PROCEDURE Register_Business
    @partner_id INT,
    @name VARCHAR(100),
    @description VARCHAR(255),
    @link_website VARCHAR(255),
    @zone_id INT,
    @opening_hour TIME,
    @closing_hour TIME,
    @expected_delivery_time INT,
    @phone CHAR(11),
    @business_type VARCHAR(20),
    @cuisine_type VARCHAR(50),
    @food_category VARCHAR(50),
    @pharmacy_type VARCHAR(50)
AS
BEGIN
    DECLARE @business_id INT;
    DECLARE @current_status VARCHAR(20);

    IF @partner_id IS NULL OR @zone_id IS NULL
       OR NOT EXISTS (SELECT 1 FROM Zone WHERE zone_id = @zone_id)
       OR @name IS NULL OR LEN(LTRIM(RTRIM(@name))) = 0
       OR @opening_hour IS NULL OR @closing_hour IS NULL
       OR @expected_delivery_time IS NULL OR @expected_delivery_time <= 0
       OR @phone IS NULL OR LEN(@phone) <> 11 OR @phone LIKE '%[^0-9]%'
       OR @business_type IS NULL OR @business_type NOT IN ('Restaurant', 'Pharmacy')
       OR (@business_type = 'Restaurant' AND
          (@cuisine_type IS NULL OR LEN(LTRIM(RTRIM(@cuisine_type))) = 0
           OR @food_category IS NULL OR LEN(LTRIM(RTRIM(@food_category))) = 0
           OR @pharmacy_type IS NOT NULL))
       OR (@business_type = 'Pharmacy' AND
          (@pharmacy_type IS NULL OR LEN(LTRIM(RTRIM(@pharmacy_type))) = 0
           OR @cuisine_type IS NOT NULL OR @food_category IS NOT NULL))
        RETURN -1;

    -- A valid user without the Partner role is not authorized to register a business.
    IF NOT EXISTS (SELECT 1 FROM Partner WHERE partner_id = @partner_id)
        RETURN -3;

    SELECT @business_id = business_id, @current_status = status
    FROM Business WHERE partner_id = @partner_id;

    IF @business_id IS NOT NULL AND @current_status <> 'Rejected'
        RETURN -2;

    BEGIN TRY
        BEGIN TRANSACTION;
        IF @business_id IS NULL
        BEGIN
            INSERT INTO Business
                (name, description, link_website, opening_hour, closing_hour,
                 expected_delivery_time, status, suspension_reason, partner_id, zone_id)
            VALUES
                (@name, @description, @link_website, @opening_hour, @closing_hour,
                 @expected_delivery_time, 'Pending', NULL, @partner_id, @zone_id);

            SELECT @business_id = business_id FROM Business WHERE partner_id = @partner_id;
        END
        ELSE
        BEGIN
            UPDATE Business
            SET name = @name,
                description = @description,
                link_website = @link_website,
                opening_hour = @opening_hour,
                closing_hour = @closing_hour,
                expected_delivery_time = @expected_delivery_time,
                status = 'Pending',
                suspension_reason = NULL,
                zone_id = @zone_id
            WHERE business_id = @business_id;

            DELETE FROM Business_Phone WHERE business_id = @business_id;
            DELETE FROM Restaurant WHERE business_id = @business_id;
            DELETE FROM Pharmacy WHERE business_id = @business_id;
        END

        INSERT INTO Business_Phone (business_id, phone) VALUES (@business_id, @phone);

        IF @business_type = 'Restaurant'
            INSERT INTO Restaurant (business_id, cuisine_type, food_category)
            VALUES (@business_id, @cuisine_type, @food_category);
        ELSE
            INSERT INTO Pharmacy (business_id, pharmacy_type)
            VALUES (@business_id, @pharmacy_type);

        COMMIT TRANSACTION;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        RETURN -1;
    END CATCH
END;
GO

-- Student 2: [Mohamed Omar] | [64-6795]
CREATE PROCEDURE Update_Business_Info
    @business_id INT,
    @opening_hour TIME,
    @closing_hour TIME,
    @phone CHAR(11),
    @link_website VARCHAR(255)
AS
BEGIN
    IF @business_id IS NULL OR NOT EXISTS (SELECT 1 FROM Business WHERE business_id = @business_id)
       OR @opening_hour IS NULL OR @closing_hour IS NULL
       OR @phone IS NULL OR LEN(@phone) <> 11 OR @phone LIKE '%[^0-9]%'
        RETURN -1;

    IF EXISTS (SELECT 1 FROM Business_Phone
               WHERE business_id = @business_id AND phone = @phone)
        RETURN -2;

    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE Business
        SET opening_hour = @opening_hour,
            closing_hour = @closing_hour,
            link_website = @link_website
        WHERE business_id = @business_id;

        INSERT INTO Business_Phone (business_id, phone)
        VALUES (@business_id, @phone);
        COMMIT TRANSACTION;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        RETURN -1;
    END CATCH
END;
GO

-- Student 2: [Mohamed Omar] | [64-6795]
CREATE PROCEDURE Upsert_Product
    @business_id INT,
    @product_id INT,
    @name VARCHAR(100),
    @description VARCHAR(255),
    @category VARCHAR(50),
    @price DECIMAL(10,2),
    @is_available BIT
AS
BEGIN
    IF @business_id IS NULL OR NOT EXISTS (SELECT 1 FROM Business WHERE business_id = @business_id)
       OR @name IS NULL OR LEN(LTRIM(RTRIM(@name))) = 0
       OR @category IS NULL OR LEN(LTRIM(RTRIM(@category))) = 0
       OR @price IS NULL OR @price <= 0 OR @is_available IS NULL
        RETURN -1;

    IF EXISTS (SELECT 1 FROM Business
               WHERE business_id = @business_id AND status = 'Suspended')
        RETURN -4;

    IF @product_id IS NULL
    BEGIN
        INSERT INTO Product
            (name, description, category, price, discount_amount, is_available, business_id)
        VALUES (@name, @description, @category, @price, 0, @is_available, @business_id);
        RETURN 0;
    END

    IF NOT EXISTS (SELECT 1 FROM Product
                   WHERE product_id = @product_id AND business_id = @business_id)
        RETURN -3;

    IF EXISTS (SELECT 1 FROM Product
               WHERE product_id = @product_id AND discount_amount > @price * 0.5)
        RETURN -1;

    UPDATE Product
    SET name = @name,
        description = @description,
        category = @category,
        price = @price,
        is_available = @is_available
    WHERE product_id = @product_id;
    RETURN 0;
END;
GO

-- Student 2: [Mohamed Omar] | [64-6795]
CREATE PROCEDURE Toggle_Product_Status
    @product_id INT,
    @is_available BIT
AS
BEGIN
    IF @product_id IS NULL OR @is_available IS NULL
       OR NOT EXISTS (SELECT 1 FROM Product WHERE product_id = @product_id)
        RETURN -1;

    IF @is_available = 1 AND EXISTS
        (SELECT 1 FROM Product AS P
         INNER JOIN Business AS B ON P.business_id = B.business_id
         WHERE P.product_id = @product_id AND B.status = 'Suspended')
        RETURN -4;

    UPDATE Product SET is_available = @is_available
    WHERE product_id = @product_id;
    RETURN 0;
END;
GO

-- Student 2: [Mohamed Omar] | [64-6795]
CREATE PROCEDURE Set_Product_Promotion
    @product_id INT,
    @discount_amount DECIMAL(10,2)
AS
BEGIN
    IF @product_id IS NULL OR @discount_amount IS NULL OR @discount_amount < 0
       OR NOT EXISTS (SELECT 1 FROM Product WHERE product_id = @product_id)
       OR EXISTS (SELECT 1 FROM Product
                  WHERE product_id = @product_id AND @discount_amount > price * 0.5)
        RETURN -1;

    UPDATE Product SET discount_amount = @discount_amount
    WHERE product_id = @product_id;
    RETURN 0;
END;
GO

-- Student 2: [Mohamed Omar] | [64-6795]
CREATE FUNCTION BusinessSalesReport
(
    @business_id INT,
    @from_date DATE,
    @to_date DATE
)
RETURNS TABLE
AS
RETURN
(
    SELECT P.product_id, P.name AS product_name,
           SUM(CI.quantity) AS units_sold,
           SUM(CI.quantity * CI.unit_price) AS revenue_per_product
    FROM Product AS P
    INNER JOIN CartItem AS CI ON CI.product_id = P.product_id
    INNER JOIN Orders AS O ON O.cart_id = CI.cart_id
    INNER JOIN SubOrder AS S ON S.order_id = O.order_id
                            AND S.business_id = P.business_id
    WHERE P.business_id = @business_id
      AND S.status <> 'Cancelled'
      AND @from_date IS NOT NULL AND @to_date IS NOT NULL AND @from_date <= @to_date
      AND CAST(O.order_date AS DATE) BETWEEN @from_date AND @to_date
    GROUP BY P.product_id, P.name
);
GO

-- Student 2: [Mohamed Omar] | [64-6795]
CREATE FUNCTION Search_Platform
(
    @customer_id INT,
    @keyword VARCHAR(100)
)
RETURNS TABLE
AS
RETURN
(
    SELECT TOP (2147483647)
           B.business_id, B.name AS business_name,
           CASE WHEN B.name = @keyword THEN 1
                WHEN B.name LIKE @keyword + '%' THEN 2
                ELSE 3 END AS priority
    FROM Business AS B
    INNER JOIN Address AS A ON B.zone_id = A.zone_id
    INNER JOIN Users AS U ON U.user_id = A.customer_id
    WHERE A.customer_id = @customer_id
      AND A.is_active = 1
      AND U.account_status = 'Active'
      AND B.status = 'Active'
      AND @keyword IS NOT NULL AND LEN(LTRIM(RTRIM(@keyword))) > 0
      AND B.name LIKE '%' + @keyword + '%'
    ORDER BY CASE WHEN B.name = @keyword THEN 1
                  WHEN B.name LIKE @keyword + '%' THEN 2
                  ELSE 3 END ASC, B.business_id ASC
);
GO

-- Student 2: [Mohamed Omar] | [64-6795]
CREATE FUNCTION Nearby_Businesses_By_Category
(
    @address_id INT,
    @product_category VARCHAR(50)
)
RETURNS TABLE
AS
RETURN
(
    SELECT TOP (2147483647)
           B.business_id, B.name AS business_name, Z.zone_name,
           CASE WHEN B.zone_id = A.zone_id THEN 1 ELSE 0 END AS same_zone,
           (SELECT AVG(CAST(D.tracking_time AS DECIMAL(10,2)))
            FROM Business AS B2
            INNER JOIN SubOrder AS S ON S.business_id = B2.business_id
            INNER JOIN Delivery AS D ON D.suborder_id = S.suborder_id
            WHERE B2.zone_id = B.zone_id AND S.status = 'Delivered') AS zone_avg_delivery_time
    FROM Business AS B
    INNER JOIN Zone AS Z ON Z.zone_id = B.zone_id
    INNER JOIN Address AS A ON A.address_id = @address_id
    WHERE B.status = 'Active'
      AND @product_category IS NOT NULL
      AND EXISTS
          (SELECT 1 FROM Product AS P
           WHERE P.business_id = B.business_id
             AND P.is_available = 1 AND P.category = @product_category)
    ORDER BY CASE WHEN B.zone_id = A.zone_id THEN 1 ELSE 0 END DESC,
             zone_avg_delivery_time ASC, B.business_id ASC
);
GO

-- Student 2: [Mohamed Omar] | [64-6795]
CREATE PROCEDURE Toggle_Favorite
    @customer_id INT,
    @item_id INT,
    @item_type VARCHAR(20)
AS
BEGIN
    IF @customer_id IS NULL OR @item_id IS NULL
       OR @item_type IS NULL OR @item_type NOT IN ('Business', 'Product')
        RETURN -1;

    IF NOT EXISTS (SELECT 1 FROM Customer WHERE customer_id = @customer_id)
        RETURN -3;

    IF EXISTS (SELECT 1 FROM Users
               WHERE user_id = @customer_id AND account_status = 'Blacklisted')
        RETURN -3;

    IF @item_type = 'Business'
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM Business WHERE business_id = @item_id)
            RETURN -1;

        IF EXISTS (SELECT 1 FROM Favorite_Business
                   WHERE customer_id = @customer_id AND business_id = @item_id)
            DELETE FROM Favorite_Business
            WHERE customer_id = @customer_id AND business_id = @item_id;
        ELSE
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM Business
                           WHERE business_id = @item_id AND status = 'Active')
                RETURN -4;

            INSERT INTO Favorite_Business (customer_id, business_id)
            VALUES (@customer_id, @item_id);
        END
    END
    ELSE
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM Product WHERE product_id = @item_id)
            RETURN -1;

        IF EXISTS (SELECT 1 FROM Favorite_Product
                   WHERE customer_id = @customer_id AND product_id = @item_id)
            DELETE FROM Favorite_Product
            WHERE customer_id = @customer_id AND product_id = @item_id;
        ELSE
        BEGIN
            IF NOT EXISTS
                (SELECT 1 FROM Product AS P
                 INNER JOIN Business AS B ON B.business_id = P.business_id
                 WHERE P.product_id = @item_id AND P.is_available = 1
                   AND B.status = 'Active')
                RETURN -4;

            INSERT INTO Favorite_Product (customer_id, product_id)
            VALUES (@customer_id, @item_id);
        END
    END
    RETURN 0;
END;
GO

-- Student 2: [Mohamed Omar] | [64-6795]
CREATE FUNCTION My_Favorites
(
    @customer_id INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT P.product_id, P.name AS product_name,
           B.name AS business_name,
           CASE WHEN P.is_available = 1 AND B.status = 'Active'
                      AND U.account_status = 'Active'
                      AND A.address_id IS NOT NULL AND A.zone_id = B.zone_id
                      AND (
                           B.opening_hour = B.closing_hour
                           OR (B.opening_hour < B.closing_hour
                               AND CAST(GETDATE() AS TIME) >= B.opening_hour
                               AND CAST(GETDATE() AS TIME) < B.closing_hour)
                           OR (B.opening_hour > B.closing_hour
                               AND (CAST(GETDATE() AS TIME) >= B.opening_hour
                                    OR CAST(GETDATE() AS TIME) < B.closing_hour))
                      )
                THEN 1 ELSE 0 END AS is_orderable
    FROM Favorite_Product AS FP
    INNER JOIN Product AS P ON P.product_id = FP.product_id
    INNER JOIN Business AS B ON B.business_id = P.business_id
    INNER JOIN Users AS U ON U.user_id = FP.customer_id
    LEFT JOIN Address AS A ON A.customer_id = FP.customer_id AND A.is_active = 1
    WHERE FP.customer_id = @customer_id
);
GO