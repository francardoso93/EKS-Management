locals {
  node_security_group_additional_rules = {
    metrics_server_8443_ing = {
      description                   = "Cluster API to node metrics server"
      protocol                      = "tcp"
      from_port                     = 8443
      to_port                       = 8443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    
    metrics_server_10250_ing = {
      description = "Node to node kubelets (Required for metrics server)"
      protocol    = "tcp"
      from_port   = 10250
      to_port     = 10250
      type        = "ingress"
      self        = true
    }
    
    metrics_server_10250_eg = {
      description = "Node to node metrics server"
      protocol    = "tcp"
      from_port   = 10250
      to_port     = 10250
      type        = "egress"
      self        = true
    }
    
    node_to_node_443_ing = {
      description = "Node to node HTTPS"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      self        = true
    }

    node_to_node_443_out = {
      description = "Node to node HTTPS"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "egress"
      self        = true
    }

    node_to_node_80_ing = {
      description = "Node to node HTTP"
      protocol    = "tcp"
      from_port   = 80
      to_port     = 80
      type        = "ingress"
      self        = true
    }

    node_to_node_80_out = {
      description = "Node to node HTTP"
      protocol    = "tcp"
      from_port   = 80
      to_port     = 80
      type        = "egress"
      self        = true
    }
  }
}
