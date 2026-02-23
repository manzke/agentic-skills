---
name: code-review
description: Performs comprehensive code reviews focusing on code quality, security vulnerabilities, best practices, and maintainability. Reviews both new code and changes in pull requests.
license: MIT
compatibility: git; bash; python3 (optional for advanced checks)
allowed-tools: [bash, git, grep, cat]
---

# Code Review

A comprehensive code review skill that helps identify issues in code quality, security vulnerabilities, and adherence to best practices.

## Purpose

This skill enables AI agents to perform thorough code reviews by:
- Analyzing code changes in git repositories
- Identifying potential security vulnerabilities
- Checking code quality and maintainability
- Suggesting improvements and best practices
- Detecting common programming errors

## When to Use

- Before merging pull requests
- When reviewing new code contributions
- During code quality audits
- When seeking feedback on implementation approaches
- To identify potential security issues early

## Prerequisites

- Git repository with committed changes
- Access to bash and basic Unix utilities
- Optional: Python 3 for advanced static analysis

## Instructions

### 1. Identify Scope

First, determine what code to review:

**For Pull Requests:**
```bash
# Show files changed in current branch
git diff --name-only main...HEAD

# Show the actual changes
git diff main...HEAD
```

**For Specific Files:**
```bash
# Review specific file
cat path/to/file.ext
```

**For Recent Commits:**
```bash
# Show last N commits
git log -n 5 --oneline

# Show changes in last commit
git show HEAD
```

### 2. Analyze Code Structure

Review the overall structure and organization:

- **File Organization**: Are files logically organized?
- **Module Design**: Are modules cohesive with clear responsibilities?
- **Dependencies**: Are dependencies appropriate and minimal?
- **Naming**: Are names clear, consistent, and descriptive?

### 3. Check Code Quality

Examine code for quality issues:

**Readability:**
- Is the code easy to understand?
- Are complex sections documented?
- Is formatting consistent?
- Are variable/function names descriptive?

**Complexity:**
- Are functions too long or doing too much?
- Is there excessive nesting?
- Can logic be simplified?

**Error Handling:**
- Are errors properly caught and handled?
- Are edge cases considered?
- Are error messages informative?

**Testing:**
- Are there tests for new functionality?
- Do tests cover edge cases?
- Are tests clear and maintainable?

### 4. Security Analysis

Check for common security vulnerabilities:

**Input Validation:**
```bash
# Search for potential SQL injection risks
grep -r "SELECT.*\$" .
grep -r "query.*\+" .

# Look for command injection risks
grep -r "exec\|system\|eval" .
```

**Authentication & Authorization:**
- Are authentication mechanisms secure?
- Is authorization checked before sensitive operations?
- Are passwords/secrets properly handled?

**Data Exposure:**
- Are sensitive data properly encrypted?
- Are API keys/secrets hardcoded?
- Is PII (Personal Identifiable Information) protected?

**Common Vulnerabilities:**
- XSS (Cross-Site Scripting) vulnerabilities
- CSRF (Cross-Site Request Forgery) protections
- Path traversal vulnerabilities
- Insecure deserialization

### 5. Best Practices Check

Verify adherence to language-specific best practices:

**General:**
- DRY (Don't Repeat Yourself) - Is code duplicated?
- SOLID principles followed?
- Appropriate design patterns used?
- Resource cleanup (files, connections, etc.)?

**Language-Specific:**
- Python: PEP 8 compliance, proper exception handling
- JavaScript: ESLint rules, async/await usage
- Java: Spring/Jakarta conventions
- Go: Effective Go guidelines

### 6. Performance Considerations

Look for potential performance issues:

- Unnecessary loops or iterations
- N+1 query problems
- Missing database indexes
- Memory leaks
- Inefficient algorithms

### 7. Generate Review Report

Provide a structured review with:

**Summary:**
- Overall code quality assessment
- Number of issues found (critical, major, minor)
- Recommendation (approve, request changes, needs discussion)

**Detailed Findings:**

For each issue:
1. **Severity**: Critical/High/Medium/Low
2. **Location**: File and line number
3. **Issue**: Clear description of the problem
4. **Impact**: Why it matters
5. **Recommendation**: How to fix it
6. **Example**: Show correct implementation if applicable

**Positive Feedback:**
- Highlight well-written code
- Note good practices followed
- Acknowledge improvements

## Examples

### Example 1: Reviewing a Pull Request

```bash
# Get PR changes
git fetch origin pull/123/head:pr-123
git checkout pr-123
git diff main...pr-123

# Review specific concerns
grep -r "TODO\|FIXME\|XXX" .
grep -r "password\|secret\|api_key" .
```

### Example 2: Security-Focused Review

```bash
# Check for hardcoded secrets
grep -rE "password\s*=\s*['\"]|api_key\s*=\s*['\"]" .

# Look for SQL injection vulnerabilities
grep -rE "execute\(.*%s|query\(.*\+.*\)" .

# Check for XSS vulnerabilities in templates
grep -r "innerHTML\|dangerouslySetInnerHTML" .
```

### Example 3: Code Quality Metrics

```bash
# Find large files that might need refactoring
find . -name "*.py" -exec wc -l {} \; | sort -rn | head -10

# Find complex functions (simple heuristic: many lines)
grep -rn "def " --include="*.py" | awk -F: '{print $1}' | uniq -c | sort -rn
```

## Output Format

Structure your review as:

```
# Code Review Summary

**Overall Assessment**: [Approve/Request Changes/Needs Discussion]
**Quality Score**: [1-10]
**Issues Found**: X critical, Y major, Z minor

## Critical Issues

### 1. [Issue Title]
- **File**: path/to/file.ext:line
- **Severity**: Critical
- **Issue**: Description
- **Impact**: Security risk/data loss/etc.
- **Fix**: Recommended solution

## Major Issues

[Similar structure]

## Minor Issues / Suggestions

[Similar structure]

## Positive Feedback

- [Good practice observed]
- [Well-implemented feature]

## Recommendations

1. [Priority recommendations]
2. [Nice-to-have improvements]
```

## Tips

- **Be Constructive**: Focus on helping improve the code, not criticizing
- **Explain Why**: Always explain the reasoning behind suggestions
- **Prioritize**: Not all issues are equally important
- **Be Specific**: Point to exact locations and provide examples
- **Consider Context**: Understand project requirements and constraints
- **Security First**: Always prioritize security issues
- **Test Coverage**: Encourage comprehensive testing

## Limitations

- Cannot execute or run tests automatically
- Static analysis only - runtime behavior not examined
- May miss context-specific issues
- Language-specific linting tools provide deeper analysis

## See Also

- Security analysis tools (e.g., Bandit for Python, ESLint for JS)
- Language-specific style guides
- OWASP Top 10 security vulnerabilities
- Clean Code principles by Robert Martin
