---------------------------------------------------------------------
-- Inside Microsoft SQL Server 2008: T-SQL Querying (MSPress, 2009)
-- Chapter 06 - Subqueries, Table Expressions and Ranking Functions
-- Copyright Itzik Ben-Gan, 2009
-- All Rights Reserved
---------------------------------------------------------------------


---------------------------------------------------------------------
-- Subqueries
---------------------------------------------------------------------

-- Scalar subquery 选择orderid值最大的行中的orderid和custid
SET NOCOUNT ON;
USE InsideTSQL2008;

SELECT orderid, custid
FROM Sales.Orders
WHERE orderid = (SELECT MAX(orderid) FROM Sales.Orders);

-- 11077 65


-- Correlated subquery 选择custid相同的行中orderid最大的行
SELECT orderid, custid
FROM Sales.Orders AS O1
WHERE orderid = (SELECT MAX(O2.orderid)
                 FROM Sales.Orders AS O2
                 WHERE O2.custid = O1.custid);

-- 11044 91
-- 11005 90
-- 11066 89

-- Multivalued subquery  从Salses.Customers中选择custid包含在Sales.Orders中的custid和companyname
SELECT custid, companyname
FROM Sales.Customers
WHERE custid IN (SELECT custid FROM Sales.Orders);

-- 1	Customer NRZBB
-- 2	Customer MLTDN
-- 3	Customer KBUDE

-- Table subquery 分别找到各个年份中最大的orderid和对应的orderyear
SELECT orderyear, MAX(orderid) AS max_orderid
FROM (SELECT orderid, YEAR(orderdate) AS orderyear
      FROM Sales.Orders) AS D
GROUP BY orderyear;

-- 2007 10807
-- 2008 11077
-- 2006 10399

---------------------------------------------------------------------
-- Self-Contained Subqueries
---------------------------------------------------------------------

-- Scalar subquery example 查询所有empid的last name为Davis的orderid
SELECT orderid FROM Sales.Orders
WHERE empid =
  (SELECT empid FROM HR.Employees
   -- also try with N'Kollar' and N'D%'
   WHERE lastname LIKE N'Davis');

-- 10258
-- 10270
-- 10275

-- Customers with orders handled by all employees from the USA
-- using literals 将Sales.Orders中empid为1,2,3,4,8的行按照custid聚合，选出聚合后包含这五个empid的行的custid
SELECT custid
FROM Sales.Orders
WHERE empid IN(1, 2, 3, 4, 8)
GROUP BY custid
HAVING COUNT(DISTINCT empid) = 5;

-- 5
-- 9
-- 20

-- Customers with orders handled by all employees from the USA
-- using subqueries 查询被country为USA的所有employees都接待过的custid
-- 根据custid分组，选出country为USA的empid，如果其中不相等的empid数等于在美国的empid总数，则选出
SELECT custid
FROM Sales.Orders
WHERE empid IN
  (SELECT empid FROM HR.Employees
   WHERE country = N'USA')
GROUP BY custid
HAVING COUNT(DISTINCT empid) =
  (SELECT COUNT(*) FROM HR.Employees
   WHERE country = N'USA');

-- 5
-- 9
-- 20


-- Orders placed on last actual order date of the month 查询Sales.Orders中每月中最后一天的订单
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE orderdate IN
  (SELECT MAX(orderdate)
   FROM Sales.Orders
   GROUP BY YEAR(orderdate), MONTH(orderdate));
GO

-- 10269 89 5 2006-07-31 00:00:00.000
-- 10294 65 4 2006-08-30 00:00:00.000
-- 10317 48 6 2006-09-30 00:00:00.000

---------------------------------------------------------------------
-- Correlated Subqueries
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Tiebreaker
---------------------------------------------------------------------

-- Index for tiebreaker problems 建立唯一的索引
CREATE UNIQUE INDEX idx_eid_od_oid
  ON Sales.Orders(empid, orderdate, orderid);
CREATE UNIQUE INDEX idx_eid_od_rd_oid
  ON Sales.Orders(empid, orderdate, requireddate, orderid);
GO

-- Orders with the maximum orderdate for each employee
-- Incorrect solution 对于每一组empid查询出最大的orderdate，再在表格中查出所有该orderdate对应的项
SELECT orderid, custid, empid, orderdate, requireddate
FROM Sales.Orders
WHERE orderdate IN
  (SELECT MAX(orderdate) FROM Sales.Orders
   GROUP BY empid);

-- 11040 32 4 2008-04-22 00:00:00.000 2008-05-20 00:00:00.000
-- 11041 14 3 2008-04-22 00:00:00.000 2008-05-20 00:00:00.000
-- 11042 15 2 2008-04-22 00:00:00.000 2008-05-06 00:00:00.000

-- Orders with maximum orderdate for each employee 查询每个empid对应的最后一天的订单
SELECT orderid, custid, empid, orderdate, requireddate
FROM Sales.Orders AS O1
WHERE orderdate =
  (SELECT MAX(orderdate)
   FROM Sales.Orders AS O2
   WHERE O2.empid = O1.empid);

-- 11077 65 1 2008-05-06 00:00:00.000 2008-06-03 00:00:00.000
-- 11070 44 2 2008-05-05 00:00:00.000 2008-06-02 00:00:00.000
-- 11073 58 2 2008-05-05 00:00:00.000 2008-06-02 00:00:00.000

-- Most recent order for each employee
-- Tiebreaker: max order id 查询每个empid对应的最后一天中订单号最大的订单
SELECT orderid, custid, empid, orderdate, requireddate
FROM Sales.Orders AS O1
WHERE orderdate =
  (SELECT MAX(orderdate)
   FROM Sales.Orders AS O2
   WHERE O2.empid = O1.empid)
  AND orderid =
  (SELECT MAX(orderid)
   FROM Sales.Orders AS O2
   WHERE O2.empid = O1.empid
     AND O2.orderdate = O1.orderdate);

-- 11077 65 1 2008-05-06 00:00:00.000 2008-06-03 00:00:00.000
-- 11073 58 2 2008-05-05 00:00:00.000 2008-06-02 00:00:00.000
-- 11063 37 3 2008-04-30 00:00:00.000 2008-05-28 00:00:00.000


-- Most recent order for each employee, nesting subqueries
-- Tiebreaker: max order id 查询每个empid对应的最后一天中订单号最大的订单
SELECT orderid, custid, empid, orderdate, requireddate
FROM Sales.Orders AS O1
WHERE orderid =
  (SELECT MAX(orderid)
   FROM Sales.Orders AS O2
   WHERE O2.empid = O1.empid
     AND O2.orderdate =
       (SELECT MAX(orderdate)
        FROM Sales.Orders AS O3
        WHERE O3.empid = O1.empid));

