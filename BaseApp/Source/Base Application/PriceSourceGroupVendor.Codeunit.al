codeunit 7014 "Price Source Group - Vendor" implements "Price Source Group"
{
    var
        PurchaseSourceType: Enum "Purchase Price Source Type";

    procedure IsSourceTypeSupported(SourceType: Enum "Price Source Type"): Boolean;
    var
        Ordinals: list of [Integer];
    begin
        Ordinals := PurchaseSourceType.Ordinals();
        exit(Ordinals.Contains(SourceType))
    end;

    procedure GetGroup() SourceGroup: Enum "Price Source Group";
    begin
        exit(SourceGroup::Vendor);
    end;
}