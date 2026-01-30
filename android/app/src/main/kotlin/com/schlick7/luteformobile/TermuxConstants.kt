package com.schlick7.luteformobile

object TermuxConstants {
    // Termux package and service info
    const val TERMUX_PACKAGE = "com.termux"
    const val TERMUX_SERVICE = "com.termux.app.RunCommandService"
    const val TERMUX_ACTION = "com.termux.RUN_COMMAND"
    const val TERMUX_BASH_PATH = "/data/data/com.termux/files/usr/bin/bash"
    const val TERMUX_HOME = "/data/data/com.termux/files/home"
    const val TERMUX_LUTE3_DIR = "$TERMUX_HOME/.lute3"

    // Lute3 configuration
    const val LUTE3_DEFAULT_PORT = 5001
    const val LUTE3_DATA_DIR = "$TERMUX_HOME/.local/share/lute3"
    const val LUTE3_DB_PATH = "$LUTE3_DATA_DIR/lute.db"

    // File paths for status tracking
    const val HEARTBEAT_FILE = "$TERMUX_LUTE3_DIR/heartbeat"
    const val INSTALLATION_STATUS_FILE = "$TERMUX_LUTE3_DIR/installation_status.txt"
    const val VERSION_FILE = "$TERMUX_LUTE3_DIR/version.txt"
    const val TERMUX_VERSION_FILE = "$TERMUX_LUTE3_DIR/termux_version.txt"
    const val TEST_EXTERNAL_FILE = "$TERMUX_LUTE3_DIR/test_external.txt"

    // Command completion tracking
    const val COMMAND_STATUS_DIR = "$TERMUX_LUTE3_DIR/commands"
    const val COMMAND_SUCCESS = "SUCCESS"
    const val COMMAND_FAILED = "FAILED"

    // Timeouts (in seconds)
    const val INSTALLATION_CHECK_DELAY = 3
    const val VERSION_CHECK_DELAY = 2
    const val EXTERNAL_APP_CHECK_DELAY = 2
    const val SERVER_START_TIMEOUT = 30
    const val HEARTBEAT_CHECK_INTERVAL = 120  // 2 minutes
    const val IDLE_TIMEOUT_MINUTES = 30

    // Command timeout estimates (maximum seconds to wait)
    const val SETUP_STORAGE_TIMEOUT = 60
    const val UPDATE_PACKAGES_TIMEOUT = 120
    const val UPGRADE_PACKAGES_TIMEOUT = 600
    const val INSTALL_PYTHON_TIMEOUT = 900
    const val INSTALL_LUTE3_TIMEOUT = 600
    const val COMMAND_POLL_INTERVAL = 2  // Check every 2 seconds
}
