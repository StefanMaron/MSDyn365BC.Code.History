page 15000001 "Payment Info"
{
    Caption = 'Payment Info';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Gen. Journal Line";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Remittance Account Code"; "Remittance Account Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the remittance account code associated with the general journal line.';
                }
                field("Remittance Agreement Code"; "Remittance Agreement Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the code of the agreement to which the account is linked.';
                }
                field("Remittance Type"; "Remittance Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the remittance type that is assigned to the account code.';
                }
            }
            group(Domestic)
            {
                Caption = 'Domestic';
                field("Recipient Ref. 1"; "Recipient Ref. 1")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the text that will print on the journal line.';
                }
                field("Recipient Ref. 2"; "Recipient Ref. 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the text that will print on the journal line.';
                }
                field("Recipient Ref. 3"; "Recipient Ref. 3")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the text that will print on the journal line.';
                }
                field(KID; KID)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'KID (Cust. id number)';
                    ToolTip = 'Specifies the Kunde ID (KID) associated with the general journal line.';
                }
                field("Our Account No."; "Our Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Shows the number the vendor has assigned to us in his system. In other words, this is our customer number in the vendor''s system.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the external document number for this entry.';
                }
                field("Payment Type Code Domestic"; "Payment Type Code Domestic")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a two-digit code for the payment type.';
                }
            }
            group(Foreign)
            {
                Caption = 'Foreign';
                field("Recipient Ref. Abroad"; "Recipient Ref. Abroad")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the text that will print on the invoice.';
                }
                field("Payment Type Code Abroad"; "Payment Type Code Abroad")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a two-digit code for the payment type.';
                }
                field(Check; Check)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if a check must be issued, and to whom.';
                }
                field(Urgent; Urgent)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the payment is urgent and should be treated as an urgent transfer.';
                }
                field("Agreed Exch. Rate"; "Agreed Exch. Rate")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the exchange rate that is agreed upon with the bank.';
                }
                field("Agreed With"; "Agreed With")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first six letters of the surname with whom the exchange rate is agreed upon.';
                }
                field("Futures Contract No."; "Futures Contract No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the futures contract, if this transaction is linked to a futures contract.';
                }
                field("Futures Contract Exch. Rate"; "Futures Contract Exch. Rate")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the futures contract exchange rate that is used for the payment.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Functions)
            {
                Caption = 'Functions';
                action("Initialize payment info")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Initialize payment info';
                    Image = ViewCheck;
                    ToolTip = 'Create a manual remittance payment. If the payment is linked to an existing vendor ledger entry, information will be transferred from the entry. If the payment is not linked to a vendor ledger entry, only partial information will be created.';

                    trigger OnAction()
                    begin
                        InitVendEntry;
                        RemTools.CreateJournalData(Rec, VendEntry);
                        CurrPage.Update;
                    end;
                }
                separator(Action39)
                {
                }
                action("Insert &recipient ref.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Insert &recipient ref.';
                    Image = SuggestLines;
                    ToolTip = 'Insert the reference text that is set up for the receiving vendor.';

                    trigger OnAction()
                    begin
                        if KID <> '' then
                            if not Confirm(Text000, false) then
                                Error('');
                        InitVendEntry;
                        // Delete KID in the copy of the vendor entry used for initializing
                        VendEntry.KID := '';
                        RemTools.CreateJournalData(Rec, VendEntry);
                        CurrPage.Update;
                    end;
                }
                action("Insert &KID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Insert &KID';
                    Image = NumberSetup;
                    ToolTip = 'Insert the customer identification number that provides a payment reference to the vendor and ensures that the vendor is posting the payment correctly.';

                    trigger OnAction()
                    begin
                        InitVendEntry;
                        VendEntry.TestField(KID);
                        RemTools.CreateJournalData(Rec, VendEntry);
                        CurrPage.Update;
                    end;
                }
            }
        }
    }

    var
        Text000: Label 'KID is specified in payments info.\Delete KID and insert recipient ref.?';
        Text001: Label 'Transaction does not apply to a vendor entry.\KID/Recipient ref. can not be formatted.';
        VendEntry: Record "Vendor Ledger Entry";
        RemTools: Codeunit "Remittance Tools";

    local procedure InitVendEntry()
    begin
        if "Applies-to Doc. No." = '' then begin
            VendEntry.Init;
            Message(Text001);
        end else
            RemTools.SearchEntry(Rec, VendEntry);
    end;
}

