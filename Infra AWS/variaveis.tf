variable "cidr_qualquer_ip" {
    description = "Qualquer IP do mundo"
    type = string 
    default = "0.0.0.0/0"
}

variable "frontend_port" {
    description = "Porta do frontend"
    type = number
    default = 5173
}