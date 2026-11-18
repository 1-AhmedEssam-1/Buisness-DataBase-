Go 
Create database  LocalDeliveryMarketplace_Team_135

Go 
use LocalDeliveryMarketplace_Team_135

Go
-- Student 4: <Mohamed Abdelaiz Abdelhakim> - <64-21045>
Create Procedure createAllTables 
as

 Create table Zone(
 zone_id INT Primary key identity(1,1),
 zone_name Varchar(50) Not null Unique ,
 delivery_fee  decimal(10,2) not null check (delivery_fee >= 0)
 );

Create table Users(
user_id int identity(1,1) Primary key,
first_name varchar(30) Not null,
middle_name varchar(30),
last_name varchar(30) Not null,
username varchar(30) Not null UNIQUE ,
password varchar(30) Not null,
email varchar(100) Not null UNIQUE ,
dob date ,
account_status varchar(20) Not null DEFAULT 'Active' ,
Constraint Account_Status_CK check(account_status in ('Active','Blacklisted') )
 );

 Create Table User_Phone(
 user_id int ,
 phone char(11) ,
 Constraint user_id_FK FOREIGN KEY (user_id) REFERENCES Users(user_id),
 Constraint User_Phone_PK PRIMARY KEY (user_id, phone)
 );

 Create Table Admin (
 admin_id int PRIMARY KEY ,
 role varchar(20) not null DEFAULT 'Super Admin',
 zone_id int ,
 Constraint Admin_User_FK FOREIGN KEY (admin_id) REFERENCES Users(user_id),
 Constraint Admin_Zone_FK FOREIGN KEY (zone_id) REFERENCES Zone(zone_id),
 Constraint Admin_Role_CK check(role in ('Super Admin','Zone Admin') ),
 Constraint Admin_Role_Zone_CK check ((role = 'Super Admin' and zone_id is null) or (role = 'Zone Admin'  and zone_id is not null))
 );

 Create Table Partner(
 partner_id int Primary key,
 Constraint partner_id_FK FOREIGN KEY (partner_id) REFERENCES Users(user_id)
 );

 Create Table Rider(
 rider_id int Primary key,
 vehicle_type varchar(30) not null,
 plate_no varchar(15) not null UNIQUE,
 license_no varchar(20) not null UNIQUE,
 is_available bit not null DEFAULT 1,
 zone_id int not null,
 Constraint Rider_User_FK FOREIGN KEY (rider_id) REFERENCES Users(user_id),
 Constraint Rider_Zone_FK FOREIGN KEY (zone_id) REFERENCES Zone(zone_id)
 );

 Create Table Customer(
 customer_id int Primary key,
 wallet_balance decimal(10,2) not null DEFAULT 0 CHECK (wallet_balance >= 0),
 Constraint customer_id FOREIGN KEY (customer_id) REFERENCES Users(user_id)
 );

 Create Table Address(
  address_id int identity(1,1) Primary key,
  description varchar(150) not null ,
  is_active bit not null DEFAULT 1 ,
  customer_id int not null,
  zone_id int not null,
  Constraint Address_Customer_FK FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
  Constraint Address_Zone_FK FOREIGN KEY (zone_id) REFERENCES Zone(zone_id)
 );

 Create Table Card (
    card_id INT IDENTITY(1,1) PRIMARY KEY,
    card_no CHAR(16) NOT NULL,
    card_holder_name VARCHAR(100) NOT NULL,
    expiration_date DATE NOT NULL,
    customer_id INT NOT NULL,
    CONSTRAINT Card_Customer_FK FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
    CONSTRAINT Card_Customer_Card_UQ UNIQUE (customer_id, card_no)
);

Create Table Business(
business_id int identity(1,1) PRIMARY KEY,
name varchar(100) not null,
description varchar(255),
link_website varchar(255),
opening_hour time not null,
closing_hour time not null,
expected_delivery_time int not null CHECK (expected_delivery_time > 0),
status varchar(20) not null DEFAULT 'Pending',
suspension_reason varchar(255),
partner_id int not null UNIQUE ,
zone_id int not null , 
CONSTRAINT Business_SuspReason_CK CHECK (status = 'Suspended' OR suspension_reason IS NULL),
CONSTRAINT Business_Partner_FK FOREIGN KEY (partner_id) REFERENCES Partner(partner_id),
CONSTRAINT Business_Zone_FK FOREIGN KEY (zone_id) REFERENCES Zone(zone_id),
CONSTRAINT Business_Status_CK check (status in ('Pending','Active','Suspended','Rejected'))
);

Create Table Business_Phone(
business_id int , 
phone char(11) ,
 CONSTRAINT Business_Phone_PK PRIMARY KEY (business_id, phone),
CONSTRAINT Business_Phone_Business_FK FOREIGN KEY (business_id) REFERENCES Business(business_id)

);

Create Table Restaurant(
business_id int PRIMARY KEY,
cuisine_type varchar(50) not null,
food_category varchar(50) not null,
 CONSTRAINT Restaurant_Business_FK FOREIGN KEY (business_id) REFERENCES Business(business_id)
);

Create Table Pharmacy(
business_id int PRIMARY KEY,
pharmacy_type varchar(50) not null,
CONSTRAINT Pharmacy_Business_FK FOREIGN KEY (business_id) REFERENCES Business(business_id)
);

CREATE TABLE Blacklist (
    customer_id INT PRIMARY KEY,
    admin_id INT NOT NULL,
    reason VARCHAR(255) NOT NULL,
    CONSTRAINT Blacklist_Customer_FK FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
    CONSTRAINT Blacklist_Admin_FK FOREIGN KEY (admin_id) REFERENCES Admin(admin_id)
);

