# Layout Snapshot Library

Standalone Robot Framework library for stable UI layout snapshots.

```robot
Library    layout_snapshot_library.LayoutSnapshotLibrary

Capture Stable Layout Snapshot      ${OUTPUT_FILE}
Verify Ui Layout Against Baseline   ${BASELINE_FILE}    pixel_tolerance=2
```
