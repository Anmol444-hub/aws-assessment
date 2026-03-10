resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.labels.tags, { Name = "${var.labels.id}-vpc" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.labels.tags, { Name = "${var.labels.id}-igw" })
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.labels.tags, {
    Name = "${var.labels.id}-public-${count.index + 1}"
    Tier = "public"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.labels.tags, { Name = "${var.labels.id}-public-rt" })
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security group for ECS Fargate tasks — egress-only (needs outbound for SNS + ECR pull)
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.labels.id}-ecs-tasks-sg"
  description = "Egress-only SG for ECS Fargate publisher tasks"
  vpc_id      = aws_vpc.this.id

  egress {
    description = "Allow all outbound (SNS publish, ECR image pull)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.labels.tags, { Name = "${var.labels.id}-ecs-tasks-sg" })
}
