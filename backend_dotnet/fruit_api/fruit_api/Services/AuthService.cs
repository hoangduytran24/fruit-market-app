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
    private readonly ILogger<AuthService> _logger;

    public AuthService(
        ApplicationDbContext context,
        IConfiguration configuration,
        ILogger<AuthService> logger)
    {
        _context = context;
        _configuration = configuration;
        _logger = logger;
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
            throw new Exception("Sai tên đăng nhập hoặc mật khẩu");
        }

        // Check password
        if (!BCrypt.Net.BCrypt.Verify(loginDto.Password, user.PasswordHash))
        {
            throw new Exception("Sai tên đăng nhập hoặc mật khẩu");
        }

        // Check status
        if (user.Status != "active")
        {
            throw new Exception("Tài khoản của bạn đã bị khóa");
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

    public async Task<AuthResponseDto> GetUserByIdAsync(string userId)
    {
        var user = await _context.Users
            .FirstOrDefaultAsync(u => u.UserId == userId);

        if (user == null)
        {
            throw new Exception("User not found");
        }

        return new AuthResponseDto
        {
            UserId = user.UserId,
            FullName = user.FullName,
            Email = user.Email,
            Phone = user.Phone,
            Role = user.Role,
            Token = null  // Không cần trả token mới
        };
    }

    // ===============================
    // CHECK ACCOUNT STATUS
    // ===============================
    public async Task<AccountStatusDto> CheckAccountStatusAsync(string userId)
    {
        var user = await _context.Users
            .Where(u => u.UserId == userId)
            .Select(u => new AccountStatusDto
            {
                UserId = u.UserId,
                FullName = u.FullName,
                Email = u.Email,
                Phone = u.Phone,
                Role = u.Role,
                Status = u.Status,
                IsActive = u.Status == "active"
            })
            .FirstOrDefaultAsync();

        if (user == null)
        {
            throw new Exception("Không tìm thấy người dùng");
        }

        return user;
    }

    // ===============================
    // LOCK USER ACCOUNT (for Admin)
    // ===============================
    public async Task<bool> LockUserAccountAsync(string userId, string? reason = null)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null)
        {
            throw new Exception("Không tìm thấy người dùng");
        }

        if (user.Status == "active")
        {
            user.Status = "locked"; // hoặc "inactive", "banned"

            // Nếu muốn lưu thêm thông tin (cần thêm các field này vào model User)
            // user.LockedAt = DateTime.UtcNow;
            // user.LockReason = reason;
            // user.LockedBy = adminUserId;

            await _context.SaveChangesAsync();

            _logger.LogInformation($"Tài khoản {userId} ({user.FullName}) đã bị khóa. Lý do: {reason ?? "Không có lý do"}");
            return true;
        }

        _logger.LogWarning($"Tài khoản {userId} hiện đang có status '{user.Status}', không thể khóa");
        return false;
    }

    // ===============================
    // UNLOCK USER ACCOUNT (for Admin)
    // ===============================
    public async Task<bool> UnlockUserAccountAsync(string userId)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null)
        {
            throw new Exception("Không tìm thấy người dùng");
        }

        if (user.Status != "active")
        {
            user.Status = "active";

            // Nếu muốn xóa thông tin khóa
            // user.LockedAt = null;
            // user.LockReason = null;
            // user.LockedBy = null;

            await _context.SaveChangesAsync();

            _logger.LogInformation($"Tài khoản {userId} ({user.FullName}) đã được mở khóa");
            return true;
        }

        _logger.LogWarning($"Tài khoản {userId} hiện đang ở trạng thái active, không cần mở khóa");
        return false;
    }

    // ===============================
    // GET ALL LOCKED USERS (for Admin)
    // ===============================
    public async Task<List<AccountStatusDto>> GetLockedUsersAsync()
    {
        var lockedUsers = await _context.Users
            .Where(u => u.Status != "active")
            .Select(u => new AccountStatusDto
            {
                UserId = u.UserId,
                FullName = u.FullName,
                Email = u.Email,
                Phone = u.Phone,
                Role = u.Role,
                Status = u.Status,
                IsActive = false
            })
            .ToListAsync();

        return lockedUsers;
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