create table Product(
product_id int identity(1,1) PRIMARY KEY,
name varchar(100) not null,
description varchar(255),
category varchar(50) not null,
price decimal(10,2) not null CHECK (price > 0) ,
discount_amount decimal(10,2) not null DEFAULT 0 ,
is_available bit not null DEFAULT 1 , 
business_id int not null,
CONSTRAINT Product_Business_FK FOREIGN KEY (business_id) REFERENCES Business(business_id),
CONSTRAINT Product_Discount_CK CHECK (discount_amount >= 0 AND discount_amount <= 0.5 * price)
);

create table Favorite_Business(
customer_id int ,
business_id int ,
CONSTRAINT Favorite_Business_PK PRIMARY KEY (customer_id, business_id),
CONSTRAINT FavBusiness_Business_FK FOREIGN KEY (business_id) REFERENCES Business(business_id),
CONSTRAINT FavBusiness_Customer_FK FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
);

create table Favorite_Product(
customer_id int ,
product_id int ,
 CONSTRAINT Favorite_Product_PK PRIMARY KEY (customer_id, product_id),
CONSTRAINT FavProduct_Product_FK FOREIGN KEY (product_id) REFERENCES Product(product_id),
CONSTRAINT FavProduct_Customer_FK FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
);

create table Voucher(
voucher_id int identity(1,1) PRIMARY KEY,
promo_code varchar(30) not null UNIQUE,
is_percentage bit not null,
amount decimal(10,2) not null CHECK (amount > 0),
expiry_date date not null,
status varchar(20) not null DEFAULT 'Unused',
customer_id int not null ,
Constraint Voucher_Customer_FK FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
Constraint Voucher_Status_CK check (status in ('Unused','Used') )
);

Create Table Cart (
    cart_id INT IDENTITY(1,1) PRIMARY KEY,
    status VARCHAR(20) NOT NULL DEFAULT 'Active',
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    customer_id INT NOT NULL,
    address_id INT NOT NULL,
    Constraint Cart_Customer_FK FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
    Constraint Cart_Address_FK FOREIGN KEY (address_id) REFERENCES Address(address_id),
    Constraint Cart_Status_CK check (status in ('Active','Checked Out'))
);

Create Table CartItem(
    cart_id INT,
    product_id INT,
    quantity INT NOT NULL CHECK (quantity BETWEEN 1 AND 10),
    notes VARCHAR(255),
    unit_price DECIMAL(10,2),
    CONSTRAINT CartItem_PK PRIMARY KEY (cart_id, product_id),
 CONSTRAINT CartItem_Cart_FK FOREIGN KEY (cart_id) REFERENCES Cart(cart_id),
CONSTRAINT CartItem_Product_FK FOREIGN KEY (product_id) REFERENCES Product(product_id)
);

Create table Orders(
order_id int identity(1,1) PRIMARY KEY,
order_date datetime not null,
status varchar(20) not null DEFAULT 'Placed',
discount_amount decimal(10,2) not null DEFAULT 0 ,
total_amount decimal(10,2) not null ,
cart_id int not null UNIQUE,
zone_id int not null,
voucher_id int,
CONSTRAINT Orders_Cart_FK FOREIGN KEY (cart_id) REFERENCES Cart(cart_id),
CONSTRAINT Orders_Zone_FK FOREIGN KEY (zone_id) REFERENCES Zone(zone_id),
CONSTRAINT Orders_Voucher_FK FOREIGN KEY (voucher_id) REFERENCES Voucher(voucher_id),
CONSTRAINT Orders_Status_FK check (status in ('Placed','In Progress','Delivered','Cancelled'))
);

create table SubOrder(
suborder_id int identity(1,1) PRIMARY KEY,
status varchar(20) not null DEFAULT 'Placed' ,
total_price decimal(10,2) not null,
delivery_fee decimal(10,2) not null,
order_id int not null,
business_id int not null,
CONSTRAINT SubOrder_Order_FK FOREIGN KEY (order_id) REFERENCES Orders(order_id),
CONSTRAINT SubOrder_Business_FK FOREIGN KEY (business_id) REFERENCES Business(business_id),
CONSTRAINT SubOrder_OrderBusiness_UQ UNIQUE (order_id, business_id),
CONSTRAINT SubOrder_Status_FK check (status in ('Placed','Assigned','Picked Up','Delivered','Cancelled'))
);

create table Delivery (
    delivery_id INT IDENTITY(1,1) PRIMARY KEY,
    assigned_at DATETIME NOT NULL,
    picked_up_at DATETIME,
    delivered_at DATETIME,
    tracking_time INT,
    rider_rating INT CHECK (rider_rating BETWEEN 1 AND 5),
    suborder_id INT NOT NULL UNIQUE,
    rider_id INT NOT NULL,
    CONSTRAINT Delivery_SubOrder_FK FOREIGN KEY (suborder_id) REFERENCES SubOrder(suborder_id),
CONSTRAINT Delivery_Rider_FK FOREIGN KEY (rider_id) REFERENCES Rider(rider_id)
);

create table Payment(
payment_id int identity(1,1) PRIMARY KEY,
amount decimal(10,2) not null,
currency varchar(3) not null DEFAULT 'EGP',
method varchar(20) not null,
transaction_date datetime not null,
refunded_amount decimal(10,2) not null DEFAULT 0,
order_id int not null UNIQUE,
card_id int,
CONSTRAINT Payment_Order_FK FOREIGN KEY (order_id) REFERENCES Orders(order_id),
CONSTRAINT Payment_Card_FK FOREIGN KEY (card_id) REFERENCES Card(card_id),
CONSTRAINT Payment_Refund_CK CHECK (refunded_amount <= amount),
 CONSTRAINT Payment_Method_CK check (method in ('Cash','Card','Wallet'))
);

