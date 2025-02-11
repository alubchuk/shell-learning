#!/bin/bash

# =============================================================================
# CI/CD Integration Examples
# This script demonstrates integration between Git and CI/CD systems,
# including GitHub Actions, GitLab CI, and Jenkins pipeline configurations.
# =============================================================================

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Function: setup_example_repo
# Purpose: Create an example repository for CI/CD demonstrations
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
setup_example_repo() {
    echo "=== Setting Up Example Repository ==="
    
    # Create and initialize test repository
    local repo_path="/tmp/git_cicd_demo"
    rm -rf "$repo_path"
    mkdir -p "$repo_path"
    cd "$repo_path"
    git init
    
    # Create project structure
    mkdir -p {src,tests,.github/workflows}
    
    # Create sample Python application
    cat << 'EOF' > src/app.py
def add(a: int, b: int) -> int:
    return a + b

def subtract(a: int, b: int) -> int:
    return a - b

if __name__ == "__main__":
    print(f"2 + 2 = {add(2, 2)}")
EOF
    
    # Create tests
    cat << 'EOF' > tests/test_app.py
import pytest
from src.app import add, subtract

def test_add():
    assert add(2, 2) == 4
    assert add(-1, 1) == 0

def test_subtract():
    assert subtract(5, 3) == 2
    assert subtract(1, 1) == 0
EOF
    
    # Create requirements.txt
    cat << 'EOF' > requirements.txt
pytest==7.4.0
pytest-cov==4.1.0
flake8==6.1.0
black==23.7.0
mypy==1.5.1
EOF
    
    # Initial commit
    git add .
    git commit -m "feat: initial commit"
    
    echo "Repository created at $repo_path"
}

# -----------------------------------------------------------------------------
# Function: setup_github_actions
# Purpose: Create GitHub Actions workflow configurations
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
setup_github_actions() {
    echo -e "\n=== Setting Up GitHub Actions ==="
    
    # Create main workflow
    cat << 'EOF' > .github/workflows/main.yml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: [3.9, 3.10, 3.11]

    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python ${{ matrix.python-version }}
      uses: actions/setup-python@v4
      with:
        python-version: ${{ matrix.python-version }}
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
    
    - name: Check code formatting
      run: |
        black --check src tests
    
    - name: Lint with flake8
      run: |
        flake8 src tests --max-line-length=88
    
    - name: Type check with mypy
      run: |
        mypy src tests
    
    - name: Run tests with coverage
      run: |
        pytest tests/ --cov=src --cov-report=xml
    
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage.xml

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'
    
    - name: Build package
      run: |
        pip install build
        python -m build
    
    - name: Publish to PyPI
      if: startsWith(github.ref, 'refs/tags/v')
      uses: pypa/gh-action-pypi-publish@release/v1
      with:
        password: ${{ secrets.PYPI_API_TOKEN }}
EOF
    
    # Create release workflow
    cat << 'EOF' > .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
      with:
        fetch-depth: 0
    
    - name: Generate changelog
      id: changelog
      uses: github-changelog-generator/github-changelog-generator@v1
      with:
        token: ${{ secrets.GITHUB_TOKEN }}
        future-release: ${{ github.ref_name }}
    
    - name: Create Release
      uses: softprops/action-gh-release@v1
      with:
        body_path: CHANGELOG.md
        draft: false
        prerelease: false
EOF
    
    git add .github
    git commit -m "ci: add GitHub Actions workflows"
}

