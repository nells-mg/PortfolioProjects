/*

 Cleaning Data in SQL Queries
 
 */

SELECT *
FROM HousingData.nashvillehousing;

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Standerdized Data Format 

-- Checking the datatype for the SaleDate column to see if I need to alter it 

SELECT * 
FROM INFORMATION_SCHEMA.COLUMNS;

-- SaleDate column = text data type (Month day, year) - I need to alter it to date (yyyy/mm/dd)

SELECT saledate, STR_TO_DATE(saledate, '%M %d, %Y') -- gives correct date
FROM HousingData.nashvillehousing;

UPDATE housingdata.nashvillehousing
SET SaleDate = STR_TO_DATE(saledate, '%M %d, %Y')
WHERE SaleDate IS NOT NULL; 

SELECT *
FROM HousingData.nashvillehousing;
   
--------------------------------------------------------------------------------------------------------------------------------------------------------
   -- Polulate Property Address data 

SELECT *
FROM HousingData.nashvillehousing
-- WHERE propertyaddress IS NULL; 
ORDER BY parcelid; 

SELECT a.parcelid, a.propertyaddress, b.parcelid, b.propertyaddress, IFNULL(a.propertyaddress, b.propertyaddress)
FROM HousingData.nashvillehousing a
JOIN HousingData.nashvillehousing b
	ON a.parcelid = b.parcelid
    AND a.uniqueid != b.uniqueid
WHERE a.propertyaddress IS NULL; 

UPDATE HousingData.nashvillehousing a
JOIN HousingData.nashvillehousing b
	ON a.parcelid = b.parcelid
    AND a.uniqueid != b.uniqueid
SET a.propertyaddress =  IFNULL(a.propertyaddress, b.propertyaddress)
WHERE a.propertyaddress IS NULL; 

-- Double checking there are no more NULLs

SELECT *
FROM HousingData.nashvillehousing
-- WHERE propertyaddress IS NULL
ORDER BY parcelid; 

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Breaking out Address into individual columns (Address, City, State) 

SELECT propertyaddress
FROM HousingData.nashvillehousing;
-- WHERE propertyaddress IS NULL; 
-- ORDER BY parcelid; 

SELECT 
substring(propertyaddress, 1, locate(',', propertyaddress)-1) AS Address 
,  substring(propertyaddress, locate(',', propertyaddress) +1, length(propertyaddress))  AS City
FROM HousingData.nashvillehousing;

ALTER TABLE HousingData.nashvillehousing
ADD PropertySplitAddress VARCHAR(255) CHARSET utf8MB4; 

UPDATE housingdata.nashvillehousing
SET PropertySplitAddress = substring(propertyaddress, 1, locate(',', propertyaddress)-1); 

SELECT * 
FROM HousingData.nashvillehousing;

ALTER TABLE nashvillehousing
ADD PropertySplitCity VARCHAR(255) CHARSET utf8MB4;

UPDATE housingdata.nashvillehousing
SET PropertySplitCity = substring(propertyaddress, locate(',', propertyaddress) +1, length(propertyaddress));

SELECT  OwnerAddress
FROM HousingData.nashvillehousing;

SELECT 
SUBSTRING_INDEX(owneraddress,',', 1) as 'Address'
, SUBSTRING_INDEX(owneraddress,',', -2) as 'City'
, SUBSTRING_INDEX(owneraddress,',', -1) as 'state'
FROM HousingData.nashvillehousing;

ALTER TABLE nashvillehousing
ADD OwnerSplitAddress VARCHAR(255) CHARSET utf8MB4;

UPDATE housingdata.nashvillehousing
SET OwnerSplitAddress = SUBSTRING_INDEX(owneraddress,',', 1); 

ALTER TABLE nashvillehousing
ADD OwnerSplitCity VARCHAR(255) CHARSET utf8MB4;

UPDATE housingdata.nashvillehousing
SET OwnerSplitCity = SUBSTRING_INDEX(owneraddress,',', -2);

ALTER TABLE nashvillehousing
ADD OwnerSplitState VARCHAR(255) CHARSET utf8MB4;

UPDATE housingdata.nashvillehousing
SET OwnerSplitState = SUBSTRING_INDEX(owneraddress,',', -1);

SELECT 
SUBSTRING_INDEX(OwnerSplitCity,',', 1) as 'City'
FROM HousingData.nashvillehousing;

ALTER TABLE nashvillehousing
ADD OwnerSplitCity1 VARCHAR(255) CHARSET utf8MB4;

UPDATE housingdata.nashvillehousing
SET OwnerSplitCity1 = SUBSTRING_INDEX(OwnerSplitCity,',', 1); 

ALTER TABLE housingdata.nashvillehousing
RENAME COLUMN OwnerSplitCity1 TO OwnerSplitCity; 


ALTER TABLE housingdata.nashvillehousing
CHANGE COLUMN OwnerSplitCity OwnerSplitCity VARCHAR(255) CHARSET utf8MB4 
AFTER OwnerSplitAddress;

--------------------------------------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field 

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM HousingData.nashvillehousing
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant
, CASE 
			WHEN SoldAsVacant = 'Y' THEN 'Yes' 
			WHEN SoldAsVacant = 'N' THEN 'No' 
			ELSE SoldAsVacant
END 
FROM HousingData.nashvillehousing;

UPDATE HousingData.nashvillehousing
SET SoldAsVacant =  CASE 
			WHEN SoldAsVacant = 'Y' THEN 'Yes' 
			WHEN SoldAsVacant = 'N' THEN 'No' 
			ELSE SoldAsVacant
END; 

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remove Duplicates 
-- Removing Duplicates by creating a Distinct Table 

CREATE TABLE HousingData.nashvillehousing_distinct LIKE HousingData.nashvillehousing;

INSERT INTO HousingData.nashvillehousing_distinct
		SELECT DISTINCT *
        FROM HousingData.nashvillehousing;
        
WITH RowNumCTE2 AS (
SELECT *,
ROW_NUMBER () OVER (
PARTITION BY ParcelID,
	 				  PropertyAddress,
					  SalePrice,
					  SaleDate,
					  LegalReference
	ORDER BY UniqueID
        )  row_num
FROM HousingData.nashvillehousing_distinct
)
SELECT *
FROM RowNumCTE2
WHERE row_num > 1; 
        
-- LOOK UP HOW TO DO THIS - STILL HASN'T WORKED 
-- Removing Duplicates by using CTE

-- WITH RowNumCTE AS (
SELECT *,
ROW_NUMBER () OVER (
PARTITION BY ParcelID,
	 				  PropertyAddress,
					  SalePrice,
					  SaleDate,
					 LegalReference
	ORDER BY UniqueID
        )  row_num
FROM HousingData.nashvillehousing
)
DELETE 
FROM RowNumCTE
WHERE row_num > 1;

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Delete unused columns 

ALTER TABLE HousingData.nashvillehousing_distinct
DROP COLUMN OwnerAddress,
DROP COLUMN TaxDistrict,
DROP COLUMN PropertyAddress;

SELECT *
FROM HousingData.nashvillehousing_distinct;

