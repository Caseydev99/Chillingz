const fs = require('node:fs');
const path = require('node:path');

const projectRoot = path.resolve(__dirname, '..');
const publicDirectory = path.join(projectRoot, 'public');
const webBuildDirectory = path.join(projectRoot, 'build', 'web');

if (!fs.existsSync(webBuildDirectory)) {
  throw new Error(
    `Flutter web build output was not found at ${webBuildDirectory}`,
  );
}

fs.cpSync(publicDirectory, webBuildDirectory, { recursive: true });
