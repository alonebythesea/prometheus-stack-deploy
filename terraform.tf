provider "aws" {
	region = "us-east-1"
}


data "aws_vpc" "default" {
	default = true
}

data "aws_subnet_ids" "all" {
	vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group" "allow_ssh" {
	name = "allow_ssh"
	vpc_id = data.aws_vpc.default.id
	
	ingress {
	  from_port   = 22
	  to_port     = 22
	  protocol    = "tcp"
	  cidr_blocks = ["0.0.0.0/0"]
	}

	egress {
	  from_port   = 0
	  to_port     = 0
	  protocol    = -1
	  cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_security_group" "allow_internal" {
	name = "allow_internal"
	vpc_id = data.aws_vpc.default.id
	
	ingress {
	  from_port   = 0
	  to_port     = 0
          protocol    = -1
	  cidr_blocks = [data.aws_vpc.default.cidr_block]
	}
}

resource "aws_security_group" "allow_9090" {
	name = "allow_9090"
	vpc_id = data.aws_vpc.default.id

	ingress {
	  from_port   = 9090
	  to_port     = 9090
	  protocol    = "tcp"
	  cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_security_group" "allow_3000" {
	name = "allow_3000"
	vpc_id = data.aws_vpc.default.id

	ingress {
	  from_port   = 3000
	  to_port     = 3000
	  protocol    = "tcp"
	  cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_instance" "node-exporter" {
	count 	      	       = 1
	ami           	       = "ami-0083662ba17882949"
	instance_type 	       = "t3.small"
	availability_zone      = "us-east-1a" 
	key_name      	       = "my-key"
	vpc_security_group_ids = [aws_security_group.allow_internal.id, aws_security_group.allow_ssh.id]
	
	connection {
		type = "ssh"
		host = self.public_ip 
		user = "centos"
		private_key = file("~/.ssh/my-key.pem") 
	}
	
	provisioner "file" {

		source = "."
		destination = "/tmp"
	}

	provisioner "remote-exec" {
		inline = [
			"chmod +x /tmp/node_exporter.sh",
			"sudo /tmp/node_exporter.sh",
		]
	}

}

resource "aws_instance" "prometheus-server" {
	count 	      	       	= 1
	ami           	       	= "ami-0083662ba17882949"
	instance_type 	       	= "t3.small"
	availability_zone      	= "us-east-1a" 
	key_name      	       	= "my-key"
	vpc_security_group_ids 	= [aws_security_group.allow_internal.id, aws_security_group.allow_ssh.id, aws_security_group.allow_9090.id, aws_security_group.allow_3000.id]

	connection {
		type = "ssh"
		host = self.public_ip 
		user = "centos"
		private_key = file("~/.ssh/my-key.pem") 
	}
	
	provisioner "file" {

		source = "."
		destination = "/tmp"
	}

	provisioner "remote-exec" {
		inline = [
			"echo ${aws_instance.node-exporter[0].private_ip} > /tmp/ip",
			"chmod +x /tmp/prometheus_provision.sh",
			"sudo /tmp/prometheus_provision.sh",
		]
	}
} 
