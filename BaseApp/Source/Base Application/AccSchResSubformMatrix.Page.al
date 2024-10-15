page 31094 "Acc. Sch. Res. Subform Matrix"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Acc. Schedule Result Line";

    layout
    {
        area(content)
        {
            repeater(Control1220007)
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
                    ToolTip = 'Specifies the name of account schedule results.';
                }
                field(Field1; Value[1])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[1];
                    ToolTip = 'Specifies the value of acc. sch. res. subform matrix';
                    Visible = Field1Visible;

                    trigger OnAssistEdit()
                    begin
                        if Matrix_ColumnSet[1] <> 0 then
                            MatrixLookUp(Matrix_ColumnSet[1]);
                    end;

                    trigger OnValidate()
                    begin
                        Value1OnAfterValidate;
                    end;
                }
                field(Field2; Value[2])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[2];
                    ToolTip = 'Specifies the value of acc. sch. res. subform matrix';
                    Visible = Field2Visible;

                    trigger OnAssistEdit()
                    begin
                        if Matrix_ColumnSet[2] <> 0 then
                            MatrixLookUp(Matrix_ColumnSet[2]);
                    end;

                    trigger OnValidate()
                    begin
                        Value2OnAfterValidate;
                    end;
                }
                field(Field3; Value[3])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[3];
                    ToolTip = 'Specifies the value of acc. sch. res. subform matrix';
                    Visible = Field3Visible;

                    trigger OnAssistEdit()
                    begin
                        if Matrix_ColumnSet[3] <> 0 then
                            MatrixLookUp(Matrix_ColumnSet[3])
                    end;

                    trigger OnValidate()
                    begin
                        Value3OnAfterValidate;
                    end;
                }
                field(Field4; Value[4])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[4];
                    ToolTip = 'Specifies the value of acc. sch. res. subform matrix';
                    Visible = Field4Visible;

                    trigger OnAssistEdit()
                    begin
                        if Matrix_ColumnSet[4] <> 0 then
                            MatrixLookUp(Matrix_ColumnSet[4]);
                    end;

                    trigger OnValidate()
                    begin
                        Value4OnAfterValidate;
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        RecordFlag: Boolean;
    begin
        Clear(Value);
        AccSchedResultValue.Reset();
        AccSchedResultValue.SetRange("Result Code", "Result Code");
        AccSchedResultValue.SetRange("Row No.", "Line No.");
        AccSchedResultValue.SetFilter("Column No.", '%1..', Matrix_ColumnSet[1]);
        if AccSchedResultValue.Find('-') then
            for StackCounter := 1 to 4 do begin
                if StackCounter <> 1 then
                    if AccSchedResultValue.Next = 0 then
                        RecordFlag := true;
                if (not RecordFlag) and CheckValueRule(Matrix_ColumnSet[StackCounter]) then
                    UpdateValue(AccSchedResultValue.Value, StackCounter);
            end;
    end;

    trigger OnInit()
    begin
        Field4Visible := true;
        Field3Visible := true;
        Field2Visible := true;
        Field1Visible := true;
    end;

    var
        MatrixErr: Label 'Matrix column does not exists.';
        AccSchedResultValue: Record "Acc. Schedule Result Value";
        AccSchedResultHistory: Record "Acc. Schedule Result History";
        Value: array[4] of Decimal;
        ShowOnlyChangedValues: Boolean;
        Matrix_ColumnSet: array[4] of Integer;
        StackCounter: Integer;
        MATRIX_CaptionSet: array[4] of Text[1024];
        [InDataSet]
        Field1Visible: Boolean;
        [InDataSet]
        Field2Visible: Boolean;
        [InDataSet]
        Field3Visible: Boolean;
        [InDataSet]
        Field4Visible: Boolean;

    [Scope('OnPrem')]
    procedure UpdateValue(CelValue: Decimal; Counter: Integer)
    begin
        if Counter <> 0 then
            Value[Counter] := CelValue;
    end;

    [Scope('OnPrem')]
    procedure MatrixLookUp(ColumnNo: Integer)
    begin
        AccSchedResultHistory.SetRange("Result Code", "Result Code");
        AccSchedResultHistory.SetRange("Row No.", "Line No.");
        AccSchedResultHistory.SetRange("Column No.", ColumnNo);
        PAGE.Run(PAGE::"Acc. Schedule Result History", AccSchedResultHistory)
    end;

    [Scope('OnPrem')]
    procedure UpdateRecordValue(ColumnNo: Integer; ColumnValue: Decimal)
    begin
        if AccSchedResultValue.Get("Result Code", "Line No.", ColumnNo) then begin
            AccSchedResultValue.Validate(Value, ColumnValue);
            AccSchedResultValue.Modify();
        end else begin
            AccSchedResultValue."Result Code" := "Result Code";
            AccSchedResultValue."Row No." := "Line No.";
            AccSchedResultValue."Column No." := ColumnNo;
            AccSchedResultValue.Validate(Value, ColumnValue);
            AccSchedResultValue.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckValueRule(ColumnNo: Integer): Boolean
    var
        AccSchedResultHistory: Record "Acc. Schedule Result History";
    begin
        if not ShowOnlyChangedValues then
            exit(true);

        AccSchedResultHistory.SetRange("Result Code", "Result Code");
        AccSchedResultHistory.SetRange("Row No.", "Line No.");
        AccSchedResultHistory.SetRange("Column No.", ColumnNo);
        exit(not AccSchedResultHistory.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure SetShowOnlyChangeValue(NewShowOnlyChangedValues: Boolean)
    begin
        ShowOnlyChangedValues := NewShowOnlyChangedValues;
        CurrPage.Update(false);
    end;

    [Scope('OnPrem')]
    procedure Load(NewColumnStack: array[4] of Integer; NewColumnName: array[4] of Text[1024])
    begin
        Clear(Matrix_ColumnSet);
        Clear(MATRIX_CaptionSet);
        CopyArray(Matrix_ColumnSet, NewColumnStack, 1);
        CopyArray(MATRIX_CaptionSet, NewColumnName, 1);

        Field1Visible := MATRIX_CaptionSet[1] <> '';
        Field2Visible := MATRIX_CaptionSet[2] <> '';
        Field3Visible := MATRIX_CaptionSet[3] <> '';
        Field4Visible := MATRIX_CaptionSet[4] <> '';
    end;

    local procedure Value1OnAfterValidate()
    begin
        if Matrix_ColumnSet[1] <> 0 then
            UpdateRecordValue(Matrix_ColumnSet[1], Value[1])
        else
            Error(MatrixErr);
    end;

    local procedure Value2OnAfterValidate()
    begin
        if Matrix_ColumnSet[2] <> 0 then
            UpdateRecordValue(Matrix_ColumnSet[2], Value[2])
        else
            Error(MatrixErr);
    end;

    local procedure Value3OnAfterValidate()
    begin
        if Matrix_ColumnSet[3] <> 0 then
            UpdateRecordValue(Matrix_ColumnSet[3], Value[3])
        else
            Error(MatrixErr);
    end;

    local procedure Value4OnAfterValidate()
    begin
        if Matrix_ColumnSet[4] <> 0 then
            UpdateRecordValue(Matrix_ColumnSet[4], Value[4])
        else
            Error(MatrixErr);
    end;
}