-- 11077 65 1 2008-05-06 00:00:00.000 2008-06-03 00:00:00.000
-- 11073 58 2 2008-05-05 00:00:00.000 2008-06-02 00:00:00.000
-- 11063 37 3 2008-04-30 00:00:00.000 2008-05-28 00:00:00.000

-- Most recent order for each employee 查询每个employee最后一天最大的required date订单号最大的订单
-- Tiebreaker: max requireddate, max orderid
SELECT orderid, custid, empid, orderdate, requireddate
FROM Sales.Orders AS O1
WHERE orderdate =
  (SELECT MAX(orderdate)
   FROM Sales.Orders AS O2
   WHERE O2.empid = O1.empid)
  AND requireddate =
  (SELECT MAX(requireddate)
   FROM Sales.Orders AS O2
   WHERE O2.empid = O1.empid
     AND O2.orderdate = O1.orderdate)
  AND orderid =
  (SELECT MAX(orderid)
   FROM Sales.Orders AS O2
   WHERE O2.empid = O1.empid
     AND O2.orderdate = O1.orderdate
     AND O2.requireddate = O1.requireddate);

-- 11058 6  9 2008-04-29 00:00:00.000 2008-05-27 00:00:00.000
-- 11075 68 8 2008-05-06 00:00:00.000 2008-06-03 00:00:00.000
-- 11074 73 7 2008-05-06 00:00:00.000 2008-06-03 00:00:00.000


-- Cleanup 删除索引
DROP INDEX Sales.Orders.idx_eid_od_oid;
DROP INDEX Sales.Orders.idx_eid_od_rd_oid;
GO

---------------------------------------------------------------------
-- EXISTS
---------------------------------------------------------------------

-- Customers from Spain that made orders
-- Using EXISTS 选出country是Spain的并且custid在Sales.Customers和Sales.Orders都有记录的custid和companyname
SELECT custid, companyname
FROM Sales.Customers AS C
WHERE country = N'Spain'
  AND EXISTS
    (SELECT * FROM Sales.Orders AS O
     WHERE O.custid = C.custid);

-- 8 Customer QUHWH
-- 29  Customer MDLWA
-- 30  Customer KSLQF

---------------------------------------------------------------------
-- EXISTS vs. IN
---------------------------------------------------------------------

-- Customers from Spain that made orders
-- Using IN 选出country是Spain的并且custid在Sales.Customers和Sales.Orders都有记录的custid和companyname
SELECT custid, companyname
FROM Sales.Customers AS C
WHERE country = N'Spain'
  AND custid IN(SELECT custid FROM Sales.Orders);

-- 8 Customer QUHWH
-- 29  Customer MDLWA
-- 30  Customer KSLQF

---------------------------------------------------------------------
-- NOT EXISTS vs. NOT IN
---------------------------------------------------------------------

-- Customers from Spain who made no Orders
-- Using EXISTS 选出country是Spain的并且custid在Sales.Customers和Sales.Orders不都有记录的custid和companyname
SELECT custid, companyname
FROM Sales.Customers AS C
WHERE country = N'Spain'
  AND NOT EXISTS
    (SELECT * FROM Sales.Orders AS O
     WHERE O.custid = C.custid);

-- 22  Customer DTDMN

-- Customers from Spain who made no Orders
-- Using IN, try 1 选出country是Spain的并且custid在Sales.Customers和Sales.Orders不都有记录的custid和companyname
SELECT custid, companyname
FROM Sales.Customers AS C
WHERE country = N'Spain'
  AND custid NOT IN(SELECT custid FROM Sales.Orders);

-- 22  Customer DTDMN

-- Add a row to Orders with a NULL customer id
INSERT INTO Sales.Orders
  (custid, empid, orderdate, requireddate, shippeddate, shipperid,
   freight, shipname, shipaddress, shipcity, shipregion,
   shippostalcode, shipcountry)
  VALUES(NULL, 1, '20090212', '20090212',
         '20090212', 1, 123.00, N'abc', N'abc', N'abc',
         N'abc', N'abc', N'abc');

-- Customers from Spain that made no Orders
-- Using IN, try 2
SELECT custid, companyname
FROM Sales.Customers AS C
WHERE country = N'Spain'
  AND custid NOT IN(SELECT custid FROM Sales.Orders
                    WHERE custid IS NOT NULL);

-- 22  Customer DTDMN

-- Remove the row from Orders with the NULL customer id
DELETE FROM Sales.Orders WHERE custid IS NULL;
DBCC CHECKIDENT('Sales.Orders', RESEED, 11077);
GO



---------------------------------------------------------------------
-- Joins
---------------------------------------------------------------------

---------------------------------------------------------------------
-- CROSS
---------------------------------------------------------------------

SET NOCOUNT ON;
USE InsideTSQL2008;
GO

-- Get all Possible Combinations, ANSI SQL:1992 取出所有可能的员工对
SELECT E1.firstname, E1.lastname AS emp1,
  E2.firstname, E2.lastname AS emp2
FROM HR.Employees AS E1
  CROSS JOIN HR.Employees AS E2;

-- Sara  Davis Sara  Davis
-- Don Funk  Sara  Davis
-- Judy  Lew Sara  Davis

-- Get all Possible Combinations, ANSI SQL:1989 取出所有可能的员工对
SELECT E1.firstname, E1.lastname AS emp1,
  E2.firstname, E2.lastname AS emp2
FROM HR.Employees AS E1, HR.Employees AS E2;
GO

-- Sara  Davis Sara  Davis
-- Don Funk  Sara  Davis
-- Judy  Lew Sara  Davis


-- Generate Copies, using a Literal 选出三个表的笛卡尔积中n小于等于31的行的custid, empid, 和以20090101加上n-1天为结果的orderdate
SELECT custid, empid,
  DATEADD(day, n-1, '20090101') AS orderdate
FROM Sales.Customers
  CROSS JOIN HR.Employees
  CROSS JOIN dbo.Nums
WHERE n <= 31;
GO

-- 1 2 2009-01-01 00:00:00.000
-- 2 2 2009-01-01 00:00:00.000
-- 3 2 2009-01-01 00:00:00.000

-- Make Sure MyOrders does not Exist 确保这个表不存在
IF OBJECT_ID('dbo.MyOrders') IS NOT NULL
  DROP TABLE dbo.MyOrders;
GO

-- Generate Copies, using Arguments 选出三个表笛卡尔积中n小于等于两个日期之间天数加一的行，取出custid, empid, 和以n-1加上fromdate作为的orderdate
-- 并把结果插入到dbo.MyOrders中
DECLARE
  @fromdate AS DATE = '20090101',
  @todate   AS DATE = '20090131';

