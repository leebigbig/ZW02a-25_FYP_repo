import subprocess

import inquirer
from inquirer.themes import GreenPassion

commit_type = inquirer.list_input("commit_type",choices=["verification", "design","script"])
update_module = ""

if commit_type == "design":
    update_module = inquirer.list_input("update_module",choices=["lib", "axi","mxu","ram","others"])
elif commit_type == "verification":
    update_module = inquirer.list_input("update_module",choices=["checker","sequence","driver","intf","tc","env","cov","others"])
elif commit_type == "script":
    update_module = inquirer.list_input("update_module",choices=["git", "others"])

commit_text = inquirer.text("commit_text")

commit_message = f'[{commit_type}][{update_module}] {commit_text}'

subprocess.run(["git",'commit','-m', commit_message])
#print(commit_message)