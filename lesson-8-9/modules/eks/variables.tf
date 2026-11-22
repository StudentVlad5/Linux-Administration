variable "cluster_name" {
  description = "Назва EKS кластера"
  type        = string
  default     = "lesson-7-eks"
}

variable "subnet_ids" {
  description = "Список ID підмереж для розгортання кластера та нод"
  type        = list(string)
}

variable "instance_types" {
  description = "Тип інстансів для Worker Nodes"
  type        = list(string)
  default     = ["t3.micro", "t2.micro"]
}