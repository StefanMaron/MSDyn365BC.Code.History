page 18746 "Pay TDS"
{
    Caption = 'Pay TDS';
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
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that TDS entry is linked to.';
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

                field("TDS Base Amount"; "TDS Base Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'TDS Base Amount';
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
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
                field("Challan Date"; "Challan Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the challan date for the TDS entry once TDS amount is paid to government.';
                }
                field("Challan No."; "Challan No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the challan number for the TDS entry once TDS amount is paid to government.';
                }
                field("Bank Name"; "Bank Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account of the applied entry.';
                }
                field("TDS %"; "TDS %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies TDS % on the TDS entry.';
                }
                field(Adjusted; Adjusted)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the TDS entry is adjusted.';
                }
                field("Adjusted TDS %"; "Adjusted TDS %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies adjusted TDS % for the TDS Entry.';
                }
                field("Pay TDS Document No."; "Pay TDS Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number of the TDS entry to be paid to government.';
                }
                field("Applies To"; "Applies To")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the entry is applied to any entry.';
                }
                field("Surcharge %"; "Surcharge %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the surcharge % on the TDS entry.';
                }
                field("Surcharge Amount"; "Surcharge Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the surcharge amount that the TDS entry is linked to.';
                }
                field("Concessional Code"; "Concessional Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the applied concessional code that the TDS entry is linked to.';
                }
                field("Concessional Form No."; "Concessional Form No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the applied concessional form on TDS entry.';
                }
                field("Invoice Amount"; "Invoice Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the invoice amount that the TDS entry is linked to.';
                }

                field(Applied; Applied)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the TDS entry is applied.';
                }
                field("TDS Amount"; "TDS Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the TDS Amount that the TDS entry is linked to.';
                }
                field("eCESS %"; "eCESS %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the eCess % on TDS entry.';
                }
                field("eCESS Amount"; "eCESS Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the eCess amount on TDS entry.';
                }
                field("SHE Cess %"; "SHE Cess %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SHE Cess % on TDS entry.';
                }
                field("SHE Cess Amount"; "SHE Cess Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SHE Cess amount on TDS entry.';
                }
                field("T.A.N. No."; "T.A.N. No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'T.A.N. No.';
                    ToolTip = 'Specifies the T.A.N. number that the TDS entry is linked to.';
                }
                field(Reversed; Reversed)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the TDS entry has been reversed.';
                }
                field("Reversed by Entry No."; "Reversed by Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry number by which the TDS entry has been reversed.';
                }
                field("Reversed Entry No."; "Reversed Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry number for which the TDS entry has been reversed.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user who posted the TDS entry.';
                }
                field("Source Code"; "Source Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source code. Source code can be PURCHASES, SALES, GENJNL, BANKPYMT etc.';
                }
                field("Transaction No."; "Transaction No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction number of the posted entry.';
                }
                field("Party P.A.N. No."; "Party P.A.N. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the P.A.N. number of the deductee.';
                }
                field("TDS Payment Date"; "TDS Payment Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the P.A.N. number of the deductee.';
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
                ToolTip = 'Click Pay to transfer the total of the selected entries to the amount field of payment journal.';
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ApplicationArea = Basic, Suite;
                Image = Payment;
                trigger OnAction()
                var
                    TDSEntry: Record "TDS Entry";
                    DocNo: Code[20];
                    TotalTDSAmount: Decimal;
                    TotalInvAmount: Decimal;
                    TotalCreditAmount: Decimal;
                begin
                    TotalTDSAmount := 0;
                    DocNo := GetGenJnlLineDocNo();

                    TDSEntry.SETRANGE("Pay TDS Document No.", DocNo);
                    TDSEntry.SETRANGE("TDS Paid", FALSE);
                    if TDSEntry.FindSet() then
                        repeat
                            TDSEntry."Pay TDS Document No." := ' ';
                            TDSEntry.MODIFY();
                        until TDSEntry.NEXT() = 0;

                    TDSEntry.COPY(Rec);
                    if TDSEntry.FindSet() then
                        repeat
                            if NOT (TDSEntry."Document Type" = TDSEntry."Document Type"::"Credit Memo") then
                                TotalInvAmount := TotalInvAmount + TDSEntry."Bal. TDS Including SHE CESS"
                            else
                                TotalCreditAmount := TotalCreditAmount + TDSEntry."Bal. TDS Including SHE CESS";
                            TDSEntry."Pay TDS Document No." := DocNo;
                            TDSEntry.MODIFY();
                        until TDSEntry.NEXT() = 0;
                    TotalTDSAmount := TotalInvAmount - TotalCreditAmount;

                    UpdateGenJnlLineAmount(TotalTDSAmount);

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