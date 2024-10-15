page 18751 "Pay WorkTax"
{
    Caption = 'Pay WorkTax';
    Editable = false;
    PageType = List;
    SourceTable = "TDS Entry";
    UsageCategory = Lists;
    ApplicationArea = Basic, Suite;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';

                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that TDS entry is linked to.';
                }
                field("Work Tax Account"; "Work Tax Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger account that the Work Tax entry is linked to.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the vendor account that TDS entry is linked to.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date of the TDS entry.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type that the TDS entry belongs to.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies document number of the TDS entry.';
                }
                field("Work Tax Base Amount"; "Work Tax Base Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the base amount on which Work Tax is calculated.';
                }
                field("Work Tax %"; "Work Tax %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Work Tax % on the TDS entry.';
                }
                field("Work Tax Amount"; "Work Tax Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Work Tax Amount on the TDS entry.';
                }
                field("Pay Work Tax Document No."; "Pay Work Tax Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number of the TDS entry to be paid to government.';
                }
                field("Work Tax Paid"; "Work Tax Paid")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the amount on the Work Tax entry is fully paid.';
                }
                field("Assessee Code"; "Assessee Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the assessee code of the customer account that the TDS entry is linked to.';
                }
                field("TDS Paid"; "TDS Paid")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the amount on the TDS entry is fully paid.';
                }
                field("Applied To"; "Applied To")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number of the applied TDS entry';
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
                ToolTip = 'Click Pay to transfer the total of the selected entries to the amount field of  payment journal.';
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                ApplicationArea = Basic, Suite;
                Image = Payment;
                trigger OnAction()
                var
                    TDSEntry: Record "TDS Entry";
                    DocNo: Code[20];
                    TotalWorkTaxAmount: Decimal;
                    TotalTDSAmount: Decimal;
                    TotalInvAmount: Decimal;
                    TotalCreditAmount: Decimal;
                begin
                    TotalWorkTaxAmount := 0;

                    DocNo := GetGenJnlLineDocNo();

                    TDSEntry.SETRANGE("Pay Work Tax Document No.", DocNo);
                    TDSEntry.SETRANGE("Work Tax Paid", FALSE);
                    if TDSEntry.FindSet() then
                        repeat
                            TDSEntry."Pay Work Tax Document No." := ' ';
                            TDSEntry.MODIFY();
                        until TDSEntry.NEXT() = 0;

                    TDSEntry.COPY(Rec);
                    if TDSEntry.FindSet() then
                        repeat
                            if NOT (TDSEntry."Document Type" = TDSEntry."Document Type"::"Credit Memo") then
                                TotalInvAmount := TotalInvAmount + TDSEntry."Balance Work Tax Amount"
                            else
                                TotalCreditAmount := TotalCreditAmount + TDSEntry."Balance Work Tax Amount";
                            TDSEntry."Pay Work Tax Document No." := DocNo;
                            TDSEntry.MODIFY();
                        until TDSEntry.NEXT() = 0;
                    TotalWorkTaxAmount := TotalInvAmount - TotalCreditAmount;

                    UpdateGenJnlLineAmount(TotalWorkTaxAmount);

                    CurrPage.CLOSE();
                end;
            }
        }
    }

    procedure SetProperties(BatchName: Code[10]; TemplateName: Code[10]; "No.": Integer)
    begin
        Batch := BatchName;
        Template := TemplateName;
        LineNo := "No.";
    end;

    local procedure GetGenJnlLineDocNo(): Code[20]
    begin
        GenJnlLine.RESET();
        GenJnlLine.SETRANGE("Journal Template Name", Template);
        GenJnlLine.SETRANGE("Journal Batch Name", Batch);
        GenJnlLine.SETRANGE("Line No.", LineNo);
        if GenJnlLine.FINDLAST() then
            exit(GenJnlLine."Document No.");
    end;

    local procedure UpdateGenJnlLineAmount(Amount: Decimal)
    begin
        GenJnlLine.RESET();
        GenJnlLine.SETRANGE("Journal Template Name", Template);
        GenJnlLine.SETRANGE("Journal Batch Name", Batch);
        GenJnlLine.SETRANGE("Line No.", LineNo);
        if GenJnlLine.FINDLAST() then begin
            GenJnlLine.Amount := Amount;
            GenJnlLine.VALIDATE("Debit Amount", Amount);
            GenJnlLine.MODIFY();
        end;
    end;

    var
        GenJnlLine: Record "Gen. Journal Line";
        Batch: Code[10];
        Template: Code[10];
        LineNo: Integer;
}