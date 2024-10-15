report 14964 "Export Payr. An. Rep. to Excel"
{
    Caption = 'Export Payr. An. Rep. to Excel';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));

            trigger OnAfterGetRecord()
            var
                Window: Dialog;
                RecNo: Integer;
                TotalRecNo: Integer;
                RowNo: Integer;
                ColumnNo: Integer;
            begin
                Window.Open(
                  Text000 +
                  '@1@@@@@@@@@@@@@@@@@@@@@\');
                Window.Update(1, 0);
                TotalRecNo := PayrollAnalysisLine.Count();
                RecNo := 0;

                TempExcelBuffer.DeleteAll();
                Clear(TempExcelBuffer);

                PayrollAnalysisLineTemplate.Get(PayrollAnalysisLine."Analysis Line Template Name");
                if PayrollAnalysisLineTemplate."Payroll Analysis View Code" <> '' then
                    PayrollAnalysisView.Get(PayrollAnalysisLineTemplate."Payroll Analysis View Code");
                GLSetup.Get();

                RowNo := 1;
                EnterCell(RowNo, 1, Text001, false, false, true);
                if PayrollAnalysisLine.GetFilter("Date Filter") <> '' then begin
                    RowNo := RowNo + 1;
                    EnterFilterInCell(
                      RowNo,
                      PayrollAnalysisLine.GetFilter("Date Filter"),
                      PayrollAnalysisLine.FieldCaption("Date Filter"));
                end;
                if PayrollAnalysisLine.GetFilter("Dimension 1 Filter") <> '' then begin
                    RowNo := RowNo + 1;
                    EnterFilterInCell(
                      RowNo,
                      PayrollAnalysisLine.GetFilter("Dimension 1 Filter"),
                      GetDimFilterCaption(1));
                end;
                if PayrollAnalysisLine.GetFilter("Dimension 2 Filter") <> '' then begin
                    RowNo := RowNo + 1;
                    EnterFilterInCell(
                      RowNo,
                      PayrollAnalysisLine.GetFilter("Dimension 2 Filter"),
                      GetDimFilterCaption(2));
                end;
                if PayrollAnalysisLine.GetFilter("Dimension 3 Filter") <> '' then begin
                    RowNo := RowNo + 1;
                    EnterFilterInCell(
                      RowNo,
                      PayrollAnalysisLine.GetFilter("Dimension 3 Filter"),
                      GetDimFilterCaption(3));
                end;

                RowNo := RowNo + 1;
                if GLSetup."LCY Code" <> '' then begin
                    RowNo := RowNo + 1;
                    EnterFilterInCell(
                      RowNo,
                      GLSetup."LCY Code",
                      Currency.TableCaption);
                end;

                RowNo := RowNo + 1;
                if PayrollAnalysisLine.FindSet then begin
                    if PayrollAnalysisColumn.FindSet then begin
                        RowNo := RowNo + 1;
                        ColumnNo := 1;
                        repeat
                            ColumnNo := ColumnNo + 1;
                            EnterCell(
                              RowNo,
                              ColumnNo,
                              PayrollAnalysisColumn."Column Header",
                              false,
                              false,
                              false);
                        until PayrollAnalysisColumn.Next() = 0;
                    end;
                    repeat
                        RecNo := RecNo + 1;
                        Window.Update(1, Round(RecNo / TotalRecNo * 10000, 1));
                        RowNo := RowNo + 1;
                        ColumnNo := 1;
                        EnterCell(
                          RowNo,
                          ColumnNo,
                          PayrollAnalysisLine.Description,
                          PayrollAnalysisLine.Bold,
                          PayrollAnalysisLine.Italic,
                          PayrollAnalysisLine.Underline);
                        if PayrollAnalysisColumn.FindSet then begin
                            repeat
                                ColumnValue := PayrollAnalysisReportMgt.CalcCell(PayrollAnalysisLine, PayrollAnalysisColumn, false);
                                if PayrollAnalysisReportMgt.GetDivisionError then
                                    ColumnValue := 0;
                                ColumnNo := ColumnNo + 1;
                                if ColumnValue <> 0 then
                                    EnterCell(
                                      RowNo,
                                      ColumnNo,
                                      Format(ColumnValue),
                                      PayrollAnalysisLine.Bold,
                                      PayrollAnalysisLine.Italic,
                                      PayrollAnalysisLine.Underline)
                                else
                                    EnterCell(
                                      RowNo,
                                      ColumnNo,
                                      '',
                                      PayrollAnalysisLine.Bold,
                                      PayrollAnalysisLine.Italic,
                                      PayrollAnalysisLine.Underline);
                            until PayrollAnalysisColumn.Next() = 0;
                        end;
                    until PayrollAnalysisLine.Next() = 0;
                end;

                Window.Close;

                if Option = Option::"Update Workbook" then begin
#if not CLEAN17
                    FileName := FileMgt.OpenFileDialog(Text002, FileName, '');
#else
                    FileName := FileMgt.UploadFile(Text002, FileName);
#endif
                    SheetName := TempExcelBuffer.SelectSheetsName(FileName);
                    TempExcelBuffer.UpdateBook(FileName, SheetName);
                    TempExcelBuffer.WriteSheet('', CompanyName, UserId);
                end else begin
                    if SheetName = '' then
                        SheetName := AnalysisTemplateName;
                    if ServerFileName <> '' then
                        TempExcelBuffer.CreateBook(ServerFileName, SheetName)
                    else
                        TempExcelBuffer.CreateBook('', SheetName);
                    TempExcelBuffer.WriteSheet(AnalysisTemplateName, CompanyName, UserId);
                end;
                if not TestMode then begin
                    TempExcelBuffer.CloseBook;
                    TempExcelBuffer.OpenExcel;
                end;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                field(SheetName; SheetName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sheet Name';
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        Text000: Label 'Analyzing Data...\\';
        Text001: Label 'Filters';
        Text002: Label 'Update Workbook';
        PayrollAnalysisLineTemplate: Record "Payroll Analysis Line Template";
        PayrollAnalysisLine: Record "Payroll Analysis Line";
        PayrollAnalysisColumn: Record "Payroll Analysis Column";
        TempExcelBuffer: Record "Excel Buffer" temporary;
        GLSetup: Record "General Ledger Setup";
        PayrollAnalysisView: Record "Payroll Analysis View";
        Currency: Record Currency;
        PayrollAnalysisReportMgt: Codeunit "Payroll Analysis Report Mgt.";
        FileMgt: Codeunit "File Management";
        ColumnValue: Decimal;
        ServerFileName: Text;
        FileName: Text[250];
        UploadedFileName: Text[1024];
        SheetName: Text[250];
        Option: Option "Create Workbook","Update Workbook";
        AnalysisTemplateName: Code[10];
        [InDataSet]
        FileNameEnable: Boolean;
        [InDataSet]
        SheetNameEnable: Boolean;
        TestMode: Boolean;

    [Scope('OnPrem')]
    procedure SetOptions(var PayrollAnalysisLine2: Record "Payroll Analysis Line"; ColumnLayoutName2: Code[10]; NewAnalysisTemplateName: Code[10])
    begin
        AnalysisTemplateName := NewAnalysisTemplateName;
        PayrollAnalysisLine.CopyFilters(PayrollAnalysisLine2);
        PayrollAnalysisLine := PayrollAnalysisLine2;
        PayrollAnalysisLine.SetFilter("Analysis Line Template Name", NewAnalysisTemplateName);
        PayrollAnalysisColumn.SetRange("Analysis Column Template", ColumnLayoutName2);
    end;

    local procedure EnterFilterInCell(RowNo: Integer; "Filter": Text[250]; FieldName: Text[100])
    begin
        if Filter <> '' then begin
            EnterCell(RowNo, 1, FieldName, false, false, false);
            EnterCell(RowNo, 2, Filter, false, false, false);
        end;
    end;

    local procedure EnterCell(RowNo: Integer; ColumnNo: Integer; CellValue: Text[250]; Bold: Boolean; Italic: Boolean; UnderLine: Boolean)
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

    local procedure GetDimFilterCaption(DimFilterNo: Integer): Text[80]
    var
        Dimension: Record Dimension;
    begin
        if PayrollAnalysisLineTemplate."Payroll Analysis View Code" = '' then
            case DimFilterNo of
                1:
                    Dimension.Get(GLSetup."Global Dimension 1 Code");
                2:
                    Dimension.Get(GLSetup."Global Dimension 2 Code");
            end
        else
            case DimFilterNo of
                1:
                    Dimension.Get(PayrollAnalysisView."Dimension 1 Code");
                2:
                    Dimension.Get(PayrollAnalysisView."Dimension 2 Code");
                3:
                    Dimension.Get(PayrollAnalysisView."Dimension 3 Code");
            end;
        exit(CopyStr(Dimension.GetMLFilterCaption(GlobalLanguage), 1, 80));
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        ServerFileName := NewFileName;
    end;

    [Scope('OnPrem')]
    procedure SetTestMode(NewTestMode: Boolean)
    begin
        TestMode := NewTestMode;
    end;
}

