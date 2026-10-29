#!/usr/bin/env bash
set -euo pipefail

SERVICES_DIR="$HOME/Library/Services"
mkdir -p "$SERVICES_DIR"

python3 - << 'EOF'
import os, plistlib

services_dir = os.path.expanduser("~/Library/Services")

def install_action(name, script):
    wflow_dir = os.path.join(services_dir, f"{name}.workflow")
    contents_dir = os.path.join(wflow_dir, "Contents")
    os.makedirs(contents_dir, exist_ok=True)
    
    info = {
        "CFBundleIdentifier": f"com.rarflow.{name.replace(' ', '')}",
        "CFBundleName": name,
        "NSServices": [{
            "NSMenuItem": {"default": name},
            "NSMessage": "runWorkflowAsService",
            "NSSendFileTypes": ["public.item"],
            "NSRequiredContext": {
                "NSTextContent": "FilePath"
            }
        }]
    }
    with open(os.path.join(contents_dir, "Info.plist"), "wb") as f:
        plistlib.dump(info, f)
        
    wflow = {
        "AMApplicationBuild": "523",
        "AMApplicationVersion": "2.10",
        "AMDocumentVersion": "2",
        "actions": [{
            "action": {
                "AMAccepts": {
                    "Container": "List",
                    "Optional": False,
                    "Types": ["com.apple.cocoa.path"]
                },
                "AMActionVersion": "2.0.3",
                "AMApplication": ["Automator"],
                "AMParameterProperties": {},
                "AMProvides": {
                    "Container": "List",
                    "Types": ["com.apple.cocoa.path"]
                },
                "AMRequiredResources": [],
                "ActionBundlePath": "/System/Library/Automator/Run Shell Script.action",
                "ActionName": "Run Shell Script",
                "ActionParameters": {
                    "COMMAND_STRING": script,
                    "CheckedForUserDefaultShell": True,
                    "inputMethod": 1,
                    "shell": "/bin/bash",
                    "source": ""
                },
                "BundleIdentifier": "com.apple.RunShellScript",
                "CFBundleVersion": "2.0.3",
                "CanShowSelectedItemsWhenRun": False,
                "CanShowWhenRun": True,
                "Category": ["AMCategoryUtilities"],
                "Class Name": "RunShellScriptAction",
                "InputUUID": "43916298-C40E-47C0-8356-D7E36965C79E",
                "Keywords": ["Shell", "Script", "Command", "Run", "Unix"],
                "OutputUUID": "E9E5AC78-C195-4BDD-9219-54316F71A377",
                "UUID": "57E0E99E-197C-4C9C-8A67-33671569B6F3",
                "UnlocalizedApplications": ["Automator"],
                "arguments": {
                    "0": {"default value": 0, "name": "inputMethod", "required": "0", "type": "0", "value": 1},
                    "1": {"default value": "", "name": "source", "required": "0", "type": "0", "value": ""},
                    "2": {"default value": False, "name": "CheckedForUserDefaultShell", "required": "0", "type": "0", "value": True},
                    "3": {"default value": "/bin/sh", "name": "shell", "required": "0", "type": "0", "value": "/bin/bash"},
                    "4": {"default value": "", "name": "COMMAND_STRING", "required": "0", "type": "0", "value": script}
                },
                "isViewVisible": True,
                "location": "529.000000:305.000000",
                "nibPath": "/System/Library/Automator/Run Shell Script.action/Contents/Resources/Base.lproj/main.nib"
            },
            "isViewVisible": True
        }],
        "connectors": {},
        "workflowMetaData": {
            "applicationBundleIDsByPath": {},
            "applicationPaths": [],
            "inputTypeIdentifier": "com.apple.Automator.fileSystemObject",
            "outputTypeIdentifier": "com.apple.Automator.nothing",
            "presentationMode": 15,
            "processesInput": 0,
            "serviceInputTypeIdentifier": "com.apple.Automator.fileSystemObject",
            "serviceOutputTypeIdentifier": "com.apple.Automator.nothing",
            "serviceProcessesInput": 0,
            "systemImageName": "NSActionTemplate",
            "useAutomaticInputType": False,
            "workflowTypeIdentifier": "com.apple.Automator.servicesMenu"
        }
    }
    with open(os.path.join(contents_dir, "document.wflow"), "wb") as f:
        plistlib.dump(wflow, f)
    print(f"Installed: {wflow_dir}")

install_action("Extract using RARFlow", 'open -a RARFlow "$@"')
install_action("Compress using RARFlow", 'open -a RARFlow "$@"')
EOF

echo "Finder Quick Actions successfully installed in $SERVICES_DIR"
