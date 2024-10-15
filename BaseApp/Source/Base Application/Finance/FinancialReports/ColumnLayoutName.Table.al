namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.Analysis;
using System.IO;

table 333 "Column Layout Name"
{
    Caption = 'Column Layout Name';
    DataCaptionFields = Name, Description;
    LookupPageID = "Column Layout Names";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(4; "Analysis View Name"; Code[10])
        {
            Caption = 'Analysis View Name';
            TableRelation = "Analysis View";
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Name, Description, "Analysis View Name")
        {
        }
    }

    trigger OnDelete()
    begin
        ColumnLayout.SetRange("Column Layout Name", Name);
        ColumnLayout.DeleteAll();
    end;

    var
        ColumnLayout: Record "Column Layout";
        PackageImportErr: Label 'The imported package is not valid.';

    procedure XMLExchangeExport()
    var
        ConfigPackage: Record "Config. Package";
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        ConfigPackageCode: Code[20];
    begin
        ConfigPackageCode := AddColumnDefinitionToPackage(Rec.Name);
        ConfigPackage.Get(ConfigPackageCode);
        ConfigXMLExchange.ExportPackage(ConfigPackage);
    end;

    procedure XMLExchangeImport()
    var
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        PackageCode: Code[20];
    begin
        if ConfigXMLExchange.ImportPackageXMLFromClient() then begin
            PackageCode := ConfigXMLExchange.GetImportedPackageCode();
            ApplyPackage(PackageCode);
        end;
    end;

    local procedure ApplyPackage(PackageCode: Code[20])
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageMgt: Codeunit "Config. Package Management";
    begin
        if not ConfigPackage.Get(PackageCode) then
            Error(PackageImportErr);

        if GetNewColumnDefinitionName(PackageCode) = '' then
            Error(PackageImportErr);

        ConfigPackageTable.SetRange("Package Code", PackageCode);
        ConfigPackageMgt.ApplyPackage(ConfigPackage, ConfigPackageTable, false);
    end;

    local procedure GetNewColumnDefinitionName(PackageCode: Code[20]): Code[10]
    var
        ColumnLayoutName: Record "Column Layout Name";
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
        NewFinancialReport: Page "New Financial Report";
        ColumnDefinitionNameFromPackage: Code[10];
        NewName: Code[10];
    begin
        ColumnDefinitionNameFromPackage := GetColumnDefinitionNameFromImportedPackage(PackageCode);
        if ColumnDefinitionNameFromPackage = '' then
            exit('');
        if not ColumnLayoutName.Get(ColumnDefinitionNameFromPackage) then
            exit(ColumnDefinitionNameFromPackage);
        NewFinancialReport.Set('', '', ColumnDefinitionNameFromPackage);
        if NewFinancialReport.RunModal() = Action::OK then begin
            NewName := NewFinancialReport.GetColumnLayoutName();
            if NewName <> '' then
                FinancialReportMgt.RenameColumnLayoutInPackage(PackageCode, ColumnDefinitionNameFromPackage, NewName);
            exit(NewName);
        end;
    end;

    local procedure GetColumnDefinitionNameFromImportedPackage(PackageCode: Code[20]): Code[10]
    var
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageField: Record "Config. Package Field";
    begin
        if not ConfigPackageField.Get(PackageCode, Database::"Column Layout Name", Rec.FieldNo(Name)) then
            exit('');

        ConfigPackageData.SetLoadFields(Value);
        ConfigPackageData.SetRange("Package Code", PackageCode);
        ConfigPackageData.SetRange("Table ID", Database::"Column Layout Name");
        ConfigPackageData.SetRange("Field ID", Rec.FieldNo(Name));
        if ConfigPackageData.FindFirst() then
            exit(CopyStr(ConfigPackageData.Value, 1, 10));
    end;

    local procedure AddColumnDefinitionToPackage(ColumnLayoutNameCode: Code[10]) PackageCode: Code[20]
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigPackageManagement: Codeunit "Config. Package Management";
        PackageNameTxt: Label 'Column Definition - %1', Comment = '%1 - The name of the exported column definition';
        PackageCodeTok: Label 'COL.DEF.%1', Locked = true;
    begin
        PackageCode := CopyStr(StrSubstNo(PackageCodeTok, ColumnLayoutNameCode), 1, MaxStrLen(PackageCode));
        if ConfigPackage.Get(PackageCode) then
            ConfigPackage.Delete(true);

        ConfigPackageManagement.InsertPackage(ConfigPackage, PackageCode, StrSubstNo(PackageNameTxt, ColumnLayoutNameCode), true);

        ConfigPackageManagement.InsertPackageTable(ConfigPackageTable, PackageCode, Database::"Column Layout Name");
        ConfigPackageManagement.InsertPackageFilter(ConfigPackageFilter, PackageCode, Database::"Column Layout Name", 0, Rec.FieldNo(Name), ColumnLayoutNameCode);
        ConfigPackageManagement.InsertPackageTable(ConfigPackageTable, PackageCode, Database::"Column Layout");
        ConfigPackageManagement.InsertPackageFilter(ConfigPackageFilter, PackageCode, Database::"Column Layout", 0, ColumnLayout.FieldNo("Column Layout Name"), ColumnLayoutNameCode);
        if ConfigPackageField.Get(PackageCode, Database::"Column Layout Name", Rec.FieldNo("Analysis View Name")) then
            ConfigPackageField.Delete();
    end;

}

