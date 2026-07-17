@echo off
echo ============================================
echo  EduMarket Backend - Firewall Setup
echo ============================================
echo.
echo Adding firewall rule for port 5001...
netsh advfirewall firewall add rule name="EduMarket Backend Port 5001" dir=in action=allow protocol=TCP localport=5001
echo.
echo Done! Your phone can now reach the backend over Wi-Fi.
echo No more "Unable to connect" errors!
echo.
pause
