# SASS Watch Script
# Kompiliert SASS automatisch bei Änderungen

#!/bin/bash

echo "Starting SASS watch mode..."
echo "Compiling main.scss → main.css"
echo "Press Ctrl+C to stop"
echo ""

sass --watch resources/sass/main.scss:resources/css/main.css --style expanded --source-map
