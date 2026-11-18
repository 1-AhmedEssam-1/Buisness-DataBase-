USE LocalDeliveryMarketplace_Team_135;
GO

-- Student 5: [Abdelrahman Haitham] | [64-15002]
CREATE VIEW BusinessRatingsSummary AS
SELECT B.business_id, B.name AS business_name,
       CAST(AVG(CAST(F.rating AS DECIMAL(10,2))) AS DECIMAL(10,2)) AS avg_rating,
       COUNT(F.feedback_id) AS ratings_count
FROM Business AS B
LEFT JOIN SubOrder AS S ON S.business_id = B.business_id
LEFT JOIN Feedback AS F ON F.suborder_id = S.suborder_id
GROUP BY B.business_id, B.name;
GO

-- Student 5: [Abdelrahman Haitham] | [64-15002]
CREATE VIEW RiderPerformanceSummary AS
SELECT R.rider_id,
       U.first_name + ' ' + U.last_name AS rider_name,
       Z.zone_name,
       COUNT(CASE WHEN S.status = 'Delivered' THEN D.delivery_id END) AS completed_deliveries,
       CAST(AVG(CASE WHEN S.status = 'Delivered' THEN CAST(D.rider_rating AS DECIMAL(10,2)) END) AS DECIMAL(10,2)) AS avg_rating
FROM Rider AS R
INNER JOIN Users AS U ON U.user_id = R.rider_id
INNER JOIN Zone AS Z ON Z.zone_id = R.zone_id
LEFT JOIN Delivery AS D ON D.rider_id = R.rider_id
LEFT JOIN SubOrder AS S ON S.suborder_id = D.suborder_id
GROUP BY R.rider_id, U.first_name, U.last_name, Z.zone_name;
GO

-- Student 5: [Abdelrahman Haitham] | [64-15002]
CREATE VIEW ZoneDeliveryPerformance AS
SELECT Z.zone_id, Z.zone_name,
       COUNT(D.delivery_id) AS delivery_count,
       CAST(AVG(CAST(D.tracking_time AS DECIMAL(10,2))) AS DECIMAL(10,2)) AS avg_tracking_time
FROM Zone AS Z
LEFT JOIN Orders AS O ON O.zone_id = Z.zone_id
LEFT JOIN SubOrder AS S ON S.order_id = O.order_id AND S.status = 'Delivered'
LEFT JOIN Delivery AS D ON D.suborder_id = S.suborder_id
GROUP BY Z.zone_id, Z.zone_name;
GO

-- Student 5: [Abdelrahman Haitham] | [64-15002]
CREATE FUNCTION TopRiders
(
    @from_date DATE,
    @to_date DATE
)
RETURNS TABLE
AS
RETURN
(
    SELECT TOP (5)
           RANK() OVER (ORDER BY COUNT(D.delivery_id) DESC, R.rider_id ASC) AS rider_rank,
           R.rider_id,
           U.first_name + ' ' + U.last_name AS rider_name,
           COUNT(D.delivery_id) AS completed_delivery_count
    FROM Rider AS R
    INNER JOIN Users AS U ON U.user_id = R.rider_id
    INNER JOIN Delivery AS D ON D.rider_id = R.rider_id
    INNER JOIN SubOrder AS S ON S.suborder_id = D.suborder_id
    WHERE @from_date IS NOT NULL AND @to_date IS NOT NULL AND @from_date <= @to_date
      AND S.status = 'Delivered'
      AND CAST(D.delivered_at AS DATE) BETWEEN @from_date AND @to_date
    GROUP BY R.rider_id, U.first_name, U.last_name
    HAVING COUNT(D.delivery_id) > 0
    ORDER BY COUNT(D.delivery_id) DESC, R.rider_id ASC
);
GO

