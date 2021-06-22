page 99000812 "Prod. BOM Matrix per Version"
{
    Caption = 'Prod. BOM Matrix per Version';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "Production Matrix BOM Line";

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(ShowLevel; ShowLevel)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Levels';
                    OptionCaption = 'Single,Multi';
                    ToolTip = 'Specifies a filter for this matrix. You can choose Single or Multi to show the lines in this filter.';

                    trigger OnValidate()
                    begin
                        ShowLevelOnAfterValidate;
                    end;
                }
            }
            group("Matrix Options")
            {
                Caption = 'Matrix Options';
                field(MATRIX_CaptionRange; MATRIX_CaptionRange)
                {
                    ApplicationArea = Manufacturing;
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
            action("&Show Matrix")
            {
                ApplicationArea = Manufacturing;
                Caption = '&Show Matrix';
                Image = ShowMatrix;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'View the data overview according to the selected filters and options.';

                trigger OnAction()
                var
                    MatrixForm: Page "Prod. BOM Mat. per Ver. Matrix";
                begin
                    Clear(MatrixForm);
                    MatrixForm.Load(MATRIX_CaptionSet, MatrixRecords, MATRIX_CurrSetLength, ProdBOM, ShowLevel);
                    MatrixForm.RunModal;
                end;
            }
            action("Previous Set")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Previous Set';
                Image = PreviousSet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Go to the previous set of data.';

                trigger OnAction()
                begin
                    MATRIX_GenerateMatrix(MATRIX_SetWanted::Previous);
                end;
            }
            action("Next Set")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Next Set';
                Image = NextSet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Go to the next set of data.';

                trigger OnAction()
                begin
                    MATRIX_GenerateMatrix(MATRIX_SetWanted::Next);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        BuildMatrix;
    end;

    var
        MatrixRecords: array[32] of Record "Production BOM Version";
        MATRIX_MatrixRecord: Record "Production BOM Version";
        ProdBOM: Record "Production BOM Header";
        BOMMatrixMgt: Codeunit "BOM Matrix Management";
        MATRIX_CaptionSet: array[32] of Text[80];
        MATRIX_CaptionRange: Text;
        ShowLevel: Option Single,Multi;
        MATRIX_SetWanted: Option First,Previous,Same,Next;
        PKFirstMatrixRecInSet: Text;
        MATRIX_CurrSetLength: Integer;

    procedure Set(var NewProdBOM: Record "Production BOM Header")
    begin
        ProdBOM.Copy(NewProdBOM);
    end;

    local procedure BuildMatrix()
    begin
        Clear(BOMMatrixMgt);
        BOMMatrixMgt.BOMMatrixFromBOM(ProdBOM, ShowLevel = ShowLevel::Multi);
        MATRIX_MatrixRecord.SetRange("Production BOM No.", ProdBOM."No.");
        MATRIX_GenerateMatrix(MATRIX_SetWanted::First);
    end;

    local procedure MATRIX_GenerateMatrix(SetWanted: Option First,Previous,Same,Next)
    var
        MatrixMgt: Codeunit "Matrix Management";
        RecRef: RecordRef;
        CurrentMatrixRecordOrdinal: Integer;
    begin
        Clear(MATRIX_CaptionSet);
        Clear(MatrixRecords);
        CurrentMatrixRecordOrdinal := 0;

        RecRef.GetTable(MATRIX_MatrixRecord);
        RecRef.SetTable(MATRIX_MatrixRecord);
        MatrixMgt.GenerateMatrixData(RecRef, SetWanted, ArrayLen(MatrixRecords), 2, PKFirstMatrixRecInSet, MATRIX_CaptionSet,
          MATRIX_CaptionRange, MATRIX_CurrSetLength);

        if MATRIX_CurrSetLength > 0 then begin
            MATRIX_MatrixRecord.SetPosition(PKFirstMatrixRecInSet);
            MATRIX_MatrixRecord.Find;

            repeat
                CurrentMatrixRecordOrdinal := CurrentMatrixRecordOrdinal + 1;
                MatrixRecords[CurrentMatrixRecordOrdinal].Copy(MATRIX_MatrixRecord);
            until (CurrentMatrixRecordOrdinal = MATRIX_CurrSetLength) or (MATRIX_MatrixRecord.Next <> 1);
        end;
    end;

    procedure SetCaption(): Text[80]
    begin
        exit(ProdBOM."No." + ' ' + ProdBOM.Description);
    end;

    local procedure ShowLevelOnAfterValidate()
    begin
        BuildMatrix;
        CurrPage.Update(false);
    end;
}

