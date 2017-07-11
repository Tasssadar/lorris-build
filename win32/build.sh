docker build -t lorris-build-win32 . && docker run -t -v $(pwd)/lorris-release:/lorris-release lorris-build-win32
