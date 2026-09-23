#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

DRY_RUN=false
BACKUP_DIR=""
PROFILE=""
PACKAGES=()
PACKAGES_EXPLICIT=false

profile_packages() {
    case "$1" in
        server)
            echo "home claude server"
            ;;
        pc)
            echo "home claude hyprland noctalia pc"
            ;;
        laptop)
            echo "home claude hyprland noctalia laptop"
            ;;
        nas)
            echo "home claude"
            ;;
        minimal)
            echo "home claude"
            ;;
        *)
            error "Unknown profile: $1"
            ;;
    esac
}

detect_profile() {
    local host
    host="$(hostname 2>/dev/null || echo unknown)"

    case "$host" in
        server)
            echo "server"
            ;;
        semyon-pc-cachy|pc|winpc|semyons-pc)
            echo "pc"
            ;;
        semyons-laptop|cachy-laptop|laptop)
            echo "laptop"
            ;;
        nas)
            echo "nas"
            ;;
        *)
            echo "minimal"
            ;;
    esac
}

resolve_packages() {
    local packages package

    if [[ ${#PACKAGES[@]} -eq 0 ]]; then
        [[ "$PACKAGES_EXPLICIT" == false ]] || error "--packages list is empty"
        [[ -n "$PROFILE" ]] || PROFILE="$(detect_profile)"
        # capture first so an unknown profile fails here instead of becoming package names
        packages="$(profile_packages "$PROFILE")" || error "Unknown profile: $PROFILE"
        read -r -a PACKAGES <<< "$packages"
        [[ ${#PACKAGES[@]} -gt 0 ]] || error "Profile resolved to no packages: $PROFILE"
    fi

    for package in "${PACKAGES[@]}"; do
        # only plain top-level package names, not paths or repo support dirs
        case "$package" in
            ''|.*|*/*|lib|docs|tests|skills)
                error "Invalid package name: '$package'" ;;
        esac
        [[ -d "$SCRIPT_DIR/$package" ]] || error "Package not found: $package"
    done
}

rollback() {
    if [[ -n "$BACKUP_DIR" && -d "$BACKUP_DIR" ]]; then
        warn "Rolling back changes..."
        cd "$SCRIPT_DIR"
        if [[ ${#PACKAGES[@]} -gt 0 ]]; then
            stow --no-folding -D "${PACKAGES[@]}" 2>/dev/null || true
        fi

        if [[ -n "$(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
            cp -a "$BACKUP_DIR"/. "$HOME"/ 2>/dev/null || true
            success "Restored files from backup"
        fi

        error "Setup failed. Original files restored."
    else
        error "Setup failed. No backup to restore."
    fi
}

ensure_stow() {
    if command -v stow &>/dev/null; then
        return 0
    fi

    local os base_os
    os="$(detect_os)"
    base_os="$(get_base_os)"

    if [[ "$DRY_RUN" == true ]]; then
        error "stow not installed. Install it first, dry runs never install packages."
    fi

    info "Installing stow..."

    case "$base_os" in
        arch|endeavouros|manjaro|cachyos)
            sudo pacman -S --noconfirm stow ;;
        ubuntu|debian|pop|linuxmint)
            sudo apt update && sudo apt install -y stow ;;
        fedora|rhel|centos)
            sudo dnf install -y stow ;;
        opensuse*)
            sudo zypper install -y stow ;;
        macos)
            command -v brew &>/dev/null || error "Homebrew required. Install from https://brew.sh"
            brew install stow ;;
        *)
            error "Unsupported OS: $os. Install stow manually." ;;
    esac

    success "stow installed"
}

package_conflicts() {
    local package source rel target

    for package in "${PACKAGES[@]}"; do
        [[ -d "$SCRIPT_DIR/$package" ]] || error "Package not found: $package"

        while IFS= read -r source; do
            rel="${source#"$SCRIPT_DIR/$package/"}"
            target="$HOME/$rel"
            if [[ -e "$target" && ! -L "$target" ]]; then
                printf '%s\n' "$rel"
            fi
        done < <(package_files "$package")
    done | sort -u
}

package_files() {
    local package=$1 source rel base

    while IFS= read -r source; do
        rel="${source#"$SCRIPT_DIR/$package/"}"
        base="$(basename "$rel")"

        case "$rel" in
            README|README.*|LICENSE|COPYING|.stow-local-ignore)
                continue ;;
        esac

        case "$base" in
            .gitignore)
                continue ;;
        esac

        printf '%s\n' "$source"
    done < <(find "$SCRIPT_DIR/$package" \( -type f -o -type l \))
}

backup_existing() {
    local files_to_backup=()
    local file

    mapfile -t files_to_backup < <(package_conflicts)

    if [[ ${#files_to_backup[@]} -eq 0 ]]; then
        info "No conflicting files found"
        return 0
    fi

    BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY RUN] Would backup ${#files_to_backup[@]} files to $BACKUP_DIR"
        return 0
    fi

    warn "Found ${#files_to_backup[@]} conflicting files"
    read -p "Backup these files? (y/n) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mkdir -p "$BACKUP_DIR"
        for file in "${files_to_backup[@]}"; do
            mkdir -p "$BACKUP_DIR/$(dirname "$file")"
            mv "$HOME/$file" "$BACKUP_DIR/$file"
        done
        success "Backup created at $BACKUP_DIR"
    else
        error "Cannot proceed with existing files"
    fi
}

deploy_dotfiles() {
    resolve_packages

    info "Deploying dotfiles from $SCRIPT_DIR"
    if [[ -n "$PROFILE" ]]; then
        info "Profile: $PROFILE"
    fi
    info "Packages: ${PACKAGES[*]}"

    cd "$SCRIPT_DIR"

    if stow --no-folding -n "${PACKAGES[@]}" 2>&1 | grep -q "conflict"; then
        warn "Conflicts detected"
        backup_existing
    fi

    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY RUN] Simulating deployment..."
        stow --no-folding -n -v "${PACKAGES[@]}" || true
        return 0
    fi

    stow --no-folding "${PACKAGES[@]}"
    success "Dotfiles deployed"
}

verify_installation() {
    local verified=0 failed=0 package source rel target

    info "Verifying installation..."

    for package in "${PACKAGES[@]}"; do
        while IFS= read -r source; do
            rel="${source#"$SCRIPT_DIR/$package/"}"
            target="$HOME/$rel"
            if [[ -L "$target" ]]; then
                ((verified+=1))
            else
                ((failed+=1))
            fi
        done < <(package_files "$package")
    done

    echo "  Verified symlinks: $verified"
    if [[ $failed -gt 0 ]]; then
        echo "  Missing or unmanaged paths: $failed"
    fi
}

print_help() {
    cat <<'EOF'
Usage: ./setup.sh [OPTIONS]

Options:
  --profile NAME       Deploy a known profile: server, pc, laptop, nas, minimal
  --packages LIST      Deploy an explicit space/comma-separated package list
  --dry-run, -n        Simulate without making changes
  --help, -h           Show this help

Examples:
  ./setup.sh --profile server
  ./setup.sh --profile pc
  ./setup.sh --profile laptop
  ./setup.sh --packages "home claude"
  ./setup.sh --packages "codex"
EOF
}

main() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run|-n)
                DRY_RUN=true
                shift ;;
            --profile)
                [[ $# -ge 2 ]] || error "--profile requires a value"
                PROFILE="$2"
                shift 2 ;;
            --packages)
                [[ $# -ge 2 ]] || error "--packages requires a value"
                IFS=', ' read -r -a PACKAGES <<< "$2"
                PACKAGES_EXPLICIT=true
                shift 2 ;;
            --help|-h)
                print_help
                exit 0 ;;
            *)
                error "Unknown option: $1" ;;
        esac
    done

    echo ""
    echo "================================"
    echo "  Dotfiles Setup (GNU Stow)"
    echo "================================"
    echo ""

    if [[ "$DRY_RUN" == true ]]; then
        warn "DRY RUN MODE"
    fi

    # errtrace lets the ERR trap fire inside nested functions
    set -E
    trap rollback ERR

    # validate package input before anything can install stow
    resolve_packages
    ensure_stow
    echo ""
    deploy_dotfiles
    echo ""

    if [[ "$DRY_RUN" == false ]]; then
        verify_installation
        trap - ERR
        set +E
        echo ""
        success "Setup complete!"
        info "Restart terminal or run: source ~/.bashrc"
    else
        trap - ERR
        set +E
        success "Dry run complete"
    fi
    echo ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
