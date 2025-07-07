#!/usr/bin/env python3
import json

def main():
    # Load your JSON file
    with open("metadata.json", "r") as f:
        data = json.load(f)

    # Prepare the variables dictionary
    params = {}
    for item in data["params"]:
        param_name = item["param-name"]
        default_value = item["default-value"]
        params[param_name] = default_value

    # Build the extra vars string
    extra_vars = []
    for k, v in params.items():
        # For Linux shell, single-quote everything safely
        v = v.replace("'", "'\"'\"'")
        extra_vars.append(f"{k}='{v}'")

    extra_vars_str = " ".join(extra_vars)

    # Compose the bash script
    bash_script = f"""#!/usr/bin/env bash
set -e

PLAYBOOK=windows_cert_crawler_install.yml
INVENTORY=hosts.ini

EXTRA_VARS="{extra_vars_str}"

echo "Running ansible-playbook with variables:"
echo $EXTRA_VARS

ansible-playbook -i $INVENTORY $PLAYBOOK -e "$EXTRA_VARS"

echo "Playbook completed successfully."
"""

    # Write the .sh script
    with open("run_cert_crawler.sh", "w") as f:
        f.write(bash_script)

    print("Bash script 'run_cert_crawler.sh' has been generated.")

if __name__ == "__main__":
    main()
