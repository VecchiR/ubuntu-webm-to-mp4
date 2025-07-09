#!/bin/bash
# =============================================================================
# WebM to MP4 Converter - Installation Script
# =============================================================================
# This script installs a complete WebM to MP4 conversion system for Linux
# It creates multiple scripts that work together to convert video files
# and integrates with the Nautilus file manager for easy right-click access
# =============================================================================

# =============================================================================
# DEFAULT CONVERTED FILES FOLDER
# =============================================================================
# By default, converted MP4 files are saved to:
#   $HOME/Videos/converted mp4s
# You can change this in the configuration GUI or by editing the config file.
# =============================================================================

# =============================================================================
# CONFIGURATION SECTION - Change these paths if needed
# =============================================================================

# Where to install the main scripts (usually ~/.local/bin is in your PATH)
INSTALL_DIR="$HOME/.local/bin"

# Names of the three main scripts that will be created
SCRIPT_NAME="webm-to-mp4"              # Main conversion script
CONFIG_SCRIPT_NAME="webm-to-mp4-config" # Configuration GUI script
STATUS_SCRIPT_NAME="webm-to-mp4-status" # Status checking script

# Where Nautilus (file manager) looks for right-click scripts
NAUTILUS_SCRIPTS_DIR="$HOME/.local/share/nautilus/scripts/webm-to-mp4"

# Path for the converter icon (not currently used but created for future use)
ICON_PATH="$HOME/.local/share/icons/webm-to-mp4.png"

# =============================================================================
# DIRECTORY SETUP - Create necessary folders
# =============================================================================

# Create the installation directory if it doesn't exist
# The -p flag means "create parent directories as needed, don't error if exists"
mkdir -p "$INSTALL_DIR"
mkdir -p "$NAUTILUS_SCRIPTS_DIR"
mkdir -p "$(dirname "$ICON_PATH")"  # Create the icons directory

# =============================================================================
# DEPENDENCY CHECK FUNCTION
# =============================================================================
# This function checks if required programs are installed on your system
# CHANGE HERE: Add or remove required programs from the dependency list
# =============================================================================

check_dependencies() {
    # Array to store missing programs
    missing_deps=()
    
    # List of required programs - ADD OR REMOVE PROGRAMS HERE
    for dep in ffmpeg zenity yad notify-send; do
        # Check if the program exists in the system PATH
        # &> /dev/null means "hide all output"
        if ! command -v "$dep" &> /dev/null; then
            # Add missing program to the array
            missing_deps+=("$dep")
        fi
    done
    
    # If any dependencies are missing, show error and exit
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "Missing dependencies: ${missing_deps[*]}"
        echo "Please install them with:"
        echo "sudo apt install ffmpeg zenity yad libnotify-bin"
        exit 1
    fi
}

# =============================================================================
# MAIN CONVERSION SCRIPT CREATION
# =============================================================================
# This function creates the main script that does the actual video conversion
# CHANGE HERE: Modify conversion settings, file paths, or ffmpeg parameters
# =============================================================================

