#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(dirname "$(dirname "$(readlink -fm "$0")")")"

# Runs `sed` with `diff` right before showing what the `sed` command changes
# Usage:
#   sed_with_preview [file_path] [options] [pattern]
function sed_with_preview {
  sed "${@:2}" "$1" | diff "$1" - || true
  sed -i "${@:2}" "$1"
}

# Runs `sed` with `diff` right before showing what the `sed` command changes
# RUns using sudo
# Usage:
#   sudo_sed_with_preview [file_path] [options] [pattern]
function sudo_sed_with_preview {
  sed "${@:2}" "$1" | diff "$1" - || true
  sudo sed -i "${@:2}" "$1"
}

# Delimits a sub-stage
# Usage:
#   sub_stage [message]
function sub_stage {
  echo "CANONICAL-SUB-STAGE-START ===================="
  echo "$1"
  echo "=============================================="
}

# Sets the current wallpaper on each screen.
# Thanks to https://www.reddit.com/r/kde/comments/65pmhj/change_wallpaper_from_terminal/
# for this insane one-liner
# Usage:
#   set_wallpaper [plugin] [file_path]
function set_wallpaper {
  dbus-send --session --dest=org.kde.plasmashell --type=method_call /PlasmaShell org.kde.PlasmaShell.evaluateScript 'string:
var Desktops = desktops();
for (i=0;i<Desktops.length;i++) {
  d = Desktops[i];
  d.wallpaperPlugin = "'$1'";
  d.currentConfigGroup = Array("Wallpaper",
                               "'$1'",
                               "General");
  d.writeConfig("Image", "file://'$2'");
}'
}

# Installling packages used during installation
sub_stage "Installing Common Packages"
sudo apt update
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y \
  wget \
  curl \
  python3-pip \
  rsync \
  flameshot \
  xsel \
  git
python3 -m pip install --user pipx
python3 -m pipx ensurepath

# Install ocs-url
if ! command -v ocs-url &> /dev/null
then
  sub_stage "Installing ocs-url"
  DEBIAN_FRONTEND=noninteractive sudo apt-get install -y \
    -f $DOTFILES/resources/packages/ocs-url_3.1.0-0ubuntu1_amd64.deb
fi

# Install fonts
sub_stage "Installing fonts"
sudo mkdir -p /usr/local/share/fonts/ligaturizer
sudo cp \
  $DOTFILES/resources/fonts/ligaturizer/*.ttf \
  $DOTFILES/resources/fonts/ligaturizer/*.otf \
  /usr/local/share/fonts/ligaturizer
sudo mkdir -p /usr/local/share/fonts/san-francisco
sudo cp \
  $DOTFILES/resources/fonts/san-francisco/*.ttf \
  $DOTFILES/resources/fonts/san-francisco/*.otf \
  /usr/local/share/fonts/san-francisco
fc-cache -f -v > /dev/null
kwriteconfig5 --file $HOME/.config/kdeglobals           --group "General" --key "font"                 "SF Pro Text,10,-1,5,50,0,0,0,0,0"
kwriteconfig5 --file $HOME/.config/kdeglobals           --group "General" --key "fixed"                "Ligalex Mono,10,-1,5,57,0,0,0,0,0,Medium"
kwriteconfig5 --file $HOME/.config/kdeglobals           --group "General" --key "menuFont"             "SF Pro Text,10,-1,5,50,0,0,0,0,0"
kwriteconfig5 --file $HOME/.config/kdeglobals           --group "General" --key "smallestReadableFont" "SF Pro Text,8,-1,5,50,0,0,0,0,0"
kwriteconfig5 --file $HOME/.config/kdeglobals           --group "General" --key "toolBarFont"          "SF Pro Text,10,-1,5,50,0,0,0,0,0"
kwriteconfig5 --file $HOME/.config/kdeglobals           --group "WM"      --key "activeFont"           "SF Pro Text,10,-1,5,50,0,0,0,0,0"
kwriteconfig5 --file $HOME/.kde/share/config/kdeglobals --group "General" --key "font"                 "SF Pro Text,10,-1,5,50,0,0,0,0,0"
kwriteconfig5 --file $HOME/.kde/share/config/kdeglobals --group "General" --key "menuFont"             "SF Pro Text,10,-1,5,50,0,0,0,0,0"
kwriteconfig5 --file $HOME/.kde/share/config/kdeglobals --group "General" --key "smallestReadableFont" "SF Pro Text,8,-1,5,50,0,0,0,0,0"
kwriteconfig5 --file $HOME/.kde/share/config/kdeglobals --group "General" --key "toolBarFont"          "SF Pro Text,10,-1,5,50,0,0,0,0,0"
sed_with_preview     $HOME/.config/xsettingsd/xsettingsd.conf -E 's/Gtk\/FontName "[^"]*"/Gtk\/FontName "SF Pro Text,  10"/g'
sed_with_preview     $HOME/.config/gtk-3.0/settings.ini       -E 's/gtk-font-name=.*/gtk-font-name=SF Pro Text,  10/g'
sed_with_preview     $HOME/.config/gtk-4.0/settings.ini       -E 's/gtk-font-name=.*/gtk-font-name=SF Pro Text,  10/g'
sed_with_preview     $HOME/.gtkrc-2.0                         -E 's/gtk-font-name="[^"]*"/gtk-font-name="SF Pro Text,  10"/g'

