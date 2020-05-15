package main

import "core:sys/win32"
import "core:strings"

import dx "shared:odin-dx"

logln :: dx.logln;

main :: proc() {
	window, ok := dx.create_window("Main", 1920, 1080);
	dx.main_window = window;
	
	swap_chain        : ^dx.IDXGISwapChain;
	desc              : dx.DXGI_SWAP_CHAIN_DESC;

	device            : ^dx.ID3D11Device;
	ctxt              : ^dx.ID3D11DeviceContext;

	render_target_view: ^dx.ID3D11RenderTargetView;

	// Initialize DirectX
	{
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

		feature_level : dx.D3D_FEATURE_LEVEL;
		res := cast(dx.Create_Device_Response) dx.create_device_and_swapchain(
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

		logln("Create Device and SwapChain Response: ", res);
		logln("Initialized DirectX at Feature Level: ", feature_level);

		back_buffer: ^dx.ID3D11Texture2D;
		swap_chain.GetBuffer(swap_chain, 0, dx.IID_ID3D11Texture2D, cast(^rawptr)&back_buffer);
		device.CreateRenderTargetView(device, cast(^dx.ID3D11Resource) back_buffer, nil, &render_target_view);
		ctxt.OMSetRenderTargets(ctxt, 1, &render_target_view, nil);
	}

	layout := []dx.D3D11_INPUT_ELEMENT_DESC{
		{"POSITION", 0, .DXGI_FORMAT_R32G32B32_FLOAT, 0, 0, .D3D11_INPUT_PER_VERTEX_DATA, 0},
		// {"COLOUR", 0, .DXGI_FORMAT_R32G32B32A32_FLOAT, 0, 12, .D3D11_INPUT_PER_VERTEX_DATA, 0},
	};

	vertex_buffer_desc := dx.D3D11_BUFFER_DESC {
		size_of(Vertex) * 3, 
		.D3D11_USAGE_DEFAULT,
		.D3D11_BIND_VERTEX_BUFFER,
		0,
		0,
		0,
	};

	triangle_verts := []Vertex{
		{{0, 0.5, 0.5}},
		{{0.5, -0.5, 0.5}},
		{{-0.5,-0.5,0.5}},
	};

	VS: ^dx.ID3D11VertexShader;
	PS: ^dx.ID3D11PixelShader;
	VS_Buffer: ^dx.ID3D10Blob;
	PS_Buffer: ^dx.ID3D10Blob;

	vert_layout: ^dx.ID3D11InputLayout;

	hs: dx.HRESULT;

	err: ^dx.ID3D10Blob;
	f_name := win32.utf8_to_wstring("Effects.fx\x00");
	entry_vs : cstring = "VS\x00";
	entry_ps : cstring = "PS\x00";
	ver_vs : cstring = "vs_4_0\x00";
	ver_ps : cstring = "ps_4_0\x00";
	hs = dx.compile_from_file(f_name, nil, nil, entry_vs, ver_vs, 1, 0, &VS_Buffer, &err);
    hs = dx.compile_from_file(f_name, nil, nil, entry_ps, ver_ps, 1, 0, &PS_Buffer, nil);

    device.CreateVertexShader(device, VS_Buffer.GetBufferPointer(VS_Buffer), VS_Buffer.GetBufferSize(VS_Buffer), nil, &VS);
    device.CreatePixelShader(device, PS_Buffer.GetBufferPointer(PS_Buffer), PS_Buffer.GetBufferSize(PS_Buffer), nil, &PS);

    ctxt.VSSetShader(ctxt, VS, nil, 0);
    ctxt.PSSetShader(ctxt, PS, nil, 0);

	vertex_buffer_data: dx.D3D11_SUBRESOURCE_DATA;
	vertex_buffer_data.pSysMem = &triangle_verts[0];

	triangle_vert_buffer: ^dx.ID3D11Buffer;
	device.CreateBuffer(device, &vertex_buffer_desc, &vertex_buffer_data, &triangle_vert_buffer);

	stride : u32 = size_of(Vertex);
	offset : u32 = 0;
	ctxt.IASetVertexBuffers(ctxt, 0, 1, &triangle_vert_buffer, &stride, &offset);

	device.CreateInputLayout(device, &layout[0], cast(u32) len(layout), VS_Buffer.GetBufferPointer(VS_Buffer), VS_Buffer.GetBufferSize(VS_Buffer), &vert_layout);

	ctxt.IASetInputLayout(ctxt, vert_layout);
	ctxt.IASetPrimitiveTopology(ctxt, .D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);

	viewport: dx.D3D11_VIEWPORT;
	viewport.TopLeftX = 0;
	viewport.TopLeftY = 0;
	viewport.Width = 1920;
	viewport.Height = 1080;
	viewport.MaxDepth = 1;

	ctxt.RSSetViewports(ctxt, 1, &viewport);

	update_loop: for {
		message: win32.Msg;
	    for win32.peek_message_a(&message, nil, 0, 0, win32.PM_REMOVE) {
	        win32.translate_message(&message);
	        win32.dispatch_message_a(&message);
	    }

		ctxt.OMSetRenderTargets(ctxt, 1, &render_target_view, nil);
	    ctxt.ClearRenderTargetView(ctxt, render_target_view, {0.1,0.5,0.8,1});
	    
	    ctxt.Draw(ctxt, 3, 0);

	    swap_chain.Present(swap_chain, 0, 0);
	}
}

Vertex :: struct {
	pos: [3]f32,
	// colour: [4]f32,
}

