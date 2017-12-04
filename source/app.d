module app;

import std.datetime;
import std.exception;
import std.format;
import std.stdio;

import libbtc.Block;

/// Application entry point
void main (string[] args)
{
    foreach (a; args[1 .. $])
        printBlockInfosFromFile(a);
}

void printBlockInfosFromFile (string path)
{
    Block block;
    auto f = File(path);
    while (readFullBlock(f, block))
        writeln(block);
}

public bool readFullBlock (ref File f, ref Block block)
{
    // Speed up reading / deserialization
    static ubyte[] buffer;

    BlockDiskHeader dheader = readDiskHeader(f);
    if (f.eof) return false;

    if (buffer.length < dheader.size)
        buffer.length = dheader.size;

    const(ubyte)[] slice = f.rawRead(buffer[0 .. dheader.size]);
    enforce(slice.length == dheader.size, "Incomplete data read");

    block = deserializeBlock(slice);
    return true;
}

public BlockDiskHeader readDiskHeader (ref File f)
{
    BlockDiskHeader header;
    if (f.rawRead((&header)[0 .. 1]).length == 0)
    {
        enforce(f.eof, "Nothing read but EOF not reached");
        return header;
    }

    enforce(header.magic == BlockDiskHeader.MagicChallenge,
            format("Magic %X doesn't match challenge %X",
                   header.magic, BlockDiskHeader.MagicChallenge));
    enforce(header.size > BlockHeader.sizeof,
            "The size of the block is not even the one of the header");
    return header;
}

public Block deserializeBlock (scope ref const(ubyte)[] raw)
{
    Block block = Block(raw.read!BlockHeader);
    ulong tx_count = raw.readCompactSize();
    block.vtx.length = tx_count;
    foreach (ref tx; block.vtx)
        tx = readTransaction(raw);

    return block;
}

public Transaction readTransaction (scope ref const(ubyte)[] raw)
{
    Transaction tx;

    // Read version number
    tx.nVersion = raw.read!uint;

    ulong inputs = raw.readCompactSize();
    tx.vin.length = inputs;
    foreach (ref tx_in; tx.vin)
        tx_in = readCTxIn(raw);

    ulong outputs = raw.readCompactSize();
    tx.vout.length = outputs;
    foreach (ref tx_out; tx.vout)
        tx_out = readCTxOut(raw);

    tx.nLockTime = raw.read!uint;

    return tx;
}

public CTxIn readCTxIn (scope ref const(ubyte)[] raw)
{
    CTxIn ret;
    ret.prevout = raw.read!COutPoint;
    ulong sig_size = raw.readCompactSize;
    ret.scriptSig = raw.readArray!ubyte(sig_size).dup;
    ret.nSequence = raw.read!uint;
    return ret;
}

public CTxOut readCTxOut (scope ref const(ubyte)[] raw)
{
    CTxOut ret;
    ret.nValue = raw.read!CAmount;
    ulong script_size = raw.readCompactSize;
    ret.scriptPubKey = raw.readArray!ubyte(script_size).dup;
    return ret;
}
