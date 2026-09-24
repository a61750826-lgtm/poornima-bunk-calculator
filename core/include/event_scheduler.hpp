#pragma once

#include "bunk_engine.hpp"
#include <vector>
#include <chrono>
#include <ctime>
#include <iomanip>

namespace poornima {

struct ScheduledEvent {
    std::string event_type; // "MORNING_DIGEST", "POST_CLASS_PROBE", "NIGHT_HIBERNATE"
    int trigger_hour;
    int trigger_minute;
    std::string period_info;
    std::string description;
};

class EventScheduler {
public:
    static std::vector<ScheduledEvent> generate_daily_schedule(const std::vector<PeriodSlot>& today_slots) {
        std::vector<ScheduledEvent> events;

        // 1. Always schedule 7:30 AM Morning Digest
        events.push_back({
            "MORNING_DIGEST",
            7, 30,
            "",
            "Morning brief: Today's lectures and safe bunk wallet balance"
        });

        // 2. If no classes today (Weekend / Holiday), hibernate immediately
        if (today_slots.empty()) {
            events.push_back({
                "NIGHT_HIBERNATE",
                8, 0,
                "",
                "No classes scheduled today. Hibernate engine."
            });
            return events;
        }

        // 3. For each scheduled period, set an alarm exactly 10 minutes after period end
        for (const auto& slot : today_slots) {
            PeriodSlot s = slot;
            s.parse_end_time();

            if (s.end_hour > 0) {
                int probe_min = s.end_minute + 10;
                int probe_hour = s.end_hour;
                if (probe_min >= 60) {
                    probe_min -= 60;
                    probe_hour += 1;
                }

                std::ostringstream ss;
                ss << "Probe attendance 10 min after " << s.subject_name << " (" << s.time_slot << ")";

                events.push_back({
                    "POST_CLASS_PROBE",
                    probe_hour, probe_min,
                    s.subject_name + " [" + s.time_slot + "]",
                    ss.str()
                });
            }
        }

        // 4. Night Hibernate after last class
        events.push_back({
            "NIGHT_HIBERNATE",
            17, 0,
            "",
            "College hours finished. Hibernate all triggers until next 7:30 AM."
        });

        return events;
    }
};

} // namespace poornima
