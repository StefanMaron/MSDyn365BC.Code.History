codeunit 883 "OCR Master Data Mgt."
{

    trigger OnRun()
    begin
    end;

    [Obsolete('Integration Records will be replaced by SystemID and SystemLastDateTimeModified', '17.0')]
    procedure UpdateIntegrationRecords(OnlyRecordsWithoutID: Boolean)
    var
        IntegrationRecord: Record "Integration Record";
        UpdatedIntegrationRecord: Record "Integration Record";
        Vendor: Record Vendor;
        IntegrationManagement: Codeunit "Integration Management";
        VendorRecordRef: RecordRef;
        NullGuid: Guid;
    begin
        if not IntegrationManagement.IsIntegrationActivated then
            exit;

        if OnlyRecordsWithoutID then
            Vendor.SetRange(Id, NullGuid);

        if Vendor.FindSet then
            repeat
                if not IntegrationRecord.Get(Vendor.SystemId) then begin
                    VendorRecordRef.GetTable(Vendor);
                    IntegrationManagement.InsertUpdateIntegrationRecord(VendorRecordRef, CurrentDateTime);
                    if IsNullGuid(Format(Vendor.SystemId)) then begin
                        UpdatedIntegrationRecord.SetRange("Record ID", Vendor.RecordId);
                        UpdatedIntegrationRecord.FindFirst;
                        Vendor.SystemId := IntegrationManagement.GetIdWithoutBrackets(UpdatedIntegrationRecord."Integration ID");
                    end;
                    Vendor.Modify(false);
                end;
            until Vendor.Next = 0;
    end;
}

