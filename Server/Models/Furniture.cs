namespace Madori.Api.Models
{
    public class Furniture
    {
        public int Id { get; set; } 
        public string Type { get; set; } = "";
        public double X { get; set; }
        public double Y { get; set; }
        public double Width { get; set; }
        public double Height { get; set; }
        public string Color { get; set; } = "#FFFFFF";
        public bool IsOn { get; set; }
    }
}
