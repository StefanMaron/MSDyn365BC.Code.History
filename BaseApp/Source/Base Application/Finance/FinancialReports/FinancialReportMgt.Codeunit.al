namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.GeneralLedger.Account;
using System.Environment.Configuration;
using System.Environment;
using System.IO;
using System.Telemetry;

codeunit 18 "Financial Report Mgt."
{

    TableNo = "Financial Report";

    var
        FinRepPrefixTxt: Label 'FIN.REP.', MaxLength = 10, Comment = 'Part of the name for the confguration package, stands for Financial Report';
        TwoPosTxt: Label '%1%2', Locked = true;
        PackageNameTxt: Label 'Financial Report - %1', MaxLength = 40, Comment = '%1 - financial report name';
        PackageImportErr: Label 'The financial report could not be imported.';
        RowsEditWarningNotificationMsg: Label 'Changes to this row definition will affect all financial reports using it.';
        RowsNotificationIdTok: Label 'e6374e6b-dba0-43a0-9099-0ae20ee77f4b', Locked = true;
        ColumnsEditWarningNotificationMsg: Label 'Changes to this column definition will affect all financial reports using it.';
        ColumnsNotificationIdTok: Label '883e213e-08bd-4154-b929-87f689848f10', Locked = true;
        DontShowAgainMsg: Label 'Don''t show again';
        TelemetryEventTxt: Label 'Financial Report Definition %1: %2', Comment = '%1 = event type, %2 = report', Locked = true;
        OpenFinancialReportsLbl: Label 'Open Financial Reports';
        NotifyUpdateFinancialReportNameTxt: Label 'Notify about updating financial reports.';
        NotifyUpdateFinancialReportDescTxt: Label 'Notify that financial reports should be updated after someone creates a new G/L account.';
        UpdateFinancialReportMsg: Label 'You have created one or more G/L accounts and might need to update your financial reports. We recommend that you review your financial reports by choosing the Open Financial Reports action.';
        UpdateFinancialReportNotificationIdTok: Label 'cc02b894-bef8-4945-8042-f177422f8906', Locked = true;

    internal procedure LaunchEditRowsWarningNotification()
    var
        MyNotifications: Record "My Notifications";
        EditWarningNotification: Notification;
    begin
        if not MyNotifications.IsEnabled(RowsNotificationIdTok) then
            exit;
        EditWarningNotification.AddAction(DontShowAgainMsg, Codeunit::"Financial Report Mgt.", 'DisableRowsDefinitionNotification');
        EditWarningNotification.Message := RowsEditWarningNotificationMsg;
        EditWarningNotification.Scope := NotificationScope::LocalScope;
        EditWarningNotification.Send();
    end;

    internal procedure LaunchEditColumnsWarningNotification()
    var
        MyNotifications: Record "My Notifications";
        EditWarningNotification: Notification;
    begin
        if not MyNotifications.IsEnabled(ColumnsNotificationIdTok) then
            exit;
        EditWarningNotification.AddAction(DontShowAgainMsg, Codeunit::"Financial Report Mgt.", 'DisableColumnsDefinitionNotification');
        EditWarningNotification.Message := ColumnsEditWarningNotificationMsg;
        EditWarningNotification.Scope := NotificationScope::LocalScope;
        EditWarningNotification.Send();
    end;

    internal procedure DisableColumnsDefinitionNotification(WarningNotification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(ColumnsNotificationIdTok) then
            MyNotifications.InsertDefault(ColumnsNotificationIdTok, ColumnsEditWarningNotificationMsg, '', false);
    end;

    internal procedure DisableRowsDefinitionNotification(WarningNotification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(RowsNotificationIdTok) then
            MyNotifications.InsertDefault(RowsNotificationIdTok, RowsEditWarningNotificationMsg, '', false);
    end;

    procedure XMLExchangeExport(FinancialReport: Record "Financial Report")
    var
        ConfigPackage: Record "Config. Package";
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
    begin
        AddFinancialReportToConfigPackage(FinancialReport.Name, ConfigPackage);
        Commit();
        ConfigXMLExchange.ExportPackage(ConfigPackage);
        LogImportExportTelemetry(FinancialReport.Name, 'exported');
    end;

    local procedure AddFinancialReportToConfigPackage(FinancialReportName: Code[10]; var ConfigPackage: Record "Config. Package")
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigPackageField: Record "Config. Package Field";
        FinancialReport: Record "Financial Report";
        AccScheduleName: Record "Acc. Schedule Name";
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
        ConfigPackageManagement: Codeunit "Config. Package Management";
        PackageCode: Code[20];
        ColumnGroupCode: Code[10];
    begin
        FinancialReport.Get(FinancialReportName);
        AccScheduleName.Get(FinancialReport."Financial Report Row Group");
        PackageCode := StrSubstNo(TwoPosTxt, FinRepPrefixTxt, FinancialReport.Name);
        if ConfigPackage.Get(PackageCode) then
            ConfigPackage.Delete(true);
        ConfigPackageManagement.InsertPackage(ConfigPackage, PackageCode, StrSubstNo(PackageNameTxt, FinancialReport.Name), true);
        ConfigPackageManagement.InsertPackageTable(ConfigPackageTable, PackageCode, Database::"Financial Report");
        ConfigPackageManagement.InsertPackageFilter(ConfigPackageFilter, PackageCode, Database::"Financial Report", 0, FinancialReport.FieldNo(Name), FinancialReportName);
        AccScheduleName.AddRowDefinitionToConfigPackage(FinancialReport."Financial Report Row Group", ConfigPackage, PackageCode);
        if FinancialReport."Financial Report Column Group" <> '' then begin
            ColumnGroupCode := FinancialReport."Financial Report Column Group";
            ConfigPackageManagement.InsertPackageTable(ConfigPackageTable, PackageCode, Database::"Column Layout Name");
            ConfigPackageManagement.InsertPackageFilter(ConfigPackageFilter, PackageCode, Database::"Column Layout Name", 0, ColumnLayoutName.FieldNo(Name), ColumnGroupCode);
            ConfigPackageManagement.InsertPackageTable(ConfigPackageTable, PackageCode, Database::"Column Layout");
            ConfigPackageManagement.InsertPackageFilter(ConfigPackageFilter, PackageCode, Database::"Column Layout", 0, ColumnLayout.FieldNo("Column Layout Name"), ColumnGroupCode);
            if ConfigPackageField.Get(PackageCode, Database::"Column Layout Name", ColumnLayoutName.FieldNo("Analysis View Name")) then
                ConfigPackageField.Delete();
        end;
    end;

    procedure XMLExchangeImport(FinancialReport: Record "Financial Report")
    var
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        PackageCode: Code[20];
    begin
        if ConfigXMLExchange.ImportPackageXMLFromClient() then begin
            PackageCode := ConfigXMLExchange.GetImportedPackageCode();
            Commit();
            ApplyPackage(PackageCode);
        end;
    end;

    procedure ApplyPackage(PackageCode: Code[20])
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        NewName: Code[10];
    begin
        if not ConfigPackage.Get(PackageCode) then
            Error(PackageImportErr);

        NewName := GetPackageFinancialReportName(PackageCode);
        if NewName = '' then
            Error(PackageImportErr);

        ConfigPackageTable.SetRange("Package Code", PackageCode);
        ConfigPackageMgt.ApplyPackage(ConfigPackage, ConfigPackageTable, false);
        LogImportExportTelemetry(NewName, 'imported');
    end;

    local procedure GetPackageFinancialReportName(PackageCode: Code[20]) NewFinancialReportName: Code[10]
    var
        NewColumnLayoutName: Code[10];
        OldColumnLayoutName: Code[10];
        NewAccountScheduleName: Code[10];
        OldAccountScheduleName: Code[10];
        OldFinancialReportName: Code[10];
        AccScheduleExists: Boolean;
        ColumnLayoutExists: Boolean;
        FinancialReportExists: Boolean;
    begin
        NewFinancialReportName := GetFinancialReportName(PackageCode, FinancialReportExists);
        if NewFinancialReportName = '' then
            exit('');

        NewAccountScheduleName := GetAccountScheduleName(PackageCode, AccScheduleExists);
        if NewAccountScheduleName = '' then
            exit('');

        NewColumnLayoutName := GetColumnLayoutName(PackageCode, ColumnLayoutExists);
        if not FinancialReportExists and not AccScheduleExists and not ColumnLayoutExists then
            exit(NewFinancialReportName);

        OldFinancialReportName := NewFinancialReportName;
        OldAccountScheduleName := NewAccountScheduleName;
        OldColumnLayoutName := NewColumnLayoutName;
        if not GetNewFinancialReportName(NewFinancialReportName, NewAccountScheduleName, NewColumnLayoutName) then
            exit('');

        RenamePackageContents(PackageCode, OldFinancialReportName, NewFinancialReportName, OldAccountScheduleName, NewAccountScheduleName, OldColumnLayoutName, NewColumnLayoutName);
    end;

    local procedure GetNewFinancialReportName(var FinancialReportName: Code[10]; var AccScheduleName: Code[10]; var ColumnLayoutName: Code[10]): Boolean
    var
        NewFinancialReport: Page "New Financial Report";
    begin
        NewFinancialReport.Set(FinancialReportName, AccScheduleName, ColumnLayoutName);
        if NewFinancialReport.RunModal() = Action::OK then begin
            FinancialReportName := NewFinancialReport.GetFinancialReportName();
            AccScheduleName := NewFinancialReport.GetAccSchedName();
            ColumnLayoutName := NewFinancialReport.GetColumnLayoutName();
            exit(true);
        end;
        exit(false)
    end;

    local procedure RenamePackageContents(PackageCode: Code[20]; OldFinancialReportName: Code[10]; NewFinancialReportName: Code[10]; OldAccScheduleName: Code[10]; NewAccScheduleName: Code[10]; OldColumnLayoutName: Code[10]; NewColumnLayoutName: Code[10])
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        if (OldFinancialReportName = NewFinancialReportName) and (OldAccScheduleName = NewAccScheduleName) and (OldColumnLayoutName = NewColumnLayoutName) then
            exit;
        RenameFinancialReportInPackage(PackageCode, OldFinancialReportName, NewFinancialReportName, OldAccScheduleName, NewAccScheduleName, OldColumnLayoutName, NewColumnLayoutName);
        AccScheduleName.RenameAccountScheduleInPackage(PackageCode, OldAccScheduleName, NewAccScheduleName);
        RenameColumnLayoutInPackage(PackageCode, OldColumnLayoutName, NewColumnLayoutName);
    end;

    local procedure RenameFinancialReportInPackage(PackageCode: Code[20]; OldFinancialReportName: Code[10]; NewFinancialReportName: Code[10]; OldAccScheduleName: Code[10]; NewAccScheduleName: Code[10]; OldColumnLayoutName: Code[10]; NewColumnLayoutName: Code[10])
    var
        FinancialReport: Record "Financial Report";
        ConfigPackageData: Record "Config. Package Data";
    begin
        ConfigPackageData.SetLoadFields(Value);
        ConfigPackageData.SetRange("Package Code", PackageCode);

        if OldFinancialReportName <> NewFinancialReportName then begin
            ConfigPackageData.SetRange("Table ID", Database::"Financial Report");
            ConfigPackageData.SetRange("Field ID", FinancialReport.FieldNo(Name));
            ConfigPackageData.SetRange(Value, OldFinancialReportName);
            ConfigPackageData.ModifyAll(Value, NewFinancialReportName);
        end;

        if OldAccScheduleName <> NewAccScheduleName then begin
            ConfigPackageData.SetRange("Table ID", Database::"Financial Report");
            ConfigPackageData.SetRange("Field ID", FinancialReport.FieldNo("Financial Report Row Group"));
            ConfigPackageData.SetRange(Value, OldAccScheduleName);
            ConfigPackageData.ModifyAll(Value, NewAccScheduleName);
        end;

        if OldColumnLayoutName <> NewColumnLayoutName then begin
            ConfigPackageData.SetRange("Table ID", Database::"Financial Report");
            ConfigPackageData.SetRange("Field ID", FinancialReport.FieldNo("Financial Report Column Group"));
            ConfigPackageData.SetRange(Value, OldColumnLayoutName);
            ConfigPackageData.ModifyAll(Value, NewColumnLayoutName);
        end;
    end;

    internal procedure RenameColumnLayoutInPackage(PackageCode: Code[20]; OldName: Code[10]; NewName: Code[10])
    var
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
        ConfigPackageData: Record "Config. Package Data";
    begin
        if OldName = NewName then
            exit;

        ConfigPackageData.SetLoadFields(Value);
        ConfigPackageData.SetRange("Package Code", PackageCode);
        ConfigPackageData.SetRange(Value, OldName);

        ConfigPackageData.SetRange("Table ID", Database::"Column Layout Name");
        ConfigPackageData.SetRange("Field ID", ColumnLayoutName.FieldNo(Name));
        ConfigPackageData.ModifyAll(Value, NewName);

        ConfigPackageData.SetRange("Table ID", Database::"Column Layout");
        ConfigPackageData.SetRange("Field ID", ColumnLayout.FieldNo("Column Layout Name"));
        ConfigPackageData.ModifyAll(Value, NewName);
    end;

    local procedure GetFinancialReportName(PackageCode: Code[20]; var FinancialReportExists: Boolean) Name: Code[10]
    var
        FinancialReport: Record "Financial Report";
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageField: Record "Config. Package Field";
    begin
        FinancialReportExists := false;
        if not ConfigPackageField.Get(PackageCode, Database::"Financial Report", FinancialReport.FieldNo(Name)) then
            exit('');

        ConfigPackageData.SetLoadFields(Value);
        ConfigPackageData.SetRange("Package Code", PackageCode);
        ConfigPackageData.SetRange("Table ID", Database::"Financial Report");
        ConfigPackageData.SetRange("Field ID", FinancialReport.FieldNo(Name));
        if ConfigPackageData.FindFirst() then begin
            Name := CopyStr(ConfigPackageData.Value, 1, MaxStrLen(FinancialReport.Name));
            FinancialReportExists := FinancialReport.Get(Name);
        end;
    end;

    local procedure GetAccountScheduleName(PackageCode: Code[20]; var AccScheduleExists: Boolean) Name: Code[10]
    var
        AccScheduleName: Record "Acc. Schedule Name";
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageField: Record "Config. Package Field";
    begin
        AccScheduleExists := false;
        if not ConfigPackageField.Get(PackageCode, Database::"Acc. Schedule Name", AccScheduleName.FieldNo(Name)) then
            exit('');

        ConfigPackageData.SetLoadFields(Value);
        ConfigPackageData.SetRange("Package Code", PackageCode);
        ConfigPackageData.SetRange("Table ID", Database::"Acc. Schedule Name");
        ConfigPackageData.SetRange("Field ID", AccScheduleName.FieldNo(Name));
        if ConfigPackageData.FindFirst() then begin
            Name := CopyStr(ConfigPackageData.Value, 1, MaxStrLen(AccScheduleName.Name));
            AccScheduleExists := AccScheduleName.Get(Name);
        end;
    end;

    local procedure GetColumnLayoutName(PackageCode: Code[20]; var ColumnLayoutExists: Boolean) Name: Code[10]
    var
        ColumnLayoutName: Record "Column Layout Name";
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageField: Record "Config. Package Field";
    begin
        ColumnLayoutExists := false;
        if not ConfigPackageField.Get(PackageCode, Database::"Column Layout Name", ColumnLayoutName.FieldNo(Name)) then
            exit('');

        ConfigPackageData.SetLoadFields(Value);
        ConfigPackageData.SetRange("Package Code", PackageCode);
        ConfigPackageData.SetRange("Table ID", Database::"Column Layout Name");
        ConfigPackageData.SetRange("Field ID", ColumnLayoutName.FieldNo(Name));
        if ConfigPackageData.FindFirst() then begin
            Name := CopyStr(ConfigPackageData.Value, 1, MaxStrLen(ColumnLayoutName.Name));
            ColumnLayoutExists := ColumnLayoutName.Get(Name);
        end;
    end;

    procedure Print(FinancialReport: Record "Financial Report")
    var
        AccountSchedule: Report "Account Schedule";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrint(FinancialReport, IsHandled);
        if IsHandled then
            exit;

        AccountSchedule.SetFinancialReportName(FinancialReport.Name);
        AccountSchedule.Run();
    end;

    procedure LookupName(FinancialReportName: Code[10]; var EntrdSchedName: Text[10]): Boolean
    var
        FinancialReport: Record "Financial Report";
    begin
        if not FinancialReport.Get(FinancialReportName) then;

        if PAGE.RunModal(0, FinancialReport) <> ACTION::LookupOK then
            exit(false);

        EntrdSchedName := FinancialReport.Name;
        exit(true);
    end;

    procedure Initialize()
    var
        FinancialReport: Record "Financial Report";
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        if not FinancialReport.IsEmpty() then
            exit;
        if AccScheduleName.FindSet() then
            repeat
                CreateFinancialReportFromRowDefinition(AccScheduleName);
            until AccScheduleName.Next() = 0;
    end;

    local procedure CreateFinancialReportFromRowDefinition(AccScheduleName: Record "Acc. Schedule Name")
    var
        FinancialReport: Record "Financial Report";
    begin
        FinancialReport.Init();
        FinancialReport.Name := AccScheduleName.Name;
        FinancialReport.Description := AccScheduleName.Description;
        FinancialReport."Financial Report Row Group" := AccScheduleName.Name;
        FinancialReport.Insert();
    end;

    internal procedure NotifyUpdateFinancialReport(var GLAccount: Record "G/L Account")
    var
        MyNotification: Record "My Notifications";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        UpdateFinancialReportNotification: Notification;
    begin
        if not GuiAllowed() then
            exit;
        if GLAccount.IsTemporary() then
            exit;
        if not MyNotification.IsEnabled(GetUpdateFinancialReportNotificationId()) then
            exit;

        UpdateFinancialReportNotification.Id := GetUpdateFinancialReportNotificationId();
        UpdateFinancialReportNotification.Message := UpdateFinancialReportMsg;
        UpdateFinancialReportNotification.AddAction(
            OpenFinancialReportsLbl, Codeunit::"Financial Report Mgt.", 'OpenFinancialReports');
        UpdateFinancialReportNotification.AddAction(
            DontShowAgainMsg, Codeunit::"Financial Report Mgt.", 'HideUpdateFinancialReportNotification');
        NotificationLifecycleMgt.SendNotification(UpdateFinancialReportNotification, GLAccount.RecordId);
    end;

    procedure OpenFinancialReports(UpdateFinancialReportNotification: Notification)
    begin
        Page.Run(Page::"Financial Reports");
    end;

    procedure HideUpdateFinancialReportNotification(UpdateFinancialReportNotification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(UpdateFinancialReportNotification.Id) then
            MyNotifications.InsertDefault(UpdateFinancialReportNotification.Id,
                NotifyUpdateFinancialReportNameTxt, NotifyUpdateFinancialReportDescTxt, false);
    end;

    local procedure LogImportExportTelemetry(Name: Text; Action: Text)
    var
        EnvironmentInfo: Codeunit "Environment Information";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        if not EnvironmentInfo.IsSaaS() then
            exit;

        TelemetryDimensions.Add('ReportDefinitionCode', Name);
        FeatureTelemetry.LogUsage('0000ONR', 'Financial Report', StrSubstNo(TelemetryEventTxt, Name, Action), TelemetryDimensions);
    end;

    procedure GetUpdateFinancialReportNotificationId(): Guid
    begin
        exit(UpdateFinancialReportNotificationIdTok);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrint(var FinancialReport: Record "Financial Report"; var IsHandled: Boolean)
    begin
    end;
}