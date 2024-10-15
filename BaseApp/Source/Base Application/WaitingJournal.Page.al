page 15000005 "Waiting Journal"
{
    Caption = 'Waiting Journal';
    DataCaptionFields = "Payment Order ID - Sent", "Payment Order ID - Approved", "Payment Order ID - Settled";
    Editable = false;
    PageType = List;
    SourceTable = "Waiting Journal";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Reference; Reference)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reference associated with the waiting journal.';
                }
                field("BBS Referance"; "BBS Referance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reference number when remitting to Bankenes BetalingsSentral (BBS).';
                    Visible = false;
                }
                field("Remittance Status"; "Remittance Status")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the remittance associated with the waiting journal.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date of the waiting journal.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type to which the waiting journal belongs.';
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account type associated with the waiting journal.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number associated with the waiting journal.';

                    trigger OnValidate()
                    begin
                        ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the waiting journal.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the currency associated with the waiting journal.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the waiting journal.';
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the waiting journal entry in LCY.';
                    Visible = false;
                }
                field("Applies-to Doc. Type"; "Applies-to Doc. Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of document to which the journal line will be applied.';
                }
                field("Applies-to Doc. No."; "Applies-to Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the document to which the journal line will be applied.';
                }
                field("Return Code"; "Return Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the return code associated with the waiting journal.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a reference to a combination of dimension values.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a reference to a combination of dimension values.';
                    Visible = false;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(3),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(3, ShortcutDimCode[3]);
                    end;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(4),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(4, ShortcutDimCode[4]);
                    end;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(5),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(5, ShortcutDimCode[5]);
                    end;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(6),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(6, ShortcutDimCode[6]);
                    end;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(7),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(7, ShortcutDimCode[7]);
                    end;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(8),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
                }
                field("Handling Ref."; "Handling Ref.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the handling reference associated with the waiting journal.';
                }
                field("BBS Shipment No."; "BBS Shipment No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the shipment order when remitting to Bankenes BetalingsSentral (BBS).';
                    Visible = false;
                }
                field("BBS Payment Order No."; "BBS Payment Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment order number when remitting to Bankenes BetalingsSentral (BBS).';
                    Visible = false;
                }
                field("BBS Transaction No."; "BBS Transaction No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction number when remitting to Bankenes BetalingsSentral (BBS).';
                    Visible = false;
                }
                field("Payment Order ID - Sent"; "Payment Order ID - Sent")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sent remittance payment order ID associated with the waiting journal.';
                }
                field("Payment Order ID - Approved"; "Payment Order ID - Approved")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the approved remittance payment order ID associated with the waiting journal.';
                }
                field("Payment Order ID - Settled"; "Payment Order ID - Settled")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the settled remittance payment order ID associated with the waiting journal.';
                }
                field("Journal, Settlement Template"; "Journal, Settlement Template")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the settlement template associated with the waiting journal.';
                    Visible = false;
                }
                field("Journal - Settlement"; "Journal - Settlement")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the settlement journal associated with the waiting journal.';
                    Visible = false;
                }
                field(KID; KID)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the electronic Kunde ID (KID).';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                action("&Dimensions")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                        CurrPage.SaveRecord;
                    end;
                }
            }
            group("Waiting Journal")
            {
                Caption = 'Waiting Journal';
                action("Payment Overview")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Overview';
                    Image = Payment;
                    RunObject = Report "Waiting Jnl - paym. overview";
                    ToolTip = 'Get an overview of payments that are not settled.';
                }
                action("Return Error")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Return Error';
                    Image = ErrorLog;
                    RunObject = Page "Return Error";
                    RunPageLink = "Waiting Journal Reference" = FIELD(Reference);
                    ToolTip = 'View the electronic payment orders that have been returned with an error. For a remittance error, the error code from the bank and an explanation of the error will be shown for the payment in the Waiting Journal window.';
                }
                separator(Action37)
                {
                }
                action("Cancel Payment")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cancel Payment';
                    Image = VoidExpiredCheck;
                    ToolTip = 'Cancel the payment. An individual payment can be canceled if the payment cannot be processed by the bank and a new remittance has to be made. You can also cancel a payment if you do not want to process the payment. Settled payments cannot be canceled.';

                    trigger OnAction()
                    var
                        ResetJournal: Codeunit "Reset Remittance Payment Order";
                    begin
                        // Reset waiting journal (and related posts):
                        ResetJournal.ResetWaitingJournalJN(Rec);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(ShortcutDimCode);
    end;

    var
        ShortcutDimCode: array[8] of Code[20];
}