-- Student 5: [Abdelrahman Haitham] | [64-15002]
CREATE FUNCTION BusinessFeedbackOverview
(
    @business_id INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT CAST(AVG(CAST(F.rating AS DECIMAL(10,2))) AS DECIMAL(10,2)) AS avg_rating,
           COUNT(F.feedback_id) AS number_of_feedbacks,
           SUM(CASE WHEN F.rating = 5 THEN 1 ELSE 0 END) AS five_star,
           SUM(CASE WHEN F.rating = 4 THEN 1 ELSE 0 END) AS four_star,
           SUM(CASE WHEN F.rating = 3 THEN 1 ELSE 0 END) AS three_star,
           SUM(CASE WHEN F.rating = 2 THEN 1 ELSE 0 END) AS two_star,
           SUM(CASE WHEN F.rating = 1 THEN 1 ELSE 0 END) AS one_star
    FROM Business AS B
    LEFT JOIN SubOrder AS S ON S.business_id = B.business_id
    LEFT JOIN Feedback AS F ON F.suborder_id = S.suborder_id
    WHERE B.business_id = @business_id
    GROUP BY B.business_id
);
GO

-- Student 5: [Abdelrahman Haitham] | [64-15002]
CREATE PROCEDURE Submit_Feedback
    @suborder_id INT,
    @headline VARCHAR(100),
    @description VARCHAR(500),
    @rating INT
AS
BEGIN
    IF @suborder_id IS NULL OR @headline IS NULL
       OR LEN(LTRIM(RTRIM(@headline))) = 0
       OR @rating IS NULL OR @rating NOT BETWEEN 1 AND 5
       OR NOT EXISTS (SELECT 1 FROM SubOrder WHERE suborder_id = @suborder_id)
        RETURN -1;

    IF NOT EXISTS (SELECT 1 FROM SubOrder
                   WHERE suborder_id = @suborder_id AND status = 'Delivered')
        RETURN -4;

    IF EXISTS (SELECT 1 FROM Feedback WHERE suborder_id = @suborder_id)
        RETURN -2;

    INSERT INTO Feedback (headline, description, rating, feedback_date, suborder_id)
    VALUES (@headline, @description, @rating, GETDATE(), @suborder_id);
    RETURN 0;
END;
GO

-- Student 5: [Abdelrahman Haitham] | [64-15002]
CREATE PROCEDURE Rate_Rider
    @suborder_id INT,
    @rider_rating INT
AS
BEGIN
    IF @suborder_id IS NULL OR @rider_rating IS NULL
       OR @rider_rating NOT BETWEEN 1 AND 5
       OR NOT EXISTS (SELECT 1 FROM SubOrder WHERE suborder_id = @suborder_id)
        RETURN -1;

    IF NOT EXISTS
       (SELECT 1 FROM SubOrder AS S
        INNER JOIN Delivery AS D ON D.suborder_id = S.suborder_id
        WHERE S.suborder_id = @suborder_id AND S.status = 'Delivered')
        RETURN -4;

    IF EXISTS (SELECT 1 FROM Delivery
               WHERE suborder_id = @suborder_id AND rider_rating IS NOT NULL)
        RETURN -2;

    UPDATE Delivery SET rider_rating = @rider_rating
    WHERE suborder_id = @suborder_id;
    RETURN 0;
END;
GO

