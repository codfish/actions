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
   * Update the main README.md file
   */
  updateReadme() {
    const readmePath = path.join(this.rootDir, 'README.md');

    if (!fs.existsSync(readmePath)) {
      console.error('README.md not found');
      return false;
    }

    try {
      let content = fs.readFileSync(readmePath, 'utf8');

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

      // Write back to file
      fs.writeFileSync(readmePath, updatedContent, 'utf8');

      console.log('✅ README.md updated successfully!');
      console.log(`📝 Generated documentation for ${this.actions.length} actions`);

      return true;

    } catch (error) {
      console.error('Error updating README.md:', error.message);
      return false;
    }
  }

  /**
   * Run the documentation generation
   */
  run() {
    console.log('🔍 Scanning for GitHub Actions...');

    const success = this.updateReadme();

    if (success) {
      console.log('\n📚 Documentation generation complete!');
      console.log('Run `git diff README.md` to see the changes.');
    } else {
      console.error('\n❌ Documentation generation failed!');
      process.exit(1);
    }
  }
}

// Run the generator
const generator = new DocumentationGenerator();
generator.run();