create table Feedback(
 feedback_id INT IDENTITY(1,1) PRIMARY KEY,
    headline VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    feedback_date DATETIME NOT NULL DEFAULT GETDATE(),
    suborder_id INT NOT NULL UNIQUE,
   CONSTRAINT Feedback_SubOrder_FK FOREIGN KEY (suborder_id) REFERENCES SubOrder(suborder_id)
);
return 0;
Go
-- Integration: create tables before compiling views and functions.
EXEC dbo.createAllTables;
GO

Go
-- Student 4: <Mohamed Abdelaiz Abdelhakim> - <64-21045>
Create procedure dropAllTables
as
    drop table Feedback;
    drop table Payment;
    drop table Delivery;
    drop table SubOrder;
    drop table Orders;
    drop table CartItem;
    drop table Cart;
    drop table Voucher;
    drop table Favorite_Product;
    drop table Favorite_Business;
    drop table Product;
    drop table Blacklist;
    drop table Pharmacy;
    drop table Restaurant;
    drop table Business_Phone;
    drop table Business;
    drop table Card;
    drop table Address;
    drop table Customer;
    drop table Rider;
    drop table Partner;
    drop table Admin;
    drop table User_Phone;
    drop table Users;
    drop table Zone;
    return 0;
Go


Go 
-- Student 4: <Mohamed Abdelaiz Abdelhakim> - <64-21045>
create procedure dropAllProceduresFunctionsViews 
as
     -- views
    drop view allBusinessProfiles;
    drop view BusinessesPerZone;
    drop view BusinessRatingsSummary;
    drop view ActiveVouchers;
    drop view PendingBusinessApprovals;
    drop view RiderPerformanceSummary;
    drop view TopSellingProducts;
    drop view ZoneDeliveryPerformance;

        -- stored procedures
    drop procedure createAllTables;
    drop procedure dropAllTables;
    drop procedure Customer_Register;
    drop procedure Partner_Register;
    drop procedure Rider_Register;
    drop procedure Change_Password;
    drop procedure Create_Admin;
    drop procedure Approve_Business;
    drop procedure Reject_Business;
    drop procedure Suspend_Business;
    drop procedure Reinstate_Business;
    drop procedure Create_Zone;
    drop procedure Update_Zone_Fee;
    drop procedure Assign_Admin_Zone;
    drop procedure Issue_Voucher;
    drop procedure Blacklist_Customer;
    drop procedure Lift_Customer_Blacklist;
    drop procedure Register_Business;
    drop procedure Update_Business_Info;
    drop procedure Upsert_Product;
    drop procedure Toggle_Product_Status;
    drop procedure Set_Product_Promotion;
    drop procedure Add_Customer_Address;
    drop procedure Update_Delete_Customer_Address;
    drop procedure Change_Active_Address;
    drop procedure Add_Card;
    drop procedure Create_Cart;
    drop procedure Add_To_Cart;
    drop procedure Remove_From_Cart;
    drop procedure Checkout_Cart;
    drop procedure Cancel_Order;
    drop procedure Reorder;
    drop procedure Submit_Feedback;
    drop procedure Rate_Rider;
    drop procedure Toggle_Favorite;
    drop procedure Set_Rider_Availability;
    drop procedure Mark_Picked_Up;
    drop procedure Mark_Delivered;

    -- scalar functions
    drop function CustomerLoginValidation;
    drop function PartnerLoginValidation;
    drop function RiderLoginValidation;
    drop function AdminLoginValidation;
    drop function Calculate_Voucher_Discount;

    -- table-valued functions
    drop function ZoneOrderReport;
    drop function TopRiders;
    drop function Daily_Revenue_Report;
    drop function BusinessSalesReport;
    drop function BusinessFeedbackOverview;
    drop function My_Order_History;
    drop function My_Favorites;
    drop function Recommended_Products;
    drop function My_Active_Deliveries;
    drop function My_Earnings;
    drop function My_Rating_Summary;
    drop function My_Delivery_History;
    drop function Search_Platform;
    drop function Reconcile_Order_Totals;
    drop function Nearby_Businesses_By_Category;
    drop function Platform_Health_Snapshot;
    return 0 ;
Go


Go
-- Student 4: <Mohamed Abdelaiz Abdelhakim> - <64-21045>
create procedure Create_Zone
 @zone_name varchar(50), @delivery_fee decimal(10,2), @super_admin_id int 
 as
 Begin
    IF @zone_name is null or @delivery_fee is Null or @delivery_fee < 0
    begin
        return -1;
    end
    IF not exists (select 1 from Admin A where A.admin_id =@super_admin_id and A.role ='Super Admin')
    begin
        return -3;
    end
    If exists (select 1 from Zone Z where Z.zone_name =@zone_name)
    begin
        return -2;
    end

    insert into Zone(zone_name ,delivery_fee) values (@zone_name,@delivery_fee);
    return 0;
 end
Go

Go
-- Student 4: <Mohamed Abdelaiz Abdelhakim> - <64-21045>
Create procedure Update_Zone_Fee
@zone_id int, @new_fee decimal(10,2), @super_admin_id int
as
begin
    If @new_fee is null or @new_fee < 0
        begin
        return -1;
    end
    IF not exists (select 1 from Admin A where A.admin_id =@super_admin_id and A.role ='Super Admin')
    begin
        return -3;
    end
    If not exists (select 1 from Zone Z where Z.zone_id =@zone_id)
    begin
        return -1;
    end

    Update Zone Set delivery_fee = @new_fee where zone_id =@zone_id ;  
    return 0;
end
Go

Go
-- Student 4: <Mohamed Abdelaiz Abdelhakim> - <64-21045>
Create View BusinessesPerZone
as
select Z.zone_id, Z.zone_name, Count(B.business_id) as business_count 
From Zone Z left outer join Business B on Z.zone_id = B.zone_id and B.status = 'Active'
Group by Z.zone_id ,Z.zone_name;
Go

