#!/bin/bash

# =============================================================================
# Modern Development Tools Examples
# This script demonstrates usage of modern development tools including direnv,
# asdf version manager, and other productivity enhancers.
# =============================================================================

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Function: check_tools
# Purpose: Check if required development tools are installed
# Arguments: None
# Returns: 0 if all tools are available, 1 otherwise
# -----------------------------------------------------------------------------
check_tools() {
    echo "=== Checking Development Tools ==="
    
    local -A tools=(
        ["direnv"]="Directory environment manager"
        ["asdf"]="Version manager"
        ["httpie"]="HTTP client"
        ["jq"]="JSON processor"
        ["yq"]="YAML processor"
    )
    
    local missing=0
    
    for tool in "${!tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            echo "✓ $tool (${tools[$tool]}) is installed"
        else
            echo "✗ $tool (${tools[$tool]}) is NOT installed"
            missing=1
        fi
    done
    
    if ((missing)); then
        echo -e "\nSome tools are missing. Install them with:"
        echo "brew install direnv asdf httpie jq yq  # macOS"
        echo "apt install direnv httpie jq  # Ubuntu/Debian"
        return 1
    fi
    
    return 0
}

# -----------------------------------------------------------------------------
# Function: demonstrate_direnv
# Purpose: Show direnv usage and configuration
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_direnv() {
    echo -e "\n=== direnv Usage Examples ==="
    
    # Create example project structure
    mkdir -p /tmp/direnv_demo/{dev,prod}
    
    # Create .envrc files
    cat << 'EOF' > /tmp/direnv_demo/dev/.envrc
# Development environment variables
export ENV="development"
export API_URL="http://localhost:3000"
export DEBUG="true"
export DB_HOST="localhost"
export DB_PORT="5432"
export DB_NAME="myapp_dev"

# Add local bin to PATH
PATH_add bin

# Load node version
use node 16

# Load Python virtual environment
layout python3

# Load .env file if it exists
dotenv_if_exists
EOF
    
    cat << 'EOF' > /tmp/direnv_demo/prod/.envrc
# Production environment variables
export ENV="production"
export API_URL="https://api.example.com"
export DEBUG="false"
export DB_HOST="db.example.com"
export DB_PORT="5432"
export DB_NAME="myapp_prod"

# Load specific node version
use node 18

# Load specific Python version
use python 3.9
EOF
    
    echo "1. Basic direnv Setup:"
    cat << 'EOF'
# Add to ~/.zshrc or ~/.bashrc:
eval "$(direnv hook zsh)"  # or bash

# Allow .envrc in directory:
direnv allow .

# Edit .envrc:
direnv edit .
EOF
    
    echo -e "\n2. Advanced direnv Features:"
    cat << 'EOF'
# Load different environments:
layout python3          # Create/load Python venv
layout node            # Setup NODE_PATH
layout ruby            # Setup bundle and local gems

# Path manipulation:
PATH_add bin           # Add ./bin to PATH
PATH_add ../scripts    # Add relative path

# Load version managers:
use node 16           # Load specific Node.js version
use python 3.9        # Load specific Python version
use ruby 3.1.0        # Load specific Ruby version

# Load .env files:
dotenv                # Load .env
dotenv_if_exists     # Load .env if it exists
EOF
    
    # Clean up
    rm -rf /tmp/direnv_demo
}

# -----------------------------------------------------------------------------
# Function: demonstrate_asdf
# Purpose: Show asdf version manager usage
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_asdf() {
    echo -e "\n=== asdf Version Manager Examples ==="
    
    cat << 'EOF'
1. Basic Setup:
# Add to ~/.zshrc or ~/.bashrc:
. $(brew --prefix asdf)/libexec/asdf.sh  # macOS
. $HOME/.asdf/asdf.sh                    # Linux

2. Plugin Management:
# List all plugins
asdf plugin list all

# Add plugins
asdf plugin add nodejs
asdf plugin add python
asdf plugin add ruby
asdf plugin add golang

3. Version Management:
# List available versions
asdf list all nodejs
asdf list all python

# Install versions
asdf install nodejs 16.15.0
asdf install python 3.9.7

# Set versions
asdf global nodejs 16.15.0    # Set global version
asdf local nodejs 14.17.0     # Set local version
asdf shell nodejs 18.0.0      # Set shell version

4. Project Configuration (.tool-versions):
nodejs 16.15.0
python 3.9.7
ruby 3.1.0
golang 1.18.2

5. Common Commands:
asdf current              # Show current versions
asdf list                 # List installed versions
asdf uninstall nodejs 14  # Uninstall version
asdf update              # Update asdf itself
asdf plugin update --all  # Update all plugins
EOF
}