create_main_script() {
    # Create the main conversion script using a "here document" (everything between 'EOF' markers)
    cat > "$INSTALL_DIR/$SCRIPT_NAME" << 'EOF'
#!/bin/bash

# =============================================================================
# MAIN CONVERSION SCRIPT - File Paths and Configuration
# =============================================================================
# CHANGE HERE: Modify these paths to customize where files are stored
# =============================================================================

# Where user settings are stored
CONFIG_FILE="$HOME/.config/webm-to-mp4/webm-to-mp4.conf"

# Where conversion logs are stored
LOG_DIR="$HOME/.config/webm-to-mp4/logs"

# Where current conversion status is stored
STATUS_FILE="$HOME/.config/webm-to-mp4/status"

# Icon used for notifications (change this to use a different icon)
ICON="/usr/share/icons/Humanity/mimes/48/video-x-generic.png"

# =============================================================================
# SETUP - Create necessary directories
# =============================================================================

# Create directories if they don't exist
mkdir -p "$LOG_DIR"
mkdir -p "$(dirname "$STATUS_FILE")"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Function to update the status file and show notifications
update_status() {
    local status="$1"  # The status message to display
    
    # Write status to file so other scripts can read it
    echo "$status" > "$STATUS_FILE"
    
    # Show desktop notification if enabled in config
    if [ "$notifications" = "true" ]; then
        notify-send -i "$ICON" "webm-to-mp4" "$status"
    fi
}

# Function to write messages to the log file
log_message() {
    local level="$1"    # Log level: INFO, WARN, ERROR
    local message="$2"  # The message to log
    
    # Create timestamp in format: DD-MM-YYYY 12:00:00
    local timestamp=$(date "+%d-%m-%Y %H:%M:%S")
    
    # Append to log file with timestamp and level
    echo "[$timestamp] [$level] $message" >> "$LOG_DIR/conversion.log"
}

# =============================================================================
# CONFIGURATION LOADING
# =============================================================================
# CHANGE HERE: Modify default settings or add new configuration options
# =============================================================================

# Load user configuration from file if it exists
if [ -f "$CONFIG_FILE" ]; then
    # Load config file, ignoring comments and fixing spacing around = signs
    source <(grep -v '^#' "$CONFIG_FILE" | sed 's/ *= */=/' )
else
    # DEFAULT SETTINGS - Change these to customize default behavior
    output_dir="mp4_folder"        # Where to save converted files ("same", "mp4_folder", or custom path)
    delete_original=false    # Whether to delete original .webm files after conversion
    output_suffix=""         # Text to add to output filename (e.g., "_converted")
    notifications=true       # Whether to show desktop notifications
fi

# =============================================================================
# OUTPUT DIRECTORY SETUP
# =============================================================================
# CHANGE HERE: Modify the default MP4 folder location
# =============================================================================

# If using the mp4_folder option, create the directory
if [ "$output_dir" = "mp4_folder" ]; then
    # DEFAULT MP4 FOLDER - Change this path if you want a different location
    output_dir="$HOME/Videos/webm-to-mp4/converted mp4s"
    mkdir -p "$output_dir"
fi

# Create directory for error logs
# CHANGE HERE: Change error log location
ERROR_LOG_DIR="$HOME/Videos/webm-to-mp4/conversion error logs"
mkdir -p "$ERROR_LOG_DIR"

# =============================================================================
# CONVERSION PROCESS SETUP
# =============================================================================

# Initialize counters for tracking conversion progress
total_files=$#           # Total number of files to convert ($# = number of arguments)
current_file=0          # Current file being processed
failed_files=0          # Number of failed conversions
successful_files=0      # Number of successful conversions

# Show initial status
update_status "Starting conversion of $total_files files..."
log_message "INFO" "Starting conversion of $total_files files"

# =============================================================================
# MAIN CONVERSION LOOP (runs in background)
# =============================================================================
# CHANGE HERE: Modify ffmpeg settings, file handling, or conversion logic
# =============================================================================

# Run the conversion process in the background using ( ) & syntax
(
    # Loop through each file passed as an argument
    for INPUT in "$@"
    do
        # Increment current file counter
        current_file=$((current_file + 1))
        
        # Extract file extension (everything after the last dot)
        EXT="${INPUT##*.}"
        
        # Skip files that aren't .webm
        if [ "$EXT" != "webm" ]; then
            log_message "WARN" "Skipping $INPUT — not a .webm file"
            continue
        fi
        
        # Extract directory and filename without extension
        DIR=$(dirname "$INPUT")                    # Directory containing the file
        BASENAME=$(basename "$INPUT" .webm)       # Filename without .webm extension
        
        # Determine where to save the converted file
        if [ "$output_dir" = "same" ]; then
            OUTDIR="$DIR"                         # Save in same directory as original
        else
            OUTDIR="$output_dir"                  # Save in specified directory
            mkdir -p "$OUTDIR"                    # Create directory if needed
        fi
        
        # Construct output filename and error log path
        OUTPUT="$OUTDIR/${BASENAME}${output_suffix}.mp4"
        ERROR_LOG="$ERROR_LOG_DIR/${BASENAME}_error.log"
        
        # Update status and log
        update_status "Converting ($current_file/$total_files): $(basename "$INPUT")"
        log_message "INFO" "Converting: $INPUT to $OUTPUT"
        
        # =============================================================================
        # FFMPEG CONVERSION COMMAND
        # =============================================================================
        # CHANGE HERE: Modify video conversion settings
        # Current settings:
        # -i "$INPUT"                          = Input file
        # -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2"  = Make dimensions even numbers (required for some codecs)
        # -progress /dev/stdout               = Show progress information
        # 2> "$ERROR_LOG"                     = Send errors to log file
        # =============================================================================
        
        ffmpeg -i "$INPUT" -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -progress /dev/stdout "$OUTPUT" 2> "$ERROR_LOG" | while read line; do
            # Extract speed information from ffmpeg output for progress tracking
            if [[ "$line" == speed=* ]]; then
                echo "$line" > "$STATUS_FILE.progress"
            fi
        done
        
        # Check if conversion was successful
        # ${PIPESTATUS[0]} gets the exit code of the ffmpeg command (before the pipe)
        if [ ${PIPESTATUS[0]} -eq 0 ]; then
            # SUCCESS: Conversion completed successfully
            successful_files=$((successful_files + 1))
            log_message "INFO" "Successfully converted: $INPUT"
            rm -f "$ERROR_LOG"  # Remove error log since conversion succeeded
            
            # Delete original file if configured to do so
            if [ "$delete_original" = "true" ]; then
                rm "$INPUT"
                log_message "INFO" "Deleted original: $INPUT"
            fi
        else
            # FAILURE: Conversion failed
            failed_files=$((failed_files + 1))
            error_message="Conversion failed: $(basename "$INPUT"). See log: $ERROR_LOG"
            log_message "ERROR" "Conversion failed: $INPUT"
            
            # Show error notification
            if [ "$notifications" = "true" ]; then
                notify-send -u critical -i "$ICON" "webm-to-mp4 - ERROR" "$error_message"
            fi
        fi
    done
    
    # =============================================================================
    # CONVERSION COMPLETION
    # =============================================================================
    
    # Show final results
    completion_message="Conversion complete: $successful_files successful, $failed_files failed"
    update_status "$completion_message"
    log_message "INFO" "$completion_message"
    
    # Clean up temporary files
    rm -f "$STATUS_FILE.progress"
    
    # Add completion timestamp to status file
    echo "$(date "+%d-%m-%Y %H:%M:%S")" >> "$STATUS_FILE"
) &

# =============================================================================
# BACKGROUND PROCESS MANAGEMENT
# =============================================================================

# Get the process ID of the background conversion process
process_pid=$!

# Save the process ID so other scripts can check if conversion is running
echo $process_pid > "$STATUS_FILE.pid"

# Disown the process so it continues running even if this script exits
disown

# Show notification that process is running in background
if [ "$notifications" = "true" ]; then
    notify-send -i "$ICON" "webm-to-mp4" "Converting in background (PID: $process_pid).\nCheck status with webm-to-mp4 converter status"
fi

# Exit successfully
exit 0
EOF
    
    # Make the script executable
    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
}

