page 6071 "Contract Gain/Loss (Contracts)"
{
    ApplicationArea = Service;
    Caption = 'Contract Gain/Loss (Contract)';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    RefreshOnActivate = true;
    SaveValues = true;
    SourceTable = Date;
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(PeriodStart; PeriodStart)
                {
                    ApplicationArea = Service;
                    Caption = 'Period Start';
                    ToolTip = 'Specifies the starting date of the period that you want to view.';
                }
            }
            group(Filters)
            {
                Caption = 'Filters';
                field(ContractFilter; ContractFilter)
                {
                    ApplicationArea = Service;
                    Caption = 'Contract No. Filter';
                    ToolTip = 'Specifies the service contract number for which you want to view gains or losses.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        ServContract.Reset();
                        ServContract.SetRange("Contract Type", ServContract."Contract Type"::Contract);
                        if PAGE.RunModal(0, ServContract) = ACTION::LookupOK then begin
                            Text := ServContract."Contract No.";
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_GenerateColumnCaptions(SetWanted::Initial);
                        ContractFilterOnAfterValidate;
                    end;
                }
            }
            group("Matrix Options")
            {
                Caption = 'Matrix Options';
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Service;
                    Caption = 'View by';
                    OptionCaption = 'Day,Week,Month,Quarter,Year';
                    ToolTip = 'Specifies by which period amounts are displayed.';
                }
                field(AmountType; AmountType)
                {
                    ApplicationArea = Service;
                    Caption = 'View as';
                    OptionCaption = 'Net Change,Balance at Date';
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';
                }
                field(MATRIX_CaptionRange; MATRIX_CaptionRange)
                {
                    ApplicationArea = Service;
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
                ApplicationArea = Service;
                Caption = '&Show Matrix';
                Image = ShowMatrix;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'View the data overview according to the selected filters and options.';

                trigger OnAction()
                var
                    MatrixForm: Page "Contr. G/Loss (Contr.) Matrix";
                begin
                    if PeriodStart = 0D then
                        PeriodStart := WorkDate;
                    Clear(MatrixForm);

                    MatrixForm.Load(MATRIX_CaptionSet, MatrixRecords, MATRIX_CurrentNoOfColumns, AmountType, PeriodType,
                      ContractFilter, PeriodStart);
                    MatrixForm.RunModal;
                end;
            }
            action("Previous Set")
            {
                ApplicationArea = Service;
                Caption = 'Previous Set';
                Image = PreviousSet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Go to the previous set of data.';

                trigger OnAction()
                begin
                    MATRIX_GenerateColumnCaptions(SetWanted::Previous);
                end;
            }
            action("Next Set")
            {
                ApplicationArea = Service;
                Caption = 'Next Set';
                Image = NextSet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Go to the next set of data.';

                trigger OnAction()
                begin
                    MATRIX_GenerateColumnCaptions(SetWanted::Next);
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(true);
    end;

    trigger OnOpenPage()
    begin
        if PeriodStart = 0D then
            PeriodStart := WorkDate;
        MATRIX_GenerateColumnCaptions(SetWanted::Initial);
    end;

    var
        ServContract: Record "Service Contract Header";
        MatrixRecords: array[32] of Record "Service Contract Header";
        MatrixRecord: Record "Service Contract Header";
        MATRIX_CaptionSet: array[32] of Text[80];
        MATRIX_CaptionRange: Text;
        PKFirstRecInCurrSet: Text;
        MATRIX_CurrentNoOfColumns: Integer;
        AmountType: Option "Net Change","Balance at Date";
        PeriodType: Option Day,Week,Month,Quarter,Year;
        ContractFilter: Text[250];
        PeriodStart: Date;
        SetWanted: Option Initial,Previous,Same,Next;

    local procedure MATRIX_GenerateColumnCaptions(SetWanted: Option First,Previous,Same,Next)
    var
        MatrixMgt: Codeunit "Matrix Management";
        RecRef: RecordRef;
        CurrentMatrixRecordOrdinal: Integer;
    begin
        Clear(MATRIX_CaptionSet);
        Clear(MatrixRecords);
        CurrentMatrixRecordOrdinal := 1;
        if ContractFilter <> '' then
            MatrixRecord.SetFilter("Contract No.", ContractFilter)
        else
            MatrixRecord.SetRange("Contract No.");

        RecRef.GetTable(MatrixRecord);
        RecRef.SetTable(MatrixRecord);

        MatrixMgt.GenerateMatrixData(RecRef, SetWanted, ArrayLen(MatrixRecords), 1, PKFirstRecInCurrSet,
          MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
        if MATRIX_CurrentNoOfColumns > 0 then begin
            MatrixRecord.SetPosition(PKFirstRecInCurrSet);
            MatrixRecord.Find;
            repeat
                MatrixRecords[CurrentMatrixRecordOrdinal].Copy(MatrixRecord);
                CurrentMatrixRecordOrdinal := CurrentMatrixRecordOrdinal + 1;
            until (CurrentMatrixRecordOrdinal > MATRIX_CurrentNoOfColumns) or (MatrixRecord.Next <> 1);
        end;
    end;

    local procedure ContractFilterOnAfterValidate()
    begin
        CurrPage.Update(true);
    end;
}

