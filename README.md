# Upstash QStash CLI

![npm (scoped)](https://img.shields.io/npm/v/@upstash/qstash-cli)

> [!NOTE]  
> **This project is in GA Stage.**
> The Upstash Professional Support fully covers this project. It receives regular updates, and bug fixes.
> The Upstash team is committed to maintaining and improving its functionality.

QStash CLI is a command-line tool that helps developers work with QStash locally. The only command currently available is `dev`, which runs a local QStash server for development and testing purposes.

**QStash** is an HTTP based messaging and scheduling solution for serverless and
edge runtimes.

It is 100% built on stateless HTTP requests and designed for:

- Serverless functions (AWS Lambda ...)
- Cloudflare Workers (see
  [the example](https://github.com/upstash/sdk-qstash-ts/tree/main/examples/cloudflare-workers))
- Fastly Compute@Edge
- Next.js, including [edge](https://nextjs.org/docs/api-reference/edge-runtime)
- Deno
- Client side web/mobile applications
- WebAssembly
- and other environments where HTTP is preferred over TCP.

## Quick Start

### Install

```bash
npm install @upstash/qstash-cli
```

## Basic Usage:

```bash
npx @upstash/qstash-cli dev
```

### Available Commands

```bash
Usage:
        qstash-cli [command] [options]
Commands:
        dev     Start a local dev server
Options:
        -port  The port number to start server on (default: 8080)
```


## Docs

See [the local development guide](https://docs.upstash.com/qstash/howto/local-development) for details.
