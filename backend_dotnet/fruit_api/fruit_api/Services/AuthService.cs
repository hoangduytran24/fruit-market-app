using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using fruit_api.Data;
using fruit_api.DTOs.Auth;
using fruit_api.Models;
using fruit_api.Services.Interfaces;

namespace fruit_api.Services;

public class AuthService : IAuthService
{
    private readonly ApplicationDbContext _context;
    private readonly IConfiguration _configuration;

    public AuthService(ApplicationDbContext context, IConfiguration configuration)
    {
        _context = context;
        _configuration = configuration;
    }

    public async Task<AuthResponseDto> RegisterAsync(RegisterDto registerDto)
    {
        // Check existing user
        var existingUser = await _context.Users
            .FirstOrDefaultAsync(u => u.Email == registerDto.Email || u.Phone == registerDto.Phone);

        if (existingUser != null)
        {
            throw new Exception("Email or phone already exists");
        }

        // Generate UserId
        var userId = await GenerateUserId();

        // Create new user
        var user = new User
        {
            UserId = userId,
            FullName = registerDto.FullName,
            Email = registerDto.Email,
            Phone = registerDto.Phone,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(registerDto.Password),
            Role = "customer",
            Status = "active",
            CreatedAt = DateTime.UtcNow
        };

        // Create cart for user and link navigation properties so EF knows the relationship
        var cart = new Cart
        {
            CartId = Guid.NewGuid().ToString(),
            UserId = user.UserId,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow,
            User = user
        };

        user.Cart = cart;

        // Add entities
        _context.Users.Add(user);
        _context.Carts.Add(cart);

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateException dbEx)
        {
            // Surface inner exception message to help identify the real SQL/constraint error
            var inner = dbEx.InnerException?.Message ?? dbEx.Message;
            throw new Exception($"Database save failed: {inner}");
        }

        // Generate token
        var token = GenerateJwtToken(user);

        return new AuthResponseDto
        {
            UserId = user.UserId,
            FullName = user.FullName,
            Email = user.Email,
            Phone = user.Phone,
            Role = user.Role,
            Token = token
        };
    }

    public async Task<AuthResponseDto> LoginAsync(LoginDto loginDto)
    {
        // Find user
        var user = await _context.Users
            .FirstOrDefaultAsync(u => u.Email == loginDto.Username || u.Phone == loginDto.Username);

        if (user == null)
        {
            throw new Exception("Invalid username or password");
        }

        // Check password
        if (!BCrypt.Net.BCrypt.Verify(loginDto.Password, user.PasswordHash))
        {
            throw new Exception("Invalid username or password");
        }

        // Check status
        if (user.Status != "active")
        {
            throw new Exception("Account is not active");
        }

        // Generate token
        var token = GenerateJwtToken(user);

        return new AuthResponseDto
        {
            UserId = user.UserId,
            FullName = user.FullName,
            Email = user.Email,
            Phone = user.Phone,
            Role = user.Role,
            Token = token
        };
    }

    // ===============================
    // Generate JWT Token
    // ===============================
    private string GenerateJwtToken(User user)
    {
        var tokenHandler = new JwtSecurityTokenHandler();
        var key = Encoding.ASCII.GetBytes(_configuration["Jwt:Key"]);

        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, user.UserId),
            new Claim(ClaimTypes.Name, user.FullName),
            new Claim(ClaimTypes.Role, user.Role)
        };

        if (!string.IsNullOrEmpty(user.Email))
            claims.Add(new Claim(ClaimTypes.Email, user.Email));

        if (!string.IsNullOrEmpty(user.Phone))
            claims.Add(new Claim(ClaimTypes.MobilePhone, user.Phone));

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = DateTime.UtcNow.AddDays(7),
            Issuer = _configuration["Jwt:Issuer"],
            Audience = _configuration["Jwt:Audience"],
            SigningCredentials = new SigningCredentials(
                new SymmetricSecurityKey(key),
                SecurityAlgorithms.HmacSha256Signature)
        };

        var token = tokenHandler.CreateToken(tokenDescriptor);
        return tokenHandler.WriteToken(token);
    }

    // ===============================
    // Generate UserId: US0001
    // ===============================
    private async Task<string> GenerateUserId()
    {
        var lastUser = await _context.Users
            .OrderByDescending(u => u.UserId)
            .FirstOrDefaultAsync();

        int nextNumber = 1;

        if (lastUser != null)
        {
            int number = int.Parse(lastUser.UserId.Substring(2));
            nextNumber = number + 1;
        }

        return "US" + nextNumber.ToString("D4");
    }
}