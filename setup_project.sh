#!/bin/bash
# setup_project.sh — Bootstraps the Student Attendance Tracker project

# Prompt for project name (loop until non-empty)
while true; do
    read -p "Enter project name: " input
    if [[ -n "$input" ]]; then
        break
    fi
    echo "Error: Project name cannot be empty. Please try again."
done

project_dir="attendance_tracker_$input"

# Handle existing directory (loop until valid choice)
if [[ -d "$project_dir" ]]; then
    while true; do
        read -p "Directory '$project_dir' already exists. Overwrite? [y/n]: " ow
        if [[ -z "$ow" ]]; then
            echo "Error: Input cannot be empty. Please enter 'y' or 'n'."
        elif [[ "$ow" =~ ^[Yy]$ ]]; then
            rm -rf "$project_dir"
            break
        elif [[ "$ow" =~ ^[Nn]$ ]]; then
            echo "Aborted. Nothing was changed."
            exit 0
        else
            echo "Error: Please enter 'y' or 'n'."
        fi
    done
fi

# Signal trap: archive + cleanup on Ctrl+C
cleanup() {
    echo ""
    echo "Setup interrupted. Archiving current state..."
    tar -czf "${project_dir}_archive" "$project_dir" 2>/dev/null
    rm -rf "$project_dir"
    echo "Archive saved: ${project_dir}_archive"
    echo "Incomplete directory removed."
    exit 1
}
trap cleanup SIGINT

# Create directory structure
mkdir -p "$project_dir"
cd "$project_dir" || { echo "Error: Failed to enter $project_dir"; exit 1; }
mkdir -p Helpers reports

# Generate attendance_checker.py
cat > attendance_checker.py << 'EOF'
import csv
import json
import os
from datetime import datetime

def run_attendance_check():
    with open('Helpers/config.json', 'r') as f:
        config = json.load(f)

    if os.path.exists('reports/reports.log'):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        os.rename('reports/reports.log', f'reports/reports_{timestamp}.log.archive')

    with open('Helpers/assets.csv', mode='r') as f, open('reports/reports.log', 'w') as log:
        reader = csv.DictReader(f)
        total_sessions = config['total_sessions']
        log.write(f"--- Attendance Report Run: {datetime.now()} ---\n")

        for row in reader:
            name = row['Names']
            email = row['Email']
            attended = int(row['Attendance Count'])
            attendance_pct = (attended / total_sessions) * 100

            message = ""
            if attendance_pct < config['thresholds']['failure']:
                message = f"URGENT: {name}, your attendance is {attendance_pct:.1f}%. You will fail this class."
            elif attendance_pct < config['thresholds']['warning']:
                message = f"WARNING: {name}, your attendance is {attendance_pct:.1f}%. Please be careful."

            if message:
                if config['run_mode'] == "live":
                    log.write(f"[{datetime.now()}] ALERT SENT TO {email}: {message}\n")
                    print(f"Logged alert for {name}")
                else:
                    print(f"[DRY RUN] Email to {email}: {message}")

if __name__ == "__main__":
    run_attendance_check()
EOF

# Generate Helpers/assets.csv
cat > Helpers/assets.csv << 'EOF'
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
EOF

# Generate Helpers/config.json
cat > Helpers/config.json << 'EOF'
{
    "thresholds": {
        "warning": 75,
        "failure": 50
    },
    "run_mode": "live",
    "total_sessions": 15
}
EOF

# Initialize reports/reports.log
touch reports/reports.log

# Dynamic configuration via sed (loop until valid y/n)
while true; do
    read -p "Update attendance thresholds? [y/n]: " update
    if [[ -z "$update" ]]; then
        echo "Error: Input cannot be empty. Please enter 'y' or 'n'."
    elif [[ "$update" =~ ^[YyNn]$ ]]; then
        if [[ "$update" =~ ^[Yy]$ ]]; then
            # Warning threshold — whole number 0-100
            while true; do
                read -p "  Warning threshold (default 75): " warn_val
                warn_val="${warn_val:-75}"
                if [[ "$warn_val" =~ ^[0-9]+$ ]] && (( warn_val >= 0 && warn_val <= 100 )); then
                    break
                fi
                echo "  Error: Enter a whole number between 0 and 100."
            done
            # Failure threshold — whole number, must be less than warning
            while true; do
                read -p "  Failure threshold (default 50): " fail_val
                fail_val="${fail_val:-50}"
                if ! [[ "$fail_val" =~ ^[0-9]+$ ]] || (( fail_val < 0 || fail_val > 100 )); then
                    echo "  Error: Enter a whole number between 0 and 100."
                elif (( fail_val >= warn_val )); then
                    echo "  Error: Failure ($fail_val) must be less than Warning ($warn_val)."
                else
                    break
                fi
            done
            sed -i -E "s/\"warning\"[[:space:]]*:[[:space:]]*[0-9]+/\"warning\": $warn_val/" Helpers/config.json
            sed -i -E "s/\"failure\"[[:space:]]*:[[:space:]]*[0-9]+/\"failure\": $fail_val/" Helpers/config.json
            echo "Thresholds updated — Warning: ${warn_val}%  Failure: ${fail_val}%"
        else
            echo "No updates made to thresholds."
        fi
        break
    else
        echo "Error: Please enter 'y' or 'N'."
    fi
done

# Environment validation (Health Check)
echo "--------------------"
echo "Running health check..."

if python3 --version > /dev/null 2>&1; then
    echo "[OK]   $(python3 --version) is installed."
else
    echo "[WARN] python3 is not installed. Install it before running the app."
fi

missing=0
for item in attendance_checker.py Helpers/assets.csv Helpers/config.json reports/reports.log; do
    if [[ -e "$item" ]]; then
        echo "[OK]   $item exists."
    else
        echo "[FAIL] $item is missing!"
        missing=1
    fi
done

echo "--------------------"
if [[ $missing -eq 0 ]]; then
    echo "Project '$project_dir' set up successfully!"
    echo "To run the application:"
    echo "  1. cd $project_dir"
    echo "  2. python3 attendance_checker.py"
else
    echo "Setup finished with errors. Please review the messages above."
fi
