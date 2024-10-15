namespace System.Environment.Configuration;

using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.Reporting;

codeunit 5409 "Feature - Report Selection" implements "Feature Data Update"
{
    // The Data upgrade codeunit for Platform Based Report Selection
    var
        TempDocumentEntry: Record "Document Entry" temporary;
        FeatureDataUpdateMgt: Codeunit "Feature Data Update Mgt.";
        DescriptionTxt: Label 'If you enable platform based report selection, all user-added layouts from the Custom Report Layout table will be migrated to the Report Layouts table.';

    procedure IsDataUpdateRequired(): Boolean;
    begin
        // Data upgrade is not required if the Custom report layout table is empty.
        CountRecords();
        exit(not TempDocumentEntry.IsEmpty);
    end;

    procedure ReviewData()
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

    procedure UpdateData(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        CustomReportLayout: Record "Custom Report Layout";
        StartDateTime: DateTime;
    begin
        StartDateTime := CurrentDateTime;
        MigrateCustomReportLayouts();
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, CustomReportLayout.TableCaption(), StartDateTime);
    end;

    procedure GetTaskDescription() TaskDescription: Text;
    begin
        TaskDescription := DescriptionTxt;
    end;

    local procedure CountRecords()
    var
        CustomReportLayout: Record "Custom Report Layout";
    begin
        TempDocumentEntry.Reset();
        TempDocumentEntry.DeleteAll();
        CustomReportLayout.SetRange(CustomReportLayout."Built-In", false);
        InsertDocumentEntry(Database::"Custom Report Layout", CustomReportLayout.TableCaption(), CustomReportLayout.Count());
    end;

    local procedure MigrateCustomReportLayouts()
    var
        CustomReportLayout: Record "Custom Report Layout";
        TenantReportLayout: Record "Tenant Report Layout";
        InStreamLayout: Instream;
        CustomReportLayoutTok: Label 'CRL';
    begin
        CustomReportLayout.SetRange("Built-In", false);
        if CustomReportLayout.FindSet() then
            repeat
                TenantReportLayout.Init();
                CustomReportLayout.Layout.CreateInStream(InStreamLayout);
                TenantReportLayout.Layout.ImportStream(InStreamLayout, CustomReportLayout.Description);

                TenantReportLayout."Report ID" := CustomReportLayout."Report ID";
                TenantReportLayout.Name := CustomReportLayout.Code + '-' + CustomReportLayoutTok;
                TenantReportLayout.Description := CustomReportLayout.Description;
                TenantReportLayout."Company Name" := CustomReportLayout."Company Name";

                // Assign the Layout-Format.
                case CustomReportLayout.Type of
                    CustomReportLayout.Type::RDLC:
                        TenantReportLayout."Layout Format" := TenantReportLayout."Layout Format"::RDLC;
                    CustomReportLayout.Type::Word:
                        TenantReportLayout."Layout Format" := TenantReportLayout."Layout Format"::Word
                    else
                        TenantReportLayout."Layout Format" := TenantReportLayout."Layout Format"::Custom;
                end;

                // Assign the File-Format if the layout format is 'Custom'/'External' (UI)
                if (CustomReportLayout."File Extension" <> '') and (TenantReportLayout."Layout Format" = TenantReportLayout."Layout Format"::Custom) then
                    TenantReportLayout."MIME Type" := 'reportlayout/' + CustomReportLayout."File Extension";

                if TenantReportLayout.Insert() then; // Might have been added earlier
            until (CustomReportLayout.Next() = 0);
    end;

    local procedure InsertDocumentEntry(TableID: Integer; TableName: Text; RecordCount: Integer)
    begin
        if RecordCount = 0 then
            exit;
        TempDocumentEntry.Init();
        TempDocumentEntry."Entry No." += 1;
        TempDocumentEntry."Table ID" := TableID;
        TempDocumentEntry."Table Name" := CopyStr(TableName, 1, MaxStrLen(TempDocumentEntry."Table Name"));
        TempDocumentEntry."No. of Records" := RecordCount;
        TempDocumentEntry.Insert();
    end;
}