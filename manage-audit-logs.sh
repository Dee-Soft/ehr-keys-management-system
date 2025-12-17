#!/bin/bash

# EHR Keys Management System - Audit Log Management Script
# Provides tools to manage OpenBao audit devices and audit logs

set -e

# Default configuration
OPENBAO_ADDR="${OPENBAO_ADDR:-http://localhost:18200}"
OPENBAO_TOKEN="${OPENBAO_TOKEN:-ehr-permanent-token}"
AUDIT_LOG_PATH="./openbao/logs/audit.log"
OPERATIONAL_LOG_PATH="./openbao/logs/openbao.log"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to test OpenBao connectivity
test_openbao_connection() {
    print_status "Testing OpenBao connectivity..."
    
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
        --header "X-Vault-Token: $OPENBAO_TOKEN" \
        "$OPENBAO_ADDR/v1/sys/health")
    
    if [ "$RESPONSE" = "200" ] || [ "$RESPONSE" = "501" ]; then
        print_success "OpenBao is accessible"
        return 0
    else
        print_error "OpenBao connection failed (HTTP $RESPONSE)"
        return 1
    fi
}

# Function to list audit devices
list_audit_devices() {
    print_status "Listing audit devices..."
    
    curl -s --header "X-Vault-Token: $OPENBAO_TOKEN" \
        "$OPENBAO_ADDR/v1/sys/audit" | jq -r '.data'
}

# Function to enable file audit device
enable_file_audit() {
    local file_path="${1:-/vault/logs/audit.log}"
    
    print_status "Enabling file audit device at $file_path..."
    
    curl -s --header "X-Vault-Token: $OPENBAO_TOKEN" \
        --header "Content-Type: application/json" \
        --request POST \
        --data "{\"type\":\"file\",\"options\":{\"file_path\":\"$file_path\"}}" \
        "$OPENBAO_ADDR/v1/sys/audit/file"
    
    if [ $? -eq 0 ]; then
        print_success "File audit device enabled"
    else
        print_error "Failed to enable file audit device"
    fi
}

# Function to disable audit device
disable_audit_device() {
    local device_name="${1:-file}"
    
    print_status "Disabling audit device: $device_name..."
    
    curl -s --header "X-Vault-Token: $OPENBAO_TOKEN" \
        --request DELETE \
        "$OPENBAO_ADDR/v1/sys/audit/$device_name"
    
    if [ $? -eq 0 ]; then
        print_success "Audit device '$device_name' disabled"
    else
        print_error "Failed to disable audit device '$device_name'"
    fi
}

# Function to rotate audit logs
rotate_audit_logs() {
    print_status "Rotating audit logs..."
    
    if [ -f "$AUDIT_LOG_PATH" ]; then
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        local backup_path="${AUDIT_LOG_PATH}.${timestamp}"
        
        print_status "Backing up audit log to $backup_path"
        cp "$AUDIT_LOG_PATH" "$backup_path"
        
        print_status "Truncating current audit log"
        > "$AUDIT_LOG_PATH"
        
        print_success "Audit logs rotated successfully"
        echo "Backup created at: $backup_path"
    else
        print_warning "Audit log file not found at $AUDIT_LOG_PATH"
    fi
}

