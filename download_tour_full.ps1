
$baseUrl = "http://zeal360.co.in/360/mallareddyuniversity2/MallaReddyUniversitydata"

# List of scenes extracted from XML (partial list focusing on Mobile/Low ReS first)
$scenes = @(
    "_01__university___fro_220",
    "_01__vc_chamber_228",
    "_02__board_room_229",
    "_01__admission_wing_232",
    "_02__administration_w_579",
    "_01__class_room_236",
    "_04__aerial_view_495",
    "_02__campus_view___1_221",
    "_03__campus_view___2_222"
)

# Download function
function Download-File {
    param ($RemotePath, $LocalPath)
    $parentDir = Split-Path $LocalPath -Parent
    if (!(Test-Path $parentDir)) { New-Item -ItemType Directory -Force -Path $parentDir | Out-Null }
    
    try {
        # Check if file exists to avoid redownload
        if (!(Test-Path $LocalPath)) {
            Write-Host "Downloading $RemotePath..."
            Invoke-WebRequest -Uri $RemotePath -OutFile $LocalPath
        }
    } catch {
        Write-Host "Errors downloading $RemotePath: $_"
    }
}

foreach ($scene in $scenes) {
    # 1. Preview & Thumbnails
    Download-File "$baseUrl/$scene/preview.jpg" "assets/tour/MallaReddyUniversitydata/$scene/preview.jpg"
    Download-File "$baseUrl/$scene/thumbnail.jpg" "assets/tour/MallaReddyUniversitydata/$scene/thumbnail.jpg"

    # 2. Mobile Tiles (Fallback for all devices without WebGL or if we force mobile mode)
    # The XML structure for mobile is: mobile/0.jpg to mobile/5.jpg (Cube faces)
    for ($i = 0; $i -le 5; $i++) {
        Download-File "$baseUrl/$scene/mobile/$i.jpg" "assets/tour/MallaReddyUniversitydata/$scene/mobile/$i.jpg"
    }
    
    # 3. Low Res PC Tiles (Level 0 / 1024x1024)
    # Structure: /0/0/0_0.jpg, 1_0.jpg ... (face_row_col)
    # 6 faces * 1 row * 1 col = 6 images
    # Faces: 0=front, 1=right, 2=back, 3=left, 4=up, 5=down
    for ($face = 0; $face -le 5; $face++) {
        # Construct path safely
        $relPath = "$scene/$face/0/0_0.jpg"
        $remoteUrl = "$baseUrl/$relPath"
        
        # Local path using Join-Path (safest way)
        $localFile = Join-Path "assets/tour/MallaReddyUniversitydata" $relPath.Replace("/","\")
        
        # Ensure directory exists for this specific file
        $localDir = Split-Path $localFile -Parent
        if (!(Test-Path $localDir)) { New-Item -ItemType Directory -Force -Path $localDir | Out-Null }
        
        Download-File $remoteUrl $localFile
    }
}

Write-Host "Done! Mobile and Low-Res tiles downloaded."
