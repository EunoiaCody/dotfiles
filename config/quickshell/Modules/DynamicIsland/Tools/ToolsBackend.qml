import QtQuick
import Quickshell.Io
import qs.Common

Item {
    id: backendRoot
    
    property string currentRecordMode: "video" 
    signal recordCancelled() 

    function pickColor() { colorPickerProcess.running = false; colorPickerProcess.running = true }
    function takeScreenshot() { screenshotProcess.running = false; screenshotProcess.running = true }
    function recognizeOcr()     { ocrProcess.running = false; ocrProcess.running = true }

    // --- 调用外部脚本开始录制 ---
    function startRecord(mode) {
        backendRoot.currentRecordMode = mode
        recordProcess.command = ["bash", "-c", "nohup bash \"" + Paths.scriptPath("capture", "record.sh") + "\" start " + mode + " >/dev/null 2>&1 &"]
        recordProcess.running = false
        recordProcess.running = true
    }

    // --- 调用外部脚本停止录制 ---
    function stopRecord() {
        var mode = backendRoot.currentRecordMode
        stopProcess.command = ["bash", "-c", "nohup bash \"" + Paths.scriptPath("capture", "record.sh") + "\" stop " + mode + " >/dev/null 2>&1 &"]
        stopProcess.running = false
        stopProcess.running = true
    }

    // ================= 【录音控制后端】 =================
    // 接收 mode 参数 (audio_mic 或 audio_sys)
    function startAudio(mode) {
        startAudioProcess.command = ["bash", "-c", "nohup bash \"" + Paths.scriptPath("capture", "record.sh") + "\" start " + mode + " >/dev/null 2>&1 &"]
        startAudioProcess.running = false
        startAudioProcess.running = true
    }

    // 停止时统一传 audio
    function stopAudio() {
        stopAudioProcess.command = ["bash", "-c", "nohup bash \"" + Paths.scriptPath("capture", "record.sh") + "\" stop audio >/dev/null 2>&1 &"]
        stopAudioProcess.running = false
        stopAudioProcess.running = true
    }

    // --- 简单工具: 内联命令 ---
    Process {
        id: colorPickerProcess
        command: ["bash", "-c", "nohup bash -c 'sleep 0.3; hyprpicker -a' >/dev/null 2>&1 &"]
    }

    Process {
        id: screenshotProcess
        command: ["bash", "-c",
            "sleep 0.3; " +
            "DIR=\"$HOME/Pictures/Screenshots\"; " +
            "mkdir -p \"$DIR\"; " +
            "FILE=\"$DIR/Screenshot from $(date +'%Y-%m-%d %H-%M-%S').png\"; " +
            "grim -g \"$(slurp)\" \"$FILE\" && wl-copy < \"$FILE\" && notify-send -a 截屏 '✅ 截图已保存' \"$FILE\" -i camera-photo"]
    }

    Process {
        id: ocrProcess
        command: ["bash", "-c",
            "sleep 0.3; " +
            "TMP=/tmp/niri-ocr-$$.png; " +
            "DIR=\"$HOME/Pictures/OCR\"; " +
            "mkdir -p \"$DIR\"; " +
            "SAVE=\"$DIR/OCR $(date +'%Y-%m-%d %H-%M-%S').png\"; " +
            "grim -g \"$(slurp)\" \"$TMP\"; " +
            "cp \"$TMP\" \"$SAVE\"; " +
            "if tesseract \"$TMP\" - -l chi_sim+eng 2>/dev/null | wl-copy; then " +
            "notify-send -a OCR '✅ OCR 识别完成' \"文字已复制到剪贴板 | 图片: $SAVE\" -i accessories-text-editor; " +
            "else notify-send -a OCR '❌ OCR 失败' '请确认已安装 tesseract 和 tesseract-data-chi_sim' -u critical; fi; " +
            "rm -f \"$TMP\""]
    }

    Process { id: recordProcess }
    Process { id: stopProcess }

    // 【新增：录音专用的 Process 节点】
    Process { id: startAudioProcess }
    Process { id: stopAudioProcess }
}
