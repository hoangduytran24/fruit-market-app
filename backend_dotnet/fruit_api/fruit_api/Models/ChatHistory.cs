using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace fruit_api.Models
{
    [Table("ChatHistory")]
    public class ChatHistory
    {
        [Key]
        [Column("chatId")]
        public string ChatId { get; set; } = "CH" + Guid.NewGuid().ToString("N").Substring(0, 8).ToUpper();

        [Required]
        [Column("userId")]
        public string UserId { get; set; }

        [Required]
        [Column("sessionId")]
        public string SessionId { get; set; }

        [Required]
        [Column("userMessage")]
        public string UserMessage { get; set; }

        [Required]
        [Column("aiResponse")]
        public string AiResponse { get; set; }

        [Column("intent")]
        public string? Intent { get; set; }

        [Column("isResolved")]
        public bool IsResolved { get; set; } = false;

        [Column("responseTimeMs")]
        public int? ResponseTimeMs { get; set; }

        [Column("tokensUsed")]
        public int? TokensUsed { get; set; }

        [Column("metadata")]
        public string? Metadata { get; set; }

        [Column("createdAt")]
        public DateTime CreatedAt { get; set; } = DateTime.Now;
    }
}