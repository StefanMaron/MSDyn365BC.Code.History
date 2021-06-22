report 1395 "Cancel Issued Fin.Charge Memos"
{
    AdditionalSearchTerms = 'cancel issued fin. charge memo';
    Caption = 'Cancel Issued Fin.Charge Memos';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Issued Fin. Charge Memo Header"; "Issued Fin. Charge Memo Header")
        {

            trigger OnAfterGetRecord()
            var
                TempErrorMessage: Record "Error Message" temporary;
                CancelIssuedFinChargeMemo: Codeunit "Cancel Issued Fin. Charge Memo";
            begin
                CancelIssuedFinChargeMemo.SetParameters(UseSameDocumentNo, UseSamePostingDate, NewPostingDate, NoOfRecords > 1);
                if CancelIssuedFinChargeMemo.Run("Issued Fin. Charge Memo Header") then begin
                    if CancelIssuedFinChargeMemo.GetErrorMessages(TempErrorMessage) then
                        AddIssuedFinChargeMemoHeaderToErrorBuffer;
                    Commit();
                end else begin
                    if NoOfRecords > 1 then begin
                        TempErrorMessage.LogLastError;
                        AddIssuedFinChargeMemoHeaderToErrorBuffer;
                    end else
                        Error(GetLastErrorText);
                end;
            end;

            trigger OnPostDataItem()
            begin
                if NoOfRecords > 1 then begin
                    if not TempIssuedFinChargeMemoHeader.IsEmpty then
                        AskShowNotCancelledIssuedFinChargeMemos;
                end;
            end;

            trigger OnPreDataItem()
            begin
                NoOfRecords := Count;
                if NoOfRecords = 0 then
                    Error(NothingToCancelErr);

                if not UseSamePostingDate and (NewPostingDate = 0D) then
                    Error(SpecifyPostingDateErr);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                field(UseSameDocumentNo; UseSameDocumentNo)
                {
                    ApplicationArea = Suite;
                    Caption = 'Use Same Document No.';
                    ToolTip = 'Specifies if you want to use the same document number for corrective ledger entries. If you do not select the check box, then a document number will be assigned from the Canceled Issued Fin. Ch. Memos Nos. number series that is defined on the Sales & Receivables Setup page.';
                }
                field(UseSamePostingDate; UseSamePostingDate)
                {
                    ApplicationArea = Suite;
                    Caption = 'Use Same Posting Date';
                    ToolTip = 'Specifies if you want to use same posting date for corrective ledger entries.';

                    trigger OnValidate()
                    begin
                        if UseSamePostingDate then
                            NewPostingDate := 0D;
                        SetEnabled;
                    end;
                }
                field(NewPostingDate; NewPostingDate)
                {
                    ApplicationArea = Suite;
                    Caption = 'New Posting Date';
                    Enabled = NewPostingDateEnabled;
                    ToolTip = 'Specifies the new posting date for corrective ledger entries.';
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            UseSameDocumentNo := true;
            UseSamePostingDate := true;
            SetEnabled;
        end;
    }

    labels
    {
    }

    var
        TempIssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header" temporary;
        NoOfRecords: Integer;
        NothingToCancelErr: Label 'There is nothing to cancel.';
        UseSameDocumentNo: Boolean;
        UseSamePostingDate: Boolean;
        NewPostingDate: Date;
        [InDataSet]
        NewPostingDateEnabled: Boolean;
        SpecifyPostingDateErr: Label 'You must specify a posting date.';
        ShowNotCancelledFinChargeMemosQst: Label 'One or more of the selected issued finance charge memos could not be canceled.\\Do you want to see a list of the issued finance charge memos that were not canceled?';

    local procedure SetEnabled()
    begin
        NewPostingDateEnabled := not UseSamePostingDate;
    end;

    local procedure AskShowNotCancelledIssuedFinChargeMemos()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if ConfirmManagement.GetResponseOrDefault(ShowNotCancelledFinChargeMemosQst, true) then
            PAGE.RunModal(PAGE::"Issued Fin. Charge Memo List", TempIssuedFinChargeMemoHeader);
    end;

    local procedure AddIssuedFinChargeMemoHeaderToErrorBuffer()
    begin
        TempIssuedFinChargeMemoHeader := "Issued Fin. Charge Memo Header";
        TempIssuedFinChargeMemoHeader.Insert();
    end;
}

