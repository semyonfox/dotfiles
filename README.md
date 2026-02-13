# semyon's dotfiles

hey there! welcome to my personal configuration files. this is where i keep my linux setup tidy, organized, and ready to roll.

## table of contents
- [what's inside](#whats-inside)
- [getting started](#getting-started)
- [structure and usage](#structure-and-usage)
- [dependencies](#dependencies)
- [switching to zsh](#switching-to-zsh)
- [managing dotfiles](#managing-dotfiles)
- [claude code configuration](#claude-code-configuration)
- [troubleshooting](#troubleshooting)
- [wsl2 compatibility](#wsl2-compatibility)
- [license](#license)

## what's inside

*   **shell** - bash & zsh with custom aliases, functions, and history handling
*   **terminal** - configurations for wezterm & ghostty
*   **editor** - neovim setup using lazy.nvim
*   **system tools** - git, tmux, htop, btop, neofetch
*   **prompt** - starship
*   **hyprland** - Wayland window manager configuration (HyDE Catppuccin Mocha theme)
*   **waybar** - status bar configuration (HyDE-generated)

## getting started

### one-command install (recommended)
```bash
git clone https://github.com/semyonfox/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

the installer will:
- detect your OS (arch, ubuntu, fedora, macos, wsl2)
- prompt you for each step:
  1. install dependencies? (core tools + CLI tools)
  2. install optional CLI tools? (thefuck, pyenv)
  3. deploy dotfiles with stow?
  4. switch to zsh?
  5. install zsh enhancements? (oh-my-zsh - asked when switching to zsh)
- backup any conflicting files automatically
- safe to re-run if something fails

**installation flow:**
```
1. Install dependencies? (y/n)
   -> installs: zsh, git, tmux, neovim, stow, eza, bat, fd, ripgrep, etc.
2. Install optional CLI tools? (y/n)
   -> thefuck, pyenv
3. Deploy dotfiles? (y/n)
   -> creates symlinks with stow
4. Switch to zsh? (y/n)
   -> if yes, asks: install oh-my-zsh? (y/n) [y]
   -> changes default shell
```

### alternative: individual scripts
if you prefer to run things separately:
```bash
./install-deps.sh  # just install packages
./setup.sh         # just deploy dotfiles
./switch-to-zsh.sh # just switch shell
```

### manual install
```bash
# install stow first, then:
git clone https://github.com/semyonfox/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow home
```

### what gets installed

when you run `./install.sh` or `stow home`, these configs are symlinked:

**shell configs:**
- bash: `.bashrc`, `.bash_aliases`, `.bash_functions`, `.bash_profile`, `.profile`
- zsh: `.zshrc`, `.zsh_aliases`, `.zsh_functions`, `.zprofile`

**application configs:**
- git: `.gitconfig`
- tmux: `.tmux.conf`
- terminal: `.wezterm.lua`
- hyprland: `.config/hypr/` (window manager)
- waybar: `.config/waybar/` (status bar)
- other: `.config/btop`, `.config/ghostty`, `.config/htop`, `.config/kitty`, `.config/neofetch`, `.config/starship.toml`

## structure and usage

this repo uses [GNU Stow](https://www.gnu.org/software/stow/) for symlink management:

*   **home/** - package containing all dotfiles (`.bashrc`, `.config/nvim`, etc.)
*   when you run `stow home`, it creates symlinks in `~` that point to files in `home/`
*   **example**: `home/.bashrc` → `~/.bashrc`

## dependencies

### what install-deps.sh installs

**core tools (always installed):**
- `zsh` - modern shell with powerful features
- `git` - version control
- `tmux` - terminal multiplexer
- `neovim` - modern vim-based editor
- `stow` - symlink manager for dotfiles
- `curl`, `wget` - download tools

**modern cli tools (always installed):**
- `eza` - modern replacement for ls
- `bat` - cat with syntax highlighting
- `fd` - modern find alternative
- `ripgrep` - faster grep
- `fzf` - fuzzy finder
- `zoxide` - smarter cd command
- `starship` - customizable prompt

**optional (prompted during install):**
- `oh-my-zsh` - zsh plugin framework
- `thefuck` - command correction tool
- `pyenv` - python version manager
- `tpm` - tmux plugin manager (auto-installed)

**terminal emulators (configs included, manual install):**
- wezterm - config: `.wezterm.lua`
- ghostty - config: `.config/ghostty/`
- kitty - config: `.config/kitty/`
- note: these are skipped in wsl2 (use windows terminal)

### manual installations needed

after running the setup scripts, you may want to install:

1. **terminal emulator** (if not using wsl2)
   - [wezterm](https://wezfurlong.org/wezterm/) - recommended
   - [ghostty](https://ghostty.org/) - fast and minimal
   - [kitty](https://sw.kovidgoyal.net/kitty/) - gpu-accelerated

2. **nerd font** for icons in terminal
   ```bash
   # arch
   sudo pacman -S ttf-jetbrains-mono-nerd

   # ubuntu/debian
   mkdir -p ~/.local/share/fonts
   cd ~/.local/share/fonts
   curl -fLO https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip
   unzip JetBrainsMono.zip && rm JetBrainsMono.zip
   fc-cache -fv
   ```

3. **tmux plugins** (after setup)
   - open tmux and press `prefix + I` (ctrl-b then I)
   - tpm will install configured plugins automatically

## switching to zsh

want to use zsh instead of bash? we've got you covered:

1. **install zsh**
   ```bash
   sudo pacman -S zsh zsh-completions
   ```

2. **switch your default shell**
   ```bash
   ./switch-to-zsh.sh
   ```
   or manually:
   ```bash
   chsh -s $(which zsh)
   ```

3. **log out and log back in** for the changes to take effect

the zsh configs mirror all the bash functionality with zsh-specific improvements like better completion and shared history across sessions.

## hyprland setup (optional)

if you're on omarchy or using hyprland, these dotfiles include a complete hyprland + waybar configuration:

**to deploy hyprland configuration:**
```bash
cd ~/dotfiles
stow hyprland waybar
```

this includes:
- **hyprland** - complete window manager setup with HyDE framework (Catppuccin Mocha theme)
- **waybar** - status bar (dynamically generated by HyDE)

**credits:**
- [HyDE (HyprDots)](https://github.com/prasanthrangan/hyprdots) - Hyprland framework and Catppuccin Mocha theme
- [Omarchy](https://omarchy.org/) - theme management system (keeps mako notifications in sync with system theme)

**note on omarchy integration:**
the mako notification daemon config is symlinked from omarchy's theme system, so notifications automatically match your system theme. this is intentional - we keep the window manager configuration (hyprland) separate from the theme management system (omarchy).

for details, see [hyprland/README.md](hyprland/README.md) and [waybar/README.md](waybar/README.md).

## managing dotfiles

**add new configs:**
```bash
# add file to home/ directory
cp ~/.newconfig home/.newconfig
stow home  # create symlink
```

**update existing:**
just edit files in the repo, changes are instant (they're symlinked)

**remove symlinks:**
```bash
stow -D home  # removes all symlinks
```

**re-stow:**
```bash
stow -R home  # recreate symlinks
```

**scripts available:**
- `install.sh` - unified installer (recommended)
- `install-deps.sh` - standalone dependency installer
- `setup.sh` - standalone stow deployment
- `switch-to-zsh.sh` - standalone shell switcher

## claude code configuration

if you use [claude code](https://claude.ai/code), there's a separate `claude/` package with global instructions and configuration:

```bash
stow claude
```

this creates symlinks for:
- `~/.claude/CLAUDE.md` - global instructions for claude code
- `~/.claude/agents/` - agent configurations (local)
- `~/.claude/plugins/` - plugin configurations (local)

sensitive files (`.claude.json`, `.credentials.json`, cache, history) are gitignored and managed locally.

each project can override the global instructions by adding a `CLAUDE.md` at its root. see [claude/README.md](claude/README.md) for details.

## troubleshooting

**conflict errors when stowing?**
```bash
# backup existing configs first
mkdir -p ~/backup
mv ~/.bashrc ~/.gitconfig ~/.tmux.conf ~/backup/

# then try stowing again
stow home
```

**check if symlinks are working:**
```bash
# verify all symlinks are valid
for file in .bashrc .gitconfig .tmux.conf .wezterm.lua; do
  if [ -L ~/"$file" ]; then
    echo "$file: symlinked to $(readlink ~/$file)"
  else
    echo "$file: not a symlink"
  fi
done
```

**restore original configs:**
```bash
cd ~/dotfiles
stow -D home  # remove all symlinks
cp ~/backup/* ~/  # restore from backup
```

## wsl2 compatibility

these dotfiles are **fully compatible with wsl2** (windows subsystem for linux). the setup scripts automatically detect wsl2 and adjust accordingly.

### wsl2 setup guide

1. **install wsl2 with ubuntu/debian/arch**
   ```powershell
   # in powershell (windows)
   wsl --install -d Ubuntu
   # or for arch: wsl --install -d Arch
   ```

2. **install dotfiles in wsl**
   ```bash
   # inside wsl terminal
   git clone https://github.com/semyonfox/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ./install.sh  # automatically detects wsl2 and adjusts
   ```

### wsl2 specific notes

**what works:**
- all shell configurations (bash/zsh)
- all cli tools (eza, bat, fd, zoxide, starship, etc.)
- tmux with full functionality
- neovim and all editor configs
- git configurations

**what's different in wsl2:**
- **terminal emulators**: use windows terminal instead of wezterm/ghostty/kitty
  - install from microsoft store: `winget install Microsoft.WindowsTerminal`
  - configs for linux terminal emulators are skipped automatically
- **gui applications**: require x server (vcxsrv/x410) or use wslg (built-in on windows 11)
- **systemd**: available on ubuntu 22.04+ in wsl2, may need enabling

**wsl2 optimizations:**

1. **configure .wslconfig** (optional, on windows side)
   create `C:\Users\YourName\.wslconfig`:
   ```ini
   [wsl2]
   memory=8GB           # limit memory usage
   processors=4         # limit cpu cores
   swap=2GB
   localhostForwarding=true
   ```

2. **configure wsl.conf** (optional, in wsl)
   edit `/etc/wsl.conf`:
   ```ini
   [boot]
   systemd=true         # enable systemd (ubuntu 22.04+)

   [interop]
   appendWindowsPath=false  # optional: don't pollute PATH with windows dirs

   [network]
   generateResolvConf=true
   ```

3. **windows terminal integration**
   - configs are symlinked and work immediately
   - starship prompt works perfectly in windows terminal
   - font recommendation: install a nerd font (jetbrains mono nf, fira code nf)

4. **performance tips**
   - keep project files in linux filesystem (`~/projects`) not windows (`/mnt/c/`)
   - use git from linux, not windows
   - wsl2 has near-native linux performance when files are in `~`

**known issues:**
- clipboard integration: install `xclip` or use windows terminal's native clipboard
- some aliases reference `pacman` (arch-specific) - they'll error on ubuntu/debian (harmless)
- `.wezterm.lua` config exists but wezterm should be run on windows side, not in wsl

**recommended setup:**
```bash
# 1. install windows terminal
# 2. set default profile to your wsl distro
# 3. install a nerd font in windows
# 4. run the dotfiles setup as shown above
# 5. configure windows terminal to use installed font
```

for more wsl2 help: https://learn.microsoft.com/en-us/windows/wsl/

## license

mit - feel free to fork this, steal code, or learn from my messy experiments.

## acknowledgements

big thanks to these folks for some great inspiration:
*   [omerxx](https://github.com/omerxx/dotfiles) for dotfiles inspiration
*   [axenide](https://github.com/starship/starship/discussions/1107#discussioncomment-13953875) for starship config ideas
