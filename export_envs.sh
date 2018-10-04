#!/bin/bash

for a in 01 02 03 04 05 06 14; do
    PROJECT=ad-training-${a}
    pushd ${PROJECT}
    source .envrc

    cat > ${PROJECT}-env <<-OEOF
#!/bin/bash
export BOSH_ENVIRONMENT=$(bosh int <(bucc vars) --path /bosh_target)
export BOSH_CA_CERT='$(bosh int <(bucc vars) --path /bosh_ca_cert)'
export BOSH_CLIENT=$(bosh int <(bucc vars) --path /bosh_client)
export BOSH_CLIENT_SECRET=$(bosh int <(bucc vars) --path /bosh_client_secret)
export BOSH_GW_USER=jumpbox
export BOSH_GW_HOST=$(bosh int <(bucc vars) --path /bosh_target)
export BOSH_GW_PRIVATE_KEY=\$(mktemp)
cat > \${BOSH_GW_PRIVATE_KEY} <<-EOF
$(bosh int vars/director-vars-store.yml --path /jumpbox_ssh/private_key)
EOF
export BOSH_ALL_PROXY_KEY=\$(mktemp)
cat > \${BOSH_ALL_PROXY_KEY} <<-EOF
$(bosh int vars/jumpbox-vars-store.yml --path /jumpbox_ssh/private_key)
EOF
export BOSH_ALL_PROXY=ssh+socks5://jumpbox@$(bosh int <(bucc vars) --path /jumpbox_url)?private-key=\${BOSH_ALL_PROXY_KEY}
export CREDHUB_PROXY=\${BOSH_ALL_PROXY}
export CREDHUB_SERVER=$(bosh int <(bucc vars) --path /credhub_url)
export CREDHUB_SECRET=$(bosh int <(bucc vars) --path /credhub_password)
export CREDHUB_CLIENT=$(bosh int <(bucc vars) --path /credhub_username)
export CREDHUB_CA_CERT='$(bosh int <(bucc vars) --path /bosh_ca_cert)'

export CONCOURSE_CA_CERT=\$(mktemp)
cat > \${CONCOURSE_CA_CERT} <<-EOF
$(bosh int <(bucc vars) --path /concourse_ca_cert)'
EOF

alias fly_login='fly --target ${PROJECT} login \
            --concourse-url $(bosh int <(bucc vars) --path /concourse_url) \
            --username $(bosh int <(bucc vars) --path /concourse_username) \
            --password $(bosh int <(bucc vars) --path /concourse_password) \
            --team-name main \
            --ca-cert \${CONCOURSE_CA_CERT}
          echo "Example fly commands:"
          echo "  fly -t ${PROJECT} pipelines"
          echo "  fly -t ${PROJECT} builds"
'
OEOF

    popd
done
