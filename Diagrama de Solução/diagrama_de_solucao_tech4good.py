from diagrams import Diagram, Cluster, Edge
from diagrams.aws.general import InternetGateway
from diagrams.aws.compute import EC2
from diagrams.onprem.client import Users
from diagrams.onprem.network import Internet
from diagrams.onprem.compute import Server
from diagrams.onprem.database import MySQL
from diagrams.programming.language import Java, Nodejs
from diagrams.programming.framework import React
from diagrams.custom import Custom



with Diagram("Diagrama de Solução", direction="LR"):

    with Cluster("ASA"):
        beneficiados = Users("Beneficiados")
        voluntario = Users("Voluntário(a)")


    internet = Internet("Internet")

    with Cluster("AWS VPC"):
        igw = InternetGateway("Internet Gateway")

        with Cluster("Front-End", direction="LR"):
            fe_ec2 = EC2("EC2")
            with Cluster("Container Docker", direction="LR"):
                fe_react = React("React")
                fe_node = Nodejs("Node.js")

        with Cluster("Back-End"):
            be_ec2 = EC2("EC2")
            with Cluster("Container Docker", direction="LR"):
                be_java = Java("Java Spring")
                be_mysql = MySQL("MySQL")
         
        fe_ec2 - Edge(style="dashed") - be_ec2


    with Cluster("APIs Externas", direction="LR"):
        twilio = Custom("Twilio", './assets/twilio.png')
        viacep = Custom("ViaCEP", './assets/viacep.png')
        google_vision = Custom("Google Vision", "./assets/google_vision.png")
        api_gateway = Custom("API Gateway", "./assets/api.png")
        api_gateway >> [twilio, viacep, google_vision]

    beneficiados >> voluntario >> internet >> igw
    igw >> fe_ec2
    fe_react >> api_gateway 
    be_java >> api_gateway
