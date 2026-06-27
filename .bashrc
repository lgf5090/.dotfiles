config_file="$HOME/.config/bash/config.bash"
[[ -r $config_file ]] && source $config_file



# TRIAL without installation
# git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git
# make -C ble.sh
# source ble.sh/out/ble.sh

# # Quick INSTALL to BASHRC (If this doesn't work, please follow Sec 1.3)

# git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git
# make -C ble.sh install PREFIX=~/.local
# echo 'source -- ~/.local/share/blesh/ble.sh' >> ~/.bashrc
# export USER=$(id -un)
# source -- ~/.local/share/blesh/ble.sh

# 仅在非 Windows 环境（非 msys/cygwin/mingw）下加载 ble.sh
# if [[ "$OSTYPE" != "msys" && "$OSTYPE" != "cygwin" && "$OSTYPE" != "win32" && "$OSTYPE" != "mingw"* ]]; then
#   if [[ -r "$HOME/.local/share/blesh/ble.sh" ]]; then
#     source -- "$HOME/.local/share/blesh/ble.sh"
#   fi
# fi