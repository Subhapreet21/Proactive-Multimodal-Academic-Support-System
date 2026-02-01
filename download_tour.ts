
import * as fs from 'fs';
import * as path from 'path';
import * as https from 'http'; // The site is http

const baseUrl = "http://zeal360.co.in/360/mallareddyuniversity2/MallaReddyUniversitydata";
const localBase = path.join(__dirname, "assets", "tour", "MallaReddyUniversitydata");

const scenes = [
    "_01__university___fro_220",
    "_01__vc_chamber_228",
    "_02__board_room_229",
    "_01__admission_wing_232",
    "_02__administration_w_579",
    "_01__class_room_236",
    "_04__aerial_view_495",
    "_02__campus_view___1_221",
    "_03__campus_view___2_222"
];

function downloadFile(url: string, dest: string) {
    const dir = path.dirname(dest);
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }

    // Skip if exists
    if (fs.existsSync(dest) && fs.statSync(dest).size > 0) {
        return;
    }

    const file = fs.createWriteStream(dest);
    const request = https.get(url, function (response) {
        if (response.statusCode === 200) {
            response.pipe(file);
            file.on('finish', () => {
                file.close();
                console.log(`Downloaded: ${path.basename(dest)}`);
            });
        } else {
            console.log(`Failed to download ${url} (Status: ${response.statusCode})`);
            fs.unlink(dest, () => { }); // Delete failed file
        }
    }).on('error', function (err) { // Handle errors
        fs.unlink(dest, () => { }); // Delete the file async. (But we don't check the result)
        console.log(`Error downloading ${url}: ${err.message}`);
    });
}

async function main() {
    console.log("Starting download...");

    for (const scene of scenes) {
        // 1. Preview & Thumbnails
        downloadFile(`${baseUrl}/${scene}/preview.jpg`, path.join(localBase, scene, "preview.jpg"));
        downloadFile(`${baseUrl}/${scene}/thumbnail.jpg`, path.join(localBase, scene, "thumbnail.jpg"));

        // 2. Mobile Tiles (0-5)
        for (let i = 0; i <= 5; i++) {
            downloadFile(`${baseUrl}/${scene}/mobile/${i}.jpg`, path.join(localBase, scene, "mobile", `${i}.jpg`));
        }

        // 3. Low Res Tiles (Face 0-5, 0_0.jpg)
        for (let face = 0; face <= 5; face++) {
            downloadFile(`${baseUrl}/${scene}/${face}/0/0_0.jpg`, path.join(localBase, scene, `${face}`, "0", "0_0.jpg"));
        }
    }
}

main();
