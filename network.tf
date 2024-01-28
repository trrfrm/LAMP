provider "aws" {
    region = var.default_region.region
}

resource "aws_vpc" "vnet" {
    cidr_block          = var.network_details.cidr_block
    tags                = {
        Name            = var.network_details.name
    }
}

resource "aws_subnet" "pub_subnets" {
    count                = local.count
    vpc_id               = aws_vpc.vnet.id
    cidr_block           = cidrsubnet(var.network_details.cidr_block, 8, count.index)
    availability_zone    = format("${var.default_region.region}%s", count.index%2==0?"a":"c")
    tags                 = {
        Name             = "${local.env_prefix}-subnet"
    }
    depends_on           = [ aws_vpc.vnet ]
}

resource "aws_internet_gateway" "igateway" {
    vpc_id               = aws_vpc.vnet.id
    tags                 = {
        Name             = "IGW"
    }
    depends_on           = [ aws_vpc.vnet, aws_subnet.pub_subnets ]
}

resource "aws_security_group" "Web-SG" {
    vpc_id               = aws_vpc.vnet.id
    description          = local.default_desc

    ingress {
        from_port        = local.ssh_port
        to_port          = local.ssh_port
        protocol         = local.protocol
        cidr_blocks      = [local.any_where]
    }
    ingress {
        from_port        = local.http_port
        to_port          = local.http_port
        protocol         = local.protocol
        cidr_blocks      = [local.any_where]
    }
    egress {
        from_port        = local.all_ports
        to_port          = local.all_ports
        protocol         = local.any_protocol
        cidr_blocks      = [local.any_where]
        ipv6_cidr_blocks = [local.any_where_ipv6]
    }
    tags                 = {
        Name             = "Web-Security"
    }
    depends_on           = [ aws_vpc.vnet ]
}

resource "aws_route_table" "public_rt" {
    vpc_id               = aws_vpc.vnet.id
    route {
        cidr_block       = local.any_where
        gateway_id       = aws_internet_gateway.igateway.id
    }
        tags             = {
        Name             = "Public-RT"
    }
    depends_on           = [ aws_internet_gateway.igateway ]
}

resource "aws_route_table" "private_rt" {
    vpc_id               = aws_vpc.vnet.id
    tags                 = {
        Name             = "Private-RT"
    }
    depends_on           = [ aws_internet_gateway.igateway ]
}

resource "aws_route_table_association" "a" {
    count               = local.count
    subnet_id           = aws_subnet.pub_subnets[count.index].id
    route_table_id      = count.index<2 ? aws_route_table.public_rt.id: aws_route_table.private_rt.id
                         #contains(var.public_routes, lookup(aws_subnet.pub_subnets[count.index].tags_all, "Name", "")) ? aws_route_table.public_rt.id: aws_route_table.private_rt.id

    depends_on          = [ aws_route_table.public_rt, aws_route_table.private_rt ]
}
