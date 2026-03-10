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
  iso_url      = "https://releases.ubuntu.com/22.04.4/ubuntu-22.04.4-live-server-amd64.iso"
  iso_checksum = "file:https://releases.ubuntu.com/22.04.4/SHA256SUMS"
  
  # 2. THE EMULATOR
  qemu_binary  = "qemu-system-x86_64"
  machine_type = "q35"
  
  # 3. VIRTUAL HARDWARE
  cpus         = 4
  memory       = 4096
  disk_size    = "20G"
  format       = "qcow2" 
  
  # 4. THE CONNECTION
  http_directory = "http"
  boot_wait      = "5s"
  boot_command = [
    "c<wait>",
    "set linux_gfx_mode=text<enter>",
    "linux /casper/vmlinuz --- autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]

  # 5. CREDENTIALS & PERFORMANCE (Unified)
  ssh_username     = "admin"
  ssh_password     = "admin"
  ssh_timeout      = "30m"          # Increased slightly to be safe for GitHub
  accelerator      = "kvm"          # This makes GitHub build at native speed
  shutdown_command = "echo 'admin' | sudo -S shutdown -P now"

  # 6. HEADLESS (Crucial for GitHub runners)
  headless            = true
  use_default_display = false
  display            = "none"
  
  qemuargs = [
    ["-display", "none"],
    ["-vga", "none"],
    ["-device", "virtio-net-pci,netdev=net0"],
    ["-netdev", "user,id=net0,hostfwd=tcp::{{ .SSHHostPort }}-:22"]
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