# Install cursors
sub_stage "Installing cursors"
sudo mkdir -p /usr/share/icons/{posy-black,posy-black-tiny,posy-white,posy-white-tiny}
sudo rsync -au --delete "$DOTFILES/resources/cursors/posy-black/"      /usr/share/icons/posy-black/
sudo rsync -au --delete "$DOTFILES/resources/cursors/posy-black-tiny/" /usr/share/icons/posy-black-tiny/
sudo rsync -au --delete "$DOTFILES/resources/cursors/posy-white/"      /usr/share/icons/posy-white/
sudo rsync -au --delete "$DOTFILES/resources/cursors/posy-white-tiny/" /usr/share/icons/posy-white-tiny/
kwriteconfig5 --file $HOME/.config/kcminputrc --group "Mouse" --key "cursorTheme" "posy-black"
sed_with_preview     $HOME/.config/xsettingsd/xsettingsd.conf -E 's/Gtk\/CursorThemeName "[^"]*"/Gtk\/CursorThemeName "posy-black"/g'
sed_with_preview     $HOME/.config/gtk-3.0/settings.ini       -E 's/gtk-cursor-theme-name=.*/gtk-cursor-theme-name=posy-black/g'
sed_with_preview     $HOME/.config/gtk-4.0/settings.ini       -E 's/gtk-cursor-theme-name=.*/gtk-cursor-theme-name=posy-black/g'
sed_with_preview     $HOME/.gtkrc-2.0                         -E 's/gtk-cursor-theme-name="[^"]*"/gtk-cursor-theme-name="posy-black"/g'

# Install icons
sub_stage "Installing icons"
sudo mkdir -p /usr/share/icons/{WhiteSur,WhiteSur-dark}
sudo rsync -au --delete "$DOTFILES/resources/icons/WhiteSur/"      "/usr/share/icons/WhiteSur/"
sudo rsync -au --delete "$DOTFILES/resources/icons/WhiteSur-dark/" "/usr/share/icons/WhiteSur-dark/"
# Sync the patch folder (but do not use --delete)
sudo rsync -au          "$DOTFILES/resources/icons/patch/places/" "/usr/share/icons/WhiteSur/places/"
sudo rsync -au          "$DOTFILES/resources/icons/patch/places/" "/usr/share/icons/WhiteSur-dark/places/"
sudo rsync -au          "$DOTFILES/resources/icons/patch/apps/"   "/usr/share/icons/WhiteSur/apps/"
kwriteconfig5 --file $HOME/.config/kdeglobals           --group "Icons" --key "Theme" "WhiteSur-dark"
kwriteconfig5 --file $HOME/.kde/share/config/kdeglobals --group "Icons" --key "Theme" "WhiteSur-dark"
sed_with_preview     $HOME/.config/xsettingsd/xsettingsd.conf -E 's/Net\/IconThemeName "[^"]*"/Net\/IconThemeName "WhiteSur-dark"/g'
sed_with_preview     $HOME/.config/gtk-3.0/settings.ini       -E 's/gtk-icon-theme-name=.*/gtk-icon-theme-name=WhiteSur-dark/g'
sed_with_preview     $HOME/.config/gtk-4.0/settings.ini       -E 's/gtk-icon-theme-name=.*/gtk-icon-theme-name=WhiteSur-dark/g'
sed_with_preview     $HOME/.gtkrc-2.0                         -E 's/gtk-icon-theme-name="[^"]*"/gtk-icon-theme-name="WhiteSur-dark"/g'
rm -f $HOME/.cache/icon-cache.kcache
kbuildsycoca5 --noincremental