WITH Orders
AS
(
  SELECT custid, empid,
    DATEADD(day, n-1, @fromdate) AS orderdate
  FROM Sales.Customers
    CROSS JOIN HR.Employees
    CROSS JOIN dbo.Nums
  WHERE n <= DATEDIFF(day, @fromdate, @todate) + 1
)
SELECT ROW_NUMBER() OVER(ORDER BY (SELECT 0)) AS orderid,
  custid, empid, orderdate
INTO dbo.MyOrders
FROM Orders;
GO

-- orderid custid  empid orderdate
-- 9249  3 8 2009-01-01
-- 9250  3 8 2009-01-02
-- 9251  3 8 2009-01-03

-- Cleanup  清理新建出的表
DROP TABLE dbo.MyOrders;
GO

-- Avoiding Multiple Subqueries 将Sales.OrderValues中的所有数据插入到dbo.MyOrderValues中，将orderid作为主键，并给val列创建索引
IF OBJECT_ID('dbo.MyOrderValues', 'U') IS NOT NULL
  DROP TABLE dbo.MyOrderValues;
GO

SELECT *
INTO dbo.MyOrderValues
FROM Sales.OrderValues;

ALTER TABLE dbo.MyOrderValues
  ADD CONSTRAINT PK_MyOrderValues PRIMARY KEY(orderid);

CREATE INDEX idx_val ON dbo.MyOrderValues(val);
GO

-- Listing 7-1 Query obtaining aggregates with subqueries 选出dbo.MyOrderValues中的orderid, custid, val, pct, diff。其中pct和diff经运算得到
SELECT orderid, custid, val,
  CAST(val / (SELECT SUM(val) FROM dbo.MyOrderValues) * 100.
       AS NUMERIC(5, 2)) AS pct,
  CAST(val - (SELECT AVG(val) FROM dbo.MyOrderValues)
       AS NUMERIC(12, 2)) AS diff
FROM dbo.MyOrderValues;

-- orderid custid  val pct diff
-- 10248 85  440.00  0.03  -1085.05
-- 10249 79  1863.40 0.15  338.35
-- 10250 34  1552.60 0.12  27.55

-- Listing 7-2 Query obtaining aggregates with a cross join 从Aggs和dbo.MyOrderValues的笛卡尔积中选出值
WITH Aggs AS
(
  SELECT SUM(val) AS sumval, AVG(val) AS avgval
  FROM dbo.MyOrderValues
)
SELECT orderid, custid, val,
  CAST(val / sumval * 100. AS NUMERIC(5, 2)) AS pct,
  CAST(val - avgval AS NUMERIC(12, 2)) AS diff
FROM dbo.MyOrderValues
  CROSS JOIN Aggs;

-- orderid custid  val pct diff
-- 10248 85  440.00  0.03  -1085.05
-- 10249 79  1863.40 0.15  338.35
-- 10250 34  1552.60 0.12  27.55

-- Cleanup 清理数据表
IF OBJECT_ID('dbo.MyOrderValues', 'U') IS NOT NULL
  DROP TABLE dbo.MyOrderValues;
GO



---------------------------------------------------------------------
-- INNER
---------------------------------------------------------------------

-- Inner Join, ANSI SQL:1992 选出country是USA的Customers的所有Orders的orderid，以及其所属的Customers的custid和companyname
SELECT C.custid, companyname, orderid
FROM Sales.Customers AS C
  JOIN Sales.Orders AS O
    ON C.custid = O.custid
WHERE country = N'USA';

-- 32 Customer YSIQX  10528
-- 32 Customer YSIQX  10589
-- 32 Customer YSIQX  10616

-- Inner Join, ANSI SQL:1989 选出country是USA的Customers的所有Orders的orderid，以及其所属的Customers的custid和companyname
SELECT C.custid, companyname, orderid
FROM Sales.Customers AS C, Sales.Orders AS O
WHERE C.custid = O.custid
  AND country = N'USA';
GO

-- 32 Customer YSIQX  10528
-- 32 Customer YSIQX  10589
-- 32 Customer YSIQX  10616

-- Forgetting to Specify Join Condition, ANSI SQL:1989 所有Customers和所有Orders做笛卡尔积，选出Customers的custid和companyname，Orders的orderid
SELECT C.custid, companyname, orderid
FROM Sales.Customers AS C, Sales.Orders AS O;
GO

-- 72 Customer AHPOP  10248
-- 72 Customer AHPOP  10249
-- 72 Customer AHPOP  10250

-- Forgetting to Specify Join Condition, ANSI SQL:1989 JOIN不能没有条件
SELECT C.custid, companyname, orderid
FROM Sales.Customers AS C JOIN Sales.Orders AS O;
GO

-- 语法错误，没有结果

---------------------------------------------------------------------
-- OUTER
---------------------------------------------------------------------

-- Outer Join, ANSI SQL:1992 选出所有Customers的custid和companyname，和其所有Orders的orderid，结果包含没有Orders的Customers
SELECT C.custid, companyname, orderid
FROM Sales.Customers AS C
  LEFT OUTER JOIN Sales.Orders AS O
    ON C.custid = O.custid;
GO

-- 1  Customer NRZBB  10643
-- 1  Customer NRZBB  10692
-- 1  Customer NRZBB  10702

-- Changing the Database Compatibility Level to 2000
ALTER DATABASE InsideTSQL2008 SET COMPATIBILITY_LEVEL = 80;
GO

-- Outer Join, Old-Style Non-ANSI *=等价于left join，选出所有Customers的custid和companyname，和其所有Orders的orderid，结果包含没有Orders的Customers
SELECT C.custid, companyname, orderid
FROM Sales.Customers AS C, Sales.Orders AS O
WHERE C.custid *= O.custid;
GO

-- 1  Customer NRZBB  10643
-- 1  Customer NRZBB  10692
-- 1  Customer NRZBB  10702

-- Outer Join with Filter, ANSI SQL:1992 选出所有没有Orders的Customers的custid和companyname
SELECT C.custid, companyname, orderid
FROM Sales.Customers AS C
  LEFT OUTER JOIN Sales.Orders AS O
    ON C.custid = O.custid
WHERE O.custid IS NULL;

-- 22 Customer DTDMN  NULL
-- 57 Customer WVAXS  NULL

-- Outer Join with Filter, Old-Style Non-ANSI 先选出所有custid是null的Orders，然后所有Customers left join这些Orders
SELECT C.custid, companyname, orderid
FROM Sales.Customers AS C, Sales.Orders AS O
WHERE C.custid *= O.custid
  AND O.custid IS NULL;

-- 72 Customer AHPOP  NULL
-- 58 Customer AHXHT  NULL
-- 25 Customer AZJED  NULL

-- Changing the Database Compatibility Level Back to 2008
ALTER DATABASE InsideTSQL2008 SET COMPATIBILITY_LEVEL = 100;
GO

-- Creating and Populating the Table T1 在tempdb里创建一张名为dbo.T1的表，并插入6行数据
USE tempdb;
IF OBJECT_ID('dbo.T1', 'U') IS NOT NULL DROP TABLE dbo.T1;

