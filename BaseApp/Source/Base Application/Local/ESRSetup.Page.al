page 3010531 "ESR Setup"
{
    Caption = 'ESR Setup';
    PageType = Card;
    SourceTable = "ESR Setup";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Bank Code"; "Bank Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ESR bank is identified by the bank code.';
                }
                field("ESR Payment Method Code"; "ESR Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that vendors are linked with the ESR bank using the payment method code.';
                }
                field("ESR System"; "ESR System")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the invoice amount will be printed and no deduction can be made with the payment.';
                }
                field("ESR Currency Code"; "ESR Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that ESR can be used for CHF and EUR.';
                }
                field("Bal. Account Type"; "Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies for which account type the credit advice of the bank takes place.';
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the post or bank account that is used as the balance account.';
                }
                field("ESR Main Bank"; "ESR Main Bank")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a bank as main bank.';
                }
            }
            group(Member)
            {
                Caption = 'Member';
                field("ESR Account No."; "ESR Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ESR account number in a code field.';
                }
                field("ESR Member Name 1"; "ESR Member Name 1")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the member name is set as it should be printed on the deposit slip. This can also be the address of the bank.';
                }
                field("ESR Member Name 2"; "ESR Member Name 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the member name is set as it should be printed on the deposit slip. This can also be the address of the bank.';
                }
                field("ESR Member Name 3"; "ESR Member Name 3")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the member name is set as it should be printed on the deposit slip. This can also be the address of the bank.';
                }
                field("Beneficiary Text"; "Beneficiary Text")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the text "Pay to the order of:" or similar should be printed on the ESR form in the area for the payment receiver.';
                }
                field(Beneficiary; Beneficiary)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a maximum of five fields are available for the address of the beneficiary.';
                }
                field("Beneficiary 2"; "Beneficiary 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a maximum of five fields are available for the address of the beneficiary.';
                }
                field("Beneficiary 3"; "Beneficiary 3")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a maximum of five fields are available for the address of the beneficiary.';
                }
                field("Beneficiary 4"; "Beneficiary 4")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a maximum of five fields are available for the address of the beneficiary.';
                }
                field("BESR Customer ID"; "BESR Customer ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an 11-digit number if the ESR statement was made by the bank.';
                }
            }
            group("ESR File")
            {
                Caption = 'ESR File';
                field("ESR Filename"; "ESR Filename")
                {
                    ApplicationArea = Advanced;
                    ToolTip = 'Specifies the folder and name of the ESR file, such as C:\cronus.v11.';
                }
                field("Backup Copy"; "Backup Copy")
                {
                    ApplicationArea = Advanced;
                    ToolTip = 'Specifies that if the option Backup Copy is activated, a copy of the original file is made after reading in the ESR file.';
                }
                field("Backup Folder"; "Backup Folder")
                {
                    ApplicationArea = Advanced;
                    ToolTip = 'Specifies that if the option Backup Copy is activated, a copy of the original file is made after reading in the ESR file.';
                }
                field("Last Backup No."; "Last Backup No.")
                {
                    ApplicationArea = Advanced;
                    ToolTip = 'Specifies the incrementing number for the backup copy.';
                }
            }
        }
    }

    actions
    {
    }
}