-- Student 5: [Abdelrahman Haitham] | [64-15002]
CREATE FUNCTION Recommended_Products
(
    @customer_id INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT TOP (10)
           P.product_id,
           P.name AS product_name,
           B.name AS business_name,
           P.category,
           CAST(P.price - P.discount_amount AS DECIMAL(10,2)) AS final_price
    FROM Product AS P
    INNER JOIN Business AS B ON B.business_id = P.business_id
    INNER JOIN Address AS A ON A.customer_id = @customer_id
                           AND A.is_active = 1 AND A.zone_id = B.zone_id
    INNER JOIN Users AS U ON U.user_id = @customer_id AND U.account_status = 'Active'
    INNER JOIN
       (SELECT PastProduct.category, SUM(PastItem.quantity) AS category_order_count
        FROM Orders AS PastOrder
        INNER JOIN Cart AS PastCart ON PastCart.cart_id = PastOrder.cart_id
        INNER JOIN CartItem AS PastItem ON PastItem.cart_id = PastCart.cart_id
        INNER JOIN Product AS PastProduct ON PastProduct.product_id = PastItem.product_id
        WHERE PastCart.customer_id = @customer_id
        GROUP BY PastProduct.category) AS History
        ON History.category = P.category
    WHERE P.is_available = 1
      AND B.status = 'Active'
      AND NOT EXISTS
         (SELECT 1 FROM Orders AS OldOrder
          INNER JOIN Cart AS OldCart ON OldCart.cart_id = OldOrder.cart_id
          INNER JOIN CartItem AS OldItem ON OldItem.cart_id = OldCart.cart_id
          WHERE OldCart.customer_id = @customer_id AND OldItem.product_id = P.product_id)
    ORDER BY History.category_order_count DESC, P.product_id ASC
);
GO

-- Student 5: [Abdelrahman Haitham] | [64-15002]
CREATE PROCEDURE Set_Rider_Availability
    @rider_id INT,
    @is_available BIT
AS
BEGIN
    IF @rider_id IS NULL OR @is_available IS NULL
        RETURN -1;

    -- Wrong user type is -3, not invalid input (-1).
    IF NOT EXISTS (SELECT 1 FROM Rider WHERE rider_id = @rider_id)
        RETURN -3;

    UPDATE Rider
    SET is_available = @is_available
    WHERE rider_id = @rider_id;
    RETURN 0;
END;
GO

-- Student 5: [Abdelrahman Haitham] | [64-15002]
CREATE FUNCTION My_Active_Deliveries
(
    @rider_id INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT D.delivery_id, O.order_id, S.suborder_id,
           B.name AS business_name,
           U.first_name + ' ' + U.last_name AS customer_name,
           A.description AS address_description,
           Z.zone_name,
           S.status,
           D.assigned_at
    FROM Delivery AS D
    INNER JOIN SubOrder AS S ON S.suborder_id = D.suborder_id
    INNER JOIN Orders AS O ON O.order_id = S.order_id
    INNER JOIN Cart AS C ON C.cart_id = O.cart_id
    INNER JOIN Address AS A ON A.address_id = C.address_id
    INNER JOIN Users AS U ON U.user_id = C.customer_id
    INNER JOIN Business AS B ON B.business_id = S.business_id
    INNER JOIN Zone AS Z ON Z.zone_id = O.zone_id
    WHERE D.rider_id = @rider_id AND S.status IN ('Assigned', 'Picked Up')
);
GO

-- Student 5: [Abdelrahman Haitham] | [64-15002]
CREATE PROCEDURE Mark_Picked_Up
    @delivery_id INT
AS
BEGIN
    DECLARE @suborder_id INT;
    DECLARE @order_id INT;
    DECLARE @status VARCHAR(20);
    DECLARE @now DATETIME;

    SELECT @suborder_id = S.suborder_id, @order_id = S.order_id, @status = S.status
    FROM Delivery AS D
    INNER JOIN SubOrder AS S ON S.suborder_id = D.suborder_id
    WHERE D.delivery_id = @delivery_id;

    IF @delivery_id IS NULL OR @suborder_id IS NULL RETURN -1;
    IF @status <> 'Assigned' RETURN -4;

    SET @now = GETDATE();
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE SubOrder SET status = 'Picked Up'
        WHERE suborder_id = @suborder_id;
        UPDATE Delivery SET picked_up_at = @now
        WHERE delivery_id = @delivery_id;
        -- At least one suborder is now Picked Up, so the order is In Progress.
        UPDATE Orders SET status = 'In Progress'
        WHERE order_id = @order_id;
        COMMIT TRANSACTION;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        RETURN -1;
    END CATCH
END;
GO

