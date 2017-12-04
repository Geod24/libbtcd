/*******************************************************************************

    A binary blob implementation, used as base for hash types

    Data is stored in little endian, internally.

    This module also defines the widely used `uint160`, `uint256` and
    `Hash` types.

*******************************************************************************/

module libbtc.BitBlob;

static import std.ascii;
import std.algorithm;
import std.range;
import std.stdio;
import std.string;
import std.utf;

version (unittest) import libbtc.TestData;

/// Ditto
public struct BitBlob (size_t Bits)
{
    // retro for BigEndian / LittleEndian
    import std.range;

    /// Used by std.format
    public void toString (scope void delegate(const(char)[]) sink) const
    {
        sink("0x");
        char[2] data;
        // retro because the data is stored in little endian
        this.data[].retro.each!(
            (bin)
            {
                sformat(data, "%0.2x", bin);
                sink(data);
            });
    }

    pure nothrow @nogc @safe:

    /***************************************************************************

        Create a BitBlob from binary data, e.g. serialized data

        Params:
            bin  = Binary data to store in this `BitBlob`.
            isLE = `true` if the data is little endian, `false` otherwise.
                   Internally the data will be stored in little endian.

        Throws:
            If `bin.length != typeof(this).Width`

    ***************************************************************************/

    public this (in ubyte[] bin, bool isLE = true)
    {
        assert(bin.length == Width);
        this.data[] = bin[];
        if (!isLE)
            this.data[].reverse;
    }

    /***************************************************************************

        Create a BitBlob from an hexadecimal string representation

        Params:
            hexstr = String representation of the binary data in base 16.
                     The hexadecimal prefix (0x) is optional.
                     Can be upper or lower case.

        Throws:
            If `hexstr_without_prefix.length != (typeof(this).Width * 2)`.

    ***************************************************************************/

    public this (const(char)[] hexstr)
    {
        assert(hexstr.length == (Width * 2)
               || hexstr.length == (Width * 2) + "0x".length);

        auto range = hexstr.byChar.map!(std.ascii.toLower!(char));
        range.skipOver("0x".byChar);
        // Each doesn't work
        foreach (size_t idx, chunk; range.map!(fromHex).chunks(2).retro.enumerate)
            this.data[idx] = cast(ubyte)((chunk[0] << 4) + chunk[1]);
    }

    static assert (
        Bits % 8 == 0,
        "Argument to BitBlob must be a multiple of 8");

    /// The width of this aggregate, in octets
    public static immutable Width = Bits / 8;

    /// Store the internal data
    private ubyte[Width] data;

    /// Returns: If this BitBlob has any value
    public bool isNull () const
    {
        return this.data[].all!((v) => v == 0);
    }

    /// Public because of a visibility bug
    public static ubyte fromHex (char c)
    {
        if (c >= '0' && c <= '9')
            return cast(ubyte)(c - '0');
        if (c >= 'a' && c <= 'f')
            return cast(ubyte)(10 + c - 'a');
        assert(0, "Unexpected char in string passed to uint256");
    }
}

/// 160 bits opaque blob, used for RIPEMD160
public alias uint160 = BitBlob!160;

/// 256 bits opaque blob, used for hashs
public alias uint256 = BitBlob!256;

/// The standard hash type used in Bitcoin
public alias Hash = uint256;

pure @safe nothrow @nogc unittest
{
    static immutable GMerkle_str =
        "0X4A5E1E4BAAB89F3A32518A88C31BC87F618F76673E2CC77AB2127B7AFDEDA33B";

    static immutable ubyte[] GMerkle_bin = GenesisBlockHeader[36 .. 68];
    uint256 gen1 = GenesisBlockHashStr;
    uint256 gen2 = GenesisBlockHash;
    assert(gen1.data == GenesisBlockHash);
    assert(gen1 == gen2);

    uint256 gm1 = GMerkle_str;
    uint256 gm2 = GMerkle_bin;
    assert(gm1.data == GMerkle_bin);
    assert(gm1 == gm2);

    uint256 empty;
    assert(empty.isNull);
    assert(!gen1.isNull);
}

/// Test toString
unittest
{
    import std.format;
    uint256 gen1 = GenesisBlockHashStr;
    assert(format("%s", gen1) == GenesisBlockHashStr);
}
