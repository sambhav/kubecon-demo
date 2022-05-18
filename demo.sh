#!/bin/bash
set -e

source demo-magic.sh

function create_busybox_bin_dir() {
  mkdir -p bin
  echo "Downloading busybox..."
  test -f bin/busybox || ( cd bin && wget https://busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox )
  echo "Creating symlinks..."
  while read com; do
    ( cd bin && rm -f $com && ln -s busybox $com )
  done <commands.txt
  echo "Done!"
}

pe "create_busybox_bin_dir"
pe "ls -l bin"

rm -rf output-image
rm -rf temp

pe "# Creating the OCI image layout"
pe "mkdir -p output-image"
pe "# Creating the layer"
pe "tar cf output-image/layer.tar.gz bin"
pe "tar tf output-image/layer.tar.gz"
pe 'layer_checksum=$(shasum -a 256 output-image/layer.tar.gz | cut -d" " -f1)'
pe "layer_size=\$(wc -c output-image/layer.tar.gz | awk '{print \$1}')"
pe 'echo $layer_checksum $layer_size'
pe 'mkdir -p output-image/blobs/sha256'
pe 'mv output-image/layer.tar.gz output-image/blobs/sha256/$layer_checksum'
pe "# Layer blob is ready and named properly!"
pe 'ls output-image/blobs/sha256'
pe '# Creating the config blob!'
pe "$(<config-command)"
pe 'config_checksum=$(shasum -a 256 output-image/config.json | cut -d" " -f1)'
pe "config_size=\$(wc -c output-image/config.json | awk '{print \$1}')"
pe 'mv output-image/config.json output-image/blobs/sha256/$config_checksum'
pe '# Creating the manifest blob!'
pe "$(<manifest-command)"
pe 'manifest_checksum=$(shasum -a 256 output-image/manifest.json | cut -d" " -f1)'
pe "manifest_size=\$(wc -c output-image/manifest.json | awk '{print \$1}')"
pe 'mv output-image/manifest.json output-image/blobs/sha256/$manifest_checksum'
pe '# Creating the image index!'
pe "$(<index-command)"
pe "echo '{\"imageLayoutVersion\":\"1.0.0\"}' > output-image/oci-layout"
pe '# Pushing the image out to a registry!'
pe "crane push output-image localhost:5001/output-image"
pe "# Let's run it!"
pe "docker run -it localhost:5001/output-image sh"
