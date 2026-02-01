import codfish from '@codfish/eslint-config';
import { defineConfig } from 'eslint/config';

export default defineConfig([
  codfish,

  {
    rules: {
      'no-console': 'off',
    },
  },
]);
