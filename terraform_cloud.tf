terraform { 
  cloud { 
    
    organization = "ITXprt" 

    workspaces { 
      name = "testing" 
    } 
  } 
}