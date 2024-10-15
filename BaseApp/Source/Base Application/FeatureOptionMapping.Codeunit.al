#if not CLEAN22
namespace System.Environment.Configuration;

using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;
using Microsoft.Foundation.Navigate;
using Microsoft.Integration.D365Sales;

codeunit 5408 "Feature - Option Mapping" implements "Feature Data Update"
{
    ObsoleteReason = 'Feature OptionMapping will be enabled by default in version 22.0.';
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';

    procedure IsDataUpdateRequired(): Boolean;
    begin
        CountRecords();
        exit(not TempDocumentEntry.IsEmpty);
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
        CRMOptionMapping: Record "CRM Option Mapping";
        TempIntegrationFieldMapping: Record "Integration Field Mapping" temporary;
        StartDateTime: DateTime;
    begin
        StartDateTime := CurrentDateTime;
        AdjustCRMConnectionSetup();
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, TempIntegrationFieldMapping.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, CRMOptionMapping.TableCaption(), StartDateTime);
    end;

    procedure GetTaskDescription() TaskDescription: Text;
    begin
        TaskDescription := DescriptionTxt;
    end;

    var
        TempDocumentEntry: Record "Document Entry" temporary;
        FeatureDataUpdateMgt: Codeunit "Feature Data Update Mgt.";
        LastEntryNo: Integer;
        DescriptionTxt: Label 'Update the option mapping for Payment Terms, Shipment Methods and Shipping Agent to synchronize without the need of extending enums.';

    local procedure CountRecords()
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        TempIntegrationFieldMapping: Record "Integration Field Mapping" temporary;
    begin
        TempDocumentEntry.Reset();
        TempDocumentEntry.DeleteAll();

        TempIntegrationFieldMapping.SetFilter("Integration Table Mapping Name", 'CUSTOMER|VENDOR|PAYMENT TERMS|SHIPMENT METHOD|SHIPPING AGENT');
        TempIntegrationFieldMapping.SetFilter("Field No.", '15|75|80');
        InsertDocumentEntry(Database::"CRM Option Mapping", TempIntegrationFieldMapping.TableCaption(), TempIntegrationFieldMapping.CountApprox);
        InsertDocumentEntry(Database::"CRM Option Mapping", CRMOptionMapping.TableCaption(), CRMOptionMapping.Count());
    end;

    local procedure AdjustCRMConnectionSetup()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        CDSFailedOptionMapping: Record "CDS Failed Option Mapping";
        CRMAccount: Record "CRM Account";
        CRMInvoice: Record "CRM Invoice";
        CRMSalesorder: Record "CRM Salesorder";
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
    begin
        CDSSetupDefaults.ResetOptionMappingConfiguration();

        //Payment Terms
        IntegrationFieldMapping.SetFilter("Integration Table Mapping Name", 'CUSTOMER|VENDOR|PAYMENT TERMS');
        IntegrationFieldMapping.SetRange("Integration Table Field No.", 15);
        if not IntegrationFieldMapping.IsEmpty() then
            IntegrationFieldMapping.ModifyAll("Integration Table Field No.", CRMAccount.FieldNo(PaymentTermsCodeEnum));

        IntegrationFieldMapping.Reset();
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", 'POSTEDSALESINV-INV');
        IntegrationFieldMapping.SetRange("Integration Table Field No.", 24);
        if not IntegrationFieldMapping.IsEmpty() then
            IntegrationFieldMapping.ModifyAll("Integration Table Field No.", CRMInvoice.FieldNo(PaymentTermsCodeEnum));

        IntegrationFieldMapping.Reset();
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", 'SALESORDER-ORDER');
        IntegrationFieldMapping.SetRange("Integration Table Field No.", 28);
        if not IntegrationFieldMapping.IsEmpty() then
            IntegrationFieldMapping.ModifyAll("Integration Table Field No.", CRMSalesorder.FieldNo(PaymentTermsCodeEnum));

        //Shipment Method
        IntegrationFieldMapping.Reset();
        IntegrationFieldMapping.SetFilter("Integration Table Mapping Name", 'CUSTOMER|VENDOR|SHIPMENT METHOD');
        IntegrationFieldMapping.SetRange("Integration Table Field No.", 75);
        if not IntegrationFieldMapping.IsEmpty() then
            IntegrationFieldMapping.ModifyAll("Integration Table Field No.", CRMAccount.FieldNo(Address1_FreightTermsCodeEnum));

        //Shipping Agent
        IntegrationFieldMapping.Reset();
        IntegrationFieldMapping.SetFilter("Integration Table Mapping Name", 'CUSTOMER|VENDOR|SHIPPING AGENT');
        IntegrationFieldMapping.SetRange("Integration Table Field No.", 80);
        if not IntegrationFieldMapping.IsEmpty() then
            IntegrationFieldMapping.ModifyAll("Integration Table Field No.", CRMAccount.FieldNo(Address1_ShippingMethodCodeEnum));

        IntegrationFieldMapping.Reset();
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", 'POSTEDSALESINV-INV');
        IntegrationFieldMapping.SetRange("Integration Table Field No.", 23);
        if not IntegrationFieldMapping.IsEmpty() then
            IntegrationFieldMapping.ModifyAll("Integration Table Field No.", CRMInvoice.FieldNo(ShippingMethodCodeEnum));

        IntegrationFieldMapping.Reset();
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", 'SALESORDER-ORDER');
        IntegrationFieldMapping.SetRange("Integration Table Field No.", 27);
        if not IntegrationFieldMapping.IsEmpty() then
            IntegrationFieldMapping.ModifyAll("Integration Table Field No.", CRMSalesorder.FieldNo(ShippingMethodCodeEnum));

        if IntegrationTableMapping.Get('CUSTOMER') then begin
            IntegrationTableMapping."Dependency Filter" += '|PAYMENT TERMS|SHIPMENT METHOD|SHIPPING AGENT';
            IntegrationTableMapping.Modify();
        end;

        if IntegrationTableMapping.Get('VENDOR') then begin
            IntegrationTableMapping."Dependency Filter" += '|PAYMENT TERMS|SHIPMENT METHOD|SHIPPING AGENT';
            IntegrationTableMapping.Modify();
        end;

        CDSFailedOptionMapping.DeleteAll();
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