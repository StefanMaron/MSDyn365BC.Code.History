page 31017 "Linked Prepayments"
{
    Caption = 'Linked Prepayments';
    Editable = false;
    PageType = List;
    SourceTable = "CV Ledger Entry Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1220009)
            {
                ShowCaption = false;
                field("CV No."; "CV No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of customer''s or vendor''s advance payment.';
                    Visible = false;
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date for the entry.';
                }
                field(Prepayment; Prepayment)
                {
                    ApplicationArea = Basic, Suite, Prepayments;
                    ToolTip = 'Specifies if line of purchase journal is prepayment';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite, Prepayments;
                    ToolTip = 'Specifies the document type of the customer or vendor ledger entry.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite, Prepayments;
                    ToolTip = 'Specifies linked prepayments to be viewed by using this window to. You can use this window to view document types, posting dates, descriptions, and amounts to apply for prepayments.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite, Prepayments;
                    ToolTip = 'Specifies description for sales advance.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency of amounts on the document.';
                }
                field("Amount to Apply"; "Amount to Apply")
                {
                    ApplicationArea = Basic, Suite, Prepayments;
                    ToolTip = 'Specifies the amount to apply.';

                    trigger OnDrillDown()
                    begin
                        DrillDownLinks;
                    end;
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite, Prepayments;
                    ToolTip = 'Specifies the entry number that is assigned to the entry.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                action("Applied E&ntries")
                {
                    ApplicationArea = Basic, Suite, Prepayments;
                    Caption = 'Applied E&ntries';
                    Image = Approve;
                    RunPageOnRec = true;
                    ToolTip = 'Open the page with applied customer or vendor entries.';

                    trigger OnAction()
                    var
                        VendLedgEntry: Record "Vendor Ledger Entry";
                        CustLedgEntry: Record "Cust. Ledger Entry";
                    begin
                        if VendLedgEntry.Get("Entry No.") then
                            PAGE.RunModal(PAGE::"Applied Vendor Entries", VendLedgEntry);
                        if CustLedgEntry.Get("Entry No.") then
                            PAGE.RunModal(PAGE::"Applied Customer Entries", CustLedgEntry);
                    end;
                }
            }
        }
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite, Prepayments;
                Caption = 'Find entries...';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate;
                end;
            }
        }
    }

    [Scope('OnPrem')]
    procedure InsertCustEntries(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        if CustLedgEntry.FindSet then
            repeat
                "Entry No." := CustLedgEntry."Entry No.";
                "CV No." := CustLedgEntry."Customer No.";
                Prepayment := CustLedgEntry.Prepayment;
                "Posting Date" := CustLedgEntry."Posting Date";
                "Document Type" := CustLedgEntry."Document Type";
                "Document No." := CustLedgEntry."Document No.";
                Description := CustLedgEntry.Description;
                "Currency Code" := CustLedgEntry."Currency Code";
                "Amount to Apply" := CustLedgEntry."Amount to Apply";
                Positive := false;
                Insert;
            until CustLedgEntry.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure InsertVendEntries(var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        if VendLedgEntry.FindSet then
            repeat
                "Entry No." := VendLedgEntry."Entry No.";
                "CV No." := VendLedgEntry."Vendor No.";
                Prepayment := VendLedgEntry.Prepayment;
                "Posting Date" := VendLedgEntry."Posting Date";
                "Document Type" := VendLedgEntry."Document Type";
                "Document No." := VendLedgEntry."Document No.";
                Description := VendLedgEntry.Description;
                "Currency Code" := VendLedgEntry."Currency Code";
                "Amount to Apply" := VendLedgEntry."Amount to Apply";
                Positive := true;
                Insert;
            until VendLedgEntry.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure DrillDownLinks()
    var
        AdvanceLink: Record "Advance Link";
        LinksToAdvanceLetter: Page "Links to Advance Letter";
    begin
        AdvanceLink.SetRange("CV Ledger Entry No.", "Entry No.");
        AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
        LinksToAdvanceLetter.SetTableView(AdvanceLink);
        LinksToAdvanceLetter.RunModal;
    end;

    [Scope('OnPrem')]
    procedure Navigate()
    var
        NavigatePage: Page Navigate;
    begin
        NavigatePage.SetDoc("Posting Date", "Document No.");
        NavigatePage.Run;
    end;
}

