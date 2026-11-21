#!/usr/bin/env bash
echo "Starting 5-device simulation mesh..."
python3 p2p_engine.py --name "Laptop 1" --type laptop --port 8765 &
PID1=$!
python3 p2p_engine.py --name "Laptop 2" --type laptop --port 8767 &
PID2=$!
python3 p2p_engine.py --name "Laptop 3" --type laptop --port 8768 &
PID3=$!
python3 p2p_engine.py --name "Phone 1" --type phone --port 8769 &
PID4=$!
python3 p2p_engine.py --name "Phone 2" --type phone --port 8770 &
PID5=$!

echo "Nodes started with PIDs: $PID1 $PID2 $PID3 $PID4 $PID5"
echo "Open http://127.0.0.1:8765 to view Laptop 1 (it will show the other 4 peers on the blue radar)"
echo "Press Ctrl+C to terminate all nodes."

trap "kill $PID1 $PID2 $PID3 $PID4 $PID5" SIGINT SIGTERM EXIT
wait