Go
-- Student 4: <Mohamed Abdelaiz Abdelhakim> - <64-21045>
Create Function dbo.ZoneOrderReport(@zone_id int, @from_date date, @to_date date)
returns Table
as
return(
    Select Z.zone_id, Z.zone_name, Count(O.order_id) as number_of_orders, Avg(O.total_amount) as avg_order_total ,Coalesce((select Sum(S.total_price)
    from SubOrder S inner join Orders O2 on O2.order_id = S.order_id where O2.zone_id = Z.zone_id
    and cast(O2.order_date as date) between @from_date and @to_date and S.status <> 'Cancelled') * 0.1, 0) as platform_commission
    From Zone Z left outer join Orders O on Z.zone_id = O.zone_id
    where   Z.zone_id = @zone_id 
    and cast(O.order_date as date) between @from_date and @to_date
    and O.status <> 'Cancelled'
    group by Z.zone_id,Z.zone_name
);
Go

Go
-- Student 4: <Mohamed Abdelaiz Abdelhakim> - <64-21045>
Create Function dbo.Daily_Revenue_Report(@report_date date)
Returns table
as
return(
    Select Z.zone_name , case when R.business_id is not null then 'Restaurant' else 'Pharmacy' end as business_type, Count(S.suborder_id) as number_of_suborders,
    Sum(S.total_price) as gross_sales , Sum(S.delivery_fee) as delivery_fees , Sum(S.total_price)*0.1 as platform_commission
    From Suborder S inner join Orders O on S.order_id = o.order_id 
    inner join Zone Z on Z.zone_id = O.zone_id 
    inner join Business B on B.business_id = S.business_id
    left outer join Restaurant R on R.business_id = B.business_id
    left outer join Pharmacy P on P.business_id = B.business_id
    where cast(O.order_date as date) = @report_date
    and S.status <> 'Cancelled'
    group by Z.zone_id ,Z.zone_name,case when R.business_id is not null then 'Restaurant' else 'Pharmacy' end
);
Go

Go 
-- Student 4: <Mohamed Abdelaiz Abdelhakim> - <64-21045>
Create Procedure Suspend_Business
@business_id int, @admin_id int, @reason varchar(255)
as
begin
   If @reason is null 
   begin
    return -1;
   end

   If not exists (select 1 from Admin A where A.admin_id = @admin_id and (A.role='Super Admin' or A.zone_id = (select B.zone_id from Business B where B.business_id = @business_id )) )
   begin
    return -3;
   end

   if not exists (select 1 from Business B where B.business_id = @business_id and B.status ='Active' )
   begin
    return -4 ;
   end
        
        declare @AffectedOrders table (
        order_id int primary key); 

        insert into @AffectedOrders select distinct S.order_id from SubOrder S  where S.business_id = @business_id and status in ('Placed' , 'Assigned');

       declare @Refunds table (
        order_id int primary key , refund_amount decimal(10,2) , method varchar(20) , customer_id int);
        

        insert into @Refunds select
        AO.order_id , 
        case when S.total_price + S.delivery_fee > P.amount - P.refunded_amount then P.amount - P.refunded_amount else S.total_price + S.delivery_fee end , 
        P.method , C.customer_id
        From @AffectedOrders AO inner join SubOrder S on AO.order_id = S.order_id 
        inner join Payment P on P.order_id= AO.order_id
        inner join Orders O on O.order_id = AO.order_id
        inner join Cart C  on C.cart_id = O.cart_id
        inner join Customer CU on C.customer_id = CU.customer_id
        where S.business_id = @business_id
        and S.status in ('Placed' , 'Assigned');
        --group by AO.order_id , P.amount , P.refunded_amount , P.method , CU.customer_id;

        Update Business Set status='Suspended' , suspension_reason=@reason where business_id = @business_id ;
        Update Product set is_available = 0 where business_id = @business_id;
        Update SubOrder set status ='Cancelled' where business_id = @business_id and status in ('Placed' , 'Assigned');
        
        Update P set P.refunded_amount = P.refunded_amount + R.refund_amount  from Payment P inner join @Refunds R on R.order_id = P.order_id;
        Update C set C.wallet_balance = C.wallet_balance + T.total_refund from Customer C inner join 
        (select customer_id , sum(refund_amount) as total_refund from @Refunds where method <> 'Cash' group by customer_id) T
        on T.customer_id = C.customer_id ;

        Update O set status= case when not exists(select 1 from SubOrder S where O.order_id = S.order_id and S.status<>'Cancelled') then 'Cancelled'
        when not exists(select 1 from SubOrder S where O.order_id = S.order_id and S.status not in ('Cancelled','Delivered')) then 'Delivered'
        when  exists(select 1 from SubOrder S where O.order_id = S.order_id and S.status  in ('Picked Up','Delivered')) then 'In Progress' else 'Placed' end
        From Orders O inner join @AffectedOrders A  on A.order_id = O.order_id ;

        Update V set status = 'Unused' From Voucher V inner join Orders O on V.voucher_id = O.voucher_id inner join @AffectedOrders A  on A.order_id = O.order_id 
        where not exists (select 1 from SubOrder S where O.order_id = S.order_id and S.status<>'Cancelled');

        Update O set voucher_id = null From Orders O inner join @AffectedOrders A  on A.order_id = O.order_id 
        where not exists (select 1 from SubOrder S where O.order_id = S.order_id and S.status<>'Cancelled');


   return 0 ;

end
Go

