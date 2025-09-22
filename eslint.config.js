import codfish from '@codfish/eslint-config';

export default [
  ...codfish,
  {
    ignores: ['pnpm-lock.yaml'],
  },
];
