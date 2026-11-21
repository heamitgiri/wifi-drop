@echo off
echo ========================================================
echo   Starting 5-Device Local Simulation Mesh
echo   (Laptop 1, Laptop 2, Laptop 3, Phone 1, Phone 2)
echo ========================================================

start "WiFi Drop - Laptop 1" py -3 p2p_engine.py --name "Laptop 1" --type laptop --port 8765
timeout /t 1 >nul
start "WiFi Drop - Laptop 2" py -3 p2p_engine.py --name "Laptop 2" --type laptop --port 8767
timeout /t 1 >nul
start "WiFi Drop - Laptop 3" py -3 p2p_engine.py --name "Laptop 3" --type laptop --port 8768
timeout /t 1 >nul
start "WiFi Drop - Phone 1" py -3 p2p_engine.py --name "Phone 1" --type phone --port 8769
timeout /t 1 >nul
start "WiFi Drop - Phone 2" py -3 p2p_engine.py --name "Phone 2" --type phone --port 8770

echo All 5 nodes started!
echo Open http://127.0.0.1:8765 to view Laptop 1 (will show the other 4 peers on radar)
echo Open http://127.0.0.1:8767 to view Laptop 2
echo Open http://127.0.0.1:8769 to view Phone 1
