page 563 "G/L Entries Dimension Overview"
{
    Caption = 'G/L Entries Dimension Overview';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SourceTable = "G/L Entry";

    layout
    {
        area(content)
        {
            group("Matrix Options")
            {
                Caption = 'Matrix Options';
                field(MATRIX_CaptionRange; MATRIX_CaptionRange)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Column Set';
                    Editable = false;
                    ToolTip = 'Specifies the range of values that are displayed in the matrix window, for example, the total period. To change the contents of the field, choose Next Set or Previous Set.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ShowMatrix)
            {
                ApplicationArea = Dimensions;
                Caption = '&Show Matrix';
                Image = ShowMatrix;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'View the data overview according to the selected filters and options.';

                trigger OnAction()
                var
                    MatrixForm: Page "G/L Entries Dim. Overv. Matrix";
                begin
                    Clear(MatrixForm);
                    MatrixForm.Load(MATRIX_CaptionSet, MATRIX_PKFirstCaptionInCurrSet, MATRIX_CurrSetLength);
                    if RunOnTempRec then
                        MatrixForm.SetTempGLEntry(TempGLEntry)
                    else
                        MatrixForm.SetTableView(Rec);
                    MatrixForm.RunModal;
                end;
            }
            action("Previous Set")
            {
                ApplicationArea = Dimensions;
                Caption = 'Previous Set';
                Image = PreviousSet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Go to the previous set of data.';

                trigger OnAction()
                var
                    MATRIX_Step: Option First,Previous,Same,Next;
                begin
                    MATRIX_GenerateColumnCaptions(MATRIX_Step::Previous);
                end;
            }
            action("Next Set")
            {
                ApplicationArea = Dimensions;
                Caption = 'Next Set';
                Image = NextSet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Go to the next set of data.';

                trigger OnAction()
                var
                    MATRIX_Step: Option First,Previous,Same,Next;
                begin
                    MATRIX_GenerateColumnCaptions(MATRIX_Step::Next);
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        MATRIX_Step: Option First,Previous,Same,Next;
    begin
        MATRIX_GenerateColumnCaptions(MATRIX_Step::First);
    end;

    var
        MatrixRecord: Record Dimension;
        TempGLEntry: Record "G/L Entry" temporary;
        RunOnTempRec: Boolean;
        MATRIX_CaptionSet: array[32] of Text[80];
        MATRIX_PKFirstCaptionInCurrSet: Text;
        MATRIX_CaptionRange: Text;
        MATRIX_CurrSetLength: Integer;

    procedure SetTempGLEntry(var NewGLEntry: Record "G/L Entry")
    begin
        RunOnTempRec := true;
        TempGLEntry.DeleteAll();
        if NewGLEntry.Find('-') then
            repeat
                TempGLEntry := NewGLEntry;
                TempGLEntry.Insert();
            until NewGLEntry.Next = 0;
    end;

    local procedure MATRIX_GenerateColumnCaptions(Step: Option First,Previous,Same,Next)
    var
        MatrixMgt: Codeunit "Matrix Management";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(MatrixRecord);
        RecRef.SetTable(MatrixRecord);

        MatrixMgt.GenerateMatrixData(RecRef, Step, ArrayLen(MATRIX_CaptionSet)
          , 1, MATRIX_PKFirstCaptionInCurrSet, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrSetLength);
    end;
}

