Select * 
From Test_Portfolio_Covid..covid_deaths
Where continent is not NULL
order by location, date;

Select *
From Test_Portfolio_Covid..covid_vaccinations
Where continent is not NULL
order by location, date;

--Selecting the most important data from covid.deaths

Select location, date, total_cases, new_cases,total_deaths,new_deaths, total_cases_per_million, total_deaths_per_million
From Test_Portfolio_Covid..covid_deaths
Where continent is not Null
order by location, date

--Selecting the most important data from covid.vaccinations

Select location, date, total_tests, new_tests, positive_rate, tests_per_case, total_vaccinations, new_vaccinations, 
people_vaccinated, people_fully_vaccinated 
From Test_Portfolio_Covid..covid_vaccinations
Where continent is not Null
order by location, date

--Looking at total deaths vs total cases by date and location

Select location, date, total_cases, total_deaths, 
(total_deaths/total_cases)*100 as DeathPercentage
From Test_Portfolio_Covid..covid_deaths
Where continent is not Null
order by location, date

--Looking at total deaths vs total cases in Greece 

Select location, date, total_cases, total_deaths, 
(total_deaths/total_cases)*100 as DeathPercentage
From Test_Portfolio_Covid..covid_deaths
Where location = 'Greece' and continent is not Null
order by date


--Looking at total cases vs total population in Greece

Select location, date, population, total_cases,  
(total_cases/population)*100 as CasesPercentage
From Test_Portfolio_Covid..covid_deaths
Where location = 'Greece' and continent is not Null
order by location, date

--Countries with highest infection rate compared to population

Select location, max(total_cases) as HighestInfectionCount, max(total_cases/population)*100 as PercentPopulationInfected 
From Test_Portfolio_Covid..covid_deaths
Where continent is not Null
group by location, population
order by PercentPopulationInfected desc


--Countries with highest infection rate compared to population (only for countries with population between 8-12 million - similar to Greece)

Select location, max(total_cases) as HighestInfectionCount, max(total_cases/population)*100 as PercentPopulationInfected 
From Test_Portfolio_Covid..covid_deaths
Where continent is not Null and population Between 8000000 and 12000000
group by location, population
order by PercentPopulationInfected desc


--Countries with the highest death rate compared to population

Select location, max(cast (total_deaths as int)) as TotalDeathCount, max(total_deaths/population)*100 as PercentPopulationDied 
From Test_Portfolio_Covid..covid_deaths
Where continent is not Null
group by location
order by PercentPopulationDied desc


-- Total population vs vaccination

Select dea.location, dea.date, dea.population, vac.new_vaccinations
From Test_Portfolio_Covid..covid_deaths dea
Join Test_Portfolio_Covid..covid_vaccinations vac
	On dea.location = vac.location and
	dea.date = vac.date
Where dea.continent is not Null 
order by dea.location, dea.date


-- Highest people-fully-vaccinated count per country

Select dea.location,dea.population, max(convert(bigint,vac.people_fully_vaccinated)) as MaxFullyVaccinatedCount
From Test_Portfolio_Covid..covid_deaths dea
Join Test_Portfolio_Covid..covid_vaccinations vac
	On dea.location = vac.location and
	dea.date = vac.date
Where dea.continent is not Null
group by dea.location, dea.population
order by  MaxFullyVaccinatedCount desc

-- Using CTE for showing the vaccination rate per country

With CTE_FullyVaccinatedRate as 
(Select dea.location, dea.population, max(convert(bigint,vac.people_fully_vaccinated)) as MaxFullyVaccinatedCount
From Test_Portfolio_Covid..covid_deaths dea
Join Test_Portfolio_Covid..covid_vaccinations vac
	On dea.location = vac.location and
	dea.date = vac.date
Where dea.continent is not Null
group by dea.location, dea.population)
--order by  MaxFullyVaccinatedCount desc)

Select *, (MaxFullyVaccinatedCount/population)*100 as FullyVaccinatedRate 
From CTE_FullyVaccinatedRate
Where (MaxFullyVaccinatedCount/population)*100 < 100
order by FullyVaccinatedRate desc



-- Using Temp table for showing the vaccination rate per country

Drop Table #FullyVaccinatedRate
Create Table #FullyVaccinatedRate
(location nvarchar(255),
population numeric,
MaxFullyVaccinatedCount numeric)

Insert into #FullyVaccinatedRate
Select dea.location, dea.population, max(convert(bigint,vac.people_fully_vaccinated)) as MaxFullyVaccinatedCount
From Test_Portfolio_Covid..covid_deaths dea
Join Test_Portfolio_Covid..covid_vaccinations vac
	On dea.location = vac.location and
	dea.date = vac.date
Where dea.continent is not Null
group by dea.location, dea.population

Select *, (MaxFullyVaccinatedCount/population)*100
From #FullyVaccinatedRate
Where (MaxFullyVaccinatedCount/population)*100 < 100
Order by (MaxFullyVaccinatedCount/population)*100 desc


