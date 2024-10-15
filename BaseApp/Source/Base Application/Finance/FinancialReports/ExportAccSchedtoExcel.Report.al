namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Environment;
using System.IO;
using System.Utilities;

report 29 "Export Acc. Sched. to Excel"
{
    Caption = 'Export Acc. Sched. to Excel';
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnAfterGetRecord()
            var
                Company: Record Company;
                Window: Dialog;
                RecNo: Integer;
                TotalRecNo: Integer;
                RowNo: Integer;
                ColumnNo: Integer;
                CompanyDisplayName, ClientFileName : Text;
            begin
                if DoUpdateExistingWorksheet then
                    if not UploadClientFile(ClientFileName, ServerFileName) then
                        exit;

                Window.Open(
                  Text000 +
                  '@1@@@@@@@@@@@@@@@@@@@@@\');
                Window.Update(1, 0);
                AccSchedLine.SetFilter(Show, '<>%1', AccSchedLine.Show::No);
                OnIntegerOnAfterGetRecordOnAfterAccSchedLineSetFilter(AccSchedLine);
                TotalRecNo := AccSchedLine.Count();
                RecNo := 0;

                TempExcelBuffer.DeleteAll();
                Clear(TempExcelBuffer);

                AccSchedName.Get(AccSchedLine.GetRangeMin("Schedule Name"));
                AccSchedManagement.CheckAnalysisView(AccSchedName.Name, ColumnLayout.GetRangeMin("Column Layout Name"), true);
                if AccSchedName."Analysis View Name" <> '' then
                    AnalysisView.Get(AccSchedName."Analysis View Name");
                GLSetup.Get();

                RowNo := 1;
                EnterCell(RowNo, 1, Text001, false, false, true, false, '', TempExcelBuffer."Cell Type"::Text);
                EnterFilterInCell(
                  RowNo, AccSchedLine.GetFilter("Date Filter"), AccSchedLine.FieldCaption("Date Filter"),
                  '', TempExcelBuffer."Cell Type"::Text);
                EnterFilterInCell(
                  RowNo, AccSchedLine.GetFilter("G/L Budget Filter"), AccSchedLine.FieldCaption("G/L Budget Filter"),
                  '', TempExcelBuffer."Cell Type"::Text);
                EnterFilterInCell(
                  RowNo, AccSchedLine.GetFilter("Cost Budget Filter"), AccSchedLine.FieldCaption("Cost Budget Filter"),
                  '', TempExcelBuffer."Cell Type"::Text);
                EnterFilterInCell(
                  RowNo, AccSchedLine.GetFilter("Cost Center Filter"), AccSchedLine.FieldCaption("Cost Center Filter"),
                  '', TempExcelBuffer."Cell Type"::Text);
                EnterFilterInCell(
                  RowNo, AccSchedLine.GetFilter("Cost Object Filter"), AccSchedLine.FieldCaption("Cost Object Filter"),
                  '', TempExcelBuffer."Cell Type"::Text);
                EnterFilterInCell(
                  RowNo, AccSchedLine.GetFilter("Cash Flow Forecast Filter"), AccSchedLine.FieldCaption("Cash Flow Forecast Filter"),
                  '', TempExcelBuffer."Cell Type"::Text);

                if ((AccSchedName."Analysis View Name" = '') and (GLSetup."Global Dimension 1 Code" <> '')) or
                   ((AccSchedName."Analysis View Name" <> '') and (AnalysisView."Dimension 1 Code" <> ''))
                then
                    EnterFilterInCell(
                      RowNo, AccSchedLine.GetFilter("Dimension 1 Filter"), GetDimFilterCaption(1), '', TempExcelBuffer."Cell Type"::Text);
                if ((AccSchedName."Analysis View Name" = '') and (GLSetup."Global Dimension 2 Code" <> '')) or
                   ((AccSchedName."Analysis View Name" <> '') and (AnalysisView."Dimension 2 Code" <> ''))
                then
                    EnterFilterInCell(
                      RowNo, AccSchedLine.GetFilter("Dimension 2 Filter"), GetDimFilterCaption(2), '', TempExcelBuffer."Cell Type"::Text);
                if (AccSchedName."Analysis View Name" = '') or
                   ((AccSchedName."Analysis View Name" <> '') and (AnalysisView."Dimension 3 Code" <> ''))
                then
                    EnterFilterInCell(
                      RowNo, AccSchedLine.GetFilter("Dimension 3 Filter"), GetDimFilterCaption(3), '', TempExcelBuffer."Cell Type"::Text);
                if (AccSchedName."Analysis View Name" = '') or
                   ((AccSchedName."Analysis View Name" <> '') and (AnalysisView."Dimension 4 Code" <> ''))
                then
                    EnterFilterInCell(
                      RowNo, AccSchedLine.GetFilter("Dimension 4 Filter"), GetDimFilterCaption(4), '', TempExcelBuffer."Cell Type"::Text);

                RowNo := RowNo + 1;
                if UseAmtsInAddCurr then
                    EnterFilterInCell(
                      RowNo, GLSetup."Additional Reporting Currency", Currency.TableCaption(), '', TempExcelBuffer."Cell Type"::Text)
                else
                    EnterFilterInCell(
                      RowNo, GLSetup."LCY Code", Currency.TableCaption(), '', TempExcelBuffer."Cell Type"::Text);

                RowNo := RowNo + 1;
                if AccSchedLine.Find('-') then begin
                    if ColumnLayout.Find('-') then begin
                        RowNo := RowNo + 1;
                        ColumnNo := 2; // Skip the "Row No." column.
                        repeat
                            ColumnNo := ColumnNo + 1;
                            EnterCell(
                              RowNo, ColumnNo, ColumnLayout."Column Header", false, false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                        until ColumnLayout.Next() = 0;
                    end;
                    repeat
                        RecNo := RecNo + 1;
                        Window.Update(1, Round(RecNo / TotalRecNo * 10000, 1));
                        RowNo := RowNo + 1;
                        ColumnNo := 1;
                        EnterCell(
                          RowNo, ColumnNo, AccSchedLine."Row No.",
                          AccSchedLine.Bold, AccSchedLine.Italic, AccSchedLine.Underline, AccSchedLine."Double Underline",
                          '0', TempExcelBuffer."Cell Type"::Text);
                        ColumnNo := 2;
                        EnterCell(
                          RowNo, ColumnNo, AccSchedLine.Description,
                          AccSchedLine.Bold, AccSchedLine.Italic, AccSchedLine.Underline, AccSchedLine."Double Underline",
                          '', TempExcelBuffer."Cell Type"::Text);
                        if ColumnLayout.Find('-') then
                            repeat
                                CalcColumnValue();
                                ColumnNo := ColumnNo + 1;
                                EnterCell(
                                  RowNo, ColumnNo, MatrixMgt.FormatAmount(ColumnValue, ColumnLayout."Rounding Factor", UseAmtsInAddCurr),
                                  AccSchedLine.Bold, AccSchedLine.Italic, AccSchedLine.Underline, AccSchedLine."Double Underline",
                                  '', TempExcelBuffer."Cell Type"::Number)
                            until ColumnLayout.Next() = 0;
                    until AccSchedLine.Next() = 0;
                end;

                Window.Close();

                Company.Get(CompanyName());
                CompanyDisplayName := Company."Display Name";
                if CompanyDisplayName = '' then
                    CompanyDisplayName := Company.Name;

                if DoUpdateExistingWorksheet then begin
                    TempExcelBuffer.UpdateBookExcel(ServerFileName, SheetName, false);
                    TempExcelBuffer.WriteSheet('', CompanyDisplayName, UserId);
                    TempExcelBuffer.CloseBook();
                    if not TestMode then
                        TempExcelBuffer.OpenExcelWithName(ClientFileName);
                end else begin
                    TempExcelBuffer.CreateBook(ServerFileName, AccSchedName.Name);
                    TempExcelBuffer.WriteSheet(AccSchedName.Description, CompanyDisplayName, UserId);
                    TempExcelBuffer.CloseBook();
                    if not TestMode then
                        TempExcelBuffer.OpenExcel();
                end;
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        AccSchedName: Record "Acc. Schedule Name";
        AccSchedLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        TempExcelBuffer: Record "Excel Buffer" temporary;
        GLSetup: Record "General Ledger Setup";
        AnalysisView: Record "Analysis View";
        Currency: Record Currency;
        AccSchedManagement: Codeunit AccSchedManagement;
        MatrixMgt: Codeunit "Matrix Management";
        FileMgt: Codeunit "File Management";
        UseAmtsInAddCurr: Boolean;
        ColumnValue: Decimal;
        ServerFileName: Text;
        SheetName: Text[250];
        DoUpdateExistingWorksheet: Boolean;
        TestMode: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Analyzing Data...\\';
        Text001: Label 'Filters';
        Text002: Label 'Update Workbook';
#pragma warning restore AA0074
        ExcelFileExtensionTok: Label '.xlsx', Locked = true;

    procedure SetOptions(var AccSchedLine2: Record "Acc. Schedule Line"; ColumnLayoutName2: Code[10]; UseAmtsInAddCurr2: Boolean)
    begin
        AccSchedLine.CopyFilters(AccSchedLine2);
        ColumnLayout.SetRange("Column Layout Name", ColumnLayoutName2);
        UseAmtsInAddCurr := UseAmtsInAddCurr2;
    end;

    local procedure CalcColumnValue()
    begin
        OnBeforeCalcColumnValue(UseAmtsInAddCurr, ColumnLayout);
        if AccSchedLine.Totaling = '' then
            ColumnValue := 0
        else begin
            ColumnValue := AccSchedManagement.CalcCell(AccSchedLine, ColumnLayout, UseAmtsInAddCurr);
            if AccSchedManagement.GetDivisionError() then
                ColumnValue := 0
        end;
        OnAferCalcColumnValue(UseAmtsInAddCurr, ColumnLayout);
    end;

    local procedure EnterFilterInCell(var RowNo: Integer; "Filter": Text[250]; FieldName: Text[100]; Format: Text[30]; CellType: Option)
    begin
        if Filter <> '' then begin
            RowNo := RowNo + 1;
            EnterCell(RowNo, 1, FieldName, false, false, false, false, '', TempExcelBuffer."Cell Type"::Text);
            EnterCell(RowNo, 2, Filter, false, false, false, false, Format, CellType);
        end;
    end;

    local procedure EnterCell(RowNo: Integer; ColumnNo: Integer; CellValue: Text[250]; Bold: Boolean; Italic: Boolean; UnderLine: Boolean; DoubleUnderLine: Boolean; Format: Text[30]; CellType: Option)
    begin
        TempExcelBuffer.Init();
        TempExcelBuffer.Validate("Row No.", RowNo);
        TempExcelBuffer.Validate("Column No.", ColumnNo);
        TempExcelBuffer."Cell Value as Text" := CellValue;
        TempExcelBuffer.Formula := '';
        TempExcelBuffer.Bold := Bold;
        TempExcelBuffer.Italic := Italic;
        if DoubleUnderLine = true then begin
            TempExcelBuffer."Double Underline" := true;
            TempExcelBuffer.Underline := false;
        end else begin
            TempExcelBuffer."Double Underline" := false;
            TempExcelBuffer.Underline := UnderLine;
        end;
        TempExcelBuffer.NumberFormat := Format;
        TempExcelBuffer."Cell Type" := CellType;
        TempExcelBuffer.Insert();
    end;

    local procedure GetDimFilterCaption(DimFilterNo: Integer): Text[80]
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

    procedure SetUpdateExistingWorksheet(UpdateExistingWorksheet: Boolean)
    begin
        DoUpdateExistingWorksheet := UpdateExistingWorksheet;
    end;

    procedure SetFileNameSilent(NewFileName: Text)
    begin
        ServerFileName := NewFileName;
    end;

    procedure SetTestMode(NewTestMode: Boolean)
    begin
        TestMode := NewTestMode;
    end;

    local procedure UploadClientFile(var ClientFileName: Text; var ServerFileName: Text): Boolean
    begin
        ServerFileName := FileMgt.UploadFile(Text002, ExcelFileExtensionTok);
        ClientFileName := FileMgt.GetFileName(ServerFileName);
        if ServerFileName = '' then
            exit(false);

        SheetName := TempExcelBuffer.SelectSheetsName(ServerFileName);
        if SheetName = '' then
            exit(false);

        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcColumnValue(var UseAmtsInAddCurr: Boolean; var ColumnLayout: Record "Column Layout")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAferCalcColumnValue(var UseAmtsInAddCurr: Boolean; var ColumnLayout: Record "Column Layout")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIntegerOnAfterGetRecordOnAfterAccSchedLineSetFilter(var AccScheduleLine: Record "Acc. Schedule Line")
    begin
    end;
}

