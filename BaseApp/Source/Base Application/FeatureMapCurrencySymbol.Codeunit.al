#if not CLEAN22
namespace System.Environment.Configuration;

using Microsoft.Finance.Currency;
using Microsoft.Foundation.Navigate;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.D365Sales;
using Microsoft.Integration.SyncEngine;

codeunit 5405 "Feature Map Currency Symbol" implements "Feature Data Update"
{
    ObsoleteReason = 'Feature CurrencySymbolMapping will be enabled by default in version 22.0.';
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';

    procedure IsDataUpdateRequired(): Boolean;
    begin
        CountRecords();
        exit(not TempDocumentEntry.IsEmpty());
    end;

    procedure ReviewData();
    var
        DataUpgradeOverview: Page "Data Upgrade Overview";
    begin
        Commit();
        Clear(DataUpgradeOverview);
        DataUpgradeOverview.Set(TempDocumentEntry);
        DataUpgradeOverview.RunModal();
    end;

    procedure AfterUpdate(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    begin
    end;

    procedure UpdateData(FeatureDataUpdateStatus: Record "Feature Data Update Status");
    var
        TempIntegrationFieldMapping: Record "Integration Field Mapping" temporary;
        StartDateTime: DateTime;
    begin
        StartDateTime := CurrentDateTime;
        UpdateCurrencySymbolFieldMapping();
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, TempIntegrationFieldMapping.TableCaption(), StartDateTime);
    end;

    procedure GetTaskDescription() TaskDescription: Text;
    begin
        TaskDescription := DescriptionTxt;
    end;

    var
        TempDocumentEntry: Record "Document Entry" temporary;
        FeatureDataUpdateMgt: Codeunit "Feature Data Update Mgt.";
        LastEntryNo: Integer;
        DescriptionTxt: Label 'Update the field mapping for currencies in Business Central and Dataverse to be symbol to symbol instead of code to symbol.';

    local procedure CountRecords()
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        TempDocumentEntry.Reset();
        TempDocumentEntry.DeleteAll();
        if FindCurrencySymbolFieldMapping(IntegrationFieldMapping) then
            InsertDocumentEntry(Database::"Integration Field Mapping", IntegrationFieldMapping.TableCaption(), 1);
    end;

    local procedure UpdateCurrencySymbolFieldMapping()
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
        TempCurrency: Record Currency temporary;
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
    begin
        if not CDSIntegrationMgt.IsIntegrationEnabled() then
            if not CRMIntegrationManagement.IsIntegrationEnabled() then
                exit;

        if not FindCurrencySymbolFieldMapping(IntegrationFieldMapping) then
            exit;

        IntegrationFieldMapping."Field No." := TempCurrency.FieldNo(Symbol);
        IntegrationFieldMapping.Modify();
    end;

    local procedure FindCurrencySymbolFieldMapping(var IntegrationFieldMapping: Record "Integration Field Mapping"): Boolean
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        TempCurrency: Record Currency temporary;
        TempCRMTransactionCurrency: Record "CRM Transactioncurrency" temporary;
    begin
        if not IntegrationTableMapping.FindMapping(Database::Currency, Database::"CRM Transactioncurrency") then
            exit;

        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
        IntegrationFieldMapping.SetRange("Field No.", TempCurrency.FieldNo(Code));
        IntegrationFieldMapping.SetRange("Integration Table Field No.", TempCRMTransactionCurrency.FieldNo(CurrencySymbol));
        exit(IntegrationFieldMapping.FindFirst());
    end;

    local procedure InsertDocumentEntry(TableID: Integer; TableName: Text; RecordCount: Integer)
    begin
        if RecordCount = 0 then
            exit;

        LastEntryNo += 1;
        TempDocumentEntry.Init();
        TempDocumentEntry."Entry No." := LastEntryNo;
        TempDocumentEntry."Table ID" := TableID;
        TempDocumentEntry."Table Name" := CopyStr(TableName, 1, MaxStrLen(TempDocumentEntry."Table Name"));
        TempDocumentEntry."No. of Records" := RecordCount;
        TempDocumentEntry.Insert();
    end;
}
#endif