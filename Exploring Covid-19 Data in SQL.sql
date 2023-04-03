/*
Covid-19 Data exploration
Skills used: Joins, CTE's, Temp Tables, Windows Function,Aggregate Functions, Creating Views, Converting Data Types
*/
--------------------------------------------------------------------------------------------------------------------------


Select *
From PortfolioProject	..CovidDeaths
Where continent is not null
Order by 3,4

Select *
From PortfolioProject	..CovidVaccinations
Where continent is not null
Order by 3,4


-- Select Data that we are going to be starting with


Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject	..CovidDeaths
Where continent is not null
Order by 1,2


--------------------------------------------------------------------------------------------------------------------------

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
From PortfolioProject	..CovidDeaths
where location = 'India'
Order by 1,2


--------------------------------------------------------------------------------------------------------------------------

-- Total Cases vs Population
-- Shows what percentage of population got infected by Covid

Select Location, date, Population, total_cases, (total_cases/Population)*100 as Population_Infected
From PortfolioProject	..CovidDeaths
--where location = 'India'
Order by 1,2


--------------------------------------------------------------------------------------------------------------------------

-- Countries with Highest Infection Rate compared to Population

Select Location, Population, Max(total_cases) as Highest_Infection_Count, Max((total_cases/Population))*100 as Percent_Population_Infected
From PortfolioProject	..CovidDeaths
--where location = 'India'
Group by Location, Population
Order by Percent_Population_Infected desc


--------------------------------------------------------------------------------------------------------------------------

-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as Total_Death_Count
From PortfolioProject	..CovidDeaths
--where location = 'India'
where continent is not null
Group by Location
Order by Total_Death_Count desc


--------------------------------------------------------------------------------------------------------------------------

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as Total_Death_Count
From PortfolioProject	..CovidDeaths
--where location = 'India'
where continent is not null
Group by continent
Order by Total_Death_Count desc


--------------------------------------------------------------------------------------------------------------------------

-- GLOBAL NUMBERS

Select date, Sum(new_cases) as Total_Cases, Sum(Cast(new_deaths as int)) as Total_Deaths,
					Sum(Cast(new_deaths as int))/Sum(new_cases)*100 as Death_Percentage
From PortfolioProject	..CovidDeaths
--where location = 'India'
where continent is not null
Group by date
Order by 1,2


--------------------------------------------------------------------------------------------------------------------------

-- Joining both the tables

Select *
From Portfolioproject..CovidDeaths as dea
join PortfolioProject..CovidVaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date


--------------------------------------------------------------------------------------------------------------------------

-- Looking at Total Population vs New Vaccinations per day


Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From Portfolioproject..CovidDeaths as dea
join PortfolioProject..CovidVaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
	and dea.location = 'India'
Order by 2,3


--------------------------------------------------------------------------------------------------------------------------

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	Sum(Convert(int, vac.new_vaccinations)) 
	OVER (partition by dea.location order by dea.location, dea.date) as Rolling_People_Vaccinated
From Portfolioproject..CovidDeaths as dea
join PortfolioProject..CovidVaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
	--and dea.location = 'India'
Order by 2,3 desc


--------------------------------------------------------------------------------------------------------------------------

-- Using CTE to perform Calculation on Partition By in previous query
		
with Pop_vs_Vac (continent, location, date, population, new_vaccinations, Rolling_People_Vaccinated)
as 
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	Sum(Convert(int, vac.new_vaccinations)) 
	OVER (partition by dea.location order by dea.location, dea.date) as Rolling_People_Vaccinated
From Portfolioproject..CovidDeaths as dea
join PortfolioProject..CovidVaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
	--and dea.location = 'India'
--Order by 2,3 desc
)

select *, (Rolling_People_Vaccinated/population)*100 as Percentage_of_Population_Vaccinated
From Pop_vs_Vac
Order by 2,3 desc


--------------------------------------------------------------------------------------------------------------------------

-- Using Temp Table to perform Calculation on Partition By in previous query

Drop Table if exists #PercentageofPopulationVaccinated
Create Table #PercentageofPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
Rolling_People_Vaccinated numeric,
)


Insert into #PercentageofPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	Sum(Convert(int, vac.new_vaccinations)) 
	OVER (partition by dea.location order by dea.location, dea.date) as Rolling_People_Vaccinated
From Portfolioproject..CovidDeaths as dea
join PortfolioProject..CovidVaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
	--and dea.location = 'India'
--Order by 2,3 desc

select *, (Rolling_People_Vaccinated/population)*100 as Per_of_Population_Vaccinated
From #PercentageofPopulationVaccinated
Order by 2,3 desc


--------------------------------------------------------------------------------------------------------------------------

-- Creating View to store data for later visualizations

Create View PercentageofPopulationVaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	Sum(Convert(int, vac.new_vaccinations)) 
	OVER (partition by dea.location order by dea.location, dea.date) as Rolling_People_Vaccinated
From Portfolioproject..CovidDeaths as dea
join PortfolioProject..CovidVaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
	and dea.location = 'India'
--Order by 2,3 desc