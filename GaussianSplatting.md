# Hier wird die Bash datei in den einzelnen schritten 

## Schritt 1:

```Bash
tmux
```
## Schritt 2:

```Bash
srun --gres=gpu:1 --time=48:00:00 --pty bash
```

## Schritt 3:

```Bash
module load devel/cuda
```
## Schritt 4:

```Bash
module load cs/colmap
```
## Schritt 5:
In Ordner gehen wo Video gespeichert ist und folgende Ordner erstellen
- images
- colmap
- colmap/sparse
- outputs

## Schritt 6:

```Bash
ffmpeg -i input.mp4 -q:v 1 -vf "select=not(mod(n,3))" -vsync vfr images/frame_%04d.jpg
```
## Schritt 7:

```Bash
colmap feature_extractor \
  --database_path colmap/database.db \
  --image_path images \
  --ImageReader.single_camera 1 \
  --SiftExtraction.use_gpu 1
```
## Schritt 8:

```Bash
colmap mapper \
    --database_path colmap/database.db \
    --image_path images \
    --output_path colmap/sparse \
    --Mapper.ba_local_max_num_iterations 50 \
    --Mapper.ba_global_max_num_iterations 100 \
    --Mapper.tri_ignore_two_view_tracks 1 \
    --Mapper.init_min_tri_angle 4.0 \
    --Mapper.multiple_models 0 \
    --Mapper.extract_colors 1
```
## Schritt 9:

```Bash
colmap bundle_adjuster \
    --input_path colmap/sparse/0 \
    --output_path colmap/sparse/0 \
    --BundleAdjustment.refine_principal_point 1
```
## Schritt 10:
images Ordner in colmap Ordner verschieben

## Schritt 11:
In build Ordner von OpenSplat gehen dann:

```Bash
./opensplat /home/es/es_es/es_nutzername/Projektname/colmap \
-n 120000 \
--save-every 10000 \
-o /home/es/es_es/es_nutzername/Projektname/outputs/output.ply
```
