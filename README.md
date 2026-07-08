# OmniRoute Cloudron Package

Cloudron package for [OmniRoute](https://github.com/diegosouzapw/OmniRoute) — a self-hosted AI gateway with 237+ providers.

## Install via Cloudron

1. Add this app source URL in Cloudron: `https://github.com/vRobM/omniroute-cloudron`
2. Or use the CloudronVersions.json for testing:
   ```
   https://raw.githubusercontent.com/vRobM/omniroute-cloudron/main/CloudronVersions.json
   ```

## Building

The Dockerfile builds OmniRoute from source using the Cloudron base image.

```bash
# Clone this repo
git clone https://github.com/vRobM/omniroute-cloudron.git
cd omniroute-cloudron

# Clone upstream source (not tracked in git)
git clone --depth 1 https://github.com/diegosouzapw/OmniRoute.git omniroute-source

# Build on Cloudron build service
cloudron build build --repository docker.io/robius/omniroute --tag 0.1.0
```

## Links

- [OmniRoute GitHub](https://github.com/diegosouzapw/OmniRoute)
- [OmniRoute Wiki](https://github.com/diegosouzapw/OmniRoute/wiki)
- [Cloudron Forum](https://forum.cloudron.io)
