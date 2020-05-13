package main

import "core:sys/win32"

import dx "shared:odin-dx"

logln :: dx.logln;

main :: proc() {
	window, ok := dx.create_window("Main", 1920, 1080);
	dx.main_window = window;
	
	swap_chain: ^dx.IDXGISwapChain;
	desc: dx.DXGI_SWAP_CHAIN_DESC;

	device : ^dx.ID3D11Device;
	ctxt : ^dx.ID3D11DeviceContext;

	desc.BufferDesc.Width = 1920;
    desc.BufferDesc.Height = 1080;
    desc.BufferDesc.RefreshRate.Numerator = 60;
    desc.BufferDesc.RefreshRate.Denominator = 1;
    desc.BufferDesc.Format = .DXGI_FORMAT_B8G8R8A8_UNORM;
    desc.BufferDesc.ScanlineOrdering = .DXGI_MODE_SCANLINE_ORDER_UNSPECIFIED;
    desc.BufferDesc.Scaling = .DXGI_MODE_SCALING_UNSPECIFIED;
    desc.SampleDesc.Count = 1;
    desc.SampleDesc.Quality = 0;
    desc.BufferUsage = .DXGI_USAGE_RENDER_TARGET_OUTPUT;
    desc.BufferCount = 2;
    desc.OutputWindow = window.platform_data.window_handle;
    desc.Windowed = true;
    desc.SwapEffect = .DXGI_SWAP_EFFECT_FLIP_DISCARD;
    desc.Flags = .DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH;

    logln(size_of(^dx.IDXGIAdapter));
	logln(size_of(dx.D3D_DRIVER_TYPE));
	logln(size_of(dx.HMODULE));
	logln(size_of(dx.D3D11_CREATE_DEVICE_FLAG));
	logln(size_of(^[]dx.D3D_FEATURE_LEVEL));
	logln(size_of(u32));

	feature_level : dx.D3D_FEATURE_LEVEL;
	res := dx.create_device_and_swapchain(
		nil,
		.D3D_DRIVER_TYPE_HARDWARE, 
		dx.HMODULE(nil), 
		.D3D11_CREATE_DEVICE_DEBUG, // flags
		nil,
		0,
		7,
		&desc,
		&swap_chain,
		&device,
		&feature_level,
		&ctxt);

	logln(dx.Create_Device_Response(res));
	logln(feature_level);

	logln(swap_chain);

	back_buffer: ^dx.ID3D11Texture2D;
	swap_chain.GetBuffer(swap_chain, 0, dx.get_guid(dx.ID3D11Texture2D), cast(^rawptr)&back_buffer);

	for {
		message: win32.Msg;
	    for win32.peek_message_a(&message, nil, 0, 0, win32.PM_REMOVE) {
	        win32.translate_message(&message);
	        win32.dispatch_message_a(&message);
	    }

		win32.swap_buffers(window.platform_data.device_context);
	}
}