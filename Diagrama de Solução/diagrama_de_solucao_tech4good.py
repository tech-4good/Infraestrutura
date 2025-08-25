from diagrams import Diagram, Cluster, Edge
from diagrams.aws.general import InternetGateway
from diagrams.aws.compute import EC2
from diagrams.onprem.client import Users
from diagrams.onprem.network import Internet
from diagrams.onprem.compute import Server
from diagrams.onprem.container import Docker
from diagrams.onprem.database import MySQL
from diagrams.programming.language import Java, Nodejs
from diagrams.programming.framework import React

with Diagram("Diagrama de Solução", direction="LR"):

    with Cluster("ASA"):
        beneficiados = Users("Beneficiados")
        voluntario = Users("Voluntário(a)")

    internet = Internet("Internet")

    with Cluster("AWS VPC"):
        igw = InternetGateway("Internet Gateway")

        with Cluster("Front-End"):
            fe_ec2 = EC2("EC2")
            with Cluster("Container FE"):
                fe_docker = Docker("Docker")
                fe_react = React("React")
                fe_node = Nodejs("Node.js")
                fe_docker >> [fe_react, fe_node]
            fe_ec2 >> fe_docker 

        with Cluster("Back-End"):
            be_ec2 = EC2("EC2")
            with Cluster("Container BE"):
                be_docker = Docker("Docker")
                be_java = Java("Java Spring")
                be_mysql = MySQL("MySQL")
                be_docker >> [be_java, be_mysql]
            be_ec2 >> be_docker

        fe_ec2 - Edge(style="dashed") - be_ec2

    with Cluster("APIs Externas"):
        twilio = Server("Twilio")
        viacep = Server("ViaCEP")
        google_vision = Server("Google Vision")

        api_gateway = Server("API")

        api_gateway >> [twilio, viacep, google_vision]

    beneficiados >> voluntario >> internet >> igw
    igw >> fe_ec2
    fe_ec2 >> api_gateway
