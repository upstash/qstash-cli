# QStash CLI

QStash CLI is a command-line tool that helps developers work with QStash locally. The only command currently available is `dev`, which runs a local QStash server for development and testing purposes.

## Installation & Usage

You can run QStash CLI directly using npx:

```bash
npx qstash-cli dev
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

## Development Setup

This repository contains the NPM distribution for the QStash CLI, which provides the executable binary through NPX.



1. Update the version in `package.json` to match a version available in the [artifact repository](https://artifact.upstash.com).


2. Build the project:
```bash
npm run build
```

3. Create a global symlink to use your local version:
```bash
npm link
```

### Testing Local Changes

You can test your local changes using any of these methods:

1. Using the linked package:
```bash
qstash-cli dev
```

2. Using npx with an absolute path:
```bash
npx /path/to/local/qstash-cli dev
```

3. Installing locally and running:
```bash
npm install .
npx qstash-cli dev
```
