L1_RPC_URL="https://opt-sepolia.g.alchemy.com/v2/demo"
L1_RPC_KIND="alchemy"

pull_dirs:
	git clone https://github.com/blockscout/blockscout.git -b production-optimism
	git clone https://github.com/ethereum-optimism/optimism.git
	git clone https://github.com/ethereum-optimism/op-geth.git
	git clone https://github.com/ethereum-optimism/infra.git

validate_versions:
	cd optimism
	./packages/contracts-bedrock/scripts/getting-started/versions.sh

build_proj:
# # Switch to the correct branch and install dependencies
# 	cd ./optimism && git checkout tutorials/chain && pnpm install
# # Build op-node, op-batcher, and op-proposer
# 	cd ./optimism && make op-node op-batcher op-proposer && pnpm build
# # Build op-geth
# 	cd ./op-geth && make geth
# # Set environment variables
# 	cd ./optimism && direnv allow
# 	cd ./optimism/packages/contracts-bedrock && L1_RPC_URL="https://opt-sepolia.g.alchemy.com/v2/demo" ./scripts/getting-started/config.sh
# 	cd ./optimism/op-node && direnv allow && L1_RPC_URL="https://opt-sepolia.g.alchemy.com/v2/demo" \
# 		go run ./cmd/main.go genesis l2 \
# 			--deploy-config ../packages/contracts-bedrock/deploy-config/sepolia.json \
# 			--l1-deployments ../packages/contracts-bedrock/deployments/optimism-sepolia/.depoly \
# 			--outfile.l2 genesis.json \
# 			--outfile.rollup rollup.json \
# 			--l1-rpc "https://opt-sepolia.g.alchemy.com/v2/demo"

# # PRE REQUIREMENTS: set L1_RPC_URL and GS_ADMIN_PRIVATE_KEY in .envrc
# deploy_contracts:
# 	cd packages/contracts-bedrock
# 	forge script scripts/Deploy.s.sol:Deploy --private-key $GS_ADMIN_PRIVATE_KEY --broadcast --rpc-url $L1_RPC_URL --slow
