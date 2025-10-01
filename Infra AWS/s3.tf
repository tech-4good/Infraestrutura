resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "raw" {
  bucket = "analise-dados-raw-${random_id.suffix.hex}"
  tags = { Name = "Raw" }
}
resource "aws_s3_bucket" "trusted" {
  bucket = "analise-dados-trusted-${random_id.suffix.hex}"
  tags = { Name = "Trusted" }
}
resource "aws_s3_bucket" "curated" {
  bucket = "analise-dados-curated-${random_id.suffix.hex}"
  tags = { Name = "Curated" }
}

resource "aws_s3_bucket_public_access_block" "bloco_acesso_publico_s3" {
  bucket = aws_s3_bucket.curated.id

  block_public_acls       = false
  block_public_policy     = false 
  ignore_public_acls      = false 
  restrict_public_buckets = false  
}

resource "aws_s3_bucket_policy" "politica_acesso_publico_bucket" {
  bucket = aws_s3_bucket.curated.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["s3:GetObject"]
        Principal = "*"
        Effect = "Allow"
        Resource = "${aws_s3_bucket.curated.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.bloco_acesso_publico_s3]
}