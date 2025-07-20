# Installing from source

Building Rayhunter from source for development or local use.

## Prerequisites

* Install [Rust and Cargo](https://www.rust-lang.org/tools/install)
* Install [Node.js/npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm), which is required to build Rayhunter's web UI
* Install `curl` on your computer to run the install scripts

## Building

1. **Build the web UI first:**
   ```sh
   cd daemon/web
   npm install
   npm run build
   cd ../..
   ```

2. **Build the Rust components:**
   ```sh
   cargo build --release
   ```

3. **Run the application:**
   ```sh
   ./target/release/rayhunter-daemon
   ```

## Development

For development with hot-reloading of the web UI:
```sh
cd daemon/web
npm run dev
```

This will start the development server at `http://localhost:5173`.

## Build Script

You can also use the simplified build script:
```sh
./build_all.sh
```

This will build all components in the correct order.
