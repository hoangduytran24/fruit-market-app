using Microsoft.EntityFrameworkCore;
using fruit_api.Data;
using fruit_api.DTOs.User;
using fruit_api.Models;
using fruit_api.Services.Interfaces;

namespace fruit_api.Services;

public class UserManagementService : IUserManagementService
{
    private readonly ApplicationDbContext _context;

    public UserManagementService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<UserDto>> GetUsersAsync(string? search = null, string? role = null)
    {
        var query = _context.Users
            .Include(u => u.Orders)
            .AsQueryable();

        // Lọc theo role
        if (!string.IsNullOrEmpty(role))
        {
            query = query.Where(u => u.Role == role);
        }

        // Tìm kiếm theo tên, email, SĐT
        if (!string.IsNullOrEmpty(search))
        {
            query = query.Where(u =>
                u.FullName.Contains(search) ||
                (u.Email != null && u.Email.Contains(search)) ||
                (u.Phone != null && u.Phone.Contains(search))
            );
        }

        return await query
            .OrderByDescending(u => u.CreatedAt)
            .Select(u => new UserDto
            {
                UserId = u.UserId,
                FullName = u.FullName,
                Email = u.Email,
                Phone = u.Phone,
                Role = u.Role,
                Status = u.Status,
                CreatedAt = u.CreatedAt,
                OrderCount = u.Orders != null ? u.Orders.Count : 0,
                TotalSpent = u.Orders != null && u.Orders.Any()
                    ? (double)u.Orders.Where(o => o.Status == "completed").Sum(o => (decimal)o.FinalAmount)
                    : 0
            })
            .ToListAsync();
    }

    public async Task<UserDto?> GetUserByIdAsync(string userId)
    {
        var user = await _context.Users
            .Include(u => u.Orders)
            .FirstOrDefaultAsync(u => u.UserId == userId);

        if (user == null) return null;

        return new UserDto
        {
            UserId = user.UserId,
            FullName = user.FullName,
            Email = user.Email,
            Phone = user.Phone,
            Role = user.Role,
            Status = user.Status,
            CreatedAt = user.CreatedAt,
            OrderCount = user.Orders != null ? user.Orders.Count : 0,
            TotalSpent = user.Orders != null && user.Orders.Any()
                ? (double)user.Orders.Where(o => o.Status == "completed").Sum(o => (decimal)o.FinalAmount)
                : 0
        };
    }

    public async Task<UserDto> UpdateUserStatusAsync(string userId, UpdateUserStatusDto updateDto)
    {
        var user = await _context.Users.FindAsync(userId);

        if (user == null)
            throw new Exception("User not found");

        // Không cho khóa tài khoản admin
        if (user.Role == "admin" && updateDto.Status != "active")
            throw new Exception("Cannot block admin account");

        user.Status = updateDto.Status;
        await _context.SaveChangesAsync();

        return await GetUserByIdAsync(userId) ?? throw new Exception("User not found");
    }

    public async Task<UserDto> CreateAdminAsync(CreateAdminDto createAdminDto)
    {
        // Kiểm tra email đã tồn tại
        var existingUser = await _context.Users
            .FirstOrDefaultAsync(u => u.Email == createAdminDto.Email);

        if (existingUser != null)
            throw new Exception("Email already exists");

        // Tạo ID user mới
        var lastUser = await _context.Users
            .OrderByDescending(u => u.UserId)
            .FirstOrDefaultAsync();

        int nextNumber = 1;
        if (lastUser != null && lastUser.UserId.Length > 2)
        {
            int.TryParse(lastUser.UserId.Substring(2), out nextNumber);
            nextNumber++;
        }
        var userId = "US" + nextNumber.ToString("D4");

        // Tạo admin
        var user = new User
        {
            UserId = userId,
            FullName = createAdminDto.FullName,
            Email = createAdminDto.Email,
            Phone = createAdminDto.Phone,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(createAdminDto.Password),
            Role = "admin",
            Status = "active",
            CreatedAt = DateTime.UtcNow
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        return new UserDto
        {
            UserId = user.UserId,
            FullName = user.FullName,
            Email = user.Email,
            Phone = user.Phone,
            Role = user.Role,
            Status = user.Status,
            CreatedAt = user.CreatedAt,
            OrderCount = 0,
            TotalSpent = 0
        };
    }
}