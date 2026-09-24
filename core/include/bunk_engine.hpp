#pragma once

#include <string>
#include <vector>
#include <cmath>
#include <sstream>
#include <iomanip>

namespace poornima {

struct Subject {
    std::string code;
    std::string name;
    int total_lectures{0};
    int present{0};
    int absent{0};
    double percentage{0.0};

    // Calculate how many lectures can be safely skipped for this subject
    int safe_bunks(double target_pct = 75.0) const {
        if (total_lectures == 0) return 0;
        double target = target_pct / 100.0;
        int max_total = static_cast<int>(std::floor(static_cast<double>(present) / target));
        int bunks = max_total - total_lectures;
        return bunks > 0 ? bunks : 0;
    }

    // Calculate how many consecutive lectures must be attended to reach target %
    int required_to_attend(double target_pct = 75.0) const {
        if (percentage >= target_pct) return 0;
        double target = target_pct / 100.0;
        double needed = (target * total_lectures - present) / (1.0 - target);
        return static_cast<int>(std::ceil(needed));
    }
};

struct PeriodSlot {
    std::string subject_name;
    std::string course_code;
    std::string time_slot; // e.g., "08:00-09:00"
    std::string status;    // "Present", "Absent", "Not Marked", "Pending"
    int end_hour{0};
    int end_minute{0};

    void parse_end_time() {
        // Expected format "HH:MM-HH:MM"
        auto dash_pos = time_slot.find('-');
        if (dash_pos != std::string::npos && dash_pos + 1 < time_slot.length()) {
            std::string end_str = time_slot.substr(dash_pos + 1);
            auto colon_pos = end_str.find(':');
            if (colon_pos != std::string::npos) {
                try {
                    end_hour = std::stoi(end_str.substr(0, colon_pos));
                    end_minute = std::stoi(end_str.substr(colon_pos + 1));
                } catch (...) {
                    end_hour = 0;
                    end_minute = 0;
                }
            }
        }
    }
};

struct AttendanceReport {
    std::string student_name;
    std::string program;
    int overall_total{0};
    int overall_present{0};
    int overall_absent{0};
    double overall_percentage{0.0};
    std::vector<Subject> subjects;
    std::vector<PeriodSlot> today_schedule;
    std::string date_str;
    bool is_tcs_down{false};
    std::string last_synced_at;

    int total_safe_bunks(double target_pct = 75.0) const {
        if (overall_total == 0) return 0;
        double target = target_pct / 100.0;
        int max_total = static_cast<int>(std::floor(static_cast<double>(overall_present) / target));
        int bunks = max_total - overall_total;
        return bunks > 0 ? bunks : 0;
    }

    std::string generate_advisor_summary() const {
        std::ostringstream ss;
        if (overall_percentage >= 75.0) {
            int bunks = total_safe_bunks(75.0);
            ss << "You can safely miss up to " << bunks << " class(es) and remain comfortably above 75%.";
        } else {
            double target = 0.75;
            double needed = (target * overall_total - overall_present) / (1.0 - target);
            int req = static_cast<int>(std::ceil(needed));
            ss << "You must attend the next " << req << " consecutive class(es) to cross 75%.";
        }
        return ss.str();
    }
};

} // namespace poornima
