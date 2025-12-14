POPUP_OFF="sketchybar --set apple popup.drawing=off"
POPUP_CLICK_SCRIPT="sketchybar --set apple popup.drawing=toggle"

apple_menu=(
  icon=
  icon.font="JetBrainsMono Nerd Font:Bold:18.0"
  icon.color=$BLUE
  label.drawing=off
  background.color=$SURFACE0  background.corner_radius=8
  background.border_width=1
  background.border_color=$BLUE  popup.background.color=$SURFACE0
  popup.background.corner_radius=12
  popup.background.border_width=2
  popup.background.border_color=$LAVENDER
  popup.blur_radius=50
  popup.height=35
  popup.y_offset=3
)

sketchybar --add item apple left \
           --set apple "${apple_menu[@]}" \
           click_script="$POPUP_CLICK_SCRIPT"

# Menu items with animation settings
menu_item_defaults=(
  background.color=$SURFACE1
  background.corner_radius=8
  background.height=30
  background.padding_left=5
  background.padding_right=5
  background.border_width=1
  background.drawing=on
  label.color=$TEXT
  icon.padding_left=8
  icon.padding_right=4
  label.padding_right=8
)

sketchybar --add item apple.prefs popup.apple \
           --set apple.prefs "${menu_item_defaults[@]}" \
           icon=󰒓 \
           icon.color=$SAPPHIRE \
           background.border_color=$SAPPHIRE \
           label="系统设置" \
           click_script="open -a 'System Preferences'; $POPUP_OFF"

sketchybar --add item apple.activity popup.apple \
           --set apple.activity "${menu_item_defaults[@]}" \
           icon=󰍹 \
           icon.color=$GREEN \
           background.border_color=$GREEN \
           label="活动监视器" \
           click_script="open -a 'Activity Monitor'; $POPUP_OFF"

sketchybar --add item apple.lock popup.apple \
           --set apple.lock "${menu_item_defaults[@]}" \
           icon=󰌾 \
           icon.color=$YELLOW \
           background.border_color=$YELLOW \
           label="锁定屏幕" \
           click_script="pmset displaysleepnow; $POPUP_OFF"

sketchybar --add item apple.restart popup.apple \
           --set apple.restart "${menu_item_defaults[@]}" \
           icon=󰜉 \
           icon.color=$PEACH \
           background.border_color=$PEACH \
           label="重新启动" \
           click_script="osascript -e 'tell app \"System Events\" to restart'; $POPUP_OFF"

sketchybar --add item apple.shutdown popup.apple \
           --set apple.shutdown "${menu_item_defaults[@]}" \
           icon=󰐥 \
           icon.color=$RED \
           background.border_color=$RED \
           label="关机" \
           click_script="osascript -e 'tell app \"System Events\" to shut down'; $POPUP_OFF"
