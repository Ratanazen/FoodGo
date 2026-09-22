import asyncio
import websockets
import json
import time

async def simulate_driver():
    uri = "ws://127.0.0.1:8000/ws/tracking/1/"
    
    start_lat = 37.774900
    start_lng = -122.419400
    end_lat = 37.785800
    end_lng = -122.406400
    
    steps = 100
    lat_step = (end_lat - start_lat) / steps
    lng_step = (end_lng - start_lng) / steps

    print(f"Connecting to {uri}...")
    try:
        async with websockets.connect(uri) as websocket:
            print("Connected! Simulating driver movement...")
            
            for i in range(steps + 1):
                current_lat = start_lat + (lat_step * i)
                current_lng = start_lng + (lng_step * i)
                
                payload = {
                    "lat": current_lat,
                    "lng": current_lng
                }
                
                await websocket.send(json.dumps(payload))
                print(f"Sent location: {current_lat:.5f}, {current_lng:.5f} (Step {i}/{steps})")
                
                await asyncio.sleep(1) # move every 1 second
                
            print("Driver arrived at destination!")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(simulate_driver())
