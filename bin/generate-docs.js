#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import yaml from 'js-yaml';

/**
 * Generate documentation for all GitHub Actions in the repository
 */
class DocumentationGenerator {
  constructor() {
    this.rootDir = process.cwd();
    this.actions = [];
  }

  /**
   * Find all action directories by looking for action.yml files
   */
  findActionDirectories() {
    const entries = fs.readdirSync(this.rootDir, { withFileTypes: true });

    return entries
      .filter(entry => entry.isDirectory())
      .filter(entry => !entry.name.startsWith('.') && entry.name !== 'node_modules')
      .map(entry => entry.name)
      .filter(dirName => {
        const actionFile = path.join(this.rootDir, dirName, 'action.yml');
        return fs.existsSync(actionFile);
      });
  }

  /**
   * Parse action.yml file to extract metadata
   */
  parseActionFile(dirName) {
    const actionFile = path.join(this.rootDir, dirName, 'action.yml');

    try {
      const content = fs.readFileSync(actionFile, 'utf8');
      const actionData = yaml.load(content);

      return {
        directory: dirName,
        name: actionData.name || dirName,
        description: actionData.description || 'No description available',
        inputs: actionData.inputs || {},
        outputs: actionData.outputs || {},
        rawData: actionData
      };
    } catch (error) {
      console.error(`Error parsing ${actionFile}:`, error.message);
      return null;
    }
  }

  /**
   * Extract usage example from README.md
   */
  extractUsageExample(dirName) {
    const readmeFile = path.join(this.rootDir, dirName, 'README.md');

    if (!fs.existsSync(readmeFile)) {
      return null;
    }

    try {
      const content = fs.readFileSync(readmeFile, 'utf8');

      // Look for usage examples in various sections
      const patterns = [
        // Look for "## Usage" section with yaml code block
        /## Usage[\s\S]*?```yaml\n([\s\S]*?)\n```/i,
        // Look for any yaml code block with "uses: "
        /```yaml\n([\s\S]*?uses:\s*[.\w/-]+[\s\S]*?)\n```/i,
        // Look for specific action usage
        new RegExp(`\`\`\`yaml\\n([\\s\\S]*?uses:\\s*[^\\n]*${dirName}[\\s\\S]*?)\\n\`\`\``, 'i')
      ];

      for (const pattern of patterns) {
        const match = content.match(pattern);
        if (match && match[1]) {
          // Clean up the example and ensure it's properly formatted
          const example = match[1].trim();

          // If it doesn't start with a step name, add one
          if (!example.match(/^\s*-\s*name:/m) && !example.match(/^\s*-\s*uses:/m)) {
            return `- uses: codfish/actions/${dirName}@main\n${example.replace(/^/gm, '  ')}`;
          }

          return example;
        }
      }

      // Fallback: create a basic example based on inputs
      return this.generateBasicExample(dirName);

    } catch (error) {
      console.error(`Error reading README for ${dirName}:`, error.message);
      return this.generateBasicExample(dirName);
    }
  }

  /**
   * Generate a basic usage example based on action inputs
   */
  generateBasicExample(dirName, inputs = {}) {
    let example = `- uses: codfish/actions/${dirName}@main`;

    const inputKeys = Object.keys(inputs);
    if (inputKeys.length > 0) {
      example += '\n  with:';

      // Add required inputs first
      const requiredInputs = inputKeys.filter(key => inputs[key].required);
      const optionalInputs = inputKeys.filter(key => !inputs[key].required);

      [...requiredInputs, ...optionalInputs.slice(0, 2)].forEach(key => {
        const input = inputs[key];
        let value = 'value';

        // Smart defaults based on input name
        if (key.includes('token')) value = '${{ secrets.TOKEN_NAME }}';
        else if (key.includes('version')) value = 'lts/*';
        else if (key.includes('message')) value = 'Your message here';
        else if (key.includes('tag')) value = 'tag-name';
        else if (input.default) value = input.default;

        example += `\n    ${key}: ${value}`;
      });
    }

    return example;
  }

