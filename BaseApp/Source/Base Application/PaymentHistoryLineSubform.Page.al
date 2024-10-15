page 11000008 "Payment History Line Subform"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Payment History Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Docket; Docket)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that a docket exists for this payment.';
                }
                field("Line No."; "Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the line''s number.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the payment history line.';

                    trigger OnValidate()
                    begin
                        StatusOnAfterValidate;
                    end;
                }
                field(Identification; Identification)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the identification number for the payment history line.';
                }
                field("Order"; Order)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the order type of the payment history line.';
                    Visible = false;
                }
                field("Payment/Receipt"; "Payment/Receipt")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies whether the payment history line concerns a payment or a receipt.';
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of the account you want to perform payments to, or collections from.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the account you want to perform payments to, or collections from.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies total amount (including VAT) for the entry.';
                }
                field(Date; Date)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date when you want the payment or collection to be performed.';
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Transaction Mode"; "Transaction Mode")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the transaction mode used in telebanking.';
                    Visible = false;
                }
                field(Bank; Bank)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number for the bank you want to perform payments to, or collections from.';
                    Visible = false;
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the bank account number you want to perform payments to, or collections from.';
                }
                field("Direct Debit Mandate ID"; "Direct Debit Mandate ID")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    LookupPageID = "SEPA Direct Debit Mandates";
                    ToolTip = 'Specifies the direct debit mandate of the customer who made this payment.';
                }
                field("Description 1"; "Description 1")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the payment history line.';
                }
                field("Description 2"; "Description 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional description of the payment history line.';
                    Visible = false;
                }
                field("Description 3"; "Description 3")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional description of the payment history line.';
                    Visible = false;
                }
                field("Description 4"; "Description 4")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional description of the payment history line.';
                    Visible = false;
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the currency code that the entry is linked to.';
                    Visible = false;
                }
                field("Account Holder Name"; "Account Holder Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the bank account owner''s name.';
                    Visible = false;
                }
                field("Account Holder Address"; "Account Holder Address")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the bank account owner''s address.';
                    Visible = false;
                }
                field("Account Holder Post Code"; "Account Holder Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the bank account owner''s postal code.';
                    Visible = false;
                }
                field("Account Holder City"; "Account Holder City")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the bank account owner''s city.';
                    Visible = false;
                }
                field("Acc. Hold. Country/Region Code"; "Acc. Hold. Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the country/region code of the bank account holder.';
                    Visible = false;
                }
                field("Nature of the Payment"; "Nature of the Payment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the nature of the payment for the proposal line.';
                    Visible = false;
                }
                field("Registration No. DNB"; "Registration No. DNB")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number issued by the Dutch Central Bank (DNB), to identify a number of types of foreign payments.';
                    Visible = false;
                }
                field("Description Payment"; "Description Payment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description related to the nature of the payment.';
                    Visible = false;
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number the Dutch Central Bank (DNB) issues to transito traders, to identify goods being sold and purchased by these traders.';
                    Visible = false;
                }
                field("Traders No."; "Traders No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number the Dutch Central Bank (DNB) issued to transito trader.';
                    Visible = false;
                }
                field(Urgent; Urgent)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the payment should be performed urgently.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(DetailInformation)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Detail Information';
                    Image = ViewDetails;
                    ShortCutKey = 'F7';
                    ToolTip = 'View invoice-level information for the line.';

                    trigger OnAction()
                    begin
                        Zoom;
                    end;
                }
                action(Dimension)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimension';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions();
                        CurrPage.SaveRecord;
                    end;
                }
                group("A&ccount")
                {
                    Caption = 'A&ccount';
                    Image = ChartOfAccounts;
                    action(Card)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = '&Card';
                        Image = EditLines;
                        ShortCutKey = 'Shift+F7';
                        ToolTip = 'View detailed information about the payment.';

                        trigger OnAction()
                        begin
                            ShowAccount;
                        end;
                    }
                    action(LedgerEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ledger E&ntries';
                        ShortCutKey = 'Ctrl+F7';
                        ToolTip = 'View the bank ledger entries.';

                        trigger OnAction()
                        begin
                            ShowEntries;
                        end;
                    }
                }
            }
        }
    }

    [Scope('OnPrem')]
    procedure Zoom()
    var
        SentLinesZoom: Page "Payment History Line Detail";
        PaymentHistLine: Record "Payment History Line";
    begin
        PaymentHistLine := Rec;
        PaymentHistLine.FilterGroup(10);
        PaymentHistLine.SetRange("Run No.", "Run No.");
        PaymentHistLine.FilterGroup(0);
        PaymentHistLine.SetRange("Line No.", "Line No.");
        SentLinesZoom.SetTableView(PaymentHistLine);
        SentLinesZoom.SetRecord(PaymentHistLine);
        SentLinesZoom.Run();
    end;

    [Scope('OnPrem')]
    procedure ShowAccount()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        case "Account Type" of
            "Account Type"::Customer:
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
            "Account Type"::Vendor:
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
            "Account Type"::Employee:
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::Employee;
        end;
        GenJnlLine."Account No." := "Account No.";
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Show Card", GenJnlLine);
    end;

    [Scope('OnPrem')]
    procedure ShowEntries()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        case "Account Type" of
            "Account Type"::Customer:
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
            "Account Type"::Vendor:
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
            "Account Type"::Employee:
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::Employee;
        end;
        GenJnlLine."Account No." := "Account No.";
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Show Entries", GenJnlLine);
    end;

    local procedure StatusOnAfterValidate()
    begin
        CurrPage.Update();
    end;
}