Go
-- Student 4: <Mohamed Abdelaiz Abdelhakim> - <64-21045>
Create Procedure Reinstate_Business
@business_id int, @super_admin_id int
as
    IF not exists (select 1 from Admin A where A.admin_id =@super_admin_id and A.role ='Super Admin')
    begin
        return -3;
    end

    IF not exists (select 1 from Business B where B.business_id =@business_id and B.status ='Suspended')
    begin
        return -4;
    end

    Update Business set status ='Active',suspension_reason=null where business_id =@business_id ;
    return 0 ;
Go

----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

-- Student 1: <Belal Ahmed Abdelgawad> - <64-24788>

Create View ActiveVouchers AS
Select voucher_id, promo_code, customer_id, is_percentage, amount, expiry_date
from voucher
WHERE status = 'Unused' AND expiry_date >= CAST(GETDATE() AS DATE);
GO

----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

-- Student 1: <Belal Ahmed Abdelgawad> - <64-24788>
Create PROCEDURE Customer_Register
    @first_name varchar(30), 
    @middle_name varchar(30), 
    @last_name varchar(30), 
    @username varchar(30), 
    @password varchar(30), 
    @email varchar(100), 
    @phone char(11), 
    @dob date
AS
BEGIN
    -- 1. Validate constraints manually
    IF EXISTS (SELECT 1 FROM Users WHERE username = @username OR email = @email)
    BEGIN
        RETURN -2; -- Duplicate error code
    END
    
    IF @first_name IS NULL OR @last_name IS NULL OR @username IS NULL OR @password IS NULL OR @email IS NULL OR @phone IS NULL
    BEGIN
        RETURN -1; -- Invalid input error code
    END

    IF LEN(RTRIM(@phone)) <> 11 OR @phone LIKE '%[^0-9]%'
    BEGIN
        RETURN -1;
    END

    -- 2. Start Transaction
    BEGIN TRAN;

    -- 3. Insert into superclass
    INSERT INTO Users (first_name, middle_name, last_name, username, password, email, dob)
    VALUES (@first_name, @middle_name, @last_name, @username, @password, @email, @dob);

    -- 4. Get the generated ID
    DECLARE @new_user_id INT = SCOPE_IDENTITY();

    -- 5. Insert into subclass and phone tables
    INSERT INTO Customer (customer_id, wallet_balance)
    VALUES (@new_user_id, 0);

    INSERT INTO User_Phone (user_id, phone)
    VALUES (@new_user_id, @phone);

    -- 6. Commit and return success
    COMMIT TRAN;
    RETURN 0;
END;
GO

----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

-- Student 1: <Belal Ahmed Abdelgawad> - <64-24788>
Create PROCEDURE Partner_Register
    @first_name varchar(30), 
    @middle_name varchar(30), 
    @last_name varchar(30), 
    @username varchar(30), 
    @password varchar(30), 
    @email varchar(100), 
    @phone char(11), 
    @dob date
AS
BEGIN
    -- 1. Validate constraints manually
    IF EXISTS (SELECT 1 FROM Users WHERE username = @username OR email = @email)
    BEGIN
        RETURN -2; -- Duplicate error code
    END
    
    IF @first_name IS NULL OR @last_name IS NULL OR @username IS NULL OR @password IS NULL OR @email IS NULL OR @phone IS NULL
    BEGIN
        RETURN -1; -- Invalid input error code
    END

    IF LEN(RTRIM(@phone)) <> 11 OR @phone LIKE '%[^0-9]%'
    BEGIN
        RETURN -1;
    END

    -- 2. Start Transaction
    BEGIN TRAN;

    -- 3. Insert into superclass
    INSERT INTO Users (first_name, middle_name, last_name, username, password, email, dob)
    VALUES (@first_name, @middle_name, @last_name, @username, @password, @email, @dob);

    -- 4. Get the generated ID
    DECLARE @new_user_id INT = SCOPE_IDENTITY();

    -- 5. Insert into subclass and phone tables
    INSERT INTO Partner (partner_id)
    VALUES (@new_user_id);

    INSERT INTO User_Phone (user_id, phone)
    VALUES (@new_user_id, @phone);

    -- 6. Commit and return success
    COMMIT TRAN;
    RETURN 0;
END;
GO

----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

-- Student 1: <Belal Ahmed Abdelgawad> - <64-24788>
Create PROCEDURE Rider_Register
    @first_name varchar(30), 
    @middle_name varchar(30), 
    @last_name varchar(30), 
    @username varchar(30), 
    @password varchar(30), 
    @email varchar(100), 
    @phone char(11), 
    @dob date,
    @vehicle_type varchar(30), 
    @plate_no varchar(15), 
    @license_no varchar(20), 
    @zone_id int
AS
BEGIN
    -- 1. Validate constraints manually
    IF EXISTS (SELECT 1 FROM Users WHERE username = @username OR email = @email) OR EXISTS (SELECT 1 FROM Rider WHERE @plate_no = plate_no OR @license_no = license_no)
    BEGIN
        RETURN -2; -- Duplicate error code
    END
    
    IF @first_name IS NULL OR @last_name IS NULL OR @username IS NULL OR @password IS NULL OR @email IS NULL OR @phone IS NULL OR @vehicle_type IS NULL OR @plate_no IS NULL OR @license_no IS NULL OR @zone_id IS NULL
    BEGIN
        RETURN -1; -- Invalid input error code
    END

    IF LEN(RTRIM(@phone)) <> 11 OR @phone LIKE '%[^0-9]%'
    BEGIN
        RETURN -1;
    END

    -- 2. Start Transaction
    BEGIN TRAN;

    -- 3. Insert into superclass
    INSERT INTO Users (first_name, middle_name, last_name, username, password, email, dob)
    VALUES (@first_name, @middle_name, @last_name, @username, @password, @email, @dob);

    -- 4. Get the generated ID
    DECLARE @new_user_id INT = SCOPE_IDENTITY();

    -- 5. Insert into subclass and phone tables
    INSERT INTO Rider (rider_id, vehicle_type, plate_no, license_no, zone_id)
    VALUES (@new_user_id, @vehicle_type, @plate_no, @license_no, @zone_id);

    INSERT INTO User_Phone (user_id, phone)
    VALUES (@new_user_id, @phone);

    -- 6. Commit and return success
    COMMIT TRAN;
    RETURN 0;