# -----------------------------------------------------------------------------
# Function: demonstrate_httpie
# Purpose: Show HTTPie usage examples
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_httpie() {
    echo -e "\n=== HTTPie Usage Examples ==="
    
    cat << 'EOF'
1. Basic Requests:
# GET request
http GET api.example.com/users

# POST request
http POST api.example.com/users name=John age:=30

# PUT request
http PUT api.example.com/users/1 name=John

# DELETE request
http DELETE api.example.com/users/1

2. Headers and Authentication:
# Custom headers
http example.com X-API-Token:123 User-Agent:CustomApp

# Basic auth
http -a username:password example.com

# Bearer token
http example.com Authorization:"Bearer token123"

3. Request Data:
# JSON data
http POST api.example.com/users \
    name=John \
    age:=30 \
    roles:='["admin", "user"]'

# Form data
http -f POST api.example.com/users \
    name='John Doe' \
    file@~/file.txt

4. Output Formatting:
http --pretty=all    # Colored, formatted output
http --print=HBhb    # Print request and response headers/body
http --download      # Download file
http --session=user  # Save and use session

5. Advanced Features:
# Offline mode
http --offline POST server.com/users name=John

# Certificate validation
http --verify=no https://example.com
http --cert=client.pem https://example.com
EOF
}

# -----------------------------------------------------------------------------
# Function: demonstrate_json_tools
# Purpose: Show jq and yq usage examples
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_json_tools() {
    echo -e "\n=== JSON/YAML Tools Examples ==="
    
    # Create example JSON
    cat << 'EOF' > /tmp/example.json
{
  "name": "John Doe",
  "age": 30,
  "address": {
    "street": "123 Main St",
    "city": "Example City",
    "country": "Example Country"
  },
  "contacts": [
    {
      "type": "email",
      "value": "john@example.com"
    },
    {
      "type": "phone",
      "value": "+1234567890"
    }
  ]
}
EOF
    
    # Create example YAML
    cat << 'EOF' > /tmp/example.yaml
name: John Doe
age: 30
address:
  street: 123 Main St
  city: Example City
  country: Example Country
contacts:
  - type: email
    value: john@example.com
  - type: phone
    value: "+1234567890"
EOF
    
    echo "1. jq Examples:"
    cat << 'EOF'
# Basic filters
jq .name                     # Get value
jq '.address.city'          # Nested value
jq '.contacts[0]'           # Array element
jq '.contacts[].type'       # Array values

# Transformations
jq '{name, age}'            # Create new object
jq 'map(select(.age > 25))' # Filter array
jq 'del(.address)'          # Delete field
jq '.contacts | length'     # Count array items

# Complex operations
jq '.contacts[] | select(.type == "email").value'
jq 'walk(if type == "string" then ascii_upcase else . end)'
EOF
    
    echo -e "\n2. yq Examples:"
    cat << 'EOF'
# Read YAML
yq '.name' file.yaml
yq '.address.city' file.yaml
yq '.contacts[0].value' file.yaml

# Convert formats
yq -o=json file.yaml        # YAML to JSON
yq -P file.json            # JSON to YAML

# Modify YAML
yq '.age = 31' -i file.yaml
yq '.contacts += {"type": "web"}' file.yaml
yq 'del(.address)' file.yaml

# Multiple files
yq eval-all '. as $item ireduce ({}; . * $item)' *.yaml
EOF
    
    # Clean up
    rm /tmp/example.{json,yaml}
}

# =============================================================================
# Main Script
# =============================================================================

main() {
    echo "Starting development tools demonstrations..."
    
    # Check for required tools
    check_tools
    
    # Run all demonstrations
    demonstrate_direnv
    demonstrate_asdf
    demonstrate_httpie
    demonstrate_json_tools
    
    echo -e "\nDevelopment tools demonstrations completed."
}

# Run main function
main
