/*******************************************************************************

    Hashing utilities

*******************************************************************************/

module libbtc.Hash;

import libbtc.BitBlob;
import libbtc.Block;
version(unittest) import libbtc.TestData;

/// Perform double sha256 hashing of the input data
public Hash hash256 (in ubyte[] arg) pure nothrow @nogc @safe
{
    import std.digest.sha;
    return Hash(sha256Of(sha256Of(arg)));
}

///
pure @safe nothrow @nogc unittest
{
    auto ghash = hash256(GenesisBlockHeader);
    assert(ghash == Hash(GenesisBlockHash));
}

/// Perform hashing of the block header
public Hash hash256 (const ref BlockHeader header) pure nothrow @nogc @safe
{
    return () @trusted {
        scope const bin = (cast(const ubyte*)&header)[0 .. BlockHeader.sizeof];
        return hash256(bin);
    }();
}

///
pure @safe nothrow @nogc unittest
{
    BlockHeader genesis_header =
    {
        nVersion: 1,
        hashPrevBlock: Hash.init,
        hashMerkleRoot: Hash(GenesisBlockHeader[36 .. 68]),
        nTime: 0x495FAB29,
        nBits: 0x1D00FFFF,
        nNounce: 0x7C2BAC1D
    };
    auto ghash = hash256(genesis_header);
    assert(ghash == Hash(GenesisBlockHash));
}
