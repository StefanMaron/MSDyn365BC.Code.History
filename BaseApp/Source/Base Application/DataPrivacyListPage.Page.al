page 1181 "Data Privacy ListPage"
{
    Caption = 'Data Privacy ListPage';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "Data Privacy Records";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Editable = false;
                field("Table Name"; "Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Editable = false;
                    Enabled = false;
                }
                field("Field Name"; "Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Editable = false;
                    Enabled = false;
                    ToolTip = 'Specifies the name of the field.';
                }
                field("Field Value"; "Field Value")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Editable = false;
                    Enabled = false;
                    ToolTip = 'Specifies the value in the field.';
                }
            }
        }
    }

    actions
    {
    }

    var
        ConfigProgressBar: Codeunit "Config. Progress Bar";
        CreatingPreviewDataTxt: Label 'Creating preview data...';

    procedure GeneratePreviewData(PackageCode: Code[20])
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        Counter: Integer;
    begin
        Counter := 1;
        Clear(Rec);
        Reset;
        DeleteAll;
        CurrPage.Update;

        if ConfigPackage.Get(PackageCode) then begin
            ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
            ConfigProgressBar.Init(ConfigPackageTable.Count, 1, CreatingPreviewDataTxt);
            ConfigPackageTable.SetAutoCalcFields("Table Name");
            if ConfigPackageTable.FindSet then
                repeat
                    ConfigProgressBar.Update(ConfigPackageTable."Table Name");
                    RecRef.Open(ConfigPackageTable."Table ID");
                    ConfigXMLExchange.ApplyPackageFilter(ConfigPackageTable, RecRef);
                    if RecRef.FindSet then
                        repeat
                            ConfigPackageField.SetRange("Package Code", ConfigPackageTable."Package Code");
                            ConfigPackageField.SetRange("Table ID", ConfigPackageTable."Table ID");
                            if ConfigPackageField.FindSet then
                                repeat
                                    FieldRef := RecRef.Field(ConfigPackageField."Field ID");
                                    Init;
                                    ID := Counter;
                                    "Table No." := ConfigPackageTable."Table ID";
                                    "Field No." := ConfigPackageField."Field ID";
                                    "Field Value" := Format(FieldRef.Value);
                                    "Field DataType" := Format(FieldRef.Type);
                                    if not Insert then
                                        repeat
                                            Counter := Counter + 1;
                                            ID := Counter;
                                        until Insert;
                                until ConfigPackageField.Next = 0;
                        until RecRef.Next = 0;
                    RecRef.Close;
                until ConfigPackageTable.Next = 0;
            ConfigProgressBar.Close;
        end;
    end;
}

