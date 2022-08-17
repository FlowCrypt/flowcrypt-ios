/* eslint-disable @typescript-eslint/naming-convention */
module.exports = {
  parser: '@typescript-eslint/parser',
  parserOptions: {
    project: 'tsconfig.eslint.json',
    tsconfigRootDir: __dirname,
  },
  root: true,
  env: {
    browser: true,
    node: true,
    commonjs: true,
    es6: true
  },
  globals: {
    '$': false,
    'chrome': false,
    'OpenPGP': false
  },
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/base',
    'plugin:@typescript-eslint/recommended'
  ],
  plugins: [
    'no-only-tests',
    'header',
    'eslint-plugin-jsdoc',
    'eslint-plugin-prefer-arrow',
    'eslint-plugin-import',
    '@typescript-eslint',
    'eslint-plugin-local-rules'
  ],
  rules: {
    '@typescript-eslint/adjacent-overload-signatures': 'error',
    '@typescript-eslint/array-type': 'off',
    '@typescript-eslint/await-thenable': 'off',
    "@typescript-eslint/ban-ts-comment": "off",
    '@typescript-eslint/ban-types': [
      'error',
      {
        'types': {
          'Object': {
            'message': 'Avoid using the `Object` type. Did you mean `object`?'
          },
          'Function': {
            'message': 'Avoid using the `Function` type. Prefer `() => void`'
          },
          'Boolean': {
            'message': 'Avoid using the `Boolean` type. Did you mean `boolean`?'
          },
          'Number': {
            'message': 'Avoid using the `Number` type. Did you mean `number`?'
          },
          'String': {
            'message': 'Avoid using the `String` type. Did you mean `string`?'
          },
          'Symbol': {
            'message': 'Avoid using the `Symbol` type. Did you mean `symbol`?'
          }
        }
      }
    ],
    '@typescript-eslint/consistent-type-assertions': 'error',
    '@typescript-eslint/consistent-type-definitions': 'off',
    '@typescript-eslint/dot-notation': 'error',
    '@typescript-eslint/explicit-function-return-type': 'off',
    '@typescript-eslint/explicit-member-accessibility': [
      'error',
      {
        'accessibility': 'explicit'
      }
    ],
    '@typescript-eslint/explicit-module-boundary-types': 'off',
    '@typescript-eslint/indent': ['error', 2,
      {
        SwitchCase: 1,
        ignoredNodes: [
          "PropertyDefinition[decorators]",
          "TSUnionType"
        ]
      }
    ],
    '@typescript-eslint/member-ordering': 'error',
    '@typescript-eslint/naming-convention': 'error',
    '@typescript-eslint/no-empty-function': 'error',
    '@typescript-eslint/no-empty-interface': 'off',
    '@typescript-eslint/no-explicit-any': 'warn',
    '@typescript-eslint/no-floating-promises': 'error',
    '@typescript-eslint/no-misused-promises': ['error'],
    '@typescript-eslint/no-misused-new': 'error',
    '@typescript-eslint/no-namespace': 'off',
    '@typescript-eslint/no-parameter-properties': 'off',
    '@typescript-eslint/no-shadow': [
      'off',
      {
        'hoist': 'all'
      }
    ],
    '@typescript-eslint/no-unsafe-return': 'error',
    '@typescript-eslint/no-unsafe-argument': 'warn',
    '@typescript-eslint/no-unused-expressions': 'error',
    '@typescript-eslint/no-unused-vars': 'error',
    '@typescript-eslint/no-use-before-define': 'off',
    '@typescript-eslint/no-var-requires': 'error',
    '@typescript-eslint/prefer-for-of': 'error',
    '@typescript-eslint/prefer-function-type': 'error',
    '@typescript-eslint/prefer-namespace-keyword': 'error',
    '@typescript-eslint/quotes': 'off',
    '@typescript-eslint/semi': 'error',
    '@typescript-eslint/triple-slash-reference': [
      'off',
      {
        'path': 'always',
        'types': 'prefer-import',
        'lib': 'always'
      }
    ],
    '@typescript-eslint/type-annotation-spacing': 'off',
    '@typescript-eslint/typedef': 'off',
    '@typescript-eslint/unbound-method': 'error',
    '@typescript-eslint/unified-signatures': 'error',
    'indent': 'off',
    'max-len': ['error', { code: 120 }],
    'arrow-parens': [
      'off',
      'always'
    ],
    'complexity': 'off',
    'constructor-super': 'error',
    'dot-notation': 'error',
    'eqeqeq': [
      'error',
      'smart'
    ],
    'guard-for-in': 'error',
    'id-denylist': 'error',
    'id-match': 'error',
    'import/order': 'off',
    'jsdoc/check-alignment': 'off',
    'jsdoc/check-indentation': 'off',
    'jsdoc/newline-after-description': 'off',
    'max-classes-per-file': 'off',
    'new-parens': 'error',
    'no-bitwise': 'off',
    'no-caller': 'error',
    'no-cond-assign': 'error',
    'no-console': 'off',
    'no-constant-condition': 0,
    'no-control-regex': 0,
    'no-debugger': 'error',
    'no-empty': 'error',
    'no-empty-function': 'error',
    'no-empty-pattern': 0,
    'no-eval': 'error',
    'no-fallthrough': 'off',
    'no-invalid-this': 'off',
    'no-new-wrappers': 'error',
    'no-only-tests/no-only-tests': ['error', { block: ['ava.default'] }],
    'no-prototype-builtins': 0,
    'no-shadow': 'off',
    'no-throw-literal': 'error',
    'no-trailing-spaces': 'error',
    'no-undef': 0,
    'no-undef-init': 'error',
    'no-underscore-dangle': 'error',
    'no-unsafe-finally': 'error',
    'no-unused-expressions': 0,
    'no-unused-labels': 'error',
    'no-unused-vars': 0,
    'no-use-before-define': 'off',
    'no-useless-escape': 0,
    'no-var': 'error',
    'object-shorthand': 'error',
    'one-var': [
      'off',
      'never'
    ],
    'prefer-arrow/prefer-arrow-functions': 'error',
    'prefer-const': ['error', {
      destructuring: 'all',
    }],
    'radix': 'off',
    'require-atomic-updates': 0,
    'semi': 0,
    'sort-imports': ['off', {
      'ignoreCase': false,
      'ignoreDeclarationSort': false,
      'ignoreMemberSort': false,
      'memberSyntaxSortOrder': ['none', 'all', 'multiple', 'single']
    }],
    'space-before-blocks': ['error', 'always'],
    'spaced-comment': [
      'error',
      'always',
      {
        'markers': [
          '/'
        ]
      }
    ],
    'use-isnan': 'error',
    'valid-typeof': 'off',
    'local-rules/standard-loops': 'error'
  },
  overrides: [
    {
      'files': ['./source/**/*.ts'],
      'rules': {
        'header/header': ['error', 'block',
          ' ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com ']
      }
    }
  ]
};