END;
GO

----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

-- Student 1: <Belal Ahmed Abdelgawad> - <64-24788>
Create Function dbo.CustomerLoginValidation(@username varchar(30), @password varchar(30))
RETURNS BIT
AS
Begin
    DECLARE @user_id INT;

    SELECT @user_id = user_id
    FROM Users
    WHERE username = @username AND password = @password and account_status = 'Active';

    IF @user_id IS NULL
        RETURN 0; -- Invalid credentials

    IF NOT EXISTS (SELECT 1 FROM Customer WHERE customer_id = @user_id)
        RETURN 0; -- Not a customer

    RETURN 1; --Success
END;
GO

----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

-- Student 1: <Belal Ahmed Abdelgawad> - <64-24788>
Create Function dbo.PartnerLoginValidation(@username varchar(30), @password varchar(30))
RETURNS BIT
AS
Begin
    DECLARE @user_id INT;

    SELECT @user_id = user_id
    FROM Users
    WHERE username = @username AND password = @password and account_status = 'Active';

    IF @user_id IS NULL
        RETURN 0; -- Invalid credentials

    IF NOT EXISTS (SELECT 1 FROM Partner WHERE partner_id = @user_id)
        RETURN 0; -- Not a partner

    RETURN 1; --Success
END;
GO

----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

-- Student 1: <Belal Ahmed Abdelgawad> - <64-24788>
Create Function dbo.RiderLoginValidation(@username varchar(30), @password varchar(30))
RETURNS BIT
AS
Begin
    DECLARE @user_id INT;

    SELECT @user_id = user_id
    FROM Users
    WHERE username = @username AND password = @password and account_status = 'Active';

    IF @user_id IS NULL
        RETURN 0; -- Invalid credentials

    IF NOT EXISTS (SELECT 1 FROM Rider WHERE rider_id = @user_id)
        RETURN 0; -- Not a rider

    RETURN 1; --Success
END;
GO

----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

-- Student 1: <Belal Ahmed Abdelgawad> - <64-24788>
Create Function dbo.AdminLoginValidation(@username varchar(30), @password varchar(30))
RETURNS BIT
AS
Begin
    DECLARE @user_id INT;

    SELECT @user_id = user_id
    FROM Users
    WHERE username = @username AND password = @password and account_status = 'Active';

    IF @user_id IS NULL
        RETURN 0; -- Invalid credentials

    IF NOT EXISTS (SELECT 1 FROM Admin WHERE admin_id = @user_id)
        RETURN 0; -- Not an admin

    RETURN 1; --Success
END;
GO

----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

-- Student 1: <Belal Ahmed Abdelgawad> - <64-24788>
Create PROCEDURE Change_Password
    @user_id int, 
    @old_password varchar(30), 
    @new_password varchar(30), 
    @new_password_repeat varchar(30), 
    @success bit OUTPUT
AS
BEGIN
    Declare @current_password varchar(30);
    SELECT @current_password = password FROM Users WHERE user_id = @user_id;
    IF @current_password IS NULL OR @current_password <> @old_password OR @new_password <> @new_password_repeat
    BEGIN
        SET @success = 0; -- Failure
        RETURN -1;
    END

    UPDATE Users
    SET password = @new_password
    WHERE user_id = @user_id;

    SET @success = 1; -- Success
    return 0;
END;
GO

----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

-- Student 1: <Belal Ahmed Abdelgawad> - <64-24788>
Create PROCEDURE Create_Admin
    @first_name varchar(30), 
    @middle_name varchar(30), 
    @last_name varchar(30), 
    @username varchar(30), 
    @password varchar(30), 
    @email varchar(100), 
    @phone char(11), 
    @dob date,
    @role varchar(20),
    @zone_id int = NULL,
    @super_admin_id int
AS
Begin
    -- 1. Validate constraints manually
    IF EXISTS (SELECT 1 FROM Users WHERE username = @username OR email = @email)
    BEGIN
        RETURN -2; -- Duplicate error code
    END
    
    IF @first_name IS NULL OR @last_name IS NULL OR @username IS NULL OR @password IS NULL OR @email IS NULL OR @phone IS NULL or @super_admin_id IS NULL
    BEGIN
        RETURN -1; -- Invalid input error code
    END

    IF LEN(RTRIM(@phone)) <> 11 OR @phone LIKE '%[^0-9]%'
    BEGIN
        RETURN -1;
    END

    -- 2. Validate that the role and zone_id align with Business Rule 2
    IF (ISNULL(@role, 'Super Admin') = 'Super Admin' AND @zone_id IS NOT NULL) OR (@role = 'Zone Admin' AND @zone_id IS NULL)
    BEGIN
        RETURN -1; -- Invalid input error code
    END

    -- 3. Verify the executing user is a Super Admin
    IF NOT EXISTS (SELECT 1 FROM Admin WHERE admin_id = @super_admin_id AND role = 'Super Admin')
    BEGIN
        RETURN -3; -- Not allowed error code
    END

    -- 4. Start Transaction
    BEGIN TRAN;
    -- 5. Insert into superclass
    INSERT INTO Users (first_name, middle_name, last_name, username, password, email, dob)
    VALUES (@first_name, @middle_name, @last_name, @username, @password, @email, @dob);

    -- 6. Get the generated ID
    DECLARE @new_user_id INT = SCOPE_IDENTITY();

    -- 7. Insert into subclass and phone tables
    INSERT INTO Admin (admin_id, role, zone_id)
    VALUES (@new_user_id, ISNULL(@role, 'Super Admin'), @zone_id);

    INSERT INTO User_Phone (user_id, phone)
    VALUES (@new_user_id, @phone);

    -- 8. Commit and return success
    COMMIT TRAN;
    RETURN 0;
