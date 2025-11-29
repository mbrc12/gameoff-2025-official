rm -rf build
cd ~/dev/ext/love-web-builder
rm -rf build
mkdir build
python3 build.py ~/dev/gameoff-25 build -m 128000000
cd build
echo "Starting web server on http://localhost:8001"
python3 -m http.server 8001
