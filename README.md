# cusf_launcher

Requirements:
Godot v4.3 :
https://github.com/godotengine/godot/releases/tag/4.3-stable

To build with godot editor just open the project and hit the play button.

Building with compatibility mode right now because it doesn't seem to work on virtualized windows hosts in forward+.

If you have any issues open an issue here: 
https://github.com/LayerTwo-Labs/cusf_launcher/issues

Command line build instructions:

Linux:

`godot --headless --path cusf_launcher/ --export-release "Linux" cusf_launcher.x86_64`

Windows:

`godot --headless --path cusf_launcher/ --export-release "Windows" cusf_launcher.exe`

Mac:

`godot --headless --path cusf_launcher/ --export-release "Mac" cusf_launcher.dmg`


