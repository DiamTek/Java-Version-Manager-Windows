// Java Version Manager
// Copyright (C) 2026 DiamTek / Alexéy Shishkin
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

use std::env;
use std::fs;
use std::os::windows::fs::MetadataExt;
use std::path::{Path, PathBuf};
use std::process::Command;

const FILE_ATTRIBUTE_REPARSE_POINT: u32 = 0x00000400;

/// Validates that a path is an existing, non-reparse point (no symlink/junction) regular file (CWE-59).
fn is_secure_file(path: &Path) -> bool {
    if let Ok(metadata) = fs::symlink_metadata(path) {
        if !metadata.is_file() {
            return false;
        }
        let attrs = metadata.file_attributes();
        if (attrs & FILE_ATTRIBUTE_REPARSE_POINT) != 0 {
            return false;
        }
        return true;
    }
    false
}

/// Verifies that no ancestor directory in the lineage is a reparse point (CWE-59).
fn has_reparse_in_lineage(path: &Path) -> bool {
    let mut current = path;
    while let Some(parent) = current.parent() {
        if let Ok(metadata) = fs::symlink_metadata(parent) {
            let attrs = metadata.file_attributes();
            if (attrs & FILE_ATTRIBUTE_REPARSE_POINT) != 0 {
                return true;
            }
        }
        if current == parent {
            break;
        }
        current = parent;
    }
    false
}

/// Resolves the trusted, authentic jvm.bat engine script without relying on CWD or arbitrary PATH (CWE-426).
fn find_jvm_bat() -> Option<PathBuf> {
    // 1. Check directory of the current jvm.exe
    if let Ok(exe_path) = env::current_exe() {
        if let Some(dir) = exe_path.parent() {
            let candidate = dir.join("jvm.bat");
            if is_secure_file(&candidate) && !has_reparse_in_lineage(&candidate) {
                return Some(candidate);
            }
            // Check parent directory (e.g. if exe is staged in bin/)
            let parent_candidate = dir.join("..").join("jvm.bat");
            if is_secure_file(&parent_candidate) && !has_reparse_in_lineage(&parent_candidate) {
                if let Ok(canonical) = parent_candidate.canonicalize() {
                    let cleaned_str = canonical.to_string_lossy();
                    let trimmed = cleaned_str.strip_prefix(r"\\?\").unwrap_or(&cleaned_str);
                    let clean_path = PathBuf::from(trimmed);
                    if is_secure_file(&clean_path) && !has_reparse_in_lineage(&clean_path) {
                        return Some(clean_path);
                    }
                }
            }
        }
    }

    // 2. Check canonical LOCALAPPDATA location: %LOCALAPPDATA%\DiamTek\JVM\bin\jvm.bat
    if let Ok(local_app_data) = env::var("LOCALAPPDATA") {
        let local_path = Path::new(&local_app_data);
        if !local_app_data.is_empty() && local_path.is_absolute() {
            let candidate = local_path
                .join("DiamTek")
                .join("JVM")
                .join("bin")
                .join("jvm.bat");
            if is_secure_file(&candidate) && !has_reparse_in_lineage(&candidate) {
                return Some(candidate);
            }

            let root_candidate = local_path
                .join("DiamTek")
                .join("JVM")
                .join("jvm.bat");
            if is_secure_file(&root_candidate) && !has_reparse_in_lineage(&root_candidate) {
                return Some(root_candidate);
            }
        }
    }

    None
}

/// Securely locates the system cmd.exe shell, verifying SystemRoot and preventing CWD hijacking (CWE-426).
fn get_trusted_cmd() -> PathBuf {
    let sys_root = env::var("SystemRoot")
        .or_else(|_| env::var("windir"))
        .unwrap_or_else(|_| "C:\\Windows".to_string());

    let primary_cmd = Path::new(&sys_root).join("System32").join("cmd.exe");
    if is_secure_file(&primary_cmd) {
        return primary_cmd;
    }

    let fallback_cmd = PathBuf::from(r"C:\Windows\System32\cmd.exe");
    if is_secure_file(&fallback_cmd) {
        return fallback_cmd;
    }

    // Default to canonical path
    primary_cmd
}

fn main() {
    let jvm_bat = match find_jvm_bat() {
        Some(path) => path,
        None => {
            eprintln!("[ ERROR  ] Could not locate authentic 'jvm.bat' engine script.");
            eprintln!("           Ensure Java Version Manager is properly installed in %LOCALAPPDATA%\\DiamTek\\JVM");
            std::process::exit(1);
        }
    };

    let cmd_exe = get_trusted_cmd();
    let args: Vec<String> = env::args().skip(1).collect();

    // Prevent binary planting in CWD (CWE-426)
    env::set_var("NoDefaultCurrentDirectoryInExePath", "1");

    // Construct cmd.exe execution: cmd.exe /c "<path_to_jvm.bat>" arg1 arg2 ...
    let mut cmd = Command::new(&cmd_exe);
    cmd.arg("/c");
    cmd.arg(&jvm_bat);

    for arg in &args {
        cmd.arg(arg);
    }

    // Set launcher indicator
    cmd.env("JVM_LAUNCHER_EXE", "1");

    match cmd.status() {
        Ok(status) => {
            let code = status.code().unwrap_or_else(|| {
                if status.success() { 0 } else { 1 }
            });
            std::process::exit(code);
        }
        Err(err) => {
            eprintln!("[ ERROR  ] Failed to execute JVM engine: {}", err);
            std::process::exit(1);
        }
    }
}
