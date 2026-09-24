#include <iostream>
#include <fstream>
#include <sstream>
#include <regex>
#include "../include/bunk_engine.hpp"
#include "../include/event_scheduler.hpp"

// Lightweight JSON serialization
void dump_json_output(const poornima::AttendanceReport& report, const std::string& filepath) {
    std::ofstream out(filepath);
    if (!out.is_open()) return;

    out << "{\n";
    out << "  \"app_name\": \"Poornima Bunk Calculator\",\n";
    out << "  \"developer\": \"Crafted with precision by Gourav Singh (cyber)\",\n";
    out << "  \"student_name\": \"" << report.student_name << "\",\n";
    out << "  \"program\": \"" << report.program << "\",\n";
    out << "  \"overall_total\": " << report.overall_total << ",\n";
    out << "  \"overall_present\": " << report.overall_present << ",\n";
    out << "  \"overall_absent\": " << report.overall_absent << ",\n";
    out << "  \"overall_percentage\": " << report.overall_percentage << ",\n";
    out << "  \"total_safe_bunks\": " << report.total_safe_bunks(75.0) << ",\n";
    out << "  \"bunk_advice\": \"" << report.generate_advisor_summary() << "\",\n";
    out << "  \"is_tcs_down\": " << (report.is_tcs_down ? "true" : "false") << ",\n";
    out << "  \"last_synced_at\": \"" << report.last_synced_at << "\",\n";
    out << "  \"date\": \"" << report.date_str << "\",\n";

    // Subjects
    out << "  \"subjects\": [\n";
    for (size_t i = 0; i < report.subjects.size(); ++i) {
        const auto& s = report.subjects[i];
        out << "    {\n";
        out << "      \"code\": \"" << s.code << "\",\n";
        out << "      \"name\": \"" << s.name << "\",\n";
        out << "      \"total\": " << s.total_lectures << ",\n";
        out << "      \"present\": " << s.present << ",\n";
        out << "      \"absent\": " << s.absent << ",\n";
        out << "      \"percentage\": " << s.percentage << ",\n";
        out << "      \"safe_bunks\": " << s.safe_bunks(75.0) << ",\n";
        out << "      \"need_to_attend\": " << s.required_to_attend(75.0) << "\n";
        out << "    }" << (i + 1 < report.subjects.size() ? "," : "") << "\n";
    }
    out << "  ],\n";

    // Today Schedule
    out << "  \"today_schedule\": [\n";
    for (size_t i = 0; i < report.today_schedule.size(); ++i) {
        const auto& p = report.today_schedule[i];
        out << "    {\n";
        out << "      \"subject\": \"" << p.subject_name << "\",\n";
        out << "      \"time_slot\": \"" << p.time_slot << "\",\n";
        out << "      \"status\": \"" << p.status << "\"\n";
        out << "    }" << (i + 1 < report.today_schedule.size() ? "," : "") << "\n";
    }
    out << "  ],\n";

    // Event Triggers
    auto events = poornima::EventScheduler::generate_daily_schedule(report.today_schedule);
    out << "  \"scheduled_triggers\": [\n";
    for (size_t i = 0; i < events.size(); ++i) {
        const auto& ev = events[i];
        char time_buf[16];
        snprintf(time_buf, sizeof(time_buf), "%02d:%02d", ev.trigger_hour, ev.trigger_minute);
        out << "    {\n";
        out << "      \"type\": \"" << ev.event_type << "\",\n";
        out << "      \"trigger_time\": \"" << time_buf << "\",\n";
        out << "      \"desc\": \"" << ev.description << "\"\n";
        out << "    }" << (i + 1 < events.size() ? "," : "") << "\n";
    }
    out << "  ]\n";
    out << "}\n";
}

int main(int argc, char** argv) {
    poornima::AttendanceReport report;
    report.student_name = "Gaurav";
    report.program = "B. Tech. (CY) PCE (Semester 1)";
    report.overall_total = 72;
    report.overall_present = 69;
    report.overall_absent = 3;
    report.overall_percentage = 95.83;
    report.date_str = "24-September-2026";
    report.is_tcs_down = false;
    report.last_synced_at = "2026-09-24 23:25:00";

    // Subject breakdown
    report.subjects = {
        {"NSP001", "Non Syllabus Project", 6, 6, 0, 100.0},
        {"PC261FY103", "Engineering Mathematics-I", 12, 12, 0, 100.0},
        {"PC261CY104", "Basic Electrical & Electronics Engg", 9, 7, 2, 77.78},
        {"PC261FY102", "Engineering Physics", 6, 5, 1, 83.33},
        {"PC261FY106", "Programming with C", 3, 3, 0, 100.0},
        {"PC261FY405", "Human Values and Ethics", 10, 10, 0, 100.0},
        {"PC261CY124", "Web Programming Lab", 6, 6, 0, 100.0},
        {"PC261FY122", "Engineering Physics Lab", 4, 4, 0, 100.0},
        {"PC261FY123", "Programming with C Lab", 2, 2, 0, 100.0},
        {"PC261FY526", "Language Lab*", 6, 6, 0, 100.0},
        {"PC261FY628", "IDEA Lab Workshop", 2, 2, 0, 100.0},
        {"PC261FY629", "Manufacturing Practices Workshop", 6, 6, 0, 100.0}
    };

    // Today Schedule
    report.today_schedule = {
        {"Human Values and Ethics", "PC261FY405", "08:00-09:00", "Present"},
        {"Basic Electrical & Electronics Engg", "PC261CY104", "09:00-10:00", "Present"},
        {"Engineering Mathematics-I", "PC261FY103", "10:00-11:00", "Present"},
        {"Human Values and Ethics", "PC261FY405", "11:00-12:00", "Present"},
        {"Web Programming Lab", "PC261CY124", "12:50-13:50", "Present"},
        {"Web Programming Lab", "PC261CY124", "13:50-14:50", "Present"}
    };

    std::string out_path = "/home/cybergaurav/.gemini/antigravity/scratch/poornima_bunk_calculator/core/bunk_report.json";
    if (argc > 1) {
        out_path = argv[1];
    }

    dump_json_output(report, out_path);
    std::cout << "[C++ Engine] Poornima Bunk Calculator Core successfully executed!\n";
    std::cout << "[C++ Engine] Safe Bunks Available: +" << report.total_safe_bunks(75.0) << "\n";
    std::cout << "[C++ Engine] Advisor: " << report.generate_advisor_summary() << "\n";
    std::cout << "[C++ Engine] Developer: Crafted with precision by Gourav Singh (cyber)\n";
    std::cout << "[C++ Engine] Output written to: " << out_path << "\n";

    return 0;
}
