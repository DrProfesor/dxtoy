package main

import "shared:dx"

main :: proc() {
	device : dx.ID3D11Device;
	swap_chain : dx.IDXGISwapChain;
	ctxt : dx.ID3D11DeviceContext;
	desc : dx.DXGI_SWAP_CHAIN_DESC;

	dx.create_device_and_swapchain(
		nil, 
		.D3D_DRIVER_TYPE_UNKNOWN, 
		nil, 
		0, 
		0,
		0,
		7,
		&desc,
		&swap_chain,
		&device,
		0,
		&ctxt);
}