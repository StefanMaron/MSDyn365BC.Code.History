codeunit 883 "OCR Master Data Mgt."
{

    trigger OnRun()
    begin
    end;

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
                if not IntegrationRecord.Get(Vendor.Id) then begin
                    VendorRecordRef.GetTable(Vendor);
                    IntegrationManagement.InsertUpdateIntegrationRecord(VendorRecordRef, CurrentDateTime);
                    if IsNullGuid(Format(Vendor.Id)) then begin
                        UpdatedIntegrationRecord.SetRange("Record ID", Vendor.RecordId);
                        UpdatedIntegrationRecord.FindFirst;
                        Vendor.Id := IntegrationManagement.GetIdWithoutBrackets(UpdatedIntegrationRecord."Integration ID");
                    end;
                    Vendor.Modify(false);
                end;
            until Vendor.Next = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5150, 'OnGetIntegrationActivated', '', false, false)]
    local procedure OnGetIntegrationActivated(var IsSyncEnabled: Boolean)
    var
        ReadSoftOCRMasterDataSync: Codeunit "ReadSoft OCR Master Data Sync";
    begin
        if IsSyncEnabled then
            exit;

        IsSyncEnabled := ReadSoftOCRMasterDataSync.IsSyncEnabled;
    end;
}

