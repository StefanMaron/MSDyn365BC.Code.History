#if not CLEAN19
page 11721 "Issued Payment Order"
{
    Caption = 'Issued Payment Order (Obsolete)';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Issued Payment Order Header";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the payment order.';
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of bank account.';
                }
                field("Bank Account Name"; Rec."Bank Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of bank account.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number used by the bank for the bank account.';
                }
                field("Foreign Payment Order"; Rec."Foreign Payment Order")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the foreign or domestic payment order.';
                }
                field("No. exported"; Rec."No. exported")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies how many times was payment order exported.';
                }
                field(CancelLinesFilter; CancelLinesFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Canceled Lines Filter';
                    OptionCaption = ' ,Not Canceled,Canceled';
                    ToolTip = 'Specifies to filter out the canceled or not canceled or all lines.';

                    trigger OnValidate()
                    begin
                        CurrPage.Lines.PAGE.FilterCanceledLines(CancelLinesFilter);
                        CurrPage.Lines.PAGE.Update(false);
                        CancelLinesFilterOnAfterVal();
                    end;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date on which you created the document.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the currency of amounts on the document.';

                    trigger OnAssistEdit()
                    var
                        ChangeExchangeRate: Page "Change Exchange Rate";
                    begin
                        ChangeExchangeRate.SetParameter("Currency Code", "Currency Factor", "Document Date");
                        ChangeExchangeRate.Editable(false);
                        if ChangeExchangeRate.RunModal() = ACTION::OK then begin
                            Validate("Currency Factor", ChangeExchangeRate.GetParameter());
                            CurrPage.Update();
                        end;
                    end;
                }
                field("Payment Order Currency Code"; Rec."Payment Order Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the payment order currency code.';

                    trigger OnAssistEdit()
                    var
                        ChangeExchangeRate: Page "Change Exchange Rate";
                    begin
                        ChangeExchangeRate.SetParameter("Payment Order Currency Code", "Payment Order Currency Factor", "Document Date");
                        ChangeExchangeRate.Editable(false);
                        if ChangeExchangeRate.RunModal() = ACTION::OK then begin
                            Validate("Payment Order Currency Factor", ChangeExchangeRate.GetParameter());
                            CurrPage.Update();
                        end;
                    end;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of vendor''s document.';
                }
                field("No. of Lines"; Rec."No. of Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of lines in the payment order.';
                }
                field("Uncertainty Pay.Check DateTime"; Rec."Uncertainty Pay.Check DateTime")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the check of uncertainty.';
                }
            }
            part(Lines; "Issued Payment Order Subform")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                SubPageLink = "Payment Order No." = FIELD("No.");
            }
            group("Debet/Credit")
            {
                Caption = 'Debet/Credit';
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total amount for payment order lines. The program calculates this amount from the sum of line amount fields on payment order lines.';
                }
                field(Debit; Debit)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total amount that the line consists of, if it is a debit amount.';
                }
                field(Credit; Credit)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total credit amount for issued payment order lines. The program calculates this credit amount from the sum of line credit fields on issued payment order lines.';
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total amount that the line consists of. The amount is in the local currency.';
                }
                field("Debit (LCY)"; Rec."Debit (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total amount that the line consists of, if it is a debit amount. The amount is in the local currency.';
                }
                field("Credit (LCY)"; Rec."Credit (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total amount that the line consists of, if it is a credit amount. The amount is in the local currency.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220036; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220035; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Payment Order")
            {
                Caption = '&Payment Order';
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Issued Payment Order Stat.";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View the statistics on the selected payment order.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action("Payment Order Export")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Order Export';
                    Ellipsis = true;
                    Image = ExportToBank;
                    ToolTip = 'Open the report for expor payment order to the bank.';

                    trigger OnAction()
                    begin
                        ExportPmtOrd();
                    end;
                }
            }
            group("&Print")
            {
                Caption = '&Print';
                action("Payment Order")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Order';
                    Ellipsis = true;
                    Image = BankAccountStatement;
                    ToolTip = 'Open the report for payment order.';

                    trigger OnAction()
                    begin
                        PrintPaymentOrder();
                    end;
                }
                separator(Action1220026)
                {
                }
                action("Payment Order Domestic")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Order Domestic';
                    Ellipsis = true;
                    Image = PurchaseTaxStatement;
                    ToolTip = 'Open the report for domestic payment order.';

                    trigger OnAction()
                    begin
                        PrintDomesticPaymentOrder();
                    end;
                }
                action("Payment Order International")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Order International';
                    Ellipsis = true;
                    Image = SalesTaxStatement;
                    ToolTip = 'Open the report for foreign payment order.';

                    trigger OnAction()
                    begin
                        PrintForeignPaymentOrder();
                    end;
                }
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        FilterGroup(2);
        if not (GetFilter("Bank Account No.") <> '') then begin
            if "Bank Account No." <> '' then
                SetRange("Bank Account No.", "Bank Account No.");
        end;
        FilterGroup(0);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        FilterGroup(2);
        if GetFilter("Bank Account No.") <> '' then
            "Bank Account No." := GetRangeMax("Bank Account No.");
        FilterGroup(0);
    end;

    trigger OnOpenPage()
    begin
        CurrPage.Lines.PAGE.FilterCanceledLines(CancelLinesFilter);
    end;

    var
        CancelLinesFilter: Option " ","Not Canceled",Canceled;

    local procedure CancelLinesFilterOnAfterVal()
    begin
        CurrPage.Update();
    end;

    local procedure PrintPaymentOrder()
    var
        IssuedPmtOrdHdr: Record "Issued Payment Order Header";
    begin
        IssuedPmtOrdHdr := Rec;
        IssuedPmtOrdHdr.SetRecFilter();
        IssuedPmtOrdHdr.PrintRecords(true);
    end;

    local procedure PrintDomesticPaymentOrder()
    var
        IssuedPmtOrdHdr: Record "Issued Payment Order Header";
    begin
        IssuedPmtOrdHdr := Rec;
        IssuedPmtOrdHdr.SetRecFilter();
        IssuedPmtOrdHdr.PrintDomesticPmtOrd(true);
    end;

    local procedure PrintForeignPaymentOrder()
    var
        IssuedPmtOrdHdr: Record "Issued Payment Order Header";
    begin
        IssuedPmtOrdHdr := Rec;
        IssuedPmtOrdHdr.SetRecFilter();
        IssuedPmtOrdHdr.PrintForeignPmtOrd(true);
    end;
}
#endif
