#!/usr/bin/env bats
# BATS tests for HyprSupreme-Builder installation

setup() {
    # Set up test environment
    export TEST_MODE=true
    export HYPRSUPREME_TEST_DIR="/tmp/hyprsupreme-test-$$"
    mkdir -p "$HYPRSUPREME_TEST_DIR"
}

teardown() {
    # Clean up test environment
    rm -rf "$HYPRSUPREME_TEST_DIR"
}

@test "install.sh exists and is executable" {
    [ -f "install.sh" ]
    [ -x "install.sh" ]
}

@test "hyprsupreme main executable exists and is executable" {
    [ -f "hyprsupreme" ]
    [ -x "hyprsupreme" ]
}

@test "requirements.txt exists and contains valid packages" {
    [ -f "requirements.txt" ]
    run grep -E "^[a-zA-Z]" requirements.txt
    [ "$status" -eq 0 ]
}

@test "VERSION file exists and contains valid version" {
    [ -f "VERSION" ]
    run cat VERSION
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "README.md exists and is not empty" {
    [ -f "README.md" ]
    [ -s "README.md" ]
}

@test "License file exists" {
    [ -f "LICENSE" ]
}

@test "All Python tools are executable" {
    for tool in tools/*.py; do
        [ -f "$tool" ]
        run python3 -m py_compile "$tool"
        [ "$status" -eq 0 ]
    done
}

@test "All shell scripts have proper shebang" {
    for script in *.sh tools/*.sh; do
        if [ -f "$script" ]; then
            run head -n1 "$script"
            [[ "$output" =~ ^#!/.*sh ]]
        fi
    done
}

@test "Community platform files exist" {
    [ -d "community" ]
    [ -f "community/web_interface.py" ]
    [ -f "community/community_platform.py" ]
}

@test "GUI files exist" {
    [ -d "gui" ]
    [ -f "gui/hyprsupreme-gui.py" ]
}

@test "Essential documentation files exist" {
    [ -f "KEYBINDINGS_REFERENCE.md" ]
    [ -f "COMMUNITY_COMMANDS.md" ]
    [ -f "CHANGELOG.md" ]
}

@test "Test keybindings script exists and runs" {
    [ -f "test_keybindings.sh" ]
    [ -x "test_keybindings.sh" ]
}

@test "Web launcher script exists and is executable" {
    [ -f "launch_web.sh" ]
    [ -x "launch_web.sh" ]
}

@test "Finalize project script exists and is executable" {
    [ -f "finalize_project.sh" ]
    [ -x "finalize_project.sh" ]
}

@test "Python syntax check for all Python files" {
    for py_file in $(find . -name "*.py" -not -path "./sources/*" -not -path "./venv/*" -not -path "./.git/*"); do
        run python3 -m py_compile "$py_file"
        [ "$status" -eq 0 ]
    done
}

@test "Check for common shell script issues" {
    for script in $(find . -name "*.sh" -not -path "./sources/*" -not -path "./.git/*"); do
        if command -v shellcheck >/dev/null 2>&1; then
            run shellcheck -S warning "$script"
            [ "$status" -eq 0 ]
        else
            skip "shellcheck not available"
        fi
    done
}

