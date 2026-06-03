namespace Madori.Api.Models
{
    public class Room
    {
        public int Id { get; set; } 
        public string Name { get; set; } = "";
        public string BackgroundColor { get; set; } = "#FFFFFF";

        public List<PointDto> Points { get; set; } = new();
        public List<Door> Doors { get; set; } = new();
        public List<Furniture> Furnitures { get; set; } = new();
    }

    public class PointDto
    {
        public double X { get; set; }
        public double Y { get; set; }
    }
}
