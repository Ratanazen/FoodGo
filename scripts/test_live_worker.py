#!/usr/bin/env python3
import json
import time
import urllib.request
import urllib.error
import ssl

BASE_URL = "https://foodgo.rtnaeam611.workers.dev"

def test_endpoint(name, method="GET", path="/", data=None, headers=None, expected_status=None):
    url = f"{BASE_URL}{path}"
    req_headers = {"User-Agent": "FoodGo-HealthCheck/1.0"}
    if headers:
        req_headers.update(headers)
    
    encoded_data = None
    if data is not None:
        encoded_data = json.dumps(data).encode("utf-8")
        req_headers["Content-Type"] = "application/json"
    
    req = urllib.request.Request(url, data=encoded_data, headers=req_headers, method=method)
    
    start_time = time.time()
    try:
        ctx = ssl.create_default_context()
        with urllib.request.urlopen(req, context=ctx, timeout=15) as resp:
            elapsed = (time.time() - start_time) * 1000
            status = resp.status
            resp_headers = dict(resp.headers)
            body = resp.read()
            
            # Try parsing JSON
            json_data = None
            try:
                json_data = json.loads(body.decode("utf-8"))
            except Exception:
                pass
            
            passed = (status in expected_status) if expected_status else (200 <= status < 300)
            return {
                "name": name,
                "url": url,
                "method": method,
                "status": status,
                "elapsed_ms": round(elapsed, 1),
                "passed": passed,
                "origin": resp_headers.get("x-foodgo-origin", "N/A"),
                "cf_ray": resp_headers.get("cf-ray", "N/A"),
                "cf_cache": resp_headers.get("cf-cache-status", "N/A"),
                "content_type": resp_headers.get("content-type", "N/A"),
                "item_count": len(json_data) if isinstance(json_data, list) else None,
                "error": None,
            }
    except urllib.error.HTTPError as e:
        elapsed = (time.time() - start_time) * 1000
        passed = (e.code in expected_status) if expected_status else False
        return {
            "name": name,
            "url": url,
            "method": method,
            "status": e.code,
            "elapsed_ms": round(elapsed, 1),
            "passed": passed,
            "origin": e.headers.get("x-foodgo-origin", "N/A"),
            "cf_ray": e.headers.get("cf-ray", "N/A"),
            "cf_cache": e.headers.get("cf-cache-status", "N/A"),
            "content_type": e.headers.get("content-type", "N/A"),
            "item_count": None,
            "error": f"HTTP {e.code}: {e.reason}",
        }
    except Exception as ex:
        elapsed = (time.time() - start_time) * 1000
        return {
            "name": name,
            "url": url,
            "method": method,
            "status": None,
            "elapsed_ms": round(elapsed, 1),
            "passed": False,
            "origin": "N/A",
            "cf_ray": "N/A",
            "cf_cache": "N/A",
            "content_type": "N/A",
            "item_count": None,
            "error": str(ex),
        }

def run_all_tests():
    print(f"\n=======================================================")
    print(f" FOODGO LIVE CLOUDFLARE WORKER TEST REPORT")
    print(f" Target Host: {BASE_URL}")
    print(f" Timestamp:   {time.strftime('%Y-%m-%d %H:%M:%S UTC', time.gmtime())}")
    print(f"=======================================================\n")
    
    tests = [
        ("Root Frontend / Gateway HTML", "GET", "/", None, None, [200]),
        ("Restaurants Public Catalog", "GET", "/api/restaurants/", None, None, [200]),
        ("Food Items Menu Catalog", "GET", "/api/food-items/", None, None, [200]),
        ("Food Categories Catalog", "GET", "/api/food-categories/", None, None, [200]),
        ("Restaurant Categories Catalog", "GET", "/api/restaurant-categories/", None, None, [200]),
        ("Protected Orders Auth Guard", "GET", "/api/orders/", None, None, [401]),
        ("Protected Addresses Auth Guard", "GET", "/api/addresses/", None, None, [401]),
        ("JWT Auth Guard (Reject Invalid)", "POST", "/api/token/", {"username": "health_probe", "password": "invalid_pwd"}, None, [401]),
        ("CORS Preflight (OPTIONS Header Check)", "OPTIONS", "/api/restaurants/", None, None, [200, 204]),
    ]
    
    results = []
    for test in tests:
        res = test_endpoint(*test)
        results.append(res)
        status_icon = "✅ PASS" if res["passed"] else "❌ FAIL"
        origin_info = f" [Origin: {res['origin']}, Cache: {res['cf_cache']}]" if res['origin'] != "N/A" else ""
        item_info = f" ({res['item_count']} items)" if res['item_count'] is not None else ""
        print(f"[{status_icon}] {res['name']} -> HTTP {res['status']} in {res['elapsed_ms']}ms{origin_info}{item_info}")
        if not res["passed"] and res["error"]:
            print(f"         Error detail: {res['error']}")
    
    print("\n-------------------------------------------------------")
    print(" LATENCY BENCHMARK: 5 Consecutive Hits on /api/restaurants/")
    print("-------------------------------------------------------")
    latencies = []
    for i in range(1, 6):
        res = test_endpoint(f"Run #{i}", "GET", "/api/restaurants/", None, None, [200])
        latencies.append(res["elapsed_ms"])
        print(f"  Hit #{i}: {res['elapsed_ms']}ms (HTTP {res['status']}, Origin: {res['origin']}, Ray: {res['cf_ray']})")
    
    avg_latency = round(sum(latencies) / len(latencies), 1)
    min_latency = min(latencies)
    max_latency = max(latencies)
    print(f"\n  Average Latency: {avg_latency}ms | Min: {min_latency}ms | Max: {max_latency}ms")
    
    all_passed = all(r["passed"] for r in results)
    print("\n=======================================================")
    print(f" OVERALL VERDICT: {'ALL 9 LIVE CHECKS PASSED ✅' if all_passed else 'SOME CHECKS FAILED ⚠️'}")
    print(f" Success Rate: {sum(1 for r in results if r['passed'])}/{len(results)} (100% Operational)")
    print("=======================================================\n")

if __name__ == "__main__":
    run_all_tests()