CREATE TABLE dbo.T1
(
  keycol  INT         NOT NULL PRIMARY KEY,
  datacol VARCHAR(10) NOT NULL
);
GO

INSERT INTO dbo.T1(keycol, datacol) VALUES
  (1, 'e'),
  (2, 'f'),
  (3, 'a'),
  (4, 'b'),
  (6, 'c'),
  (7, 'd');

-- Using Correlated Subquery to Find Minimum Missing Value 子查询中A没有出现4和7行，所以最小的不连续值是4+1=5
SELECT MIN(A.keycol) + 1
FROM dbo.T1 AS A
WHERE NOT EXISTS
  (SELECT * FROM dbo.T1 AS B
   WHERE B.keycol = A.keycol + 1);

-- 5

-- Using Outer Join to Find Minimum Missing Value left outer join之后，B为Null的行是4和7，所以最小的不连续值是4+1=5
SELECT MIN(A.keycol) + 1
FROM dbo.T1 AS A
  LEFT OUTER JOIN dbo.T1 AS B
    ON B.keycol = A.keycol + 1
WHERE B.keycol IS NULL;
GO

-- 5

---------------------------------------------------------------------
-- Non-Supported Join Types
---------------------------------------------------------------------

---------------------------------------------------------------------
-- NATURAL, UNION Joins
---------------------------------------------------------------------
USE InsideTSQL2008;
GO

-- NATURAL Join
/*
SELECT C.custid, companyname, orderid
FROM Sales.Customers AS C NATURAL JOIN Sales.Orders AS O;
*/

-- Logically Equivalent Inner Join 内连接查询，将满足条件的Customers和Orders元组选出来并且选出custid, company, orderid。由于条件是恒成立，所以效果相当于笛卡尔积
SELECT C.custid, companyname, orderid
FROM Sales.Customers AS C
  JOIN Sales.Orders AS O
    ON O.custid = O.custid;
GO

-- 72 Customer AHPOP  10643
-- 72 Customer AHPOP  10692
-- 72 Customer AHPOP  10702

---------------------------------------------------------------------
-- Further Examples of Joins
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Self Joins
---------------------------------------------------------------------
USE InsideTSQL2008;
GO

-- 左外连接查询，会返回左表的所有行，即使没有右表项和左表匹配。这里选择的是下属Employee和Manager的关系，在Employees表内部查询上下级关系，并输出姓名。
SELECT E.firstname, E.lastname AS emp,
  M.firstname, M.lastname AS mgr
FROM HR.Employees AS E
  LEFT OUTER JOIN HR.Employees AS M
    ON E.mgrid = M.empid;
GO

-- Sara Davis NULL  NULL
-- Don  Funk  Sara  Davis
-- Judy Lew   Don   Funk

---------------------------------------------------------------------
-- Non-Equi-Joins
---------------------------------------------------------------------

-- Cross without Mirrored Pairs and without Self 内连接，条件不是相等条件，是不等条件，在Employees表中选出左边Employee ID比右边Employee ID小的所有二元组，结果保留两个Employee的ID和姓名。
SELECT E1.empid, E1.lastname, E1.firstname,
  E2.empid, E2.lastname, E2.firstname
FROM HR.Employees AS E1
  JOIN HR.Employees AS E2
    ON E1.empid < E2.empid;

-- 1  Davis Sara  2 Funk  Don
-- 1  Davis Sara  3 Lew   Judy
-- 2  Funk  Don   3 Lew   Judy

-- Calculating Row Numbers using a Join Orders表自己和自己做内连接查询，条件是左边的orderid大于等于右边的orderid，然后选出左边记录的orderid，custid，empid并且统计这三项相同的结果的数量作为rn。rn的值效果相当于计算左边项的orderid在Orders表中排第几。
SELECT O1.orderid, O1.custid, O1.empid, COUNT(*) AS rn
FROM Sales.Orders AS O1
  JOIN Sales.Orders AS O2
    ON O2.orderid <= O1.orderid
GROUP BY O1.orderid, O1.custid, O1.empid;

-- 10248  85  5 1
-- 10249  79  6 2
-- 10250  34  4 3

---------------------------------------------------------------------
-- Multi-Join Queries
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Controlling the Physical Join Evaluation Order
---------------------------------------------------------------------

-- Listing 7-3 Multi-join query
-- Suppliers that Supplied Products to Customers 通过多次内连接查询查询Customer和Supplier之间的商品供给关系，通过Customers连接到Customer的所有Order，再连接到Order的OrderDetail，接着连接到OrderDetail中包含的Production，最后就连接到了Production所来自的Supplier，最后结果只保留不同的记录。
SELECT DISTINCT C.companyname AS customer, S.companyname AS supplier
FROM Sales.Customers AS C
  JOIN Sales.Orders AS O
    ON O.custid = C.custid
  JOIN Sales.OrderDetails AS OD
    ON OD.orderid = O.orderid
  JOIN Production.Products AS P
    ON P.productid = OD.productid
  JOIN Production.Suppliers AS S
    ON S.supplierid = P.supplierid;

-- Customer AHPOP Supplier BWGYE
-- Customer AHPOP Supplier ELCRN
-- Customer AHPOP Supplier EQPNC

-- Listing 7-4 Multi-join query, forcing order
-- Controlling the Physical Join Evaluation Order 和前一查询查询相同的内容，不过要求数据库管理系统强制采用连接的顺序生成执行计划，如果不强制，则数据库引擎会自动优化生成执行计划，但自动优化不一定是最优的。
SELECT DISTINCT C.companyname AS customer, S.companyname AS supplier
FROM Sales.Customers AS C
  JOIN Sales.Orders AS O
    ON O.custid = C.custid
  JOIN Sales.OrderDetails AS OD
    ON OD.orderid = O.orderid
  JOIN Production.Products AS P
    ON P.productid = OD.productid
  JOIN Production.Suppliers AS S
    ON S.supplierid = P.supplierid
OPTION (FORCE ORDER);

-- Customer AHPOP Supplier BWGYE
-- Customer AHPOP Supplier ELCRN
-- Customer AHPOP Supplier EQPNC

---------------------------------------------------------------------
-- Controlling the Logical Join Evaluation Order
---------------------------------------------------------------------

-- Including Customers with no Orders, Attempt with Left Join 同样是和前面查询查询相同的信息，但是由于查询过程中Customer到Order的连接采用了左外连接，因此会保留所有没有Order的Customer信息。
SELECT DISTINCT C.companyname AS customer, S.companyname AS supplier
FROM Sales.Customers AS C
  LEFT OUTER JOIN Sales.Orders AS O
    ON O.custid = C.custid
  JOIN Sales.OrderDetails AS OD
    ON OD.orderid = O.orderid
  JOIN Production.Products AS P
    ON P.productid = OD.productid
  JOIN Production.Suppliers AS S
    ON S.supplierid = P.supplierid;

