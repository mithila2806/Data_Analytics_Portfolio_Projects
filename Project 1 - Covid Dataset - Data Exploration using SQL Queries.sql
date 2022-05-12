
--Covid 19 Data Exploration 
--Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

-- Viewing the CovidDeaths Dataset
select * 
FROM [Portfolio Project].dbo.CovidDeaths
order by 3,4

-- Viewing the CovidVaccinations Dataset
select * 
FROM [Portfolio Project].dbo.CovidVaccinations
order by 3,4

-- Select Data that we are going to be starting with and organise the selected data based on 
-- location and date

Select Location, date, total_cases, new_cases, total_deaths, population
From [Portfolio Project].dbo.CovidDeaths
--Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying (in the form of percentage) if people do contract covid in the UK 
-- Worked out the calculation for Death Percentage
Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From [Portfolio Project].dbo.CovidDeaths
Where location like '%United Kingdom%'
and continent is not null 
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid in the UK

Select Location, date, Population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
From [Portfolio Project].dbo.CovidDeaths
Where location like '%United Kingdom%'
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select 
Location, 
Population, 
MAX(total_cases) as HighestInfectionCount,  
MAX((total_cases/population))*100 as PercentPopulationInfected
From  [Portfolio Project].dbo.CovidDeaths
--Where location like '%United%'
GROUP BY
Location,
population
order by 4 desc
--order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population
-- Resolved an error on ORDER BY clause when the alias TotalDealthCount was used in order by. 
-- Fix: Used MAX(Total_deaths) instead of using the alias.
-- Learning: You can't use alias in ORDER BY Clause.
Select Location, 
MAX(Total_deaths) as TotalDealthCount
From [Portfolio Project].dbo.CovidDeaths
Where continent is not null 
Group by Location
--order by TotalDealthCount
order by MAX(Total_deaths) desc

-- TotalDeathCount results seem to be incorrect. Hence, looked at the data type of total_deaths 
-- column in the table and it's nvarchar.
-- So, we need to cast this to int to get the correct results.
-- This also resolved the error in order by clause when I was using the alis 'TotalDealthCount'. 

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From [Portfolio Project].dbo.CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc
--order by TotalDeathCount desc

-- BREAKING THINGS DOWN BY CONTINENT
-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From [Portfolio Project].dbo.CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc


-- GLOBAL NUMBERS

Select
--date,
SUM(new_cases) as total_cases, 
SUM(cast(new_deaths as int)) as total_deaths, 
SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From [Portfolio Project].dbo.CovidDeaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

------------------------------------------JOINS-------------------------------------------

-- View Vaccinations Dataset

select * 
from
[Portfolio Project].dbo.CovidDeaths dea
Join
[Portfolio Project].dbo.CovidVaccinations vac
  on dea.location = vac.location
  and dea.date = dea.date

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
Select 
dea.continent, 
dea.location, 
dea.date, 
dea.population, 
vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations as int)) OVER 
(Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [Portfolio Project].dbo.CovidDeaths dea
Join [Portfolio Project].dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

-------------------------------CTE----------------------------------------------------
-- Using CTE to perform Calculation on Partition By in previous query
With PopvsVac (
Continent, 
Location, 
Date, 
Population, 
New_Vaccinations, 
RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [Portfolio Project].dbo.CovidDeaths dea
Join [Portfolio Project].dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac


-- Temp Table
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select 
dea.continent, 
dea.location, 
dea.date, 
dea.population, 
vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations as int)) OVER 
(Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [Portfolio Project].dbo.CovidDeaths dea
Join [Portfolio Project].dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [Portfolio Project].dbo.CovidDeaths dea
Join [Portfolio Project].dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

-- View the View
SELECT * FROM PercentPopulationVaccinated
