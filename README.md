# ptt-dictate

Push-to-talk voice dictation for Linux using [`whisper.cpp`](https://github.com/ggml-org/whisper.cpp).

Bind this script to a keyboard shortcut. Toggle on, speak, toggle off, and watch as whisper transcribes your words into wherever your text cursor is focused. Works on any text input: terminal, web input, address bar etc. If you can type it, you can `ptt-dictate`.

https://github.com/user-attachments/assets/50733c7b-3f7c-47de-810d-cec5ee22c4e0

## Setup

1. Install [`whisper.cpp`](https://github.com/ggml-org/whisper.cpp)
Recommended: if you have an Nvida GPU, make sure to enable CUDA.

2. Install other dependencies. In Arch:
```bash
	sudo pacman -S pipewire pipewire-pulse libnotify curl jq ydotoolj
```

Note: It can be tricky to get `ydotool` to work. Make sure to test `ydotool type` in the terminal before continuing.

3. Put the script somewhere in your path, make executable
```bash
	git clone https://github.com/<your-username>/ptt-dictate.git
	cp ptt-dictate/ptt-dictate.sh ~/.local/bin/ptt-dictate.sh
	chmod +x ~/.local/bin/ptt-dictate.sh
```

4. Bind script to a shortcut. In i3:
```bash
	bindsym $mod+v exec --no-startup-id ~/.local/bin/ptt-dictate.sh
```

5. Start your whisper.cpp server:
```bash
	# Wherever you put whisper.cpp
	./build/bin/whisper-server -m models/ggml-base.en.bin -t $(nproc)
```

That's it!