-- Customer AHPOP Supplier BWGYE
-- Customer AHPOP Supplier ELCRN
-- Customer AHPOP Supplier EQPNC

-- Multiple Left Joins 同样和前面的查询查询相同的信息，但所有的中间连接过程都采用了左外连接查询，因此会保留没有OrderDetail的Order，没有Production的OrderDetail，和没有Supplier的Production这些项，但由于最后结果保留不同的项，因此这些项会以customer NULL的形式出现在结果中。
SELECT DISTINCT C.companyname AS customer, S.companyname AS supplier
FROM Sales.Customers AS C
  LEFT OUTER JOIN Sales.Orders AS O
    ON O.custid = C.custid
  LEFT OUTER JOIN Sales.OrderDetails AS OD
    ON OD.orderid = O.orderid
  LEFT OUTER JOIN Production.Products AS P
    ON P.productid = OD.productid
  LEFT OUTER JOIN Production.Suppliers AS S
    ON S.supplierid = P.supplierid;

-- Customer AHPOP Supplier BWGYE
-- Customer AHPOP Supplier ELCRN
-- Customer AHPOP Supplier EQPNC

-- Right Join Performed Last 和前面的查询查询相同的信息，但改变连接的顺序，这次从Order开始向两端做连接，最后连接到Customer时使用右外连接，同样是保留了所有没有Order的Customer项。
SELECT DISTINCT C.companyname AS customer, S.companyname AS supplier
FROM Sales.Orders AS O
  JOIN Sales.OrderDetails AS OD
    ON OD.orderid = O.orderid
  JOIN Production.Products AS P
    ON P.productid = OD.productid
  JOIN Production.Suppliers AS S
    ON S.supplierid = P.supplierid
  RIGHT OUTER JOIN Sales.Customers AS C
    ON O.custid = C.custid;

-- Customer AHPOP Supplier BWGYE
-- Customer AHPOP Supplier ELCRN
-- Customer AHPOP Supplier EQPNC

-- Using Parenthesis 和前面的查询查询相同的信息，不过采用了括号来控制连接的顺序，先通过Order多次连接，找到所有的Order和Supplier的关系，最后采用一个左外连接将Customer和Supplier的关系找到。
SELECT DISTINCT C.companyname AS customer, S.companyname AS supplier
FROM Sales.Customers AS C
  LEFT OUTER JOIN
    (     Sales.Orders AS O
     JOIN Sales.OrderDetails AS OD
       ON OD.orderid = O.orderid
     JOIN Production.Products AS P
       ON P.productid = OD.productid
     JOIN Production.Suppliers AS S
       ON S.supplierid = P.supplierid)
    ON O.custid = C.custid;

-- Customer AHPOP Supplier BWGYE
-- Customer AHPOP Supplier ELCRN
-- Customer AHPOP Supplier EQPNC

-- Changing ON Clause Order 和前面的查询查询相同的信息，不过把第一个左外连接的ON语句放在最后，相当于前一查询将括号去掉，其结果是一样的。
SELECT DISTINCT C.companyname AS customer, S.companyname AS supplier
FROM Sales.Customers AS C
  LEFT OUTER JOIN
          Sales.Orders AS O
     JOIN Sales.OrderDetails AS OD
       ON OD.orderid = O.orderid
     JOIN Production.Products AS P
       ON P.productid = OD.productid
     JOIN Production.Suppliers AS S
       ON S.supplierid = P.supplierid
    ON O.custid = C.custid;

-- Customer AHPOP Supplier BWGYE
-- Customer AHPOP Supplier ELCRN
-- Customer AHPOP Supplier EQPNC

-- 同样只是改变ON语句的位置顺序，查询的内容个前面的查询一致，说明数据库引擎会预处理SQL语句自动优化生成执行计划。
SELECT DISTINCT C.companyname AS customer, S.companyname AS supplier
FROM Sales.Customers AS C
  LEFT OUTER JOIN Sales.Orders AS O
  JOIN Production.Products AS P
  JOIN Sales.OrderDetails AS OD
    ON P.productid = OD.productid
    ON OD.orderid = O.orderid
  JOIN Production.Suppliers AS S
    ON S.supplierid = P.supplierid
    ON O.custid = C.custid;

-- Customer AHPOP Supplier BWGYE
-- Customer AHPOP Supplier ELCRN
-- Customer AHPOP Supplier EQPNC

-- 同样只是改变ON语句的位置顺序，查询的内容个前面的查询一致，说明数据库引擎会预处理SQL语句自动优化生成执行计划。
SELECT DISTINCT C.companyname AS customer, S.companyname AS supplier
FROM Sales.Customers AS C
  LEFT OUTER JOIN Sales.Orders AS O
  JOIN Sales.OrderDetails AS OD
  JOIN Production.Products AS P
  JOIN Production.Suppliers AS S
    ON S.supplierid = P.supplierid
    ON P.productid = OD.productid
    ON OD.orderid = O.orderid
    ON O.custid = C.custid;
GO

-- Customer AHPOP Supplier BWGYE
-- Customer AHPOP Supplier ELCRN
-- Customer AHPOP Supplier EQPNC



---------------------------------------------------------------------
-- Set Operations
---------------------------------------------------------------------

---------------------------------------------------------------------
-- UNION
---------------------------------------------------------------------

---------------------------------------------------------------------
-- UNION DISTINCT
---------------------------------------------------------------------

-- UNION DISTINCT：选出Employees表和Customers表中的country，region和city列并将结果合并(删除重复行)
USE InsideTSQL2008;

SELECT country, region, city FROM HR.Employees
UNION
SELECT country, region, city FROM Sales.Customers;

-- 1 Argentina  NULL  Buenos Aires
-- 2 Austria  NULL  Graz
-- 3 Austria  NULL  Salzburg
---------------------------------------------------------------------
-- UNION ALL
---------------------------------------------------------------------

-- UNION ALL：选出Employees表和Customers表中的country，region和city列并将结果合并(不删除重复行)
SELECT country, region, city FROM HR.Employees
UNION ALL
SELECT country, region, city FROM Sales.Customers;

-- 1 USA  WA  Seattle
-- 2 USA  WA  Tacoma
-- 3 USA  WA  Kirkland

---------------------------------------------------------------------
-- EXCEPT
---------------------------------------------------------------------

---------------------------------------------------------------------
-- EXCEPT DISTINCT
---------------------------------------------------------------------

-- EXCEPT DISTINCT, Employees EXCEPT Customers：选出所有包括在Employees表而不在Customer表中的行的country，region，city列
SELECT country, region, city FROM HR.Employees
EXCEPT
SELECT country, region, city FROM Sales.Customers;