-- Student 5: [Abdelrahman Haitham] | [64-15002]
CREATE PROCEDURE Mark_Delivered
    @delivery_id INT
AS
BEGIN
    DECLARE @suborder_id INT;
    DECLARE @order_id INT;
    DECLARE @status VARCHAR(20);
    DECLARE @picked_up_at DATETIME;
    DECLARE @now DATETIME;

    SELECT @suborder_id = S.suborder_id, @order_id = S.order_id,
           @status = S.status, @picked_up_at = D.picked_up_at
    FROM Delivery AS D
    INNER JOIN SubOrder AS S ON S.suborder_id = D.suborder_id
    WHERE D.delivery_id = @delivery_id;

    IF @delivery_id IS NULL OR @suborder_id IS NULL RETURN -1;
    IF @status <> 'Picked Up' OR @picked_up_at IS NULL RETURN -4;

    SET @now = GETDATE();
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE SubOrder SET status = 'Delivered'
        WHERE suborder_id = @suborder_id;
        UPDATE Delivery
        SET delivered_at = @now,
            tracking_time = DATEDIFF(MINUTE, @picked_up_at, @now)
        WHERE delivery_id = @delivery_id;

        -- BR-11: recompute using every SubOrder of the parent order.
        UPDATE Orders
        SET status = CASE
                        WHEN NOT EXISTS
                            (SELECT 1 FROM SubOrder AS S
                             WHERE S.order_id = @order_id AND S.status <> 'Cancelled')
                        THEN 'Cancelled'
                        WHEN NOT EXISTS
                            (SELECT 1 FROM SubOrder AS S
                             WHERE S.order_id = @order_id
                               AND S.status NOT IN ('Cancelled', 'Delivered'))
                        THEN 'Delivered'
                        WHEN EXISTS
                            (SELECT 1 FROM SubOrder AS S
                             WHERE S.order_id = @order_id
                               AND S.status IN ('Picked Up', 'Delivered'))
                        THEN 'In Progress'
                        ELSE 'Placed'
                    END
        WHERE order_id = @order_id;
        COMMIT TRANSACTION;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        RETURN -1;
    END CATCH
END;
GO

-- Student 5: [Abdelrahman Haitham] | [64-15002]
CREATE FUNCTION My_Earnings
(
    @rider_id INT,
    @from_date DATE,
    @to_date DATE
)
RETURNS TABLE
AS
RETURN
(
    SELECT COUNT(CASE WHEN S.status = 'Delivered' THEN D.delivery_id END) AS completed_deliveries,
           CAST(ISNULL(SUM(CASE WHEN S.status = 'Delivered'
                                THEN S.delivery_fee ELSE 0 END), 0) AS DECIMAL(10,2)) AS total_delivery_fees,
           CAST(ISNULL(SUM(CASE WHEN S.status = 'Delivered'
                                THEN S.delivery_fee * 0.80 ELSE 0 END), 0) AS DECIMAL(10,2)) AS total_earnings
    FROM Rider AS R
    LEFT JOIN Delivery AS D ON D.rider_id = R.rider_id
        AND CAST(D.delivered_at AS DATE) BETWEEN @from_date AND @to_date
    LEFT JOIN SubOrder AS S ON S.suborder_id = D.suborder_id
    WHERE R.rider_id = @rider_id
      AND @from_date IS NOT NULL AND @to_date IS NOT NULL AND @from_date <= @to_date
    GROUP BY R.rider_id
);
GO

