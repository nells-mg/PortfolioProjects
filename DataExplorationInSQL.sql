SELECT *
FROM Covid.coviddeaths
WHERE continent IS NOT NULL 
ORDER BY 3,4;  

-- SELECT *
-- FROM Covid.covidvaccinations
-- ORDER BY 3,4;  

SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM Covid.coviddeaths
WHERE continent IS NOT NULL 
ORDER BY 1,2;

-- Looking at Total Cases Vs Total Deaths 
-- Shows the likelihood of dying if you contract Covid by location

-- SELECT location, date, total_cases, total_deaths
-- (CONVERT(float, total_deaths)) / NULLIF(CONVERT(float, total_cases), 0))*100 AS Deathpercentage
-- FROM Covid.coviddeaths
-- ORDER BY 1,2

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage 
FROM Covid.coviddeaths
-- WHERE location LIKE "%United States%"
ORDER BY 1,2;

-- Looking at Total Cases Vs Population 
-- Shows what percentage of population got Covid 

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM Covid.coviddeaths
-- WHERE location LIKE "%United States%"
ORDER BY 1,2;

-- Looking at Countries with Highest Infection Rate Vs Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM Covid.coviddeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- Showing countries with highest death count per population 

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM Covid.coviddeaths
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Breaking it down by continent 
-- Showing continents with the highest deat count per poopulation

SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM Covid.coviddeaths
WHERE continent IS NOT NULL 
GROUP BY continent 
ORDER BY TotalDeathCount DESC;

-- Global Numbers 

SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM Covid.coviddeaths
WHERE continent IS NOT NULL 
GROUP BY date 
ORDER BY 1,2; 

-- Removing date 

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM Covid.coviddeaths
WHERE continent IS NOT NULL 
-- GROUP BY date 
ORDER BY 1,2; 

-- Looking at Total Population Vs. Vaccination 

SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
,SUM(new_vaccinations) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/
FROM Covid.coviddeaths CD
JOIN Covid.covidvaccinations CV
	ON CD.location = CV.location 
    AND CD.date = CV.date 
WHERE CD.continent IS NOT NULL 
ORDER BY 2,3;

-- Use CTE - Make sure number of columns is the same as CTE if not = error 

WITH PopulationvsVaccination (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS 
(
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
,SUM(new_vaccinations) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/
FROM Covid.coviddeaths CD
JOIN Covid.covidvaccinations CV
	ON CD.location = CV.location 
    AND CD.date = CV.date 
WHERE CD.continent IS NOT NULL 
-- ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopulationvsVaccination 

-- Temp Table 
-- DROP TABLE NOT WORKING - BUT VERY HELPFUL ONCE IT WORKS 

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255), Location nvarchar(255), Date datetime, Population numeric, New_Vaccinations numeric, RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
,SUM(new_vaccinations) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/
FROM Covid.coviddeaths CD
JOIN Covid.covidvaccinations CV
	ON CD.location = CV.location 
    AND CD.date = CV.date
-- WHERE CD.continent IS NOT NULL 
-- ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated


-- Creating views to store data for later visualizations 

-- PercentPopulationVaccinated

CREATE VIEW PercentPopulationVaccinated AS 
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
,SUM(new_vaccinations) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/Population)*100
FROM Covid.coviddeaths CD
JOIN Covid.covidvaccinations CV
	ON CD.location = CV.location 
    AND CD.date = CV.date 
WHERE CD.continent IS NOT NULL
-- ORDER BY 2,3

SELECT * 
FROM PercentPopulationVaccinated

-- PercentPopulationInfected 

CREATE VIEW PercentPopulationInfected AS 
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM Covid.coviddeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

SELECT *
FROM PercentPopulationInfected

-- TotalDeathCount

CREATE VIEW TotalDeathCount AS
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM Covid.coviddeaths
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY TotalDeathCount DESC;


