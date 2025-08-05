# README: Video zu Gaussian Splatting Pipeline

Dieses Skript automatisiert den Ablauf von einem Video bis zur fertigen Gaussian Splatting `.ply`-Datei auf dem Dachs-Cluster der Hochschule.

---

## Voraussetzungen

- Benutzerzugang zum Dachs-Cluster der Hochschule  
- `tmux` ist auf dem Cluster verfügbar (Standard)  
- Verfügbarkeit der Module:
  - `devel/cuda`  
  - `cs/colmap`  
- **ffmpeg ist nicht vorinstalliert!**  
  Du kannst `ffmpeg` lokal installieren, siehe unten.  
- Miniconda sollte vor OpenSplat installiert werden (siehe unten).  
- OpenSplat:  
  - Sollte im Hauptverzeichnis des Benutzers liegen (z.B. `~/OpenSplat`) mit einem `build`-Ordner.  
  - Falls OpenSplat anderswo liegt, wirst du beim Start des Skripts danach gefragt.  
- Das Video und die Projektordner sollten in einem für dich zugänglichen Verzeichnis liegen.

---

## Installation von ffmpeg

Da `ffmpeg` auf dem Dachs-Cluster nicht vorinstalliert ist und kein `sudo` verfügbar ist, gibt es zwei einfache Möglichkeiten:

### 1. Lokale Kompilierung von ffmpeg (empfohlen)

```bash
mkdir -p ~/ffmpeg_build && cd ~/ffmpeg_build
git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg
cd ffmpeg
./configure --prefix=$HOME/ffmpeg_build --disable-static --enable-shared --disable-doc
make -j$(nproc)
make install
export PATH=$HOME/ffmpeg_build/bin:$PATH
ffmpeg -version
```

### 2. Download einer minimalen, vorgefertigten statischen Binary

- Besuche [https://johnvansickle.com/ffmpeg/](https://johnvansickle.com/ffmpeg/)  
- Lade die passende Linux-Static-Binary herunter (z.B. `ffmpeg-release-amd64-static.tar.xz`)  
- Entpacke die Datei z.B. nach `~/ffmpeg`  
- Ergänze den Pfad zu `~/ffmpeg` in deiner Shell (siehe oben)

---

## Miniconda Installation (wichtig vor OpenSplat)

Miniconda wird benötigt, um die Python-Umgebung für OpenSplat sauber zu verwalten.

```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh
bash ~/miniconda.sh -b -p $HOME/miniconda
export PATH="$HOME/miniconda/bin:$PATH"
source ~/.bashrc
conda --version
```

---

## OpenSplat Vorbereitung

Für die installation muss CUDA gealden sein.

```bash
module load devel/cuda
```
Danach kann OpenSplat installiert werden.

```bash
cd ~
git clone https://github.com/pierotofy/OpenSplat.git OpenSplat
cd OpenSplat
mkdir build && cd build
cmake -DCMAKE_PREFIX_PATH=/path/to/libtorch/ .. && make -j$(nproc)
```

Stelle sicher, dass `~/OpenSplat/build` existiert.

---

## Installation

- `tmux` ist auf dem Cluster installiert, keine Installation nötig.  
- Module `devel/cuda` und `cs/colmap` werden im Skript automatisch geladen.  
- Skript speichern und ausführbar machen.

---

## Nutzung

```bash
chmod +x GaussianSplatting.sh
./GaussianSplatting.sh
```

Folge den Eingabeaufforderungen:

- Pfad zum Bearbeitungsordner  
- Name der Videodatei  
- Pfad zu OpenSplat (falls nicht Standard `~/OpenSplat`)  
- Linux-Benutzername (Cluster-Account)

Die Verarbeitung läuft in einer `tmux`-Session namens `splatting`. Zum Anschauen:

```bash
tmux attach -t splatting
```

---

## Ordnerstruktur nach Ausführung

- `images/` (Frames, später nach `colmap/images` verschoben)  
- `colmap/` (Datenbank, Sparse Reconstruction)  
- `colmap/sparse/`  
- `outputs/` (fertige `.ply`-Datei)

---

## Hinweise

- GPU-Reservation erfolgt automatisch mit `srun` (48h).  
- Prozesse laufen in `tmux`-Session, Abbruch der SSH-Verbindung stoppt sie nicht.  
- OpenSplat-Parameter sind im Skript änderbar.

---

Bei Fragen gerne melden!
