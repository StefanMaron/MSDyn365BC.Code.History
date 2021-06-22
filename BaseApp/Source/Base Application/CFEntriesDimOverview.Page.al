page 860 "CF Entries Dim. Overview"
{
    Caption = 'CF Forcst. Entries Dimension Overview';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SourceTable = "Cash Flow Forecast Entry";

    layout
    {
        area(content)
        {
            group("Matrix Options")
            {
                Caption = 'Matrix Options';
                field(MATRIX_CaptionRange; MATRIX_CaptionRange)
                {
                    ApplicationArea = Suite;
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
                ApplicationArea = Suite;
                Caption = '&Show Matrix';
                Image = ShowMatrix;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'View the data overview according to the selected filters and options.';

                trigger OnAction()
                var
                    CFEntriesDimMatrix: Page "CF Entries Dim. Matrix";
                begin
                    Clear(CFEntriesDimMatrix);
                    CFEntriesDimMatrix.Load(MATRIX_CaptionSet, MATRIX_PKFirstCaptionInCurrSet, MATRIX_CurrSetLength);
                    if RunOnTempRec then
                        CFEntriesDimMatrix.SetTempCFForecastEntry(TempCFForecastEntry)
                    else
                        CFEntriesDimMatrix.SetTableView(Rec);
                    CFEntriesDimMatrix.RunModal;
                end;
            }
            action("Previous Set")
            {
                ApplicationArea = Suite;
                Caption = 'Previous Set';
                Image = PreviousSet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
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
                ApplicationArea = Suite;
                Caption = 'Next Set';
                Image = NextSet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
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
        TempCFForecastEntry: Record "Cash Flow Forecast Entry" temporary;
        Dimension: Record Dimension;
        RunOnTempRec: Boolean;
        MATRIX_CaptionSet: array[32] of Text[80];
        MATRIX_PKFirstCaptionInCurrSet: Text;
        MATRIX_CaptionRange: Text;
        MATRIX_CurrSetLength: Integer;

    procedure SetTempCFForecastEntry(var NewCFForecastEntry: Record "Cash Flow Forecast Entry")
    begin
        RunOnTempRec := true;
        TempCFForecastEntry.DeleteAll();
        if NewCFForecastEntry.Find('-') then
            repeat
                TempCFForecastEntry := NewCFForecastEntry;
                TempCFForecastEntry.Insert();
            until NewCFForecastEntry.Next = 0;
    end;

    local procedure MATRIX_GenerateColumnCaptions(Step: Option First,Previous,Same,Next)
    var
        MatrixMgt: Codeunit "Matrix Management";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Dimension);
        RecRef.SetTable(Dimension);

        MatrixMgt.GenerateMatrixData(RecRef, Step, ArrayLen(MATRIX_CaptionSet),
          1, MATRIX_PKFirstCaptionInCurrSet, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrSetLength);
    end;
}

