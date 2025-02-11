# Modern Shell Tools

This module covers modern alternatives to traditional shell tools and contemporary shell development practices.

## Topics Covered

1. **Modern CLI Tools**
   - `fd` (find alternative)
   - `ripgrep` (grep alternative)
   - `bat` (cat alternative)
   - `exa` (ls alternative)
   - `delta` (diff alternative)
   - `fzf` (fuzzy finder)
   - `zoxide` (cd alternative)

2. **Shell Frameworks**
   - Oh My Zsh
   - Prezto
   - Fish shell features
   - Starship prompt
   - Powerlevel10k

3. **Terminal Multiplexers**
   - tmux basics
   - Screen usage
   - Window management
   - Session handling
   - Custom configurations

4. **Development Tools**
   - direnv
   - asdf version manager
   - shellcheck
   - shell-format
   - watchexec

5. **Productivity Tools**
   - autojump
   - thefuck
   - tldr
   - cheat.sh
   - hub/gh (GitHub CLI)

## Examples in this Module

1. `01_modern_alternatives.sh`: Modern CLI tool usage
   - File finding with fd
   - Text search with ripgrep
   - File viewing with bat
   - Directory listing with exa
   - Fuzzy finding with fzf

2. `02_shell_frameworks.sh`: Shell framework configuration
   - Oh My Zsh setup
   - Plugin management
   - Theme customization
   - Framework features

3. `03_tmux_basics.sh`: Terminal multiplexer usage
   - Session management
   - Window operations
   - Pane handling
   - Custom configurations

4. `04_dev_tools.sh`: Development tool integration
   - Directory-specific environments
   - Version management
   - Code analysis
   - Auto-formatting

5. `05_productivity_tools.sh`: Productivity enhancement
   - Directory jumping
   - Command correction
   - Documentation access
   - GitHub integration

## Tool Installation and Setup

1. **Package Managers**
   ```bash
   # Homebrew (macOS)
   brew install fd ripgrep bat exa fzf

   # APT (Ubuntu/Debian)
   apt install fd-find ripgrep bat exa fzf
   ```

2. **Shell Framework Installation**
   ```bash
   # Oh My Zsh
   sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

   # Prezto
   git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
   ```

3. **Terminal Multiplexer Setup**
   ```bash
   # tmux installation
   brew install tmux

   # Basic configuration
   cat << EOF > ~/.tmux.conf
   set -g mouse on
   set -g base-index 1
   set -g default-terminal "screen-256color"
   EOF
   ```

## Best Practices

1. **Tool Selection**
   - Choose tools that improve workflow
   - Ensure cross-platform compatibility
   - Consider performance impact
   - Maintain backward compatibility

2. **Configuration Management**
   - Use version control for configs
   - Document customizations
   - Share configurations
   - Backup important settings

3. **Integration**
   - Combine tools effectively
   - Create custom aliases
   - Write wrapper functions
   - Automate common tasks

4. **Performance**
   - Monitor startup time
   - Optimize configurations
   - Cache when possible
   - Profile tool usage

## Additional Resources

1. **Documentation**
   - Tool manuals and guides
   - GitHub repositories
   - Community wikis
   - Configuration examples

2. **Communities**
   - Reddit (r/commandline)
   - GitHub discussions
   - Stack Overflow
   - Tool-specific forums

3. **Learning Resources**
   - Online tutorials
   - Video demonstrations
   - Blog posts
   - Conference talks
