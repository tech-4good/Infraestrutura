from diagrams import Diagram, Cluster
from diagrams.aws.compute import EC2
from diagrams.aws.network import ELB, VPC, InternetGateway, RouteTable
from diagrams.aws.storage import S3
from diagrams.aws.general import User


with Diagram("|Diagrama de Rede| Tech4Good", filename="diagrama_de_rede_tech4good", direction="LR"):
    
    # Recursos externos à VPC
    user = User("Usuário Final")
    
    with Cluster("S3", direction="TB"):
            s3_trusted = S3("Trusted")
            s3_raw = S3("Raw")
            s3_curated = S3("Curated")
            s3_raw >> s3_trusted >> s3_curated
        # Lista de buckets para facilitar conexões
            s3_buckets = [s3_trusted, s3_raw, s3_curated]

    with Cluster("VPC 10.0.0.0/26"):
       
        # Zona de disponibilidade us-east-1c
        with Cluster("us-east-1c"):
            with Cluster("Private Subnet\n10.0.0.16/28"):
                ec2_priv_1c = EC2("Back-End & DB")
            with Cluster("Public Subnet\n10.0.0.0/28"):
                ec2_pub_1c = EC2("Web")

        # Zona de disponibilidade us-east-1b
        with Cluster("us-east-1b"):
            with Cluster("Private Subnet\n10.0.0.48/28"):
                ec2_priv_1b = EC2("Back-End & DB")
            with Cluster("Public Subnet\n10.0.0.32/28"):
                ec2_pub_1b = EC2("Web")

        # Load Balancer e Internet Gateway
        lb = ELB("Application Load Balancer")
        igw = InternetGateway("Internet Gateway")
        route = RouteTable("Route Table")

        # Conexões principais
        user >> igw >> lb
        lb >> [ec2_pub_1c, ec2_pub_1b]
        ec2_pub_1c >> ec2_priv_1c
        ec2_pub_1b >> ec2_priv_1b

        # Rotas
        lb >> route
        route >> [ec2_pub_1c, ec2_pub_1b, ec2_priv_1c, ec2_priv_1b]

    # Conexões externas (fora da VPC)
    ec2_priv_1c >> s3_raw
    ec2_priv_1b >> s3_raw
