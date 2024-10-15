#if not CLEAN20
report 31081 "Filtered Acc. Schedule Export"
{
    Caption = 'Filtered Acc. Schedule Export';
    ProcessingOnly = true;
    ObsoleteReason = 'The functionality will be removed and this report should not be used.';
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));

            trigger OnAfterGetRecord()
            var
                RowNo: Integer;
                ColumnNo: Integer;
                StartRowCaptions: Integer;
                StartRowLine: Integer;
                StartColumn: Integer;
                ColumnValue: Decimal;
            begin
                RowNo := 1;

                if AccSchedLine.GetFilter("Date Filter") <> '' then
                    EnterFilterInCell(RowNo, AccSchedLine.GetFilter("Date Filter"), AccSchedLine.FieldCaption("Date Filter"));

                RowNo += 1;
                if ExportAccSched."Show Amts. in Add. Curr." then
                    if GLSetup."Additional Reporting Currency" <> '' then begin
                        RowNo += 1;
                        EnterFilterInCell(RowNo, GLSetup."Additional Reporting Currency", Currency.TableCaption);
                    end
                    else
                        if GLSetup."LCY Code" <> '' then begin
                            RowNo += 1;
                            EnterFilterInCell(RowNo, GLSetup."LCY Code", Currency.TableCaption);
                        end;

                RowNo += 3;
                StartRowCaptions := RowNo;

                if AccSchedLine.FindSet() then begin
                    ColumnNo := 1;
                    if ExportAccLineNo then begin
                        EnterCell(RowNo, ColumnNo, AccSchedLine.FieldCaption("Row No."), false, false, false);
                        ColumnNo += 1;
                    end;
                    RowNo += 2;
                    StartRowLine := RowNo;

                    repeat
                        ColumnNo := 1;
                        if ExportAccLineNo then begin
                            EnterCell(RowNo, ColumnNo, AccSchedLine."Row No.", AccSchedLine.Bold, AccSchedLine.Italic, AccSchedLine.Underline);
                            ColumnNo += 1;
                        end;
                        EnterCell(RowNo, ColumnNo, AccSchedLine.Description, AccSchedLine.Bold, AccSchedLine.Italic, AccSchedLine.Underline);
                        RowNo += 1;
                    until AccSchedLine.Next() = 0;
                end;

                ColumnNo += 1;
                if AccSchedFilterLine.FindSet() then
                    repeat
                        RecNo += 1;
                        Window.Update(1, Round(RecNo / TotalRecNo * 10000, 1));
                        if AccSchedFilterLine.Show then
                            if AccSchedFilterLine."Empty Column" then
                                ColumnNo += 1
                            else begin
                                AccSchedLine.SetFilter("Dimension 1 Filter", AccSchedFilterLine."Dimension 1 Filter");
                                AccSchedLine.SetFilter("Dimension 2 Filter", AccSchedFilterLine."Dimension 2 Filter");
                                AccSchedLine.SetFilter("Dimension 3 Filter", AccSchedFilterLine."Dimension 3 Filter");
                                AccSchedLine.SetFilter("Dimension 4 Filter", AccSchedFilterLine."Dimension 4 Filter");
                                RowNo := StartRowCaptions;
                                EnterCell(RowNo, ColumnNo, GetDimensionFilter(AccSchedLine), false, false, false);
                                RowNo += 1;
                                StartColumn := ColumnNo;
                                if ColumnLayout.FindSet() then
                                    repeat
                                        EnterCell(RowNo, ColumnNo, ColumnLayout."Column Header", false, false, false);
                                        ColumnNo += 1;
                                    until ColumnLayout.Next() = 0;

                                RowNo := StartRowLine;
                                ColumnNo := StartColumn;
                                if AccSchedLine.FindSet() then
                                    repeat
                                        ColumnNo := StartColumn;
                                        if ColumnLayout.FindSet() then
                                            repeat
                                                if AccSchedLine.Totaling = '' then
                                                    ColumnValue := 0
                                                else begin
                                                    ColumnValue := AccSchedManagement.CalcCell(AccSchedLine, ColumnLayout,
                                                                     ExportAccSched."Show Amts. in Add. Curr.");
                                                    if AccSchedManagement.GetDivisionError then
                                                        ColumnValue := 0
                                                end;
                                                if ColumnValue <> 0 then
                                                    EnterCell(RowNo, ColumnNo, Format(ColumnValue), AccSchedLine.Bold,
                                                      AccSchedLine.Italic, AccSchedLine.Underline)
                                                else
                                                    EnterCell(RowNo, ColumnNo, '', AccSchedLine.Bold, AccSchedLine.Italic, AccSchedLine.Underline);
                                                ColumnNo += 1;
                                            until ColumnLayout.Next() = 0;
                                        RowNo += 1;
                                    until AccSchedLine.Next() = 0;
                            end;
                    until AccSchedFilterLine.Next() = 0;
            end;

            trigger OnPostDataItem()
            begin
                Window.Close;
            end;

            trigger OnPreDataItem()
            begin
                if StartDate = 0D then
                    Error(StartDateErr);
                if EndDate = 0D then
                    Error(EndDateErr);

                AccSchedName.Get(ExportAccSched."Account Schedule Name");
                if AccSchedName."Analysis View Name" <> '' then
                    AnalysisView.Get(AccSchedName."Analysis View Name");
                GLSetup.Get();

                AccSchedLine.SetRange("Schedule Name", ExportAccSched."Account Schedule Name");
                AccSchedLine.SetFilter("Date Filter", '%1..%2', StartDate, EndDate);
                AccSchedFilterLine.SetRange("Export Acc. Schedule Name", ExportAccSched.Name);
                ColumnLayout.SetRange("Column Layout Name", ExportAccSched."Column Layout Name");

                Window.Open(AnalysisTxt);
                Window.Update(1, 0);
                TotalRecNo := AccSchedFilterLine.Count();
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
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the starting date';
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the last date in the period.';
                    }
                    field(ExportAccLineNo; ExportAccLineNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Export Row No.';
                        ToolTip = 'Specifies if row number has to be printed.';
                    }
                    field(Option; Option)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Option';
                        OptionCaption = 'Create Workbook,Update Workbook';
                        ToolTip = 'Specifies the option if the new sheet will be created (create workbook) or will be updated (update workbook)';

                        trigger OnValidate()
                        begin
                            UpdateRequestForm;
                        end;
                    }
                    field(FileName; FileName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Workbook File Name';
                        Enabled = FileNameEnable;
                        ToolTip = 'Specifies workbook file name';
                    }
                    field(SheetName; SheetName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Worksheet Name';
                        Enabled = SheetNameEnable;
                        ToolTip = 'Specifies worksheet name';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            SheetNameEnable := true;
            FileNameEnable := true;
        end;

        trigger OnOpenPage()
        begin
            UpdateRequestForm;
        end;
    }

    labels
    {
    }

    var
        GLSetup: Record "General Ledger Setup";
        AccSchedName: Record "Acc. Schedule Name";
        AnalysisView: Record "Analysis View";
        AccSchedLine: Record "Acc. Schedule Line";
        ExportAccSched: Record "Export Acc. Schedule";
        AccSchedFilterLine: Record "Acc. Schedule Filter Line";
        ColumnLayout: Record "Column Layout";
        Currency: Record Currency;
        TempExcelBuffer: Record "Excel Buffer" temporary;
        AccSchedManagement: Codeunit AccSchedManagement;
        Window: Dialog;
        FileName: Text[250];
        SheetName: Text[250];
        StartDate: Date;
        EndDate: Date;
        Option: Option "Create Workbook","Update Workbook";
        ExportAccLineNo: Boolean;
        TotalRecNo: Integer;
        RecNo: Integer;
        [InDataSet]
        FileNameEnable: Boolean;
        [InDataSet]
        SheetNameEnable: Boolean;
        AnalysisTxt: Label 'Analyzing Data @1@@@@@@@@@@@@@@@@@@@@@';
        StartDateErr: Label 'You must specify starting date.';
        EndDateErr: Label 'You must specify ending date.';

    [Scope('OnPrem')]
    procedure UpdateRequestForm()
    begin
        PageUpdateRequestForm;
    end;

    [Scope('OnPrem')]
    procedure EnterCell(RowNo: Integer; ColumnNo: Integer; CellValue: Text[250]; Bold: Boolean; Italic: Boolean; UnderLine: Boolean)
    begin
        TempExcelBuffer.Init();
        TempExcelBuffer.Validate("Row No.", RowNo);
        TempExcelBuffer.Validate("Column No.", ColumnNo);
        TempExcelBuffer."Cell Value as Text" := CellValue;
        TempExcelBuffer.Formula := '';
        TempExcelBuffer.Bold := Bold;
        TempExcelBuffer.Italic := Italic;
        TempExcelBuffer.Underline := UnderLine;
        TempExcelBuffer.Insert();
    end;

    [Scope('OnPrem')]
    procedure EnterFilterInCell(RowNo: Integer; "Filter": Text[250]; FieldName: Text[100])
    begin
        if Filter <> '' then begin
            EnterCell(RowNo, 1, FieldName, false, false, false);
            EnterCell(RowNo, 2, Filter, false, false, false);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetDimFilterCaption(DimFilterNo: Integer): Text[80]
    var
        Dimension: Record Dimension;
    begin
        if AccSchedName."Analysis View Name" = '' then
            case DimFilterNo of
                1:
                    Dimension.Get(GLSetup."Global Dimension 1 Code");
                2:
                    Dimension.Get(GLSetup."Global Dimension 2 Code");
            end
        else
            case DimFilterNo of
                1:
                    Dimension.Get(AnalysisView."Dimension 1 Code");
                2:
                    Dimension.Get(AnalysisView."Dimension 2 Code");
                3:
                    Dimension.Get(AnalysisView."Dimension 3 Code");
                4:
                    Dimension.Get(AnalysisView."Dimension 4 Code");
            end;
        exit(CopyStr(Dimension.GetMLFilterCaption(GlobalLanguage), 1, 80));
    end;

    [Scope('OnPrem')]
    procedure GetDimensionFilter(var AccSchedLine: Record "Acc. Schedule Line"): Text[250]
    var
        DimFilters: Text;
    begin
        if AccSchedLine.GetFilter("Dimension 1 Filter") <> '' then
            DimFilters := GetDimFilterCaption(1) + ':' +
              AccSchedLine.GetFilter("Dimension 1 Filter");

        if AccSchedLine.GetFilter("Dimension 2 Filter") <> '' then begin
            if DimFilters <> '' then begin
                DimFilters := DimFilters + ';';
                DimFilters := DimFilters + GetDimFilterCaption(2) + ':' +
                  AccSchedLine.GetFilter("Dimension 2 Filter");
            end else
                DimFilters := GetDimFilterCaption(2) + ':' +
                  AccSchedLine.GetFilter("Dimension 2 Filter");
        end;

        if AccSchedLine.GetFilter("Dimension 3 Filter") <> '' then begin
            if DimFilters <> '' then begin
                DimFilters := DimFilters + ';';
                DimFilters := DimFilters + GetDimFilterCaption(3) + ':' +
                  AccSchedLine.GetFilter("Dimension 3 Filter");
            end else
                DimFilters := GetDimFilterCaption(3) + ':' +
                  AccSchedLine.GetFilter("Dimension 3 Filter");
        end;

        if AccSchedLine.GetFilter("Dimension 4 Filter") <> '' then begin
            if DimFilters <> '' then begin
                DimFilters := DimFilters + ';';
                DimFilters := DimFilters + GetDimFilterCaption(4) + ':' +
                  AccSchedLine.GetFilter("Dimension 4 Filter");
            end else
                DimFilters := GetDimFilterCaption(4) + ':' +
                  AccSchedLine.GetFilter("Dimension 4 Filter");
        end;

        exit(CopyStr(DimFilters, 1, 250));
    end;

    [Scope('OnPrem')]
    procedure SetParameter(lreExportAccSched: Record "Export Acc. Schedule")
    begin
        ExportAccSched := lreExportAccSched;
    end;

    local procedure PageUpdateRequestForm()
    begin
        if Option = Option::"Update Workbook" then begin
            FileNameEnable := true;
            SheetNameEnable := true;
        end else begin
            FileName := '';
            SheetName := '';
            FileNameEnable := false;
            SheetNameEnable := false;
        end;
    end;
}
#endif
