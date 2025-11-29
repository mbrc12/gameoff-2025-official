rm -rf build
mkdir build
zip build/game.love -r .
cd build
love.js game.love game -c -t game
cd game
python3 -m http.server 8000
