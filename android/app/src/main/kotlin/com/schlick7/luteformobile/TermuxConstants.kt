package com.schlick7.luteformobile

object TermuxConstants {
    // Termux package and service info
    const val TERMUX_PACKAGE = "com.termux"
    const val TERMUX_SERVICE = "com.termux.app.RunCommandService"
    const val TERMUX_MAIN_ACTIVITY = "com.termux.app.TermuxActivity"
    const val TERMUX_ACTION = "com.termux.RUN_COMMAND"
    const val TERMUX_BASH_PATH = "/data/data/com.termux/files/usr/bin/bash"
    const val TERMUX_HOME = "/data/data/com.termux/files/home"
    const val TERMUX_LUTE3_DIR = "$TERMUX_HOME/.lute3"

    // Lute3 configuration
    const val LUTE3_DEFAULT_PORT = 5001
    const val LUTE3_DATA_DIR = "$TERMUX_HOME/.local/share/lute3"
    const val LUTE3_DB_PATH = "$LUTE3_DATA_DIR/lute.db"

    // File paths for status tracking (use Downloads directory which both apps can access)
    val HEARTBEAT_FILE: String
        get() = "${StorageHelper.getDownloadsDirectory()}/lute3_heartbeat.txt"
    val INSTALLATION_STATUS_FILE: String
        get() = "${StorageHelper.getDownloadsDirectory()}/lute3_installation_status.txt"
    val VERSION_FILE: String
        get() = "${StorageHelper.getDownloadsDirectory()}/lute3_version.txt"
    val TEST_EXTERNAL_FILE: String
        get() = "${StorageHelper.getDownloadsDirectory()}/termux_test_external.txt"

    // Command completion tracking
    val COMMAND_STATUS_DIR: String
        get() = "${StorageHelper.getDownloadsDirectory()}/lute3_commands"

    val DOWNLOADS_DIR: String
        get() = StorageHelper.getDownloadsDirectory().absolutePath
    const val COMMAND_SUCCESS = "SUCCESS"
    const val COMMAND_FAILED = "FAILED"

    // tmux configuration
    const val TMUX_SOCKET_DIR = "/data/data/com.termux/files/usr/var/run/tmux"
    val TMUX_SOCKET_FILE: String
        get() = "$TMUX_SOCKET_DIR/lute_session_socket"
    const val TMUX_INSTALL_TIMEOUT = 180  // 3 minutes for tmux installation
    const val TMUX_CONFIGURE_TIMEOUT = 30  // 30 seconds for tmux configuration

    // Timeouts (in seconds)
    const val INSTALLATION_CHECK_DELAY = 3
    const val VERSION_CHECK_DELAY = 2
    const val EXTERNAL_APP_CHECK_DELAY = 2
    const val SERVER_START_TIMEOUT = 30
    const val HEARTBEAT_CHECK_INTERVAL = 120  // 2 minutes
    const val IDLE_TIMEOUT_MINUTES = 30
    const val TERMUX_STEALTH_LAUNCH_TIMEOUT = 1500L // milliseconds

    // Command timeout estimates (maximum seconds to wait)
    const val SETUP_STORAGE_TIMEOUT = 60
    const val UPDATE_PACKAGES_TIMEOUT = 120
    const val UPGRADE_PACKAGES_TIMEOUT = 600
    const val INSTALL_PYTHON_TIMEOUT = 900
    const val INSTALL_LUTE3_TIMEOUT = 600
    const val COMMAND_POLL_INTERVAL = 2  // Check every 2 seconds
}
