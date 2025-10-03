using Dapper;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore.Metadata.Internal;
using Microsoft.IdentityModel.Tokens;
using MySqlConnector;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

var builder = WebApplication.CreateBuilder(args);
var configuration = builder.Configuration;

// JWT Authentication  (Encoding.UTF8.GetBytes(configuration["Jwt:Key"]))
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = configuration["Jwt:Issuer"],
            ValidAudience = configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(configuration["Jwt:Key"]))
        };
    });


builder.Services.AddAuthorization();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI();

app.UseAuthentication();
app.UseAuthorization();

string connString = configuration.GetConnectionString("DefaultConnection");

// ------------------- Endpoints -------------------

// Login - hardcoded user demo
app.MapPost("/auth/login", (LoginRequest req) =>
{
    if (req.Username == "admin" && req.Password == "password")
    {
        var tokenHandler = new JwtSecurityTokenHandler();

        var keyString = configuration["Jwt:Key"];
        if (string.IsNullOrEmpty(keyString))
        {
            throw new Exception("JWT Key is missing in appsettings.json");
        }
        var key = Encoding.UTF8.GetBytes(keyString);

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(new[]
            {
                new Claim(ClaimTypes.Name, req.Username),
                new Claim(ClaimTypes.Role, "Admin")
            }),
            Expires = DateTime.UtcNow.AddHours(2),
            Issuer = configuration["Jwt:Issuer"],
            Audience = configuration["Jwt:Audience"],
            SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
        };
        var token = tokenHandler.CreateToken(tokenDescriptor);
        return Results.Ok(new { token = tokenHandler.WriteToken(token) });
    }
    return Results.Unauthorized();
});

// Get items (paged, filtered)
app.MapGet("/api/items", async (string? search, int page = 1, int pageSize = 10) =>
{
    using var conn = new MySqlConnection(connString);
    string sql = "SELECT * FROM Items WHERE 1=1 ";
    if (!string.IsNullOrEmpty(search))
        sql += "AND (Sku LIKE @Search OR Name LIKE @Search) ";
    sql += "LIMIT @Offset,@PageSize";

    var items = await conn.QueryAsync<Item>(sql, new { Search = $"%{search}%", Offset = (page - 1) * pageSize, PageSize = pageSize });
    return Results.Ok(items);
});

// Get stock for item
app.MapGet("/api/items/{id}/stock", async (int id) =>
{
    using var conn = new MySqlConnection(connString);
    var stock = await conn.QueryFirstOrDefaultAsync("SELECT * FROM vw_StockOnHand WHERE ItemId=@Id", new { Id = id });
    if (stock == null) return Results.NotFound();
    return Results.Ok(stock);
});

// Post receipt
app.MapPost("/api/receipts/{receiptId}/post", async (int receiptId) =>
{
    using var conn = new MySqlConnection(connString);
    try
    {
        await conn.ExecuteAsync("CALL usp_PostReceipt(@ReceiptId)", new { ReceiptId = receiptId });
        return Results.Ok(new { message = "Receipt posted" });
    }
    catch (Exception ex)
    {
        return Results.Problem(ex.Message);
    }
});

// Post shipment
app.MapPost("/api/shipments/{shipId}/post", async (int shipId) =>
{
    using var conn = new MySqlConnection(connString);
    try
    {
        await conn.ExecuteAsync("CALL usp_PostShipment(@ShipId)", new { ShipId = shipId });
        return Results.Ok(new { message = "Shipment posted" });
    }
    catch (Exception ex)
    {
        return Results.Problem(ex.Message);
    }
});

// KPI: Sales
app.MapGet("/api/kpi/sales", async (DateTime startDate, DateTime endDate) =>
{
    using var conn = new MySqlConnection(connString);
    var topItems = await conn.QueryAsync("CALL usp_TopItemsByMargin(@StartDate,@EndDate,@TopN)",
        new { StartDate = startDate, EndDate = endDate, TopN = 5 });
    return Results.Ok(topItems);
});

app.Run();

// ------------------- Models -------------------
record LoginRequest(string Username, string Password);

public class Item
{
    public int ItemId { get; set; }
    public string Sku { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Category { get; set; }
    public decimal UnitPrice { get; set; }
    public bool Active { get; set; }
}
