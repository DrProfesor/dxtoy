package main

import "core:sys/win32"
import "core:strings"
import "core:math/linalg"

import dx "shared:odin-dx"

logln :: dx.logln;

Vec3 :: linalg.Vector3;
Vec4 :: linalg.Vector4;
Mat4 :: linalg.Matrix4;

main :: proc() {
	dx.g_context = context;
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
	    desc.BufferDesc.Format = dx.DXGI_FORMAT_B8G8R8A8_UNORM;
	    desc.BufferDesc.ScanlineOrdering = dx.DXGI_MODE_SCANLINE_ORDER_UNSPECIFIED;
	    desc.BufferDesc.Scaling = dx.DXGI_MODE_SCALING_UNSPECIFIED;
	    desc.SampleDesc.Count = 1;
	    desc.SampleDesc.Quality = 0;
	    desc.BufferUsage = .DXGI_USAGE_RENDER_TARGET_OUTPUT;
	    desc.BufferCount = 2;
	    desc.OutputWindow = window.platform_data.window_handle;
	    desc.Windowed = true;
	    desc.SwapEffect = dx.DXGI_SWAP_EFFECT_FLIP_DISCARD;
	    desc.Flags = dx.DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH;

		feature_level : dx.D3D_FEATURE_LEVEL;
		res := dx.D3D11CreateDeviceAndSwapChain(
			nil,
			dx.D3D_DRIVER_TYPE_HARDWARE, 
			dx.HMODULE(nil), 
			dx.D3D11_CREATE_DEVICE_DEBUG, // flags
			nil,
			0,
			7,
			&desc,
			&swap_chain,
			&device,
			&feature_level,
			&ctxt);

		logln("Create Device and SwapChain Response: ", res == dx.S_OK ? "OK" : "FAIL");
		logln("Initialized DirectX at Feature Level: ", feature_level);

		back_buffer: ^dx.ID3D11Texture2D;
		swap_chain.GetBuffer(swap_chain, 0, dx.IID_ID3D11Texture2D, cast(^rawptr)&back_buffer);
		device.CreateRenderTargetView(device, cast(^dx.ID3D11Resource) back_buffer, nil, &render_target_view);
		ctxt.OMSetRenderTargets(ctxt, 1, &render_target_view, nil);
	}

	layout := []dx.D3D11_INPUT_ELEMENT_DESC{
		{"POSITION", 0, dx.DXGI_FORMAT_R32G32B32_FLOAT, 0, 0, dx.D3D11_INPUT_PER_VERTEX_DATA, 0},
		{"COLOR", 0, dx.DXGI_FORMAT_R32G32B32A32_FLOAT, 0, 12, dx.D3D11_INPUT_PER_VERTEX_DATA, 0},
	};

	verts := []Vertex{
    	{{-1.0, -1.0, -1.0}, {1.0, 0.0, 0.0, 1.0}},
	    {{-1.0, +1.0, -1.0}, {0.0, 1.0, 0.0, 1.0}},
	    {{+1.0, +1.0, -1.0}, {0.0, 0.0, 1.0, 1.0}},
	    {{+1.0, -1.0, -1.0}, {1.0, 1.0, 0.0, 1.0}},
	    {{-1.0, -1.0, +1.0}, {0.0, 1.0, 1.0, 1.0}},
	    {{-1.0, +1.0, +1.0}, {1.0, 1.0, 1.0, 1.0}},
	    {{+1.0, +1.0, +1.0}, {1.0, 0.0, 1.0, 1.0}},
	    {{+1.0, -1.0, +1.0}, {1.0, 0.0, 0.0, 1.0}},
	};

	indices := []u32{
    // front face
	    0, 1, 2,
	    0, 2, 3,
	    // back face
	    4, 6, 5,
	    4, 7, 6,
	    // left face
	    4, 5, 1,
	    4, 1, 0,
	    // right face
	    3, 2, 6,
	    3, 6, 7,
	    // top face
	    1, 5, 6,
	    1, 6, 2,
	    // bottom face
	    4, 0, 3, 
	    4, 3, 7
	};	

	VS: ^dx.ID3D11VertexShader;
	PS: ^dx.ID3D11PixelShader;
	VS_Buffer: ^dx.ID3D10Blob;
	PS_Buffer: ^dx.ID3D10Blob;

	vert_layout: ^dx.ID3D11InputLayout;

	depth_stencil_view: ^dx.ID3D11DepthStencilView;
	depth_stencil_buffer: ^dx.ID3D11Texture2D;

	hs: dx.HRESULT;

	// Load shaders
	{
		err: ^dx.ID3D10Blob;
		f_name := win32.utf8_to_wstring("Effects.fx\x00");
		entry_vs : cstring = "VS";
		entry_ps : cstring = "PS";
		ver_vs : cstring = "vs_4_0";
		ver_ps : cstring = "ps_4_0";
		hs = dx.D3DCompileFromFile(f_name, nil, nil, entry_vs, ver_vs, 1, 0, &VS_Buffer, &err); log_errors(err);
	    hs = dx.D3DCompileFromFile(f_name, nil, nil, entry_ps, ver_ps, 1, 0, &PS_Buffer, &err); log_errors(err);

	    device.CreateVertexShader(device, VS_Buffer.GetBufferPointer(VS_Buffer), VS_Buffer.GetBufferSize(VS_Buffer), nil, &VS);
	    device.CreatePixelShader(device, PS_Buffer.GetBufferPointer(PS_Buffer), PS_Buffer.GetBufferSize(PS_Buffer), nil, &PS);

	    ctxt.VSSetShader(ctxt, VS, nil, 0);
	    ctxt.PSSetShader(ctxt, PS, nil, 0);
	}

	// vertex buffers
	{
		vertex_buffer_desc := dx.D3D11_BUFFER_DESC {
			u32(size_of(Vertex) * len(verts)), 
			dx.D3D11_USAGE_DEFAULT,
			dx.D3D11_BIND_VERTEX_BUFFER,
			0,
			0,
			0,
		};

		vertex_buffer_data: dx.D3D11_SUBRESOURCE_DATA;
		vertex_buffer_data.pSysMem = &verts[0];

		vert_buffer: ^dx.ID3D11Buffer;
		device.CreateBuffer(device, &vertex_buffer_desc, &vertex_buffer_data, &vert_buffer);

		stride : u32 = size_of(Vertex);
		offset : u32 = 0;
		ctxt.IASetVertexBuffers(ctxt, 0, 1, &vert_buffer, &stride, &offset);
	}

	// index buffers
	{
		index_buffer_desc := dx.D3D11_BUFFER_DESC {
			cast(u32) (size_of(u32) * len(indices)), 
			dx.D3D11_USAGE_DEFAULT,
			dx.D3D11_BIND_INDEX_BUFFER,
			0,
			0,
			0,
		};

		ind_buffer_data: dx.D3D11_SUBRESOURCE_DATA;
		ind_buffer_data.pSysMem = &indices[0];

		ind_buffer: ^dx.ID3D11Buffer;
		device.CreateBuffer(device, &index_buffer_desc, &ind_buffer_data, &ind_buffer);

		ctxt.IASetIndexBuffer(ctxt, ind_buffer, dx.DXGI_FORMAT_R32_UINT, 0);
	}

	// depth buffer
	{
   		depth_stencil_desc: dx.D3D11_TEXTURE2D_DESC;

	    depth_stencil_desc.Width     = 1920;
	    depth_stencil_desc.Height    = 1080;
	    depth_stencil_desc.MipLevels = 1;
	    depth_stencil_desc.ArraySize = 1;
	    depth_stencil_desc.Format    = dx.DXGI_FORMAT_D24_UNORM_S8_UINT;
	    depth_stencil_desc.SampleDesc.Count   = 1;
	    depth_stencil_desc.SampleDesc.Quality = 0;
	    depth_stencil_desc.Usage          = dx.D3D11_USAGE_DEFAULT;
	    depth_stencil_desc.BindFlags      = dx.D3D11_BIND_DEPTH_STENCIL;
	    depth_stencil_desc.CPUAccessFlags = 0; 
	    depth_stencil_desc.MiscFlags      = 0;

	    device.CreateTexture2D(device, &depth_stencil_desc, nil, &depth_stencil_buffer);
	    device.CreateDepthStencilView(device, cast(^dx.ID3D11Resource) depth_stencil_buffer, nil, &depth_stencil_view);

	}

	// cbuffer
	constant_buffer: ^dx.ID3D11Buffer;
	cbo: CBObj;
	{
	    cbbd: dx.D3D11_BUFFER_DESC;    
	    cbbd.Usage = dx.D3D11_USAGE_DEFAULT;
	    cbbd.ByteWidth = size_of(CBObj);
	    cbbd.BindFlags = dx.D3D11_BIND_CONSTANT_BUFFER;
	    cbbd.CPUAccessFlags = 0;
	    cbbd.MiscFlags = 0;

	    device.CreateBuffer(device, &cbbd, nil, &constant_buffer);
	}

	cam_pos := Vec3{0.0, 5.0, -15.0};
    cam_target := Vec3{0.0, 0.0, 0.0};
    cam_up := Vec3{0.0, 1.0, 0.0};
    cam_view := linalg.matrix4_look_at(cam_pos, cam_target, cam_up);
    cam_proj := linalg.matrix4_perspective(linalg.radians(90), 1920.0/1080.0, 1.0, 1000.0);

    cube_world := linalg.matrix4_translate({0,0,0});

	device.CreateInputLayout(device, &layout[0], cast(u32) len(layout), VS_Buffer.GetBufferPointer(VS_Buffer), VS_Buffer.GetBufferSize(VS_Buffer), &vert_layout);
	ctxt.IASetInputLayout(ctxt, vert_layout);
	ctxt.IASetPrimitiveTopology(ctxt, dx.D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);

	// viewport
	viewport: dx.D3D11_VIEWPORT;
	{
		viewport.TopLeftX = 0;
		viewport.TopLeftY = 0;
		viewport.Width = 1920;
		viewport.Height = 1080;
		viewport.MaxDepth = 1;

		ctxt.RSSetViewports(ctxt, 1, &viewport);
	}
	
	update_loop: for {
		message: win32.Msg;
	    for win32.peek_message_a(&message, nil, 0, 0, win32.PM_REMOVE) {
	        win32.translate_message(&message);
	        win32.dispatch_message_a(&message);
	    }

	    ctxt.OMSetRenderTargets(ctxt, 1, &render_target_view, depth_stencil_view);
	    ctxt.ClearDepthStencilView(ctxt, depth_stencil_view, dx.D3D11_CLEAR_DEPTH | dx.D3D11_CLEAR_STENCIL, 1.0, 0);

		ctxt.OMSetRenderTargets(ctxt, 1, &render_target_view, nil);
	    ctxt.ClearRenderTargetView(ctxt, render_target_view, {0.1,0.5,0.8,1});

	    mvp := linalg.mul(linalg.mul(cube_world, cam_view), cam_proj);
	    cbo.MVP = linalg.transpose(mvp);
	    ctxt.UpdateSubresource(ctxt, cast(^dx.ID3D11Resource) constant_buffer, 0, nil, &cbo, 0, 0);
	    ctxt.VSSetConstantBuffers(ctxt, 0, 1, &constant_buffer);
	    
	    ctxt.DrawIndexed(ctxt, cast(u32) len(indices), 0, 0);

	    swap_chain.Present(swap_chain, 0, 0);
	}
}

CBObj :: struct {
	MVP: Mat4,
}

Vertex :: struct {
	pos: [3]f32,
	colour: [4]f32,
}

log_errors :: proc(errors: ^dx.ID3D10Blob) {
    if errors == nil do return;

    cstr := cast(cstring)errors.GetBufferPointer(errors);
    logln(cstr);
}