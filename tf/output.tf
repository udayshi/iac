output "s3_bucket_id" {
  description = "ID of the usweb S3 bucket."
  value       = aws_s3_bucket.usweb.id
}

output "vpc_id" {
  description = "ID of the us-vpc VPC."
  value       = aws_vpc.us_vpc.id
}

output "internet_gateway_id" {
  description = "ID of the VPC internet gateway."
  value       = aws_internet_gateway.us_vpc.id
}

output "public_route_table_id" {
  description = "ID of the public route table."
  value       = aws_route_table.public.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets, keyed by subnet name."
  value = {
    for name, subnet in aws_subnet.public : name => subnet.id
  }
}

output "public_subnet_cidr_blocks" {
  description = "CIDR blocks of the public subnets, keyed by subnet name."
  value = {
    for name, subnet in aws_subnet.public : name => subnet.cidr_block
  }
}
