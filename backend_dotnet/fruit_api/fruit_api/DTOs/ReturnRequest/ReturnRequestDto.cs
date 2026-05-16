using System;
using Microsoft.AspNetCore.Http;

namespace fruit_api.DTOs;

public class CreateReturnRequestDto
{
    public string OrderId { get; set; } = string.Empty;
    public string Reason { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public IFormFile? ImageFile { get; set; }
}

public class ProcessReturnRequestDto
{
    public string ReturnId { get; set; } = string.Empty;
    public bool IsApproved { get; set; }
    public string? RejectReason { get; set; }
}

public class ReturnRequestResponseDto
{
    public string ReturnId { get; set; } = string.Empty;
    public string OrderId { get; set; } = string.Empty;
    public string UserId { get; set; } = string.Empty;
    public string Reason { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public string Status { get; set; } = string.Empty;
    public decimal RefundAmount { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? ApprovedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
    public DateTime? RejectedAt { get; set; }
    public string? RejectReason { get; set; }
    public string StatusText { get; set; } = string.Empty;
}