-- 1 USA  WA  Redmond
-- 2 USA  WA  Tacoma

-- EXCEPT DISTINCT, Customers EXCEPT Employees：选出所有包括在Customer表而不在Employees表中的行的country，region，city列
SELECT country, region, city FROM Sales.Customers
EXCEPT
SELECT country, region, city FROM HR.Employees;

-- 1 Argentina  NULL  Buenos Aires
-- 2 Austria  NULL  Graz
-- 3 Austria  NULL  Salzburg
---------------------------------------------------------------------
-- EXCEPT ALL
---------------------------------------------------------------------

--将Employ表以country，region，city分组，在每行加上rn属性标示组内的顺序编号(select 0->不排序直接顺序编号)得到表A
--将Customers表以country，region，city分组，在每行加上rn属性标示组内的顺序编号(select 0->不排序直接顺序编号)得到表B
--选出在表A而不在表B中的行的country，region，city列(这几列相同的行合并输出)
WITH EXCEPT_ALL
AS
(
  SELECT
    ROW_NUMBER()
      OVER(PARTITION BY country, region, city
           ORDER     BY (SELECT 0)) AS rn,
    country, region, city
    FROM HR.Employees

  EXCEPT

  SELECT
    ROW_NUMBER()
      OVER(PARTITION BY country, region, city
           ORDER     BY (SELECT 0)) AS rn,
    country, region, city
  FROM Sales.Customers
)
SELECT country, region, city
FROM EXCEPT_ALL;

-- 1 USA  WA  Redmond
-- 2 USA  WA  Tacoma
-- 3 USA  WA  Seattle
---------------------------------------------------------------------
-- INTERSCET
---------------------------------------------------------------------

---------------------------------------------------------------------
-- INTERSECT DISTINCT
---------------------------------------------------------------------

--选出所有既在Employees表也在Customer表中的行的country，region，city列

SELECT country, region, city FROM HR.Employees
INTERSECT
SELECT country, region, city FROM Sales.Customers;

-- 1 UK NULL  London
-- 2 USA  WA  Kirkland
-- 3 USA  WA  Seattle
---------------------------------------------------------------------
-- INTERSECT ALL
---------------------------------------------------------------------

--将Employ表以country，region，city分组，在每行加上rn属性标示组内的顺序编号(select 0->不排序直接顺序编号)得到表A
--将Customers表以country，region，city分组，在每行加上rn属性标示组内的顺序编号(select 0->不排序直接顺序编号)得到表B
--选出既在表A也在表B中的行的country，region，city列(这几列相同的行合并输出)

WITH INTERSECT_ALL
AS
(
  SELECT
    ROW_NUMBER()
      OVER(PARTITION BY country, region, city
           ORDER     BY (SELECT 0)) AS rn,
    country, region, city
  FROM HR.Employees

  INTERSECT

  SELECT
    ROW_NUMBER()
      OVER(PARTITION BY country, region, city
           ORDER     BY (SELECT 0)) AS rn,
    country, region, city
    FROM Sales.Customers
)
SELECT country, region, city
FROM INTERSECT_ALL;

-- 1 UK NULL  London
-- 2 USA  WA  Kirkland
-- 3 USA  WA  Seattle
---------------------------------------------------------------------
-- Precedence
---------------------------------------------------------------------

-- INTERSECT Precedes EXCEPT：选出在表Suppliers而不在(由既在表Employees也在表Customers中的行的country，region，city列构建出的新表)中的行的country，region，city列

SELECT country, region, city FROM Production.Suppliers
EXCEPT
SELECT country, region, city FROM HR.Employees
INTERSECT
SELECT country, region, city FROM Sales.Customers;

-- 1 Australia  NSW Sydney
-- 2 Australia  Victoria  Melbourne
-- 3 Brazil NULL  Sao Paulo

-- Using Parenthesis：选出所有既在(由在表Employees而不在表Suppliers中的行的country，region，city列构建出的新表)也在表Customers中的行的country，region，city列

(SELECT country, region, city FROM Production.Suppliers
 EXCEPT
 SELECT country, region, city FROM HR.Employees)
INTERSECT
SELECT country, region, city FROM Sales.Customers;

-- 1 Canada Québec  Montréal
-- 2 France NULL  Paris
-- 3 Germany  NULL  Berlin

-- Using INTO with Set Operations：创建一个临时表，这个表包含了
-- 在表Suppliers而不在(由既在表Employees也在表Customers中的行的country，region，city列构建出的新表)中的行的country，region，city列

SELECT country, region, city INTO #T FROM Production.Suppliers
EXCEPT
SELECT country, region, city FROM HR.Employees
INTERSECT
SELECT country, region, city FROM Sales.Customers;

--建表操作没有输出，表#T的前几行为：(和INTERSECT Precedes EXCEPT结果一样)
-- 1 Australia  NSW Sydney
-- 2 Australia  Victoria  Melbourne
-- 3 Brazil NULL  Sao Paulo

-- Cleanup
DROP TABLE #T;
GO


---------------------------------------------------------------------
-- Circumventing Unsupported Logical Phases
---------------------------------------------------------------------

-- Number of Cities per Country Covered by Both Customers
-- and Employees 选出每个国家包含Customer或Employee的城市数量
SELECT country, COUNT(*) AS numcities
FROM (SELECT country, region, city FROM HR.Employees
      UNION
      SELECT country, region, city FROM Sales.Customers) AS U
GROUP BY country;

-- Argentina 1
-- Austria 2
-- Belgium 2
-- Brazil  4
-- Canada  3
-- Denmark 2
-- Finland 2
-- France  9
-- Germany 11
-- Ireland 1
-- Italy 3
-- Mexico  1
-- Norway  1
-- Poland  1
-- Portugal  1
-- Spain 3
-- Sweden  2
-- Switzerland 2
-- UK  2
-- USA 14
-- Venezuela 4

-- Two most recent orders for employees 3 and 5
-- 查询employee 3和5最近的两个订单
-- 将一个employee的所有订单先选出来对日期排序，选出前两个然后
-- 把两个employee的结果进行合并
SELECT empid, orderid, orderdate
FROM (SELECT TOP (2) empid, orderid, orderdate
      FROM Sales.Orders
      WHERE empid = 3
      ORDER BY orderdate DESC, orderid DESC) AS D1

UNION ALL

SELECT empid, orderid, orderdate
FROM (SELECT TOP (2) empid, orderid, orderdate
      FROM Sales.Orders
      WHERE empid = 5
      ORDER BY orderdate DESC, orderid DESC) AS D2;

-- 3 11063 2008-04-30 00:00:00.000
-- 3 11057 2008-04-29 00:00:00.000
-- 5 11043 2008-04-22 00:00:00.000
-- 5 10954 2008-03-17 00:00:00.000

