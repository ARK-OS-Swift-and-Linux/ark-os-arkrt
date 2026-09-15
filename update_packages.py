import os
import re

packages = {
    "Kernel": [
        "https://github.com/apple/swift-mmio",
        "https://github.com/apple/swift-atomics",
        "https://github.com/apple/swift-numerics"
    ],
    "Network": [
    ],
    "System": [
        "https://github.com/apple/swift-system",
        "https://github.com/xtremekforever/swift-systemd",
        "https://github.com/apple/swift-system-metrics",
        "https://github.com/swiftlang/swift-package-manager",
        "https://github.com/apple/swift-llbuild2",
        "https://github.com/apple/swift-algorithms",
        "https://github.com/apple/swift-async-algorithms"
    ],
    "Service": [
        "https://github.com/swift-server/swift-service-lifecycle",
        "https://github.com/apple/swift-log",
        "https://github.com/apple/swift-metrics",
        "https://github.com/apple/swift-statsd-client",
        "https://github.com/apple/swift-distributed-tracing",
        "https://github.com/apple/swift-distributed-tracing-baggage-core",
        "https://github.com/apple/swift-service-discovery",
        "https://github.com/apple/swift-service-context",
        "https://github.com/apple/servicetalk",
        "https://github.com/apple/swift-protobuf",
        "https://github.com/apple/swift-configuration",
        "https://github.com/apple/swift-ntp",
        "https://github.com/apple/swift-asn1",
        "https://github.com/apple/swift-certificates",
        "https://github.com/apple/swift-homomorphic-encryption",
        "https://github.com/apple/foundationdb",
        "https://github.com/apple/coreai-models",
        "https://github.com/apple/foundation-models-utilities"
    ],
    "Terminal": [
        "https://github.com/migueldeicaza/SwiftTerm",
        "https://github.com/moreSwift/swift-cross-ui"
    ]
}

def update_package(directory, repos):
    pkg_path = os.path.join(directory, "Package.swift")
    if not os.path.exists(pkg_path):
        print(f"Skipping {pkg_path} (not found)")
        return
    
    with open(pkg_path, "r") as f:
        content = f.read()
    
    # We want to insert dependencies into dependencies: [ ... ]
    # Find the dependencies array: dependencies: [
    deps_match = re.search(r'dependencies:\s*\[', content)
    if not deps_match:
        print(f"Skipping {pkg_path} (dependencies array not found)")
        return
    
    # Generate the string to insert
    new_deps = []
    for repo in repos:
        if repo in content:
            continue
        new_deps.append(f'        .package(url: "{repo}.git", branch: "main")')
    
    if not new_deps:
        print(f"Nothing to add to {pkg_path}")
        return

    insertion_point = deps_match.end()
    
    # Check if there are already dependencies (if the next char is not ']')
    # We might need a comma.
    # It's easier to append before the closing bracket of dependencies.
    # We find the closing bracket of dependencies array.
    # We can do this by counting brackets.
    
    bracket_count = 0
    in_string = False
    escape = False
    closing_pos = -1
    for i in range(deps_match.end() - 1, len(content)):
        char = content[i]
        if escape:
            escape = False
            continue
        if char == '\\':
            escape = True
            continue
        if char == '"':
            in_string = not in_string
            continue
        
        if not in_string:
            if char == '[':
                bracket_count += 1
            elif char == ']':
                bracket_count -= 1
                if bracket_count == 0:
                    closing_pos = i
                    break
    
    if closing_pos != -1:
        # Before closing_pos, if there's no comma, add one
        # Unless it's empty
        before_closing = content[deps_match.end():closing_pos].strip()
        needs_comma = False
        if before_closing and not before_closing.endswith(','):
            needs_comma = True
            
        insertion_string = "\n" + ",\n".join(new_deps)
        if needs_comma:
            # Add a comma to the last dependency before inserting our new ones
            # Let's insert the comma before the newline before the closing bracket
            # Wait, easier: just insert a comma at the beginning of our insertion string
            insertion_string = ",\n" + ",\n".join(new_deps)
            
        # Also need a newline before the closing bracket
        insertion_string += "\n    "
        
        new_content = content[:closing_pos] + insertion_string + content[closing_pos:]
        
        with open(pkg_path, "w") as f:
            f.write(new_content)
        print(f"Updated {pkg_path}")
    else:
        print(f"Could not find closing bracket for dependencies in {pkg_path}")

for directory, repos in packages.items():
    update_package(directory, repos)
