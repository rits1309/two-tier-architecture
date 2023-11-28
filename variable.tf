variable "myvpc" {
  default = "10.0.0.0/16"
}
variable "pub-sub1" {
    default = "10.0.1.0/24"
}
variable "pub-sub2" {
    default = "10.0.2.0/24"
}
variable "pr-sub1" {
    default = "10.0.3.0/24"
}
variable "pr-sub2" {
    default = "10.0.4.0/24"  
}
variable "ssh_key" {
    default = "my-key-pair-rits" 
}
variable "ami" {
    default ="ami-0230bd60aa48260c6"  
}
variable "sg" {
    default = "sg-0379bdcc8868ee80f"
  
}