-- Student 5: [Abdelrahman Haitham] | [64-15002]
CREATE FUNCTION My_Rating_Summary
(
    @rider_id INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT CAST(AVG(CAST(D.rider_rating AS DECIMAL(10,2))) AS DECIMAL(10,2)) AS avg_rating,
           COUNT(D.rider_rating) AS ratings_count,
           SUM(CASE WHEN D.rider_rating = 5 THEN 1 ELSE 0 END) AS five_star,
           SUM(CASE WHEN D.rider_rating = 4 THEN 1 ELSE 0 END) AS four_star,
           SUM(CASE WHEN D.rider_rating = 3 THEN 1 ELSE 0 END) AS three_star,
           SUM(CASE WHEN D.rider_rating = 2 THEN 1 ELSE 0 END) AS two_star,
           SUM(CASE WHEN D.rider_rating = 1 THEN 1 ELSE 0 END) AS one_star
    FROM Rider AS R
    LEFT JOIN Delivery AS D ON D.rider_id = R.rider_id
    WHERE R.rider_id = @rider_id
    GROUP BY R.rider_id
);
GO

-- Student 5: [Abdelrahman Haitham] | [64-15002]
CREATE FUNCTION My_Delivery_History
(
    @rider_id INT,
    @from_date DATE,
    @to_date DATE
)
RETURNS TABLE
AS
RETURN
(
    SELECT D.delivery_id, O.order_id, B.name AS business_name,
           S.status, D.assigned_at, D.picked_up_at, D.delivered_at,
           D.tracking_time
    FROM Delivery AS D
    INNER JOIN SubOrder AS S ON S.suborder_id = D.suborder_id
    INNER JOIN Orders AS O ON O.order_id = S.order_id
    INNER JOIN Business AS B ON B.business_id = S.business_id
    WHERE D.rider_id = @rider_id
      AND S.status IN ('Delivered', 'Cancelled')
      AND @from_date IS NOT NULL AND @to_date IS NOT NULL AND @from_date <= @to_date
      AND CAST(D.assigned_at AS DATE) BETWEEN @from_date AND @to_date
);
GO

-- Student 5: [Abdelrahman Haitham] | [64-15002]
CREATE FUNCTION Reconcile_Order_Totals()
RETURNS TABLE
AS
RETURN
(
    SELECT O.order_id,
           CAST(ISNULL(T.suborder_sum, 0) - O.discount_amount AS DECIMAL(10,2)) AS expected_total,
           O.total_amount AS order_total,
           P.amount AS payment_amount
    FROM Orders AS O
    LEFT JOIN
         (SELECT S.order_id, SUM(S.total_price + S.delivery_fee) AS suborder_sum
          FROM SubOrder AS S
          GROUP BY S.order_id) AS T
          ON T.order_id = O.order_id
    LEFT JOIN Payment AS P ON P.order_id = O.order_id
    WHERE P.payment_id IS NULL
       OR O.total_amount <> ISNULL(T.suborder_sum, 0) - O.discount_amount
       OR P.amount <> O.total_amount
);
GO

-- Student 5: [Abdelrahman Haitham] | [64-15002]
CREATE FUNCTION Platform_Health_Snapshot()
RETURNS TABLE
AS
RETURN
(
    SELECT
        (SELECT COUNT(*) FROM Business WHERE status = 'Active') AS active_businesses,
        (SELECT COUNT(*)
         FROM Rider AS R
         INNER JOIN Users AS U ON U.user_id = R.rider_id
         WHERE R.is_available = 1 AND U.account_status = 'Active') AS available_riders,
        (SELECT COUNT(*)
         FROM Orders WHERE CAST(order_date AS DATE) = CAST(GETDATE() AS DATE)) AS orders_today,
        (SELECT CAST(AVG(CAST(D.tracking_time AS DECIMAL(10,2))) AS DECIMAL(10,2))
         FROM Delivery AS D
         INNER JOIN SubOrder AS S ON S.suborder_id = D.suborder_id
         WHERE S.status = 'Delivered'
           AND CAST(D.delivered_at AS DATE) = CAST(GETDATE() AS DATE)) AS avg_delivery_time_today,
        (SELECT COUNT(*)
         FROM Feedback AS F
         WHERE F.rating <= 2
           AND CAST(F.feedback_date AS DATE) = CAST(GETDATE() AS DATE)) AS low_ratings_today
);
GO