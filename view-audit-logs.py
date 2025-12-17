#!/usr/bin/env python3
"""
EHR Keys Management System - Audit Log Viewer
Parses and analyzes OpenBao audit logs in human-readable format
"""

import json
import sys
import os
import argparse
from datetime import datetime
from collections import defaultdict, Counter
from typing import Dict, List, Any, Optional

class AuditLogViewer:
    """Viewer for OpenBao audit logs"""
    
    def __init__(self, log_path: str = "./openbao/logs/audit.log"):
        self.log_path = log_path
        self.entries = []
        
    def load_logs(self) -> bool:
        """Load and parse audit log entries"""
        if not os.path.exists(self.log_path):
            print(f"Error: Audit log file not found at {self.log_path}")
            return False
            
        try:
            with open(self.log_path, 'r') as f:
                for line_num, line in enumerate(f, 1):
                    line = line.strip()
                    if not line:
                        continue
                        
                    try:
                        entry = json.loads(line)
                        self.entries.append(entry)
                    except json.JSONDecodeError as e:
                        print(f"Warning: Could not parse line {line_num}: {e}")
                        
            print(f"Loaded {len(self.entries)} audit log entries")
            return True
            
        except Exception as e:
            print(f"Error loading audit logs: {e}")
            return False
    
    def format_timestamp(self, timestamp: str) -> str:
        """Format ISO timestamp to human-readable format"""
        try:
            dt = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
            return dt.strftime("%Y-%m-%d %H:%M:%S")
        except:
            return timestamp
    
    def get_operation_type(self, path: str) -> str:
        """Categorize operation based on API path"""
        if not path:
            return "Unknown"
            
        path_lower = path.lower()
        
        # Authentication operations
        if path_lower.startswith('auth/'):
            return "Authentication"
        
        # Key management operations
        elif path_lower.startswith('transit/'):
            return "Key Management"
        
        # System operations
        elif path_lower.startswith('sys/'):
            if 'policy' in path_lower or 'acl' in path_lower:
                return "Policy Management"
            elif 'audit' in path_lower:
                return "Audit Management"
            else:
                return "System Operations"
        
        # Secrets operations
        elif path_lower.startswith('secret/') or path_lower.startswith('kv/'):
            return "Secrets Management"
        
        # Identity operations
        elif path_lower.startswith('identity/'):
            return "Identity Management"
        
        else:
            return "Other Operations"
    
    def print_summary(self):
        """Print summary statistics"""
        if not self.entries:
            print("No audit log entries to analyze")
            return
        
        print("\n" + "="*60)
        print("AUDIT LOG SUMMARY")
        print("="*60)
        
        # Basic statistics
        total_entries = len(self.entries)
        print(f"Total entries: {total_entries}")
        
        # Time range
        timestamps = []
        for entry in self.entries:
            if 'time' in entry:
                timestamps.append(entry['time'])
        
        if timestamps:
            try:
                first = min(timestamps)
                last = max(timestamps)
                print(f"Time range: {self.format_timestamp(first)} to {self.format_timestamp(last)}")
            except:
                pass
        
        # Operation type breakdown
        print("\nOperation Type Breakdown:")
        print("-"*40)
        
        op_counts = Counter()
        for entry in self.entries:
            path = entry.get('request', {}).get('path', '')
            op_type = self.get_operation_type(path)
            op_counts[op_type] += 1
        
        for op_type, count in op_counts.most_common():
            percentage = (count / total_entries) * 100
            print(f"  {op_type:<20} {count:>5} ({percentage:.1f}%)")
        
        # HTTP method breakdown
        print("\nHTTP Method Breakdown:")
        print("-"*40)
        
        method_counts = Counter()
        for entry in self.entries:
            method = entry.get('request', {}).get('method', 'UNKNOWN')
            method_counts[method] += 1
        
        for method, count in method_counts.most_common():
            percentage = (count / total_entries) * 100
            print(f"  {method:<10} {count:>5} ({percentage:.1f}%)")
        
        # Client IP breakdown (if available)
        print("\nClient IP Statistics (top 10):")
        print("-"*40)
        
        ip_counts = Counter()
        for entry in self.entries:
            remote_addr = entry.get('request', {}).get('remote_address', '')
            if remote_addr:
                ip_counts[remote_addr] += 1
        
        if ip_counts:
            for ip, count in ip_counts.most_common(10):
                percentage = (count / total_entries) * 100
                print(f"  {ip:<20} {count:>5} ({percentage:.1f}%)")
        else:
            print("  No client IP information available")
    
    def print_entries(self, limit: int = 10, filter_type: Optional[str] = None):
        """Print individual audit log entries"""
        if not self.entries:
            print("No audit log entries to display")
            return
        
        print(f"\n{'='*80}")
        print(f"AUDIT LOG ENTRIES{'' if not filter_type else f' - {filter_type}'}")
        print(f"{'='*80}")
        
        displayed = 0
        for i, entry in enumerate(reversed(self.entries), 1):
            if limit and displayed >= limit:
                break
            
            # Apply filter if specified
            if filter_type:
                path = entry.get('request', {}).get('path', '')
                entry_type = self.get_operation_type(path)
                if entry_type != filter_type:
                    continue
            
            self.print_entry(entry, i)
            displayed += 1
        
        if displayed == 0:
            print(f"No entries found matching filter: {filter_type}")
        else:
            print(f"\nDisplayed {displayed} of {len(self.entries)} total entries")
    
    def print_entry(self, entry: Dict[str, Any], index: int = 1):
        """Print a single audit log entry in human-readable format"""
        print(f"\n[{index}] Entry")
        print("-"*40)
        
        # Basic information
        if 'time' in entry:
            print(f"Time:      {self.format_timestamp(entry['time'])}")
        
        # Request information
        request = entry.get('request', {})
        if request:
            print(f"Method:    {request.get('method', 'N/A')}")
            print(f"Path:      {request.get('path', 'N/A')}")
            
            # Operation type
            path = request.get('path', '')
            op_type = self.get_operation_type(path)
            print(f"Type:      {op_type}")
            
            # Client information
            remote_addr = request.get('remote_address', '')
            if remote_addr:
                print(f"Client:    {remote_addr}")
            
            # Request ID
            request_id = request.get('id', '')
            if request_id:
                print(f"Request ID: {request_id}")
        
        # Response information
        response = entry.get('response', {})
        if response:
            status_code = response.get('status_code', '')
            if status_code:
                status_text = "SUCCESS" if 200 <= status_code < 300 else "ERROR"
                print(f"Status:    {status_code} ({status_text})")
        
        # Error information (if any)
        if 'error' in entry:
            print(f"Error:     {entry['error']}")
    
    def search_entries(self, search_term: str, case_sensitive: bool = False):
        """Search audit log entries for specific terms"""
        if not self.entries:
            print("No audit log entries to search")
            return
        
        print(f"\n{'='*80}")
        print(f"SEARCH RESULTS for: '{search_term}'")
        print(f"{'='*80}")
        
        matches = []
        search_term_lower = search_term if case_sensitive else search_term.lower()
        
        for entry in self.entries:
            # Convert entry to JSON string for searching
            entry_str = json.dumps(entry)
            if not case_sensitive:
                entry_str = entry_str.lower()
            
            if search_term_lower in entry_str:
                matches.append(entry)
        
        if not matches:
            print(f"No entries found containing '{search_term}'")
            return
        
        print(f"Found {len(matches)} matching entries")
        
        for i, entry in enumerate(reversed(matches), 1):
            if i > 20:  # Limit display to 20 matches
                print(f"\n... and {len(matches) - 20} more matches")
                break
            self.print_entry(entry, i)
    
    def export_report(self, output_file: str):
        """Export audit log analysis to a text file"""
        try:
            with open(output_file, 'w') as f:
                # Redirect stdout to file
                original_stdout = sys.stdout
                sys.stdout = f
                
                print("EHR Keys Management System - Audit Log Report")
                print("="*60)
                print(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
                print(f"Log file: {self.log_path}")
                print(f"Total entries: {len(self.entries)}")
                print()
                
                self.print_summary()
                print("\n\nRECENT ENTRIES:")
                self.print_entries(limit=50)
                
                # Restore stdout
                sys.stdout = original_stdout
            
            print(f"\nReport exported to: {output_file}")
            
        except Exception as e:
            print(f"Error exporting report: {e}")

def main():
    parser = argparse.ArgumentParser(
        description="OpenBao Audit Log Viewer - Parse and analyze audit logs"
    )
    parser.add_argument(
        "--file", "-f",
        default="./openbao/logs/audit.log",
        help="Path to audit log file (default: ./openbao/logs/audit.log)"
    )
    parser.add_argument(
        "--summary", "-s",
        action="store_true",
        help="Show summary statistics"
    )
    parser.add_argument(
        "--entries", "-e",
        type=int,
        default=0,
        help="Show N most recent entries (default: 10, 0 for all)"
    )
    parser.add_argument(
        "--filter", "-t",
        choices=["Authentication", "Key Management", "Policy Management", 
                "System Operations", "Secrets Management", "Identity Management",
                "Audit Management", "Other Operations"],
        help="Filter entries by operation type"
    )
    parser.add_argument(
        "--search", "-q",
        help="Search for entries containing specific text"
    )
    parser.add_argument(
        "--export", "-x",
        help="Export report to specified file"
    )
    
    args = parser.parse_args()
    
    # Create viewer instance
    viewer = AuditLogViewer(args.file)
    
    # Load logs
    if not viewer.load_logs():
        sys.exit(1)
    
    # Process commands
    if args.export:
        viewer.export_report(args.export)
    
    if args.summary:
        viewer.print_summary()
    
    if args.search:
        viewer.search_entries(args.search)
    
    if args.entries != 0:
        limit = args.entries if args.entries > 0 else None
        viewer.print_entries(limit=limit, filter_type=args.filter)
    elif not any([args.summary, args.search, args.export]):
        # Default: show summary and recent entries
        viewer.print_summary()
        viewer.print_entries(limit=10)

if __name__ == "__main__":
    main()
