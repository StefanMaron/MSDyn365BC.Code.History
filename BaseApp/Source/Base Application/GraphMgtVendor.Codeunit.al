codeunit 5472 "Graph Mgt - Vendor"
{

    trigger OnRun()
    begin
    end;

    procedure PostalAddressToJSON(Vendor: Record Vendor) JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        with Vendor do
            GraphMgtComplexTypes.GetPostalAddressJSON(Address, "Address 2", City, County, "Country/Region Code", "Post Code", JSON);
    end;

    procedure UpdateIntegrationRecords(OnlyVendorsWithoutId: Boolean)
    var
        DummyVendor: Record Vendor;
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        VendorRecordRef: RecordRef;
    begin
        VendorRecordRef.Open(DATABASE::Vendor);
        GraphMgtGeneralTools.UpdateIntegrationRecords(VendorRecordRef, DummyVendor.FieldNo(Id), OnlyVendorsWithoutId);
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

    [EventSubscriber(ObjectType::Codeunit, 5465, 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIntegrationRecords(false);
        UpdateIds;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5150, 'OnUpdateRelatedRecordIdFields', '', false, false)]
    local procedure HandleUpdateRelatedRecordIdFields(var RecRef: RecordRef)
    var
        Vendor: Record Vendor;
        TempField: Record "Field" temporary;
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        UpdatedRecRef: RecordRef;
    begin
        if not (RecRef.Number = DATABASE::Vendor) then
            exit;

        if RecRef.IsTemporary then
            exit;

        RecRef.SetTable(Vendor);
        Vendor.UpdateReferencedIds;

        UpdatedRecRef.GetTable(Vendor);
        Vendor.GetReferencedIds(TempField);
        GraphMgtGeneralTools.TransferRelatedRecordIntegrationIDs(RecRef, UpdatedRecRef, TempField);
    end;

    procedure UpdateIds()
    var
        Vendor: Record Vendor;
    begin
        if not Vendor.FindSet(true, false) then
            exit;

        repeat
            Vendor.UpdateReferencedIds;
            Vendor.Modify(false);
        until Vendor.Next = 0;
    end;
}

