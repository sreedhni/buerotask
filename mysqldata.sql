create database mydata;
use mydata;
create table booking(
    id int auto_increment primary key,
    booking_id varchar(200) unique,
    mode_of_shipment_id int not null,
    port_of_departure varchar(200) not null,
    date_of_departure date not null,
    port_of_discharge varchar(200) not null,
    date_of_discharge date not null
);

create table customer(
    id int auto_increment primary key,
    customer_name varchar(200) unique,
    country_name varchar(200)
);

create table customer_invoice_head(
    id int auto_increment primary key,
    invoice_id varchar(200) unique,
    invoice_sent_date date not null,
    invoice_due_date date not null,
    invoice_paid_date date not null
);

create table customer_invoice_body(
    id int auto_increment primary key,
    invoice_currency varchar(200) not null,
    purchase_order_ref varchar(200) not null,
    booking_id varchar(200),
    customer_id int,
    foreign key(booking_id) references booking(booking_id) on delete cascade,
    foreign key(customer_id) references customer(id) on delete cascade
);

create table customer_invoice_leg(
    id int auto_increment primary key,
    leg_name varchar(200) not null,
    original_currency varchar(200) not null,
    amount_in_original_currency float not null,
    amount_in_invoice_currency float not null
);

create table customer_invoice_relationship(
    id int auto_increment primary key,
    head_id int,
    body_id int,
    leg_id int,
    foreign key(head_id) references customer_invoice_head(id) on delete cascade,
    foreign key(body_id) references customer_invoice_body(id) on delete cascade,
    foreign key(leg_id) references customer_invoice_leg(id) on delete cascade
);
   
SELECT booking_id
FROM booking
WHERE mode_of_shipment_id = 3
  AND date_of_departure BETWEEN '2021-01-01' AND '2021-01-31';

SELECT mode_of_shipment_id, COUNT(*) as number_of_bookings
FROM booking
WHERE date_of_departure BETWEEN '2021-01-01' AND '2021-01-31'
GROUP BY mode_of_shipment_id;


SELECT b.booking_id
FROM booking b
JOIN customer_invoice_body cib ON b.booking_id = cib.booking_id
JOIN customer c ON cib.customer_id = c.id
WHERE c.id = 214598
  AND b.date_of_departure BETWEEN '2021-01-01' AND '2021-01-31';
  
  SELECT cib.invoice_id
FROM customer_invoice_body cib
JOIN customer_invoice_head cih ON cib.invoice_id = cih.invoice_id
WHERE cib.invoice_currency = 'GBP'
  AND cih.invoice_sent_date BETWEEN '2021-01-01' AND '2021-01-31'
ORDER BY cib.amount_in_invoice_currency DESC
LIMIT 10;

SELECT c.customer_name
FROM customer c
JOIN customer_invoice_body cib ON c.id = cib.customer_id
JOIN customer_invoice_head cih ON cib.invoice_id = cih.invoice_id
WHERE cih.invoice_sent_date BETWEEN '2021-01-01' AND '2021-01-31'
GROUP BY c.customer_name
HAVING COUNT(DISTINCT cih.invoice_id) > 10;


SELECT cil.leg_name, cil.amount_in_invoice_currency
FROM customer_invoice_body cib
JOIN booking b ON cib.booking_id = b.booking_id
JOIN customer c ON cib.customer_id = c.id
JOIN customer_invoice_leg cil ON cib.booking_id = cil.booking_id
WHERE c.id = 214598 
  AND b.id = (SELECT MIN(id) FROM booking WHERE customer_id = 214598);

WITH RankedCustomers AS (
    SELECT
        c.customer_name,
        c.country_name,
        SUM(cib.amount_in_invoice_currency) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(cib.amount_in_invoice_currency) DESC) AS SalesRank
    FROM
        customer_invoice_body cib
    JOIN customer_invoice_head cih ON cib.invoice_id = cih.invoice_id
    JOIN customer c ON cib.customer_id = c.id
    WHERE
        cib.invoice_currency = 'GBP'
        AND cih.invoice_sent_date BETWEEN '2021-01-01' AND '2021-01-31'
    GROUP BY
        c.customer_name, c.country_name
)

SELECT
    rc1.customer_name,
    rc1.total_sales,
    rc2.customer_name AS lag_customer_name_same_country,
    rc2.total_sales AS lag_total_sales_same_country,
    rc1.total_sales - rc2.total_sales AS difference_in_sales
FROM
    RankedCustomers rc1
LEFT JOIN RankedCustomers rc2 ON rc1.country_name = rc2.country_name AND rc1.SalesRank = rc2.SalesRank - 1
WHERE
    rc1.SalesRank <= 10;
