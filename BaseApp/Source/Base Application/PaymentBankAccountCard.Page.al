#if not CLEAN17
page 1283 "Payment Bank Account Card"
{
    Caption = 'Payment Bank Account Card';
    SourceTable = "Bank Account";
    SourceTableView = WHERE("Account Type" = CONST("Bank Account"));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    NotBlank = true;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank where you have the bank account.';
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number used by the bank for the bank account.';
                }
                field(IBAN; IBAN)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account''s international bank account number.';
                }
                field("Bank Acc. Posting Group"; "Bank Acc. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies a code for the bank account posting group for the bank account.';
                }
                group("Payment Match Tolerance")
                {
                    Caption = 'Payment Match Tolerance';
                    field("Match Tolerance Type"; "Match Tolerance Type")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies by which tolerance the automatic payment application function will apply the Amount Incl. Tolerance Matched rule for this bank account.';
                    }
                    field("Match Tolerance Value"; "Match Tolerance Value")
                    {
                        ApplicationArea = Basic, Suite;
                        DecimalPlaces = 0 : 2;
                        ToolTip = 'Specifies if the automatic payment application function will apply the Amount Incl. Tolerance Matched rule by Percentage or Amount.';
                    }
                }
                field("Bank Statement Import Format"; "Bank Statement Import Format")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the format of the bank statement file that can be imported into this bank account.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the relevant currency code for the bank account.';
                }
                field("Last Payment Statement No."; "Last Payment Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the last bank statement that was imported, either as a feed or a file.';
                }
            }
            group(Address)
            {
                Caption = 'Address';
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone number of the bank where you have the bank account.';
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address associated with the bank account.';
                }
                field(Contact; Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank employee regularly contacted in connection with this bank account.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Information)
            {
                Caption = 'Information';
                Image = Customer;
                action("Detailed Information")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Detailed Information';
                    Image = ViewDetails;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    RunObject = Page "Bank Account Card";
                    RunPageLink = "No." = FIELD("No.");
                    ToolTip = 'View or edit additional information about the bank account, such as the account. You can also check the balance on the account.';
                }
            }
        }
    }
}
#endif