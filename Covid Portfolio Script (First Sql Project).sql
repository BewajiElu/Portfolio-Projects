use PortoflioProject

select * from ..CovidDeaths$
WHERE continent is not null
order by 3,4

--select * from ..CovidVaccinations$
--order by 3,4

-- Total Cases  Vs Total Death
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
from ..CovidDeaths$
where location like '%Nigeria%'
order by 1,2

-- Total Cases Vs Population

select location, date, total_cases, population, (total_cases/population)*100 as PopulationInfected
from ..CovidDeaths$
where location like '%Nigeria%'
order by 1,2

-- Country with highest infection rate
select location, population, MAX(total_cases) as HInfectionCount, MAX((total_cases/population))*100 
as PopulationInfectedCountry
From PortoflioProject..CovidDeaths$ 
Group by population, location
order by PopulationInfectedCountry Desc

select location, population, date, MAX(total_cases) as HInfectionCount, MAX((total_cases/population))*100 
as PopulationInfectedCountry
From PortoflioProject..CovidDeaths$ 
Group by population, location, date
order by PopulationInfectedCountry Desc


-- Highest Death Count
select location, MAX(cast(total_deaths as int)) as HDeathCount
From PortoflioProject..CovidDeaths$ 
Where continent is not null
Group by location
order by HDeathCount Desc

--Description by continent

select continent, MAX(cast(total_deaths as int)) as HDeathCount
From PortoflioProject..CovidDeaths$ 
Where continent is not null
Group by continent
order by HDeathCount Desc

use PortoflioProject

--GLOBAL NUMBERS 

select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
SUM(cast(new_deaths as int))/ SUM(new_cases)*100 as Death_Percentage
from ..CovidDeaths$
where continent is not null
--group by date
order by 1,2

Select * from CovidDeaths$ CD
Join CovidVaccinations$ CV 
On CD.location = CV.location
and CD.date = Cv.date


select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
SUM(CONVERT(int, CV.new_vaccinations)) OVER (partition by CD.location order by CD.location, CD.date) as rollovercount
 from CovidDeaths$ CD
Join CovidVaccinations$ CV 
On CD.location = CV.location
and CD.date = Cv.date
where CD.continent is not null
order by 2,3

            --CTE 
 with POPvsVAC (continent, location, date, population, new_vaccinations, rollovercount)
 AS (select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
SUM(CONVERT(int, CV.new_vaccinations)) OVER (partition by CD.location order by CD.location, CD.date) as rollovercount
 from CovidDeaths$ CD
Join CovidVaccinations$ CV 
On CD.location = CV.location
and CD.date = Cv.date
where CD.continent is not null)
select *, (rollovercount/population)*100
from POPvsVAC


 WITH POPvsVAC (location, population, new_vaccinations, rollovercount)
 AS (
   SELECT CD.location, CD.population, CV.new_vaccinations,
   SUM(CONVERT(decimal(18,2), CV.new_vaccinations)) OVER (PARTITION BY CD.location ORDER BY CD.location) as rollovercount
   FROM CovidDeaths$ CD
   JOIN CovidVaccinations$ CV 
   ON CD.location = CV.location
   WHERE CD.continent IS NOT NULL
)
SELECT location, population, new_vaccinations, rollovercount, CONVERT(decimal(18,2), MAX(rollovercount/population)*100) as max_pct
FROM POPvsVAC
GROUP BY location, population, new_vaccinations, rollovercount;


-- Temp Table 
Drop Table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
	 continent nvarchar(260), loaction nvarchar(260), date datetime, 
	 population numeric, new_vaccinations numeric, rollovercount numeric)

Insert into #PercentPopulationVaccinated
select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
SUM(CONVERT(int, CV.new_vaccinations)) OVER (partition by CD.location order by CD.location, CD.date) as rollovercount
 from CovidDeaths$ CD
Join CovidVaccinations$ CV 
On CD.location = CV.location
and CD.date = Cv.date
--where CD.continent is not null)
select *, (rollovercount/population)*100
from #PercentPopulationVaccinated

Drop Table if exists #MaxPopulationVac
create table #MaxPopulationVac
(location nvarchar(260), population numeric, new_vaccinations numeric, rollovercount numeric)

Insert into #MaxPopulationVac
 SELECT CD.location, CD.population, CV.new_vaccinations,
   SUM(CONVERT(decimal(18,2), CV.new_vaccinations)) OVER (PARTITION BY CD.location ORDER BY CD.location) as rollovercount
   FROM CovidDeaths$ CD
   JOIN CovidVaccinations$ CV 
   ON CD.location = CV.location
  -- WHERE CD.continent IS NOT NULL
--SELECT location, population, new_vaccinations, rollovercount, CONVERT(decimal(18,2), MAX(rollovercount/population)*100) as max_pct
select *,CONVERT(decimal(18,2), MAX(rollovercount/population)*100) as max_pct
from #MaxPopulationVac
GROUP BY location, population, new_vaccinations, rollovercount;

-- Data Visualized in Tableau 


  create view TotalDeathCounts as
  select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
SUM(cast(new_deaths as int))/ SUM(new_cases)*100 as Death_Percentage
from ..CovidDeaths$
where continent is not null
group by date
--order by 1,2


create view SumTotalDeath as
select location, SUM(cast(new_deaths as int)) as SumTotalDeath
From PortoflioProject..CovidDeaths$ 
Where continent is null
and location not in ('World', 'European Union', 'International')
Group by location
--order by SumTotalDeath Desc

Create view PercentPopulationInfected as 
select location, population, MAX(total_cases) as HInfectionCount, MAX((total_cases/population))*100 
as PopulationInfectedCountry
From PortoflioProject..CovidDeaths$ 
Group by population, location
--order by PopulationInfectedCountry Desc

Create view HighestInfectionCount as
select location, population, date, MAX(total_cases) as HInfectionCount, MAX((total_cases/population))*100 
as PopulationInfectedCountry
From PortoflioProject..CovidDeaths$ 
Group by population, location, date
--order by PopulationInfectedCountry Desc

Create view TotalVacCount as 
select location, SUM(cast(total_vaccinations as decimal(18,2))) as SumTotalVac
From PortoflioProject..CovidVaccinations$
Where continent is null
and location not in ('World', 'European Union', 'International')
Group by location
