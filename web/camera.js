let mediaStream = null;
let mediaRecorder = null;
let recordedChunks = [];

// Start camera and attach video stream to the container
function startCamera(containerId) {
    navigator.mediaDevices.getUserMedia({ video: true })
        .then(stream => {
            mediaStream = stream;
            const video = document.createElement('video');
            video.srcObject = stream;
            video.autoplay = true;
            video.muted = true; // Mute the video to avoid feedback
            video.style.width = '100%';
            video.style.height = '100%';
            video.style.objectFit = 'cover'; // Ensure video fits the container
            const container = document.getElementById(containerId);
            if (container) {
                container.innerHTML = '';  // Clear any existing content
                container.appendChild(video);
            } else {
                console.error('Container element not found.');
            }
        })
        .catch(err => {
            console.error('Error accessing the camera:', err);
        });
}

// Start recording
function startRecording() {
    if (!mediaStream) {
        console.error('No media stream available for recording.');
        return;
    }

    try {
        mediaRecorder = new MediaRecorder(mediaStream);
        recordedChunks = []; // Clear previous chunks

        mediaRecorder.ondataavailable = function(event) {
            if (event.data.size > 0) {
                recordedChunks.push(event.data);
            }
        };

        mediaRecorder.onstop = function() {
            const blob = new Blob(recordedChunks, { type: 'video/webm' });
            const url = URL.createObjectURL(blob);
            console.log('Recording stopped. Blob URL:', url);

            // Display the recorded video
            const video = document.createElement('video');
            video.src = url;
            video.controls = true; // Add controls to the video element
            video.style.width = '100%';
            video.style.height = 'auto';
            const container = document.getElementById('video-container');
            if (container) {
                container.innerHTML = ''; // Clear any existing content
                container.appendChild(video);
            } else {
                console.error('Container element not found.');
            }

            // Optional: Provide a link to download the recorded video
            const downloadLink = document.createElement('a');
            downloadLink.href = url;
            downloadLink.download = 'recording.webm';
            downloadLink.textContent = 'Download Recording';
            container.appendChild(downloadLink);
        };

        mediaRecorder.start();
        console.log('Recording started.');
    } catch (err) {
        console.error('Error starting recording:', err);
    }
}

// Stop recording
function stopRecording() {
    if (mediaRecorder) {
        mediaRecorder.stop();
        console.log('Stopping recording...');
    } else {
        console.error('No media recorder found.');
    }
}

// Upload recording
function uploadRecording(apiUrl) {
    if (recordedChunks.length === 0) {
        console.error('No recorded video to upload.');
        return;
    }

    const blob = new Blob(recordedChunks, { type: 'video/webm' });
    const formData = new FormData();
    formData.append('file', blob, 'recording.webm');

    fetch(apiUrl, {
        method: 'POST',
        body: formData
    })
    .then(response => response.json())
    .then(data => {
        console.log('Upload successful:', data);
    })
    .catch(error => {
        console.error('Error uploading recording:', error);
    });
}
