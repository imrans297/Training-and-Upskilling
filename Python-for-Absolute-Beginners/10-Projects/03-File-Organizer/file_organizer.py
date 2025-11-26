#!/usr/bin/env python3
"""
File Organizer - Starter Code
"""

import os
import shutil
import sys

CATEGORIES = {
    'Images': ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg'],
    'Documents': ['.pdf', '.doc', '.docx', '.txt', '.xlsx', '.pptx'],
    'Videos': ['.mp4', '.avi', '.mkv', '.mov'],
    'Audio': ['.mp3', '.wav', '.flac'],
    'Archives': ['.zip', '.tar', '.gz', '.rar'],
    'Code': ['.py', '.js', '.java', '.cpp', '.sh']
}

def get_category(file_extension):
    """Determine category for file extension"""
    # TODO: Implement
    pass

def create_folders(base_path):
    """Create category folders"""
    # TODO: Implement
    pass

def organize_files(directory):
    """Organize files in directory"""
    # TODO: Implement
    # 1. List all files
    # 2. For each file, determine category
    # 3. Move to appropriate folder
    # 4. Handle errors
    pass

def generate_report(organized_files):
    """Generate organization report"""
    # TODO: Implement
    pass

def main():
    """Main function"""
    if len(sys.argv) < 2:
        print("Usage: python3 file_organizer.py <directory>")
        return
    
    directory = sys.argv[1]
    
    if not os.path.exists(directory):
        print(f"Error: {directory} does not exist")
        return
    
    # TODO: Implement main logic
    print(f"Organizing files in: {directory}")

if __name__ == "__main__":
    main()
