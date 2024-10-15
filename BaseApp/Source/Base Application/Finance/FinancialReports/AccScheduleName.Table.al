namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.GeneralLedger.Setup;
using System.IO;
using System.Utilities;

table 84 "Acc. Schedule Name"
{
    Caption = 'Acc. Schedule Name';
    DataCaptionFields = Name, Description;
    LookupPageID = "Account Schedule Names";
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
        field(3; "Default Column Layout"; Code[10])
        {
            Caption = 'Default Column Layout';
            TableRelation = "Column Layout Name";
            ObsoleteReason = 'Use now the Column Group property in the table Financial Report';
            ObsoleteTag = '25.0';
            ObsoleteState = Removed;
        }
        field(4; "Analysis View Name"; Code[10])
        {
            Caption = 'Analysis View Name';
            TableRelation = "Analysis View";

            trigger OnValidate()
            var
                AnalysisView: Record "Analysis View";
                xAnalysisView: Record "Analysis View";
                ConfirmManagement: Codeunit "Confirm Management";
                AskedUser: Boolean;
                ClearTotaling: Boolean;
                i: Integer;
            begin
                if xRec."Analysis View Name" <> "Analysis View Name" then begin
                    AnalysisViewGet(xAnalysisView, xRec."Analysis View Name");
                    AnalysisViewGet(AnalysisView, "Analysis View Name");

                    ClearTotaling := true;

                    for i := 1 to 4 do
                        if (GetDimCodeByNum(xAnalysisView, i) <> GetDimCodeByNum(AnalysisView, i)) and ClearTotaling then
                            if not DimTotalingLinesAreEmpty(i) then begin
                                if not AskedUser then begin
                                    ClearTotaling := ConfirmManagement.GetResponseOrDefault(ClearDimensionTotalingConfirmTxt, true);
                                    AskedUser := true;
                                end;

                                if ClearTotaling then
                                    ClearDimTotalingLines(i);
                            end;
                    if not ClearTotaling then
                        "Analysis View Name" := xRec."Analysis View Name";
                end;
            end;
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
    }

    trigger OnDelete()
    begin
        AccSchedLine.SetRange("Schedule Name", Name);
        AccSchedLine.DeleteAll();
    end;

    var
        AccSchedLine: Record "Acc. Schedule Line";
        AccSchedPrefixTxt: Label 'ROW.DEF.', MaxLength = 10, Comment = 'Part of the name for the confguration package, stands for Row Definition';
        TwoPosTxt: Label '%1%2', Locked = true;
        PackageNameTxt: Label 'Row Definition - %1', MaxLength = 40, Comment = '%1 - Rows definition name';
        ClearDimensionTotalingConfirmTxt: Label 'Changing Analysis View will clear differing dimension totaling columns of Account Schedule Lines. \Do you want to continue?';
        PackageImportErr: Label 'The row definitions could not be imported.';

    local procedure AnalysisViewGet(var AnalysisView: Record "Analysis View"; AnalysisViewName: Code[10])
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if not AnalysisView.Get(AnalysisViewName) then
            if "Analysis View Name" = '' then begin
                GLSetup.Get();
                AnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
                AnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
            end;
    end;

    procedure DimTotalingLinesAreEmpty(DimNumber: Integer): Boolean
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        AccSchedLine.Reset();
        AccSchedLine.SetRange("Schedule Name", Name);
        RecRef.GetTable(AccSchedLine);
        FieldRef := RecRef.Field(AccSchedLine.FieldNo("Dimension 1 Totaling") + DimNumber - 1);
        FieldRef.SetFilter('<>%1', '');
        RecRef := FieldRef.Record();
        exit(RecRef.IsEmpty());
    end;

    procedure ClearDimTotalingLines(DimNumber: Integer)
    var
        FieldRef: FieldRef;
        RecRef: RecordRef;
    begin
        AccSchedLine.Reset();
        AccSchedLine.SetRange("Schedule Name", Name);
        RecRef.GetTable(AccSchedLine);
        if RecRef.FindSet() then
            repeat
                FieldRef := RecRef.Field(AccSchedLine.FieldNo("Dimension 1 Totaling") + DimNumber - 1);
                FieldRef.Value := '';
                RecRef.Modify();
            until RecRef.Next() = 0;
    end;

    local procedure GetDimCodeByNum(AnalysisView: Record "Analysis View"; DimNumber: Integer) DimensionCode: Code[20]
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(AnalysisView);
        FieldRef := RecRef.Field(AnalysisView.FieldNo("Dimension 1 Code") + DimNumber - 1);
        Evaluate(DimensionCode, Format(FieldRef.Value));
    end;

    procedure Export()
    var
        ConfigPackage: Record "Config. Package";
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        PackageCode: Code[20];
    begin
        PackageCode := StrSubstNo(TwoPosTxt, AccSchedPrefixTxt, Name);
        if ConfigPackage.Get(PackageCode) then
            ConfigPackage.Delete(true);

        ConfigPackage.Code := PackageCode;
        ConfigPackage."Package Name" := StrSubstNo(PackageNameTxt, Name);
        ConfigPackage."Exclude Config. Tables" := true;
        ConfigPackage.Insert(true);
        AddRowDefinitionToConfigPackage(Name, ConfigPackage, PackageCode);
        Commit();
        ConfigXMLExchange.ExportPackage(ConfigPackage);
    end;

    procedure AddRowDefinitionToConfigPackage(AccScheduleName: Code[10]; var ConfigPackage: Record "Config. Package"; PackageCode: Code[20])
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        AnalysisView: Record "Analysis View";
    begin
        AddConfigPackageTable(PackageCode, Database::"Acc. Schedule Name", FieldNo(Name), AccScheduleName);
        AddConfigPackageTable(
            PackageCode, Database::"Acc. Schedule Line", AccScheduleLine.FieldNo("Schedule Name"), AccScheduleName);
        if "Analysis View Name" <> '' then
            AddConfigPackageTable(
                PackageCode, Database::"Analysis View", AnalysisView.FieldNo(Code), "Analysis View Name");
    end;

    local procedure AddConfigPackageTable(PackageCode: Code[20]; TableID: Integer; FieldID: Integer; AccScheduleName: Code[10])
    var
        ConfigPackageTable: Record "Config. Package Table";
    begin
        ConfigPackageTable."Package Code" := PackageCode;
        ConfigPackageTable.Validate("Table ID", TableID);
        ConfigPackageTable.Insert(true);
        AddConfigPackageFilter(ConfigPackageTable, FieldID, AccScheduleName);
    end;

    local procedure AddConfigPackageFilter(ConfigPackageTable: Record "Config. Package Table"; FieldNumber: Integer; FieldFilter: Text[250])
    var
        ConfigPackageFilter: Record "Config. Package Filter";
    begin
        ConfigPackageFilter.Init();
        ConfigPackageFilter."Package Code" := ConfigPackageTable."Package Code";
        ConfigPackageFilter."Table ID" := ConfigPackageTable."Table ID";
        ConfigPackageFilter."Field ID" := FieldNumber;
        ConfigPackageFilter."Processing Rule No." := 0;
        ConfigPackageFilter."Field Filter" := FieldFilter;
        ConfigPackageFilter.Insert(true);
    end;

    procedure Import()
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
    begin
        if not ConfigPackage.Get(PackageCode) then
            Error(PackageImportErr);

        if GetPackageAccSchedName(PackageCode) = '' then
            Error(PackageImportErr);

        ConfigPackageTable.SetRange("Package Code", PackageCode);
        ConfigPackageMgt.ApplyPackage(ConfigPackage, ConfigPackageTable, false);
    end;

    local procedure GetPackageAccSchedName(PackageCode: Code[20]) NewName: Code[10]
    var
        OldName: Code[10];
        AccScheduleExists: Boolean;
    begin
        NewName := GetAccountScheduleName(PackageCode, AccScheduleExists);
        if NewName = '' then
            exit('');

        if not AccScheduleExists then
            exit(NewName);

        OldName := NewName;
        if not GetNewAccScheduleName(NewName) then
            exit('');

        RenameAccountScheduleInPackage(PackageCode, OldName, NewName);
    end;

    local procedure GetNewAccScheduleName(var AccScheduleName: Code[10]): Boolean
    var
        NewAccountScheduleName: Page "New Account Schedule Name";
    begin
        NewAccountScheduleName.Set(AccScheduleName);
        if NewAccountScheduleName.RunModal() = Action::OK then begin
            AccScheduleName := NewAccountScheduleName.GetName();
            exit(true);
        end;
        exit(false)
    end;

    procedure RenameAccountScheduleInPackage(PackageCode: Code[20]; OldName: Code[10]; NewName: Code[10])
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ConfigPackageData: Record "Config. Package Data";
    begin
        if OldName = NewName then
            exit;

        ConfigPackageData.SetLoadFields(Value);
        ConfigPackageData.SetRange("Package Code", PackageCode);
        ConfigPackageData.SetRange(Value, OldName);

        ConfigPackageData.SetRange("Table ID", Database::"Acc. Schedule Name");
        ConfigPackageData.SetRange("Field ID", AccScheduleName.FieldNo(Name));
        ConfigPackageData.ModifyAll(Value, NewName);

        ConfigPackageData.SetRange("Table ID", Database::"Acc. Schedule Line");
        ConfigPackageData.SetRange("Field ID", AccScheduleLine.FieldNo("Schedule Name"));
        ConfigPackageData.ModifyAll(Value, NewName);
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
}