# -----------------------------------------------------------------------------
# Function: setup_gitlab_ci
# Purpose: Create GitLab CI configuration
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
setup_gitlab_ci() {
    echo -e "\n=== Setting Up GitLab CI ==="
    
    cat << 'EOF' > .gitlab-ci.yml
image: python:3.11

variables:
  PIP_CACHE_DIR: "$CI_PROJECT_DIR/.pip-cache"

cache:
  paths:
    - .pip-cache/
    - .pytest_cache/
    - .mypy_cache/

stages:
  - test
  - build
  - deploy

before_script:
  - python -V
  - pip install -r requirements.txt

test:
  stage: test
  script:
    - black --check src tests
    - flake8 src tests --max-line-length=88
    - mypy src tests
    - pytest tests/ --cov=src --cov-report=xml
  coverage: '/TOTAL.+ ([0-9]{1,3}%)/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml

build:
  stage: build
  script:
    - pip install build
    - python -m build
  artifacts:
    paths:
      - dist/*
  only:
    - tags

deploy:
  stage: deploy
  script:
    - pip install twine
    - TWINE_PASSWORD=${CI_JOB_TOKEN} TWINE_USERNAME=gitlab-ci-token
      python -m twine upload --repository-url ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/pypi dist/*
  only:
    - tags
EOF
    
    git add .gitlab-ci.yml
    git commit -m "ci: add GitLab CI configuration"
}

# -----------------------------------------------------------------------------
# Function: setup_jenkins_pipeline
# Purpose: Create Jenkins pipeline configuration
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
setup_jenkins_pipeline() {
    echo -e "\n=== Setting Up Jenkins Pipeline ==="
    
    cat << 'EOF' > Jenkinsfile
pipeline {
    agent {
        docker {
            image 'python:3.11'
            args '-v $HOME/.cache:/root/.cache'
        }
    }
    
    environment {
        PYTHON_VERSION = '3.11'
        PIP_CACHE_DIR = '/root/.cache/pip'
    }
    
    stages {
        stage('Setup') {
            steps {
                sh 'python -m pip install --upgrade pip'
                sh 'pip install -r requirements.txt'
            }
        }
        
        stage('Code Quality') {
            parallel {
                stage('Format Check') {
                    steps {
                        sh 'black --check src tests'
                    }
                }
                stage('Lint') {
                    steps {
                        sh 'flake8 src tests --max-line-length=88'
                    }
                }
                stage('Type Check') {
                    steps {
                        sh 'mypy src tests'
                    }
                }
            }
        }
        
        stage('Test') {
            steps {
                sh 'pytest tests/ --cov=src --cov-report=xml --junitxml=test-results.xml'
            }
            post {
                always {
                    junit 'test-results.xml'
                    cobertura coberturaReportFile: 'coverage.xml'
                }
            }
        }
        
        stage('Build') {
            when {
                tag "v*"
            }
            steps {
                sh 'pip install build'
                sh 'python -m build'
            }
        }
        
        stage('Deploy') {
            when {
                tag "v*"
            }
            environment {
                TWINE_USERNAME = credentials('pypi-username')
                TWINE_PASSWORD = credentials('pypi-password')
            }
            steps {
                sh 'pip install twine'
                sh 'python -m twine upload dist/*'
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
EOF
    
    git add Jenkinsfile
    git commit -m "ci: add Jenkins pipeline configuration"
}

# -----------------------------------------------------------------------------
# Function: create_ci_scripts
# Purpose: Create CI helper scripts
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
create_ci_scripts() {
    echo -e "\n=== Creating CI Helper Scripts ==="
    
    mkdir -p scripts/ci
    
    # Create version bump script
    cat << 'EOF' > scripts/ci/bump-version.sh
#!/bin/bash
set -euo pipefail

# Get current version from src/app.py
current_version=$(grep -oP '__version__ = "\K[^"]+' src/app.py)
echo "Current version: $current_version"

# Determine new version
case ${1:-patch} in
    major)
        new_version=$(echo "$current_version" | awk -F. '{$1++; $2=0; $3=0; print $1"."$2"."$3}')
        ;;
    minor)
        new_version=$(echo "$current_version" | awk -F. '{$2++; $3=0; print $1"."$2"."$3}')
        ;;
    patch)
        new_version=$(echo "$current_version" | awk -F. '{$3++; print $1"."$2"."$3}')
        ;;
    *)
        echo "Invalid version type. Use major, minor, or patch"
        exit 1
        ;;
esac

echo "New version: $new_version"

# Update version in files
sed -i.bak "s/__version__ = \"$current_version\"/__version__ = \"$new_version\"/" src/app.py
rm -f src/app.py.bak

# Create git tag
git add src/app.py
git commit -m "chore: bump version to $new_version"
git tag -a "v$new_version" -m "Release version $new_version"

echo "Version bumped and tagged"
EOF
    
    # Create release script
    cat << 'EOF' > scripts/ci/create-release.sh
#!/bin/bash
set -euo pipefail

# Ensure we're on main branch
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$current_branch" != "main" ]; then
    echo "Must be on main branch to create release"
    exit 1
fi

# Ensure working directory is clean
if ! git diff-index --quiet HEAD --; then
    echo "Working directory must be clean"
    exit 1
fi

# Get version type
version_type=${1:-patch}

# Bump version
./scripts/ci/bump-version.sh "$version_type"

# Push changes
git push origin main --tags

echo "Release created and pushed"
EOF
    
    # Create CI environment setup script
    cat << 'EOF' > scripts/ci/setup-ci-env.sh
#!/bin/bash
set -euo pipefail

# Create Python virtual environment
python -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Install pre-commit hooks
if [ -f .pre-commit-config.yaml ]; then
    pip install pre-commit
    pre-commit install
fi

# Setup git config
git config --local user.name "CI Bot"
git config --local user.email "ci@example.com"

echo "CI environment setup complete"
EOF
    
    # Make scripts executable
    chmod +x scripts/ci/*.sh
    
    # Add to git
    git add scripts/ci
    git commit -m "ci: add CI helper scripts"
}

# -----------------------------------------------------------------------------
# Function: demonstrate_ci_workflow
# Purpose: Demonstrate CI workflow
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_ci_workflow() {
    echo -e "\n=== Demonstrating CI Workflow ==="
    
    # Create feature branch
    git checkout -b feature/add-multiply
    
    # Add new feature
    echo -e "\ndef multiply(a: int, b: int) -> int:\n    return a * b" >> src/app.py
    echo -e "\ndef test_multiply():\n    assert multiply(2, 3) == 6" >> tests/test_app.py
    
    # Commit changes
    git add .
    git commit -m "feat: add multiply function"
    
    # Show CI workflow
    echo -e "\nTypical CI workflow:"
    echo "1. Push feature branch"
    echo "2. CI runs tests and checks"
    echo "3. Create pull request"
    echo "4. Review and merge"
    echo "5. CI deploys to staging"
    echo "6. Create release"
    echo "7. CI deploys to production"
}

# =============================================================================
# Main Script
# =============================================================================

main() {
    echo "Starting CI/CD integration demonstration..."
    
    # Set up example repository
    setup_example_repo
    
    # Set up CI configurations
    setup_github_actions
    setup_gitlab_ci
    setup_jenkins_pipeline
    
    # Create CI scripts
    create_ci_scripts
    
    # Demonstrate workflow
    demonstrate_ci_workflow
    
    echo -e "\nCI/CD integration demonstration completed."
    echo "Example repository is at /tmp/git_cicd_demo"
}

# Run main function
main
