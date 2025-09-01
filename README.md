# Windows Only

# Uses a pre-existing Amplitube 5 at5p preset file as the base, where Amp A is a Tonex Model (used as placeholder), this can be edited to your liking, but AMP A must ALWAYS be a TONEX model (unless you know how to edit scripts here)

1. Download and install (default settings) SQLiteStudio -> https://sqlitestudio.pl/

2. go to C:\Users\[YOUR USERNAME]\Documents\IK Multimedia\TONEX

3. Backup "Library.db" just in case, then Right click "Library.db" Open With:
 
4. Choose another app -> More Apps -> Scroll all the way down -> Look for another app on this PC

5. Go to C:\Program Files\SQLiteStudio then choose SQLiteStudio.exe

6. SQLiteStudio opens, on the file menu, go to Tools > Open Configuration Dialogue

7. Highlight "Data Browsing" on left hand selection 

8. Change "Number of data rows per page" to high number like 2000 or more depending how much presets you have

9. Press Apply, Ok. Left hand side Databases panel, Expand "Library", expand "Tables" 

10. Right click "Presets" table, Export the table -> Export table data checked only -> NEXT

11. Export Format: CSV, output file with filename Presets.csv case sensitive with UTF-8 encoding to same folder with script

12. Check "Column names in first row" with column seperator set to , (comma)

13. Press Finish. Do the same to ToneModels table, name it ToneModels.csv case sensitive, save into same folder with script

14. 2 files, Generate-At5p_Uncategorized.ps1 exports all presets into 1 output folder

15. Generate-At5p_Categorized.ps1 exports presets into subfolders and categorizes by the Model Name

16. Right click your preferred, then "Run With Powershell", you'll see a new folder with generated presets

17. copy presets to C:\Users\[YOUR USERNAME]\Documents\IK Multimedia\AmpliTube 5\Presets

If you KNOW what you are doing, the Powershell scripts can be edited for high customization. This is just a starter script
and nothing further advanced. 