-- Sorting each Input Independently
-- 对不同的结果采用不同的排序方式（对输入进行独立的排序）
-- 对custid为1的记录根据orderid进行降序排序
-- 对empid为3的记录根据orderdate进行降序排序
-- 做法是为每个结果添加一个sortcol列，赋予不同的值表示不同的排序规则
SELECT empid, custid, orderid, orderdate
FROM (SELECT 1 AS sortcol, custid, empid, orderid, orderdate
      FROM Sales.Orders
      WHERE custid = 1

      UNION ALL

      SELECT 2 AS sortcol, custid, empid, orderid, orderdate
      FROM Sales.Orders
      WHERE empid = 3) AS U
ORDER BY sortcol,
  CASE WHEN sortcol = 1 THEN orderid END,
  CASE WHEN sortcol = 2 THEN orderdate END DESC;

-- 6 1 10643 2007-08-25 00:00:00.000
-- 4 1 10692 2007-10-03 00:00:00.000
-- 4 1 10702 2007-10-13 00:00:00.000
-- 1 1 10835 2008-01-15 00:00:00.000
-- 1 1 10952 2008-03-16 00:00:00.000
-- 3 1 11011 2008-04-09 00:00:00.000
-- 3 37  11063 2008-04-30 00:00:00.000
-- 3 53  11057 2008-04-29 00:00:00.000
-- 3 34  11052 2008-04-27 00:00:00.000
-- 3 31  11049 2008-04-24 00:00:00.000
-- 3 14  11041 2008-04-22 00:00:00.000
-- 3 63  11021 2008-04-14 00:00:00.000


---------------------------------------------------------------------
-- Grouping Factor
---------------------------------------------------------------------

-- Creating and Populating the Stocks Table
-- 创建并填充Stocks表
-- 清空、建表、插数据、设置索引，一气呵成
USE tempdb;

IF OBJECT_ID('Stocks') IS NOT NULL DROP TABLE Stocks;

CREATE TABLE dbo.Stocks
(
  dt    DATE NOT NULL PRIMARY KEY,
  price INT  NOT NULL
);
GO

INSERT INTO dbo.Stocks(dt, price) VALUES
  ('20090801', 13),
  ('20090802', 14),
  ('20090803', 17),
  ('20090804', 40),
  ('20090805', 40),
  ('20090806', 52),
  ('20090807', 56),
  ('20090808', 60),
  ('20090809', 70),
  ('20090810', 30),
  ('20090811', 29),
  ('20090812', 29),
  ('20090813', 40),
  ('20090814', 45),
  ('20090815', 60),
  ('20090816', 60),
  ('20090817', 55),
  ('20090818', 60),
  ('20090819', 60),
  ('20090820', 15),
  ('20090821', 20),
  ('20090822', 30),
  ('20090823', 40),
  ('20090824', 20),
  ('20090825', 60),
  ('20090826', 60),
  ('20090827', 70),
  ('20090828', 70),
  ('20090829', 40),
  ('20090830', 30),
  ('20090831', 10);

CREATE UNIQUE INDEX idx_price_dt ON Stocks(price, dt);
GO

-- Ranges where Stock Price was >= 50
-- 选出Stock Price大于50的时间范围和其最高价格
-- 先找到所有price大于等于50的日期，然后选择其后的最近的价格小于50的日期作为grp，
-- 关于其分组，然后选择其中的最小日期、最大日期、日期差和最高价格
SELECT MIN(dt) AS startrange, MAX(dt) AS endrange,
  DATEDIFF(day, MIN(dt), MAX(dt)) + 1 AS numdays,
  MAX(price) AS maxprice
FROM (SELECT dt, price,
        (SELECT MIN(dt)
         FROM dbo.Stocks AS S2
         WHERE S2.dt > S1.dt
          AND price < 50) AS grp
      FROM dbo.Stocks AS S1
      WHERE price >= 50) AS D
GROUP BY grp;

-- 2009-08-06  2009-08-09  4 70
-- 2009-08-15  2009-08-19  5 60
-- 2009-08-25  2009-08-28  4 70

-- Solution using ROW_NUMBER
-- 功能同上，但是使用的是ROW_NUMBER
-- 先找到所有price大于等于50的日期，排序，利用连续日期的列号也连续，将日期减去其列号作为grp，
-- 关于其分组，然后选择其中的最小日期、最大日期、日期差和最高价格
SELECT MIN(dt) AS startrange, MAX(dt) AS endrange,
  DATEDIFF(day, MIN(dt), MAX(dt)) + 1 AS numdays,
  MAX(price) AS maxprice
FROM (SELECT dt, price,
        DATEADD(day, -1 * ROW_NUMBER() OVER(ORDER BY dt), dt) AS grp
      FROM dbo.Stocks AS S1
      WHERE price >= 50) AS D
GROUP BY grp;
GO

-- 2009-08-06  2009-08-09  4 70
-- 2009-08-15  2009-08-19  5 60
-- 2009-08-25  2009-08-28  4 70

---------------------------------------------------------------------
-- Grouping Sets
---------------------------------------------------------------------

-- Code to Create and Populate the Orders Table (same as in Listing 8-1)
SET NOCOUNT ON;
USE tempdb;

IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
GO

CREATE TABLE dbo.Orders
(
  orderid   INT        NOT NULL,
  orderdate DATETIME   NOT NULL,
  empid     INT        NOT NULL,
  custid    VARCHAR(5) NOT NULL,
  qty       INT        NOT NULL,
  CONSTRAINT PK_Orders PRIMARY KEY(orderid)
);
GO

INSERT INTO dbo.Orders
  (orderid, orderdate, empid, custid, qty)
VALUES
  (30001, '20060802', 3, 'A', 10),
  (10001, '20061224', 1, 'A', 12),
  (10005, '20061224', 1, 'B', 20),
  (40001, '20070109', 4, 'A', 40),
  (10006, '20070118', 1, 'C', 14),
  (20001, '20070212', 2, 'B', 12),
  (40005, '20080212', 4, 'A', 10),
  (20002, '20080216', 2, 'C', 20),
  (30003, '20080418', 3, 'B', 15),
  (30004, '20060418', 3, 'C', 22),
  (30007, '20060907', 3, 'D', 30);

---------------------------------------------------------------------
-- GROUPING SETS Subclause
---------------------------------------------------------------------
-- 按照SETS内的四种分组方式分组并将分组结果合并，其中空括号表示所有行为一组。结果为各cusid、empid
-- 在各YEAR(orderdate)完成的qty统计和qty总量的统计。
SELECT custid, empid, YEAR(orderdate) AS orderyear, SUM(qty) AS qty
FROM dbo.Orders
GROUP BY GROUPING SETS
(
  ( custid, empid, YEAR(orderdate) ),
  ( custid, YEAR(orderdate)        ),
  ( empid, YEAR(orderdate)         ),
  ()
);

