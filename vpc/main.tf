#Create VPC
resource "aws_vpc" "main_vpc" {
  #cidr_block = var.cidr #range of ip for vpc
  cidr_block = "192.168.0.0/16"
  enable_dns_hostnames = true   # Enabling automatic hostname assigning
   tags = {
    Name = "${var.name}-${var.environment}"
  }
}

#Public subnet
resource "aws_subnet" "public_subnet" {
    depends_on = [
      aws_vpc.main_vpc
    ]
        vpc_id = aws_vpc.main_vpc.id
        #cidr_block = element(var.public_subnets, count.index)
        cidr_block = "192.168.0.0/24"  # IP Range of this subnet
        map_public_ip_on_launch = true
        #count = length(var.public_subnets)

    tags = {
    Name        = "${var.name}-${var.environment}-public"
  }
}


#Private subnet
resource "aws_subnet" "private_subnet" {
    depends_on = [
      aws_vpc.main_vpc,
      aws_subnet.public_subnet
    ]

    vpc_id = aws_vpc.main_vpc.id
    #cidr_block        = element(var.private_subnets, count.index)  
    cidr_block = "192.168.1.0/24"  # IP Range of this subnet
    #count             = length(var.private_subnets)
   tags = {
    Name        = "${var.name}-${var.environment}-private"
  }
}


#Internet Gateway
resource "aws_internet_gateway" "main_igw" {
    depends_on = [
    aws_vpc.main_vpc,
    aws_subnet.public_subnet,
    aws_subnet.private_subnet
  ]
  vpc_id = aws_vpc.main_vpc.id
    tags = {
    Name = "IG-Public-&-Private-VPC"
  }
}

#Route table for internet gateway /public 
resource "aws_route_table" "public_rt_table" {
  depends_on = [
    aws_vpc.main_vpc,
    aws_internet_gateway.main_igw
  ]

  vpc_id = aws_vpc.main_vpc.id

    route { #NAT rule
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.main_igw.id
  }
    tags = {
    Name = "Route Table for Internet Gateway"
  }
}

# Route Table Association!
resource "aws_route_table_association" "rt_asso_public" {
    depends_on = [
    aws_vpc.main_vpc,
    aws_subnet.public_subnet,
    aws_subnet.private_subnet,
    aws_route_table.public_rt_table
  ]
  
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt_table.id
}


# Creating an Elastic IP for the NAT Gateway!
resource "aws_eip" "Nat-Gateway-EIP" {
  depends_on = [
    aws_route_table_association.rt_asso_public
  ]
  vpc = true
}

#NAT GW
resource "aws_nat_gateway" "nat_gw" {
  depends_on = [
    aws_eip.Nat-Gateway-EIP
  ]
   # Allocating the Elastic IP to the NAT Gateway!
  allocation_id = aws_eip.Nat-Gateway-EIP.id
  
  # Associating it in the Public Subnet!
  subnet_id = aws_subnet.public_subnet.id
  tags = {
    Name = "Nat-Gateway_Project"
  }
}
 

# Creating a Route Table for the Nat Gateway!
resource "aws_route_table" "NAT-Gateway-RT" {
  depends_on = [
    aws_nat_gateway.nat_gw
  ]

  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "Route Table for NAT Gateway"
  }

}

# Creating an Route Table Association of the NAT Gateway route 
# table with the Private Subnet!
resource "aws_route_table_association" "Nat-Gateway-RT-Association" {
  depends_on = [
    aws_route_table.NAT-Gateway-RT
  ]

#  Private Subnet ID for adding this route table to the DHCP server of Private subnet!
  subnet_id      = aws_subnet.private_subnet.id

# Route Table ID
  route_table_id = aws_route_table.NAT-Gateway-RT.id
}

output "id" {
  value = aws_vpc.main_vpc.id
}

output "public_subnets" {
  value = aws_subnet.public_subnet
}

output "private_subnets" {
  value = aws_subnet.private_subnet
}