#if not CLEAN19
report 31083 "Exp. Acc. Sched. Res. to Excel"
{
    Caption = 'Exp. Acc. Sched. Res. to Excel (Obsolete)';
    ProcessingOnly = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '19.0';

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
                if DoUpdateExistingWorksheet then begin
                    ServerFileName := FileMgt.UploadFile(Text001, FileExtTxt);
                    if ServerFileName = '' then
                        exit;
                    SheetName := TempExcelBuffer.SelectSheetsName(ServerFileName);
                    if SheetName = '' then
                        exit;
                end;

                Window.Open(
                  Text000 +
                  '@1@@@@@@@@@@@@@@@@@@@@@\');
                Window.Update(1, 0);
                AccScheduleResultLine.SetRange("Result Code", AccScheduleResultHeader."Result Code");
                AccScheduleResultColumn.SetRange("Result Code", AccScheduleResultHeader."Result Code");
                TotalRecNo := AccScheduleResultLine.Count();
                RecNo := 0;

                TempExcelBuffer.DeleteAll();
                Clear(TempExcelBuffer);

                GLSetup.Get();

                RowNo := 1;
                EnterCell(RowNo, 1, AccScheduleResultHeader.FieldCaption(Description), false, false, true);
                EnterCell(RowNo, 2, AccScheduleResultHeader.Description, false, false, true);

                RowNo := RowNo + 1;
                EnterFilterInCell(
                  RowNo,
                  AccScheduleResultHeader."Date Filter",
                  AccScheduleResultHeader.FieldCaption("Date Filter"));

                RowNo := RowNo + 1;
                if UseAmtsInAddCurr then begin
                    if GLSetup."Additional Reporting Currency" <> '' then begin
                        RowNo := RowNo + 1;
                        EnterFilterInCell(
                          RowNo,
                          GLSetup."Additional Reporting Currency",
                          Currency.TableCaption())
                    end;
                end else
                    if GLSetup."LCY Code" <> '' then begin
                        RowNo := RowNo + 1;
                        EnterFilterInCell(
                          RowNo,
                          GLSetup."LCY Code",
                          Currency.TableCaption());
                    end;

                RowNo := RowNo + 1;
                if AccScheduleResultLine.FindSet() then begin
                    if AccScheduleResultColumn.FindSet() then begin
                        RowNo := RowNo + 1;
                        ColumnNo := 1;
                        repeat
                            ColumnNo := ColumnNo + 1;
                            EnterCell(
                              RowNo,
                              ColumnNo,
                              AccScheduleResultColumn."Column Header",
                              false,
                              false,
                              false);
                        until AccScheduleResultColumn.Next() = 0;
                    end;
                    repeat
                        RecNo := RecNo + 1;
                        Window.Update(1, Round(RecNo / TotalRecNo * 10000, 1));
                        RowNo := RowNo + 1;
                        ColumnNo := 1;
                        EnterCell(
                          RowNo,
                          ColumnNo,
                          AccScheduleResultLine.Description,
                          AccScheduleResultLine.Bold,
                          AccScheduleResultLine.Italic,
                          AccScheduleResultLine.Underline);
                        if AccScheduleResultColumn.FindSet() then begin
                            repeat
                                AccScheduleResultValue.Get(
                                  AccScheduleResultHeader."Result Code",
                                  AccScheduleResultLine."Line No.",
                                  AccScheduleResultColumn."Line No.");
                                ColumnValue := AccScheduleResultValue.Value;
                                ColumnNo := ColumnNo + 1;
                                if ColumnValue <> 0 then
                                    EnterCell(
                                      RowNo,
                                      ColumnNo,
                                      Format(ColumnValue),
                                      AccScheduleResultLine.Bold,
                                      AccScheduleResultLine.Italic,
                                      AccScheduleResultLine.Underline)
                                else
                                    EnterCell(
                                      RowNo,
                                      ColumnNo,
                                      '',
                                      AccScheduleResultLine.Bold,
                                      AccScheduleResultLine.Italic,
                                      AccScheduleResultLine.Underline);
                            until AccScheduleResultColumn.Next() = 0;
                        end;
                    until AccScheduleResultLine.Next() = 0;
                end;

                Window.Close();
                AccSchedName.Get(AccScheduleResultHeader."Acc. Schedule Name");
                if DoUpdateExistingWorksheet then begin
                    TempExcelBuffer.UpdateBook(ServerFileName, SheetName);
                    TempExcelBuffer.WriteSheet('', CompanyName, UserId);
                    TempExcelBuffer.CloseBook();
                    TempExcelBuffer.DownloadAndOpenExcel();
                end else begin
                    TempExcelBuffer.CreateBook('', AccSchedName.Name);
                    TempExcelBuffer.WriteSheet(AccSchedName.Description, CompanyName, UserId);
                    TempExcelBuffer.CloseBook();
                    TempExcelBuffer.OpenExcel();
                end;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

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
        Text000: Label 'Analyzing Data...\\';
        Text001: Label 'Update Workbook';
        AccSchedName: Record "Acc. Schedule Name";
        AccScheduleResultHeader: Record "Acc. Schedule Result Header";
        AccScheduleResultLine: Record "Acc. Schedule Result Line";
        AccScheduleResultColumn: Record "Acc. Schedule Result Column";
        TempExcelBuffer: Record "Excel Buffer" temporary;
        GLSetup: Record "General Ledger Setup";
        AccScheduleResultValue: Record "Acc. Schedule Result Value";
        Currency: Record Currency;
        UseAmtsInAddCurr: Boolean;
        ColumnValue: Decimal;
        FileMgt: Codeunit "File Management";
        ServerFileName: Text;
        FileExtTxt: Label '.xlsx', Comment = '.xlsx';
        SheetName: Text[250];
        DoUpdateExistingWorksheet: Boolean;

    [Scope('OnPrem')]
    procedure SetOptions(AccScheduleResultHeaderCode: Code[20]; UseAmtsInAddCurr2: Boolean)
    begin
        AccScheduleResultHeader.Get(AccScheduleResultHeaderCode);

        UseAmtsInAddCurr := UseAmtsInAddCurr2;
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

    [Scope('OnPrem')]
    procedure SetUpdateExistingWorksheet(UpdateExistingWorksheet: Boolean)
    begin
        DoUpdateExistingWorksheet := UpdateExistingWorksheet;
    end;
}
#endif
