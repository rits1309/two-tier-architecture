output "website_arn" {
    description = "value"
    value = aws_instance.website
  
}
output "vpc_id" {
    value =aws_vpc.myvpc  
}
output "public_subnet1_az1" {
  value = aws_subnet.pub-sub1.id
}

output "public_subnet1_az2" {
  value = aws_subnet.pub-sub2
}

output "private_subnet1_az1" {
  value = aws_subnet.pr-sub1
}

output "private_subnet1_az2" {
  value = aws_subnet.pr-sub2
}

output "internet_gateway" {
  value = aws_internet_gateway.int-gateway
}

output "subnet_ids" {
  value = [aws_subnet.pub-sub1.id, aws_subnet.pub-sub2.id]
}
