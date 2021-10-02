Select *
From [Port_Proj.v4]..CovidDeaths
where continent is not null
order by 3,4

--Select *
From [Port_Proj.v4]..CovidVaccinations
where continent is not null
order by 3,4

--Select data that we are going to be using

--Select Location, date, total_cases, new_cases, total_deaths, population
From [Port_Proj.v4]..CovidDeaths
where continent is not null
order by 1,2

-- Looking at total cases vs total deaths
--Shows likliehood of dying if you contract covid in your country
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From [Port_Proj.v4]..CovidDeaths
where location like '%states%'
order by 1,2

-- Looking at total cases vs population
--Shows what percentage of population got covid
Select Location, date, population, total_cases, (total_cases/population)*100 as CovidPercentage
From [Port_Proj.v4]..CovidDeaths
where location like '%states%'
order by 1,2

-- Looking at countries with highest infection rate compared to population

Select Location, population, max(total_cases) as HighestInfectionCount, max((total_cases/population))*100 as PercentPopulationInfected
From [Port_Proj.v4]..CovidDeaths
--where location like '%states%'
Group by location, population
order by PercentPopulationInfected desc


--Let's break things down by continent

-- Showing countries with highest death count per population
-- Need to cast "TotalDeathCount" as an int
Select Location, Max(cast(Total_deaths as int)) as TotalDeathCount
From [Port_Proj.v4]..CovidDeaths
--where location like '%states%'
where continent is not null
Group by location
order by TotalDeathCount desc

--Let's break things down by continent

Select location, Max(cast(Total_deaths as int)) as TotalDeathCount
From [Port_Proj.v4]..CovidDeaths
--where location like '%states%'
where continent is null
Group by location
order by TotalDeathCount desc

--Showing continents with highest death count per population
Select continent, Max(cast(Total_deaths as int)) as TotalDeathCount
From [Port_Proj.v4]..CovidDeaths
--where location like '%states%'
where continent is not null
Group by continent
order by TotalDeathCount desc

-- Global Numbers
-- Total cases, deaths, and Death Percentage per day across the world
Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_Cases) * 100 as Death_Percentage
From [Port_Proj.v4]..CovidDeaths
where continent is not null
Group by date
order by 1,2

-- Total cases, total deaths, total death percentage
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_Cases) * 100 as Death_Percentage
From [Port_Proj.v4]..CovidDeaths
where continent is not null
order by 1,2

-- Looking at total population vs vaccinations
--Use CTE

With PopvsVac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, Sum(cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [Port_Proj.v4]..CovidDeaths dea
Join [Port_Proj.v4]..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac



-- Temp Table
Drop Table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, Sum(cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [Port_Proj.v4]..CovidDeaths dea
Join [Port_Proj.v4]..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
--order by 2,3

Select *, (RollingPeopleVaccinated/Population) * 100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualization

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, Sum(cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [Port_Proj.v4]..CovidDeaths dea
Join [Port_Proj.v4]..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3