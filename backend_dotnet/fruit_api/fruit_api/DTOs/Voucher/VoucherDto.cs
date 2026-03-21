namespace fruit_api.DTOs.Voucher;

public class VoucherDto
{
    public string VoucherId { get; set; } = string.Empty;
    public string VoucherCode { get; set; } = string.Empty;
    public string DiscountType { get; set; } = string.Empty;
    public decimal DiscountValue { get; set; }
    public decimal MinOrderValue { get; set; }
    public decimal? MaxDiscountValue { get; set; }
    public int Quantity { get; set; }
    public int UsedQuantity { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public string Status { get; set; } = string.Empty;
    public bool IsValid { get; set; }
}

public class CreateVoucherDto
{
    public string VoucherCode { get; set; } = string.Empty;
    public string DiscountType { get; set; } = string.Empty;
    public decimal DiscountValue { get; set; }
    public decimal MinOrderValue { get; set; } = 0;
    public decimal? MaxDiscountValue { get; set; }
    public int Quantity { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
}

public class ApplyVoucherDto
{
    public string VoucherCode { get; set; } = string.Empty;
    public decimal OrderTotal { get; set; }
}

public class VoucherResultDto
{
    public bool IsValid { get; set; }
    public string? Message { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal FinalAmount { get; set; }
    public VoucherPublicDto? Voucher { get; set; }  // SỬA: VoucherPublicDto thay vì VoucherDto
}

public class UpdateVoucherDto
{
    public string VoucherCode { get; set; } = string.Empty;
    public string DiscountType { get; set; } = string.Empty;
    public decimal DiscountValue { get; set; }
    public decimal MinOrderValue { get; set; }
    public decimal? MaxDiscountValue { get; set; }
    public int Quantity { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public string Status { get; set; } = string.Empty;
}

public class VoucherPublicDto
{
    public string VoucherId { get; set; } = string.Empty;
    public string VoucherCode { get; set; } = string.Empty;
    public string DiscountType { get; set; } = string.Empty;
    public decimal DiscountValue { get; set; }
    public decimal MinOrderValue { get; set; }
    public decimal? MaxDiscountValue { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public string? Description { get; set; }
    public int? RemainingCount { get; set; }
}

// THÊM CÁC DTO NÀY CHO USERVOUCHER
public class UserVoucherDto
{
    public string UserVoucherId { get; set; } = string.Empty;
    public string UserId { get; set; } = string.Empty;
    public string VoucherId { get; set; } = string.Empty;
    public VoucherPublicDto? Voucher { get; set; }
    public DateTime SavedAt { get; set; }
    public DateTime? UsedAt { get; set; }
    public bool IsUsed { get; set; }
}

public class SaveUserVoucherDto
{
    public string VoucherCode { get; set; } = string.Empty;
}