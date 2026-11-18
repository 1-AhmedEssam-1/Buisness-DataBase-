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