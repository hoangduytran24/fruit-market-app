using Microsoft.EntityFrameworkCore;
using fruit_api.Data;
using fruit_api.DTOs.Voucher;
using fruit_api.Models;
using fruit_api.Services.Interfaces;
using Microsoft.Extensions.Logging;

namespace fruit_api.Services;

public class VoucherService : IVoucherService
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<VoucherService> _logger;
    private static readonly Random _random = new();

    public VoucherService(ApplicationDbContext context, ILogger<VoucherService> logger)
    {
        _context = context;
        _logger = logger;
    }

    // ==================== ADMIN APIS ====================

    public async Task<IEnumerable<VoucherDto>> GetAllVouchersAsync()
    {
        try
        {
            return await _context.Vouchers
                .OrderByDescending(v => v.StartDate)
                .Select(v => new VoucherDto
                {
                    VoucherId = v.VoucherId,
                    VoucherCode = v.VoucherCode,
                    DiscountType = v.DiscountType,
                    DiscountValue = v.DiscountValue,
                    MinOrderValue = v.MinOrderValue,
                    MaxDiscountValue = v.MaxDiscountValue,
                    Quantity = v.Quantity,
                    UsedQuantity = v.UsedQuantity,
                    StartDate = v.StartDate,
                    EndDate = v.EndDate,
                    Status = v.Status,
                    IsValid = v.Status == "active" &&
                             v.Quantity > v.UsedQuantity &&
                             (v.StartDate == null || v.StartDate <= DateTime.Now) &&
                             (v.EndDate == null || v.EndDate >= DateTime.Now)
                })
                .ToListAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting all vouchers");
            throw;
        }
    }

    public async Task<VoucherDto?> GetVoucherByIdAsync(string id)
    {
        try
        {
            var voucher = await _context.Vouchers.FindAsync(id);
            if (voucher == null)
                return null;

            return MapToDto(voucher);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting voucher by ID: {VoucherId}", id);
            throw;
        }
    }

    public async Task<VoucherDto> CreateVoucherAsync(CreateVoucherDto createDto)
    {
        try
        {
            _logger.LogInformation("Creating new voucher: {VoucherCode}", createDto.VoucherCode);

            var existing = await _context.Vouchers
                .FirstOrDefaultAsync(v => v.VoucherCode == createDto.VoucherCode);

            if (existing != null)
                throw new Exception("Mã voucher đã tồn tại");

            if (createDto.DiscountType.ToLower() != "percent" &&
                createDto.DiscountType.ToLower() != "percentage" &&
                createDto.DiscountType.ToLower() != "fixed")
            {
                throw new Exception("Loại giảm giá phải là 'percent' hoặc 'fixed'");
            }

            if (createDto.DiscountValue <= 0)
                throw new Exception("Giá trị giảm phải lớn hơn 0");

            if (createDto.DiscountType.ToLower() == "percent" && createDto.DiscountValue > 100)
                throw new Exception("Giảm phần trăm không thể vượt quá 100%");

            string voucherId = await GenerateVoucherId();

            var voucher = new Voucher
            {
                VoucherId = voucherId,
                VoucherCode = createDto.VoucherCode.ToUpper().Trim(),
                DiscountType = createDto.DiscountType.ToLower(),
                DiscountValue = createDto.DiscountValue,
                MinOrderValue = createDto.MinOrderValue,
                MaxDiscountValue = createDto.MaxDiscountValue,
                Quantity = createDto.Quantity,
                UsedQuantity = 0,
                StartDate = createDto.StartDate,
                EndDate = createDto.EndDate,
                Status = "active"
            };

            _context.Vouchers.Add(voucher);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Voucher created: {VoucherCode} - ID: {VoucherId}", voucher.VoucherCode, voucher.VoucherId);
            return MapToDto(voucher);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating voucher");
            throw;
        }
    }

    public async Task<VoucherDto> UpdateVoucherAsync(string id, UpdateVoucherDto updateDto)
    {
        try
        {
            _logger.LogInformation("Updating voucher: {VoucherId}", id);

            var voucher = await _context.Vouchers.FindAsync(id);
            if (voucher == null)
                throw new Exception("Không tìm thấy voucher");

            if (voucher.VoucherCode != updateDto.VoucherCode)
            {
                var existing = await _context.Vouchers
                    .FirstOrDefaultAsync(v => v.VoucherCode == updateDto.VoucherCode);
                if (existing != null)
                    throw new Exception("Mã voucher đã tồn tại");
            }

            if (updateDto.DiscountType.ToLower() != "percent" &&
                updateDto.DiscountType.ToLower() != "percentage" &&
                updateDto.DiscountType.ToLower() != "fixed")
            {
                throw new Exception("Loại giảm giá phải là 'percent' hoặc 'fixed'");
            }

            if (updateDto.DiscountValue <= 0)
                throw new Exception("Giá trị giảm phải lớn hơn 0");

            if (updateDto.DiscountType.ToLower() == "percent" && updateDto.DiscountValue > 100)
                throw new Exception("Giảm phần trăm không thể vượt quá 100%");

            voucher.VoucherCode = updateDto.VoucherCode.ToUpper().Trim();
            voucher.DiscountType = updateDto.DiscountType.ToLower();
            voucher.DiscountValue = updateDto.DiscountValue;
            voucher.MinOrderValue = updateDto.MinOrderValue;
            voucher.MaxDiscountValue = updateDto.MaxDiscountValue;
            voucher.Quantity = updateDto.Quantity;
            voucher.StartDate = updateDto.StartDate;
            voucher.EndDate = updateDto.EndDate;
            voucher.Status = updateDto.Status;

            await _context.SaveChangesAsync();

            _logger.LogInformation("Voucher updated: {VoucherId}", id);
            return MapToDto(voucher);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating voucher: {VoucherId}", id);
            throw;
        }
    }

    public async Task<bool> DeleteVoucherAsync(string id)
    {
        try
        {
            _logger.LogInformation("Deleting voucher: {VoucherId}", id);

            var voucher = await _context.Vouchers.FindAsync(id);
            if (voucher == null)
                return false;

            _context.Vouchers.Remove(voucher);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Voucher deleted: {VoucherId}", id);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting voucher: {VoucherId}", id);
            throw;
        }
    }

    public async Task<bool> ToggleVoucherStatusAsync(string id)
    {
        try
        {
            _logger.LogInformation("Toggling voucher status: {VoucherId}", id);

            var voucher = await _context.Vouchers.FindAsync(id);
            if (voucher == null)
                return false;

            voucher.Status = voucher.Status == "active" ? "inactive" : "active";
            await _context.SaveChangesAsync();

            _logger.LogInformation("Voucher status toggled: {VoucherId} - New status: {Status}",
                id, voucher.Status);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error toggling voucher status: {VoucherId}", id);
            throw;
        }
    }

    // ==================== USER APIS ====================

    public async Task<IEnumerable<VoucherPublicDto>> GetAvailableVouchersAsync()
    {
        try
        {
            var now = DateTime.Now;

            var vouchers = await _context.Vouchers
                .Where(v => v.Status == "active" &&
                           v.Quantity > v.UsedQuantity &&
                           (v.StartDate == null || v.StartDate <= now) &&
                           (v.EndDate == null || v.EndDate >= now))
                .OrderByDescending(v => v.DiscountValue)
                .Select(v => new
                {
                    v.VoucherId,
                    v.VoucherCode,
                    v.DiscountType,
                    v.DiscountValue,
                    v.MinOrderValue,
                    v.MaxDiscountValue,
                    v.StartDate,
                    v.EndDate,
                    v.Quantity,
                    v.UsedQuantity
                })
                .ToListAsync();

            var result = vouchers.Select(v => new VoucherPublicDto
            {
                VoucherId = v.VoucherId,
                VoucherCode = v.VoucherCode,
                DiscountType = v.DiscountType,
                DiscountValue = v.DiscountValue,
                MinOrderValue = v.MinOrderValue,
                MaxDiscountValue = v.MaxDiscountValue,
                StartDate = v.StartDate,
                EndDate = v.EndDate,
                Description = GetVoucherDescription(v.DiscountType, v.DiscountValue, v.MinOrderValue, v.MaxDiscountValue),
                RemainingCount = v.Quantity - v.UsedQuantity
            });

            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting available vouchers");
            throw;
        }
    }

    public async Task<VoucherResultDto> ApplyVoucherAsync(ApplyVoucherDto applyDto)
    {
        try
        {
            var voucher = await _context.Vouchers
                .FirstOrDefaultAsync(v => v.VoucherCode == applyDto.VoucherCode.ToUpper().Trim());

            if (voucher == null)
            {
                return new VoucherResultDto
                {
                    IsValid = false,
                    Message = "Mã voucher không tồn tại",
                    DiscountAmount = 0,
                    FinalAmount = applyDto.OrderTotal
                };
            }

            if (voucher.Status != "active")
            {
                return new VoucherResultDto
                {
                    IsValid = false,
                    Message = "Voucher không khả dụng",
                    DiscountAmount = 0,
                    FinalAmount = applyDto.OrderTotal
                };
            }

            if (voucher.UsedQuantity >= voucher.Quantity)
            {
                return new VoucherResultDto
                {
                    IsValid = false,
                    Message = "Voucher đã hết lượt sử dụng",
                    DiscountAmount = 0,
                    FinalAmount = applyDto.OrderTotal
                };
            }

            var now = DateTime.Now;
            if (voucher.StartDate.HasValue && voucher.StartDate > now)
            {
                return new VoucherResultDto
                {
                    IsValid = false,
                    Message = $"Voucher có hiệu lực từ {voucher.StartDate:dd/MM/yyyy}",
                    DiscountAmount = 0,
                    FinalAmount = applyDto.OrderTotal
                };
            }

            if (voucher.EndDate.HasValue && voucher.EndDate < now)
            {
                return new VoucherResultDto
                {
                    IsValid = false,
                    Message = "Voucher đã hết hạn",
                    DiscountAmount = 0,
                    FinalAmount = applyDto.OrderTotal
                };
            }

            if (applyDto.OrderTotal < voucher.MinOrderValue)
            {
                return new VoucherResultDto
                {
                    IsValid = false,
                    Message = $"Đơn hàng tối thiểu {voucher.MinOrderValue:N0}đ để sử dụng voucher này",
                    DiscountAmount = 0,
                    FinalAmount = applyDto.OrderTotal
                };
            }

            decimal discountAmount = 0;
            if (voucher.DiscountType.ToLower() == "percent" || voucher.DiscountType.ToLower() == "percentage")
            {
                discountAmount = applyDto.OrderTotal * voucher.DiscountValue / 100;
                if (voucher.MaxDiscountValue.HasValue && discountAmount > voucher.MaxDiscountValue)
                {
                    discountAmount = voucher.MaxDiscountValue.Value;
                }
            }
            else
            {
                discountAmount = voucher.DiscountValue;
            }

            var finalAmount = applyDto.OrderTotal - discountAmount;
            if (finalAmount < 0) finalAmount = 0;

            return new VoucherResultDto
            {
                IsValid = true,
                Message = "Áp dụng voucher thành công",
                DiscountAmount = discountAmount,
                FinalAmount = finalAmount,
                Voucher = new VoucherPublicDto
                {
                    VoucherId = voucher.VoucherId,
                    VoucherCode = voucher.VoucherCode,
                    DiscountType = voucher.DiscountType,
                    DiscountValue = voucher.DiscountValue,
                    MinOrderValue = voucher.MinOrderValue,
                    MaxDiscountValue = voucher.MaxDiscountValue,
                    Description = GetVoucherDescription(voucher.DiscountType, voucher.DiscountValue, voucher.MinOrderValue, voucher.MaxDiscountValue)
                }
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error applying voucher: {VoucherCode}", applyDto.VoucherCode);
            throw;
        }
    }

    // ==================== USER VOUCHER APIS ====================

    public async Task<bool> SaveVoucherForUserAsync(string userId, string voucherCode)
    {
        try
        {
            _logger.LogInformation("Saving voucher for user {UserId}, code {VoucherCode}", userId, voucherCode);

            var voucher = await _context.Vouchers
                .FirstOrDefaultAsync(v => v.VoucherCode == voucherCode.ToUpper().Trim());

            if (voucher == null)
                throw new Exception("Voucher không tồn tại");

            var now = DateTime.Now;
            if (voucher.Status != "active" ||
                voucher.UsedQuantity >= voucher.Quantity ||
                (voucher.StartDate.HasValue && voucher.StartDate > now) ||
                (voucher.EndDate.HasValue && voucher.EndDate < now))
            {
                throw new Exception("Voucher không khả dụng để lưu");
            }

            var existing = await _context.UserVouchers
                .FirstOrDefaultAsync(uv => uv.UserId == userId && uv.VoucherId == voucher.VoucherId);

            if (existing != null)
            {
                if (existing.IsUsed)
                    throw new Exception("Bạn đã sử dụng voucher này rồi");
                else
                    throw new Exception("Bạn đã lưu voucher này rồi");
            }

            string userVoucherId = await GenerateUserVoucherId();

            var userVoucher = new UserVoucher
            {
                UserVoucherId = userVoucherId,
                UserId = userId,
                VoucherId = voucher.VoucherId,
                SavedAt = DateTime.Now,
                IsUsed = false
            };

            _context.UserVouchers.Add(userVoucher);
            await _context.SaveChangesAsync();

            _logger.LogInformation("User {UserId} saved voucher {VoucherCode} successfully", userId, voucherCode);
            return true;
        }
        catch (DbUpdateException dbEx)
        {
            _logger.LogError(dbEx, "DbUpdateException when saving voucher");

            if (dbEx.InnerException != null)
            {
                var innerMsg = dbEx.InnerException.Message;
                _logger.LogError("Inner exception: {Message}", innerMsg);

                if (innerMsg.Contains("FOREIGN KEY") || innerMsg.Contains("REFERENCE"))
                    throw new Exception("Lỗi: User hoặc Voucher không hợp lệ");
                else if (innerMsg.Contains("UNIQUE"))
                    throw new Exception("Bạn đã lưu voucher này rồi");
            }
            throw new Exception($"Lỗi database: {dbEx.InnerException?.Message ?? dbEx.Message}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving voucher for user {UserId}", userId);
            throw;
        }
    }

    public async Task<IEnumerable<UserVoucherDto>> GetUserSavedVouchersAsync(string userId)
    {
        try
        {
            var userVouchers = await _context.UserVouchers
                .Include(uv => uv.Voucher)
                .Where(uv => uv.UserId == userId && !uv.IsUsed)
                .OrderByDescending(uv => uv.SavedAt)
                .Select(uv => new
                {
                    uv.UserVoucherId,
                    uv.UserId,
                    uv.VoucherId,
                    uv.SavedAt,
                    uv.UsedAt,
                    uv.IsUsed,
                    Voucher = uv.Voucher != null ? new
                    {
                        uv.Voucher.VoucherId,
                        uv.Voucher.VoucherCode,
                        uv.Voucher.DiscountType,
                        uv.Voucher.DiscountValue,
                        uv.Voucher.MinOrderValue,
                        uv.Voucher.MaxDiscountValue,
                        uv.Voucher.StartDate,
                        uv.Voucher.EndDate,
                        uv.Voucher.Quantity,
                        uv.Voucher.UsedQuantity
                    } : null
                })
                .ToListAsync();

            var result = userVouchers.Select(uv => new UserVoucherDto
            {
                UserVoucherId = uv.UserVoucherId,
                UserId = uv.UserId,
                VoucherId = uv.VoucherId,
                SavedAt = uv.SavedAt,
                UsedAt = uv.UsedAt,
                IsUsed = uv.IsUsed,
                Voucher = uv.Voucher != null ? new VoucherPublicDto
                {
                    VoucherId = uv.Voucher.VoucherId,
                    VoucherCode = uv.Voucher.VoucherCode,
                    DiscountType = uv.Voucher.DiscountType,
                    DiscountValue = uv.Voucher.DiscountValue,
                    MinOrderValue = uv.Voucher.MinOrderValue,
                    MaxDiscountValue = uv.Voucher.MaxDiscountValue,
                    StartDate = uv.Voucher.StartDate,
                    EndDate = uv.Voucher.EndDate,
                    Description = GetVoucherDescription(
                        uv.Voucher.DiscountType,
                        uv.Voucher.DiscountValue,
                        uv.Voucher.MinOrderValue,
                        uv.Voucher.MaxDiscountValue),
                    RemainingCount = uv.Voucher.Quantity - uv.Voucher.UsedQuantity
                } : null
            });

            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting saved vouchers for user {UserId}", userId);
            throw;
        }
    }

    public async Task<bool> UseSavedVoucherAsync(string userId, string userVoucherId)
    {
        try
        {
            _logger.LogInformation("Using saved voucher for user {UserId}, userVoucherId {UserVoucherId}", userId, userVoucherId);

            var userVoucher = await _context.UserVouchers
                .Include(uv => uv.Voucher)
                .FirstOrDefaultAsync(uv => uv.UserVoucherId == userVoucherId && uv.UserId == userId);

            if (userVoucher == null)
                throw new Exception("Không tìm thấy voucher đã lưu");

            if (userVoucher.IsUsed)
                throw new Exception("Voucher đã được sử dụng");

            var now = DateTime.Now;
            var voucher = userVoucher.Voucher;

            if (voucher == null)
                throw new Exception("Voucher không tồn tại");

            if (voucher.Status != "active")
                throw new Exception("Voucher không khả dụng");

            if (voucher.UsedQuantity >= voucher.Quantity)
                throw new Exception("Voucher đã hết lượt sử dụng");

            if (voucher.StartDate.HasValue && voucher.StartDate > now)
                throw new Exception($"Voucher có hiệu lực từ {voucher.StartDate:dd/MM/yyyy}");

            if (voucher.EndDate.HasValue && voucher.EndDate < now)
                throw new Exception("Voucher đã hết hạn");

            userVoucher.IsUsed = true;
            userVoucher.UsedAt = now;

            // ========== THÊM CODE NÀY ==========
            // Tăng số lượt đã dùng của voucher
            voucher.UsedQuantity++;
            // ================================

            await _context.SaveChangesAsync();

            _logger.LogInformation("User {UserId} used voucher {UserVoucherId} successfully", userId, userVoucherId);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error using saved voucher for user {UserId}", userId);
            throw;
        }
    }

    // ==================== ID GENERATORS ====================

    private async Task<string> GenerateVoucherId()
    {
        string voucherId;
        bool exists;
        int attempt = 0;
        const int maxAttempts = 10;

        do
        {
            var randomNumber = _random.Next(1000000000, 1999999999).ToString().Substring(1);
            voucherId = "VC" + randomNumber;
            exists = await _context.Vouchers.AnyAsync(v => v.VoucherId == voucherId);
            attempt++;

            if (attempt >= maxAttempts)
                throw new Exception("Không thể tạo ID voucher duy nhất");

        } while (exists);

        return voucherId;
    }

    private async Task<string> GenerateUserVoucherId()
    {
        string userVoucherId;
        bool exists;
        int attempt = 0;
        const int maxAttempts = 10;

        do
        {
            var randomNumber = _random.Next(1000000000, 1999999999).ToString().Substring(1);
            userVoucherId = "UV" + randomNumber;
            exists = await _context.UserVouchers.AnyAsync(uv => uv.UserVoucherId == userVoucherId);
            attempt++;

            if (attempt >= maxAttempts)
                throw new Exception("Không thể tạo ID user voucher duy nhất");

        } while (exists);

        return userVoucherId;
    }

    // ==================== HELPER METHODS ====================

    private VoucherDto MapToDto(Voucher voucher)
    {
        return new VoucherDto
        {
            VoucherId = voucher.VoucherId,
            VoucherCode = voucher.VoucherCode,
            DiscountType = voucher.DiscountType,
            DiscountValue = voucher.DiscountValue,
            MinOrderValue = voucher.MinOrderValue,
            MaxDiscountValue = voucher.MaxDiscountValue,
            Quantity = voucher.Quantity,
            UsedQuantity = voucher.UsedQuantity,
            StartDate = voucher.StartDate,
            EndDate = voucher.EndDate,
            Status = voucher.Status,
            IsValid = voucher.Status == "active" &&
                     voucher.Quantity > voucher.UsedQuantity &&
                     (voucher.StartDate == null || voucher.StartDate <= DateTime.Now) &&
                     (voucher.EndDate == null || voucher.EndDate >= DateTime.Now)
        };
    }

    private static string GetVoucherDescription(string discountType, decimal discountValue, decimal minOrderValue, decimal? maxDiscountValue)
    {
        if (discountType.ToLower() == "percent" || discountType.ToLower() == "percentage")
        {
            var desc = $"Giảm {discountValue}%";
            if (maxDiscountValue.HasValue && maxDiscountValue > 0)
                desc += $" (tối đa {maxDiscountValue:N0}đ)";
            if (minOrderValue > 0)
                desc += $" cho đơn từ {minOrderValue:N0}đ";
            return desc;
        }
        else if (discountType.ToLower() == "fixed")
        {
            var desc = $"Giảm {discountValue:N0}đ";
            if (minOrderValue > 0)
                desc += $" cho đơn từ {minOrderValue:N0}đ";
            return desc;
        }

        return discountType;
    }
}