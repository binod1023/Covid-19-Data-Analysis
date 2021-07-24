--Update blank value of continet column to Null values
UPDATE covid_death SET 
continent = NULLIF(continent, '')

UPDATE covid_vaccination SET 
continent = NULLIF(continent, '')



SELECT location, date, total_cases, new_cases,total_deaths, population
FROM covid_death
Order by 1,2

-- looking at Total Cases Vs Total Death
-- likelihood of dying if you have covid
SELECT location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as death_percent
FROM covid_death
Order by 1,2

--Death Percent in USA
SELECT location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as death_percent
FROM covid_death
WHERE location like '%states%'
Order by 1,2

--looking at Total Cases Vs Population
-- Shows what percent of Population got covid
SELECT location, date, total_cases, population,(total_cases/population)*100 as infected_population_percent
FROM covid_death
WHERE continent IS NOT Null AND location NOT IN ('World', 'Europe', 'South America', 'North America', 'Asia', 'European Union')
Order by 1,2

--infection rate in United States
SELECT location, date, total_cases, population,(total_cases/population)*100 as covid_percent
FROM covid_death
WHERE location like '%states%'
Order by 1,2

--Shows countries with highest infection rate with population
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population))*100 as infected_population_percent
FROM covid_death
WHERE continent IS NOT Null AND location NOT IN ('World', 'Europe', 'South America', 'North America', 'Asia', 'European Union')
GROUP BY location, population
ORDER BY infected_population_percent DESC

--Shows Highest Death Count per Population
SELECT location, MAX(CAST(total_deaths as INT)) as highest_death_count
FROM covid_death
WHERE continent IS NOT Null AND location NOT IN ('World', 'Europe', 'South America', 'North America', 'Asia', 'European Union')
GROUP BY location, population
ORDER BY highest_death_count DESC

--Let's break by continents
-- Highest Death Count by continent
SELECT location, MAX(CAST(total_deaths as INT)) as highest_death_count
FROM covid_death
WHERE continent IS Null
GROUP BY location
ORDER BY highest_death_count DESC

SELECT continent, MAX(CAST(total_deaths as INT)) as highest_death_count
FROM covid_death
WHERE continent is NOT Null AND NOT location='World'
GROUP BY continent
ORDER BY highest_death_count DESC

--GLOBAL NUMBERS
SELECT date, SUM(new_cases) as total_cases,SUM(CAST(new_deaths AS INT)) as total_death,SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 
as death_percent
FROM covid_death
WHERE continent is NOT NULL
GROUP BY date
ORDER BY 1,2

--total death percent in the world
SELECT SUM(new_cases) as total_cases,SUM(CAST(new_deaths AS INT)) as total_death,SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 
as death_percent
FROM covid_death
WHERE continent is NOT NULL
ORDER BY 1,2

--Positive rate and total tests with date and location
SELECT date, location, positive_rate, total_testS
FROM covid_vaccination
WHERE continent IS NOT NULL
ORDER BY positive_rate DESC

SELECT *
FROM covid_death

--new cases percent and new death percent
WITH new_cases_info(continent,location,date,population,new_cases, new_deaths,rolling_new_cases, rolling_new_deaths)
as 
(
SELECT continent,location,date, population, new_cases,new_deaths, 
SUM(CAST(new_cases as float)) OVER (partition by location ORDER BY location,date) as rolling_new_cases, 
SUM(CAST(new_deaths as float))OVER (partition by location ORDER BY location,date) as rolling_new_deaths
FROM covid_death
WHERE continent is NOT NULL
)
SELECT *,rolling_new_cases/population*100 as new_cases_percent, rolling_new_deaths/population*100 as new_death_percent
FROM new_cases_info

-- total population Vs vaccination 
SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations
FROM covid_death dea
JOIN covid_vaccination vacc
on dea.location=vacc.location
and dea.date=vacc.date
WHERE dea.continent is NOT NULL
ORDER BY 2,3

-- total population Vs vaccination 
WITH pop_vacc(continent,location,date,population,new_vaccinations, rolling_people_vaccinated)
as 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations,SUM(CAST(vacc.new_vaccinations as float))
OVER (partition by dea.location ORDER BY dea.location, dea.date) as rolling_people_vaccinated
FROM covid_death dea
JOIN covid_vaccination vacc
on dea.location=vacc.location
and dea.date=vacc.date
WHERE dea.continent is NOT NULL
)
SELECT *,rolling_people_vaccinated/population*100
FROM pop_vacc

--TEMP TABLE
DROP TABLE if exists percent_people_vaccinated
CREATE TABLE percent_people_vaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Rolling_people_vaccinated numeric
)

INSERT INTO percent_people_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations, SUM(CAST(vacc.new_vaccinations as float))
OVER (partition by dea.location ORDER BY dea.location, dea.date) as rolling_people_vaccinated
FROM covid_death dea
JOIN covid_vaccination vacc
on dea.location=vacc.location
and dea.date=vacc.date
--WHERE dea.continent is NOT NULL

SELECT *
FROM percent_people_vaccinated

--Create View
CREATE VIEW rolling_people_vaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations,SUM(CAST(vacc.new_vaccinations as float))
OVER (partition by dea.location ORDER BY dea.location, dea.date) as rolling_people_vaccinated
FROM covid_death dea
JOIN covid_vaccination vacc
on dea.location=vacc.location
and dea.date=vacc.date
WHERE dea.continent is NOT NULL