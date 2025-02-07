#!/usr/bin/env node
import * as path from 'path';
import * as os from 'os';
import tar from "tar";
import fetch from "node-fetch";
import * as unzipper from 'unzipper';
import PJ from "./package.json";

interface BinaryConfig {
  arch: 'arm64' | 'amd64';
  platform: 'darwin' | 'linux' | 'windows';
  extension: '.tar.gz' | '.zip';
  baseUrl: string;
}

const platformMap: Partial<Record<NodeJS.Platform, BinaryConfig['platform']>> = {
  linux: "linux",
  darwin: "darwin",
  win32: "windows"
};

const archMap: Partial<Record<NodeJS.Architecture, BinaryConfig['arch']>> = {
  arm64: "arm64",
  x64: "amd64",
};

const extensionMap: Partial<Record<NodeJS.Platform, BinaryConfig['extension']>> = {
  linux: ".tar.gz",
  darwin: ".tar.gz",
  win32: ".zip",
};

class BinaryDownloader {
  private config: BinaryConfig;

  constructor(config: BinaryConfig) {
    this.config = config
  }

  private URL(): string {
    const { arch, platform, baseUrl, extension } = this.config;
    let version = PJ.version.trim()
    return `${baseUrl}/${version}/qstash-server_${version}_${platform}_${arch}${extension}`;
  }

  public async download(): Promise<NodeJS.ReadableStream> {
    return new Promise((resolve, reject) => {
      const url = this.URL();
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
        switch (this.config.extension) {
            case ".tar.gz":
              const untar = tar.extract({ cwd: bin });
              stream
                .pipe(untar)
                .on('close', () => resolve())
                .on('error', reject)
              break;
            case ".zip":
                stream
                  .pipe(unzipper.Extract({ path: bin }))
                  .on('close', () => resolve())
                  .on('error', reject);
          }
    })
  }
}

function getSysInfo(): { arch: BinaryConfig['arch'], platform: BinaryConfig['platform'], extension: BinaryConfig['extension'] } {
    const arch = archMap[process.arch]
    const platform = platformMap[process.platform]
    const extension = extensionMap[process.platform]

    if (!platform) {
      throw new Error(`Unsupported platform: ${platform}`);
    }

    if (!arch) {
      throw new Error(`Unsupported architecture: ${arch}`);
    }

    if (!extension) {
      throw new Error(`Unsupported extension: ${extension}`);
    }

    return { arch, platform, extension };
}

(async () => {
    try {
        const { arch, platform, extension } = getSysInfo();
    
        const downloader = new BinaryDownloader({
          arch,
          platform,
          extension,
          baseUrl: 'https://artifacts.upstash.com/qstash/versions'
        });
        const stream = await downloader.download();
        await downloader.extract(stream);
      } catch (error) {
        console.error(error);
        process.exit(1);
      }
})();


