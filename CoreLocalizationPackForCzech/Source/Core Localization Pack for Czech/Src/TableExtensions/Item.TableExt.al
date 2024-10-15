tableextension 11745 "Item CZL" extends Item
{
    fields
    {
        field(31066; "Statistic Indication CZL"; Code[10])
        {
            Caption = 'Statistic Indication';
            TableRelation = "Statistic Indication CZL".Code WHERE("Tariff No." = FIELD("Tariff No."));
            DataClassification = CustomerContent;
        }
    }
    procedure CheckOpenItemLedgerEntriesCZL()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ChangeErr: Label ' cannot be changed';
    begin
        ItemLedgerEntry.SetCurrentKey("Item No.", Open);
        ItemLedgerEntry.SetRange("Item No.", "No.");
        ItemLedgerEntry.SetRange(Open, true);
        if not ItemLedgerEntry.IsEmpty() then
            FieldError("Inventory Posting Group", ChangeErr);

        ItemLedgerEntry.SetRange(Open);
        ItemLedgerEntry.SetRange("Completely Invoiced", false);
        if not ItemLedgerEntry.IsEmpty() then
            FieldError("Inventory Posting Group", ChangeErr);
    end;
}