# =============================================================================
# CONFIGURATION SCRIPT CREATION
# =============================================================================
# This function creates the GUI configuration script
# CHANGE HERE: Modify the configuration options or GUI layout
# =============================================================================

create_config_script() {
    cat > "$INSTALL_DIR/$CONFIG_SCRIPT_NAME" << 'EOF'
#!/bin/bash

# =============================================================================
# CONFIGURATION GUI SCRIPT (YAD version with improved save location handling)
# =============================================================================

CONFIG_FILE="$HOME/.config/webm-to-mp4/webm-2-mp4.conf"
LOG_DIR="$HOME/.config/webm-to-mp4/logs"
DEFAULT_OUTPUT_PATH="$HOME/Videos/converted mp4s"

mkdir -p "$(dirname "$CONFIG_FILE")"
mkdir -p "$LOG_DIR"

# Load config or set defaults
if [ -f "$CONFIG_FILE" ]; then
    source <(grep -v '^#' "$CONFIG_FILE" | sed 's/ *= */=/')
fi

# Set default values if not loaded from config
output_dir="${output_dir:-$DEFAULT_OUTPUT_PATH}"
delete_original="${delete_original:-false}"
output_suffix="${output_suffix:-}"
notifications="${notifications:-true}"

# Determine initial state for save location
if [ "$output_dir" = "same" ]; then
    save_location_mode="same"
    custom_path="$DEFAULT_OUTPUT_PATH"
else
    save_location_mode="path"
    custom_path="$output_dir"
fi

# Function to show the main configuration dialog
show_config_dialog() {
    local mode="$1"
    local path="$2"
    
    # Enable/disable path field based on mode
    if [ "$mode" = "same" ]; then
        path_field_enabled="false"
    else
        path_field_enabled="true"
    fi
    
    # Create the YAD form
    config=$(yad --form --title="webm-to-mp4 - Configuration" \
        --width=600 --height=400 \
        --field="Save location:CB" "$mode!same!path" \
        --field="Output path:DIR" "$path" \
        --field="Output suffix:" "$output_suffix" \
        --field="Delete original .webm files:CB" "$delete_original!false!true" \
        --field="Show notifications:CB" "$notifications!true!false" \
        --button="View Logs":10 \
        --button="Clear Logs":11 \
        --button="Reset to Default Path":12 \
        --button="gtk-cancel":1 \
        --button="gtk-ok":0 \
        --text="Configure webm-to-mp4 converter settings.\n\nSave location:\n• 'same' = Save converted files in same folder as original\n• 'path' = Save converted files in specified directory\n\nDefault: The default output path is: $HOME/Videos/converted mp4s" \
        --separator="|")
    
    button=$?
    
    case $button in
        0) # OK button - save configuration
            IFS="|" read -r new_mode new_path new_suffix new_delete new_notify <<< "$config"
            save_configuration "$new_mode" "$new_path" "$new_suffix" "$new_delete" "$new_notify"
            ;;
        1) # Cancel or close
            exit 0
            ;;
        10) # View Logs
            view_logs
            show_config_dialog "$mode" "$path"
            ;;
        11) # Clear Logs
            clear_logs
            show_config_dialog "$mode" "$path"
            ;;
        12) # Reset to Default Path
            if [ "$mode" = "path" ]; then
                show_config_dialog "$mode" "$DEFAULT_OUTPUT_PATH"
            else
                show_config_dialog "$mode" "$path"
            fi
            ;;
        *) # Other/error
            exit 1
            ;;
    esac
}

