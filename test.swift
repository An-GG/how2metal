import Metal





var inputA: [Float] = []
var inputB: [Float] = []


let targetLength = 1024 * 1024 * 10
for _ in 0..<targetLength {
    inputA.append(Float.random(in: 0.0...100.0))
    inputB.append(Float.random(in: 0.0...100.0))
}


let gpus = MTLCopyAllDevices()
let radeon = gpus[0]

let libraryFile = Bundle.main.path(forResource: "compute", ofType: "metallib")!
let lib = try! radeon.makeLibrary(filepath: libraryFile)

let commandQueue = radeon.makeCommandQueue()!
let commandBuffer = commandQueue.makeCommandBuffer()!
let commandEncoder = commandBuffer.makeComputeCommandEncoder()!

let addFunction = lib.makeFunction(name: lib.functionNames[0])!
let addPipeline = try! radeon.makeComputePipelineState(function: addFunction)
commandEncoder.setComputePipelineState(addPipeline)

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


// Swift 3
func evaluateProblem(problemNumber: Int, problemBlock: () -> Void)
{

    let start = DispatchTime.now() // <<<<<<<<<< Start time
    problemBlock()
    let end = DispatchTime.now()   // <<<<<<<<<<   end time


    let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
    let timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests

    print("Time to evaluate problem \(problemNumber): \(timeInterval) seconds.")
}


func CPU_TEST() {
    var out: [Float] = [Float]()
    for i in 0..<inputA.count {
        out.append(inputA[i] + inputB[i]) 
    }
}




func GPU_TEST() {
    commandEncoder.dispatchThreads(threads, threadsPerThreadgroup: threadGroupSize)
    commandEncoder.endEncoding()

    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()

    let data = Array(UnsafeMutableBufferPointer<Float>(start: outBuffer.contents().assumingMemoryBound(to: Float.self), count: dataSize))
}




print("\(targetLength) length vector\n")

print("CPU")
evaluateProblem(problemNumber: 1, problemBlock: CPU_TEST)
print("GPU")
evaluateProblem(problemNumber: 2, problemBlock: GPU_TEST)
