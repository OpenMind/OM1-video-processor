# OM1 Video Processor

A Docker-based video streaming solution for OpenMind that captures video from local cameras, performs face recognition, and streams the results to OpenMind's video ingestion API.

## Overview

This tool uses the OM1 modules to create an intelligent video streaming pipeline that:
1. Captures video from a local camera (e.g., `/dev/video0`)
2. Performs real-time face recognition with bounding boxes and name overlays
3. Captures audio from a microphone (e.g., `hw:3,0`)
4. Streams the processed video and audio directly to OpenMind's video ingestion API via RTSP

## Features

- **GPU-accelerated processing**: Optimized for NVIDIA Jetson platforms with CUDA support
- **Real-time face recognition**: Live face detection with bounding boxes and name overlays
- **Audio capture**: Integrated microphone support with PulseAudio
- **Direct RTSP streaming**: Streams directly to OpenMind's API without intermediate relay
- **Automatic restart**: All services restart automatically if they fail
- **FPS monitoring**: Real-time performance metrics display
- **Configurable devices**: Supports multiple camera and microphone configurations

## Prerequisites

- Docker and Docker Compose
- NVIDIA Jetson device with JetPack 6.1 (or compatible NVIDIA GPU system)
- A USB camera or built-in webcam (default: `/dev/video0`)
- A microphone device (default: `hw:3,0`)
- OpenMind API credentials
- Linux system with V4L2 and ALSA support

## Setup

1. Clone this repository:
   ```bash
   git clone https://github.com/OpenMind/OM1-tools.git
   cd OM1-tools
   ```

2. Set your OpenMind API credentials as environment variables:
   ```bash
   export OM_API_KEY_ID="your_api_key_id"
   export OM_API_KEY="your_api_key"
   ```

3. (Optional) Configure camera and microphone devices:
   ```bash
   export CAMERA_INDEX="/dev/video0"    # Default camera device
   export MICROPHONE_INDEX="default_mic_aec"     # Default microphone device
   ```

> [!NOTE]
> Please refer to the [OpenMind Avatar documentation](https://github.com/OpenMind/OM1-avatar) for the audio and video device configuration details.

4. Ensure your devices are accessible:
   ```bash
   # Check available video devices
   ls /dev/video*

   # List video devices with v4l2
   v4l2-ctl --list-devices

   # Check available audio devices
   pactl list sources short
   pactl list sinks short
   ```

## Usage

### Start the streaming service:

```bash
docker-compose up -d
```

### View logs:

```bash
docker-compose logs -f
```

### Stop the service:

```bash
docker-compose down
```

## Configuration

The system is configured through several components:

### Docker Compose Configuration

The `docker-compose.yml` file configures:
- **NVIDIA runtime**: GPU acceleration for face recognition processing
- **Network mode**: Host networking for direct device access
- **Privileged mode**: Required for camera and audio device access
- **Device mapping**: Camera (default `/dev/video0`) and audio (`/dev/snd`) devices
- **Environment variables**: OpenMind API credentials, device indices, and PulseAudio configuration
- **Shared memory**: 4GB allocated for efficient video processing

### Processing Pipeline

The streaming pipeline consists of two processes managed by Supervisor:

1. **MediaMTX**: RTSP server for stream routing and management
2. **OM Face Recognition Stream**: Main processing service that:
   - Captures video from the specified camera device
   - Performs real-time face recognition with GPU acceleration
   - Overlays bounding boxes, names, and FPS information
   - Captures audio from the specified microphone
   - Streams directly to OpenMind's RTSP ingestion endpoint

### Environment Variables

The following environment variables can be configured:

- `OM_API_KEY_ID`: Your OpenMind API key ID (required)
- `OM_API_KEY`: Your OpenMind API key (required)
- `CAMERA_INDEX`: Camera device path (default: `/dev/video0`)
- `MICROPHONE_INDEX`: Microphone device identifier (default: `default_mic_aec`)

## Ports

The following ports are used internally:
- **8554**: RTSP (MediaMTX local server)
- **1935**: RTMP (MediaMTX local server)
- **8889**: HLS (MediaMTX local server)
- **8189**: WebRTC (MediaMTX local server)

Note: The main video stream is sent directly to OpenMind's RTSP endpoint at `rtsp://api-video-ingest.openmind.org:8554/`

## Troubleshooting

### Camera not detected:
```bash
# Check available video devices
ls /dev/video*

# Test camera with v4l2
v4l2-ctl --list-devices

# Test specific camera device
v4l2-ctl --device=/dev/video0 --list-formats-ext
```

### Audio issues:
```bash
# Check available audio recording devices
pactl list sources short
pactl list sinks short

# Test microphone recording
arecord -D default_mic_aec -f cd test.wav
aplay test.wav
```

> [!NOTE]
> The pactl has the noise suppression module enabled by default for better audio quality. Use arecord to test the raw microphone input without noise suppression.

### Permission issues:
```bash
# Add your user to video and audio groups
sudo usermod -a -G video,audio $USER

# Ensure device permissions
sudo chmod 666 /dev/video0
```

### Check container logs:
```bash
# View all logs
docker-compose logs

# View specific service logs
docker-compose logs om1_video_processor

# Follow logs in real-time
docker-compose logs -f om1_video_processor
```

### GPU/CUDA issues:
```bash
# Check NVIDIA runtime availability
docker info | grep nvidia

# Test CUDA in container
docker run --rm --runtime=nvidia --gpus all nvidia/cuda:11.0-base nvidia-smi
```

## Architecture

```
┌──────────────┐    ┌─────────────────────────────────┐    ┌─────────────────┐
│    Camera    │───▶│     OM Face Recognition         │───▶│   OpenMind API  │
│  /dev/video0 │    │   - GPU-accelerated processing  │    │   RTSP Ingest   │
└──────────────┘    │   - Face detection & naming     │    │                 │
                    │   - Bounding box overlay        │    └─────────────────┘
┌──────────────┐    │   - FPS monitoring              │
│  Microphone  │───▶│   - Audio capture & streaming   │
│ default_mic_ │    └─────────────────────────────────┘
│    aec       │
└──────────────┘
```

## Development

### Building the image:

```bash
docker-compose build
```

### Customizing processing settings:

Edit the command in `video_processor/supervisord.conf` to modify the `om_face_recog_stream` parameters:
- `--device`: Camera device path
- `--rtsp-mic-device`: Microphone device identifier
- `--draw-boxes`: Enable/disable bounding box overlays
- `--draw-names`: Enable/disable name overlays
- `--show-fps`: Enable/disable FPS display
- `--no-window`: Run in headless mode
- `--remote-rtsp`: OpenMind RTSP ingestion endpoint

### Local development:

```bash
# Install dependencies locally
uv sync --all-extras

# Run the face recognition stream locally
uv run om_face_recog_stream --help
```

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Support

For issues related to:
- **OpenMind API**: Contact OpenMind support
- **OM1 Modules**: Check the [OM1 modules repository](https://github.com/OpenMind/om1-modules)
- **MediaMTX**: Check the [MediaMTX documentation](https://github.com/bluenviron/mediamtx)
- **NVIDIA Jetson**: Check the [JetPack documentation](https://developer.nvidia.com/embedded/jetpack)
- **This tool**: Open an issue in this repository
