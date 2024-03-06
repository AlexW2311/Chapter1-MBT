import PlaygroundSupport
import MetalKit

guard let device = MTLCreateSystemDefaultDevice() else {
    fatalError("Gpu is not supported:  XD")
}

// set up frame and width view

let frame = CGRect(x: 0, y: 0, width: 600, height: 600)
let view = MTKView(frame: frame, device: device)

view.clearColor = MTLClearColor(red: 1, green: 1, blue: 0.8, alpha: 1)

let allocator = MTKMeshBufferAllocator(device: device)
let mdlMesh = MDLMesh(sphereWithExtent: [0.75,0.75,0.75], segments: [100,100], inwardNormals: false, geometryType: .triangles, allocator: allocator)

let mesh = try MTKMesh(mesh: mdlMesh, device: device)

//Setting up command Queue

guard let commandQueue = device.makeCommandQueue() else {
    fatalError("rip")
}

//EXAMPLE SHADER FUNCTION

let shader = """
#include <metal_stdlib>
using namespace metal;
struct VertexIn {
  float4 position [[attribute(0)]];
};
vertex float4 vertex_main(const VertexIn vertex_in [[stage_in]])
{
  return vertex_in.position;
}
fragment float4 fragment_main() {
  return float4(1, 0, 0, 1);
}
"""
//creates a metal library with the functions from the above rhe shader function
let library = try device.makeLibrary(source: shader, options: nil)
let vertexfunction = library.makeFunction(name: "vertex_main")
let fragmentFunction = library.makeFunction(name: "fragment_main")

// pipeline descriptor allows you to chqnge the pipeline sate

let pipelineDescriptor = MTLRenderPipelineDescriptor()
pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
pipelineDescriptor.vertexFunction = vertexfunction
pipelineDescriptor.fragmentFunction = fragmentFunction

//describe to gpu how vertices are laid out in memory
pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor)

//creates pipeline state from the descriptor
let pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)

guard let commandBuffer = commandQueue.makeCommandBuffer(),
      let renderPassDescriptor = view.currentRenderPassDescriptor,
      let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
else {fatalError()}

//give the encoder a pipeline state and a buffer
renderEncoder.setRenderPipelineState(pipelineState)
renderEncoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: 0)

guard let submesh = mesh.submeshes.first else { fatalError() }

//drawing

renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: 0)

//complete sending commands and finalize frame
renderEncoder.endEncoding()

guard let drawable = view.currentDrawable else { fatalError() }
commandBuffer.present(drawable)
commandBuffer.commit()

PlaygroundPage.current.liveView = view







