resource "aws_db_instance" "app01-rds_database" {
    allocated_storage = 10
    instance_class = "db.t3.micro"
    username = "stoneface_admin"
    password = "Stoneface&&33&&1998"
    skip_final_snapshot = true
    engine = "mysql"
    engine_version = "5.7"
    availability_zone = "us-east-2a"
    identifier = "prod-dbinstance-mysql"
    tags = {
        Name: "prod-dbinstance-mysql"
    }
    backup_retention_period = 7
    publicly_accessible = true
    

}





output "rds-dbinstance-mysql" {
    value = aws_db_instance.app01-rds_database.id  
}