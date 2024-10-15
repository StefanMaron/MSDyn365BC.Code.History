codeunit 5471 "Graph Mgt - Customer"
{

    trigger OnRun()
    begin
    end;

    procedure PostalAddressToJSON(var Customer: Record Customer) JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        with Customer do
            GraphMgtComplexTypes.GetPostalAddressJSON(Address, "Address 2", City, County, "Country/Region Code", "Post Code", JSON);
    end;

    [Obsolete('Integration Records will be replaced by SystemID and SystemModifiedAt ', '17.0')]
    procedure UpdateIntegrationRecords(OnlyCustomersWithoutId: Boolean)
    var
        DummyCustomer: Record Customer;
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        CustomerRecordRef: RecordRef;
    begin
        CustomerRecordRef.Open(DATABASE::Customer);
        GraphMgtGeneralTools.UpdateIntegrationRecords(CustomerRecordRef, DummyCustomer.FieldNo(SystemId), OnlyCustomersWithoutId);
    end;

    procedure UpdatePostalAddress(PostalAddressJSON: Text; var Customer: Record Customer)
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if PostalAddressJSON = '' then
            exit;

        with Customer do begin
            RecRef.GetTable(Customer);
            GraphMgtComplexTypes.ApplyPostalAddressFromJSON(PostalAddressJSON, RecRef,
              FieldNo(Address), FieldNo("Address 2"), FieldNo(City), FieldNo(County), FieldNo("Country/Region Code"), FieldNo("Post Code"));
            RecRef.SetTable(Customer);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIntegrationRecords(false);
        UpdateIds;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Management", 'OnUpdateRelatedRecordIdFields', '', false, false)]
    local procedure HandleUpdateRelatedRecordIdFields(var RecRef: RecordRef)
    var
        Customer: Record Customer;
        TempField: Record "Field" temporary;
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        UpdatedRecRef: RecordRef;
    begin
        if not (RecRef.Number = DATABASE::Customer) then
            exit;

        if RecRef.IsTemporary then
            exit;

        RecRef.SetTable(Customer);
        Customer.UpdateReferencedIds;

        UpdatedRecRef.GetTable(Customer);
        Customer.GetReferencedIds(TempField);
        GraphMgtGeneralTools.TransferRelatedRecordIntegrationIDs(RecRef, UpdatedRecRef, TempField);
    end;

    procedure UpdateIds()
    begin
        UpdateIds(false);
    end;

    procedure UpdateIds(WithCommit: Boolean)
    var
        Customer: Record Customer;
        APIDataUpgrade: Codeunit "API Data Upgrade";
        RecordCount: Integer;
    begin
        if not Customer.FindSet(true, false) then
            exit;

        repeat
            Customer.UpdateReferencedIds;
            Customer.Modify(false);
            if WithCommit then
                APIDataUpgrade.CountRecordsAndCommit(RecordCount);
        until Customer.Next() = 0;

        if WithCommit then
            Commit();
    end;
}

