# FoodGo Developer Scripts

Utility scripts for local development and testing.  
Run all commands from the **project root** (`/home/reny/FoodGo`).

---

## `simulate_driver.py`

Simulates a driver moving along a route via WebSocket.  
Useful for testing the live-map tracking feature without a real device.

**Prerequisites:** Django server must be running on `ws://127.0.0.1:8000`

```bash
# Quick way (activates venv automatically):
bash scripts/start_simulation.sh

# Or manually:
source backend/venv/bin/activate
python scripts/simulate_driver.py
```

**Customize:** Edit `simulate_driver.py` to change the order ID (`/ws/tracking/<ORDER_ID>/`),
start/end coordinates, or step count.

---

## `start_simulation.sh`

Shell wrapper that activates the backend virtual environment and runs `simulate_driver.py`.

```bash
bash scripts/start_simulation.sh
```

---

## Root-level: `run_all.sh`

Starts the entire dev ecosystem (Django + Flutter Web) in one command.

```bash
./run_all.sh
```

Kills anything on ports 8000 / 8080 first, then starts both servers in the background.
Press `Ctrl+C` to stop everything.
