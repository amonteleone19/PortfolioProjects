--Cleaning Data with SQL Queries

Select * From [Port_Proj.v4]..NashvilleHousing

--Standardize Date format -- current "Saledate" is YYYY-MM-DD XX:XX:XX.XXX
--I want to set it as YYY-MM-DD so I will add a new column and assign it this converted date

Select Saledate, CONVERT(Date, Saledate)
From [Port_Proj.v4]..NashvilleHousing

ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
Set SaleDateConverted = CONVERT(Date, Saledate)

Select Saledate, SaleDateConverted
From [Port_Proj.v4]..NashvilleHousing

--Successfully added SaleDateConverted with YYYY-MM-DD Format

-------------------------------------
--Populate Property Address data - Currently 29 null in "PropertyAddress"
--Upon scouring the data, I found that one "Parcel ID" (Referring to a land parcels)
--has multiple entries - some of those entries have "PropertyAddress" and some don't!
--I found I can copy the "PropertyAddress" from a successfully filled in entry of the same ParcelID
Select PropertyAddress
From [Port_Proj.v4]..NashvilleHousing
where PropertyAddress is null

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
From [Port_Proj.v4]..NashvilleHousing a
JOIN [Port_Proj.v4]..NashvilleHousing b
	on a.ParcelID = b.ParcelID AND a.[uniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null
--This table shows a parcel ID, a null PropertyAddress, then a matching parcelID, then a non-null PropertyAddress!

--ISNULL creates an extra entity ready to replace PropertyAddress
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.propertyaddress, b.propertyaddress)
From [Port_Proj.v4]..NashvilleHousing a
JOIN [Port_Proj.v4]..NashvilleHousing b
	on a.ParcelID = b.ParcelID AND a.[uniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

--Updating the table
Update a
Set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From [Port_Proj.v4]..NashvilleHousing a
JOIN [Port_Proj.v4]..NashvilleHousing b
	on a.ParcelID = b.ParcelID AND a.[uniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

--And if this query returns empty.. Success!
Select propertyaddress
From [Port_Proj.v4]..NashvilleHousing
where propertyaddress is null

--Breaking out address into individual columns (Address, City)
--Sample "propertyaddress" value: 928 SILKWOOD CIR, NASHVILLE
--I'd like to seperate that into different columns!
Select propertyaddress
From [Port_Proj.v4]..NashvilleHousing

--This following command returns the address up to (not including) the first comma
--and then the city starting 1 space *after* the comma
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) -1) as Address,
SUBSTRING(PropertyAddress, Charindex(',', PropertyAddress) + 1, len(propertyaddress)) as City
From [Port_Proj.v4]..NashvilleHousing

--Creating two new columns
ALTER TABLE NashvilleHousing
Add PropertySplitAddress nvarchar(255);

Update NashvilleHousing
Set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) -1)

ALTER TABLE NashvilleHousing
Add PropertySplitCity nvarchar(255);

Update NashvilleHousing
Set PropertySplitCity = SUBSTRING(PropertyAddress, Charindex(',', PropertyAddress) + 1, len(propertyaddress))

--Scrolling at the way to the right shows our two new columns!
Select *
FROM [Port_Proj.v4]..NashvilleHousing

-----------------------------------------
--Doing the same for "OwnerAddress" with PARSENAME
--PARSENAME looks for "." - So I will have to replace commas with periods!

Select OwnerAddress
FROM [Port_Proj.v4]..NashvilleHousing

Select
PARSENAME(REPLACE(OwnerAddress, ',' , '.') ,3) as OwnerStreetName,
PARSENAME(REPLACE(OwnerAddress, ',' , '.') ,2) as OwnerCity,
PARSENAME(REPLACE(OwnerAddress, ',' , '.') ,1) as OwnerState
FROM [Port_Proj.v4]..NashvilleHousing
--Now to add 3 new columns and populate
ALTER TABLE NashvilleHousing
Add OwnerSplitAddress nvarchar(255);

ALTER TABLE NashvilleHousing
Add OwnerSplitCity nvarchar(255);

ALTER TABLE NashvilleHousing
Add OwnerSplitState nvarchar(255);

Update NashvilleHousing
Set OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',' , '.') ,3)

Update NashvilleHousing
Set OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',' , '.') ,2)

Update NashvilleHousing
Set OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',' , '.') ,1)

select *
FROM [Port_Proj.v4]..NashvilleHousing
--3 New columns, correctly split up!

----------------------------------------------------
--Change Y & N to Yes & No in "SoldAsVacant" field
--This first query shows there are 4 options in "SoldAsVacant": "Y","Yes","N","No
Select Distinct(SoldAsVacant), count(SoldAsVacant)
FROM [Port_Proj.v4]..NashvilleHousing
Group by SoldAsVacant
order by 2
--Using Cases allows easy changes
Select SoldAsVacant,
CASE When SoldAsVacant = 'Y' THEN 'Yes'
	 When SoldAsVacant = 'N' THEN 'No'
	 Else SoldAsVacant
	 END
FROM [Port_Proj.v4]..NashvilleHousing

Update NashvilleHousing
SET SoldAsVacant = Case When SoldAsVacant = 'Y' THEN 'Yes'
	When SoldAsVacant = 'N' Then 'No'
	Else SoldAsVacant
	END
--Running the first query again shows only "Yes"and "No" in the SoldAsVacant column!
Select Distinct(SoldAsVacant), count(SoldAsVacant)
FROM [Port_Proj.v4]..NashvilleHousing
Group by SoldAsVacant
order by 2

--------------------------------
--Remove Duplicates
--While I would normally place removed data in a temp table for safekeeping, in this example I will just delete the data
--For this I created a CTE and used Row_number to identify duplicate rows and delete them
WITH RowNumCTE As(
Select *,
	Row_number() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num
FROM [Port_Proj.v4]..NashvilleHousing
)
DELETE
From RowNumCTE
where row_num >1
----------------------------------
--Delete Unused Columns
--Again, I would normally place these in a temp table, but for this example I will just delete them

Alter table [Port_Proj.v4]..NashvilleHousing
Drop Column OwnerAddress, TaxDistrict, PropertyAddress

--Done!
--Thank you for browsing! Please reach out at monteleone.anton@gmail.com if you would like to discuss!










