page 12148 "Vendor Aging"
{
    Caption = 'Vendor Aging';
    DataCaptionExpression = '';
    PageType = Card;
    SourceTable = Vendor;

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(RoundingFactor; RoundingFactor)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Rounding Factor';
                    OptionCaption = 'None,1,1000,1000000';
                    ToolTip = 'Specifies the rounding factor.';
                }
            }
            group("Matrix Options")
            {
                Caption = 'Matrix Options';
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View By';
                    OptionCaption = 'Day,Week,Month,Quarter,Year,Accounting Period';
                    ToolTip = 'Specifies how you want to see the data.';

                    trigger OnValidate()
                    begin
                        // FindPeriod('');;
                        PeriodTypeOnAfterValidate();
                    end;
                }
                field(AmountType; AmountType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View as';
                    OptionCaption = 'Period Balance,Balance at Date';
                    ToolTip = 'Specifies how you want to see the data.';
                }
                field(MATRIX_CaptionRange; MATRIX_CaptionRange)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Column Set';
                    Editable = false;
                    ToolTip = 'Specifies the column set.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Show Matrix")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Show Matrix';
                Image = ShowMatrix;
                ToolTip = 'Generate the overview of vendor aging amounts.';

                trigger OnAction()
                var
                    MatrixForm: Page "Vendor Aging Matrix";
                begin
                    Clear(MatrixForm);
                    MatrixForm.Load(MATRIX_CaptionSet, MatrixRecords, MATRIX_CurrentNoOfColumns, RoundingFactor, AmountType,
                      GetFilter("Global Dimension 1 Filter"), GetFilter("Global Dimension 2 Filter"));
                    MatrixForm.RunModal();
                end;
            }
            action("Next Set")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Set';
                Image = NextSet;
                ToolTip = 'Next Set';

                trigger OnAction()
                begin
                    MATRIX_GenerateColumnCaptions(SetWanted::Next);
                end;
            }
            action("Previous Set")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Set';
                Image = PreviousSet;
                ToolTip = 'Previous Set';

                trigger OnAction()
                begin
                    MATRIX_GenerateColumnCaptions(SetWanted::Previous);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Show Matrix_Promoted"; "&Show Matrix")
                {
                }
                actionref("Next Set_Promoted"; "Next Set")
                {
                }
                actionref("Previous Set_Promoted"; "Previous Set")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        MATRIX_GenerateColumnCaptions(SetWanted::Initial);
    end;

    var
        MatrixRecords: array[32] of Record Date;
        MATRIX_CaptionSet: array[32] of Text[1024];
        MATRIX_CaptionRange: Text[1024];
        MATRIX_PrimKeyFirstCaptionInCu: Text[1024];
        MATRIX_CurrentNoOfColumns: Integer;
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        AmountType: Option "Period Balance","Balance at Date";
        RoundingFactor: Option "None","1","1000","1000000";
        MATRIX_CurrentSetLength: Integer;
        SetWanted: Option Initial,Previous,Same,Next;

    [Scope('OnPrem')]
    procedure MATRIX_GenerateColumnCaptions(SetWanted: Option Initial,Previous,Same,Next)
    var
        MatrixMgt: Codeunit "Matrix Management";
    begin
        MatrixMgt.GeneratePeriodMatrixData(SetWanted, ArrayLen(MATRIX_CaptionSet), false, PeriodType, GetFilter("Date Filter"),
          MATRIX_PrimKeyFirstCaptionInCu, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentSetLength, MatrixRecords);
    end;

    local procedure PeriodTypeOnAfterValidate()
    begin
        MATRIX_GenerateColumnCaptions(SetWanted::Initial);
    end;
}