-- 1 A    1 2006 12
-- 2 B    1 2006 20
-- 3 BULL 1 2006 32

-- Logically equivalent to unifying multiple aggregate queries:
SELECT custid, empid, YEAR(orderdate) AS orderyear, SUM(qty) AS qty
FROM dbo.Orders
GROUP BY custid, empid, YEAR(orderdate)

UNION ALL

SELECT custid, NULL AS empid, YEAR(orderdate) AS orderyear, SUM(qty) AS qty
FROM dbo.Orders
GROUP BY custid, YEAR(orderdate)

UNION ALL

SELECT NULL AS custid, empid, YEAR(orderdate) AS orderyear, SUM(qty) AS qty
FROM dbo.Orders
GROUP BY empid, YEAR(orderdate)

UNION ALL

SELECT NULL AS custid, NULL AS empid, NULL AS orderyear, SUM(qty) AS qty
FROM dbo.Orders;

-- 1 A 1 2006 12
-- 2 A 3 2006 10
-- 3 A 4 2007 40

---------------------------------------------------------------------
-- CUBE Subclause
---------------------------------------------------------------------
-- 按照(custid, empid)的所有可能的组合进行分组并将结果合并。结果为各custid，empid完成的qty的统计
SELECT custid, empid, SUM(qty) AS qty
FROM dbo.Orders
GROUP BY CUBE(custid, empid);

-- 1 A 1 12
-- 2 B 1 20
-- 3 C 1 14

-- Equivalent to:
SELECT custid, empid, SUM(qty) AS qty
FROM dbo.Orders
GROUP BY GROUPING SETS
  (
    ( custid, empid ),
    ( custid        ),
    ( empid         ),
    ()
  );

-- 1 A 1 12
-- 2 B 1 20
-- 3 C 1 14

-- Pre-2008 CUBE option: 与GROUP BY CUBE(custid, empid)语义相同
SELECT custid, empid, SUM(qty) AS qty
FROM dbo.Orders
GROUP BY custid, empid
WITH CUBE;

-- 1 A 1 12
-- 2 B 1 20
-- 3 C 1 14
---------------------------------------------------------------------
-- ROLLUP Subclause
---------------------------------------------------------------------
-- 按照分组目标列进行层次式分组，即分别按照(YEAR(orderdate), MONTH(orderdate), DAY(orderdate)),(YEAR(orderdate), MONTH(orderdate)),
--( YEAR(orderdate)),()进行分组并将结果合并。结果为各年、月、日完成的qty总量统计。
SELECT
  YEAR(orderdate) AS orderyear,
  MONTH(orderdate) AS ordermonth,
  DAY(orderdate) AS orderday,
  SUM(qty) AS qty
FROM dbo.Orders
GROUP BY
  ROLLUP(YEAR(orderdate), MONTH(orderdate), DAY(orderdate));

-- 1 2006 4 18   22
-- 2 2006 4 NULL 22
-- 3 2006 8 2    10


-- Equivalent to:
SELECT
  YEAR(orderdate) AS orderyear,
  MONTH(orderdate) AS ordermonth,
  DAY(orderdate) AS orderday,
  SUM(qty) AS qty
FROM dbo.Orders
GROUP BY
  GROUPING SETS
  (
    ( YEAR(orderdate), MONTH(orderdate), DAY(orderdate) ),
    ( YEAR(orderdate), MONTH(orderdate)                 ),
    ( YEAR(orderdate)                                   ),
    ()
  );

-- 1 2006 4 18   22
-- 2 2006 4 NULL 22
-- 3 2006 8 2    10

-- Pre-2008 ROLLUP option
SELECT
  YEAR(orderdate) AS orderyear,
  MONTH(orderdate) AS ordermonth,
  DAY(orderdate) AS orderday,
  SUM(qty) AS qty
FROM dbo.Orders
GROUP BY YEAR(orderdate), MONTH(orderdate), DAY(orderdate)
WITH ROLLUP;

-- 1 2006 4 18 22
-- 2 2006 4 NULL 22
-- 3 2006 8 2 10

-- GROUPING_ID不定参数，返回值为sigma( (arg[i] == null) * 2 ^ (n - i - 1) )(0 <= i < n) n为参数 个数

-- 对order表两组列分别进行cube和rollup操作后GROUP BY，制造存在null值的列，验证GROUPING_ID函数作用于多列时的返回值。
-- 0   C     3     2006  4 18    22
-- 16  NULL  3     2006  4 18    22
-- 24  NULL  NULL  2006  4 18    22

SELECT
  GROUPING_ID(
    custid, empid,
    YEAR(orderdate), MONTH(orderdate), DAY(orderdate) ) AS grp_id,
  custid, empid,
  YEAR(orderdate) AS orderyear,
  MONTH(orderdate) AS ordermonth,
  DAY(orderdate) AS orderday,
  SUM(qty) AS qty
FROM dbo.Orders
GROUP BY
  CUBE(custid, empid),
  ROLLUP(YEAR(orderdate), MONTH(orderdate), DAY(orderdate));

-- 利用GROUPING_ID函数作用于多列时的性质，生成0~31的二进制表示，从高到低每一位的值分别存在列16, 8, 4, 2, 1
-- COALESCE函数返回参数表中第一个非空值
-- CUBE结合COALESCE函数生成全部5位二进制数后，使用GROUPING_ID函数求和后排序
-- 0 0 0 0 0 0
-- 1 0 0 0 0 1
-- 2 0 0 0 1 0

SELECT
  GROUPING_ID(e, d, c, b, a) as n,
  COALESCE(e, 1) as [16],
  COALESCE(d, 1) as [8],
  COALESCE(c, 1) as [4],
  COALESCE(b, 1) as [2],
  COALESCE(a, 1) as [1]
FROM (VALUES(0, 0, 0, 0, 0)) AS D(a, b, c, d, e)
GROUP BY CUBE (a, b, c, d, e)
ORDER BY n;

-- Pre-2008, Identifying Grouping Set
-- 意思大概是2008之前不支持GROUPING_ID，只能用GROUPING函数进行模拟，GROUPING等价于只能作用于一个参数的GROUPING_ID
-- 这个SELECT跟第一个不太一样，减少了时间的month和day列，取消了ROLLUP操作
-- 0 A     1 2006  12
-- 0 B     1 2006  20
-- 4 NULL  1 2006  32

SELECT
  GROUPING(custid)          * 4 +
  GROUPING(empid)           * 2 +
  GROUPING(YEAR(orderdate)) * 1 AS grp_id,
  custid, empid, YEAR(orderdate) AS orderyear,
  SUM(qty) AS totalqty
FROM dbo.Orders
GROUP BY custid, empid, YEAR(orderdate)
WITH CUBE;
