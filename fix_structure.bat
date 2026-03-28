@echo off
echo ==========================================
echo       FIXING FLUTTER FOLDER STRUCTURE
echo       (Updated for Phase 5: Profile)
echo ==========================================

:: 1. Create ALL required folders (including the new profile folder)
if not exist "lib\features\auth\screens" mkdir "lib\features\auth\screens"
if not exist "lib\features\auth\providers" mkdir "lib\features\auth\providers"
if not exist "lib\features\home\screens" mkdir "lib\features\home\screens"

if not exist "lib\features\blog\models" mkdir "lib\features\blog\models"
if not exist "lib\features\blog\providers" mkdir "lib\features\blog\providers"
if not exist "lib\features\blog\screens" mkdir "lib\features\blog\screens"
if not exist "lib\features\blog\widgets" mkdir "lib\features\blog\widgets"

:: NEW: Create the Profile folder
if not exist "lib\features\profile\screens" mkdir "lib\features\profile\screens"

:: 2. MOVE AUTH FILES (Phase 1 Fixes)
if exist "lib\features\home\screens\screens\login_screen.dart" move "lib\features\home\screens\screens\login_screen.dart" "lib\features\auth\screens\"
if exist "lib\features\home\screens\login_screen.dart" move "lib\features\home\screens\login_screen.dart" "lib\features\auth\screens\"
if exist "lib\features\home\screens\screens\signup_screen.dart" move "lib\features\home\screens\screens\signup_screen.dart" "lib\features\auth\screens\"
if exist "lib\features\home\screens\signup_screen.dart" move "lib\features\home\screens\signup_screen.dart" "lib\features\auth\screens\"

:: 3. MOVE HOME SCREEN (Phase 1 Fixes)
if exist "lib\features\home\screens\screens\home_screen.dart" move "lib\features\home\screens\screens\home_screen.dart" "lib\features\home\screens\"
if exist "lib\features\auth\screens\home_screen.dart" move "lib\features\auth\screens\home_screen.dart" "lib\features\home\screens\"

:: 4. MOVE MAIN LAYOUT (Phase 5 Fix - Moves it from 'blog' to 'home')
if exist "lib\features\blog\screens\main_layout.dart" move "lib\features\blog\screens\main_layout.dart" "lib\features\home\screens\"

:: 5. CLEAN UP (Delete empty/wrong folders)
if exist "lib\features\home\screens\screens" rmdir "lib\features\home\screens\screens" 2>nul
if exist "lib\features\auth\presentation" rmdir /s /q "lib\features\auth\presentation" 2>nul
if exist "lib\features\home\presentation" rmdir /s /q "lib\features\home\presentation" 2>nul

echo.
echo ==========================================
echo       DONE! FILE LOCATIONS FIXED.
echo ==========================================
echo.
echo ------------------------------------------
echo IMPORTANT NEXT STEP:
echo ------------------------------------------
echo 1. Check your VS Code sidebar.
echo 2. Go to lib/features/profile/screens/
echo 3. Create a new file named: profile_screen.dart
echo 4. Paste the Profile Screen code inside it!
echo.
pause