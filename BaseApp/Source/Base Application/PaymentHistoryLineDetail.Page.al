page 11000009 "Payment History Line Detail"
{
    Caption = 'Payment History Line Detail';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    PageType = Document;
    SourceTable = "Payment History Line";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the payment history line.';
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the account you want to perform payments to, or collections from.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the account you want to perform payments to, or collections from.';
                }
                field(Bank; Bank)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number for the bank you want to perform payments to, or collections from.';
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account number you want to perform payments to, or collections from.';
                }
                field("Transaction Mode"; "Transaction Mode")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction mode used in telebanking.';
                }
                field("Order"; Order)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the order type of the payment history line.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies total amount (including VAT) for the entry.';
                }
                field(Date; Date)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when you want the payment or collection to be performed.';
                }
            }
            part(Control47; "Detail Line Subform")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                SubPageLink = "Connect Batches" = FIELD("Run No."),
                              "Connect Lines" = FIELD("Line No."),
                              "Our Bank" = FIELD("Our Bank"),
                              Status = FILTER("In process" | Posted | Correction);
                SubPageView = SORTING("Our Bank", Status, "Connect Batches", "Connect Lines", Date);
            }
            group(Remark)
            {
                Caption = 'Remark';
                field(Identification; Identification)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the identification number for the payment history line.';
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
                }
                field("Description 3"; "Description 3")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional description of the payment history line.';
                }
                field("Description 4"; "Description 4")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional description of the payment history line.';
                }
            }
            group("Account Holder")
            {
                Caption = 'Account Holder';
                field("Account Holder Name"; "Account Holder Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account owner''s name.';
                }
                field("Account Holder Address"; "Account Holder Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account owner''s address.';
                }
                field("Account Holder Post Code"; "Account Holder Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account owner''s postal code.';
                }
                field("Account Holder City"; "Account Holder City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account owner''s city.';
                }
                field("Acc. Hold. Country/Region Code"; "Acc. Hold. Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code of the bank account holder.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        SetRange("Line No.");
    end;
}

