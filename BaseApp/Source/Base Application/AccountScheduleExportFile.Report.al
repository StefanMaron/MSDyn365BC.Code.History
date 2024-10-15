report 31080 "Account Schedule Export File"
{
    Caption = 'Account Schedule Export File (Obsolete)';
    ProcessingOnly = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    dataset
    {
        dataitem("Acc. Schedule Name"; "Acc. Schedule Name")
        {
            DataItemTableView = SORTING(Name);
            dataitem("Acc. Schedule Line"; "Acc. Schedule Line")
            {
                DataItemLink = "Schedule Name" = FIELD(Name);
                DataItemTableView = SORTING("Schedule Name", "Line No.");

                trigger OnAfterGetRecord()
                var
                    i: Integer;
                begin
                    for i := 1 to MaxColumnsDisplayed do begin
                        ColumnValuesDisplayed[i] := 0;
                        ColumnValuesAsText[i] := '';
                    end;

                    CalcColumns;
                end;

                trigger OnPreDataItem()
                begin
                    SetFilter("Date Filter", DateFilter);
                    SetFilter("G/L Budget Filter", GLBudgetFilter);
                    SetFilter("Cost Budget Filter", CostBudgetFilter);
                    SetFilter("Business Unit Filter", BusinessUnitFilter);
                    SetFilter("Dimension 1 Filter", Dim1Filter);
                    SetFilter("Dimension 2 Filter", Dim2Filter);
                    SetFilter("Dimension 3 Filter", Dim3Filter);
                    SetFilter("Dimension 4 Filter", Dim4Filter);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "Analysis View Name" <> '' then
                    AnalysisView.Get("Analysis View Name")
                else begin
                    AnalysisView.Init();
                    AnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
                    AnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
                end;
            end;

            trigger OnPostDataItem()
            begin
                if DoUpdateExistingWorksheet or
                   (ExcelTemplateCode <> '')
                then begin
                    TempExcelBuffer.UpdateBook(ServerFileName, SheetName);
                    TempExcelBuffer.WriteSheet('', CompanyName, UserId);
                    TempExcelBuffer.CloseBook;
                    TempExcelBuffer.DownloadAndOpenExcel;
                end else begin
                    TempExcelBuffer.CreateBook('', Name);
                    TempExcelBuffer.WriteSheet(Description, CompanyName, UserId);
                    TempExcelBuffer.CloseBook;
                    TempExcelBuffer.OpenExcel;
                end;
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Name, AccSchedName);

                StmtFileMapping.Reset();
                StmtFileMapping.SetRange("Schedule Name", AccSchedName);
                StmtFileMapping.SetRange("Schedule Column Layout Name", ColumnLayoutName);
                if StmtFileMapping.IsEmpty then
                    Error(Text006);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(AccSchedName; AccSchedName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Acc. Schedule Name';
                        TableRelation = "Acc. Schedule Name";
                        ToolTip = 'Specifies the name of the account schedule to be shown in the report.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            exit(AccSchedManagement.LookupName(AccSchedName, Text));
                        end;

                        trigger OnValidate()
                        begin
                            AccSchedManagement.CheckName(AccSchedName);
                            AccScheduleName.Get(AccSchedName);
                            if AccScheduleName."Default Column Layout" <> '' then
                                ColumnLayoutName := AccScheduleName."Default Column Layout";

                            if AccScheduleName."Analysis View Name" <> '' then
                                AnalysisView.Get(AccScheduleName."Analysis View Name")
                            else begin
                                Clear(AnalysisView);
                                AnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
                                AnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
                            end;
                        end;
                    }
                    field(ColumnLayoutName; ColumnLayoutName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Column Layout Name';
                        Lookup = true;
                        TableRelation = "Column Layout Name".Name;
                        ToolTip = 'Specifies the name of the column layout that you want to use in the window.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            exit(AccSchedManagement.LookupColumnName(ColumnLayoutName, Text));
                        end;

                        trigger OnValidate()
                        begin
                            AccSchedManagement.CheckColumnName(ColumnLayoutName);
                        end;
                    }
                    field(ExcelTemplateCode; ExcelTemplateCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Excel Template';
                        TableRelation = "Excel Template";
                        ToolTip = 'Specifies the excel template for the account schedule export.';

                        trigger OnValidate()
                        begin
                            ValidateExcelTemplateCode;
                        end;
                    }
                }
                group(Filters)
                {
                    Caption = 'Filters';
                    field(DateFilter; DateFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Date Filter';
                        ToolTip = 'Specifies the date filter for G/L accounts entries.';

                        trigger OnValidate()
                        begin
                            "Acc. Schedule Line".SetFilter("Date Filter", DateFilter);
                            DateFilter := "Acc. Schedule Line".GetFilter("Date Filter");
                        end;
                    }
                    field(GLBudgetFilter; GLBudgetFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'G/L Budget Filter';
                        TableRelation = "G/L Budget Name".Name;
                        ToolTip = 'Specifies a general ledger budget filter for the report.';

                        trigger OnValidate()
                        begin
                            "Acc. Schedule Line".SetFilter("G/L Budget Filter", GLBudgetFilter);
                            GLBudgetFilter := "Acc. Schedule Line".GetFilter("G/L Budget Filter");
                        end;
                    }
                    field(CostBudgetFilter; CostBudgetFilter)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Cost Budget Filter';
                        TableRelation = "Cost Budget Name".Name;
                        ToolTip = 'Specifies a cost budget filter for the report.';

                        trigger OnValidate()
                        begin
                            "Acc. Schedule Line".SetFilter("Cost Budget Filter", CostBudgetFilter);
                            CostBudgetFilter := "Acc. Schedule Line".GetFilter("Cost Budget Filter");
                        end;
                    }
                    field(BusinessUnitFilter; BusinessUnitFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Business Unit Filter';
                        LookupPageID = "Business Unit List";
                        TableRelation = "Business Unit";
                        ToolTip = 'Specifies a business unit filter for the report.';

                        trigger OnValidate()
                        begin
                            "Acc. Schedule Line".SetFilter("Business Unit Filter", BusinessUnitFilter);
                            BusinessUnitFilter := "Acc. Schedule Line".GetFilter("Business Unit Filter");
                        end;
                    }
                }
                group("Dimension Filters")
                {
                    Caption = 'Dimension Filters';
                    field(Dim1Filter; Dim1Filter)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = PageGetCaptionClass(1);
                        Caption = 'Dimension 1 Filter';
                        Enabled = Dim1FilterEnable;
                        ToolTip = 'Specifies the filter for dimension 1.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            exit(DimValue.LookUpDimFilter(AnalysisView."Dimension 1 Code", Text));
                        end;
                    }
                    field(Dim2Filter; Dim2Filter)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = PageGetCaptionClass(2);
                        Caption = 'Dimension 2 Filter';
                        Enabled = Dim2FilterEnable;
                        ToolTip = 'Specifies the filter for dimension 2.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            exit(DimValue.LookUpDimFilter(AnalysisView."Dimension 2 Code", Text));
                        end;
                    }
                    field(Dim3Filter; Dim3Filter)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = PageGetCaptionClass(3);
                        Caption = 'Dimension 3 Filter';
                        Enabled = Dim3FilterEnable;
                        ToolTip = 'Specifies the filter for dimension 3.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            exit(DimValue.LookUpDimFilter(AnalysisView."Dimension 3 Code", Text));
                        end;
                    }
                    field(Dim4Filter; Dim4Filter)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = PageGetCaptionClass(4);
                        Caption = 'Dimension 4 Filter';
                        Enabled = Dim4FilterEnable;
                        ToolTip = 'Specifies the filter for dimension 4.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            exit(DimValue.LookUpDimFilter(AnalysisView."Dimension 4 Code", Text));
                        end;
                    }
                }
                group(Show)
                {
                    Caption = 'Show';
                    field(UseAmtsInAddCurr; UseAmtsInAddCurr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in Add. Reporting Currency';
                        ToolTip = 'Specifies when the amounts in add. reporting currency is to be show';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            GLSetup.Get();
            if AccSchedNameHidden <> '' then
                AccSchedName := AccSchedNameHidden;

            if ColumnLayoutNameHidden <> '' then
                ColumnLayoutName := ColumnLayoutNameHidden;

            if AccSchedName <> '' then
                if not AccScheduleName.Get(AccSchedName) then
                    AccSchedName := '';

            if AccSchedName = '' then
                if AccScheduleName.FindFirst then
                    AccSchedName := AccScheduleName.Name;

            if AccScheduleName."Analysis View Name" <> '' then
                AnalysisView.Get(AccScheduleName."Analysis View Name")
            else begin
                AnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
                AnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
            end;

            UpdateEnabledControls;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        GLSetup.Get();
        TempExcelBuffer.DeleteAll();

        if ExcelTemplateCode <> '' then begin
            ExcelTemplate.Get(ExcelTemplateCode);
            ServerFileName := ExcelTemplate.ExportToServerFile;
            SheetName := ExcelTemplate.Sheet;
        end else
            if DoUpdateExistingWorksheet then begin
                ServerFileName := FileMgt.UploadFile(UpdateWorkbookTxt, FileExtensionTxt);
                if ServerFileName = '' then
                    exit;
                SheetName := TempExcelBuffer.SelectSheetsName(ServerFileName);
                if SheetName = '' then
                    exit;
            end;

        InitAccSched;
    end;

    var
        AccScheduleName: Record "Acc. Schedule Name";
        TempColumnLayout: Record "Column Layout" temporary;
        AnalysisView: Record "Analysis View";
        GLSetup: Record "General Ledger Setup";
        TempExcelBuffer: Record "Excel Buffer" temporary;
        StmtFileMapping: Record "Statement File Mapping";
        ExcelTemplate: Record "Excel Template";
        DimValue: Record "Dimension Value";
        AccSchedManagement: Codeunit AccSchedManagement;
        FileMgt: Codeunit "File Management";
        AccSchedName: Code[10];
        AccSchedNameHidden: Code[10];
        ColumnLayoutName: Code[10];
        ColumnLayoutNameHidden: Code[10];
        ExcelTemplateCode: Code[20];
        ShowError: Option "None","Division by Zero","Period Error",Both;
        DateFilter: Text;
        CostBudgetFilter: Text;
        GLBudgetFilter: Text;
        BusinessUnitFilter: Text;
        Dim1Filter: Text;
        [InDataSet]
        Dim1FilterEnable: Boolean;
        Dim2Filter: Text;
        [InDataSet]
        Dim2FilterEnable: Boolean;
        Dim3Filter: Text;
        [InDataSet]
        Dim3FilterEnable: Boolean;
        Dim4Filter: Text;
        [InDataSet]
        Dim4FilterEnable: Boolean;
        ColumnValuesDisplayed: array[100] of Decimal;
        ColumnValuesAsText: array[100] of Text[30];
        MaxColumnsDisplayed: Integer;
        UseAmtsInAddCurr: Boolean;
        ServerFileName: Text;
        SheetName: Text[250];
        Text002: Label '* ERROR *';
        Text004: Label 'Not Available';
        Text006: Label 'XLS mapping is empty.';
        FileExtensionTxt: Label '.xlsx', Comment = '.xlsx';
        DoUpdateExistingWorksheet: Boolean;
        UpdateWorkbookTxt: Label 'Update Workbook';

    [Scope('OnPrem')]
    procedure InitAccSched()
    begin
        MaxColumnsDisplayed := ArrayLen(ColumnValuesDisplayed);
        AccSchedManagement.CopyColumnsToTemp(ColumnLayoutName, TempColumnLayout);
    end;

    [Scope('OnPrem')]
    procedure SetAccSchedName(NewAccSchedName: Code[10])
    begin
        AccSchedNameHidden := NewAccSchedName;
    end;

    [Scope('OnPrem')]
    procedure SetColumnLayoutName(ColLayoutName: Code[10])
    begin
        ColumnLayoutNameHidden := ColLayoutName;
    end;

    local procedure CalcColumns() NonZero: Boolean
    var
        i: Integer;
    begin
        NonZero := false;
        with TempColumnLayout do begin
            SetRange("Column Layout Name", ColumnLayoutName);
            i := 0;
            if FindSet then
                repeat
                    if Show <> Show::Never then begin
                        i += 1;
                        ColumnValuesDisplayed[i] :=
                          AccSchedManagement.CalcCell("Acc. Schedule Line", TempColumnLayout, UseAmtsInAddCurr);
                        if AccSchedManagement.GetDivisionError then
                            if ShowError in [ShowError::"Division by Zero", ShowError::Both] then
                                ColumnValuesAsText[i] := Text002
                            else
                                ColumnValuesAsText[i] := ''
                        else
                            if AccSchedManagement.GetPeriodError then
                                if ShowError in [ShowError::"Period Error", ShowError::Both] then
                                    ColumnValuesAsText[i] := Text004
                                else
                                    ColumnValuesAsText[i] := ''
                            else begin
                                NonZero := NonZero or (ColumnValuesDisplayed[i] <> 0);
                                ColumnValuesAsText[i] :=
                                  AccSchedManagement.FormatCellAsText(TempColumnLayout, ColumnValuesDisplayed[i], false);
                            end;
                    end;

                    StmtFileMapping.Reset();
                    StmtFileMapping.SetRange("Schedule Name", "Acc. Schedule Line"."Schedule Name");
                    StmtFileMapping.SetRange("Schedule Line No.", "Acc. Schedule Line"."Line No.");
                    StmtFileMapping.SetRange("Schedule Column Layout Name", "Column Layout Name");
                    StmtFileMapping.SetRange("Schedule Column No.", "Line No.");
                    if StmtFileMapping.FindSet then
                        repeat
                            AddTempExcelBuffer(StmtFileMapping."Excel Row No.",
                              StmtFileMapping."Excel Column No.",
                              ColumnValuesAsText[i],
                              StmtFileMapping.Split,
                              StmtFileMapping.Offset);
                        until StmtFileMapping.Next = 0;
                until (i >= MaxColumnsDisplayed) or (Next = 0);
        end;
    end;

    local procedure AddTempExcelBuffer(Line: Integer; Column: Integer; Value: Text[250]; Split: Option " ",Right,Left; Offset: Integer)
    var
        i: Integer;
        locOffset: Integer;
    begin
        if (Line = 0) or (Column = 0) then
            exit;

        case Split of
            Split::" ":
                begin
                    TempExcelBuffer.Init();
                    TempExcelBuffer.Validate("Row No.", Line);
                    TempExcelBuffer.Validate("Column No.", Column);
                    TempExcelBuffer."Cell Value as Text" := Value;
                    if not TempExcelBuffer.Insert() then
                        TempExcelBuffer.Modify();
                end;
            Split::Right:
                for i := 1 to StrLen(Value) do begin
                    TempExcelBuffer.Init();
                    TempExcelBuffer.Validate("Row No.", Line);
                    TempExcelBuffer.Validate("Column No.", Column + locOffset);
                    TempExcelBuffer."Cell Value as Text" := CopyStr(Value, i, 1);
                    if not TempExcelBuffer.Insert() then
                        TempExcelBuffer.Modify();
                    locOffset := locOffset + Offset;
                end;
            Split::Left:
                for i := StrLen(Value) downto 1 do begin
                    TempExcelBuffer.Init();
                    TempExcelBuffer.Validate("Row No.", Line);
                    TempExcelBuffer.Validate("Column No.", Column - locOffset);
                    TempExcelBuffer."Cell Value as Text" := CopyStr(Value, i, 1);
                    if not TempExcelBuffer.Insert() then
                        TempExcelBuffer.Modify();
                    locOffset := locOffset + Offset;
                end;
        end;
    end;

    local procedure PageGetCaptionClass(DimNo: Integer): Text[250]
    begin
        exit(AnalysisView.GetCaptionClass(DimNo));
    end;

    local procedure UpdateEnabledControls()
    begin
        Dim1FilterEnable := AnalysisView."Dimension 1 Code" <> '';
        Dim2FilterEnable := AnalysisView."Dimension 2 Code" <> '';
        Dim3FilterEnable := AnalysisView."Dimension 3 Code" <> '';
        Dim4FilterEnable := AnalysisView."Dimension 4 Code" <> '';
    end;

    local procedure ValidateExcelTemplateCode()
    begin
        if ExcelTemplateCode <> '' then
            ExcelTemplate.Get(ExcelTemplateCode);

        UpdateEnabledControls;
    end;

    [Scope('OnPrem')]
    procedure SetUpdateExistingWorksheet(UpdateExistingWorksheet: Boolean)
    begin
        DoUpdateExistingWorksheet := UpdateExistingWorksheet;
    end;
}