# Install wallpaper
sub_stage "Installing wallpaper"
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y \
  plasma-wallpaper-dynamic
mkdir -p $HOME/wallpaper
cp $DOTFILES/resources/wallpaper/monterey-dark.jpg $HOME/wallpaper/monterey-dark.jpg
function download_catalina_dynamic {
  dynamic_wallpaper_location="$HOME/wallpaper/catalina-dynamic.heic"
  if [[ -f "$dynamic_wallpaper_location" ]]; then
    sha1_exit_code=0
    echo "24f27be9561c06354463e0d3d2f72e65246dbdf4 $dynamic_wallpaper_location" \
      | sha1sum -c - --quiet > /dev/null 2>&1 \
      || sha1_exit_code=$?
    if [ $sha1_exit_code -eq 0 ]; then
      return
    fi
  fi
  wget https://jazev-static-files.s3.amazonaws.com/catalina-dynamic.heic -P $HOME/wallpaper
}
download_catalina_dynamic
if [ ! -z ${WALLPAPER_TYPE+x} ] && [ "$WALLPAPER_TYPE" == "DYNAMIC" ]; then
  set_wallpaper "com.github.zzag.dynamic" $HOME/wallpaper/catalina-dynamic.heic
else
  set_wallpaper "org.kde.image"           $HOME/wallpaper/monterey-dark.jpg
fi

# Install oh-my-zsh
sub_stage "Installing oh-my-zsh"
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y \
  zsh
sudo chsh -s $(which zsh) $USER
if [[ -f "/home/jazev/.oh-my-zsh" ]]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi
sed_with_preview $HOME/.zshrc -E 's/ZSH_THEME="[^"]*"/ZSH_THEME="bira"/g'

# Install kvantum
if ! command -v kvantummanager &> /dev/null
then
  sub_stage "Installing kvantum"
  sudo add-apt-repository ppa:papirus/papirus
  sudo apt update
  DEBIAN_FRONTEND=noninteractive sudo apt-get install -y\
    qt5-style-kvantum \
    qt5-style-kvantum-themes
fi

# Install kvantum theme
# From https://github.com/mkole/KDE-Plasma
sub_stage "Installing kvantum theme"
mkdir -p "$HOME/.config/Kvantum/BigSur-Dark"
sudo rsync -au --delete "$DOTFILES/resources/kvantum/BigSur-Dark/" "$HOME/.config/Kvantum/BigSur-Dark/"
kvantummanager --set BigSur-Dark
kwriteconfig5 --file $HOME/.config/kdeglobals           --group "KDE"     --key "widgetStyle" "kvantum-dark"
kwriteconfig5 --file $HOME/.kde/share/config/kdeglobals --group "General" --key "widgetStyle" "kvantum-dark"

# Install color theme
# From https://github.com/mkole/KDE-Plasma
sub_stage "Installing color theme"
sudo mkdir -p /usr/share/color-schemes
sudo rsync -au $DOTFILES/resources/colors/Big-Dark.colors /usr/share/color-schemes/Big-Dark.colors
kwriteconfig5 --file $HOME/.config/kdeglobals           --group "General" --key "ColorScheme" "Big-Dark"
kwriteconfig5 --file $HOME/.kde/share/config/kdeglobals --group "General" --key "ColorScheme" "Big-Dark"
kwriteconfig5 --file $HOME/.kde/share/config/kdeglobals --group "General" --key "Name"        "Big-Dark"

# Configuring desktop effects
sub_stage "Configuring desktop effects"
kwriteconfig5 --file $HOME/.config/kwinrc --group "Effect-Blur" --key "NoiseStrength"              "8"
kwriteconfig5 --file $HOME/.config/kwinrc --group "Plugins"     --key "kwin4_effect_fadeEnabled"   "false"
kwriteconfig5 --file $HOME/.config/kwinrc --group "Plugins"     --key "kwin4_effect_scaleEnabled"  "true"
kwriteconfig5 --file $HOME/.config/kwinrc --group "Plugins"     --key "kwin4_effect_squashEnabled" "false"
kwriteconfig5 --file $HOME/.config/kwinrc --group "Plugins"     --key "magiclampEnabled"           "true"

