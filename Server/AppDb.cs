using Microsoft.EntityFrameworkCore;
using Madori.Api.Models;

namespace Madori.Api;
public class AppDb : DbContext
{
    public AppDb(DbContextOptions<AppDb> options) : base(options)
    {
    }

    // ★ State テーブル用
    public DbSet<State> States { get; set; }

    // ★ LogEntry テーブル用
    public DbSet<LogEntry> Logs { get; set; }
}
