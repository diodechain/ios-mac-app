import Foundation

/// Minimal Keccak-256 (Ethereum variant, not NIST SHA3-256).
public enum Keccak256 {
    public static func hash(_ data: Data) -> Data {
        hash(Array(data))
    }

    public static func hash(_ bytes: [UInt8]) -> Data {
        let rate = 136
        var state = [UInt64](repeating: 0, count: 25)
        let padded = pad(bytes, rate: rate)

        var offset = 0
        while offset < padded.count {
            for i in 0..<(rate / 8) {
                var word: UInt64 = 0
                for j in 0..<8 {
                    word |= UInt64(padded[offset + i * 8 + j]) << (8 * j)
                }
                state[i] ^= word
            }
            offset += rate
            keccakF1600(&state)
        }

        var output = [UInt8]()
        output.reserveCapacity(32)
        for i in 0..<4 {
            let word = state[i]
            for j in 0..<8 where output.count < 32 {
                output.append(UInt8((word >> (8 * j)) & 0xFF))
            }
        }
        return Data(output)
    }

    private static func pad(_ input: [UInt8], rate: Int) -> [UInt8] {
        var output = input
        output.append(0x01)
        while output.count % rate != rate - 1 {
            output.append(0x00)
        }
        output.append(0x80)
        return output
    }

    private static func keccakF1600(_ state: inout [UInt64]) {
        let roundConstants: [UInt64] = [
            0x0000000000000001, 0x0000000000008082, 0x800000000000808A, 0x8000000080008000,
            0x000000000000808B, 0x0000000080000001, 0x8000000080008081, 0x8000000000008009,
            0x000000000000008A, 0x0000000000000088, 0x0000000080008009, 0x000000008000000A,
            0x000000008000808B, 0x800000000000008B, 0x8000000000008089, 0x8000000000008003,
            0x8000000000008002, 0x8000000000000080, 0x000000000000800A, 0x800000008000000A,
            0x8000000080008081, 0x8000000000008080, 0x0000000080000001, 0x8000000080008008,
        ]
        let rotationOffsets = [
            [0, 36, 3, 41, 18],
            [1, 44, 10, 45, 2],
            [62, 6, 43, 15, 61],
            [28, 55, 25, 21, 56],
            [27, 20, 39, 8, 14],
        ]

        for round in 0..<24 {
            var c = [UInt64](repeating: 0, count: 5)
            for x in 0..<5 {
                c[x] = state[x] ^ state[x + 5] ^ state[x + 10] ^ state[x + 15] ^ state[x + 20]
            }

            var d = [UInt64](repeating: 0, count: 5)
            for x in 0..<5 {
                d[x] = c[(x + 4) % 5] ^ rotateLeft(c[(x + 1) % 5], by: 1)
            }

            for x in 0..<5 {
                for y in 0..<5 {
                    state[x + 5 * y] ^= d[x]
                }
            }

            var b = [UInt64](repeating: 0, count: 25)
            for x in 0..<5 {
                for y in 0..<5 {
                    b[y + 5 * ((2 * x + 3 * y) % 5)] = rotateLeft(state[x + 5 * y], by: rotationOffsets[x][y])
                }
            }

            for x in 0..<5 {
                for y in 0..<5 {
                    state[x + 5 * y] = b[x + 5 * y] ^ ((~b[(x + 1) % 5 + 5 * y]) & b[(x + 2) % 5 + 5 * y])
                }
            }

            state[0] ^= roundConstants[round]
        }
    }

    private static func rotateLeft(_ value: UInt64, by offset: Int) -> UInt64 {
        (value << offset) | (value >> (64 - offset))
    }
}
