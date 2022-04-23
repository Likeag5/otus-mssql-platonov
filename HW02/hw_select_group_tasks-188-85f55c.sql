/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

Select	StockitemID,
		StockItemName
From	Warehouse.StockItems
		Where StockItemName Like '%urgent%' or 
			  StockItemName Like'Animal%'
	
/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT
  s.SupplierID,
  s.SupplierName,
  t.PurchaseOrderID
FROM  Purchasing.Suppliers s
LEFT JOIN Purchasing.PurchaseOrders t
	ON t.SupplierID = s.SupplierID
	where t.PurchaseOrderID is null
/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/


SELECT 
	o.OrderID, 
	convert(nvarchar(16), o.OrderDate, 104) as OrderDate,
	month(o.OrderDate) AS 'Month',
	DATEPART(q, o.OrderDate) AS 'Quarter',
	c.CustomerName,
	CASE
        WHEN month(o.OrderDate) < '5' THEN '1' /* Нужно ли было здесь более лаконичное решение с определением трети года? */
        WHEN month(o.OrderDate) > '8' THEN '3' 
		ELSE '2' 
		END [Quadrimester]
FROM Sales.Orders o
Join Sales.Customers c 
	ON o.CustomerID = c.CustomerID
Join Sales.OrderLines ol
	ON o.OrderID = ol.OrderID

	WHERE (ol.UnitPrice > '100') OR (ol.Quantity > '20' AND ol.PickingCompletedWhen IS NOT NULL)
ORDER BY 'Quarter', 'Quadrimester', o.OrderDate
OFFSET 1000 ROWS FETCH NEXT 100 ROWS ONLY; 

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

SELECT
  d.DeliveryMethodName,
  o.ExpectedDeliveryDate,
  s.SupplierName,
  p.FullName
FROM Purchasing.PurchaseOrders o
JOIN Purchasing.Suppliers s
	ON o.SupplierID = s.SupplierID
JOIN Application.DeliveryMethods d
	ON o.DeliveryMethodID = d.DeliveryMethodID
JOIN Application.People p
	ON o.ContactPersonID = p.PersonID
WHERE ((o.ExpectedDeliveryDate between '2013-01-01' AND '2013-02-01') AND (d.DeliveryMethodName = 'Air Freight'))
								OR (d.DeliveryMethodName = 'Refrigerated Air Freight' AND o.IsOrderFinalized = '1')


/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT TOP 10
  o.OrderID,
  pp.FullName AS 'Customer',
  p.FullName AS 'Salesperson'
FROM Sales.Orders o

JOIN Application.People p
	ON o.SalespersonPersonID = p.PersonID
JOIN Application.People pp
	ON o.CustomerID = pp.PersonID
ORDER BY o.ExpectedDeliveryDate DESC
/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/
SELECT 
  o.CustomerID,
  p.FullName,
  p.PersonID,
  p.PhoneNumber,
  p.FaxNumber
FROM Sales.Orders o
JOIN Application.People p
	ON o.CustomerID = p.PersonID
JOIN Sales.OrderLines ol
	ON o.OrderID = ol.OrderID
JOIN Warehouse.StockItems i
	ON ol.StockItemID = i.StockItemID
WHERE i.StockItemName = 'Chocolate frogs 250g'