  /**
   * Generate markdown table for inputs or outputs
   */
  generateTable(items, type = 'inputs') {
    if (!items || Object.keys(items).length === 0) {
      return `*No ${type}*`;
    }

    const headers = type === 'inputs'
      ? '| Input | Description | Required | Default |'
      : '| Output | Description |';

    const separator = type === 'inputs'
      ? '|-------|-------------|----------|---------|'
      : '|--------|-------------|';

    let table = `${headers}\n${separator}`;

    Object.entries(items).forEach(([key, config]) => {
      const description = config.description || 'No description';

      if (type === 'inputs') {
        const required = config.required ? 'Yes' : 'No';
        const defaultValue = config.default ? `\`${config.default}\` ` : '-';
        table += `\n| \`${key}\` | ${description} | ${required} | ${defaultValue} |`;
      } else {
        table += `\n| \`${key}\` | ${description} |`;
      }
    });

    return table;
  }

  /**
   * Generate markdown section for a single action
   */
  generateActionSection(action) {
    const { directory, name, description, inputs, outputs } = action;
    const usageExample = this.extractUsageExample(directory);

    let section = `### [${name}](./${directory}/)\n\n`;
    section += `${description}\n\n`;

    // Add inputs table
    section += `**Inputs:**\n\n${this.generateTable(inputs, 'inputs')}\n\n`;

    // Add outputs table if there are outputs
    if (outputs && Object.keys(outputs).length > 0) {
      section += `**Outputs:**\n\n${this.generateTable(outputs, 'outputs')}\n\n`;
    }

    // Add usage example
    if (usageExample) {
      section += `**Usage:**\n\n\`\`\`yaml\n${usageExample}\n\`\`\`\n\n`;
    }

    return section;
  }

  /**
   * Generate just the content for actions (without the section header)
   */
  generateAvailableActionsContent() {
    const actionDirs = this.findActionDirectories();
    
    console.log(`Found ${actionDirs.length} action directories:`, actionDirs);

    this.actions = actionDirs
      .map(dir => this.parseActionFile(dir))
      .filter(action => action !== null)
      .sort((a, b) => a.name.localeCompare(b.name));

    let content = '';
    
    this.actions.forEach(action => {
      content += this.generateActionSection(action);
    });

    return content.trim(); // Remove trailing newlines
  }

  /**
   * Update the main README.md file using file descriptors for security
   */
  updateReadme() {
    const readmePath = path.join(this.rootDir, 'README.md');

    if (!fs.existsSync(readmePath)) {
      console.error('README.md not found');
      return false;
    }

    let fd;
    try {
      // Open file descriptor for reading and writing
      fd = fs.openSync(readmePath, 'r+');
      
      // Read content using file descriptor
      const stats = fs.fstatSync(fd);
      const buffer = Buffer.alloc(stats.size);
      fs.readSync(fd, buffer, 0, stats.size, 0);
      let content = buffer.toString('utf8');

      // Find the action docs markers
      const startMarker = '<!-- start action docs -->';
      const endMarker = '<!-- end action docs -->';
      
      const startIndex = content.indexOf(startMarker);
      const endIndex = content.indexOf(endMarker);
      
      if (startIndex === -1) {
        console.error(`Could not find "${startMarker}" in README.md`);
        console.error('Please add the marker where you want action documentation to be generated');
        return false;
      }
      
      if (endIndex === -1) {
        console.error(`Could not find "${endMarker}" in README.md`);
        console.error('Please add the end marker after the start marker');
        return false;
      }
      
      if (endIndex <= startIndex) {
        console.error('End marker must come after start marker');
        return false;
      }

      // Replace content between markers
      const beforeMarker = content.substring(0, startIndex + startMarker.length);
      const afterMarker = content.substring(endIndex);
      
      const newContent = this.generateAvailableActionsContent();
      const updatedContent = beforeMarker + '\n' + newContent + '\n' + afterMarker;

      // Truncate and write back using file descriptor
      fs.ftruncateSync(fd, 0);
      fs.writeSync(fd, updatedContent, 0, 'utf8');

      console.log('✅ README.md updated successfully!');
      console.log(`📝 Generated documentation for ${this.actions.length} actions`);

      return true;

    } catch (error) {
      console.error('Error updating README.md:', error.message);
      return false;
    } finally {
      // Always close the file descriptor
      if (fd !== undefined) {
        try {
          fs.closeSync(fd);
        } catch (closeError) {
          console.error('Error closing README.md file descriptor:', closeError.message);
        }
      }
    }
  }