# Install window decorations
# From https://github.com/kupiqu/SierraBreezeEnhanced
sub_stage "Installing window decorations"
sudo add-apt-repository -y \
  ppa:krisives/sierrabreezeenhanced
sudo apt update
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y\
  sierrabreezeenhanced
kwriteconfig5 --file $HOME/.config/kwinrc --group "org.kde.kdecoration2" --key "BorderSize"     "None"
kwriteconfig5 --file $HOME/.config/kwinrc --group "org.kde.kdecoration2" --key "BorderSizeAuto" "false"
kwriteconfig5 --file $HOME/.config/kwinrc --group "org.kde.kdecoration2" --key "ButtonsOnLeft"  "XIA"
kwriteconfig5 --file $HOME/.config/kwinrc --group "org.kde.kdecoration2" --key "ButtonsOnRight" ""
kwriteconfig5 --file $HOME/.config/kwinrc --group "org.kde.kdecoration2" --key "library"        "org.kde.sierrabreezeenhanced"
kwriteconfig5 --file $HOME/.config/kwinrc --group "org.kde.kdecoration2" --key "theme"          "Sierra Breeze Enhanced"
kwriteconfig5 --file $HOME/.config/sierrabreezeenhancedrc --group "Windeco" --key "AnimationsEnabled"     "false"
kwriteconfig5 --file $HOME/.config/sierrabreezeenhancedrc --group "Windeco" --key "ButtonHOffset"         "4"
kwriteconfig5 --file $HOME/.config/sierrabreezeenhancedrc --group "Windeco" --key "ButtonSize"            "ButtonSmall"
kwriteconfig5 --file $HOME/.config/sierrabreezeenhancedrc --group "Windeco" --key "ButtonSpacing"         "4"
kwriteconfig5 --file $HOME/.config/sierrabreezeenhancedrc --group "Windeco" --key "ButtonStyle"           "macSierra"
kwriteconfig5 --file $HOME/.config/sierrabreezeenhancedrc --group "Windeco" --key "CornerRadius"          "8"
kwriteconfig5 --file $HOME/.config/sierrabreezeenhancedrc --group "Windeco" --key "DrawTitleBarSeparator" "false"
kwriteconfig5 --file $HOME/.config/sierrabreezeenhancedrc --group "Windeco" --key "UnisonHovering"        "false"
kwriteconfig5 --file $HOME/.config/breezerc --group "Windeco Exception 0" --key "Enabled"                "true"
kwriteconfig5 --file $HOME/.config/breezerc --group "Windeco Exception 0" --key "DrawBackgroundGradient" "false"
kwriteconfig5 --file $HOME/.config/breezerc --group "Windeco Exception 0" --key "ExceptionPattern"       "konsole"
kwriteconfig5 --file $HOME/.config/breezerc --group "Windeco Exception 0" --key "ExceptionType"          "0"
kwriteconfig5 --file $HOME/.config/breezerc --group "Windeco Exception 0" --key "Mask"                   "0"
kwriteconfig5 --file $HOME/.config/breezerc --group "Windeco Exception 0" --key "OpacityOverride"        "41"
kwriteconfig5 --file $HOME/.config/breezerc --group "Windeco Exception 0" --key "OpaqueTitleBar"         "false"

# Install rounded corners
# From https://github.com/khanhas/ShapeCorners
sub_stage "Installing rounded corners"
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y \
  git \
  cmake \
  g++ \
  gettext \
  extra-cmake-modules \
  qttools5-dev \
  libqt5x11extras5-dev \
  libkf5configwidgets-dev \
  libkf5crash-dev \
  libkf5globalaccel-dev \
  libkf5kio-dev \
  libkf5notifications-dev \
  kinit-dev \
  kwin-dev
if [ ! -d "$HOME/opt/shape-corners" ]; then
  mkdir -p $HOME/opt/shape-corners
  git clone https://github.com/khanhas/ShapeCorners.git $HOME/opt/shape-corners
