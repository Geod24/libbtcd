/*******************************************************************************

    Definition of a bitcoin transaction

*******************************************************************************/

module libbtc.Transaction;

import libbtc.BitBlob;

/// A combination of a transaction hash and an index into its output
struct COutPoint
{
    /// The hash of a previous transaction
    uint256 hash;
    /// An index into the previous transaction vin
    uint index;

    /// Pretty formatting
    public void toString (scope void delegate (const(char)[]) sink)
    {
        import std.format;
        formattedWrite(sink, "%s:%d", this.hash, this.index);
    }
}

/// Default allocated to 28 in BTC
public alias CScript = ubyte[];

public struct CTxIn
{
    COutPoint prevout;
    CScript scriptSig;
    uint nSequence = SEQUENCE_FINAL;
    //CScriptWitness scriptWitness; //! Only serialized through CTransaction

    /* Setting nSequence to this value for every input in a transaction
     * disables nLockTime. */
    static immutable uint SEQUENCE_FINAL = 0xffffffff;

    /* Below flags apply in the context of BIP 68*/
    /* If this flag set, CTxIn::nSequence is NOT interpreted as a
     * relative lock-time. */
    static immutable uint SEQUENCE_LOCKTIME_DISABLE_FLAG = (1 << 31);

    /* If CTxIn::nSequence encodes a relative lock-time and this flag
     * is set, the relative lock-time has units of 512 seconds,
     * otherwise it specifies blocks with a granularity of 1. */
    static immutable uint SEQUENCE_LOCKTIME_TYPE_FLAG = (1 << 22);

    /* If CTxIn::nSequence encodes a relative lock-time, this mask is
     * applied to extract that lock-time from the sequence field. */
    static immutable uint SEQUENCE_LOCKTIME_MASK = 0x0000ffff;

    /* In order to use the same number of bits to encode roughly the
     * same wall-clock duration, and because blocks are naturally
     * limited to occur every 600s on average, the minimum granularity
     * for time-based relative lock-time is fixed at 512 seconds.
     * Converting from CTxIn::nSequence to seconds is performed by
     * multiplying by 512 = 2^9, or equivalently shifting up by
     * 9 bits. */
    static immutable uint SEQUENCE_LOCKTIME_GRANULARITY = 9;

    /// Pretty formatting
    public void toString (scope void delegate (const(char)[]) sink)
    {
        import std.format;
        formattedWrite(
            sink, "Prev: %s, Signature: %d bytes, Sequence: %X",
            this.prevout, this.scriptSig.length, this.nSequence);
    }
}

/// Amount in Satoshis, can be negative
alias CAmount = long;

immutable CAmount COIN = 100_000_000;
immutable CAmount CENT = 1_000_000;

/** No amount larger than this (in satoshi) is valid.
 *
 * Note that this constant is *not* the total money supply, which in Bitcoin
 * currently happens to be less than 21,000,000 BTC for various reasons, but
 * rather a sanity check. As this sanity check is used by consensus-critical
 * validation code, the exact value of the MAX_MONEY constant is consensus
 * critical; in unusual circumstances like a(nother) overflow bug that allowed
 * for the creation of coins out of thin air modification could lead to a fork.
 * */
immutable CAmount MAX_MONEY = 21_000_000 * COIN;
bool moneyRange (CAmount nValue) { return (nValue >= 0 && nValue <= MAX_MONEY); }

/*******************************************************************************

    Transaction that is broadcasted on the network and contained in  blocks.

    A transaction can contain multiple inputs and outputs.

*******************************************************************************/

public struct Transaction
{
    // Default transaction version.
    static immutable uint CURRENT_VERSION = 2;

    // Changing the default transaction version requires a two step process: first
    // adapting relay policy by bumping MAX_STANDARD_VERSION, and then later date
    // bumping the default CURRENT_VERSION at which point both CURRENT_VERSION and
    // MAX_STANDARD_VERSION will be equal.
    static immutable uint MAX_STANDARD_VERSION = 2;

    // The local variables are made const to prevent unintended modification
    // without updating the cached hash value. However, CTransaction is not
    // actually immutable; deserialization and assignment are implemented,
    // and bypass the constness. This is safe, as they update the entire
    // structure, including the hash.
    CTxIn[] vin;
    CTxOut[] vout;
    uint nVersion;
    uint nLockTime;
}

public struct CTxOut
{
    CAmount nValue;
    CScript scriptPubKey;

    /// Pretty formatting
    public void toString (scope void delegate (const(char)[]) sink)
    {
        import std.format;
        formattedWrite(
            sink, "Amount: %d.%d BTC, Pubkey: %d bytes",
            this.nValue / COIN, this.nValue % COIN, this.scriptPubKey.length);
    }
}
