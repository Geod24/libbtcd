/*******************************************************************************

    Utilities to (de)serialize blocks & transactions

    This module loosely follows the original client's pattern by providing
    a stream-like approach by default. Whenever a function is called, data is
    consumed from the input.

*******************************************************************************/

module libbtc.Serialization;

import std.exception;


/*******************************************************************************

    Read a data of size `T.sizeof` from the stream

    Performs validation so unsafe data can be passed along

    Params:
        T = A PoD type, either primitive (`uint`, `ubyte`...),
            or a struct with no indirection (e.g. a `Hash` or `BitBlob`).
        raw = Raw data received

    Throws:
        If `raw.length < T.sizeof`

    Returns:
        The requested type

*******************************************************************************/

public T read (T) (scope ref const(ubyte)[] raw)
{
    enforce(raw.length >= T.sizeof, "Not enough data to read");
    auto ptr = (cast(const T*)raw.ptr);
    raw = raw[T.sizeof .. $];
    return *ptr;
}

/// Ditto, except it reads an array of lvalues
public const(T)[] readArray (T) (scope ref const(ubyte)[] raw, size_t count)
{
    enforce(raw.length >= (T.sizeof * count), "Not enough data to read");
    auto ptr = (cast(const T*)raw.ptr);
    raw = raw[T.sizeof * count .. $];
    return ptr[0 .. count];
}


/*******************************************************************************

    Reads a 'compact' size from the stream

    See `sizeOfSize` for more details about compact size encoding.

    Throws:
        If there is insufficient data.

*******************************************************************************/

public ulong readCompactSize (scope ref const(ubyte)[] raw)
{
    auto v = raw.read!ubyte;
    auto cs = sizeOfSize(v);
    enforce(raw.length >= cs);
    switch (cs)
    {
    case 1:
        return v;
    case 2:
        return raw.read!ushort;
    case 4:
        return raw.read!uint;
    case 8:
        return raw.read!ulong;
    default:
        assert(0, "Unreachable unless sizeOfSize is completely broken");
    }
}

/*******************************************************************************

    Tell how large the 'size' prefix to a vector is, in bytes

    When (de)serializing an `std::vector`, the first value written is the
    number of entries in the vector.
    For small vectors (< 253) only one byte is used. Over that, the first byte
    is used to encode the size.

    Params:
        firstSizeByte = The first byte of the serialized vector, the only one
                        safe to read at that point.

    Returns:
        `1`, `2`, `4` or `8`

*******************************************************************************/

public size_t sizeOfSize (ubyte firstSizeByte)
{
    if (firstSizeByte < 253)
        return ubyte.sizeof; // 1
    else if (firstSizeByte == 253)
        return ushort.sizeof; // 2
    else if (firstSizeByte == 254)
        return uint.sizeof; // 4
    else
        return ulong.sizeof; // 8
}
