data "aws_ami" "ubuntu" {
    most_recent = true

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"]
}

// Search for eip by allocation_id
// If found data.aws_eip.graphstore_eip.public_ip will be the public ip.
data "aws_eip" "graphstore_eip" {
  id = var.eip_alloc_id
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.graphstore_server.id
  allocation_id = data.aws_eip.graphstore_eip.id
}

resource "aws_instance" "graphstore_server" {
  // This ami works for use-east-1 "ami-0dd76f917833aac4b"   
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.graphstore_sg.id]
  subnet_id              = aws_subnet.graphstore_app_stack_public_subnet.id
  key_name               = aws_key_pair.ssh_key.key_name
  tags                   = var.tags

  ebs_block_device {
    device_name           = "/dev/sda1"
    delete_on_termination = true
    tags                  = var.tags
    volume_size           = 100
  }

  provisioner "remote-exec" {
    inline = [
      "curl -fsSL https://get.docker.com -o /tmp/get-docker.sh",
      "sudo sh /tmp/get-docker.sh",
      "sudo usermod -aG docker ubuntu",
      "sudo apt-get install -y docker-compose",
      "sudo ln -s /usr/bin/python3 /usr/bin/python",
    ]

    connection {
      host        = aws_instance.graphstore_server.public_ip
      type        = "ssh"
      user        = "ubuntu"
      agent       = false
      private_key = file(var.private_key_path)
    }
  }
}
