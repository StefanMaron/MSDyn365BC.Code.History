#if not CLEAN19
page 31007 "Links to Advance Letter"
{
    Caption = 'Links to Advance Letter (Obsolete)';
    Editable = false;
    PageType = List;
    SourceTable = "Advance Link";
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            repeater(Control1220008)
            {
                ShowCaption = false;
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the entry.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number for the link.';
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the line number.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency of amounts on the document.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount for the entry.';
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of connection advance and invoice.';
                    Visible = false;
                }
                field("Invoice No."; Rec."Invoice No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an invoice number, or select an existing invoice from the list for the advance link.';
                }
                field("Transfer Date"; Rec."Transfer Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies date of transfer';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
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
            group("&Line")
            {
                Caption = '&Line';
                action("Show Advance Letter")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Advance Letter';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Opens the advance letter';

                    trigger OnAction()
                    var
                        SalesAdvanceLetterHeader: Record "Sales Advance Letter Header";
                        PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header";
                        CustLedgEntry: Record "Cust. Ledger Entry";
                        VendLedgEntry: Record "Vendor Ledger Entry";
                        Type1: Option Sale,Purchase;
                    begin
                        if "Document No." = '' then
                            exit;
                        case true of
                            CustLedgEntry.Get("CV Ledger Entry No."):
                                Type1 := Type1::Sale;
                            VendLedgEntry.Get("CV Ledger Entry No."):
                                Type1 := Type1::Purchase;
                        end;

                        case Type1 of
                            Type1::Sale:
                                begin
                                    SalesAdvanceLetterHeader.Get("Document No.");
                                    if SalesAdvanceLetterHeader."Template Code" <> '' then
                                        SalesAdvanceLetterHeader.SetRange("Template Code", SalesAdvanceLetterHeader."Template Code");
                                    PAGE.RunModal(PAGE::"Sales Advance Letter", SalesAdvanceLetterHeader);
                                end;
                            Type1::Purchase:
                                begin
                                    PurchAdvanceLetterHeader.Get("Document No.");
                                    if PurchAdvanceLetterHeader."Template Code" <> '' then
                                        PurchAdvanceLetterHeader.SetRange("Template Code", PurchAdvanceLetterHeader."Template Code");
                                    PAGE.RunModal(PAGE::"Purchase Advance Letter", PurchAdvanceLetterHeader);
                                end;
                        end;
                    end;
                }
            }
        }
    }

    [Scope('OnPrem')]
    procedure GetSelection(var AdvanceLink: Record "Advance Link")
    begin
        CurrPage.SetSelectionFilter(AdvanceLink);
    end;
}
#endif
