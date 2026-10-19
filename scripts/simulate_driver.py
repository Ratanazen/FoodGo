"""
FoodGo Phnom Penh Courier Route Simulator
Simulates real-time GPS telemetry for an active courier moving along
a realistic delivery path across central Phnom Penh, Cambodia.
"""

import argparse
import asyncio
import json
import math
import sys

# Central Phnom Penh Waypoints
# BKK1 (Pasteur 51) -> Independence Monument -> Wat Botum -> Riverside -> Koh Pich
PHNOM_PENH_WAYPOINTS = [
    (11.5529, 104.9254, "Boeung Keng Kang 1 (Pickup Point)"),
    (11.5564, 104.9282, "Independence Monument Roundabout"),
    (11.5601, 104.9315, "Wat Botum Park / Norodom Blvd"),
    (11.5645, 104.9328, "Royal Palace Front Park"),
    (11.5678, 104.9332, "Sisowath Quay (Riverside Promenade)"),
    (11.5583, 104.9405, "Koh Pich Bridge (Delivery Destination)"),
]


def calculate_bearing(lat1, lon1, lat2, lon2):
    """Calculates bearing angle in degrees from point 1 to point 2."""
    lat1_rad = math.radians(lat1)
    lat2_rad = math.radians(lat2)
    diff_lon = math.radians(lon2 - lon1)

    x = math.sin(diff_lon) * math.cos(lat2_rad)
    y = math.cos(lat1_rad) * math.sin(lat2_rad) - (
        math.sin(lat1_rad) * math.cos(lat2_rad) * math.cos(diff_lon)
    )
    initial_bearing = math.atan2(x, y)
    initial_bearing = math.degrees(initial_bearing)
    compass_bearing = (initial_bearing + 360) % 360
    return round(compass_bearing, 1)


def generate_interpolated_route(waypoints, steps_per_segment=20):
    """Generates continuous interpolated coordinate steps between waypoints."""
    full_route = []
    for i in range(len(waypoints) - 1):
        start_lat, start_lng, _ = waypoints[i]
        end_lat, end_lng, end_desc = waypoints[i + 1]

        bearing = calculate_bearing(start_lat, start_lng, end_lat, end_lng)
        lat_step = (end_lat - start_lat) / steps_per_segment
        lng_step = (end_lng - start_lng) / steps_per_segment

        for s in range(steps_per_segment):
            curr_lat = start_lat + (lat_step * s)
            curr_lng = start_lng + (lng_step * s)
            full_route.append({
                "lat": curr_lat,
                "lng": curr_lng,
                "bearing": bearing,
                "segment_target": end_desc,
            })

    final_lat, final_lng, final_desc = waypoints[-1]
    full_route.append({
        "lat": final_lat,
        "lng": final_lng,
        "bearing": 0.0,
        "segment_target": final_desc,
    })
    return full_route


async def simulate_driver(host, port, order_id, token, interval_sec):
    try:
        import websockets
    except ImportError:
        print("[ERROR] 'websockets' library is required. Install via: pip install websockets")
        sys.exit(1)

    uri = f"ws://{host}:{port}/ws/tracking/{order_id}/?token={token}"
    route = generate_interpolated_route(PHNOM_PENH_WAYPOINTS, steps_per_segment=15)
    total_steps = len(route)

    print(f"[INFO] Connecting to FoodGo Order Tracking WebSocket at: {uri}")
    print(f"[INFO] Route contains {total_steps} waypoints across Phnom Penh, Cambodia.")

    try:
        async with websockets.connect(uri) as websocket:
            print("[INFO] Connected successfully! Commencing GPS route simulation...")

            for i, pt in enumerate(route, start=1):
                payload = {
                    "lat": round(pt["lat"], 6),
                    "lng": round(pt["lng"], 6),
                    "bearing": pt["bearing"],
                    "speed": 32.5,
                }
                await websocket.send(json.dumps(payload))
                pct = int((i / total_steps) * 100)
                print(
                    f"[{pct:3d}%] Sent GPS -> Lat: {payload['lat']:.5f}, Lng: {payload['lng']:.5f} | "
                    f"Heading: {payload['bearing']:5.1f} deg | Target: {pt['segment_target']}"
                )
                await asyncio.sleep(interval_sec)

            print("[INFO] Courier has safely reached the delivery destination (Koh Pich)!")
    except Exception as e:
        print(f"[ERROR] Simulation aborted: {e}")


def main():
    parser = argparse.ArgumentParser(
        description="FoodGo Phnom Penh Courier GPS Telemetry Simulator"
    )
    parser.add_argument("--host", default="127.0.0.1", help="WebSocket server host")
    parser.add_argument("--port", type=int, default=8000, help="WebSocket server port")
    parser.add_argument("--order-id", default="1", help="Order ID to simulate tracking for")
    parser.add_argument(
        "--token",
        default="simulator-token",
        help="JWT or simulator bypass token",
    )
    parser.add_argument(
        "--interval",
        type=float,
        default=1.0,
        help="Update interval in seconds",
    )

    args = parser.parse_args()
    asyncio.run(
        simulate_driver(
            host=args.host,
            port=args.port,
            order_id=args.order_id,
            token=args.token,
            interval_sec=args.interval,
        )
    )


if __name__ == "__main__":
    main()
