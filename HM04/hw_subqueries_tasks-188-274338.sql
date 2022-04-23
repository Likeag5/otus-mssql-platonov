/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

SELECT p.PersonID, p.FullName
FROM Application.People p
WHERE p.IsSalesperson = 1 
	and exists (SELECT 1 FROM Sales.Invoices s
				WHERE s.SalespersonPersonID = p.PersonID
					and s.InvoiceDate != '2015-07-04');

SELECT p.PersonID, p.FullName
FROM Application.People p
WHERE p.IsSalesperson = 1 
	and p.PersonID in (SELECT distinct s.SalespersonPersonID 
					   FROM Sales.Invoices s
					   WHERE s.InvoiceDate != '2015-07-04');

with people_cte as (
	SELECT distinct s.SalespersonPersonID 
	FROM Sales.Invoices s
	WHERE s.InvoiceDate != '2015-07-04'
)
SELECT p.PersonID, p.FullName FROM Application.People p
WHERE p.IsSalesperson = 1 and p.PersonID in (SELECT SalespersonPersonID FROM people_cte);



/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

--TODO: напишите здесь свое решение

SELECT s.StockItemID, s.StockItemName, s.UnitPrice 
FROM Warehouse.StockItems s
WHERE s.UnitPrice = (SELECT min(s.UnitPrice) as unitprice
					 FROM Warehouse.StockItems s);

SELECT s.StockItemID, s.StockItemName, s.UnitPrice 
FROM Warehouse.StockItems s
WHERE exists (
			  SELECT st.unitprice FROM (
				  SELECT min(st.UnitPrice) as unitprice
				  FROM Warehouse.StockItems st
			  ) st 
			  WHERE st.unitprice = s.UnitPrice
			  );

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

--TODO: напишите здесь свое решение

with cust_tr_cte as (
	SELECT row_number() over(ORDER BY c.transactionamount desc) rn, c.*
	FROM Sales.CustomerTransactions c
)
SELECT CustomerID, TransactionAmount 
FROM cust_tr_cte
WHERE rn <= 5;


SELECT top 5 c.CustomerID, max(c.TransactionAmount) as tramount
FROM Sales.CustomerTransactions c
GROUP BY c.CustomerID, c.CustomerTransactionID
ORDER BY tramount desc;






/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

--TODO: напишите здесь свое решение

/*
SELECT * FROM Application.Cities;

SELECT * FROM Warehouse.StockItems st;

SELECT * FROM Sales.Invoices;

SELECT * FROM Sales.Orders;

SELECT * FROM Sales.OrderLines;

SELECT * FROM Sales.Invoices;

SELECT * FROM Sales.InvoiceLines;

SELECT * FROM Sales.Customers;

SELECT * FROM Purchasing.PurchaseOrderLines;

SELECT * FROM Purchasing.PurchaseOrders;

SELECT * FROM Application.DeliveryMethods;

SELECT * FROM Application.Cities;

SELECT * FROM Application.People;
*/


with top_3 as (
	SELECT distinct top 3 StockItemID, UnitPrice
	FROM Sales.OrderLines ol
	ORDER BY UnitPrice desc
)
SELECT distinct DeliveryCityID, ci.CityName, p.FullName
FROM Sales.Customers c
left join Sales.Invoices i
	on c.CustomerID = i.CustomerID
left join Sales.InvoiceLines il
	on i.InvoiceID = il.InvoiceID
left join Application.Cities ci
	on ci.CityID = c.DeliveryCityID
left join Application.People p
	on p.PersonID = i.PackedByPersonID
WHERE il.StockItemID in (SELECT StockItemID FROM top_3);



-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

TODO: напишите здесь свое решение
