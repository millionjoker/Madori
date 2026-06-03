using System;
using System.Text.Json;
namespace Madori.Api.Models
{
    public class State
    {
        public int Id { get; set; }
        // Flutter の state.json をそのまま保存する
        public string JsonData { get; set; } = string.Empty;
        public DateTime UpdatedAt { get; set; }
    }
}