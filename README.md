# OM1 Tools

A Docker-based video streaming solution for OpenMind that captures video from local cameras and streams it to OpenMind's video ingestion API.

## Overview

This tool uses MediaMTX (formerly rtsp-simple-server) to create a video streaming pipeline that:
1. Captures video from a local camera (e.g., `/dev/video0`)
2. Streams it locally via RTMP
3. Relays the stream to OpenMind's video ingestion API

## Features

- **Multi-architecture support**: Works on both x86_64 and ARM64 architectures
- **Automatic video capture**: Uses FFmpeg to capture from V4L2 devices
- **Real-time streaming**: Low-latency streaming with optimized encoding settings
- **Automatic restart**: All services restart automatically if they fail
- **Audio support**: Configured for PulseAudio integration

## Prerequisites

- Docker and Docker Compose
- A USB camera or built-in webcam accessible at `/dev/video0`
- OpenMind API credentials
- Linux system with V4L2 support

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

3. Ensure your camera is accessible:
   ```bash
   ls /dev/video*
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
- **Network mode**: Host networking for direct device access
- **Privileged mode**: Required for camera and audio device access
- **Device mapping**: Camera (`/dev/video0`) and audio (`/dev/snd`) devices
- **Environment variables**: OpenMind API credentials and PulseAudio configuration

### Video Pipeline

The streaming pipeline consists of three processes managed by Supervisor:

1. **MediaMTX**: RTMP server that receives and manages video streams
2. **FFmpeg Capture**: Captures video from `/dev/video0` and streams to local MediaMTX
3. **FFmpeg Relay**: Relays the stream to OpenMind's video ingestion API

### Video Settings

Current configuration:
- **Resolution**: 640x480
- **Frame rate**: 30 FPS
- **Codec**: H.264 with ultrafast preset
- **Optimization**: Zero-latency tuning for real-time streaming

## Ports

The following ports are exposed:
- **8554**: RTSP
- **1935**: RTMP
- **8889**: HLS
- **8189**: WebRTC

## Troubleshooting

### Camera not detected:
```bash
# Check available video devices
ls /dev/video*

# Test camera with v4l2
v4l2-ctl --list-devices
```

### Permission issues:
```bash
# Add your user to video and audio groups
sudo usermod -a -G video,audio $USER
```

### Check container logs:
```bash
# View all logs
docker-compose logs

# View specific service logs
docker-compose logs mediamtx
```

### Test local stream:
```bash
# Test RTMP stream locally
ffplay rtmp://localhost:1935/live
```

## Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────────┐
│   Camera    │───▶│   FFmpeg    │───▶│   MediaMTX  │───▶│   OpenMind API  │
│ /dev/video0 │    │   Capture   │    │    RTMP     │    │   Video Ingest  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────────┘
```

## Development

### Building the image:

```bash
docker build -t openmindagi/mediamtx:latest ./mediamtx
```

### Customizing video settings:

Edit the FFmpeg command in `mediamtx/supervisord.conf` to change:
- Video resolution: `-video_size 640x480`
- Frame rate: `-framerate 30`
- Input device: `-i /dev/video0`

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
- **MediaMTX**: Check the [MediaMTX documentation](https://github.com/bluenviron/mediamtx)
- **This tool**: Open an issue in this repository
