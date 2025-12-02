# 🔧 Semyon's Dotfiles

Hey there! 👋 Welcome to my personal configuration files (dotfiles). This is where I keep my Linux setup tidy, organized, and ready to roll.

## 📂 What's Inside?

*   **Shell:** Bash (with custom aliases, functions, and history handling)
*   **Terminal:** Configurations for WezTerm, Ghostty, and Kitty
*   **Editor:** Neovim setup (using lazy.nvim)
*   **System Tools:** git, tmux, htop, btop, neofetch
*   **Prompt:** Starship 🚀

## 🚀 Getting Started

Setting this up on a new machine is super easy.

1.  **Clone the repo:**
    ```bash
    git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
    cd ~/dotfiles
    ```

2.  **Run the installer:**
    ```bash
    ./install.sh
    ```

The script will automatically:
*   **Discover** all configuration files in the repo.
*   **Back up** your existing configs to a timestamped folder (safety first! 🛡️).
*   **Symlink** the new ones into place.

## 🛠️ Structure & Usage

*   **Root files:** Files in the root directory (e.g., `bashrc`, `gitconfig`) are symlinked to `~/.<filename>` (e.g., `~/.bashrc`).
*   **Config folder:** Items in `config/` are symlinked to `~/.config/<itemname>`.

### Adding new files
Just drop a file in the root or `config/` directory and run `./install.sh` again. It's idempotent, so it will only link what's missing!

## 📜 License

MIT. Feel free to fork this, steal code, or learn from my messy experiments. Happy hacking! 💻