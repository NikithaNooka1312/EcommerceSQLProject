---------------------------------------------------------
-- 1. CREATE DATABASE
---------------------------------------------------------
CREATE DATABASE EcommerceDB;
GO
USE EcommerceDB;
GO
---------------------------------------------------------
-- 2. CREATE TABLES (DDL)
---------------------------------------------------------

-- Customers Table
CREATE TABLE Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    Email NVARCHAR(100) UNIQUE,
    Phone NVARCHAR(20),
    CreatedAt DATETIME DEFAULT GETDATE()
);

-- Products Table
CREATE TABLE Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName NVARCHAR(100),
    Category NVARCHAR(50),
    Price DECIMAL(10,2),
    Stock INT,
    CreatedAt DATETIME DEFAULT GETDATE()
);

-- Orders Table
CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT FOREIGN KEY REFERENCES Customers(CustomerID),
    OrderDate DATETIME DEFAULT GETDATE(),
    TotalAmount DECIMAL(10,2)
);

-- OrderDetails Table
CREATE TABLE OrderDetails (
    OrderDetailID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT FOREIGN KEY REFERENCES Orders(OrderID),
    ProductID INT FOREIGN KEY REFERENCES Products(ProductID),
    Quantity INT,
    Price DECIMAL(10,2)
);

-- Payments Table
CREATE TABLE Payments (
    PaymentID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT FOREIGN KEY REFERENCES Orders(OrderID),
    PaymentDate DATETIME DEFAULT GETDATE(),
    Amount DECIMAL(10,2),
    PaymentMethod NVARCHAR(20)
);

---------------------------------------------------------
-- 3. INSERT SAMPLE DATA (DML)
---------------------------------------------------------

-- Insert Customers
INSERT INTO Customers (FirstName, LastName, Email, Phone) VALUES
('John','Doe','john@example.com','9999999999'),
('Jane','Smith','jane@example.com','8888888888'),
('Alice','Johnson','alice@example.com','7777777777'),
('Bob','Brown','bob@example.com','6666666666');

-- Insert Products
INSERT INTO Products (ProductName, Category, Price, Stock) VALUES
('iPhone 15','Electronics',1200,50),
('Samsung TV','Electronics',800,30),
('Nike Shoes','Fashion',150,100),
('Levi Jeans','Fashion',60,200),
('Dining Table','Furniture',400,20);

-- Insert Orders
INSERT INTO Orders (CustomerID, TotalAmount) VALUES
(1,1350),(2,800),(3,210),(4,400);

-- Insert OrderDetails
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, Price) VALUES
(1,1,1,1200),(1,3,1,150),
(2,2,1,800),
(3,3,1,150),(3,4,1,60),
(4,5,1,400);

-- Insert Payments
INSERT INTO Payments (OrderID, Amount, PaymentMethod) VALUES
(1,1350,'Credit Card'),
(2,800,'UPI'),
(3,210,'Cash'),
(4,400,'Credit Card');

---------------------------------------------------------
-- 4. BASIC QUERIES (DQL)
---------------------------------------------------------
-- Select all columns from table
SELECT * FROM Customers;
SELECT * FROM Products;
SELECT * FROM orders;
SELECT * FROM orderdetails;
SELECT * FROM payments;

-- Order by latest customers
SELECT * FROM Customers ORDER BY CreatedAt DESC;

-- Filter customers (WHERE + LIKE)
SELECT * FROM Customers WHERE Email LIKE '%example.com';

---------------------------------------------------------
-- 5. AGGREGATE FUNCTIONS
---------------------------------------------------------
SELECT COUNT(*) AS TotalOrders FROM Orders;
SELECT AVG(Price) AS AvgProductPrice FROM Products;
SELECT MIN(Price) AS Cheapest, MAX(Price) AS Expensive FROM Products;
SELECT SUM(TotalAmount) AS TotalRevenue FROM Orders;

---------------------------------------------------------
-- 6. GROUP BY + HAVING
---------------------------------------------------------
-- Total sales by category
SELECT p.Category, SUM(od.Price*od.Quantity) AS TotalSales
FROM OrderDetails od
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY p.Category
HAVING SUM(od.Price*od.Quantity) > 200;

