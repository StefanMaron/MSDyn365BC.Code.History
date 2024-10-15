page 31008 "Set Advance Link"
{
    Caption = 'Set Advance Link';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SourceTable = "Advance Link Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("TempAdvanceLinkBuf.""Posting Date"""; TempAdvanceLinkBuf."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posting Date';
                    Editable = false;
                    ToolTip = 'Specifies the advance due date.';
                }
                field("TempAdvanceLinkBuf.""Entry Type"""; TempAdvanceLinkBuf."Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Entry Type';
                    Editable = false;
                    OptionCaption = ' ,Advance Payment,Adv. Letter line';
                    ToolTip = 'Specifies if the cash document line represents a prepayment (Prepayment) or an advance (Advance).';
                }
                field("TempAdvanceLinkBuf.""Document No."""; TempAdvanceLinkBuf."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No.';
                    Editable = false;
                    ToolTip = 'Specifies the number of advance letter.';
                }
                field("TempAdvanceLinkBuf.""Entry No."""; TempAdvanceLinkBuf."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Entry No.';
                    Editable = false;
                    ToolTip = 'Specifies the line number of advance letter.';
                }
                field("TempAdvanceLinkBuf.Description"; TempAdvanceLinkBuf.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    Editable = false;
                    ToolTip = 'Specifies the description of advance.';
                }
                field("TempAdvanceLinkBuf.""Currency Code"""; TempAdvanceLinkBuf."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Currency Code';
                    Editable = false;
                    ToolTip = 'Specifies the currency code of advance.';
                }
                field("TempAdvanceLinkBuf.""Remaining Amount"""; TempAdvanceLinkBuf."Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the amount of advance.';
                }
                field("TempAdvanceLinkBuf.""Amount To Link"""; TempAdvanceLinkBuf."Amount To Link")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount To Link';
                    Editable = false;
                    ToolTip = 'Specifies the amount of advance which was linked to payment.';
                }
                field("TempAdvanceLinkBuf.""Remaining Amount"" - TempAdvanceLinkBuf.""Amount To Link"""; TempAdvanceLinkBuf."Remaining Amount" - TempAdvanceLinkBuf."Amount To Link")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remaining Amt. To Link';
                    Editable = false;
                    ToolTip = 'Specifies the remaining amount of general ledger entries to link';
                }
            }
            repeater(Control1220014)
            {
                ShowCaption = false;
                field("Links-To ID"; "Links-To ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the link between advance and payment.';
                }
                field("Link Code"; "Link Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a link code';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the posting date for the entry.';
                }
                field("Entry Type"; "Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of the entry.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the document number for the set advance link.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the external document number from vendor.';
                    Visible = false;
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of posted credit card';
                    Visible = false;
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the no. of the set advance link';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies description of payment.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the currency of amounts on the document.';
                }
                field("Remaining Amount"; "Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the remaining amount of payment after link the advance.';
                }
                field("Amount To Link"; "Amount To Link")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount not yet paid by customer.';

                    trigger OnValidate()
                    begin
                        Difference := "Amount To Link" - xRec."Amount To Link";
                        AmountToLinkOnAfterValidate;
                    end;
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the due date on the entry.';
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the entry number that is assigned to the entry.';
                    Visible = false;
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
                action("Linked E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Linked E&ntries';
                    Image = Links;
                    ToolTip = 'Action for seting advance link';

                    trigger OnAction()
                    begin
                        ShowLinkedEntries;
                    end;
                }
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'Specifies advance dimensions.';

                    trigger OnAction()
                    begin
                        ShowDimensions();
                    end;
                }
            }
            group("&Link")
            {
                Caption = '&Link';
                action("Set Linking &Entry")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Linking &Entry';
                    Image = LinkWithExisting;
                    ShortCutKey = 'Shift+F11';
                    ToolTip = 'Specifies linked prepayments';
                    Visible = false;

                    trigger OnAction()
                    begin
                        PrepmtLinksMgt.SetLinkingEntry(Rec, true);
                        PrepmtLinksMgt.GetLinkingEntry(TempAdvanceLinkBuf);
                    end;
                }
                action("Set Link-to &ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Link-to &ID';
                    Image = LinkWeb;
                    ShortCutKey = 'F7';
                    ToolTip = 'Sets link to id';

                    trigger OnAction()
                    begin
                        PrepmtLinksMgt.SetLinkID(Rec, 0);
                        PrepmtLinksMgt.GetLinkingEntry(TempAdvanceLinkBuf);
                    end;
                }
                action("Set Link")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Link';
                    Image = Link;
                    ShortCutKey = 'F9';
                    ToolTip = 'Sets link';

                    trigger OnAction()
                    begin
                        if JnlLineMode then
                            OK := true
                        else
                            LinkEntries;
                        CurrPage.Close;
                    end;
                }
            }
        }
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                var
                    Navigate: Page Navigate;
                begin
                    Navigate.SetDoc("Posting Date", "Document No.");
                    Navigate.Run;
                end;
            }
        }
    }

    trigger OnClosePage()
    begin
        if OK then
            SaveLinkIDToLetterLines;
    end;

    trigger OnOpenPage()
    begin
        if IsEmpty then
            OnOpen;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            LookupOKOnPush;
    end;

    var
        TempAdvanceLinkBuf: Record "Advance Link Buffer" temporary;
        PrepmtLinksMgt: Codeunit "Prepayment Links Management";
        OK: Boolean;
        Difference: Decimal;
        JnlLineMode: Boolean;
        CustMode: Boolean;

    [Scope('OnPrem')]
    procedure SetLinkingCustPayment(CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        CustMode := true;
        PrepmtLinksMgt.SetLinkingCustPayment(CustLedgEntry);
    end;

    [Scope('OnPrem')]
    procedure SetLinkingVendPayment(VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        CustMode := false;
        PrepmtLinksMgt.SetLinkingVendPayment(VendLedgEntry);
    end;

    [Scope('OnPrem')]
    procedure SetLinkingSalesLetter(SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    begin
        CustMode := true;
        PrepmtLinksMgt.SetLinkingSalesLetter(SalesAdvanceLetterHeader);
    end;

    [Scope('OnPrem')]
    procedure SetLinkingPurchLetter(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    begin
        CustMode := false;
        PrepmtLinksMgt.SetLinkingPurchLetter(PurchAdvanceLetterHeader);
    end;

    [Scope('OnPrem')]
    procedure SetLinkingSalesLetterLine(SalesAdvanceLetterLine: Record "Sales Advance Letter Line")
    begin
        CustMode := true;
        PrepmtLinksMgt.SetLinkingSalesLetterLine(SalesAdvanceLetterLine);
    end;

    [Scope('OnPrem')]
    procedure SetLinkingPurchLetterLine(PurchAdvanceLetterLine: Record "Purch. Advance Letter Line")
    begin
        CustMode := false;
        PrepmtLinksMgt.SetLinkingPurchLetterLine(PurchAdvanceLetterLine);
    end;

    [Scope('OnPrem')]
    procedure SetGenJnlLine(GenJnlLine: Record "Gen. Journal Line")
    begin
        CustMode := GenJnlLine."Account Type" = GenJnlLine."Account Type"::Customer;
        PrepmtLinksMgt.SetGenJnlLine(GenJnlLine);
        JnlLineMode := true;
    end;

    [Scope('OnPrem')]
    procedure SaveLinkIDToLetterLines()
    begin
        PrepmtLinksMgt.SaveLinkIDToLetterLines(Rec, CustMode);
    end;

    [Scope('OnPrem')]
    procedure LinkEntries()
    begin
        PrepmtLinksMgt.LinkEntries(Rec, CustMode);
        PrepmtLinksMgt.GetLinkingEntry(TempAdvanceLinkBuf);
    end;

    [Scope('OnPrem')]
    procedure OnOpen()
    begin
        PrepmtLinksMgt.FillBuf(Rec, CustMode);
        PrepmtLinksMgt.GetLinkingEntry(TempAdvanceLinkBuf);
    end;

    [Scope('OnPrem')]
    procedure SetPostingGroupToGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        PostGroup: Code[20];
    begin
        PostGroup := PrepmtLinksMgt.GetLinkedPostingGroup(CustMode,
            GenJnlLine."Advance Letter Link Code");
        if PostGroup <> '' then
            GenJnlLine."Posting Group" := PostGroup;
    end;

    [Scope('OnPrem')]
    procedure GetOK(): Boolean
    begin
        exit(OK);
    end;

    local procedure AmountToLinkOnAfterValidate()
    begin
        PrepmtLinksMgt.SetLinkID(Rec, Difference);
        PrepmtLinksMgt.GetLinkingEntry(TempAdvanceLinkBuf);
    end;

    local procedure LookupOKOnPush()
    begin
        OK := true;
    end;
}

