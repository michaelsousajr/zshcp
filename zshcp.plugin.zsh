# copy the active line from the command line buffer
# onto the system clipboard
function cpbuffer() {
  if builtin which clipcopy &>/dev/null; then
    printf "%s" "$BUFFER" | clipcopy
  else
    zle -M "clipcopy not found. Please make sure you have Oh My Zsh installed correctly."
  fi
}

zle -N cpbuffer

bindkey -M emacs "^Y" cpbuffer
bindkey -M viins "^Y" cpbuffer
bindkey -M vicmd "^Y" cpbuffer

function cpfile() {
    emulate -L zsh
    if [[ -z "$1" ]]; then
        echo "Usage: cpfile <file>"
        return 1
    fi

    if [[ ! -f "$1" ]]; then
        echo "Error: File $1 not found"
        return 1
    fi

    cat "$1" | clipcopy
    echo "File content copied to clipboard"
}

# Paste clipboard content to file
function psfile() {
    emulate -L zsh
    if [[ -z "$1" ]]; then
        echo "Usage: psfile <filename>"
        return 1
    fi

    if [[ -f "$1" ]]; then
        echo -n "File '$1' already exists. Overwrite? (Y/N) "
        read response
        echo
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Operation cancelled."
            return 1
        fi
    fi

    clippaste > "$1" 2>/dev/null
    if [[ $? -eq 0 ]]; then
        echo "Clipboard contents saved to '$1'"
    else
        echo "Error: Failed to write clipboard contents to file"
        return 1
    fi
}

# Copy folder path for later use
function cpfolder() {
    emulate -L zsh
    if [[ ! -d "${1:-.}" ]]; then
        echo "Error: Directory $1 not found"
        return 1
    fi

    folder_path=$(realpath "${1:-.}")
    echo "$folder_path" > "${TMPDIR:-/tmp}/.cp_folder_path"
    echo "Folder path stored for copying: $folder_path"
}

# Paste previously copied folder
function psfolder() {
    emulate -L zsh
    if [[ ! -f "${TMPDIR:-/tmp}/.cp_folder_path" ]]; then
        echo "No folder has been copied. Use cpfolder first."
        return 1
    fi

    source_path=$(cat "${TMPDIR:-/tmp}/.cp_folder_path")

    if [[ ! -d "$source_path" ]]; then
        echo "Error: Source folder no longer exists: $source_path"
        rm -f "${TMPDIR:-/tmp}/.cp_folder_path"
        return 1
    fi

    # Get the base name of the source folder
    folder_name=$(basename "$source_path")

    # If destination is specified, use it; otherwise use the folder name
    dest_path="${1:-$folder_name}"

    # Check if destination already exists
    if [[ -e "$dest_path" ]]; then
        echo -n "Destination '$dest_path' already exists. Overwrite? (Y/N) "
        read response
        echo
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Operation cancelled."
            return 1
        fi
    fi

    cp -r "$source_path" "$dest_path"
    if [[ $? -eq 0 ]]; then
        echo "Copied folder to $dest_path"
    else
        echo "Error copying folder"
        return 1
    fi
}

# Copy the current working directory path to clipboard
function cppwd() {
  emulate -L zsh
  print -n "$PWD" | clipcopy
  echo "${(%):-"%B$PWD%b copied to clipboard."}"
}

# Copy command history to clipboard
function cphistory() {
  emulate -L zsh
  fc -ln -50 1 | clipcopy
  echo "Last 50 commands copied to clipboard."
}

# Help function
function cphelp() {
    echo "Copy Plugin Commands:"
    echo "  Ctrl + Y                 - Copy(Yank) buffer to clipboard"
    echo "  cpfile <file>            - Copy file content to clipboard"
    echo "  psfile <file>            - Create/overwrite file with clipboard contents"
    echo "  cpfolder ., <folder>     - Copy specified folder, if not specified will copy in pwd"
    echo "  psfolder ., <folder>     - Create/overwrite copied folder, if not specified will paste in pwd"
    echo "  cppwd                    - Copy current directory path"
    echo "  cphistory                - Copy last 50 commands from history"
    echo "  Ctrl + V                 - Paste clipboard contents."
    echo "  cphelp                   - Show this help message"
}
