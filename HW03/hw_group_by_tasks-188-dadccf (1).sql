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
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/
SELECT 
  year(o.OrderDate) as OrderDateY, 
  month(o.OrderDate) as OrderDateM,
  count(*) as AllSales,
  avg(il.UnitPrice) as AvgPrice
  FROM Sales.Orders o
  JOIN Sales.Invoices i ON o.OrderID = i.OrderID
  JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
  GROUP BY year(o.OrderDate), month(o.OrderDate)
  ORDER BY OrderDateY, OrderDateM

/* Не понимаю, почему не получается вместо month(o.OrderDate) в GROUP BY указать OrderDateM
*/

/*
2. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT 
  year(o.OrderDate) as OrderDateY, 
  month(o.OrderDate) as OrderDateM,
  sum(il.UnitPrice) as TotalPrice

FROM Sales.Invoices i
JOIN Sales.Orders o ON i.OrderID = o.OrderID
JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
GROUP BY year(o.OrderDate), month(o.OrderDate)
HAVING sum(il.UnitPrice) > 10000 OR sum(il.UnitPrice) IS NULL

ORDER BY OrderDateY, OrderDateM

/* Также не понимаю, почему в HAVING не могу указывать псевдоним
*/
/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT 
  year(o.OrderDate) as OrderDateY, 
  month(o.OrderDate) as OrderDateM,
  s.StockItemName,
  sum(il.UnitPrice) as TotalPrice,
  min(o.OrderDate) as SaleFirstDate,
  count(il.StockItemID) as QuantitySold


FROM Sales.Invoices i
JOIN Sales.Orders o ON i.OrderID = o.OrderID
JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
JOIN Warehouse.StockItems s ON il.StockItemID = s.StockItemID
GROUP BY year(o.OrderDate), month(o.OrderDate), s.StockItemName
HAVING count(il.StockItemID) > 50 OR count(il.StockItemID) IS NULL


ORDER BY OrderDateY, OrderDateM

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
