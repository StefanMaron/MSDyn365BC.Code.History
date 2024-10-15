page 3010831 "LSV Setup"
{
    Caption = 'LSV Setup';
    PageType = Card;
    SourceTable = "LSV Setup";

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
                    ToolTip = 'Specifies the ID for the bank account.';
                }
                field("LSV Payment Method Code"; "LSV Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment method code for a customer.';
                }
                field("LSV Currency Code"; "LSV Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code for LSV+ payments.';
                }
                field("LSV Customer Bank Code"; "LSV Customer Bank Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account to be used for LSV.';
                }
                field("LSV Sender IBAN"; "LSV Sender IBAN")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies your IBAN bank account number.';
                }
                field("ESR Bank Code"; "ESR Bank Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the available ESR Bank Code related to this LSV setup card.';
                }
                field("Bal. Account Type"; "Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the balance account is a bank account or a G/L account.';
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the G/L account or bank account that is used as the balance account.';
                }
                field("Source Code"; "Source Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies where the entry was created.';
                }
            }
            group(Sender)
            {
                Caption = 'Sender';
                field("LSV Sender Name"; "LSV Sender Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of your company.';
                }
                field("LSV Sender Name 2"; "LSV Sender Name 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of your company.';
                }
                field("LSV Sender Address"; "LSV Sender Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of your company.';
                }
                field("LSV Sender Post Code"; "LSV Sender Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of your company.';
                }
                field("LSV Sender City"; "LSV Sender City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of your company.';
                }
                field("LSV Customer ID"; "LSV Customer ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the 5-digit ID that identifies your company uniquely in the LSV system.';
                }
                field("LSV Sender ID"; "LSV Sender ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the 5-digit ID that identifies your company uniquely in the LSV system.';
                }
                field("LSV Sender Clearing"; "LSV Sender Clearing")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the clearing number for your bank.';
                }
                field("LSV Credit on Account No."; "LSV Credit on Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number at your bank.';
                }
            }
            group("Bank Address")
            {
                Caption = 'Bank Address';
                field("LSV Bank Name"; "LSV Bank Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name as specified in the bank address.';
                }
                field("LSV Bank Name 2"; "LSV Bank Name 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name as specified in the bank address.';
                }
                field("LSV Bank Address"; "LSV Bank Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address as specified in the bank address.';
                }
                field("LSV Bank Post Code"; "LSV Bank Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank post code as specified in the bank address.';
                }
                field("LSV Bank City"; "LSV Bank City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city as specified in the bank address.';
                }
                field("LSV Bank E-Mail"; "LSV Bank E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address to establish a connection with the computer bureau.';
                }
                field("LSV Bank Home Page"; "LSV Bank Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address to establish a connection with the computer bureau.';
                }
                field("LSV Bank Transfer Hyperlink"; "LSV Bank Transfer Hyperlink")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transfer hyperlink to establish a connection to your bank.';
                }
            }
            group("Processing Center")
            {
                Caption = 'Processing Center';
                field("Computer Bureau Name"; "Computer Bureau Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the computer bureau that receives the file.';
                }
                field("Computer Bureau Name 2"; "Computer Bureau Name 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the computer bureau that receives the file.';
                }
                field("Computer Bureau Address"; "Computer Bureau Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the computer bureau that receives the file.';
                }
                field("Computer Bureau Post Code"; "Computer Bureau Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the computer bureau that receives the file.';
                }
                field("Computer Bureau City"; "Computer Bureau City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the computer bureau that receives the file.';
                }
                field("Computer Bureau E-Mail"; "Computer Bureau E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address to establish a connection with the computer bureau.';
                }
                field("Computer Bureau Home Page"; "Computer Bureau Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address to establish a connection with the computer bureau.';
                }
            }
            group("LSV File")
            {
                Caption = 'LSV File';
                field("LSV File Folder"; "LSV File Folder")
                {
                    ApplicationArea = Advanced;
                    ToolTip = 'Specifies values for the LSV file folder and LSV file name define where the LSV file should be stored.';
                }
                field("LSV Filename"; "LSV Filename")
                {
                    ApplicationArea = Advanced;
                    ToolTip = 'Specifies values for the LSV file folder and LSV file name define where the LSV file should be stored.';
                }
            }
            group(Permission)
            {
                Caption = 'Permission';
                field(Text; Text)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies the accompanying text that is printed at the top of the LSV Collection Authorization.';
                }
                field("Text 2"; "Text 2")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies the accompanying text that is printed at the top of the LSV Collection Authorization.';
                }
            }
            group(DebitDirect)
            {
                Caption = 'DebitDirect';
                field("DebitDirect Customerno."; "DebitDirect Customerno.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer number assigned to you by Postal Finance.';
                }
                field("Yellownet Home Page"; "Yellownet Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies your bank''s address.';
                }
                field("DebitDirect Import Filename"; "DebitDirect Import Filename")
                {
                    ToolTip = 'Specifies the file to import for DebitDirect.';
                }
                field("Backup Copy"; "Backup Copy")
                {
                    ApplicationArea = Advanced;
                    ToolTip = 'Specifies if you want to create a copy of the original ESR file.';
                }
                field("Backup Folder"; "Backup Folder")
                {
                    ApplicationArea = Advanced;
                    ToolTip = 'Specifies the location where the backup copy is saved.';
                }
                field("Last Backup No."; "Last Backup No.")
                {
                    ToolTip = 'Specifies the location where the backup copy is saved.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action("&Write DebiDirect Testfile")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Write DebiDirect Testfile';
                    Image = TestFile;
                    ToolTip = 'Test the LSV setup.';

                    trigger OnAction()
                    var
                        WriteDebitDirectFile: Report "LSV Write DebitDirect File";
                    begin
                        WriteDebitDirectFile.WriteTestFile(Rec);
                    end;
                }
            }
            group("&Print")
            {
                Caption = '&Print';
                action("Collection Authorisation")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Collection Authorisation';
                    Image = "Report";
                    RunObject = Report "LSV Collection Authorisation";
                    ToolTip = 'View the collection authorizations that are sent to your customers. Collection authorizations are an agreement with customers so that you can collect the invoice amounts in the future. Customers provide bank account information, sign the collection authorization, and return it.';
                }
                action("LSV Customerbank List")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'LSV Customerbank List';
                    Image = "Report";
                    RunObject = Report "LSV Customerbank List";
                    ToolTip = 'View the collection authorizations that are sent to your customers. Collection authorizations are an agreement with customers so that you can collect the invoice amounts in the future. Customers provide bank account information, sign the collection authorization, and return it.';
                }
            }
        }
    }

    var
        Mail: Codeunit Mail;
}

