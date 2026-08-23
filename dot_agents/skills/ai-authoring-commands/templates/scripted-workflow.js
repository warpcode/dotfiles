export const meta = {
  name: 'parallel-route-audit',
  description: 'Discover and audit all API route handlers with parallel subagents'
};

// Step 1: Discovery stage with schema validation
const discoverySchema = {
  type: 'object',
  properties: {
    files: {
      type: 'array',
      items: { type: 'string' }
    }
  },
  required: ['files']
};

const discovery = await agent(
  'Find all API route files matching src/routes/**/*.ts and return their relative paths.',
  { schema: discoverySchema, label: 'Discover Route Files' }
);

if (!discovery || !discovery.files || discovery.files.length === 0) {
  return { status: 'empty', message: 'No route files found.' };
}

// Step 2: Define structured audit output schema
const auditSchema = {
  type: 'object',
  properties: {
    file: { type: 'string' },
    hasAuth: { type: 'boolean' },
    issues: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          severity: { type: 'string', enum: ['low', 'medium', 'high', 'critical'] },
          description: { type: 'string' }
        },
        required: ['severity', 'description']
      }
    }
  },
  required: ['file', 'hasAuth', 'issues']
};

// Step 3: Stream discovered files through throttled subagent pipeline
const auditReports = await pipeline(
  discovery.files,
  file => agent(`Audit ${file} for authentication checks and input validation.`, {
    schema: auditSchema,
    label: `Audit: ${file}`,
    phase: 'Route Audit'
  }),
  { concurrency: 4 }
);

// Step 4: Clean up nulls from cancelled/errored subagents and aggregate findings
const validReports = auditReports.filter(Boolean);
const criticalCount = validReports.flatMap(r => r.issues.filter(i => i.severity === 'critical' || i.severity === 'high')).length;

return {
  totalFilesAudited: validReports.length,
  criticalIssuesFound: criticalCount,
  reports: validReports
};
