using System;
using System.Text.Json;
namespace Madori.Api.Models
{
    public class State
    {
        public int Id { get; set; }
        // Flutter の state.json をそのまま保存する
//        public string JsonData { get; set; } = string.Empty;
        public int? RoomId { get; set; }
        public int? DoorId { get; set; }
        public int? FurnitureId { get; set; }
        public bool? IsOn { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}