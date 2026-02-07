#!/usr/bin/env python3
import sys
import os
import json
import re
import argparse
import urllib.request
import concurrent.futures

# Setup path to import vsdownload from the same directory
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

try:
    import vsdownload
except ImportError:
    print("Error: Could not import vsdownload module from the same directory.", file=sys.stderr)
    sys.exit(1)

def to_semver(version_str):
    """
    Convert a Microsoft 4-part major.minor.build.revision version (e.g., 14.38.17.8) to a
    SemVer 2.0 string (e.g., 14.38.17+rev-8).
    Handles standard SemVer strings as well.
    Confer https://semver.org/ and https://learn.microsoft.com/en-us/windows/win32/sbscs/assembly-versions.
    """
    # Remove any existing build metadata or prerelease info to process the numeric core first if simpler logic preferred
    # But here we assume input like "14.38.17.8" or "14.30.17.0"
    if '+' in version_str or '-' in version_str:
        # Already has semver-like markers, assume user knows what they are doing or it's complex.
        return version_str
        
    parts = version_str.split('.')
    if len(parts) == 4:
        # Quadruple: Major.Minor.Build.Revision
        # SemVer: Major.Minor.Patch[+Label]
        # We map Revision to build metadata.
        if parts[3] == "0":
             return f"{parts[0]}.{parts[1]}.{parts[2]}"
        else:
             return f"{parts[0]}.{parts[1]}.{parts[2]}+rev-{parts[3]}"
    return version_str

def fetch_real_size(url, manifest_size, retries=3):
    """
    Head the URL to get the Content-Length.
    If fails or matches manifest_size, returns appropriate value.
    """
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, method='HEAD')
            # Add User-Agent to avoid some blocking
            req.add_header('User-Agent', 'vsdownload-python')
            with urllib.request.urlopen(req, timeout=10) as response:
                cl = response.headers.get('Content-Length')
                if cl:
                    return int(cl)
        except Exception as e:
            if attempt == retries - 1:
                # Only log error on last attempt to avoid spam
                # print(f"Warning: Failed to HEAD {url}: {e}", file=sys.stderr)
                pass
    return manifest_size

