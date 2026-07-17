// AudioSpectrum stub - provides safe defaults when Clavis.Audio is not available.
// The real Clavis.Audio plugin provides a PipeWire/Cava-based audio spectrum analyzer.
// This stub is a fallback so the Media and Lyrics components can still render without
// crashing. The visualizer will simply not animate, but everything else works.

pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    // Empty values array - visualizers will render but not animate
    property var values: []
    property int bars: 32
    // Never available so visualizers fade out gracefully
    readonly property bool available: false

    // No-op acquire/release - these are called by media components
    // to subscribe/unsubscribe to spectrum updates
    function acquire(token) {
        if (!token) return;
    }

    function release(token) {
        if (!token) return;
    }

    // Real Clavis.Audio would push live audio FFT data to this property
    // on a timer. Without it, the property stays at its initial value.
}
