use music_database;

--1. Who is the senior most employee based on job title? 
select top (1) last_name,first_name,title,levels from employee 
order by levels desc;


--2. Which countries have the most Invoices? 
select count(billing_country),billing_country from invoice
group by billing_country 
order by count(billing_country) desc;


--3. What are top 3 values of total invoice? 
select top (3) total from invoice order by total desc;


/*4. Which city has the best customers? We would like to throw a promotional Music 
Festival in the city we made the most money. Write a query that returns one city that 
has the highest sum of invoice totals. Return both the city name & sum of all invoice 
totals*/
select top(1) sum(total),city from customer
inner join invoice on customer.customer_id=invoice.customer_id
group by city
order by sum(total) desc;



/*5. Who is the best customer? The customer who has spent the most money will be 
declared the best customer. Write a query that returns the person who has spent the 
most money*/
select top(1) customer.customer_id,customer.first_name,customer.last_name, sum(invoice.total) as total from customer
join invoice on customer.customer_id=invoice.customer_id
group by customer.customer_id,customer.first_name, customer.last_name
order by total desc;



/*1. Write query to return the email, first name, last name, & Genre of all Rock Music 
listeners. Return your list ordered alphabetically by email starting with A */
select distinct customer.email,customer.first_name,customer.last_name from 
customer join invoice on customer.customer_id=invoice.customer_id
join invoice_line on invoice.invoice_id=invoice_line.invoice_id
join track on track.track_id=invoice_line.track_id
join genre on genre.genre_id=track.genre_id
where genre.name = 'Rock'
order by email;

select distinct customer.email,customer.first_name,customer.last_name from customer
join invoice on customer.customer_id=invoice.customer_id
join invoice_line on invoice.invoice_id=invoice_line.invoice_id
where track_id in(select track_id from track 
                  join genre on genre.genre_id=track.genre_id
				  where genre.name = 'Rock')
order by email;


SELECT distinct
    c.Email,
    c.First_Name,
    c.Last_Name
FROM 
    Customer c
JOIN 
    Invoice i ON c.Customer_Id = i.Customer_Id
JOIN 
    (
        SELECT 
            il.Invoice_Id,
            t.Genre_Id
        FROM 
            Invoice_Line il
        JOIN 
            Track t ON il.Track_Id = t.Track_Id
        JOIN 
            Genre g ON t.Genre_Id = g.Genre_Id
        WHERE 
            g.Name = 'Rock'
    ) rock_tracks ON i.Invoice_Id = rock_tracks.Invoice_Id
JOIN 
    Genre g ON rock_tracks.Genre_Id = g.Genre_Id
ORDER BY 
    c.Email;




/*2. Let's invite the artists who have written the most rock music in our dataset. Write a 
query that returns the Artist name and total track count of the top 10 rock bands */

select top(10) count(track.name) as total_track_count, artist.name from artist
join album on artist.artist_id=album.artist_id
join track on track.album_id=album.album_id
join genre on genre.genre_id=track.genre_id
where genre.name = 'Rock'
group by artist.name
order by count(track.name) desc;



/*3. Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the 
longest songs listed first */

select name,milliseconds from track where milliseconds > (select avg(milliseconds) from track)
order by milliseconds;


/*1. Find how much amount spent by each customer on artists? Write a query to return 
customer name, artist name and total spent */
WITH best_selling_artist AS (
    SELECT TOP 1 
        a.artist_id, 
        a.name AS artist_name, 
        SUM(il.unit_price * il.quantity) AS total_sales
    FROM invoice_line il
    JOIN track t ON t.track_id = il.track_id
    JOIN album al ON al.album_id = t.album_id
    JOIN artist a ON a.artist_id = al.artist_id
    GROUP BY a.artist_id, a.name
    ORDER BY total_sales DESC
)
SELECT 
    c.customer_id, 
    c.first_name, 
    c.last_name, 
    bsa.artist_name, 
    SUM(il.unit_price * il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album al ON al.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = al.artist_id
GROUP BY 
    c.customer_id, 
    c.first_name, 
    c.last_name, 
    bsa.artist_name
ORDER BY amount_spent DESC;

--OR

SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    a.name AS artist_name,
    SUM(il.unit_price * il.quantity) AS amount_spent
FROM invoice_line il
JOIN invoice i ON il.invoice_id = i.invoice_id
JOIN customer c ON i.customer_id = c.customer_id
JOIN track t ON il.track_id = t.track_id
JOIN album al ON t.album_id = al.album_id
JOIN artist a ON al.artist_id = a.artist_id
WHERE a.artist_id = (
    SELECT TOP 1
        a2.artist_id
    FROM invoice_line il2
    JOIN track t2 ON il2.track_id = t2.track_id
    JOIN album al2 ON t2.album_id = al2.album_id
    JOIN artist a2 ON al2.artist_id = a2.artist_id
    GROUP BY a2.artist_id
    ORDER BY SUM(il2.unit_price * il2.quantity) DESC
)
GROUP BY 
    c.customer_id,
    c.first_name,
    c.last_name,
    a.name
ORDER BY amount_spent DESC;



/*2. We want to find out the most popular music Genre for each country. We determine the 
most popular genre as the genre with the highest amount of purchases. Write a query 
that returns each country along with the top Genre. For countries where the maximum 
number of purchases is shared return all Genres */ 
WITH popular_genre AS 
(
    SELECT 
        COUNT(il.quantity) AS purchases, 
        c.country, 
        g.name AS genre_name, 
        g.genre_id,
        ROW_NUMBER() OVER (
            PARTITION BY c.country 
            ORDER BY COUNT(il.quantity) DESC
        ) AS RowNo 
    FROM invoice_line il
    JOIN invoice i ON il.invoice_id = i.invoice_id
    JOIN customer c ON c.customer_id = i.customer_id
    JOIN track t ON t.track_id = il.track_id
    JOIN genre g ON g.genre_id = t.genre_id
    GROUP BY c.country, g.name, g.genre_id
)
SELECT 
    country,
    genre_name,
    genre_id,
    purchases
FROM popular_genre
WHERE RowNo = 1
ORDER BY country;



/*3. Write a query that determines the customer that has spent the most on music for each 
country. Write a query that returns the country along with the top customer and how 
much they spent. For countries where the top amount spent is shared, provide all 
customers who spent this amount */

WITH Customer_with_country AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        i.billing_country,
        SUM(i.total) AS total_spending,
        ROW_NUMBER() OVER (
            PARTITION BY i.billing_country 
            ORDER BY SUM(i.total) DESC
        ) AS RowNo
    FROM invoice i
    JOIN customer c ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, i.billing_country
)
SELECT 
    customer_id,
    first_name,
    last_name,
    billing_country,
    total_spending
FROM Customer_with_country
WHERE RowNo = 1
ORDER BY billing_country;


