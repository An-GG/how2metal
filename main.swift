import Metal

let gpus = MTLCopyAllDevices()
let radeon = gpus[0]

print("Using GPU: " + radeon.name)

let libraryFile = Bundle.main.path(forResource: "compute", ofType: "metallib")!
let lib = try radeon.makeLibrary(filepath: libraryFile)

let commandQueue = radeon.makeCommandQueue()!
let commandBuffer = commandQueue.makeCommandBuffer()!
let commandEncoder = commandBuffer.makeComputeCommandEncoder()!


print("Lib Methods: ")
print(lib.functionNames)

let addFunction = lib.makeFunction(name: lib.functionNames[0])!
let addPipeline = try radeon.makeComputePipelineState(function: addFunction)
commandEncoder.setComputePipelineState(addPipeline)


let inputA: [Float] = [1.0, 2.0, 10, 2222]
let inputB: [Float] = [2.0, 5.0, 123, 23]

let dataSize = inputA.count


let inBufferA = radeon.makeBuffer(bytes: inputA, length: MemoryLayout<Float>.stride * dataSize, options: [])!
let inButterB = radeon.makeBuffer(bytes: inputB, length: MemoryLayout<Float>.stride * dataSize, options: [])!
let outBuffer = radeon.makeBuffer(length: MemoryLayout<Float>.stride * dataSize, options: [])!

commandEncoder.setBuffer(inBufferA, offset: 0, index: 0)
commandEncoder.setBuffer(inButterB, offset: 0, index: 1)
commandEncoder.setBuffer(outBuffer, offset: 0, index: 2)


var maxConcThreads = addPipeline.maxTotalThreadsPerThreadgroup
if (maxConcThreads > dataSize) {
    maxConcThreads = dataSize
}

let threads = MTLSize(width: dataSize, height: 1, depth: 1)
let threadGroupSize = MTLSize(width: maxConcThreads, height: 1, depth: 1)


commandEncoder.dispatchThreads(threads, threadsPerThreadgroup: threadGroupSize)
commandEncoder.endEncoding()

commandBuffer.commit()
commandBuffer.waitUntilCompleted()

let data = Array(UnsafeMutableBufferPointer<Float>(start: outBuffer.contents().assumingMemoryBound(to: Float.self), count: dataSize))
print(data)