fi
mkdir -p $HOME/opt/shape-corners/build
pushd $HOME/opt/shape-corners/build
cmake ../ -DCMAKE_INSTALL_PREFIX=/usr -DQT5BUILD=ON
make && sudo make install
touch $HOME/.config/shapecornersrc
kwriteconfig5 --file $HOME/.config/shapecornersrc --group "General" --key "Radius"             "10"
kwriteconfig5 --file $HOME/.config/shapecornersrc --group "General" --key "Type"               "Rounded"
kwriteconfig5 --file $HOME/.config/shapecornersrc --group "General" --key "SquareAtScreenEdge" "true"
kwriteconfig5 --file $HOME/.config/shapecornersrc --group "General" --key "FilterShadow"       "false"
kwriteconfig5 --file $HOME/.config/shapecornersrc --group "General" --key "Whitelist"          ""
kwriteconfig5 --file $HOME/.config/shapecornersrc --group "General" --key "Blacklist"          "lattedock,krunner"
popd

# Install Plasma theme
# From https://store.kde.org/p/1567587
sub_stage "Installing Plasma theme"
sudo mkdir -p /usr/share/plasma/desktoptheme/WhiteSur-dark
sudo rsync -au --delete "$DOTFILES/resources/plasma-themes/WhiteSur-dark/" /usr/share/plasma/desktoptheme/WhiteSur-dark/
kwriteconfig5 --file $HOME/.config/plasmarc --group "Theme" --key "name" "WhiteSur-dark"

# Install Plasmoids
sub_stage "Installing Plasmoids"
PLASMOID_INSTALL="$HOME/.local/share/plasma/plasmoids"
if [ ! -d "$PLASMOID_INSTALL/launchpadPlasma" ]; then
  plasmapkg2 --install $DOTFILES/resources/plasmoids/launchpadPlasma.tar.gz
fi
if [ ! -d "$PLASMOID_INSTALL/org.communia.apptitle" ]; then
  plasmapkg2 --install $DOTFILES/resources/plasmoids/org.communia.apptitle--v1.1.org.communia.apptitle.plasmoid
fi
if [ ! -d "$PLASMOID_INSTALL/org.kde.latte.separator" ]; then
  plasmapkg2 --install $DOTFILES/resources/plasmoids/applet-latte-separator-0.1.1.plasmoid
fi
if [ ! -d "$PLASMOID_INSTALL/org.kde.latte.spacer" ]; then
  plasmapkg2 --install $DOTFILES/resources/plasmoids/applet-latte-spacer-0.3.0.plasmoid
fi
if [ ! -d "$PLASMOID_INSTALL/org.kde.plasma.betterinlineclock" ]; then
  plasmapkg2 --install $DOTFILES/resources/plasmoids/betterinlineclock.tar.gz
fi
if [ ! -d "$PLASMOID_INSTALL/org.kde.plasma.bigSur-inlineBattery" ]; then
  plasmapkg2 --install $DOTFILES/resources/plasmoids/org.kde.plasma.bigSur-inlineBattery.tar.gz
fi
if [ ! -d "$PLASMOID_INSTALL/org.kpple.kppleMenu" ]; then
  plasmapkg2 --install $DOTFILES/resources/plasmoids/org.kpple.KppleMenu.tar.gz
fi

# Add space to system tray plasmoid
sub_stage "Adding space to system tray plasmoid"
SYSTEM_TRAY_ARROW_SPACING="6"
SYSTEM_TRAY_ICON_MARGIN="6"
sudo_sed_with_preview /usr/share/plasma/plasmoids/org.kde.plasma.private.systemtray/contents/ui/main.qml 's/columnSpacing: [0-9.-]*/columnSpacing: '$SYSTEM_TRAY_ARROW_SPACING'/g'
sudo_sed_with_preview /usr/share/plasma/plasmoids/org.kde.plasma.private.systemtray/contents/ui/main.qml 's/return autoSize ? root.height : smallSizeCellLength/return (autoSize ? root.height : smallSizeCellLength) + '$SYSTEM_TRAY_ICON_MARGIN'/g'
sudo_sed_with_preview /usr/share/plasma/plasmoids/org.kde.plasma.private.systemtray/contents/ui/main.qml 's/return (autoSize ? root.height : smallSizeCellLength) + [0-9.-]*/return (autoSize ? root.height : smallSizeCellLength) + '$SYSTEM_TRAY_ICON_MARGIN'/g'

# Install custom icons (for Latte)
sub_stage "Installing custom icons"
sudo mkdir -p /opt/icons/custom
sudo rsync -au --delete "$DOTFILES/resources/icons/custom/" "/opt/icons/custom/"

# Overriding icon on kpple menu
sub_stage "Overriding menu on kpple menu"
kwriteconfig5 --file $PLASMOID_INSTALL/org.kpple.kppleMenu/metadata.desktop --group "Desktop Entry" --key "Icon" "start-here-macos-adjusted"