END;
GO

----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

-- Student 1: <Belal Ahmed Abdelgawad> - <64-24788>
Create PROCEDURE Approve_Business
    @business_id int,
    @admin_id int
AS
BEGIN
    -- 1. Validate that the business exists
    IF NOT EXISTS (SELECT 1 FROM Business WHERE business_id = @business_id)
    BEGIN
        RETURN -1; -- Invalid input error code
    END

    -- 2. Validate that the business is pending approval
    IF NOT EXISTS (SELECT 1 FROM Business WHERE business_id = @business_id AND status = 'Pending')
    BEGIN
        RETURN -4; -- Wrong status error code
    END

    -- 3. Validate that the admin exists and is a Super Admin or Zone Admin for the business's zone
    DECLARE @business_zone_id INT;
    SELECT @business_zone_id = zone_id FROM Business WHERE business_id = @business_id;

    IF NOT EXISTS (SELECT 1 FROM Admin WHERE admin_id = @admin_id AND (role = 'Super Admin' OR (role = 'Zone Admin' AND zone_id = @business_zone_id)))
    BEGIN
        RETURN -3; -- Not allowed error code
    END

    -- 4. Update the business status to 'Active'
    UPDATE Business
    SET status = 'Active'
    WHERE business_id = @business_id;

    RETURN 0; -- Success
END;
GO

----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

-- Student 1: <Belal Ahmed Abdelgawad> - <64-24788>
Create PROCEDURE Reject_Business
    @business_id int,
    @admin_id int
AS
BEGIN
    -- 1. Validate that the business exists
    IF NOT EXISTS (SELECT 1 FROM Business WHERE business_id = @business_id)
    BEGIN
        RETURN -1; -- Invalid input error code
    END

    -- 2. Validate that the business is pending approval
    IF NOT EXISTS (SELECT 1 FROM Business WHERE business_id = @business_id AND status = 'Pending')
    BEGIN
        RETURN -4; -- Wrong status error code
    END

    -- 3. Validate that the admin exists and is a Super Admin or Zone Admin for the business's zone
    DECLARE @business_zone_id INT;
    SELECT @business_zone_id = zone_id FROM Business WHERE business_id = @business_id;

    IF NOT EXISTS (SELECT 1 FROM Admin WHERE admin_id = @admin_id AND (role = 'Super Admin' OR (role = 'Zone Admin' AND zone_id = @business_zone_id)))
    BEGIN
        RETURN -3; -- Not allowed error code
    END

    -- 4. Update the business status to 'Rejected'
    UPDATE Business
    SET status = 'Rejected'
    WHERE business_id = @business_id;

    RETURN 0; -- Success
END;
GO

----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

-- Student 1: <Belal Ahmed Abdelgawad> - <64-24788>
Create Procedure Assign_Admin_Zone
    @admin_id int,
    @zone_id int,
    @super_admin_id int
AS
BEGIN
    -- 1. Validate that the admin exists and is a Zone Admin
    IF NOT EXISTS (SELECT 1 FROM Admin WHERE admin_id = @admin_id AND role = 'Zone Admin')
    BEGIN
        RETURN -1; -- Invalid input error code
    END

    -- 2. Validate that the zone exists
    IF NOT EXISTS (SELECT 1 FROM Zone WHERE zone_id = @zone_id)
    BEGIN
        RETURN -1; -- Invalid input error code
    END

    -- 3. Validate that the executing user is a Super Admin
    IF NOT EXISTS (SELECT 1 FROM Admin WHERE admin_id = @super_admin_id AND role = 'Super Admin')
    BEGIN
        RETURN -3; -- Not allowed error code
    END

    -- 4. Validate that the admin is not already assigned to this zone
    IF EXISTS (SELECT 1 FROM Admin WHERE admin_id = @admin_id AND zone_id = @zone_id)
    BEGIN
        RETURN -2; -- Duplicate error code
    END

    -- 5. Assign the zone to the admin
    UPDATE Admin
    SET zone_id = @zone_id
    WHERE admin_id = @admin_id;

    RETURN 0; -- Success
END;
GO

----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

-- Student 1: <Belal Ahmed Abdelgawad> - <64-24788>
Create Procedure Issue_Voucher
    @customer_id int,
    @promo_code varchar(30),
    @is_percentage bit,
    @amount decimal(10,2),
    @expiry_date date,
    @admin_id int
AS
BEGIN
    -- 1. Validate that all inputs are provided
    IF @customer_id IS NULL OR @promo_code IS NULL OR @is_percentage IS NULL OR @amount IS NULL OR @expiry_date IS NULL OR @admin_id IS NULL OR @amount <= 0 OR @expiry_date < CAST(GETDATE() AS DATE)
    BEGIN
        RETURN -1; -- Invalid input error code
    END

    -- 2. Validate that the customer exists
    IF NOT EXISTS (SELECT 1 FROM Customer WHERE customer_id = @customer_id)
    BEGIN
        RETURN -3; -- Not allowed error code
    END

    IF EXISTS (SELECT 1 FROM Users WHERE user_id = @customer_id AND account_status = 'Blacklisted')
    BEGIN
        RETURN -3;
    END

    -- 3. Validate that the promo_code is unique
    IF EXISTS (SELECT 1 FROM Voucher WHERE promo_code = @promo_code)
    BEGIN
        RETURN -2; -- Duplicate error code
    END

    -- 4. Validate that the admin exists

    IF NOT EXISTS (SELECT 1 FROM Admin WHERE admin_id = @admin_id)
    BEGIN
        RETURN -3; -- Not allowed error code
    END

    -- 5. Insert the voucher
    INSERT INTO Voucher (promo_code, is_percentage, amount, expiry_date, customer_id)
    VALUES (@promo_code, @is_percentage, @amount, @expiry_date, @customer_id);

    RETURN 0; -- Success
