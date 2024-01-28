# output "subnet_tests" {
#     value = aws_subnet.pub_subnets
# }

output "subnet_count" {
    value = length(aws_subnet.pub_subnets)
}

output "Web_ips" {
    value = flatten(concat(aws_instance.WebServer.*.public_ip[*]))
}

output "php_homepage" {
    value = [ join(",", [for ip in aws_instance.WebServer.*.public_ip: "http://${ip}:80/info.php\n"]) ]
}
