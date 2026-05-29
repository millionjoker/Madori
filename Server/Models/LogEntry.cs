using System;
using System.Text.Json;
namespace Madori.Api.Models
{
    public class LogEntry
    {
        public long Id { get; set; }
        public string DeviceId { get; set; } = string.Empty;
        public DateTime EventTime { get; set; }
        public string EventType { get; set; } = string.Empty;
        // Flutter の logs.jsonl の 1 行分をそのまま保存
        public JsonElement Payload { get; set; }
    }
}
