page 31081 "Acc. Schedule File Mapping"
{
    Caption = 'Acc. Schedule File Mapping (Obsolete)';
    DataCaptionExpression = CurrentSchedName + ' -' + CurrentColumnName;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Acc. Schedule Line";
    SourceTableView = SORTING("Schedule Name", "Line No.");
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(CurrentSchedName; CurrentSchedName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account Schedule Name';
                    Lookup = true;
                    LookupPageID = "Account Schedule Names";
                    ToolTip = 'Specifies the account schedule name.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(AccSchedMgt.LookupName(CurrentSchedName, Text));
                    end;

                    trigger OnValidate()
                    begin
                        AccSchedMgt.CheckName(CurrentSchedName);
                        CurrentSchedNameOnAfterValidate;
                    end;
                }
                field(CurrentColumnName; CurrentColumnName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Column Layout Name';
                    Lookup = true;
                    TableRelation = "Column Layout Name".Name;
                    ToolTip = 'Specifies the name of the column layout that you want to use in the window.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(AccSchedMgt.LookupColumnName(CurrentColumnName, Text));
                    end;

                    trigger OnValidate()
                    begin
                        AccSchedMgt.CheckColumnName(CurrentColumnName);
                        CurrentColumnNameOnAfterValidate;
                    end;
                }
            }
            repeater(Control1220014)
            {
                ShowCaption = false;
                field("Row No."; "Row No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a number for the account schedule line.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies text that will appear on the account schedule line.';
                }
                field("ColumnValues[1]"; ColumnValues[1])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + ColumnCaptions[1];
                    ToolTip = 'Specifies the value of the column 1. Contend of the column depends on column layout name setup.';

                    trigger OnDrillDown()
                    begin
                        DrillDown(1);
                    end;

                    trigger OnValidate()
                    begin
                        ValidateColumn(1);
                        AfterValidate(1);
                    end;
                }
                field("ColumnValues[2]"; ColumnValues[2])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + ColumnCaptions[2];
                    ToolTip = 'Specifies the value of the column 2. Contend of the column depends on column layout name setup.';

                    trigger OnDrillDown()
                    begin
                        DrillDown(2);
                    end;

                    trigger OnValidate()
                    begin
                        ValidateColumn(2);
                        AfterValidate(2);
                    end;
                }
                field("ColumnValues[3]"; ColumnValues[3])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + ColumnCaptions[3];
                    ToolTip = 'Specifies the value of the column 3. Contend of the column depends on column layout name setup.';

                    trigger OnDrillDown()
                    begin
                        DrillDown(3);
                    end;

                    trigger OnValidate()
                    begin
                        ValidateColumn(3);
                        AfterValidate(3);
                    end;
                }
                field("ColumnValues[4]"; ColumnValues[4])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + ColumnCaptions[4];
                    ToolTip = 'Specifies the value of the column 4. Contend of the column depends on column layout name setup.';

                    trigger OnDrillDown()
                    begin
                        DrillDown(4);
                    end;

                    trigger OnValidate()
                    begin
                        ValidateColumn(4);
                        AfterValidate(4);
                    end;
                }
                field("ColumnValues[5]"; ColumnValues[5])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + ColumnCaptions[5];
                    ToolTip = 'Specifies the value of the column 5. Contend of the column depends on column layout name setup.';

                    trigger OnDrillDown()
                    begin
                        DrillDown(5);
                    end;

                    trigger OnValidate()
                    begin
                        ValidateColumn(5);
                        AfterValidate(5);
                    end;
                }
                field("ColumnValues[6]"; ColumnValues[6])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + ColumnCaptions[6];
                    ToolTip = 'Specifies the value of the column 6. Contend of the column depends on column layout name setup.';

                    trigger OnDrillDown()
                    begin
                        DrillDown(6);
                    end;

                    trigger OnValidate()
                    begin
                        ValidateColumn(6);
                        AfterValidate(6);
                    end;
                }
                field("ColumnValues[7]"; ColumnValues[7])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + ColumnCaptions[7];
                    ToolTip = 'Specifies the value of the column 7. Contend of the column depends on column layout name setup.';

                    trigger OnDrillDown()
                    begin
                        DrillDown(7);
                    end;

                    trigger OnValidate()
                    begin
                        ValidateColumn(7);
                        AfterValidate(7);
                    end;
                }
                field("ColumnValues[8]"; ColumnValues[8])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + ColumnCaptions[8];
                    ToolTip = 'Specifies the value of the column 8. Contend of the column depends on column layout name setup.';

                    trigger OnDrillDown()
                    begin
                        DrillDown(8);
                    end;

                    trigger OnValidate()
                    begin
                        ValidateColumn(8);
                        AfterValidate(8);
                    end;
                }
                field("ColumnValues[9]"; ColumnValues[9])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + ColumnCaptions[9];
                    ToolTip = 'Specifies the value of the column 9. Contend of the column depends on column layout name setup.';

                    trigger OnDrillDown()
                    begin
                        DrillDown(9);
                    end;

                    trigger OnValidate()
                    begin
                        ValidateColumn(9);
                        AfterValidate(9);
                    end;
                }
                field("ColumnValues[10]"; ColumnValues[10])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + ColumnCaptions[10];
                    ToolTip = 'Specifies the value of the column 10. Contend of the column depends on column layout name setup.';

                    trigger OnDrillDown()
                    begin
                        DrillDown(10);
                    end;

                    trigger OnValidate()
                    begin
                        ValidateColumn(10);
                        AfterValidate(10);
                    end;
                }
                field("ColumnValues[11]"; ColumnValues[11])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + ColumnCaptions[11];
                    ToolTip = 'Specifies the value of the column 11. Contend of the column depends on column layout name setup.';

                    trigger OnDrillDown()
                    begin
                        DrillDown(11);
                    end;

                    trigger OnValidate()
                    begin
                        ValidateColumn(11);
                        AfterValidate(11);
                    end;
                }
                field("ColumnValues[12]"; ColumnValues[12])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + ColumnCaptions[12];
                    ToolTip = 'Specifies the value of the column 12. Contend of the column depends on column layout name setup.';

                    trigger OnDrillDown()
                    begin
                        DrillDown(12);
                    end;

                    trigger OnValidate()
                    begin
                        ValidateColumn(12);
                        AfterValidate(12);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                group("Export to Excel")
                {
                    Caption = 'Export to Excel';
                    Image = ExportToExcel;
                    action("Create New Document")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Create New Document';
                        Ellipsis = true;
                        Image = ExportToExcel;
                        ToolTip = 'Creates new document';

                        trigger OnAction()
                        var
                            AccSchedExportFile: Report "Account Schedule Export File";
                        begin
                            AccSchedName.Get("Schedule Name");
                            AccSchedExportFile.SetAccSchedName(AccSchedName.Name);
                            AccSchedExportFile.SetColumnLayoutName(AccSchedName."Default Column Layout");
                            AccSchedExportFile.Run;
                        end;
                    }
                    action("Update Existing Document")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Update Existing Document';
                        Ellipsis = true;
                        Image = ExportToExcel;
                        ToolTip = 'Updates existing document';

                        trigger OnAction()
                        var
                            AccSchedExportFile: Report "Account Schedule Export File";
                        begin
                            AccSchedName.Get("Schedule Name");
                            AccSchedExportFile.SetAccSchedName(AccSchedName.Name);
                            AccSchedExportFile.SetColumnLayoutName(AccSchedName."Default Column Layout");
                            AccSchedExportFile.SetUpdateExistingWorksheet(true);
                            AccSchedExportFile.Run;
                        end;
                    }
                }
            }
            action("Previous Column")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Column';
                Image = PreviousRecord;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Show the account schedule based on the previous column.';

                trigger OnAction()
                begin
                    AdjustColumnOffset(-1);
                end;
            }
            action("Next Column")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Column';
                Image = NextRecord;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Show the account schedule based on the next column.';

                trigger OnAction()
                begin
                    AdjustColumnOffset(1);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        ColumnNo: Integer;
    begin
        Clear(ColumnValues);
        StmtFileMapping.Reset();
        StmtFileMapping.SetRange("Schedule Name", CurrentSchedName);
        StmtFileMapping.SetRange("Schedule Line No.", "Line No.");
        StmtFileMapping.SetRange("Schedule Column Layout Name", CurrentColumnName);

        if TempColumnLayout.FindSet then
            repeat
                ColumnNo := ColumnNo + 1;
                if (ColumnNo > ColumnOffset) and (ColumnNo - ColumnOffset <= ArrayLen(ColumnValues)) then begin
                    StmtFileMapping.SetRange("Schedule Column No.", TempColumnLayout."Line No.");
                    if StmtFileMapping.FindSet then begin
                        if StmtFileMapping.Count > 1 then begin
                            repeat
                                ColumnValues[ColumnNo - ColumnOffset] := ColumnValues[ColumnNo - ColumnOffset] + '|' + StmtFileMapping."Excel Cell"
                            until StmtFileMapping.Next() = 0;
                            ColumnValues[ColumnNo - ColumnOffset] := DelChr(ColumnValues[ColumnNo - ColumnOffset], '<', '|')
                        end else
                            ColumnValues[ColumnNo - ColumnOffset] := StmtFileMapping."Excel Cell";
                    end;
                    ColumnLayoutArr[ColumnNo - ColumnOffset] := TempColumnLayout;
                end;
            until TempColumnLayout.Next() = 0;
    end;

    trigger OnOpenPage()
    begin
        GLSetup.Get();
        if NewCurrentSchedName <> '' then
            CurrentSchedName := NewCurrentSchedName;
        if CurrentSchedName = '' then
            CurrentSchedName := SchedNameTxt;
        if NewCurrentColumnName <> '' then
            CurrentColumnName := NewCurrentColumnName;
        if CurrentColumnName = '' then
            CurrentColumnName := SchedNameTxt;
        AccSchedMgt.CopyColumnsToTemp(CurrentColumnName, TempColumnLayout);
        AccSchedMgt.OpenSchedule(CurrentSchedName, Rec);
        AccSchedMgt.OpenColumns(CurrentColumnName, TempColumnLayout);
        UpdateColumnCaptions;
    end;

    var
        StmtFileMapping: Record "Statement File Mapping";
        StmtFileMapping2: Record "Statement File Mapping";
        TempColumnLayout: Record "Column Layout" temporary;
        ColumnLayoutArr: array[12] of Record "Column Layout";
        AccSchedName: Record "Acc. Schedule Name";
        GLSetup: Record "General Ledger Setup";
        AccSchedMgt: Codeunit AccSchedManagement;
        CurrentSchedName: Code[10];
        CurrentColumnName: Code[10];
        NewCurrentSchedName: Code[10];
        NewCurrentColumnName: Code[10];
        ColumnValues: array[12] of Code[50];
        ColumnCaptions: array[12] of Text[80];
        ColumnOffset: Integer;
        SchedNameTxt: Label 'DEFAULT', Comment = 'Max. 10 characters';

    [Scope('OnPrem')]
    procedure SetAccSchedName(NewAccSchedName: Code[10])
    var
        AccSchedName: Record "Acc. Schedule Name";
    begin
        NewCurrentSchedName := NewAccSchedName;
        if AccSchedName.Get(NewCurrentSchedName) then
            if AccSchedName."Default Column Layout" <> '' then
                NewCurrentColumnName := AccSchedName."Default Column Layout";
    end;

    [Scope('OnPrem')]
    procedure ValidateColumn(ColumnNo: Integer)
    begin
        if ColumnValues[ColumnNo] <> '' then begin
            Clear(StmtFileMapping2);
            StmtFileMapping2.TestRowColumn(ColumnValues[ColumnNo]);
        end;
    end;

    [Scope('OnPrem')]
    procedure AfterValidate(ColumnNo: Integer)
    begin
        TempColumnLayout := ColumnLayoutArr[ColumnNo];

        if ColumnValues[ColumnNo] <> '' then begin
            StmtFileMapping2.Init();
            StmtFileMapping2."Schedule Name" := CurrentSchedName;
            StmtFileMapping2."Schedule Line No." := "Line No.";
            StmtFileMapping2."Schedule Column Layout Name" := CurrentColumnName;
            StmtFileMapping2."Schedule Column No." := TempColumnLayout."Line No.";
            StmtFileMapping2.Validate("Excel Cell", ColumnValues[ColumnNo]);
            if StmtFileMapping2.Insert() then;
        end;
    end;

    local procedure DrillDown(ColumnNo: Integer)
    begin
        TempColumnLayout := ColumnLayoutArr[ColumnNo];

        StmtFileMapping.Reset();
        StmtFileMapping.SetRange("Schedule Name", CurrentSchedName);
        StmtFileMapping.SetRange("Schedule Line No.", "Line No.");
        StmtFileMapping.SetRange("Schedule Column Layout Name", CurrentColumnName);
        StmtFileMapping.SetRange("Schedule Column No.", TempColumnLayout."Line No.");
        PAGE.RunModal(PAGE::"File Mapping", StmtFileMapping);
        CurrPage.Update(false);
    end;

    local procedure UpdateColumnCaptions()
    var
        ColumnNo: Integer;
        i: Integer;
    begin
        Clear(ColumnCaptions);
        if TempColumnLayout.FindSet then
            repeat
                ColumnNo := ColumnNo + 1;
                if (ColumnNo > ColumnOffset) and (ColumnNo - ColumnOffset <= ArrayLen(ColumnCaptions)) then
                    ColumnCaptions[ColumnNo - ColumnOffset] := TempColumnLayout."Column Header";
            until (ColumnNo - ColumnOffset = ArrayLen(ColumnCaptions)) or (TempColumnLayout.Next() = 0);
        for i := ColumnNo - ColumnOffset + 1 to ArrayLen(ColumnCaptions) do
            ColumnCaptions[i] := '';
    end;

    local procedure AdjustColumnOffset(Delta: Integer)
    var
        OldColumnOffset: Integer;
    begin
        OldColumnOffset := ColumnOffset;
        ColumnOffset := ColumnOffset + Delta;
        if ColumnOffset + 12 > TempColumnLayout.Count then
            ColumnOffset := TempColumnLayout.Count - 12;
        if ColumnOffset < 0 then
            ColumnOffset := 0;
        if ColumnOffset <> OldColumnOffset then begin
            UpdateColumnCaptions;
            CurrPage.Update(false);
        end;
    end;

    local procedure CurrentSchedNameOnAfterValidate()
    var
        AccSchedName: Record "Acc. Schedule Name";
    begin
        CurrPage.SaveRecord;
        AccSchedMgt.SetName(CurrentSchedName, Rec);
        if AccSchedName.Get(CurrentSchedName) then
            if (AccSchedName."Default Column Layout" <> '') and
               (CurrentColumnName <> AccSchedName."Default Column Layout")
            then begin
                CurrentColumnName := AccSchedName."Default Column Layout";
                AccSchedMgt.CopyColumnsToTemp(CurrentColumnName, TempColumnLayout);
                AccSchedMgt.SetColumnName(CurrentColumnName, TempColumnLayout);
            end;

        CurrPage.Update(false);
    end;

    local procedure CurrentColumnNameOnAfterValidate()
    begin
        AccSchedMgt.CopyColumnsToTemp(CurrentColumnName, TempColumnLayout);
        AccSchedMgt.SetColumnName(CurrentColumnName, TempColumnLayout);
        UpdateColumnCaptions;
        CurrPage.Update(false);
    end;
}

