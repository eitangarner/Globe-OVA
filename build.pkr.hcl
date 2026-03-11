packer {
  required_plugins {
    qemu = {
      version = "~> 1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

source "qemu" "appliance" {
  # 1. THE ISO
  iso_url      = "https://releases.ubuntu.com/25.10/ubuntu-25.10-live-server-amd64.iso"
  iso_checksum = "file:https://releases.ubuntu.com/25.10/SHA256SUMS"
  
  # 2. THE EMULATOR
  qemu_binary  = "qemu-system-x86_64"
  machine_type = "q35"
  
  # 3. VIRTUAL HARDWARE
  cpus      = 4
  memory    = 4096
  disk_size = "20G"
  format    = "qcow2" 
  
  # 4. THE CONNECTION
  http_directory = "http"
  boot_wait      = "10s"
  boot_command   = [
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ console=ttyS0<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]

  # 5. CREDENTIALS & PERFORMANCE
  ssh_username              = "admin"
  ssh_password              = "admin"
  ssh_timeout               = "180m"
  ssh_agent_auth            = false
  ssh_clear_authorized_keys = true          
  shutdown_command          = "echo 'admin' | sudo -S shutdown -P now"

  # 6. HEADLESS & LOGGING
  headless = true
  
  # Removed the manual -netdev. Added -serial stdio so you can read the boot logs in GitHub Actions!
  qemuargs = [
    ["-serial", "stdio"]
  ]
}

build {
  sources = ["source.qemu.appliance"]

  provisioner "shell" {
    script = "./setup.sh"
  }

  post-processor "shell-local" {
    inline = [
      "qemu-img convert -f qcow2 -O vmdk output-appliance/packer-appliance output-appliance/appliance.vmdk",
      "rm output-appliance/packer-appliance"
    ]
  }
}