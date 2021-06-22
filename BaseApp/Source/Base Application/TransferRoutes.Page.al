page 5747 "Transfer Routes"
{
    AdditionalSearchTerms = 'transit route,in-transit';
    ApplicationArea = Location;
    Caption = 'Transfer Routes';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = Location;
    SourceTableView = WHERE("Use As In-Transit" = CONST(false));
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(Show; Show)
                {
                    ApplicationArea = Location;
                    Caption = 'Show';
                    OptionCaption = 'In-Transit Code,Shipping Agent Code,Shipping Agent Service Code';
                    ToolTip = 'Specifies if the selected value is shown in the window.';

                    trigger OnValidate()
                    begin
                        UpdateMatrixSubform;
                    end;
                }
                field(ShowTransferToName; ShowTransferToName)
                {
                    ApplicationArea = Location;
                    Caption = 'Show Transfer-to Name';
                    ToolTip = 'Specifies that the name of the transfer-to location is shown on the routing. ';

                    trigger OnValidate()
                    begin
                        ShowTransferToNameOnAfterValid;
                    end;
                }
                field(MATRIX_CaptionRange; MATRIX_CaptionRange)
                {
                    ApplicationArea = Location;
                    Caption = 'Column Set';
                    Editable = false;
                    ToolTip = 'Specifies the range of values that are displayed in the matrix window, for example, the total period. To change the contents of the field, choose Next Set or Previous Set.';
                }
            }
            part(MatrixForm; "Transfer Routes Matrix")
            {
                ApplicationArea = Location;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Previous Set")
            {
                ApplicationArea = Location;
                Caption = 'Previous Set';
                Image = PreviousSet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Go to the previous set of data.';

                trigger OnAction()
                begin
                    MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Previous);
                end;
            }
            action("Next Set")
            {
                ApplicationArea = Location;
                Caption = 'Next Set';
                Image = NextSet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Go to the next set of data.';

                trigger OnAction()
                begin
                    MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Next);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        MATRIX_MatrixRecord.SetRange("Use As In-Transit", false);
        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::First);
    end;

    var
        MATRIX_MatrixRecord: Record Location;
        MatrixRecords: array[32] of Record Location;
        MATRIX_CaptionSet: array[32] of Text[80];
        MATRIX_CaptionRange: Text;
        MATRIX_PKFirstRecInCurrSet: Text;
        MATRIX_CurrentNoOfColumns: Integer;
        ShowTransferToName: Boolean;
        Show: Option "In-Transit Code","Shipping Agent Code","Shipping Agent Service Code";
        MATRIX_SetWanted: Option First,Previous,Same,Next;

    local procedure MATRIX_GenerateColumnCaptions(SetWanted: Option First,Previous,Same,Next)
    var
        MatrixMgt: Codeunit "Matrix Management";
        RecRef: RecordRef;
        CurrentMatrixRecordOrdinal: Integer;
        CaptionField: Integer;
    begin
        Clear(MATRIX_CaptionSet);
        Clear(MatrixRecords);
        CurrentMatrixRecordOrdinal := 1;

        RecRef.GetTable(MATRIX_MatrixRecord);
        RecRef.SetTable(MATRIX_MatrixRecord);

        if ShowTransferToName then
            CaptionField := 2
        else
            CaptionField := 1;

        MatrixMgt.GenerateMatrixData(RecRef, SetWanted, ArrayLen(MatrixRecords), CaptionField, MATRIX_PKFirstRecInCurrSet, MATRIX_CaptionSet
          , MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);

        if MATRIX_CurrentNoOfColumns > 0 then begin
            MATRIX_MatrixRecord.SetPosition(MATRIX_PKFirstRecInCurrSet);
            MATRIX_MatrixRecord.Find;
            repeat
                MatrixRecords[CurrentMatrixRecordOrdinal].Copy(MATRIX_MatrixRecord);
                CurrentMatrixRecordOrdinal := CurrentMatrixRecordOrdinal + 1;
            until (CurrentMatrixRecordOrdinal > MATRIX_CurrentNoOfColumns) or (MATRIX_MatrixRecord.Next <> 1);
        end;

        UpdateMatrixSubform;
    end;

    local procedure ShowTransferToNameOnAfterValid()
    begin
        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Same);
    end;

    local procedure UpdateMatrixSubform()
    begin
        CurrPage.MatrixForm.PAGE.Load(MATRIX_CaptionSet, MatrixRecords, MATRIX_CurrentNoOfColumns, Show);
        CurrPage.MatrixForm.PAGE.SetRecord(Rec);
        CurrPage.Update;
    end;
}