def main():
    parser = argparse.ArgumentParser(description="Generate values.jsonc for MSVC from Visual Studio Manifest")
    parser.add_argument("--manifest", required=True, help="Path to manifest.json")
    parser.add_argument("--msvc-version", required=True, help="MSVC Version (e.g. 14.38.17.8) for the Bundle ID")
    parser.add_argument("--component", action="append", dest="components", help="Component ID to include (e.g. Microsoft.VisualStudio.Workload.VCTools). Can be specified multiple times.")
    parser.add_argument("--output", required=True, help="Output .values.jsonc file path")
    parser.add_argument("--temp-dir", default="build/tmp", help="Temporary directory for finding/downloading manifest if needed")
    
    args = parser.parse_args()
    
    if not args.components:
        print("Error: No components specified. Use --component <ID>", file=sys.stderr)
        sys.exit(1)

    print(f"Reading manifest from {args.manifest}...", file=sys.stderr)
    
    # Mock args for vsdownload functions
    class MockArgs:
        manifest = args.manifest
        package = args.components
        # Default behavior flags
        save_manifest = False
        cache = None
        dest = None
        ignore = []
        accept_license = True
        include_optional = False
        skip_recommended = False
        host_arch = "x64" # Assume x64 host for now
        architecture = ["x86", "x64", "arm", "arm64"]
        msvc_version = None
        sdk_version = None
        with_wdk_installers = None
        skip_patch = False
        only_host = False
        
        # Required attributes for some functions
        major = 17 # default
        preview = False
        print_deps_tree = False
        print_reverse_deps = False
        only_download = False
        only_unpack = False
        keep_unpack = False
        
        # These affect setPackageSelection defaults if package list was empty
        full = False
        
        # Required for later versions of vsdownload or specific paths
        print_selection = False
        list_workloads = False
        list_components = False
        list_packages = False
        
    mock_args = MockArgs()

    # 1. Load Manifest
    # vsdownload.getManifest(args) handles fetching if args.manifest is None, or reading file if it exists.
    manifest = vsdownload.getManifest(mock_args)
    if not manifest:
        print("Error: Failed to load manifest.", file=sys.stderr)
        sys.exit(1)

    # 2. Get Packages map
    print("Loading packages...", file=sys.stderr)
    packages = vsdownload.getPackages(manifest, mock_args.host_arch)
    
    # 3. Apply selection
    # Use only the explicit components provided on the command line as the
    # initial package selection. Do NOT call vsdownload.setPackageSelection()
    # which may insert default packages or expand the selection beyond what
    # the user explicitly requested. We only want the packages for the
    # specified components plus their transitive dependencies.
    print(f"Selecting packages (explicit components): {args.components}", file=sys.stderr)

    # Ensure mock_args.package is the list of component ids provided
    mock_args.package = list(args.components)

    # 4. Resolve dependencies (aggregate transitive deps for the given components)
    print("Resolving dependencies...", file=sys.stderr)
    selected_packages = vsdownload.getSelectedPackages(packages, mock_args)
    
    print(f"Selected {len(selected_packages)} packages including dependencies.", file=sys.stderr)
    
    # 5. Extract Assets
    assets = []
    
    total_size = 0
    seen_urls = set()
    
    # Origins map: mapping from base_url to origin_name
    VS_ORIGIN_URL = "https://download.visualstudio.microsoft.com/download/pr/"
    VS_ORIGIN_NAME = "visual-studio-mirror"
    
    origins_map = {
        VS_ORIGIN_URL: VS_ORIGIN_NAME
    }

    # Helper list for parallel size checking
    asset_checks = []

    for pkg in selected_packages:
        payloads = pkg.get("payloads", [])
        for payload in payloads:
            url = payload.get("url")
            file_name = payload.get("fileName")
            sha256 = payload.get("sha256")
            # Normalize checksum to lowercase to satisfy dk0 strict matching
            if sha256:
                sha256 = sha256.lower()
            size = payload.get("size")
            
            if not url or not file_name or not sha256:
                continue
            
            # Avoid duplicates if multiple packages point to same payload (rare but possible)
            if url in seen_urls:
                continue
            seen_urls.add(url)
            
            # Determine Origin and Path
            origin = None
            path = None
            
            # Check known origins
            for base_url, name in origins_map.items():
                if url.startswith(base_url):
                    origin = name
                    path = url[len(base_url):]
                    break
            
            # If not found, create new origin
            if not origin:
                last_slash = url.rfind('/')
                if last_slash != -1:
                    base_url = url[:last_slash+1]
                    path = url[last_slash+1:]
                    
                    # Generate a name
                    # Simple heuristic: domain name or just generic
                    origin = f"origin-{len(origins_map)}"
                    origins_map[base_url] = origin
                    print(f"Adding new origin: {origin} -> {base_url}", file=sys.stderr)
                else:
                    print(f"Warning: Cannot parse URL {url}. Skipping.", file=sys.stderr)
                    continue

            # Create asset entry without 'url', with 'origin'
            asset = {
                "x-msvc-component": pkg.get("id", "Unknown"),
                "origin": origin,
                "path": path, 
                "size": size,
                "checksum": {
                    "sha256": sha256
                }
            }
            
            assets.append(asset)
            asset_checks.append((asset, url))
            total_size += size
            
    print(f"Found {len(assets)} assets. Initial size from manifest: {total_size/1024/1024:.2f} MB", file=sys.stderr)

    # Parallelize size checking
    print(f"Verifying real file sizes (manifest sizes are unreliable)... This may take a while.", file=sys.stderr)
    
    corrected_count = 0
    total_assets = len(assets)
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=32) as executor:
        future_map = {executor.submit(fetch_real_size, url, asset["size"]): asset for asset, url in asset_checks}
        
        completed = 0
        for future in concurrent.futures.as_completed(future_map):
            asset = future_map[future]
            completed += 1
            try:
                real_size = future.result()
                if real_size != asset["size"]:
                    asset["size"] = real_size
                    corrected_count += 1
            except Exception:
                pass
            
            if completed % 50 == 0 or completed == total_assets:
                print(f"Checked {completed}/{total_assets} assets...", file=sys.stderr)
                
    print(f"Size verification complete. Corrected {corrected_count} asset sizes.", file=sys.stderr)
    
    # Construct listing definitions
    origin_definitions = []
    # Ensure visual-studio-mirror is first if present (nicer output)
    if VS_ORIGIN_URL in origins_map:
         origin_definitions.append({
             "name": VS_ORIGIN_NAME,
             "mirrors": [VS_ORIGIN_URL]
         })
         
    for base_url, name in origins_map.items():
        if base_url == VS_ORIGIN_URL: continue
        origin_definitions.append({
             "name": name,
             "mirrors": [base_url]
         })

    # 6. Generate JSONC
    semver_version = to_semver(args.msvc_version)
    output_obj = {
        "$schema": "https://github.com/diskuv/dk/raw/refs/heads/V2_5/etc/jsonschema/dk-values.json",
        "schema_version": {"major": 1, "minor": 0},
        "bundles": [
            {
                "id": f"CommonsBase_VisualStudio.MSVC.Bundle@{semver_version}",
                "listing": {
                    "origins": origin_definitions
                },
                "assets": assets
            }
        ]
    }
    
    # Write output
    with open(args.output, "w") as f:
        f.write("/*\n")
        f.write(" * This file is automatically generated. Do not edit directly.\n")
        f.write(" * Generated by maintenance/generate_msvc_config.py\n")
        f.write(" */\n")
        json.dump(output_obj, f, indent=2)
        
    print(f"Written to {args.output}", file=sys.stderr)

if __name__ == "__main__":
    main()
