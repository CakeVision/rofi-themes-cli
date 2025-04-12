# custom_packages.nix
{ config, pkgs, lib ? pkgs.lib, ... }:

let
  cmdName = "rofi-theme-manager";

  rofi-theme-manager = pkgs.writeShellScriptBin "${cmdName}" ''
    #!/usr/bin/env bash
    
    PROGRAM_NAME="${cmdName}"
    THEMES_DIR="${themesDir}/share/rofi/themes"
    CONFIG_FILE="$HOME/.config/rofi/config.rasi"
    CURRENT_THEME_FILE="$HOME/.config/rofi/current_theme"
    
    mkdir -p "$HOME/.config/rofi"
    
    get_themes() {
      ls -1 "$THEMES_DIR" | grep "\.rasi$" | sed 's/\.rasi$//'
    }
    
    get_current_theme() {
      if [ -f "$CURRENT_THEME_FILE" ]; then
        cat "$CURRENT_THEME_FILE"
      else
        echo ""
      fi
    }
    
    save_current_theme() {
      echo "$1" > "$CURRENT_THEME_FILE"
    }
    
    set_theme() {
      THEME="$1.rasi"
      
      if [ ! -f "$THEMES_DIR/$THEME" ]; then
        echo "Theme '$1' not found. Use '$PROGRAM_NAME list' to see available themes."
        exit 1
      fi
      
      echo "@theme \"$THEMES_DIR/$THEME\"" > "$CONFIG_FILE"
      save_current_theme "$1"
      echo "Theme set to '$1'"
    }

    show_help() {
      echo "Usage: $PROGRAM_NAME [COMMAND] [THEME_NAME]"
      echo ""
      echo "Options:"
      echo "  -h, --help            Show this help message"
      echo ""
      echo "Commands:"
      echo "  list                  List all available themes"
      echo "  current               Show current theme"
      echo "  next                  Switch to next theme"
      echo "  prev                  Switch to previous theme"
      echo "  set, switch THEME     Switch to specific theme"
      echo "  themes                List all themes (machine-friendly format for completion)"
      echo ""
      echo "Examples:"
      echo "  $PROGRAM_NAME list"
      echo "  $PROGRAM_NAME current"
      echo "  $PROGRAM_NAME next"
      echo "  $PROGRAM_NAME prev"
      echo "  $PROGRAM_NAME set arthur"
      echo "  $PROGRAM_NAME switch arthur"
    }
    
    case "$1" in
      "-h"|"--help")
        show_help
        exit 0
        ;;

      "list")
        echo "Available themes:"
        get_themes
        exit 0
        ;;

      "themes")
        get_themes | tr '\n' ' '
        exit 0
        ;;
        
      "current")
        CURRENT=$(get_current_theme)
        if [ -z "$CURRENT" ]; then
          echo "No theme currently set"
        else
          echo "Current theme: $CURRENT"
        fi
        exit 0
        ;;
        
      "next")
        CURRENT=$(get_current_theme)
        THEMES=($(get_themes))
        
        if [ -z "$CURRENT" ] || [ ''${#THEMES[@]} -eq 0 ]; then
          if [ ''${#THEMES[@]} -gt 0 ]; then
            set_theme "''${THEMES[0]}"
          else
            echo "No themes available"
            exit 1
          fi
        else
          for i in "''${!THEMES[@]}"; do
            if [ "''${THEMES[$i]}" = "$CURRENT" ]; then
              # Get next theme (circular)
              NEXT_INDEX=$(( (i + 1) % ''${#THEMES[@]} ))
              set_theme "''${THEMES[$NEXT_INDEX]}"
              exit 0
            fi
          done
          
          set_theme "''${THEMES[0]}"
        fi
        ;;
        
      "prev")
        CURRENT=$(get_current_theme)
        THEMES=($(get_themes))
        
        if [ -z "$CURRENT" ] || [ ''${#THEMES[@]} -eq 0 ]; then
          if [ ''${#THEMES[@]} -gt 0 ]; then
            set_theme "''${THEMES[0]}"
          else
            echo "No themes available"
            exit 1
          fi
        else
          for i in "''${!THEMES[@]}"; do
            if [ "''${THEMES[$i]}" = "$CURRENT" ]; then
              NEXT_INDEX=$(( (i - 1 + ''${#THEMES[@]}) % ''${#THEMES[@]} ))
              set_theme "''${THEMES[$NEXT_INDEX]}"
              exit 0
            fi
          done
          
          set_theme "''${THEMES[0]}"
        fi
        ;;
        
      "set"|"switch")
        if [ -z "$2" ]; then
          echo "Error: No theme name provided."
          echo "Usage: $PROGRAM_NAME $1 THEME_NAME"
          echo "Run '$PROGRAM_NAME list' to see available themes."
          exit 1
        fi
        set_theme "$2"
        ;;
        
      "")
        show_help
        exit 1
        ;;
        
      *)
        echo "Warning: Direct theme setting is deprecated. Use '$PROGRAM_NAME set THEME' instead."
        set_theme "$1"
        ;;
    esac
  '';

  themesDir = pkgs.stdenv.mkDerivation {
    name = "rofi-themes-collection";
     
    src = pkgs.fetchFromGitHub {
      owner = "newmanls";
      repo = "rofi-themes-collection";
      rev = "c2be059e9507785d42fc2077a4c3bc2533760939";
      sha256 = "sha256-pHPhqbRFNhs1Se2x/EhVe8Ggegt7/r9UZRocHlIUZKY=";
    };
    
    installPhase = ''
      mkdir -p $out/share/rofi/themes
      cp themes/*.rasi $out/share/rofi/themes/
    '';
  };

  themesListFile = pkgs.runCommand "rofi-themes-list" {} ''
    mkdir -p $out
    ls -1 ${themesDir}/share/rofi/themes | grep "\.rasi$" | sed 's/\.rasi$//' > $out/themes.txt
  '';

  rofi-theme-completion = pkgs.writeTextFile {
    name = "rofi-theme-completion";
    destination = "/share/bash-completion/completions/${cmdName}";
    text = ''
      # bash completion for ${cmdName}
      _rofi_theme_manager() {
          local cur prev opts themes cmd
          COMPREPLY=()
          cur="''${COMP_WORDS[COMP_CWORD]}"
          prev="''${COMP_WORDS[COMP_CWORD-1]}"
          cmd="''${COMP_WORDS[1]}"
          
          # Basic commands available
          opts="list current next prev set switch themes -h --help"
          
          # Define static list of themes from pre-generated file
          themes="$(cat ${themesListFile}/themes.txt | tr '\n' ' ')"

          # First argument completion
          if [ "$COMP_CWORD" -eq 1 ]; then
              if [[ ''${cur} == -* ]]; then
                  # Complete options that start with a dash
                  COMPREPLY=( $(compgen -W "-h --help" -- ''${cur}) )
              else
                  # Complete with commands
                  COMPREPLY=( $(compgen -W "$opts" -- ''${cur}) )
              fi
              return 0
          fi
          
          # Second argument completion (depends on first argument)
          if [ "$COMP_CWORD" -eq 2 ]; then
              case "$prev" in
                  "set"|"switch")
                      # Complete with theme names
                      COMPREPLY=( $(compgen -W "$themes" -- ''${cur}) )
                      ;;
                  *)
                      # No completion for other commands
                      ;;
              esac
              return 0
          fi

          # No completion for other arguments
          return 0
      }
      complete -F _rofi_theme_manager ${cmdName}
    '';
  };

in
{
  environment.systemPackages = with pkgs; [
    rofi
    themesDir
    rofi-theme-manager
    rofi-theme-completion
    bash-completion
  ];
  
  programs.bash.completion.enable = true;
}