# Function to view audit log statistics
view_audit_stats() {
    print_status "Audit Log Statistics"
    echo "========================================"
    
    if [ -f "$AUDIT_LOG_PATH" ]; then
        local total_lines=$(wc -l < "$AUDIT_LOG_PATH")
        local file_size=$(du -h "$AUDIT_LOG_PATH" | cut -f1)
        local last_modified=$(stat -f "%Sm" "$AUDIT_LOG_PATH")
        
        echo "File: $AUDIT_LOG_PATH"
        echo "Size: $file_size"
        echo "Total entries: $total_lines"
        echo "Last modified: $last_modified"
        echo ""
        
        # Count by operation type (simplified)
        print_status "Operation type breakdown:"
        local auth_count=$(grep -c '"path":"auth/' "$AUDIT_LOG_PATH" 2>/dev/null || echo "0")
        local transit_count=$(grep -c '"path":"transit/' "$AUDIT_LOG_PATH" 2>/dev/null || echo "0")
        local sys_count=$(grep -c '"path":"sys/' "$AUDIT_LOG_PATH" 2>/dev/null || echo "0")
        local kv_count=$(grep -c '"path":"secret/' "$AUDIT_LOG_PATH" 2>/dev/null || echo "0")
        
        echo "  Authentication operations: $auth_count"
        echo "  Transit/key operations: $transit_count"
        echo "  System operations: $sys_count"
        echo "  Secret operations: $kv_count"
        
        # Show recent entries
        if [ "$total_lines" -gt 0 ]; then
            echo ""
            print_status "Recent audit entries (last 5):"
            tail -5 "$AUDIT_LOG_PATH" | while read line; do
                local timestamp=$(echo "$line" | jq -r '.time // "N/A"' 2>/dev/null || echo "N/A")
                local path=$(echo "$line" | jq -r '.request.path // "N/A"' 2>/dev/null || echo "N/A")
                local method=$(echo "$line" | jq -r '.request.method // "N/A"' 2>/dev/null || echo "N/A")
                echo "  $timestamp - $method $path"
            done
        fi
    else
        print_warning "Audit log file not found at $AUDIT_LOG_PATH"
    fi
}

# Function to test audit functionality
test_audit_functionality() {
    print_status "Testing audit functionality..."
    
    # Make a test API call that should be audited
    print_status "Making test API call to generate audit entry..."
    
    TEST_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null \
        --header "X-Vault-Token: $OPENBAO_TOKEN" \
        "$OPENBAO_ADDR/v1/sys/health")
    
    if [ "$TEST_RESPONSE" = "200" ] || [ "$TEST_RESPONSE" = "501" ]; then
        print_success "Test API call successful (HTTP $TEST_RESPONSE)"
        
        # Wait a moment for audit log to be written
        sleep 2
        
        # Check if audit log was updated
        if [ -f "$AUDIT_LOG_PATH" ]; then
            local recent_entry=$(tail -1 "$AUDIT_LOG_PATH")
            if echo "$recent_entry" | grep -q "sys/health"; then
                print_success "Audit log entry created successfully"
                echo "Recent audit entry:"
                echo "$recent_entry" | jq . 2>/dev/null || echo "$recent_entry"
            else
                print_warning "Test audit entry not found in log"
            fi
        else
            print_warning "Audit log file not created yet"
        fi
    else
        print_error "Test API call failed (HTTP $TEST_RESPONSE)"
    fi
}

# Function to show usage
show_usage() {
    echo "EHR Keys Management System - Audit Log Management"
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  list              - List configured audit devices"
    echo "  enable            - Enable file audit device"
    echo "  disable           - Disable file audit device"
    echo "  rotate            - Rotate audit logs (backup and truncate)"
    echo "  stats             - View audit log statistics"
    echo "  test              - Test audit functionality"
    echo "  help              - Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  OPENBAO_ADDR      - OpenBao address (default: http://localhost:18200)"
    echo "  OPENBAO_TOKEN     - OpenBao token (default: ehr-permanent-token)"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 enable"
    echo "  $0 stats"
    echo "  OPENBAO_TOKEN=custom-token $0 test"
}

# Main script logic
main() {
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        print_error "jq is required but not installed. Please install jq first."
        exit 1
    fi
    
    # Test connection first
    if ! test_openbao_connection; then
        print_error "Cannot connect to OpenBao. Please check if the service is running."
        exit 1
    fi
    
    case "${1:-help}" in
        list)
            list_audit_devices
            ;;
        enable)
            enable_file_audit "/vault/logs/audit.log"
            ;;
        disable)
            disable_audit_device "file"
            ;;
        rotate)
            rotate_audit_logs
            ;;
        stats)
            view_audit_stats
            ;;
        test)
            test_audit_functionality
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_error "Unknown command: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