# Function to save configuration
save_configuration() {
    local mode="$1"
    local path="$2"
    local suffix="$3"
    local delete="$4"
    local notify="$5"
    
    # Set output_dir based on mode
    if [ "$mode" = "same" ]; then
        output_dir="same"
    else
        # Clean up path (remove trailing slash)
        output_dir="${path%/}"
        
        # Validate that the path can be created
        if ! mkdir -p "$output_dir" 2>/dev/null; then
            yad --error --text="Cannot create directory: $output_dir\n\nPlease check the path and try again."
            show_config_dialog "$mode" "$path"
            return
        fi
    fi
    
    # Write configuration file
    cat > "$CONFIG_FILE" << EOL
# webm-to-mp4 Configuration File
# This file is automatically generated by the configuration script

# Output directory for converted files
# Use "same" to save in the same folder as the original file
# Use a full path to save in a specific directory
output_dir=\$output_dir

# Whether to delete original .webm files after successful conversion
delete_original=\$delete

# Suffix to add to output filename (e.g., "_converted")
output_suffix=\$suffix

# Whether to show desktop notifications
notifications=\$notify
EOL
    
    # Show success message
    if [ "$mode" = "same" ]; then
        location_text="same directory as original files"
    else
        location_text="$output_dir"
    fi
    
    yad --info --title="Configuration Saved" \
        --text="Configuration saved successfully!\n\nSettings:\n• Save location: $location_text\n• Output suffix: '$suffix'\n• Delete original: $delete\n• Notifications: $notify" \
        --width=400
}

