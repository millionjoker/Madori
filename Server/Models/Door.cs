namespace Madori.Api.Models
{
    public class Door
    {
        public int Id { get; set; } 
        public double CenterX { get; set; }
        public double CenterY { get; set; }
        public double Radius { get; set; }
        public double StartAngle { get; set; }
        public double EndAngle { get; set; }
        public string Color { get; set; } = "#FFFFFF";
        public bool IsOpen { get; set; }
    }
}