---------------------------------------------------------
-- 7. JOINS
---------------------------------------------------------
-- INNER JOIN
SELECT o.OrderID, c.FirstName, c.LastName, o.TotalAmount
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID;

-- LEFT JOIN
SELECT c.FirstName, o.OrderID, o.TotalAmount
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID;

--RIGHT JOIN
SELECT c.FirstName, o.OrderID, o.TotalAmount
FROM Customers c
RIGHT JOIN Orders o ON c.CustomerID = o.CustomerID;

--FULL JOIN
SELECT c.FirstName, o.OrderID, o.TotalAmount
FROM Customers c
FULL OUTER JOIN Orders o ON c.CustomerID = o.CustomerID;


---------------------------------------------------------
-- 8. SUBQUERIES
---------------------------------------------------------
-- Customers who spent more than avg spending
SELECT CustomerID, TotalAmount
FROM Orders
WHERE TotalAmount > (SELECT AVG(TotalAmount) FROM Orders);

---------------------------------------------------------
-- 9. WINDOW FUNCTIONS
---------------------------------------------------------
-- Ranking top customers by spending
SELECT c.FirstName, c.LastName, SUM(o.TotalAmount) AS TotalSpent,
       RANK() OVER (ORDER BY SUM(o.TotalAmount) DESC) AS RankCustomer
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.FirstName, c.LastName;

-- Running total of sales
SELECT OrderID, OrderDate, TotalAmount,
       SUM(TotalAmount) OVER (ORDER BY OrderDate) AS RunningTotal
FROM Orders;

---------------------------------------------------------
-- 10. VIEWS
---------------------------------------------------------
CREATE VIEW vw_CustomerSales AS
SELECT c.FirstName, c.LastName, SUM(o.TotalAmount) AS TotalSpent
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.FirstName, c.LastName;

SELECT * FROM vw_CustomerSales;

---------------------------------------------------------
-- 11. STORED PROCEDURE
---------------------------------------------------------
CREATE PROCEDURE GetTopCustomers @TopN INT
AS
BEGIN
    SELECT TOP (@TopN) c.FirstName, c.LastName, SUM(o.TotalAmount) AS TotalSpent
    FROM Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID
    GROUP BY c.FirstName, c.LastName
    ORDER BY TotalSpent DESC;
END;
GO

EXEC GetTopCustomers 3;

---------------------------------------------------------
-- 12. FUNCTIONS
---------------------------------------------------------
CREATE FUNCTION GetCustomerFullName(@CustomerID INT)
RETURNS NVARCHAR(200)
AS
BEGIN
    DECLARE @FullName NVARCHAR(200);
    SELECT @FullName = FirstName + ' ' + LastName FROM Customers WHERE CustomerID = @CustomerID;
    RETURN @FullName;
END;
GO

SELECT dbo.GetCustomerFullName(1) AS CustomerName;

---------------------------------------------------------
-- 13. TRIGGERS
---------------------------------------------------------
CREATE TRIGGER trg_UpdateStock
ON OrderDetails
AFTER INSERT
AS
BEGIN
    UPDATE Products
    SET Stock = Stock - i.Quantity
    FROM Products p
    JOIN inserted i ON p.ProductID = i.ProductID;
END;
GO

---------------------------------------------------------
-- 14. TRANSACTIONS + ROLLBACK (TCL)
---------------------------------------------------------
BEGIN TRANSACTION;
UPDATE Products SET Price = Price + 50 WHERE Category='Electronics';

-- Oops, rollback
ROLLBACK;

---------------------------------------------------------
-- 15. DCL (Permissions)
---------------------------------------------------------
-- (Run as Admin)
CREATE LOGIN TestUser WITH PASSWORD = 'StrongPass@123';
CREATE USER TestUser FOR LOGIN TestUser;
GRANT SELECT ON Customers TO TestUser;
DENY DELETE ON Customers TO TestUser;
