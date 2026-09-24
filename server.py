from flask import Flask, render_template, jsonify, request
import subprocess
import json
import os
import sys

app = Flask(__name__, template_folder="templates", static_folder="static")

PROJECT_DIR = "/home/cybergaurav/.gemini/antigravity/scratch/poornima_bunk_calculator"
CORE_BINARY = os.path.join(PROJECT_DIR, "core/bunk_core")
JSON_REPORT = os.path.join(PROJECT_DIR, "core/bunk_report.json")
SCRAPER_SCRIPT = "/home/cybergaurav/.gemini/antigravity/scratch/tcs_dashboard/scraper.py"

def load_data():
    if not os.path.exists(JSON_REPORT):
        subprocess.run([CORE_BINARY, JSON_REPORT], check=True)
    with open(JSON_REPORT, "r") as f:
        return json.load(f)

@app.route("/")
def index():
    data = load_data()
    return render_template("index.html", data=data)

@app.route("/api/data")
def api_data():
    return jsonify(load_data())

@app.route("/api/sync", methods=["POST"])
def api_sync():
    try:
        # Run scraping probe
        res = subprocess.run([sys.executable, SCRAPER_SCRIPT], capture_output=True, text=True, timeout=25)
        # Update C++ core
        subprocess.run([CORE_BINARY, JSON_REPORT], check=True)
        return jsonify({"success": True, "data": load_data()})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route("/api/simulate", methods=["POST"])
def simulate_bunk():
    payload = request.get_json() or {}
    subject_code = payload.get("code")
    bunk_count = int(payload.get("bunk_count", 0))

    data = load_data()
    for s in data["subjects"]:
        if s["code"] == subject_code:
            sim_total = s["total"] + bunk_count
            sim_present = s["present"]
            sim_pct = round((sim_present / sim_total) * 100, 2) if sim_total > 0 else 0.0
            return jsonify({
                "code": s["code"],
                "name": s["name"],
                "current_pct": s["percentage"],
                "simulated_pct": sim_pct,
                "is_safe": sim_pct >= 75.0
            })

    return jsonify({"error": "Subject not found"}), 404

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5050, debug=False)
