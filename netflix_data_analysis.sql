
CREATE TABLE netflix
(
    show_id      VARCHAR(10),
    type         VARCHAR(50),
    title        VARCHAR(300),
    director     VARCHAR(600),
    casts        VARCHAR(1200),
    country      VARCHAR(600),
    date_added   VARCHAR(100),
    release_year INT,
    rating       VARCHAR(100),
    duration     VARCHAR(50),
    listed_in    VARCHAR(300),
    description  VARCHAR(1000)
);

select * from netflix;

select count(*) as total_rows 
from netflix;

select distinct type
from netflix;

-- --------------------------------------------------------------------------

-- 1. Count the number of Movies vs TV Shows

select type, count(show_id) total
from netflix
group by type;


-- 2. Find the most common rating for movies and TV shows

with type_rating as
(select type, rating, count(*) as total_rating, 
dense_rank() over(partition by type order by count(*) desc) as rnk
from netflix
group by type, rating)

select type, rating, total_rating
from type_rating
where rnk = 1;


-- 3. List all movies released in a specific year (e.g., 2020)

select title
from netflix
where release_year = '2020' and type = 'Movie';


-- 4. Find the top 5 countries with the most content on Netflix

select country, count(*) as total_content
from netflix
group by country
order by count(*) desc;

-- 5. Identify the longest movies

select title, duration
from netflix
where duration = (select max(duration) 
					from netflix 
                    where type = 'Movie');
                    
                    
-- 6. Find content added in the last 5 years
with conv_str_date as
(select show_id,type, title, str_to_date(date_added, '%M %d, %Y') as str_date
from netflix)
select *
from conv_str_date
where str_date >= current_date - interval 5 year;


-- 7. Find all the movies/TV shows by director 'Rajiv Chilaka'

select type, title
from netflix
where director like '%Rajiv Chilaka%';


-- 8. List all TV shows with more than 5 seasons

select title, duration
from netflix
where type = 'TV Show' and duration > '5 Seasons';


-- 9. Count the number of content items in each genre

with recursive genre_split as (
  -- Select the initial values and positions
  select show_id, 
         TRIM(SUBSTRING_INDEX(listed_in, ',', 1)) as new_genre,
         SUBSTRING_INDEX(listed_in, ',', -1) as remaining_genre,
         1 as part
  from netflix

  union all

  -- Recursively split the remaining parts
  select show_id,
         TRIM(SUBSTRING_INDEX(remaining_genre, ',', 1)) as new_genre,
         SUBSTRING_INDEX(remaining_genre, ',', -1) as remaining_genre,
         part + 1
  from genre_split
  where remaining_genre like '%,%'
),

genre_split_output as
(select show_id, new_genre 
from genre_split
where new_genre != '')

select new_genre, count(show_id) as num_of_content
from genre_split_output
group by new_genre;



-- 10.Find each year and the average numbers of content release in India on netflix.
-- return top 5 year with highest avg content release!

with contents_per_year as
(select release_year, count(show_id) as num_of_content
from netflix
where country like '%India%'
group by release_year)

select release_year, avg(num_of_content) as average_content
from contents_per_year
group by release_year
order by avg(num_of_content) desc
limit 5;



-- 11. List all movies that are documentaries

select title
from netflix
where type = 'Movie' and listed_in like '%Documentaries%';



-- 12. Find all content without a director

select title, director
from netflix
where director is null;



-- 13. Find how many movies actor 'Salman Khan' appeared in last 10 years!

with casting as 
(select cast, show_id, str_to_date(date_added, '%M %d, %Y') as new_date
from netflix
where cast like '%Salman Khan%' and type = 'Movie')

select *
from casting
where new_date >= current_date - interval 10 year;



-- 14. Find the top 10 actors who have appeared in the highest number of movies produced in India.

select cast, count(show_id) as num_of_movies
from netflix
where country like '%India%'
group by cast;



-- 15. Categorize the content based on the presence of the keywords 'kill' and 'violence' in 
-- the description field. Label content containing these keywords as 'Bad' and all other 
-- content as 'Good'. Count how many items fall into each category.

with category_type as
(select type, show_id, 
case when description like '%kill%' or description like '%violence%' then 'Bad'
else 'Good' end as category
from netflix)

select category, type, count(show_id) as num_of_content
from category_type
group by category, type;

