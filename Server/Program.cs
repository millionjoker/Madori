using Microsoft.EntityFrameworkCore;
using Madori.Api;   // ← AppDb の namespace に合わせる
using Madori.Api.Models; 

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<AppDb>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddOpenApi();

var app = builder.Build();

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
