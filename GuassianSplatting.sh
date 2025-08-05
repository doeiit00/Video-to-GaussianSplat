#!/bin/bash

SESSION_NAME="splatting"

# tmux-Session starten, falls nicht schon da
if ! tmux has-session -t $SESSION_NAME 2>/dev/null; then
    tmux new-session -d -s $SESSION_NAME
fi

# Ordnerabfrage mit Wiederholung bei Fehler
while true; do
    read -p "Bitte Pfad zum Bearbeitungsordner eingeben: " TARGET_DIR
    if [ -d "$TARGET_DIR" ]; then
        break
    else
        echo "Ordner nicht gefunden. Bitte erneut eingeben."
    fi
done

# Video-Datei Abfrage mit Prüfung auf Existenz im Ordner
while true; do
    read -p "Bitte Videodatei im Ordner angeben (z.B. video.mp4): " VIDEO_FILE
    FILE_PATH="$TARGET_DIR/$VIDEO_FILE"
    if [ -f "$FILE_PATH" ]; then
        break
    else
        echo "Datei nicht gefunden. Bitte erneut eingeben."
    fi
done

# Erstelle die gewünschten Ordner außerhalb von tmux
mkdir -p "$TARGET_DIR/images" "$TARGET_DIR/colmap/sparse" "$TARGET_DIR/outputs"

# Prüfe ob OpenSplat im Hauptverzeichnis ist
DEFAULT_OPENSPLAT_DIR="$HOME/OpenSplat"
if [ -d "$DEFAULT_OPENSPLAT_DIR/build" ]; then
    OPENSPLAT_DIR="$DEFAULT_OPENSPLAT_DIR"
else
    # Abfrage, falls nicht gefunden
    while true; do
        read -p "OpenSplat build-Ordner nicht in ~/OpenSplat gefunden. Bitte Pfad zum OpenSplat-Ordner eingeben: " OPENSPLAT_DIR
        if [ -d "$OPENSPLAT_DIR/build" ]; then
            break
        else
            echo "Build-Ordner im angegebenen Pfad nicht gefunden. Bitte erneut eingeben."
        fi
    done
fi

# Wechsel in den Bearbeitungsordner in der tmux-Session
tmux send-keys -t $SESSION_NAME "cd \"$TARGET_DIR\"" C-m

# srun GPU-Knoten reservieren
tmux send-keys -t $SESSION_NAME "srun --gres=gpu:1 --time=48:00:00 --pty bash" C-m

# Module laden
tmux send-keys -t $SESSION_NAME "module load devel/cuda" C-m
tmux send-keys -t $SESSION_NAME "module load cs/colmap" C-m

# ffmpeg Befehl
tmux send-keys -t $SESSION_NAME "ffmpeg -i \"$VIDEO_FILE\" -q:v 1 -vf 'select=not(mod(n\\,3))' -vsync vfr images/frame_%04d.jpg" C-m

# COLMAP feature_extractor
tmux send-keys -t $SESSION_NAME "colmap feature_extractor \\
  --database_path colmap/database.db \\
  --image_path images \\
  --ImageReader.single_camera 1 \\
  --SiftExtraction.use_gpu 1" C-m

# COLMAP mapper
tmux send-keys -t $SESSION_NAME "colmap mapper \\
  --database_path colmap/database.db \\
  --image_path images \\
  --output_path colmap/sparse \\
  --Mapper.ba_local_max_num_iterations 50 \\
  --Mapper.ba_global_max_num_iterations 100 \\
  --Mapper.tri_ignore_two_view_tracks 1 \\
  --Mapper.init_min_tri_angle 4.0 \\
  --Mapper.multiple_models 0 \\
  --Mapper.extract_colors 1" C-m

# COLMAP bundle_adjuster
tmux send-keys -t $SESSION_NAME "colmap bundle_adjuster \\
  --input_path colmap/sparse/0 \\
  --output_path colmap/sparse/0 \\
  --BundleAdjustment.refine_principal_point 1" C-m

# Verschiebe images in colmap
tmux send-keys -t $SESSION_NAME "mv images colmap/" C-m

# Wechsle in den OpenSplat build-Ordner
tmux send-keys -t $SESSION_NAME "cd \"$OPENSPLAT_DIR/build\"" C-m

# Benutzername abfragen (außerhalb tmux, direkt hier)
read -p "Bitte deinen Linux-Benutzernamen eingeben: " USER_NAME

# Projektname aus TARGET_DIR extrahieren (letzter Ordnername)
PROJECT_NAME=$(basename "$TARGET_DIR")

# Pfade zusammensetzen
COLMAP_PATH="/home/$USER_NAME/$PROJECT_NAME/colmap"
OUTPUT_PATH="/home/$USER_NAME/$PROJECT_NAME/outputs/output.ply"

# OpenSplat ausführen in der tmux-Session
tmux send-keys -t $SESSION_NAME "./opensplat \"$COLMAP_PATH\" \\
-n 120000 \\
--save-every 10000 \\
-o \"$OUTPUT_PATH\"" C-m