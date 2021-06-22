page 2181 "O365 Excel Sheet Data SubPage"
{
    Caption = 'O365 Excel Sheet Data SubPage';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Integer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Number; Number)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Row No.';
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the Excel row number.';
                }
                field(Column1; CellValue[1])
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    CaptionClass = '3,' + ColumnCaptions[1];
                    Caption = 'Column 1';
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = ShowColumn1;
                }
                field(Column2; CellValue[2])
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    CaptionClass = '3,' + ColumnCaptions[2];
                    Caption = 'Column 2';
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = ShowColumn2;
                }
                field(Column3; CellValue[3])
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    CaptionClass = '3,' + ColumnCaptions[3];
                    Caption = 'Column 3';
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = ShowColumn3;
                }
                field(Column4; CellValue[4])
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    CaptionClass = '3,' + ColumnCaptions[4];
                    Caption = 'Column 4';
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = ShowColumn4;
                }
                field(Column5; CellValue[5])
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    CaptionClass = '3,' + ColumnCaptions[5];
                    Caption = 'Column 5';
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = ShowColumn5;
                }
                field(Column6; CellValue[6])
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    CaptionClass = '3,' + ColumnCaptions[6];
                    Caption = 'Column 6';
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = ShowColumn6;
                }
                field(Column7; CellValue[7])
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    CaptionClass = '3,' + ColumnCaptions[7];
                    Caption = 'Column 7';
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = ShowColumn7;
                }
                field(Column8; CellValue[8])
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    CaptionClass = '3,' + ColumnCaptions[8];
                    Caption = 'Column 8';
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = ShowColumn8;
                }
                field(Column9; CellValue[9])
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    CaptionClass = '3,' + ColumnCaptions[9];
                    Caption = 'Column 9';
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = ShowColumn9;
                }
                field(Column10; CellValue[10])
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    CaptionClass = '3,' + ColumnCaptions[10];
                    Caption = 'Column 10';
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = ShowColumn10;
                }
                field(Column11; CellValue[11])
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    CaptionClass = '3,' + ColumnCaptions[11];
                    Caption = 'Column 11';
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = ShowColumn11;
                }
                field(Column12; CellValue[12])
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    CaptionClass = '3,' + ColumnCaptions[12];
                    Caption = 'Column 12';
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = ShowColumn12;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        i: Integer;
    begin
        Clear(CellValue);

        TempExcelBuffer.SetRange("Row No.", Number);
        if TempExcelBuffer.FindSet then
            repeat
                i += 1;
                CellValue[i] := TempExcelBuffer."Cell Value as Text";
            until (TempExcelBuffer.Next = 0) or (i = ArrayLen(CellValue));

        if UseEmphasizing then
            Emphasize := Number = StartRowNo;
    end;

    trigger OnOpenPage()
    begin
        SetDefaultColumnVisibility;
    end;

    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TempO365FieldExcelMapping: Record "O365 Field Excel Mapping" temporary;
        CellValue: array[12] of Text;
        ColumnCaptions: array[12] of Text;
        StartRowNo: Integer;
        [InDataSet]
        Emphasize: Boolean;
        UseEmphasizing: Boolean;
        ShowColumn1: Boolean;
        ShowColumn2: Boolean;
        ShowColumn3: Boolean;
        ShowColumn4: Boolean;
        ShowColumn5: Boolean;
        ShowColumn6: Boolean;
        ShowColumn7: Boolean;
        ShowColumn8: Boolean;
        ShowColumn9: Boolean;
        ShowColumn10: Boolean;
        ShowColumn11: Boolean;
        ShowColumn12: Boolean;

    procedure SetExcelBuffer(var NewExcelBuffer: Record "Excel Buffer")
    begin
        ClearExcelBuffer;
        if NewExcelBuffer.FindSet then
            repeat
                TempExcelBuffer := NewExcelBuffer;
                TempExcelBuffer.Insert();
            until NewExcelBuffer.Next = 0;
        CreateLines;
    end;

    local procedure ClearExcelBuffer()
    begin
        TempExcelBuffer.Reset();
        TempExcelBuffer.DeleteAll();
    end;

    local procedure ClearColumnMappingBuffer()
    begin
        TempO365FieldExcelMapping.Reset();
        TempO365FieldExcelMapping.DeleteAll();
    end;

    local procedure CreateLines()
    var
        i: Integer;
    begin
        Reset;
        DeleteAll();
        TempExcelBuffer.Reset();
        if TempExcelBuffer.FindLast then;
        for i := 1 to TempExcelBuffer."Row No." do begin
            Number := i;
            Insert;
        end;
        if FindFirst then;
    end;

    procedure SetStartRowNo(NewStartRowNo: Integer)
    begin
        StartRowNo := NewStartRowNo;
    end;

    procedure SetColumnMapping(var NewO365FieldExcelMapping: Record "O365 Field Excel Mapping")
    begin
        ClearColumnMappingBuffer;
        if NewO365FieldExcelMapping.FindSet then
            repeat
                TempO365FieldExcelMapping := NewO365FieldExcelMapping;
                TempO365FieldExcelMapping.Insert();
            until NewO365FieldExcelMapping.Next = 0;
    end;

    procedure SetColumnVisibility()
    var
        i: Integer;
    begin
        ShowColumn1 := FieldHasMapping(1);
        ShowColumn2 := FieldHasMapping(2);
        ShowColumn3 := FieldHasMapping(3);
        ShowColumn4 := FieldHasMapping(4);
        ShowColumn5 := FieldHasMapping(5);
        ShowColumn6 := FieldHasMapping(6);
        ShowColumn7 := FieldHasMapping(7);
        ShowColumn8 := FieldHasMapping(8);
        ShowColumn9 := FieldHasMapping(9);
        ShowColumn10 := FieldHasMapping(10);
        ShowColumn11 := FieldHasMapping(11);
        ShowColumn12 := FieldHasMapping(12);

        for i := 1 to ArrayLen(ColumnCaptions) do begin
            TempO365FieldExcelMapping.SetRange("Excel Column No.", i);
            if TempO365FieldExcelMapping.FindFirst then begin
                TempO365FieldExcelMapping.CalcFields("Field Name");
                ColumnCaptions[i] := TempO365FieldExcelMapping."Field Name";
            end;
        end;
    end;

    procedure SetDefaultColumnVisibility()
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(ColumnCaptions) do
            ColumnCaptions[i] := StrSubstNo('Column %1', i);
        ShowColumn1 := true;
        ShowColumn2 := true;
        ShowColumn3 := true;
        ShowColumn4 := true;
        ShowColumn5 := true;
        ShowColumn6 := true;
        ShowColumn7 := true;
        ShowColumn8 := true;
        ShowColumn9 := true;
        ShowColumn10 := true;
        ShowColumn11 := true;
        ShowColumn12 := true;
    end;

    local procedure FieldHasMapping(i: Integer): Boolean
    begin
        TempO365FieldExcelMapping.SetRange("Excel Column No.", i);
        exit(not TempO365FieldExcelMapping.IsEmpty);
    end;

    procedure SetRowNoFilter()
    begin
        SetFilter(Number, '%1..', StartRowNo);
        CurrPage.Update(false);
    end;

    procedure SetUseEmphasizing()
    begin
        UseEmphasizing := true;
    end;
}

