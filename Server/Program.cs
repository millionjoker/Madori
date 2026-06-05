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
    var rooms = await db.States
        .Where(s => s.RoomId != null && s.DoorId == null && s.FurnitureId == null)
        .Select(s => new {
            roomId = s.RoomId,
            isOn = s.IsOn
        })
        .ToListAsync();

    var doors = await db.States
        .Where(s => s.DoorId != null)
        .Select(s => new {
            roomId = s.RoomId,
            doorId = s.DoorId,
            isOn = s.IsOn
        })
        .ToListAsync();

    var furnitures = await db.States
        .Where(s => s.FurnitureId != null)
        .Select(s => new {
            roomId = s.RoomId,
            furnitureId = s.FurnitureId,
            isOn = s.IsOn
        })
        .ToListAsync();

    return new {
        rooms,
        doors,
        furnitures
    };    
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
    var existing = await db.States
        .FirstOrDefaultAsync(s => s.RoomId == roomId && s.DoorId == null && s.FurnitureId == null);
    if (existing != null)
    {
        existing.IsOn = true;
        existing.UpdatedAt = DateTime.UtcNow;
    }
    else
    {
        db.States.Add(new State
        {
            RoomId = roomId,
            IsOn = true,
            UpdatedAt = DateTime.UtcNow
        });
    }
    await db.SaveChangesAsync();
    return Results.Ok(new { roomId, isOn = true });
});

// 部屋を OFF にする
app.MapPost("/rooms/{roomId}/off", async (int roomId, AppDb db) =>
{
    var existing = await db.States
        .FirstOrDefaultAsync(s =>
            s.RoomId == roomId &&
            s.DoorId == null &&
            s.FurnitureId == null);

    if (existing != null)
    {
        existing.IsOn = false;
        existing.UpdatedAt = DateTime.UtcNow;
    }
    else
    {
        db.States.Add(new State
        {
            RoomId = roomId,
            IsOn = false,
            UpdatedAt = DateTime.UtcNow
        });
    }

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
    var existing = await db.States
        .FirstOrDefaultAsync(s => s.RoomId == roomId && s.DoorId == doorId);

    if (existing != null)
    {
        existing.IsOn = true;
        existing.UpdatedAt = DateTime.UtcNow;
    }
    else
    {
        db.States.Add(new State
        {
            RoomId = roomId,
            DoorId = doorId,
            IsOn = true,
            UpdatedAt = DateTime.UtcNow
        });
    }

    await db.SaveChangesAsync();
    return Results.Ok(new { roomId, doorId, isOn = true });
});

// ドアを閉める
app.MapPost("/rooms/{roomId}/doors/{doorId}/close", async (int roomId, int doorId, AppDb db) =>
{
    var existing = await db.States
        .FirstOrDefaultAsync(s =>
            s.RoomId == roomId &&
            s.DoorId == doorId);

    if (existing != null)
    {
        existing.IsOn = false;
        existing.UpdatedAt = DateTime.UtcNow;
    }
    else
    {
        db.States.Add(new State
        {
            RoomId = roomId,
            DoorId = doorId,
            IsOn = false,
            UpdatedAt = DateTime.UtcNow
        });
    }

    await db.SaveChangesAsync();
    return Results.Ok(new { roomId, doorId, isOn = false });
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
    var existing = await db.States
        .FirstOrDefaultAsync(s => s.RoomId == roomId && s.FurnitureId == furnitureId);

    if (existing != null)
    {
        existing.IsOn = true;
        existing.UpdatedAt = DateTime.UtcNow;
    }
    else
    {
        db.States.Add(new State
        {
            RoomId = roomId,
            FurnitureId = furnitureId,
            IsOn = true,
            UpdatedAt = DateTime.UtcNow
        });
    }

    await db.SaveChangesAsync();
    return Results.Ok(new { roomId, furnitureId, isOn = true });    
});

// 家具を OFF にする
app.MapPost("/rooms/{roomId}/furnitures/{furnitureId}/off", async (int roomId, int furnitureId, AppDb db) =>
{
    var existing = await db.States
        .FirstOrDefaultAsync(s =>
            s.RoomId == roomId &&
            s.FurnitureId == furnitureId);

    if (existing != null)
    {
        existing.IsOn = false;
        existing.UpdatedAt = DateTime.UtcNow;
    }
    else
    {
        db.States.Add(new State
        {
            RoomId = roomId,
            FurnitureId = furnitureId,
            IsOn = false,
            UpdatedAt = DateTime.UtcNow
        });
    }

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