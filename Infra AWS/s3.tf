resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "raw" {
  bucket = "costexplorer-raw-${random_id.suffix.hex}"
  tags = { Name = "Raw" }
}
resource "aws_s3_bucket" "trusted" {
  bucket = "costexplorer-trusted-${random_id.suffix.hex}"
  tags = { Name = "Trusted" }
}
resource "aws_s3_bucket" "curated" {
  bucket = "costexplorer-curated-${random_id.suffix.hex}"
  tags = { Name = "Curated" }
}