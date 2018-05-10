provider "aws" {
	access_key = ""
	secret_key = ""
	region = "eu-west-1"

}
resource "aws_launch_configuration" "farrukh_l_configuration" {
	image_id = "ami-43bd8a3a"
	instance_type = "t2.micro"
	key_name = "irelandkey"
	security_groups = ["${aws_security_group.farrukh.id}"]
	user_data = <<-EOF
		"sudo yum clean all"
		"sudo yum install wget unzip php php-mysql php-gd  httpd -y"
		"wget -P /tmp   https://wordpress.org.latest.zip",
		"cd /tmp",
		"sudo unzip /tmp/latest.zip",
		"sudo cp -r /tmp/wordpress/* /var/www/html/",
		"sudo chown apache:apache /var/www/html/*",
		"sudo service httpd restart",
		"sudo chkconfig httpd on"
		EOF

lifecycle {
	create_before_destroy = true	
	}
}

resource "aws_security_group" "farrukh" {
	name = "farrukh-example"
	description = "This is for Raise marketing"
	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	ingress {
		from_port = 443
		to_port = 443
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	ingress {
		from_port = 8
		to_port = 0
		protocol = "icmp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
	lifecycle {
		create_before_destroy = true
	}
}

resource "aws_autoscaling_group" "farrukh_a_g" {
		launch_configuration = "${aws_launch_configuration.farrukh_l_configuration.id}"
		min_size = 3 
		max_size = 5
		availability_zones = ["${data.aws_availability_zones.all.names}"]		
		load_balancers = ["${aws_elb.farrukh.name}"]
		health_check_type = "ELB"
		tag {
			key = "Name"
			value = "farrukh_a_g"
			propagate_at_launch = true
		}
}

data "aws_availability_zones" "all" {}

resource "aws_elb" "farrukh" {
	availability_zones = ["${data.aws_availability_zones.all.names}"]	
	security_groups = ["${aws_security_group.farrukh.id}"]
	listener {
		lb_port = 80
		lb_protocol = "http"
		instance_port = 80
		instance_protocol = "http"
	}
	health_check = {
		healthy_threshold = 2
		unhealthy_threshold = 2
		timeout = 3
		interval = 30
		target = "HTTP:80/"
	}
}
#resource "aws_security_group" "farrukh_sec_group" {
#	name = "terraform-sec-group"
#	ingress {
#		from_port = 80
#		to_port = 80
#		protocol = "tcp"
#		cidr_blocks = ["0.0.0.0/0"]	
#	}
#	ingress {
#		from_port = 443
#		to_port = 443
#		protocol = "tcp"
#		cidr_blocks = ["0.0.0.0/0"]
#	}
#}


output  "elb_dns_name" {
	value = "${aws_elb.farrukh.dns_name}"	
}

