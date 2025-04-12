# Rofi Theme Manager

A simple, efficient theme manager for Rofi with bash completion support.

## DISCLAIMER

Docs were written primarily by an AI, as I don't have time to do it from scratch.
While they do seem fine at first glance there might be issues in the install guide.

## Features

- **Theme Switching**: Easily switch between available Rofi themes
- **Theme Navigation**: Cycle through themes with `next` and `prev` commands
- **Theme Listing**: View all available themes with the `list` command
- **Current Theme**: Check which theme is currently active
- **Bash Completion**: Tab completion for commands and theme names
- **Clean Interface**: Simple command-line interface with helpful messages

## Commands

```
Usage: rofi-theme-manager [COMMAND] [THEME_NAME]

Options:
  -h, --help            Show this help message

Commands:
  list                  List all available themes
  current               Show current theme
  next                  Switch to next theme
  prev                  Switch to previous theme
  set, switch THEME     Switch to specific theme
  themes                List all themes (machine-friendly format for completion)

Examples:
  rofi-theme-manager list
  rofi-theme-manager current
  rofi-theme-manager next
  rofi-theme-manager prev
  rofi-theme-manager set arthur
  rofi-theme-manager switch arthur
```

## Installation

### NixOS (Traditional)

1. Add the following to your NixOS configuration file (typically `/etc/nixos/configuration.nix`):

```nix
{ config, pkgs, ... }:

let
  custom_packages = import /path/to/custom_packages.nix { inherit config pkgs; };
in
{
  # Import the rofi-theme-manager configuration
  imports = [ custom_packages ];
  
  # Make sure Rofi is installed (if not already)
  environment.systemPackages = with pkgs; [
    rofi
  ];
  
  # Enable bash completion
  programs.bash.completion.enable = true;
}
```

2. Place the `custom_packages.nix` file in the specified location
3. Rebuild your NixOS configuration:

```bash
sudo nixos-rebuild switch
```

### NixOS (Flakes)

TODO: Add instructions for using the package with flakes

### Ubuntu/Debian

TODO: Add instructions for installing on Ubuntu/Debian systems

## Configuration

The Rofi Theme Manager stores:

- Current theme in `~/.config/rofi/current_theme`
- Rofi configuration in `~/.config/rofi/config.rasi`

These files are created automatically when you set a theme.

## Themes Collection

The package comes bundled with the [Rofi Themes Collection](https://github.com/newmanls/rofi-themes-collection), which provides a variety of visually appealing themes.

## Usage Examples

Set a specific theme:

```bash
rofi-theme-manager set arthur
```

Cycle to the next theme:

```bash
rofi-theme-manager next
```

See which theme is currently active:

```bash
rofi-theme-manager current
```

List all available themes:

```bash
rofi-theme-manager list
```