# Function to view logs
view_logs() {
    if [ -f "$LOG_DIR/conversion.log" ]; then
        if command -v gedit &> /dev/null; then
            gedit "$LOG_DIR/conversion.log" &
        elif command -v xdg-open &> /dev/null; then
            xdg-open "$LOG_DIR/conversion.log"
        else
            yad --text-info --filename="$LOG_DIR/conversion.log" --title="Conversion Log" --width=700 --height=500
        fi
    else
        yad --info --text="No conversion log found yet.\n\nThe log file will be created when you run your first conversion."
    fi
}

# Function to clear logs
clear_logs() {
    if yad --question --text="Are you sure you want to clear all conversion logs?"; then
        rm -f "$LOG_DIR/conversion.log"
        rm -f "$HOME/Videos/webm-to-mp4/conversion error logs/"*
        yad --info --text="Logs cleared successfully."
    fi
}

# Start the configuration dialog
show_config_dialog "$save_location_mode" "$custom_path"
EOF
    
    # Make the script executable
    chmod +x "$INSTALL_DIR/$CONFIG_SCRIPT_NAME"
}

# =============================================================================
# NAUTILUS INTEGRATION SCRIPTS
# =============================================================================
# These create right-click menu items in the Nautilus file manager
# CHANGE HERE: Modify right-click menu options or add new menu items
# =============================================================================

create_nautilus_script() {
    # Main conversion script - appears when you right-click on files
    cat > "$NAUTILUS_SCRIPTS_DIR/CONVERT!" << EOF
#!/bin/bash
# This script runs when you right-click on files and select "convert webm to mp4"
# NAUTILUS_SCRIPT_SELECTED_FILE_PATHS contains the selected files
$INSTALL_DIR/$SCRIPT_NAME \$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS
EOF
    chmod +x "$NAUTILUS_SCRIPTS_DIR/CONVERT!"
    
    # Configuration script - allows configuring settings from right-click menu
    cat > "$NAUTILUS_SCRIPTS_DIR/converter configuration" << EOF
#!/bin/bash
# This script opens the configuration GUI from the right-click menu
$INSTALL_DIR/$CONFIG_SCRIPT_NAME
EOF
    chmod +x "$NAUTILUS_SCRIPTS_DIR/converter configuration"
    
    # Status script - allows checking conversion status from right-click menu
    cat > "$NAUTILUS_SCRIPTS_DIR/converter status" << EOF
#!/bin/bash
# This script opens the status checker from the right-click menu
$INSTALL_DIR/$STATUS_SCRIPT_NAME
EOF
    chmod +x "$NAUTILUS_SCRIPTS_DIR/converter status"
}

# =============================================================================
# ICON CREATION
# =============================================================================
# Creates a simple SVG icon for the converter (currently not used)
# CHANGE HERE: Modify the icon design or use a different image file
# =============================================================================

create_icon() {
    cat > "$ICON_PATH" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48">
    <circle cx="24" cy="24" r="22" fill="#4285F4" />
    <polygon points="19,16 19,32 33,24" fill="white" />
    <text x="24" y="42" text-anchor="middle" font-family="Arial" font-size="10" fill="white">MP4</text>
</svg>
EOF
}

# =============================================================================
# UNINSTALL SCRIPT CREATION
# =============================================================================
# This function creates a script to uninstall webm-to-mp4
# and removes all associated files and directories
# CHANGE HERE: Modify uninstallation process or files to remove
# =============================================================================

