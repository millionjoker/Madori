using Microsoft.EntityFrameworkCore;
using Madori.Api; 
using Madori.Api.Models; 
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<AppDb>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddOpenApi();

var app = builder.Build();

// ==============================
// ★ 間取りデータの読み込み
// ==============================
var jsonText = File.ReadAllText("madori.json");
var rooms = JsonSerializer.Deserialize<List<Room>>(jsonText);

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();


// ==============================
// ★ State API（ここから）
// ==============================

// 最新の State を返す
app.MapGet("/state", async (AppDb db) =>
{
    return await db.States
        .OrderByDescending(s => s.Id)
        .FirstOrDefaultAsync();
});

// State を保存（新規追加）
app.MapPost("/state", async (AppDb db, State newState) =>
{
    newState.UpdatedAt = DateTime.UtcNow;

    db.States.Add(newState);
    await db.SaveChangesAsync();

    return Results.Created($"/state/{newState.Id}", newState);
});

// ==============================
// ★ State API（ここまで）
// ==============================

// ==============================
// ★ Room API（ここから）
// ==============================

// 部屋を ON にする
app.MapPost("/rooms/{roomId}/on", async (int roomId, AppDb db) =>
{
    var room = rooms.FirstOrDefault(r => r.Id == roomId);
    if (room == null)
        return Results.NotFound($"Room {roomId} not found");

    var state = new State
    {
        JsonData = JsonSerializer.Serialize(new {
            room = roomId,
            isOn = true
        }),
        UpdatedAt = DateTime.UtcNow
    };

    db.States.Add(state);
    await db.SaveChangesAsync();

    return Results.Ok(new { roomId, isOn = true });
});

// 部屋を OFF にする
app.MapPost("/rooms/{roomId}/off", async (int roomId, AppDb db) =>
{
    var room = rooms.FirstOrDefault(r => r.Id == roomId);
    if (room == null)
        return Results.NotFound($"Room {roomId} not found");

    var state = new State
    {
        JsonData = JsonSerializer.Serialize(new {
            room = roomId,
            isOn = false
        }),
        UpdatedAt = DateTime.UtcNow
    };

    db.States.Add(state);
    await db.SaveChangesAsync();

    return Results.Ok(new { roomId, isOn = false });
});

// ==============================
// ★ Room API（ここまで）
// ==============================

// ==============================
// ★ Door API（ここから）
// ==============================

// ドアを開ける
app.MapPost("/rooms/{roomId}/doors/{doorId}/open", async (int roomId, int doorId, AppDb db) =>
{
    var room = rooms.FirstOrDefault(r => r.Id == roomId);
    if (room == null)
        return Results.NotFound($"Room {roomId} not found");

    var door = room.Doors.FirstOrDefault(d => d.Id == doorId);
    if (door == null)
        return Results.NotFound($"Door {doorId} not found in room {roomId}");

    var state = new State
    {
        JsonData = JsonSerializer.Serialize(new {
            room = roomId,
            door = doorId,
            isOpen = true
        }),
        UpdatedAt = DateTime.UtcNow
    };

    db.States.Add(state);
    await db.SaveChangesAsync();

    return Results.Ok(new { roomId, doorId, isOpen = true });
});

// ドアを閉める
app.MapPost("/rooms/{roomId}/doors/{doorId}/close", async (int roomId, int doorId, AppDb db) =>
{
    var room = rooms.FirstOrDefault(r => r.Id == roomId);
    if (room == null)
        return Results.NotFound($"Room {roomId} not found");

    var door = room.Doors.FirstOrDefault(d => d.Id == doorId);
    if (door == null)
        return Results.NotFound($"Door {doorId} not found in room {roomId}");

    var state = new State
    {
            JsonData = JsonSerializer.Serialize(new {
            room = roomId,
            door = doorId,
            isOpen = false
        }),
        UpdatedAt = DateTime.UtcNow
    };

    db.States.Add(state);
    await db.SaveChangesAsync();

    return Results.Ok(new { roomId, doorId, isOpen = false });
});

// ==============================
// ★ Door API（ここまで）
// ==============================

// ==============================
// ★ Furniture API（ここから）
// ==============================

// 家具を ON にする
app.MapPost("/rooms/{roomId}/furnitures/{furnitureId}/on", async (int roomId, int furnitureId, AppDb db) =>
{
    var room = rooms.FirstOrDefault(r => r.Id == roomId);
    if (room == null)
        return Results.NotFound($"Room {roomId} not found");

    var f = room.Furnitures.FirstOrDefault(x => x.Id == furnitureId);
    if (f == null)
        return Results.NotFound($"Furniture {furnitureId} not found in room {roomId}");

    var state = new State
    {
        JsonData = JsonSerializer.Serialize(new {
            room = roomId,
            furniture = furnitureId,
            isOn = true
        }),
        UpdatedAt = DateTime.UtcNow
    };

    db.States.Add(state);
    await db.SaveChangesAsync();

    return Results.Ok(new { roomId, furnitureId, isOn = true });
});

// 家具を OFF にする
app.MapPost("/rooms/{roomId}/furnitures/{furnitureId}/off", async (int roomId, int furnitureId, AppDb db) =>
{
    var room = rooms.FirstOrDefault(r => r.Id == roomId);
    if (room == null)
        return Results.NotFound($"Room {roomId} not found");

    var f = room.Furnitures.FirstOrDefault(x => x.Id == furnitureId);
    if (f == null)
        return Results.NotFound($"Furniture {furnitureId} not found in room {roomId}");

    var state = new State
    {
        JsonData = JsonSerializer.Serialize(new {
            room = roomId,
            furniture = furnitureId,
            isOn = false
        }),
        UpdatedAt = DateTime.UtcNow
    };

    db.States.Add(state);
    await db.SaveChangesAsync();

    return Results.Ok(new { roomId, furnitureId, isOn = false });
});

// ==============================
// ★ Furniture API（ここまで）
// ==============================


// -------------------------------
// Logs API（ここから貼る）
// -------------------------------
app.MapGet("/logs", async (AppDb db) =>
{
    return await db.Logs
        .OrderByDescending(l => l.EventTime)
        .Take(100)
        .ToListAsync();
});

app.MapPost("/logs", async (AppDb db, LogEntry log) =>
{
    if (log.EventTime == default)
        log.EventTime = DateTime.UtcNow;
    db.Logs.Add(log);
    await db.SaveChangesAsync();
    return Results.Created($"/logs/{log.Id}", log);
});
// -------------------------------
// Logs API（ここまで）
// -------------------------------

app.Run();