# STUDENT ATTENDANCE TRACKER
A Linux-based application that automates the setup of a student attendance tracking workspace, with dynamic threshold configuration and safe cleanup on interruption.

## Features
- Automated project directory creation
- Dynamic attendance threshold configuration
- Signal trap with archive-on-cancel
- Environment health check

## Prerequisites
- Linux/Unix environment
- **Bash** 4.x or later
- **Python 3** (for running `attendance_checker.py`)
- Standard Unix utilities: `sed`, `tar`, `mkdir`, `cat`

The script performs a health check for `python3` during setup and warns if it is missing.

## Installation & Setup
1. **Clone the repository**
```
git clone https://github.com/23Ihirwe/deploy_agent_23Ihirwe.git
cd deploy_agent_23Ihirwe
```
2. **Run the environment setup**
```
bash setup_project.sh
```
- Enter a project name when prompted
- Choose whether to update attendance thresholds
- This creates the complete application structure

## Usage
### Running the Main Application
```
cd attendance_tracker_[name]
python3 attendance_checker.py
```

### Example Output
![Example Output](https://i.imgur.com/yLVW5aL.png)

### Triggering the Archive Feature
Press `Ctrl+C` at any point during setup. The script will:
- Bundle the current project state into `attendance_tracker_[name]_archive.tar.gz`
- Delete the incomplete directory automatically

![Archive](https://i.imgur.com/xzBwvYy.png)

### Updating Thresholds
When prompted during setup, enter `y` to update thresholds, or edit `Helpers/config.json` directly:
```json
{
    "thresholds": {
        "warning": 75,
        "failure": 50
    },
    "run_mode": "live",
    "total_sessions": 15
}
```
Note: `total_sessions` defines the total number of classes used in the attendance calculation — it is **not** stored per row in the CSV.

### Adding More Students
Edit the `Helpers/assets.csv` file in your application directory. The columns must match exactly:
```
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
```

## File Structure
```
attendance_tracker_<name>/
├── attendance_checker.py       # Main application logic
├── Helpers/
│   ├── assets.csv              # Student attendance records
│   └── config.json             # Threshold configuration
└── reports/
    └── reports.log             # Generated attendance reports
```

## Attendance Thresholds
Attendance percentage is calculated as `(Attendance Count / total_sessions) * 100`.

| Status   | Range    | Behavior                              |
|----------|----------|---------------------------------------|
| (silent) | ≥ 75%    | No alert logged                       |
| WARNING  | 50–74%   | Warning alert logged to `reports.log` |
| URGENT   | < 50%    | Failure alert logged to `reports.log` |

Thresholds are stored in `Helpers/config.json` and read at runtime by `attendance_checker.py`.

## Troubleshooting
- Ensure Python 3 is installed before running `attendance_checker.py`
- Run `setup_project.sh` from the repository root directory
- If `sed` edits fail, verify `Helpers/config.json` is writable

## Video Walkthrough
[Video Walkthrough](https://drive.google.com/file/d/1in-Hz2V7tZqCQ7Q4Ox_UAS9nyvXarLD7/view)

## Author
[Ihirwe Hildegardine](https://github.com/23Ihirwe)