  /**
   * Update individual action README files with inputs/outputs using file descriptors for security
   */
  updateActionReadmes() {
    const actionDirs = this.findActionDirectories();
    let updatedCount = 0;

    actionDirs.forEach(dirName => {
      const readmePath = path.join(this.rootDir, dirName, 'README.md');
      
      if (!fs.existsSync(readmePath)) {
        console.log(`⚠️  No README.md found in ${dirName}, skipping`);
        return;
      }

      const actionData = this.parseActionFile(dirName);
      if (!actionData) {
        console.log(`⚠️  Could not parse action.yml for ${dirName}, skipping`);
        return;
      }

      let fd;
      try {
        // Open file descriptor for reading and writing
        fd = fs.openSync(readmePath, 'r+');
        
        // Read content using file descriptor
        const stats = fs.fstatSync(fd);
        const buffer = Buffer.alloc(stats.size);
        fs.readSync(fd, buffer, 0, stats.size, 0);
        let content = buffer.toString('utf8');
        let modified = false;

        // Update inputs section
        const inputsStartMarker = '<!-- start inputs -->';
        const inputsEndMarker = '<!-- end inputs -->';
        const inputsStart = content.indexOf(inputsStartMarker);
        const inputsEnd = content.indexOf(inputsEndMarker);

        if (inputsStart !== -1 && inputsEnd !== -1 && inputsEnd > inputsStart) {
          const inputsTable = this.generateTable(actionData.inputs, 'inputs');
          const beforeInputs = content.substring(0, inputsStart + inputsStartMarker.length);
          const afterInputs = content.substring(inputsEnd);
          content = beforeInputs + '\n\n' + inputsTable + '\n\n' + afterInputs;
          modified = true;
          console.log(`✅ Updated inputs section in ${dirName}/README.md`);
        }

        // Update outputs section
        const outputsStartMarker = '<!-- start outputs -->';
        const outputsEndMarker = '<!-- end outputs -->';
        const outputsStart = content.indexOf(outputsStartMarker);
        const outputsEnd = content.indexOf(outputsEndMarker);

        if (outputsStart !== -1 && outputsEnd !== -1 && outputsEnd > outputsStart) {
          const outputsTable = this.generateTable(actionData.outputs, 'outputs');
          const beforeOutputs = content.substring(0, outputsStart + outputsStartMarker.length);
          const afterOutputs = content.substring(outputsEnd);
          content = beforeOutputs + '\n\n' + outputsTable + '\n\n' + afterOutputs;
          modified = true;
          console.log(`✅ Updated outputs section in ${dirName}/README.md`);
        }

        if (modified) {
          // Truncate and write back using file descriptor
          fs.ftruncateSync(fd, 0);
          fs.writeSync(fd, content, 0, 'utf8');
          updatedCount++;
        }

      } catch (error) {
        console.error(`Error updating ${dirName}/README.md:`, error.message);
      } finally {
        // Always close the file descriptor
        if (fd !== undefined) {
          try {
            fs.closeSync(fd);
          } catch (closeError) {
            console.error(`Error closing ${dirName}/README.md file descriptor:`, closeError.message);
          }
        }
      }
    });

    return updatedCount;
  }

  /**
   * Run prettier formatting on all documentation files
   */
  async formatDocs() {
    const { execSync } = await import('child_process');
    
    try {
      console.log('\n🎨 Formatting documentation with prettier...');
      execSync('pnpm format', { 
        stdio: 'inherit',
        cwd: this.rootDir 
      });
      console.log('✅ Documentation formatting complete!');
      return true;
    } catch (error) {
      console.error('❌ Prettier formatting failed:', error.message);
      return false;
    }
  }

  /**
   * Run the documentation generation
   */
  async run() {
    console.log('🔍 Scanning for GitHub Actions...');

    // Update main README
    const mainSuccess = this.updateReadme();
    
    // Update individual action READMEs
    console.log('\n🔍 Updating individual action README files...');
    const updatedActionCount = this.updateActionReadmes();

    if (mainSuccess) {
      console.log(`\n📚 Documentation generation complete!`);
      console.log(`📝 Updated main README.md with ${this.actions.length} actions`);
      if (updatedActionCount > 0) {
        console.log(`📝 Updated ${updatedActionCount} action README files`);
      }
      
      // Format the documentation
      const formatSuccess = await this.formatDocs();
      
      if (formatSuccess) {
        console.log('\n🎉 All documentation updated and formatted successfully!');
        console.log('Run `git diff` to see all changes.');
      } else {
        console.log('\n⚠️  Documentation updated but formatting failed.');
        console.log('You may want to run `pnpm format` manually.');
      }
    } else {
      console.error('\n❌ Main README documentation generation failed!');
      process.exit(1);
    }
  }
}

// Run the generator
const generator = new DocumentationGenerator();
generator.run();
