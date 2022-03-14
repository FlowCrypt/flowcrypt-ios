module.exports = {
  root: true,
  parser: '@typescript-eslint/parser',
  parserOptions: {
    project: "appium/tsconfig.eslint.json"
  },
  plugins: [
    '@typescript-eslint',
  ],
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
  ],
  "rules": {
    "@typescript-eslint/no-non-null-assertion": "off",
    "@typescript-eslint/ban-ts-comment": "off",
    "@typescript-eslint/no-floating-promises": ['error'],
    "@typescript-eslint/ban-types": "off",
    "@typescript-eslint/no-explicit-any": "off",
    "@typescript-eslint/triple-slash-reference": "off",
    "@typescript-eslint/no-empty-interface": "off",
    "@typescript-eslint/no-namespace": "off",
    "no-control-regex": "off",
    "no-empty-pattern": "off",
    "no-prototype-builtins": "off"
  }
};
