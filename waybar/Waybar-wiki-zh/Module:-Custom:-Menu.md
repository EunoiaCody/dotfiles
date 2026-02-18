部分模块支持 `menu`，允许在对模块执行定义的点击操作时弹出菜单。



### 配置
       
实现 `menu` 的模块需要在其配置中定义 3 个属性：

| option           | typeof  | default       | description |
| ---------------- | ------- | ------------- | ----------- |
| `menu`            | string  |               | 弹出菜单的操作。例如：`on-click`|
| `menu-file`       | string  |               | 菜单描述文件的位置。需要有一个 id 为 menu 的 GtkMenu 类型元素。|
| `menu-actions`    | array  |               | 菜单按钮对应的操作。每个操作的标识符需要作为 id 存在于 'menu-file' 中才能正确关联。 |


#### menu-file

menu-file 是一个表示 GtkBuilder 的 `.xml` 文件。相关文档可在此处找到：
https://docs.gtk.org/gtk4/class.Builder.html

它需要有一个 id 为 "menu" 的 GtkMenu 类型元素。menu-actions 中的每个操作通过元素的 id 与 menu-file 文件中的元素关联。

#### 示例：

模块配置：

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

### 样式

- `menu`  菜单的样式
- `menuitem`  菜单项的样式
 

#### 示例：
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
