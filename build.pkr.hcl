packer {
  required_plugins {
    qemu = {
      version = "~> 1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

source "qemu" "appliance" {
  # 1. THE ISO (The source of the OS)
  iso_url           = "https://releases.ubuntu.com/22.04.4/ubuntu-22.04.4-live-server-amd64.iso"
  iso_checksum      = "file:https://releases.ubuntu.com/22.04.4/SHA256SUMS"
  
  # 2. THE EMULATOR (The M4-to-Intel translator)
  qemu_binary       = "qemu-system-x86_64"
  machine_type      = "q35"
  
  # 3. VIRTUAL HARDWARE (Temporary build specs)
  cpus              = 4
  memory            = 4096
  disk_size         = "20G"
  format            = "qcow2"  # The format your clients' VMware will read
  
  # 4. THE CONNECTION (How your Mac talks to the booting VM)
  http_directory    = "http"
  boot_wait         = "5s"
  boot_command = [
    "c",
    "linux /casper/vmlinuz --- autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]

  # 5. CREDENTIALS (Matches your 'admin' user in user-data)
  ssh_username     = "admin"
  ssh_password     = "admin"
  ssh_timeout      = "45m"
  shutdown_command = "echo 'admin' | sudo -S shutdown -P now"

  # 6. HEADLESS
  headless            = true
  use_default_display = false
  display            = "none"
  
  qemuargs = [
    ["-display", "none"],
    ["-vga", "none"]
  ]

  # 7. GITHUB
  accelerator = "kvm"
  # Since GitHub runners are fast, we can lower the timeout back to 20m
  ssh_timeout = "20m"
}

build {
  sources = ["source.qemu.appliance"]

  provisioner "shell" {
    script = "./setup.sh"
  }

  # ADD THIS BLOCK to convert the result to VMDK at the end
  post-processor "shell-local" {
    inline = [
      "qemu-img convert -f qcow2 -O vmdk output-appliance/packer-appliance output-appliance/appliance.vmdk",
      "rm output-appliance/packer-appliance"
    ]
  }
}