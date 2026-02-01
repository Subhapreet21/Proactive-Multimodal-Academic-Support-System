$baseUrl = "http://zeal360.co.in/360/mallareddyuniversity2/"

# Create directories
New-Item -ItemType Directory -Force -Path "assets/tour"
New-Item -ItemType Directory -Force -Path "assets/tour/MallaReddyUniversitydata"
New-Item -ItemType Directory -Force -Path "assets/tour/MallaReddyUniversitydata/lib"
New-Item -ItemType Directory -Force -Path "assets/tour/MallaReddyUniversitydata/graphics"

# Main Files
Invoke-WebRequest -Uri "$baseUrl/mallareddyuniversity.html" -OutFile "assets/tour/index.html"
Invoke-WebRequest -Uri "$baseUrl/MallaReddyUniversitydata/MallaReddyUniversity.js" -OutFile "assets/tour/MallaReddyUniversitydata/MallaReddyUniversity.js"
Invoke-WebRequest -Uri "$baseUrl/MallaReddyUniversitydata/MallaReddyUniversity.xml" -OutFile "assets/tour/MallaReddyUniversitydata/MallaReddyUniversity.xml"
Invoke-WebRequest -Uri "$baseUrl/MallaReddyUniversitydata/MallaReddyUniversity_vr.xml" -OutFile "assets/tour/MallaReddyUniversitydata/MallaReddyUniversity_vr.xml"

# Libs (jQuery, Kolor, etc.)
$libs = @(
    "jquery-2.1.1.min.js",
    "jquery-1.11.1.min.js",
    "jquery-ui-1.11.1/jquery-ui.min.css",
    "jquery-ui-1.11.1/jquery-ui.min.js",
    "jquery.ui.touch-punch.min.js",
    "Kolor/KolorTools.min.js"
)

foreach ($lib in $libs) {
    $targetPath = "assets/tour/MallaReddyUniversitydata/lib/$lib"
    $parentDir = Split-Path $targetPath -Parent
    if (!(Test-Path $parentDir)) { New-Item -ItemType Directory -Force -Path $parentDir }
    
    try {
        Invoke-WebRequest -Uri "$baseUrl/MallaReddyUniversitydata/lib/$lib" -OutFile $targetPath
    } catch {
        Write-Host "Failed to download $lib"
    }
}

# Graphics
$graphics = @(
    "KolorBootstrap.js",
    "cursors_move_html5.cur",
    "cursors_drag_html5.cur"
)

foreach ($g in $graphics) {
    Invoke-WebRequest -Uri "$baseUrl/MallaReddyUniversitydata/graphics/$g" -OutFile "assets/tour/MallaReddyUniversitydata/graphics/$g"
}

Write-Host "Download Complete. NOTE: This script does NOT download the thousands of image tiles (panoramas). Doing that via script without a list is hard. I recommend testing with just the UI loading first."