END;
GO

----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

-- Student 1: <Belal Ahmed Abdelgawad> - <64-24788>
Create Procedure Blacklist_Customer
    @customer_id int,
    @admin_id int,
    @reason varchar(255)
AS
BEGIN
    -- 1. Validate that all inputs are provided
    IF @customer_id IS NULL OR @admin_id IS NULL OR @reason IS NULL
    BEGIN
        RETURN -1; -- Invalid input error code
    END

    -- 2. Validate that the customer exists
    IF NOT EXISTS (SELECT 1 FROM Customer WHERE customer_id = @customer_id)
    BEGIN
        RETURN -3; -- Not allowed error code
    END

    -- 3. Validate that the admin exists
    IF NOT EXISTS (SELECT 1 FROM Admin WHERE admin_id = @admin_id)
    BEGIN
        RETURN -3; -- Not allowed error code
    END

    -- 4. Validate Zone Admin scope (BR-3)
    DECLARE @admin_role VARCHAR(20);
    DECLARE @admin_zone INT;

    SELECT @admin_role = role, @admin_zone = zone_id 
    FROM Admin 
    WHERE admin_id = @admin_id;

    IF @admin_role = 'Zone Admin'
    BEGIN
        -- Check if the customer has at least one address in the Zone Admin's zone
        IF NOT EXISTS (SELECT 1 FROM Address WHERE customer_id = @customer_id AND zone_id = @admin_zone)
        BEGIN
            RETURN -3; -- Not allowed error code
        END
    END

    -- 5. Validate that the customer is not already blacklisted
    IF EXISTS (SELECT 1 FROM Blacklist WHERE customer_id = @customer_id)
    BEGIN
        RETURN -4; -- Wrong status error code
    END

    BEGIN TRAN;
    -- 6. Insert into Blacklist and update account_status in Users table
    INSERT INTO Blacklist (customer_id, admin_id, reason)
    VALUES (@customer_id, @admin_id, @reason);

    UPDATE Users
    SET account_status = 'Blacklisted'
    WHERE user_id = @customer_id;

    -- Declare a variable to hold the current order ID in the loop
    DECLARE @current_order_id INT;

    -- Set up a cursor to find all orders that Cancel_Order would accept
    DECLARE order_cursor CURSOR FOR
    SELECT o.order_id
    FROM Orders o
    INNER JOIN Cart c ON o.cart_id = c.cart_id
    WHERE c.customer_id = @customer_id AND o.status != 'Cancelled' AND NOT EXISTS (
          -- Ensure no SubOrder has progressed to Picked Up or Delivered
          SELECT 1 
          FROM SubOrder so 
          WHERE so.order_id = o.order_id AND so.status IN ('Picked Up', 'Delivered')
      );

    OPEN order_cursor;
    FETCH NEXT FROM order_cursor INTO @current_order_id;

    -- Loop through each eligible order and execute Student 3's procedure
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC Cancel_Order @order_id = @current_order_id;
        
        FETCH NEXT FROM order_cursor INTO @current_order_id;
    END;

    CLOSE order_cursor;
    DEALLOCATE order_cursor;

    -- Finally, delete all Unused vouchers for the blacklisted customer
    DELETE FROM Voucher
    WHERE customer_id = @customer_id AND status = 'Unused';

    COMMIT TRAN;
    RETURN 0; -- Success
END;
GO

----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

-- Student 1: <Belal Ahmed Abdelgawad> - <64-24788>
Create Procedure Lift_Customer_Blacklist
    @customer_id int,
    @admin_id int
AS
BEGIN
    -- 1. Validate that all inputs are provided
    IF @customer_id IS NULL OR @admin_id IS NULL
    BEGIN
        RETURN -1; -- Invalid input error code
    END

    -- 2. Validate that the customer exists
    IF NOT EXISTS (SELECT 1 FROM Customer WHERE customer_id = @customer_id)
    BEGIN
        RETURN -3; -- Not allowed error code
    END

    -- 3. Validate that the admin exists
    IF NOT EXISTS (SELECT 1 FROM Admin WHERE admin_id = @admin_id)
    BEGIN
        RETURN -3; -- Not allowed error code
    END

    -- 4. Validate that the customer is currently blacklisted
    IF NOT EXISTS (SELECT 1 FROM Blacklist WHERE customer_id = @customer_id)
    BEGIN
        RETURN -4; -- Wrong status error code
    END

    DECLARE @blacklisting_admin_id INT;
    SELECT @blacklisting_admin_id = admin_id FROM Blacklist WHERE customer_id = @customer_id;

    -- 5. Validate that the admin is the same admin who blacklisted the customer
    IF @blacklisting_admin_id <> @admin_id
    BEGIN
        RETURN -3; -- Not allowed error code
    END

    BEGIN TRAN;
    -- 6. Delete from Blacklist and update account_status in Users table
    DELETE FROM Blacklist
    WHERE customer_id = @customer_id;

    UPDATE Users
    SET account_status = 'Active'
    WHERE user_id = @customer_id;

    COMMIT TRAN;
    RETURN 0; -- Success
END;
GO

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




















-------------------------------------------------------------------------------------------------------



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


