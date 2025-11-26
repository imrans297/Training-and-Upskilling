# Project 3: File Organizer

## Objective
Create a script that organizes files in a directory by their extensions.

## Features

### 1. Scan Directory
- List all files in target directory
- Identify file extensions

### 2. Organize by Type
- Group files by extension
- Create folders: Images, Documents, Videos, Audio, Archives, Others

### 3. Move Files
- Move files to appropriate folders
- Handle name conflicts
- Preserve original files (optional backup)

### 4. Generate Report
- Show number of files organized
- List files moved to each category
- Display total size per category

## File Categories
```python
CATEGORIES = {
    'Images': ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg'],
    'Documents': ['.pdf', '.doc', '.docx', '.txt', '.xlsx', '.pptx'],
    'Videos': ['.mp4', '.avi', '.mkv', '.mov'],
    'Audio': ['.mp3', '.wav', '.flac'],
    'Archives': ['.zip', '.tar', '.gz', '.rar'],
    'Code': ['.py', '.js', '.java', '.cpp', '.sh']
}
```

## Usage
```bash
python3 file_organizer.py /path/to/directory
python3 file_organizer.py /path/to/directory --dry-run
python3 file_organizer.py /path/to/directory --backup
```

## Bonus Features
- Undo operation
- Custom categories
- Recursive organization
- Duplicate file detection
- Size-based organization

## Learning Outcomes
- File system operations
- Path manipulation
- Error handling
- Command-line arguments
