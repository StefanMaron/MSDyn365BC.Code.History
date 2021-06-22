page 573 "Detailed Cust. Ledg. Entries"
{
    AdditionalSearchTerms = 'sales transaction,payment receipt';
    ApplicationArea = Basic, Suite;
    Caption = 'Detailed Customer Ledger Entries';
    DataCaptionFields = "Cust. Ledger Entry No.", "Customer No.";
    Editable = false;
    InsertAllowed = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Entry';
    SourceTable = "Detailed Cust. Ledg. Entry";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date of the detailed customer ledger entry.';
                }
                field("Entry Type"; "Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry type of the detailed customer ledger entry.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type of the detailed customer ledger entry.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number of the transaction that created the entry.';
                }
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer account number to which the entry is posted.';
                }
                field("Initial Entry Global Dim. 1"; "Initial Entry Global Dim. 1")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the Global Dimension 1 code of the initial customer ledger entry.';
                    Visible = false;
                }
                field("Initial Entry Global Dim. 2"; "Initial Entry Global Dim. 2")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the Global Dimension 2 code of the initial customer ledger entry.';
                    Visible = false;
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the currency if the amount is in a foreign currency.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the detailed customer ledger entry.';
                    Visible = AmountVisible;
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the entry in LCY.';
                    Visible = AmountVisible;
                }
                field("Debit Amount"; "Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits.';
                    Visible = DebitCreditVisible;
                }
                field("Debit Amount (LCY)"; "Debit Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits, expressed in LCY.';
                    Visible = DebitCreditVisible;
                }
                field("Credit Amount"; "Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits.';
                    Visible = DebitCreditVisible;
                }
                field("Credit Amount (LCY)"; "Credit Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits, expressed in LCY.';
                    Visible = DebitCreditVisible;
                }
                field("Initial Entry Due Date"; "Initial Entry Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which the initial entry is due for payment.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("User ID");
                    end;
                }
                field("Source Code"; "Source Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                    Visible = false;
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                    Visible = false;
                }
                field(Unapplied; Unapplied)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the entry has been unapplied (undone) from the Unapply Customer Entries window by the entry no. shown in the Unapplied by Entry No. field.';
                    Visible = false;
                }
                field("Unapplied by Entry No."; "Unapplied by Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the correcting entry, if the original entry has been unapplied (undone) from the Unapply Customer Entries window.';
                    Visible = false;
                }
                field("Cust. Ledger Entry No."; "Cust. Ledger Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry number of the customer ledger entry that the detailed customer ledger entry line was created for.';
                    Visible = false;
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Unapply Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unapply Entries';
                    Ellipsis = true;
                    Image = UnApply;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Unselect one or more ledger entries that you want to unapply this record.';

                    trigger OnAction()
                    var
                        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
                    begin
                        CustEntryApplyPostedEntries.UnApplyDtldCustLedgEntry(Rec);
                    end;
                }
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Navigate';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Category4;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate.SetDoc("Posting Date", "Document No.");
                    Navigate.Run;
                end;
            }
        }
    }

    trigger OnInit()
    begin
        AmountVisible := true;
    end;

    trigger OnOpenPage()
    begin
        SetControlVisibility;
    end;

    var
        Navigate: Page Navigate;
        AmountVisible: Boolean;
        DebitCreditVisible: Boolean;

    local procedure SetControlVisibility()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        AmountVisible := not (GLSetup."Show Amounts" = GLSetup."Show Amounts"::"Debit/Credit Only");
        DebitCreditVisible := not (GLSetup."Show Amounts" = GLSetup."Show Amounts"::"Amount Only");
    end;
}

