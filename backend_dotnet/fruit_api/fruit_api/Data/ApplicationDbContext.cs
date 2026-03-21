using Microsoft.EntityFrameworkCore;
using fruit_api.Models;

namespace fruit_api.Data;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users { get; set; }
    public DbSet<Category> Categories { get; set; }
    public DbSet<Supplier> Suppliers { get; set; }
    public DbSet<Product> Products { get; set; }
    public DbSet<Cart> Carts { get; set; }
    public DbSet<CartItem> CartItems { get; set; }
    public DbSet<Order> Orders { get; set; }
    public DbSet<OrderItem> OrderItems { get; set; }
    public DbSet<Payment> Payments { get; set; }
    public DbSet<Voucher> Vouchers { get; set; }
    public DbSet<OrderVoucher> OrderVouchers { get; set; }
    public DbSet<Review> Reviews { get; set; }
    public DbSet<Favorite> Favorites { get; set; }
    public DbSet<UserVoucher> UserVouchers { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // ==================== FIX TRIGGER (QUAN TRỌNG) ====================
        modelBuilder.Entity<Order>()
            .ToTable(tb =>
            {
                tb.HasTrigger("trg_RestoreStock_WhenOrderCancelled");
            });

        modelBuilder.Entity<OrderItem>()
            .ToTable(tb =>
            {
                tb.HasTrigger("trg_UpdateStock_WhenInsertOrderItem");
                tb.HasTrigger("trg_UpdateOrderTotal");
            });

        // ==================== UNIQUE CONSTRAINTS ====================

        modelBuilder.Entity<User>()
            .HasIndex(u => u.Phone)
            .IsUnique()
            .HasFilter("[phone] IS NOT NULL");

        modelBuilder.Entity<User>()
            .HasIndex(u => u.Email)
            .IsUnique()
            .HasFilter("[email] IS NOT NULL");

        modelBuilder.Entity<Cart>()
            .HasIndex(c => c.UserId)
            .IsUnique();

        modelBuilder.Entity<CartItem>()
            .HasIndex(ci => new { ci.CartId, ci.ProductId })
            .IsUnique();

        modelBuilder.Entity<Review>()
            .HasIndex(r => new { r.UserId, r.ProductId })
            .IsUnique();

        modelBuilder.Entity<Favorite>()
            .HasIndex(f => new { f.UserId, f.ProductId })
            .IsUnique();

        modelBuilder.Entity<Voucher>()
            .HasIndex(v => v.VoucherCode)
            .IsUnique();

        modelBuilder.Entity<OrderVoucher>()
            .HasIndex(ov => ov.OrderId)
            .IsUnique();

        modelBuilder.Entity<Payment>()
            .HasIndex(p => p.OrderId)
            .IsUnique();

        // ==================== USERVOUCHER ====================

        modelBuilder.Entity<UserVoucher>()
            .HasIndex(uv => new { uv.UserId, uv.VoucherId })
            .IsUnique();

        modelBuilder.Entity<UserVoucher>().HasIndex(uv => uv.UserId);
        modelBuilder.Entity<UserVoucher>().HasIndex(uv => uv.VoucherId);
        modelBuilder.Entity<UserVoucher>().HasIndex(uv => uv.IsUsed);

        // ==================== RELATIONSHIPS ====================

        modelBuilder.Entity<User>()
            .HasOne(u => u.Cart)
            .WithOne(c => c.User)
            .HasForeignKey<Cart>(c => c.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Cart>()
            .HasMany(c => c.CartItems)
            .WithOne(ci => ci.Cart)
            .HasForeignKey(ci => ci.CartId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Order>()
            .HasMany(o => o.OrderItems)
            .WithOne(oi => oi.Order)
            .HasForeignKey(oi => oi.OrderId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Order>()
            .HasOne(o => o.Payment)
            .WithOne(p => p.Order)
            .HasForeignKey<Payment>(p => p.OrderId);

        modelBuilder.Entity<Order>()
            .HasOne(o => o.OrderVoucher)
            .WithOne(ov => ov.Order)
            .HasForeignKey<OrderVoucher>(ov => ov.OrderId);

        modelBuilder.Entity<Product>()
            .HasOne(p => p.Category)
            .WithMany(c => c.Products)
            .HasForeignKey(p => p.CategoryId);

        modelBuilder.Entity<Product>()
            .HasOne(p => p.Supplier)
            .WithMany(s => s.Products)
            .HasForeignKey(p => p.SupplierId);

        modelBuilder.Entity<User>()
            .HasMany(u => u.UserVouchers)
            .WithOne(uv => uv.User)
            .HasForeignKey(uv => uv.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Voucher>()
            .HasMany(v => v.UserVouchers)
            .WithOne(uv => uv.Voucher)
            .HasForeignKey(uv => uv.VoucherId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}