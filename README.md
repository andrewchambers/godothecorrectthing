# go do the correct thing

A script to do actions based on the current window and selected text.

With this you can:

- Select any compiler error text in any terminal and open the correct file and line in your text editor.
- Click on the output of ls in any terminal and open the corresponding file with the correct program.
- Open any url from any text on your OS and open it in your browser.

# How to use

As it stands, the tool is difficult to package because it does a lot of 

- You need to read your window manager docs to setup a hotkey to run this script.
  In my case, I use the i3 window manager so I had to add ``` bindsym $mod+g exec /home/ac/bin/godothecorrectthing.sh ```
  to the i3 config file.
  For `KDE`, go to `SystemSettings`->`Shortcuts`->`CustomShortcuts`, then add `New`->`GlobalShortcut`->`Command`.
- You need to configure your software to have a window title that contains the current working directory, for me, my operating system PS1 variable
  made it work for xterm and sublime text did this automatically. Being able to read the current directory from the window title is important
  so the script can open 'bare' file names like 'main.go' in the example video.
- You need to customize the window scraping code in the script, it is specific to my own personal PS1 variable (The nixos default) and sublime text.
  If you have different configuration or software it will not work and will guess the wrong working directory, making all links relative to your
  home directory instead of what you intended.
- You need to customize the code which executes actions to run your desired software.

Read more [here](https://acha.ninja/integrated_development_window_manager.html)

