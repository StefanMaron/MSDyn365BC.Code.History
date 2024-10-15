page 3010541 "DTA Setup"
{
    Caption = 'DTA Setup';
    PageType = Card;
    SourceTable = "DTA Setup";

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
                    ToolTip = 'Specifies a short name for the partner bank.';
                }
                field("DTA/EZAG"; "DTA/EZAG")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if this setup is for DTA or EZAG.';
                }
                field("DTA Currency Code"; "DTA Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the foreign currency used for the account.';
                }
                field("DTA Main Bank"; "DTA Main Bank")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the current bank code as the main bank.';
                }
                field("Bal. Account Type"; "Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account that is suggested as balance account in the payment suggestion.';
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the balance account number is used during the DTA Suggest Vendor Payments batch job, to make the balancing entry.';
                }
                field("Credit Limit"; "Credit Limit")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit limit for the bank account can be entered here.';
                }
            }
            group(Sender)
            {
                Caption = 'Sender';
                field("DTA Sender Name"; "DTA Sender Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the DTA sender name.';
                }
                field("DTA Sender Name 2"; "DTA Sender Name 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the second line of the DTA sender name.';
                }
                field("DTA Sender Address"; "DTA Sender Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies address of the DTA sender.';
                }
                field("DTA Sender Post Code"; "DTA Sender Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'DTA Sender ZIP/City';
                    ToolTip = 'Specifies the DTA sender post code.';
                }
                field("DTA Sender City"; "DTA Sender City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the DTA sender city is stored here.';
                }
                field("DTA Customer ID"; "DTA Customer ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the identification that is assigned by the bank and is normally identical to the DTA Sender ID.';
                }
                field("DTA Sender ID"; "DTA Sender ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the identification that is assigned by the bank and is normally identical to the DTA Customer ID.';
                }
                field("DTA Sender Clearing"; "DTA Sender Clearing")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies your bank.';
                }
                field("DTA Debit Acc. No."; "DTA Debit Acc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account that the payment orders are debited from.';
                }
                field("DTA Sender IBAN"; "DTA Sender IBAN")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the IBAN account that DTA payments is made from.';
                }
            }
            group("Bank Address")
            {
                Caption = 'Bank Address';
                field("DTA Bank Name"; "DTA Bank Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies part of the bank address.';
                }
                field("DTA Bank Name 2"; "DTA Bank Name 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies part of the bank address.';
                }
                field("DTA Bank Address"; "DTA Bank Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies part of the bank address.';
                }
                field("DTA Bank Address 2"; "DTA Bank Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies part of the bank address.';
                }
                field("DTA Bank Post Code"; "DTA Bank Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'DTA Bank Zip/City';
                    ToolTip = 'Specifies part of the bank address.';
                }
                field("DTA Bank City"; "DTA Bank City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies part of the bank address.';
                }
                field("DTA Bank E-Mail"; "DTA Bank E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address to establish a connection with the computer bureau.';
                }
                field("DTA Bank Home Page"; "DTA Bank Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address to establish a connection with the computer bureau.';
                }
            }
            group("Computer Bureau")
            {
                Caption = 'Computer Bureau';
                field("Computer Bureau Name"; "Computer Bureau Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the computer bureau that will receive the DTA file.';
                }
                field("Computer Bureau Name 2"; "Computer Bureau Name 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the computer bureau that will receive the DTA file.';
                }
                field("Computer Bureau Address"; "Computer Bureau Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the computer bureau that will receive the DTA file.';
                }
                field("Computer Bureau Post Code"; "Computer Bureau Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Computer Bureau Zip/City';
                    ToolTip = 'Specifies the computer bureau that will receive the DTA file.';
                }
                field("Computer Bureau City"; "Computer Bureau City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the computer bureau that will receive the DTA file.';
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
            group("DTA File")
            {
                Caption = 'DTA File';
                field("DTA File Folder"; "DTA File Folder")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the folder that the DTA file is saved in.';
                }
                field("DTA Filename"; "DTA Filename")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the file name with the standard value DTALSV.';
                }
                field("File Format"; "File Format")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the individual DTA file records are closed.';
                }
                field("Backup Copy"; "Backup Copy")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a backup copy is made each time a DTA file is written.';
                }
                field("Backup Folder"; "Backup Folder")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a backup copy is made each time a DTA file is written.';
                }
                field("Last Backup No."; "Last Backup No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a backup copy is made each time a DTA file is written.';
                }
            }
            group(EZAG)
            {
                Caption = 'EZAG';
                field("EZAG File Folder"; "EZAG File Folder")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the folder that the EZAG file is saved in.';
                }
                field("EZAG Filename"; "EZAG Filename")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the file name with the standard value PTTCRIA.';
                }
                field("EZAG Debit Account No."; "EZAG Debit Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that on this postal checking account, the payment order is debited from the Swiss Post.';
                }
                field("EZAG Charges Account No."; "EZAG Charges Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies all charges are debited to this account. It often corresponds to the EZAG Debit Account No.';
                }
                field("EZAG Media ID"; "EZAG Media ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the EZAG Media ID.';
                }
                field("Yellownet E-Mail"; "Yellownet E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address to establish a connection with the computer bureau.';
                }
                field("Yellownet Home Page"; "Yellownet Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address to establish a connection with the computer bureau.';
                }
                field("Last EZAG Order No."; "Last EZAG Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies each combined order has a unique number between 01 and 99.';
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
                action("&Write Testfile")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Write Testfile';
                    Image = TestFile;
                    ToolTip = 'Test the DTA setup.';

                    trigger OnAction()
                    var
                        DtaFileWrite: Report "DTA File";
                        EzagFileWrite: Report "EZAG File";
                    begin
                        if "DTA/EZAG" = "DTA/EZAG"::DTA then begin
                            if DtaFileWrite.WriteTestFile(Rec) then
                                DtaFileWrite.DownloadToFile();
                        end else
                            EzagFileWrite.WriteTestFile(Rec);
                    end;
                }
                action("E&ZAG Pictures")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'E&ZAG Pictures';
                    Image = Picture;
                    ToolTip = 'View the EZAG post logo and the EZAG bar code to be used in the EZAG Payment Order report.';

                    trigger OnAction()
                    var
                        DTASetup: Record "DTA Setup";
                    begin
                        DTASetup.Copy(Rec);
                        PAGE.Run(PAGE::"DTA EZAG Pictures", DTASetup);
                    end;
                }
            }
        }
    }

    var
        Mail: Codeunit Mail;
}

