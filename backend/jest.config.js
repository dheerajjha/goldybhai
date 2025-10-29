module.exports = {
  testEnvironment: 'node',
  coverageDirectory: 'coverage',
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/server.js', // Exclude server entry point
  ],
  testMatch: [
    '**/__tests__/**/*.test.js',
  ],
  verbose: true,
};
