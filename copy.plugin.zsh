# Copy the current command line buffer to clipboard
copybuffer() {
    echo -n "$BUFFER" | clipcopy
}
zle -N copy-line-to-clipboard
bindkey '^Y' copy-line-to-clipboard

# Helper function to check if clipcopy exists
checkclipboard() {
    if (( $+commands[xclip] )); then
        alias clipcopy='xclip -in -selection clipboard'
        alias clippaste='xclip -out -selection clipboard'
    elif (( $+commands[pbcopy] )); then
        alias clipcopy='pbcopy'
        alias clippaste='pbpaste'
    else
        echo "Please install xclip (Linux) or pbcopy (macOS)"
        return 1
    fi
}

# Initialize clipboard commands
checkclipboard

# Copy file content to clipboard
copyfile() {
    if [[ -f "$1" ]]; then
        cat "$1" | clipcopy
        echo "📋 File content copied to clipboard: $1"
    else
        echo "❌ File not found: $1"
    fi
}

# Copy file to current directory
pastefile() {
    if [[ -f "$1" ]]; then
        cp "$1" .
        echo "📄 File copied to current directory: $1"
    else
        echo "❌ File not found: $1"
    fi
}

# Copy directory
copydir() {
    if [[ -d "$1" ]]; then
        cp -r "$1" .
        echo "📁 Directory copied to current directory: $1"
    else
        echo "❌ Directory not found: $1"
    fi
}

# Copy last command to clipboard
copylastcommand() {
    fc -ln -1 | clipcopy
    echo "📋 Last command copied to clipboard"
}

# Copy working directory path
copypwd() {
    echo -n "$PWD" | clipcopy
    echo "📋 Current directory path copied to clipboard"
}

# Copy specific command from history
copyhistory() {
    local selected
    selected=$(fc -l 1 | fzf --tac | sed 's/^\s*[0-9]*\s*//')
    if [[ -n "$selected" ]]; then
        echo -n "$selected" | clipcopy
        echo "📋 Command copied to clipboard"
    fi
}

# Copy file name only
copyfilename() {
    if [[ -e "$1" ]]; then
        echo -n "$(basename "$1")" | clipcopy
        echo "📋 Filename copied to clipboard"
    else
        echo "❌ File/directory not found: $1"
    fi
}

FOLDER_CLIPBOARD="$HOME/.cache/zsh_folder_clipboard"
mkdir -p "$(dirname "$FOLDER_CLIPBOARD")"

# Copy folder to clipboard storage
copyfolder() {
    if [[ $# -eq 0 ]]; then
        echo "❌ Usage: copyfolder <folder_path>"
        return 1
    }

    local folder_path="$1"

    # Convert to absolute path
    folder_path="$(cd "$(dirname "$folder_path")" 2>/dev/null && pwd)/$(basename "$folder_path")"

    if [[ ! -d "$folder_path" ]]; then
        echo "❌ Directory not found: $folder_path"
        return 1
    }

    # Store the folder path
    echo "$folder_path" > "$FOLDER_CLIPBOARD"
    echo "📁 Folder ready to copy: $folder_path"

    # Show folder size and contents summary
    local size=$(du -sh "$folder_path" | cut -f1)
    local files_count=$(find "$folder_path" -type f | wc -l)
    local dirs_count=$(find "$folder_path" -type d | wc -l)

    echo "📊 Size: $size"
    echo "📑 Files: $files_count"
    echo "📂 Directories: $dirs_count"
}

# Paste folder from clipboard storage
pastefolder() {
    if [[ ! -f "$FOLDER_CLIPBOARD" ]]; then
        echo "❌ No folder in clipboard"
        return 1
    }

    local source_path="$(cat "$FOLDER_CLIPBOARD")"

    if [[ ! -d "$source_path" ]]; then
        echo "❌ Original folder no longer exists: $source_path"
        return 1
    }

    local target_name="$1"
    local target_path

    # If no name provided, use original folder name
    if [[ -z "$target_name" ]]; then
        target_name="$(basename "$source_path")"
    fi

    target_path="$PWD/$target_name"

    # Check if target already exists
    if [[ -e "$target_path" ]]; then
        echo "⚠️  Target already exists: $target_path"
        read -q "REPLY?Do you want to overwrite? (y/n) "
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            echo "❌ Operation cancelled"
            return 1
        fi
    fi

    echo "📋 Copying folder..."
    echo "From: $source_path"
    echo "To: $target_path"

    # Show progress while copying
    if (( $+commands[rsync] )); then
        rsync -ah --progress "$source_path/" "$target_path/"
    else
        cp -r "$source_path" "$target_path"
    fi

    if [[ $? -eq 0 ]]; then
        echo "✅ Folder copied successfully!"

        # Show result summary
        local size=$(du -sh "$target_path" | cut -f1)
        echo "📊 Copied size: $size"
    else
        echo "❌ Error during copy operation"
        return 1
    fi
}

# Show what's currently in folder clipboard
showfolder() {
    if [[ ! -f "$FOLDER_CLIPBOARD" ]]; then
        echo "📋 Folder clipboard is empty"
        return 0
    fi

    local folder_path="$(cat "$FOLDER_CLIPBOARD")"

    if [[ ! -d "$folder_path" ]]; then
        echo "❌ Stored folder no longer exists: $folder_path"
        return 1
    }

    echo "📁 Currently in folder clipboard:"
    echo "$folder_path"

    # Show folder details
    local size=$(du -sh "$folder_path" | cut -f1)
    local files_count=$(find "$folder_path" -type f | wc -l)
    local dirs_count=$(find "$folder_path" -type d | wc -l)

    echo "📊 Size: $size"
    echo "📑 Files: $files_count"
    echo "📂 Directories: $dirs_count"

    echo "\nContents preview (top-level):"
    ls -lah "$folder_path" | head -n 10
}

# Clear folder clipboard
clearfolder() {
    if [[ -f "$FOLDER_CLIPBOARD" ]]; then
        rm "$FOLDER_CLIPBOARD"
        echo "🧹 Folder clipboard cleared"
    else
        echo "📋 Folder clipboard is already empty"
    fi
}

# Help function
copyhelp() {
    echo "Copy Plugin Commands:"
    echo "  copyfile <file>     - Copy file content to clipboard"
    echo "  pastehere <file>    - Paste file to current directory"
    echo "  copydir <dir>       - Copy directory to current directory"
    echo "  copylast            - Copy last command to clipboard"
    echo "  copypwd             - Copy current directory path"
    echo "  copyhistory         - Interactive search and copy from history"
    echo "  copyname <file>     - Copy filename to clipboard"
    echo "  copyhelp            - Show this help message"
    echo "  copyfolder          - Copy a folder's content"
    echo "  pastefolder <name>  - Paste folder to pwd with name copied or specified name"
    echo "  showfolder          - Show whats in folder in clipboard"
    echo "  clearfolder         - Clear folder from clipboard"
    echo "  copybuffer          - Copy current command line to clipboard"
    echo ""
    echo "Keyboard Shortcuts:"  
    echo "  Ctrl+Y              - Copy current command line to clipboard"
}
