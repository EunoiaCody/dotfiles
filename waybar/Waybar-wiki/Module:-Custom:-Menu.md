Some modules support a `menu`, which allows to have a popup menu when a defined click is done over the module.



### Config
       
A module that implements a `menu` needs 3 properties defined in its config :

| option           | typeof  | default       | description |
| ---------------- | ------- | ------------- | ----------- |
| `menu`            | string  |               | Action that popups the menu. i.e: `on-click`|
| `menu-file`       | string  |               | Location of the menu descriptor file. There need to be an element of type GtkMenu with id menu.|
| `menu-actions`    | array  |               | The actions corresponding to the buttons of the menu. The identifiers of each actions needs to exists as an id in the 'menu-file' for it to be linked properly. |


#### menu-file

The   menu-file   is  an  `.xml`  file  representing  a  GtkBuilder.  Documentation  for  it  can  be  found  here  :
https://docs.gtk.org/gtk4/class.Builder.html

Here, it needs to have an element of type GtkMenu with id "menu". Each actions in menu-actions are  linked  to  elements in the menu-file file by the id of the elements.

#### Example:

Module config:

```jsonc
"custom/power": {
    "format" : "⏻ ",
        "tooltip": false,
        "menu": "on-click",
        "menu-file": "~/.config/waybar/power_menu.xml",
        "menu-actions": {
            "shutdown": "shutdown",
            "reboot": "reboot",
            "suspend": "systemctl suspend",
            "hibernate": "systemctl hibernate",
        },
},
```

~/.config/waybar/power_menu.xml:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<interface>
    <object class="GtkMenu" id="menu">
        <child>
            <object class="GtkMenuItem" id="suspend">
                <property name="label">Suspend</property>
            </object>
        </child>
        <child>
            <object class="GtkMenuItem" id="hibernate">
                <property name="label">Hibernate</property>
            </object>
        </child>
        <child>
            <object class="GtkMenuItem" id="shutdown">
                <property name="label">Shutdown</property>
            </object>
        </child>
        <child>
            <object class="GtkSeparatorMenuItem" id="delimiter1" />
        </child>
        <child>
            <object class="GtkMenuItem" id="reboot">
                <property name="label">Reboot</property>
            </object>
        </child>
    </object>
</interface>
``` 

### Style

- `menu`  Style for the menu
- `menuitem`  Style for items in the menu
 

#### Example:
```css
menu {
    border-radius: 15px;
    background: #161320;
    color: #B5E8E0;
}
menuitem {
    border-radius: 15px;
}
```

