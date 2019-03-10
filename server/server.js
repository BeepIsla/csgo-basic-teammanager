const http = require("http");
const URL = require("url");
const fs = require("fs");
const path = require("path");
const ChildProcess = require("child_process");

http.createServer(async (req, res) => {
	const url = URL.parse(req.url);

	if (url.query === null) {
		res.writeHead(400);
		res.end();
		return;
	}

	let params = {};
	url.query.split("&").map(m => params[decodeURIComponent(m.split("=")[0])] = decodeURIComponent(m.split("=")[1]));

	if (params.id === null) {
		res.writeHead(400);
		res.end();
		return;
	}

	if (req.method !== "GET") {
		res.writeHead(405, { id: params.id });
		res.end();
		return;
	}

	if (url.path === null) {
		res.writeHead(400, { id: params.id });
		res.end();
		return;
	}

	if (url.pathname !== "/avatar") {
		res.writeHead(400, { id: params.id });
		res.end();
		return;
	}

	// We do not allow spaces in the file name
	if (params.id.includes(" ")) {
		res.writeHead(406, { id: params.id });
		res.end();
		return;
	}

	const filePath = path.join(__dirname, "avatars", params.id + ".rgb");
	const filePathPNG = path.join(__dirname, "avatars", params.id + ".png");

	// RGB file does not exist
	if (fs.existsSync(filePath) === false) {
		// PNG file also doesn't exist
		if (fs.existsSync(filePathPNG) === false) {
			console.log("Failed to send " + params.id + " because it doesn't exist");

			res.writeHead(204, { id: params.id });
			res.end();
			return;
		}

		// File exists but only as PNG format, so we have to convert it, if needed also resize
		await new Promise((resolve, reject) => {
			const proc = ChildProcess.spawn("magick", [ "-resize 64x64\\!", params.id + ".png ", params.id + ".rgb" ], {
				cwd: path.join(__dirname, "avatars"),
				timeout: 10000, // Should never take longer than 1 second tbh but 10 second timeout is good enough
				windowsHide: true
			});

			proc.on("error", reject);
			proc.on("exit", (code, signal) => {
				if (code === 0) {
					resolve();
					return;
				}

				reject(new Error("Exited with non zero exit code: " + code));
			});
		}).catch((err) => {
			// Error while converting png to rgb
			console.error(err);

			res.writeHead(500, { id: params.id });
			res.end();
		});

		// Wait for the .catch to happen, if it did
		await new Promise(r => setInterval(r, 10));

		// If the statusCode is not 200 that means the .catch block happened
		if (res.statusCode !== 200) {
			return;
		}

		// Check if the image doesnt exist despite the process reporting success
		if (fs.existsSync(filePath) === false) {
			console.log("Failed to send " + params.id + " because it doesn't exist and we failed to convert it");

			res.writeHead(204, { id: params.id });
			res.end();
			return;
		}
	}

	// Send the file!
	const stat = fs.statSync(filePath);
	res.writeHead(200, {
		"Content-Type": "image/x-rgb",
		"Content-Length": stat.size,
		"id": params.id
	});

	fs.createReadStream(filePath).pipe(res).on("close", () => {
		console.log("Successfully sent " + params.id);

		res.end();
	}).on("error", (err) => {
		console.log("Failed to send " + params.id);
		console.error(err);

		res.end();
	});
}).listen(8181, () => {
	console.log("Listening to 8181");
});
