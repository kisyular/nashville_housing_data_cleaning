/*
DATA CLEANING IN SQL
*/


DROP TABLE IF EXISTS NashvilleHousingOriginalData;

/*
Lets create a table called NashvilleHousing. This will simplify importing of the data from CSV
*/
CREATE TABLE NashvilleHousingOriginalData
(
    UniqueID        INT,
    ParcelID        VARCHAR(MAX),
    LandUse         VARCHAR(MAX),
    PropertyAddress VARCHAR(MAX),
    SaleDate        VARCHAR(MAX),
    SalePrice       VARCHAR(MAX),
    LegalReference  VARCHAR(MAX),
    SoldAsVacant    VARCHAR(MAX),
    OwnerName       VARCHAR(MAX),
    OwnerAddress    VARCHAR(MAX),
    Acreage         float,
    TaxDistrict     VARCHAR(MAX),
    LandValue       INT,
    BuildingValue   INT,
    TotalValue      INT,
    YearBuilt       INT,
    Bedrooms        INT,
    FullBath        INT,
    HalfBath        INT
)

/*
Lets import the data from CSV. Use the file system to import the data
*/

-- Show the data
SELECT *
FROM NashvilleHousingOriginalData;


-- Lets copy the data to a new table
SELECT *
INTO NashvilleHousing
FROM NashvilleHousingOriginalData;

-- Standardize Date Format
SELECT SaleDate, CONVERT(Date, SaleDate) as SaleDateConverted
FROM NashvilleHousing;

UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate);

-- Check if the date format is converted
SELECT SaleDate
FROM NashvilleHousing;

-- Populate Property Address Data
-- Show the data where property address is null
SELECT *
FROM NashvilleHousing
WHERE PropertyAddress IS NULL;

-- Perform a join to show the data where the property address is null
-- ISNULL function is used to replace NULL values with a specified replacement value.
SELECT a.ParcelID,
       a.PropertyAddress,
       b.ParcelID  AS ParcelID_b,
       b.PropertyAddress AS PropertyAddress_b,
       ISNULL(a.PropertyAddress, b.PropertyAddress) AS UpdatedPropertyAddress
FROM NashvilleHousing a
         JOIN NashvilleHousing b
              ON a.ParcelID = b.ParcelID
                  AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

-- Update the property address where the property address is null

-- We will use the NashvilleHousing (new table) table to update the property address where the property address is null
-- Lets update the property address where the property address is null
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
-- ISNULL(a.PropertyAddress, b.PropertyAddress) is used to select the PropertyAddress from table 'a', and if it's NULL,
-- it takes the value from the corresponding row in table 'b'. This way, it populates NULL values in 'a' with non-NULL
-- values from 'b'. It acts as a coalesce function for NULL values.
FROM NashvilleHousing a
         JOIN NashvilleHousing b
              ON a.ParcelID = b.ParcelID
                  AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;


-- Check if the data is updated
SELECT TOP (15) *
FROM NashvilleHousing;


-- Breaking out Address into Individual Columns (Address, City, State)
-- Lets use the SUBSTRING function to extract the address from the PropertyAddress column
SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)                    AS Address,
       SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM NashvilleHousing;


-- Lets add the columns to the table
ALTER TABLE NashvilleHousing
    ADD PropertySplitAddress VARCHAR(MAX);

ALTER TABLE NashvilleHousing
    ADD PropertySplitCity VARCHAR(MAX);

-- Lets update the table
UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(', ', PropertyAddress) - 1);

-- The SUBSTRING function is used to extract a substring from a string.
-- The SUBSTRING function takes three arguments:
-- The string to extract the substring from.
-- The starting index of the substring.
-- The length of the substring.

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(', ', PropertyAddress) + 1, LEN(PropertyAddress));

-- Check if the data is updated
SELECT TOP (10) UniqueID, PropertyAddress, PropertySplitAddress, PropertySplitCity
FROM NashvilleHousing;

-- Breaking out Owner Address into Individual Columns (Address, City, State)
-- Lets use the PARSENAME function to extract the address from the OwnerAddress column
SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)  AS OwnerSplitAddress,
       PARSENAME(REPLACE(OwnerAddress, ', ', '.'), 2) AS OwnerSplitCity,
       PARSENAME(REPLACE(OwnerAddress, ', ', '.'), 1) AS OwnerSplitState
FROM NashvilleHousing
WHERE OwnerAddress IS NOT NULL;

-- Lets add the columns to the table
ALTER TABLE NashvilleHousing
    ADD OwnerSplitAddress VARCHAR(MAX),
        OwnerSplitCity VARCHAR(MAX),
        OwnerSplitState VARCHAR(MAX);

-- Lets update the table
UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ', ', '.'), 3),
    OwnerSplitCity    = PARSENAME(REPLACE(OwnerAddress, ', ', '.'), 2),
    OwnerSplitState   = PARSENAME(REPLACE(OwnerAddress, ', ', '.'), 1);

