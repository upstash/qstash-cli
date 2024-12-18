#!/usr/bin/env node
import * as path from 'path';
import * as os from 'os';
import tar from "tar";
import fetch from "node-fetch";
import * as unzipper from 'unzipper';
import PJ from "./package.json";

interface BinaryConfig {
  arch: 'arm64' | 'x64';
  platform: 'darwin' | 'linux' | 'windows';
  baseUrl: string;
}

class BinaryDownloader {
  private config: BinaryConfig;

  constructor(config: BinaryConfig) {
    this.config = {
      ...config,
    };
  }

  private URL(): string {
    const { arch, platform, baseUrl } = this.config;
    let version = PJ.version.trim();

    let archieveType = ""
    switch (platform) {
      case 'darwin':
      case 'linux':
        archieveType = '.tar.gz';
        break;
      case 'windows':
        archieveType = '.exe';
        break;
    }
    return `${baseUrl}/${version}/qstash-server_${version}_${platform}_${arch}${archieveType}`;
  }

  public async download(): Promise<NodeJS.ReadableStream> {
    return new Promise((resolve, reject) => {
      const url = this.URL();
      
        console.log(url)
      fetch(url).then((res) => {
          if (res.status !== 200) {
            throw new Error(`Error downloading binary; invalid response status code: ${res.status}`);
          }
          if (!res.body) {
            return reject(new Error("No body to pipe"));
          }
          resolve(res.body);
        }).catch(reject);
    });
  }

  public async extract(stream: NodeJS.ReadableStream): Promise<void> {
    return new Promise((resolve, reject) => {
        const bin = path.resolve("./bin");
        switch (this.config.platform) {
            case "darwin":
            case "linux":
              const untar = tar.extract({ cwd: bin });
              stream
                .pipe(untar)
                .on('close', () => resolve())
                .on('error', reject)
              break;
            case "windows":
                stream
                  .pipe(unzipper.Extract({ path: bin }))
                  .on('close', () => resolve())
                  .on('error', reject);
          }
    })
  }
}

function getSysInfo(): { arch: BinaryConfig['arch'], platform: BinaryConfig['platform'] } {
    const arch = os.arch() === 'arm64' ? 'arm64' : 'x64';
    const platform = os.platform() as BinaryConfig['platform'];

    if (!['darwin', 'linux', 'win32'].includes(platform)) {
      throw new Error(`Unsupported platform: ${platform}`);
    }

    return { arch, platform };
}

(async () => {
    try {
        const { arch, platform } = getSysInfo();
    
        const downloader = new BinaryDownloader({
          arch,
          platform,
          baseUrl: 'https://qstash-binaries.s3.eu-west-1.amazonaws.com/versions'
        });
        const stream = await downloader.download();
        await downloader.extract(stream);
      } catch (error) {
        console.error(error);
        process.exit(1);
      }
})();


