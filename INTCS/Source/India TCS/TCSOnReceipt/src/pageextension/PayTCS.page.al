page 18906 "Pay TCS"
{
    Caption = 'Pay TCS';
    Editable = false;
    PageType = List;
    SourceTable = "TCS Entry";
    UsageCategory = Lists;
    ApplicationArea = Basic, Suite;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that TCS entry is linked to.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the customer account that TCS entry is linked to.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date of the TCS entry.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type that the TCS entry belongs to.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies document number of the TCS entry.';
                }
                field("TCS Base Amount"; "TCS Base Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the base amount on which TCS is being calculated.';
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("TCS Nature of Collection"; "TCS Nature of Collection")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Nature of Collection on which TCS is applied.';
                }
                field("Assessee Code"; "Assessee Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the assessee code of the customer account that the TCS entry is linked to.';
                }
                field("TCS Paid"; "TCS Paid")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the amount on the TCS entry is fully paid.';
                }
                field("Challan Date"; "Challan Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the challan date for the TCS entry once TCS amount is paid to government.';
                }
                field("Challan No."; "Challan No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the challan number for the TCS entry once TCS amount is paid to government.';
                }
                field("Bank Name"; "Bank Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account of the applied entry.';
                }
                field("TCS %"; "TCS %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies TCS % on the TCS entry.';
                }
                field("Pay TCS Document No."; "Pay TCS Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number of the TCS entry to be paid to government.';
                }
                field("Surcharge %"; "Surcharge %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the surcharge % on the TCS entry.';
                }
                field("Surcharge Amount"; "Surcharge Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the surcharge amount that the TCS entry is linked to.';
                }
                field("Concessional Code"; "Concessional Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the applied concessional code that the TCS entry is linked to.';
                }
                field("Invoice Amount"; "Invoice Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the invoice amount that the TCS entry is linked to.';
                }
                field("TCS Amount"; "TCS Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the TCS Amount that the TCS entry is linked to.';
                }
                field("eCESS %"; "eCESS %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the eCess % on TCS entry.';
                }
                field("eCESS Amount"; "eCESS Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the eCess amount on TCS entry.';
                }
                field("SHE Cess %"; "SHE Cess %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SHE Cess % on TCS entry.';
                }
                field("SHE Cess Amount"; "SHE Cess Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SHE Cess amount on TCS entry.';
                }
                field("T.C.A.N. No."; "T.C.A.N. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the T.C.A.N. number that the TCS entry is linked to.';
                }
                field("Customer P.A.N. No."; "Customer P.A.N. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the PAN number of the Customer that the TCS entry is linked to.';
                }
                field("TCS Payment Date"; "TCS Payment Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which TCS is paid to the government.';
                }
            }
        }
    }
    actions
    {
        area(processing)
        {
            action("&Pay")
            {
                Caption = '&Pay';
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ApplicationArea = Basic, Suite;
                Image = Payment;
                ToolTip = 'Click Pay to transfer the total of the selected entries to the amount field of payment journal.';
                trigger OnAction()
                var
                    TCSEntry: Record "TCS Entry";
                begin
                    ClearTCSAmount();
                    TCSEntry.SetRange("Pay TCS Document No.", GetGenJnlDocNo());
                    TCSEntry.SetRange("TCS Paid", False);
                    If TCSEntry.FindSet() Then
                        TCSEntry.ModifyAll("Pay TCS Document No.", '');

                    TCSEntry.COPY(Rec);
                    If TCSEntry.FindSet() Then
                        REPEAT
                            If Not (TCSEntry."Document Type" = TCSEntry."Document Type"::"Credit Memo") Then
                                TotalInvAmount := TotalInvAmount + TCSEntry."Bal. TCS Including SHE CESS"
                            Else
                                TotalCreditAmount := TotalCreditAmount + TCSEntry."Bal. TCS Including SHE CESS";
                            TCSEntry."Pay TCS Document No." := GetGenJnlDocNo();
                            TCSEntry.Modify();
                        UNTIL TCSEntry.Next() = 0;
                    TotalTCSAmount := TotalInvAmount - TotalCreditAmount;
                    UpdateGenJnlAmounts();
                    CurrPage.Close();
                end;
            }
        }
    }

    var

        Batch: Code[10];
        Template: Code[10];
        LineNo: Integer;
        TotalTCSAmount: Decimal;
        TotalInvAmount: Decimal;
        TotalCreditAmount: Decimal;

    procedure SetProperties(BatchName: Code[10]; TemplateName: Code[10]; "No.": Integer)
    begin
        Batch := BatchName;
        Template := TemplateName;
        LineNo := "No.";
    end;

    local procedure GetGenJnlDocNo(): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        SetFiltersOnGenJnlLine(GenJnlLine);
        If GenJnlLine.FindLast() Then
            Exit(GenJnlLine."Document No.");
    end;

    local procedure UpdateGenJnlAmounts()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        SetFiltersOnGenJnlLine(GenJnlLine);
        If GenJnlLine.FindLast() Then Begin
            GenJnlLine.Amount := TotalTCSAmount;
            GenJnlLine.VALIDATE("Debit Amount", TotalTCSAmount);
            GenJnlLine.Modify();
        end;
    end;

    local procedure SetFiltersOnGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine.SetRange("Journal Template Name", Template);
        GenJnlLine.SetRange("Journal Batch Name", Batch);
        GenJnlLine.SetRange("Line No.", LineNo);
    end;

    local procedure ClearTCSAmount()
    begin
        TotalTCSAmount := 0;
    end;
}