create_uninstall_script() {
    cat > "$INSTALL_DIR/webm-to-mp4-uninstall" << 'EOF'
#!/bin/bash

set -e

# Confirm uninstall
zenity --question --title="Uninstall webm-to-mp4" \
    --text="Are you sure you want to completely uninstall webm-to-mp4 and remove all its files and settings?"
if [ $? -ne 0 ]; then
    exit 0
fi

# Paths
INSTALL_DIR="$HOME/.local/bin"
NAUTILUS_SCRIPTS_DIR="$HOME/.local/share/nautilus/scripts/webm-to-mp4"
ICON_PATH="$HOME/.local/share/icons/webm-to-mp4.png"
CONFIG_FILE="$HOME/.config/webm-to-mp4.conf"
CONFIG_DIR="$HOME/.config/webm-to-mp4"
LOG_DIR="$HOME/.config/webm-to-mp4/logs"
STATUS_FILE="$HOME/.config/webm-to-mp4/status"

# Remove main scripts
rm -f "$INSTALL_DIR/webm-to-mp4" "$INSTALL_DIR/webm-to-mp4-config" "$INSTALL_DIR/webm-to-mp4-status" "$INSTALL_DIR/webm-to-mp4-uninstall"

# Remove Nautilus integration
rm -rf "$NAUTILUS_SCRIPTS_DIR"

# Remove icon
rm -f "$ICON_PATH"

# Remove config and logs
rm -f "$CONFIG_FILE"
rm -rf "$CONFIG_DIR"

# Remove error logs and status
rm -rf "$HOME/Videos/webm-to-mp4"
rm -f "$STATUS_FILE" "$STATUS_FILE.progress" "$STATUS_FILE.pid"

# Show Zenity dialog
zenity --info --title="webm-to-mp4 Uninstalled" \
    --text="webm-to-mp4 has been fully uninstalled.\n\nTo complete removal from Nautilus, please restart Nautilus.\n\nClick OK to quit Nautilus now (you may need to reopen your file manager)."

# Prompt to quit Nautilus
zenity --question --title="Restart Nautilus?" --text="Do you want to quit Nautilus now? (You may need to reopen your file manager manually.)"
if [ $? -eq 0 ]; then
    nautilus -q
fi

exit 0
EOF
    chmod +x "$INSTALL_DIR/webm-to-mp4-uninstall"

    # Add to Nautilus menu
    cat > "$NAUTILUS_SCRIPTS_DIR/UNINSTALL webm-to-mp4" << EOF
#!/bin/bash
$INSTALL_DIR/webm-to-mp4-uninstall
EOF
    chmod +x "$NAUTILUS_SCRIPTS_DIR/UNINSTALL webm-to-mp4"
}

# =============================================================================
# MAIN INSTALLATION PROCESS
# =============================================================================
# This is where the actual installation happens
# =============================================================================

echo "Installing webm-to-mp4 converter..."

# Check if all required programs are installed
check_dependencies

# Create all the scripts
create_main_script        # Main conversion script
create_config_script      # Configuration GUI
create_status_script      # Status checker
create_nautilus_script    # Right-click menu integration
create_icon              # Create icon file
create_uninstall_script  # Uninstall script

# Show completion message
echo "Installation complete!"
echo "You can now:"
echo "1. Right-click on .webm files in Nautilus and select 'Scripts > webm-to-mp4 > CONVERT!' to convert them"
echo "2. Configure the converter with 'Scripts > webm-to-mp4 > converter configuration'"
echo "3. Check conversion status with 'Scripts > webm-to-mp4 > converter status'"
echo ""

# =============================================================================
# CUSTOMIZATION GUIDE
# =============================================================================
# 
# To customize this script, look for "CHANGE HERE" comments throughout the code.
# Common customizations:
# 
# 1. DEFAULT PATHS: Change the directories where files are stored
# 2. FFMPEG SETTINGS: Modify video conversion quality/settings
# 3. CONFIGURATION OPTIONS: Add new settings or change defaults
# 4. GUI APPEARANCE: Modify Zenity dialog boxes
# 5. NOTIFICATION BEHAVIOR: Change when/how notifications appear
# 6. FILE HANDLING: Change how files are processed or named
# 7. DEPENDENCIES: Add or remove required programs
# 8. RIGHT-CLICK MENU: Add new menu items or modify existing ones
# 
# =============================================================================
