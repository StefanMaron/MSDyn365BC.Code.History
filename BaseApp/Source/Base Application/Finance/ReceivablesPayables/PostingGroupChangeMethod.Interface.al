namespace Microsoft.Finance.ReceivablesPayables;

interface "Posting Group Change Method"
{
    /// <summary>
    /// The method fills the Price Asset parameter with "Asset No." and other data from the asset defined in the implementation codeunit. 
    /// </summary>
    /// <param name="PriceAsset">the record gets filled with data</param>
    procedure ChangePostingGroup(OldPostingGroup: Code[20]; NewPostingGroupCode: Code[20]; SourceRecordVar: Variant)
}