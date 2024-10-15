#if not CLEAN19
page 11726 "Bank No. Series Setup"
{
    Caption = 'Bank No. Series Setup (Obsolete)';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPlus;
    SourceTable = "Bank Account";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            group(Numbering)
            {
                Caption = 'Numbering';
                InstructionalText = 'To fill the Document No. field automatically, you must set up a number series.';
                field("Payment Order Nos."; "Payment Order Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to payment orders.';
                    Visible = PaymentOrderNosVisible;
                }
                field("Bank Statement Nos."; "Bank Statement Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to bank statement.';
                    Visible = BankStatementNosVisible;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Setup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Account Card';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "Bank Account Card";
                RunPageLink = "No." = FIELD("No.");
                ToolTip = 'Specifies account card';
            }
        }
    }

    var
        PaymentOrderNosVisible: Boolean;
        BankStatementNosVisible: Boolean;

    [Scope('OnPrem')]
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    procedure SetFieldsVisibility(DocType: Option "Bank Statement","Payment Order")
    begin
        PaymentOrderNosVisible := (DocType = DocType::"Payment Order");
        BankStatementNosVisible := (DocType = DocType::"Bank Statement");
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    procedure SetBankAccountNo(BankAccNo: Code[20])
    begin
        FilterGroup(2);
        SetRange("No.", BankAccNo);
        FilterGroup(0);
    end;
}

#endif