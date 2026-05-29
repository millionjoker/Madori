using System;
using System.Text.Json;
namespace Madori.Api.Models
{
    public class State
    {
        public int Id { get; set; }
        // Flutter の state.json をそのまま保存する
        public JsonElement JsonData { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}