page 426 "Vendor Bank Account List"
{
    Caption = 'Vendor Bank Account List';
    CardPageID = "Vendor Bank Account Card";
    DataCaptionFields = "Vendor No.";
    Editable = false;
    PageType = List;
    SourceTable = "Vendor Bank Account";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the vendor.';
                }
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code to identify this vendor bank account.';
                }
                field("Vendor.Name"; Vendor.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor Name';
                    Editable = false;
                    ToolTip = 'Specifies the vendor''s name.';
                }
                field("Vendor.City"; Vendor.City)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor City';
                    ToolTip = 'Specifies the city of the vendor''s address.';
                }
                field("Payment Form"; "Payment Form")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how payments are made. The different payment forms are used for different types of payment.';
                }
                field("ESR Type"; "ESR Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the format of account numbers and reference numbers for this vendor. The account number can have 5 or 9 digits, the reference number can have 15, 16, or 27 digits.';
                }
                field("ESR Account No."; "ESR Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s ESR account number.';
                }
                field("Balance Account No."; "Balance Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that when processing an invoice, for this bank account, the balance account you enter here will be suggested.';
                }
                field("Invoice No. Startposition"; "Invoice No. Startposition")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the position of the invoice number within the reference number.';
                }
                field("Invoice No. Length"; "Invoice No. Length")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the length of the invoice number in the reference number.';
                }
                field("Clearing No."; "Clearing No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the clearing number for the supplier''s bank.';
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bank account.';
                }
                field("Giro Account No."; "Giro Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s giro account no.';
                }
                field("SWIFT Code"; "SWIFT Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the international bank identifier code (SWIFT) of the bank where you have the account.';
                }
                field(IBAN; IBAN)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account''s international bank account number.';
                }
                field("Bank Identifier Code"; "Bank Identifier Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies this is used if a payment is made to a foreign bank.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank where the vendor has this bank account.';
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code.';
                    Visible = false;
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the address.';
                    Visible = false;
                }
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone number of the bank where the vendor has the bank account.';
                }
                field("Fax No."; "Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the fax number associated with the address.';
                    Visible = false;
                }
                field(Contact; Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank employee regularly contacted in connection with this bank account.';
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
    }

    trigger OnAfterGetRecord()
    begin
        Vendor.Get("Vendor No.");
    end;

    trigger OnOpenPage()
    var
        MonitorSensitiveField: Codeunit "Monitor Sensitive Field";
    begin
        MonitorSensitiveField.ShowPromoteMonitorSensitiveFieldNotification();
    end;

    var
        Vendor: Record Vendor;
}

