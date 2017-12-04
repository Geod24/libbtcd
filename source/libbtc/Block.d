/*******************************************************************************

    Definition of a bitcoin block

*******************************************************************************/

module libbtc.Block;

import libbtc.BitBlob;
import libbtc.Hash;
public import libbtc.Serialization;
version(unittest) import libbtc.TestData;
public import libbtc.Transaction;

import std.exception;

/*******************************************************************************

    A block header

    This is the first thing sent to other nodes when a block gets mined.
    Other nodes can then confirm that the header satisfies the challenge,
    then the block data itself will get transfered and verified.

*******************************************************************************/

public struct BlockHeader
{
    /// Block version
    int nVersion;
    /// Hash of the previous block in the chain
    Hash hashPrevBlock;
    /// Hash of the root of the Merkle tree
    Hash hashMerkleRoot;
    /// Unix timestamp
    uint nTime;
    /// Difficulty, in bits
    uint nBits;
    /// Nounce used to satisfy the challenge
    uint nNounce;

    public void toString (scope void delegate (const(char)[]) sink)
    {
        import std.datetime.systime;
        import std.format;

        sink.formattedWrite(
            "%s: Version: %d, Prev: %s, MerkleRoot: %s, TimeStamp: %s, Bits: 0x%x, Nounce: %d",
            this.hash256, this.nVersion, this.hashPrevBlock, this.hashMerkleRoot,
            SysTime.fromUnixTime(this.nTime), this.nBits, this.nNounce);
    }
}

/// Bitcoin use different kind of serialization depending on the destination
enum SerializationKind
{
    SER_NETWORK = (1 << 0),
    SER_DISK    = (1 << 1),
    SER_GETHASH = (1 << 2),
}

struct Block
{
    public BlockHeader header;
    public Transaction[] vtx;

    public void toString (scope void delegate (const(char)[]) sink)
    {
        import std.format;

        formattedWrite(sink, "%s", this.header);
        foreach (tx_idx, ref tx; this.vtx)
        {
            formattedWrite(
                sink, "\n  Transaction (%d/%d):", tx_idx + 1, this.vtx.length);
            foreach (idx, ref in_; tx.vin)
                formattedWrite(
                    sink, "\n    Input (%d/%d): %s", idx + 1, tx.vin.length, in_);
            foreach (idx, ref out_; tx.vout)
                formattedWrite(
                    sink, "\n    Output (%d/%d): %s", idx + 1, tx.vout.length, out_);
        }
    }
}

struct BlockDiskHeader
{
    static immutable uint MagicChallenge = 0xD9B4BEF9;

    uint magic;
    uint size;
}