# Adding space to global menu plasmoid
sub_stage "Adding space to global menu"
sudo_sed_with_preview /usr/share/plasma/plasmoids/org.kde.plasma.appmenu/contents/ui/main.qml 's/return text;/if (text === "") { return ""; } else { return " ".concat(text, " "); }/g'

# Install prerequisites for global menu
sub_stage "Installing global menu prerequisites"
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y \
  appmenu-gtk2-module \
  appmenu-gtk3-module

# Install Latte layout and configure
sub_stage "Installing Latte layout"
killall latte-dock || true
rm -f $HOME/.config/latte/personal-docks.layout.old.latte
if [[ -f "$dynamic_wallpaper_location" ]]; then
  mv $HOME/.config/latte/personal-docks.layout.latte $HOME/.config/latte/personal-docks.layout.old.latte
fi
kwriteconfig5 --file $HOME/.config/kwinrc --group "ModifierOnlyShortcuts" --key "Meta" "org.kde.lattedock,/Latte,org.kde.LatteDock,activateLauncherMenu"
latte-dock --import-layout $DOTFILES/resources/latte/personal-docks.layout.latte --replace <&- >&- 2>&- & disown

# Configure konsole
mkdir -p "$HOME/.local/share/konsole"
rsync -au "$DOTFILES/resources/konsole/one-dark-glass.colorscheme" "$HOME/.local/share/konsole/one-dark-glass.colorscheme"
rsync -au "$DOTFILES/resources/konsole/Primary.profile" "$HOME/.local/share/konsole/Primary.profile"
kwriteconfig5 --file $HOME/.config/konsolerc --group "Desktop Entry" --key "DefaultProfile" "Primary.profile"

# Add kwin rules for applications so that their titlebars match the application body
sub_stage "Adding titlebar color kwin rules"
COLOR_SCHEME_DEST=$(mktemp -d)
python3 "$DOTFILES/automation/titlebarcolors.py" \
  --kwinrulesrc "$HOME/.config/kwinrulesrc" \
  --template "$DOTFILES/automation/titlebar-template.colors" \
  --color-scheme-dest "$COLOR_SCHEME_DEST"
rsync -au "$COLOR_SCHEME_DEST/" "$HOME/.local/share/color-schemes/"

# Configure login screen
sub_stage "Configuring login screen"
sudo mkdir -p /opt/wallpaper
sudo rsync -au "$DOTFILES/resources/wallpaper/monterey-dark.jpg" /opt/wallpaper/monterey-dark.jpg
sudo kwriteconfig5 --file /etc/sddm.conf.d/kde_settings.conf --group "Theme" --key "Current"     "breeze"
sudo kwriteconfig5 --file /etc/sddm.conf.d/kde_settings.conf --group "Theme" --key "CursorTheme" "posy-black"
sudo kwriteconfig5 --file /etc/sddm.conf.d/kde_settings.conf --group "Theme" --key "Font"        "SF Pro Text,10,-1,5,50,0,0,0,0,0"
sudo kwriteconfig5 --file /usr/share/sddm/themes/breeze/theme.conf.user --group "General" --key "background" "/opt/wallpaper/monterey-dark.jpg"
sudo kwriteconfig5 --file /usr/share/sddm/themes/breeze/theme.conf.user --group "General" --key "type"       "image"

# Configure lock screen
sub_stage "Configuring lock screen"
rsync -au "$DOTFILES/resources/config/kscreenlockerrc" "$HOME/.config/kscreenlockerrc"

# Install splash screen
sub_stage "Installing splash screen"
sudo mkdir -p /usr/share/plasma/look-and-feel/manjarobamboo
sudo rsync -au "$DOTFILES/resources/splashscreens/manjarobamboo/" /usr/share/plasma/look-and-feel/manjarobamboo/
kwriteconfig5 --file "$HOME/.config/ksplashrc" --group "KSplash" --key "Engine" "KSplashQML"
kwriteconfig5 --file "$HOME/.config/ksplashrc" --group "KSplash" --key "Theme"  "manjarobamboo"

# Restart KDE (and related processes)
sub_stage "Restarting KDE"
kquitapp5 plasmashell || true
kstart5 plasmashell <&- >&- 2>&- & disown
kwin_x11 --replace <&- >&- 2>&- & disown
