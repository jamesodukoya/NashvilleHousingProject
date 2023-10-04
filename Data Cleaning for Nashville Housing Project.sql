SELECT
	*
FROM
	NashvilleHousingProject..NashvilleHousing

--Change sale date format
ALTER TABLE
	NashvilleHousing
ADD
	NewSaleDate date

UPDATE
	NashvilleHousing
SET
	NewSaleDate = CONVERT(Date, SaleDate)

SELECT
	NewSaleDate
FROM
	NashvilleHousingProject..NashvilleHousing

--Populate property address column where empty
--Using the logic that all properties with a particular ParcelID have the same PropertyAddress
UPDATE
	first
SET
	first.PropertyAddress = second.PropertyAddress
FROM
	NashvilleHousingProject..NashvilleHousing first
	JOIN
		NashvilleHousingProject..NashvilleHousing second
		ON
			first.ParcelID = second.ParcelID
		AND
			first.[UniqueID ] <> second.[UniqueID ]
WHERE
	first.PropertyAddress IS NULL

--Check for NULL values in our updated table
SELECT
	PropertyAddress
FROM
	NashvilleHousingProject..NashvilleHousing
WHERE
	PropertyAddress IS NULL

--Break PropertyAddress column into separate Address, City, and State columns
ALTER TABLE
	NashvilleHousing
ADD
	Address nvarchar(255)
	, City nvarchar(255)
	, State nvarchar(255)

UPDATE
	NashvilleHousing
SET
	Address = SUBSTRING (PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)
	, City = SUBSTRING (PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))
	, State = 'TN'

ALTER TABLE
	NashvilleHousing
DROP COLUMN
	PropertyAddress

SELECT
	Address
	, City
	, State
FROM
	NashvilleHousing

--Break OwnerAddress column into separate OwnerAdd, OwnerCity, and OwnerState columns
ALTER TABLE
	NashvilleHousing
ADD
	OwnerAdd nvarchar (255)
	, OwnerCity nvarchar (50)
	, OwnerState nvarchar (50)

UPDATE
	NashvilleHousing
SET
	OwnerAdd = PARSENAME(REPLACE(OwnerAddress,',','.'),3)
	, OwnerCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)
	, OwnerState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

SELECT
	OwnerAdd
	, OwnerCity
	,OwnerState
FROM
	NashvilleHousing

--Set uniform (only two distinct) values for the SoldAsVacant column
UPDATE
	NashvilleHousing
SET
	SoldAsVacant = 'Yes'
WHERE
	SoldAsVacant = 'Y'

UPDATE
	NashvilleHousing
SET
	SoldAsVacant = 'No'
WHERE
	SoldAsVacant = 'N'

SELECT
	DISTINCT (SoldAsVacant)
FROM
	NashvilleHousing

---Method 2: Use CASE Statement
UPDATE
	NashvilleHousing
SET
	SoldAsVacant = CASE
		WHEN SoldAsVacant = 'No' THEN 'N'
		WHEN SoldAsVacant = 'Yes' THEN 'Y'
		ELSE SoldAsVacant
	END

SELECT
	DISTINCT (SoldAsVacant)
FROM
	NashvilleHousing

--Remove duplicates
;WITH
	NashvilleCTE
AS
(
SELECT
	*
	, ROW_NUMBER()
		OVER (
			PARTITION BY 
				ParcelID
				, Address
				, SaleDate
				, OwnerName
				, LegalReference 
					ORDER BY
						UniqueID
				) row_num
FROM
	NashvilleHousing
)

DELETE FROM
	NashvilleCTE
WHERE
	row_num > 1

--Create a new table with only the columns we want
CREATE TABLE
	NashvilleHousingClean
		(
		UniqueID Numeric
		, ParcelID nvarchar(255)
		, SaleDate date
		, SalePrice Numeric
		, SoldAsVacant nvarchar(50)
		, OwnerName nvarchar(255)
		, OwnerAddress nvarchar(255)
		, OwnerCity nvarchar(255)
		, OwnerState nvarchar(255)
		)

INSERT INTO
	NashvilleHousingClean
SELECT
	UniqueID
	, ParcelID
	, SaleDate
	, SalePrice
	, SoldAsVacant
	, OwnerName
	, OwnerAdd
	, OwnerCity
	, OwnerState
FROM
	NashvilleHousing

SELECT
	*
FROM
	NashvilleHousingClean