-- Check if the data is updated
SELECT TOP (10) UniqueID,
                OwnerAddress,
                OwnerSplitCity,
                OwnerSplitState,
                OwnerSplitAddress
FROM NashvilleHousing
WHERE OwnerAddress IS NOT NULL;


-- Change Y and N to Yes and No in "Sold as Vacant" field
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2;


-- Lets use CASE statement to change Y and N to Yes and No in "Sold as Vacant" field
SELECT SoldAsVacant,
       CASE
           WHEN SoldAsVacant = 'Y' THEN 'Yes'
           WHEN SoldAsVacant = 'N' THEN 'No'
           ELSE SoldAsVacant
           END
FROM NashvilleHousing
WHERE SoldAsVacant IN ('Y', 'N');


-- Lets update the table
UPDATE NashvilleHousing
SET SoldAsVacant = CASE
                       WHEN SoldAsVacant = 'Y' THEN 'Yes'
                       WHEN SoldAsVacant = 'N' THEN 'No'
                       ELSE SoldAsVacant
    END
WHERE SoldAsVacant IN ('Y', 'N');

-- Check if the data is updated
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2;


-- Lets CONVERT the SalePrice to Numeric
-- Lets find the values which are not numeric
SELECT UniqueID,
       SalePrice,
       'Conversion Error' AS ConversionStatus
FROM NashvilleHousing
WHERE TRY_CONVERT(NUMERIC(18, 2), REPLACE(SalePrice, '$', '')) IS NULL;

-- Create a view to show the rows where the SalePrice is not numeric
CREATE VIEW ConversionError
AS
SELECT UniqueID,
       SalePrice,
       'Conversion Error' AS ConversionStatus
FROM NashvilleHousing
WHERE TRY_CONVERT(NUMERIC(18, 2), REPLACE(SalePrice, '$', '')) IS NULL;


-- We can see the rows where the SalePrice is not numeric. They have a comma, or the '$'.
-- Lets replace the comma and $ with a blank space
SELECT UniqueID, SalePrice, REPLACE(REPLACE(SalePrice, ',', ''), '$', '') AS SalePriceNumeric
FROM NashvilleHousing
WHERE TRY_CONVERT(NUMERIC(18, 2), REPLACE(SalePrice, '$', '')) IS NULL;

-- Lets update the table
UPDATE NashvilleHousing
SET SalePrice = REPLACE(REPLACE(SalePrice, ',', ''), '$', '')
WHERE UniqueID in (SELECT UniqueID FROM ConversionError);

-- Lets see if the conversion is successful
SELECT UniqueID, SalePrice
FROM NashvilleHousing
WHERE UniqueID IN (SELECT UniqueID FROM ConversionError);

-- Alter table and column SalePrice to Numeric
ALTER TABLE NashvilleHousing
    ALTER COLUMN SalePrice NUMERIC(18, 2);

-- Check if the data is updated
SELECT TOP (20) UniqueID, SalePrice
FROM NashvilleHousing
WHERE UniqueID IN (SELECT UniqueID FROM ConversionError);


-- Remove Duplicates
DROP VIEW IF EXISTS DuplicatesView;
/*
This view, DuplicatesView, identifies duplicate records in the NashvilleHousing table based on specific columns. It
uses a Common Table Expression (CTE) with ROW_NUMBER() to assign row numbers within partitions defined by ParcelID,
PropertyAddress, SalePrice, SaleDate, and LegalReference. Rows with row_num greater than 1 are duplicates.
*/
CREATE VIEW DuplicatesView AS
WITH RowNumCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY ParcelID,
               PropertyAddress,
               SalePrice,
               SaleDate,
               LegalReference
               ORDER BY UniqueID
           ) AS row_num
    FROM NashvilleHousing
)
SELECT
    UniqueID,
    ParcelID,
    PropertyAddress,
    SalePrice,
    SaleDate,
    LegalReference,
    row_num
FROM
    RowNumCTE
WHERE
    row_num > 1;

-- Lets use the view to find the duplicates
SELECT *
FROM DuplicatesView;



-- We can use View now to delete the duplicates
DELETE
FROM NashvilleHousing
WHERE UniqueID IN (SELECT UniqueID FROM DuplicatesView);


-- Check if the data is updated
WITH RowNumCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY ParcelID,
               PropertyAddress,
               SalePrice,
               SaleDate,
               LegalReference
               ORDER BY UniqueID
           ) AS row_num
    FROM NashvilleHousing
)
SELECT
    UniqueID,
    ParcelID,
    PropertyAddress,
    SalePrice,
    SaleDate,
    LegalReference,
    row_num
FROM
    RowNumCTE
WHERE
    row_num > 1;

-- Delete Unused Columns
-- Lets drop the columns we dont need
ALTER TABLE NashvilleHousing
    DROP COLUMN PropertyAddress,
        OwnerAddress,
        SaleDate,
        TaxDistrict;

-- Check if the columns are deleted
SELECT data_type, column_name
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'NashvilleHousing';