-- Create View of people fully vaccinated rate per country


Create view FullyVaccinatedRate as
Select dea.location, dea.population, max(convert(bigint,vac.people_fully_vaccinated)) as MaxFullyVaccinatedCount
From Test_Portfolio_Covid..covid_deaths dea
Join Test_Portfolio_Covid..covid_vaccinations vac
	On dea.location = vac.location and
	dea.date = vac.date
Where dea.continent is not Null
group by dea.location, dea.population

Select *, (MaxFullyVaccinatedCount/population)*100
From FullyVaccinatedRate


--Doing the same as above but now by progressively adding the new vaccinations each day to get total vaccinations

Select dea.continent, dea.location, dea.date,dea.population, vac.new_vaccinations, 
sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From Test_Portfolio_Covid..covid_deaths dea
Join Test_Portfolio_Covid..covid_vaccinations vac
	On dea.location = vac.location and
		dea.date = vac.date
Where dea.continent is not NULL
Order by dea.location, dea.date


-- Creating CTE

With CTE_RollingVaccination as ( 
Select dea.continent, dea.location, dea.date,dea.population, vac.new_vaccinations, 
sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From Test_Portfolio_Covid..covid_deaths dea
Join Test_Portfolio_Covid..covid_vaccinations vac
	On dea.location = vac.location and
		dea.date = vac.date
Where dea.continent is not NULL
)

Select *, (RollingPeopleVaccinated/population)*100 as RollingPeopleVaccinatedRate
From CTE_RollingVaccination


-- Creating Temp Table

Drop Table #RollingVaccination
Create Table #RollingVaccination (
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric)

Insert into #RollingVaccination
Select dea.continent, dea.location, dea.date,dea.population, vac.new_vaccinations, 
sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From Test_Portfolio_Covid..covid_deaths dea
Join Test_Portfolio_Covid..covid_vaccinations vac
	On dea.location = vac.location and
		dea.date = vac.date
Where dea.continent is not NULL

Select *, (RollingPeopleVaccinated/population)*100 as RollingPeopleVaccinatedRate
From #RollingVaccination
Order by location, date

-- Creating the respective view

Create View RollingPeopleVaccinatedRate as
Select dea.continent, dea.location, dea.date,dea.population, vac.new_vaccinations, 
sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From Test_Portfolio_Covid..covid_deaths dea
Join Test_Portfolio_Covid..covid_vaccinations vac
	On dea.location = vac.location and
		dea.date = vac.date
Where dea.continent is not NULL

Select * 
From RollingPeopleVaccinatedRate

--Showing some Global numbers

   --Total cases and total deaths each day from case 1 until 09.08.2022

   Select date, sum(new_cases) as Total_cases, sum(cast(new_deaths as int)) as Total_deaths, 
   (sum(cast(new_deaths as int))/sum(new_cases))*100 as DeathPercentage
   From Test_Portfolio_Covid..covid_deaths
   Where continent is not NULL
   Group by date
   Order by 1,2

   --Total cases and total deaths in 09.08.2022

   Select sum(new_cases) as Total_cases, sum(cast(new_deaths as int)) as Total_deaths, 
   (sum(cast(new_deaths as int))/sum(new_cases))*100 as DeathPercentage
   From Test_Portfolio_Covid..covid_deaths
   Where continent is not NULL
   

--Creating some more views

--Deaths Percentage by date and location

Create View DeathPercentageDayLocation as
Select location, date, total_cases, total_deaths, 
(total_deaths/total_cases)*100 as DeathPercentage
From Test_Portfolio_Covid..covid_deaths
Where continent is not Null
--order by location, date


-- Deaths Percentage by date in Greece

Create View DeathPercentageDayGreece as
Select location, date, total_cases, total_deaths, 
(total_deaths/total_cases)*100 as DeathPercentage
From Test_Portfolio_Covid..covid_deaths
Where location = 'Greece' and continent is not Null
--order by date

--Total cases vs total population in Greece

Create View CasesvsPopGreece as
Select location, date, population, total_cases,  
(total_cases/population)*100 as CasesPercentage
From Test_Portfolio_Covid..covid_deaths
Where location = 'Greece' and continent is not Null
--order by location, date


--Countries with the highest death rate compared to population

Create View HighestDeathRatevsPop as
Select location, max(cast (total_deaths as int)) as TotalDeathCount, max(total_deaths/population)*100 as PercentPopulationDied 
From Test_Portfolio_Covid..covid_deaths
Where continent is not Null
group by location
--order by PercentPopulationDied desc

-- Total population vs vaccination

Create View PopvsVac as
Select dea.location, dea.date, dea.population, vac.new_vaccinations
From Test_Portfolio_Covid..covid_deaths dea
Join Test_Portfolio_Covid..covid_vaccinations vac
	On dea.location = vac.location and
	dea.date = vac.date
Where dea.continent is not Null 
--order by dea.location, dea.date