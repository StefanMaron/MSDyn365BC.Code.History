page 61 "Applied Customer Entries"
{
    Caption = 'Applied Customer Entries';
    DataCaptionExpression = Heading;
    Editable = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Line,Entry';
    SourceTable = "Cust. Ledger Entry";

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
                    ToolTip = 'Specifies the customer entry''s posting date.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type that the customer entry belongs to.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s document number.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the customer entry.';
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = DimVisible1;
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = DimVisible2;
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the salesperson whom the entry is linked to.';
                    Visible = false;
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency code for the amount on the line.';
                }
                field("Original Amount"; "Original Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original entry.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the entry.';
                    Visible = AmountVisible;
                }
                field("Debit Amount"; "Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits.';
                    Visible = DebitCreditVisible;
                }
                field("Credit Amount"; "Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits.';
                    Visible = DebitCreditVisible;
                }
                field("Closed by Amount"; "Closed by Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that the entry was finally applied to (closed) with.';
                }
                field("Closed by Currency Code"; "Closed by Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code of the currency of the entry that was applied to (and closed) this customer ledger entry.';
                    Visible = false;
                }
                field("Closed by Currency Amount"; "Closed by Currency Amount")
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = "Closed by Currency Code";
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the amount that was finally applied to (and closed) this customer ledger entry.';
                    Visible = false;
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
        area(navigation)
        {
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
                action("Reminder/Fin. Charge Entries")
                {
                    ApplicationArea = Suite;
                    Caption = 'Reminder/Fin. Charge Entries';
                    Image = Reminder;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Reminder/Fin. Charge Entries";
                    RunPageLink = "Customer Entry No." = FIELD("Entry No.");
                    RunPageView = SORTING("Customer Entry No.");
                    ToolTip = 'View entries that were created when reminders and finance charge memos were issued.';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category5;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                    end;
                }
                action("Detailed &Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Detailed &Ledger Entries';
                    Image = View;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Detailed Cust. Ledg. Entries";
                    RunPageLink = "Cust. Ledger Entry No." = FIELD("Entry No."),
                                  "Customer No." = FIELD("Customer No.");
                    RunPageView = SORTING("Cust. Ledger Entry No.", "Posting Date");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View a summary of the all posted entries and adjustments related to a specific customer ledger entry.';
                }
            }
        }
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Navigate';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Category5;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate.SetDoc("Posting Date", "Document No.");
                    Navigate.Run;
                end;
            }
            action("Show Posted Document")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Posted Document';
                Image = Document;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                ToolTip = 'Show details for the posted payment, invoice, or credit memo.';

                trigger OnAction()
                begin
                    ShowDoc
                end;
            }
            action(ShowDocumentAttachment)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Document Attachment';
                Enabled = HasDocumentAttachment;
                Image = Attach;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                ToolTip = 'View documents or images that are attached to the posted invoice or credit memo.';

                trigger OnAction()
                begin
                    ShowPostedDocAttachment;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        HasDocumentAttachment := HasPostedDocAttachment;
    end;

    trigger OnInit()
    begin
        AmountVisible := true;
    end;

    trigger OnOpenPage()
    begin
        Reset;
        SetControlVisibility;

        if "Entry No." <> 0 then begin
            CreateCustLedgEntry := Rec;
            if CreateCustLedgEntry."Document Type" = 0 then
                Heading := Text000
            else
                Heading := Format(CreateCustLedgEntry."Document Type");
            Heading := Heading + ' ' + CreateCustLedgEntry."Document No.";

            FindApplnEntriesDtldtLedgEntry;
            SetCurrentKey("Entry No.");
            SetRange("Entry No.");

            if CreateCustLedgEntry."Closed by Entry No." <> 0 then begin
                "Entry No." := CreateCustLedgEntry."Closed by Entry No.";
                Mark(true);
            end;

            SetCurrentKey("Closed by Entry No.");
            SetRange("Closed by Entry No.", CreateCustLedgEntry."Entry No.");
            if Find('-') then
                repeat
                    Mark(true);
                until Next = 0;

            SetCurrentKey("Entry No.");
            SetRange("Closed by Entry No.");
        end;

        MarkedOnly(true);
    end;

    var
        Text000: Label 'Document';
        CreateCustLedgEntry: Record "Cust. Ledger Entry";
        Navigate: Page Navigate;
        Heading: Text[50];
        AmountVisible: Boolean;
        DebitCreditVisible: Boolean;
        DimVisible1: Boolean;
        DimVisible2: Boolean;
        HasDocumentAttachment: Boolean;

    local procedure FindApplnEntriesDtldtLedgEntry()
    var
        DtldCustLedgEntry1: Record "Detailed Cust. Ledg. Entry";
        DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustLedgEntry1.SetCurrentKey("Cust. Ledger Entry No.");
        DtldCustLedgEntry1.SetRange("Cust. Ledger Entry No.", CreateCustLedgEntry."Entry No.");
        DtldCustLedgEntry1.SetRange(Unapplied, false);
        if DtldCustLedgEntry1.Find('-') then
            repeat
                if DtldCustLedgEntry1."Cust. Ledger Entry No." =
                   DtldCustLedgEntry1."Applied Cust. Ledger Entry No."
                then begin
                    DtldCustLedgEntry2.Init();
                    DtldCustLedgEntry2.SetCurrentKey("Applied Cust. Ledger Entry No.", "Entry Type");
                    DtldCustLedgEntry2.SetRange(
                      "Applied Cust. Ledger Entry No.", DtldCustLedgEntry1."Applied Cust. Ledger Entry No.");
                    DtldCustLedgEntry2.SetRange("Entry Type", DtldCustLedgEntry2."Entry Type"::Application);
                    DtldCustLedgEntry2.SetRange(Unapplied, false);
                    if DtldCustLedgEntry2.Find('-') then
                        repeat
                            if DtldCustLedgEntry2."Cust. Ledger Entry No." <>
                               DtldCustLedgEntry2."Applied Cust. Ledger Entry No."
                            then begin
                                SetCurrentKey("Entry No.");
                                SetRange("Entry No.", DtldCustLedgEntry2."Cust. Ledger Entry No.");
                                if Find('-') then
                                    Mark(true);
                            end;
                        until DtldCustLedgEntry2.Next = 0;
                end else begin
                    SetCurrentKey("Entry No.");
                    SetRange("Entry No.", DtldCustLedgEntry1."Applied Cust. Ledger Entry No.");
                    if Find('-') then
                        Mark(true);
                end;
            until DtldCustLedgEntry1.Next = 0;
    end;

    procedure SetTempCustLedgEntry(NewTempCustLedgEntryNo: Integer)
    begin
        if NewTempCustLedgEntryNo <> 0 then begin
            SetRange("Entry No.", NewTempCustLedgEntryNo);
            Find('-');
        end;
    end;

    local procedure SetControlVisibility()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        AmountVisible := not (GLSetup."Show Amounts" = GLSetup."Show Amounts"::"Debit/Credit Only");
        DebitCreditVisible := not (GLSetup."Show Amounts" = GLSetup."Show Amounts"::"Amount Only");
        DimVisible1 := GLSetup."Global Dimension 1 Code" <> '';
        DimVisible2 := GLSetup."Global Dimension 2 Code" <> '';
    end;
}

