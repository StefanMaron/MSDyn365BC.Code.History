codeunit 5472 "Graph Mgt - Vendor"
{

    trigger OnRun()
    begin
    end;

    procedure PostalAddressToJSON(var Vendor: Record Vendor) JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        with Vendor do
            GraphMgtComplexTypes.GetPostalAddressJSON(Address, "Address 2", City, County, "Country/Region Code", "Post Code", JSON);
    end;

    procedure UpdatePostalAddress(PostalAddressJSON: Text; var Vendor: Record Vendor)
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if PostalAddressJSON = '' then
            exit;

        with Vendor do begin
            RecRef.GetTable(Vendor);
            GraphMgtComplexTypes.ApplyPostalAddressFromJSON(PostalAddressJSON, RecRef,
              FieldNo(Address), FieldNo("Address 2"), FieldNo(City), FieldNo(County), FieldNo("Country/Region Code"), FieldNo("Post Code"));
            RecRef.SetTable(Vendor);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIds();
    end;

    procedure UpdateIds()
    begin
        UpdateIds(false);
    end;

    procedure UpdateIds(WithCommit: Boolean)
    var
        Vendor: Record Vendor;
        APIDataUpgrade: Codeunit "API Data Upgrade";
        RecordCount: Integer;
    begin
        if not Vendor.FindSet(true, false) then
            exit;

        repeat
            Vendor.UpdateReferencedIds();
            Vendor.Modify(false);
            if WithCommit then
                APIDataUpgrade.CountRecordsAndCommit(RecordCount);
        until Vendor.Next() = 0;

        if WithCommit then
            Commit();
    end;

}

