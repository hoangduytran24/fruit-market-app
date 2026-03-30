using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Text;
using fruit_api.Data;
using fruit_api.Services;
using fruit_api.Services.Interfaces;
using fruit_api.Middleware;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

// Database Context
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// JWT Authentication
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]))
    };

    // Cấu hình JWT cho SignalR (nếu có)
    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            var accessToken = context.Request.Query["access_token"];
            var path = context.HttpContext.Request.Path;
            if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/hubs"))
            {
                context.Token = accessToken;
            }
            return Task.CompletedTask;
        }
    };
});

// Register Services
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<ICategoryService, CategoryService>();
builder.Services.AddScoped<IProductService, ProductService>();
builder.Services.AddScoped<ISupplierService, SupplierService>();
builder.Services.AddScoped<ICartService, CartService>();
builder.Services.AddScoped<IOrderService, OrderService>();
builder.Services.AddScoped<IVoucherService, VoucherService>();
builder.Services.AddScoped<IReviewService, ReviewService>();
builder.Services.AddScoped<IFileService, FileService>();
builder.Services.AddScoped<IFavoriteService, FavoriteService>();
builder.Services.AddScoped<IUserManagementService, UserManagementService>();
builder.Services.AddScoped<IStatisticsService, StatisticsService>();

// ========== VIETQR SERVICE ==========
builder.Services.AddScoped<VietQRService>();
builder.Services.AddScoped<BankTransactionService>();

// HttpContext Accessor (cần cho FileService)
builder.Services.AddHttpContextAccessor();

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "Fruit API", Version = "v1" });

    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme. Enter 'Bearer' [space] and then your token",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            new string[] {}
        }
    });
});

// ========== CẤU HÌNH CORS ==========
builder.Services.AddCors(options =>
{
    // Policy cho phép tất cả - Dùng trong development
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });

    // Policy cho phép các origin cụ thể - Dùng trong production
    options.AddPolicy("AllowSpecificOrigins", policy =>
    {
        policy.WithOrigins(
                "http://localhost:12345",      // Flutter web development
                "http://localhost:12346",
                "http://localhost:12347",
                "http://localhost:12348",
                "http://localhost:12349",
                "http://localhost:5000",        // React/Vue development
                "http://localhost:3000",
                "http://localhost:3001",
                "https://localhost:5001",       // HTTPS development
                "https://localhost:7262",       // API itself
                "https://yourdomain.com",       // Production domain (thay bằng domain thật)
                "https://admin.yourdomain.com"  // Admin domain (thay bằng domain thật)
            )
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials();
    });

    // Policy cho mobile app (không cần CORS nhưng vẫn có thể có)
    options.AddPolicy("MobileApp", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
else
{
    app.UseHsts(); // Thêm HSTS cho production
}

// Custom middleware
app.UseMiddleware<ErrorHandlingMiddleware>();

// Static files cho images (quan trọng cho ảnh sản phẩm)
app.UseStaticFiles(new StaticFileOptions
{
    OnPrepareResponse = ctx =>
    {
        // Thêm headers CORS cho static files
        ctx.Context.Response.Headers.Append("Access-Control-Allow-Origin", "*");
        ctx.Context.Response.Headers.Append("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
        ctx.Context.Response.Headers.Append("Access-Control-Allow-Headers", "Content-Type, Authorization");
    }
});

app.UseHttpsRedirection();

// ========== SỬ DỤNG CORS ==========
// Dùng CORS dựa trên môi trường
if (app.Environment.IsDevelopment())
{
    // Development: Cho phép tất cả để dễ test
    app.UseCors("AllowAll");
}
else
{
    // Production: Chỉ cho phép các origin cụ thể
    app.UseCors("AllowSpecificOrigins");
}

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.UseStaticFiles();
// Thêm endpoint để test CORS (bỏ WithOpenApi)
app.MapGet("/api/test-cors", () => Results.Ok(new { message = "CORS is working!" }));

app.Run();