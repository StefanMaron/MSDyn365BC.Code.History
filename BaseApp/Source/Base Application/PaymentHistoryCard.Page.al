page 11000005 "Payment History Card"
{
    Caption = 'Payment History Card';
    DeleteAllowed = true;
    InsertAllowed = false;
    PageType = Document;
    SourceTable = "Payment History";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Run No."; "Run No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the run number that was given to the entry, based on the number series that is defined in the Run No. Series field.';
                }
                field("Our Bank"; "Our Bank")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of your bank through which you want to perform payments or collections.';
                }
                field("Export Protocol"; "Export Protocol")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the export protocol used to export the payment history.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the payment history.';
                }
                field("No. of Transactions"; "No. of Transactions")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of lines that the payment history contains.';
                }
                field("Remaining Amount"; "Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that has not been reconciled. If the amount equals zero, all lines have been reconciled.';
                }
                field(Currency; CurrencyCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Currency Code';
                    Editable = false;
                    ToolTip = 'Specifies the content of the Currency Code field of the current payment history line.';
                }
            }
            part(Subform; "Payment History Line Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Run No." = FIELD("Run No."),
                              "Our Bank" = FIELD("Our Bank");
                SubPageView = SORTING("Our Bank", "Run No.", "Line No.");
            }
            group("Account Holder")
            {
                Caption = 'Account Holder';
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number used by the bank for your bank account from which the payment or collection will be performed.';
                }
                field("Account Holder Name"; "Account Holder Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies your bank account owner''s name.';
                }
                field("Account Holder Address"; "Account Holder Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies your bank account owner''s address.';
                }
                field("Account Holder Post Code"; "Account Holder Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account Holder Post Code/City';
                    ToolTip = 'Specifies your bank account owner''s postal code.';
                }
                field("Account Holder City"; "Account Holder City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies your bank account owner''s city.';
                }
                field("Acc. Hold. Country/Region Code"; "Acc. Hold. Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code of your bank account holder.';
                }
            }
            group(History)
            {
                Caption = 'History';
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who created the payment history.';
                }
                field("Creation Date"; "Creation Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the proposal lines were processed into the payment history.';
                }
                field("Day Serial Nr."; "Day Serial Nr.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the serial number assigned to the payment history.';
                }
                field("Number of Copies"; "Number of Copies")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many times the payment history has been exported.';
                }
                field("File on Disk"; "File on Disk")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the file name (including drive and path) of the exported payment history.';
                }
                field("Sent By"; "Sent By")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who last exported the payment history.';
                }
                field("Sent On"; "Sent On")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the payment history was last exported.';
                }
                field("Checksum"; rec.Checksum)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the checksum of the payment history that was exported.';
                }
            }
        }
        area(factboxes)
        {
            part("Payment File Errors"; "Payment Journal Errors Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment File Errors';
                Provider = Subform;
                SubPageLink = "Journal Template Name" = FILTER(''),
                              "Journal Batch Name" = FIELD("Our Bank"),
                              "Document No." = FIELD("Run No."),
                              "Journal Line No." = FIELD("Line No.");
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Pa&yment Hist.")
            {
                Caption = 'Pa&yment Hist.';
                Image = PaymentHistory;
                action(Export)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export';
                    Ellipsis = true;
                    Image = Export;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'F9';
                    ToolTip = 'Export the payment history to a file.';

                    trigger OnAction()
                    begin
                        ExportToPaymentFile;
                        CurrPage.Update();
                    end;
                }
                action(PrintDocket)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Print &Docket';
                    Image = Print;
                    Promoted = true;
                    PromotedCategory = "Report";
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Generate a docket report to inform your vendor or customer about the individual payments that constitute the total amount paid or collected in cases where multiple ledger entries were combined in one payment or collection.';

                    trigger OnAction()
                    var
                        PaymHist: Record "Payment History";
                    begin
                        SentProtocol.Get("Export Protocol");
                        SentProtocol.TestField("Docket ID");

                        PaymHist := Rec;
                        PaymHist.SetRange("Export Protocol", "Export Protocol");
                        PaymHist.SetRange("Our Bank", "Our Bank");
                        PaymHist.SetRange("Run No.", "Run No.");
                        REPORT.RunModal(SentProtocol."Docket ID", true, true, PaymHist);
                        CurrPage.Update();
                    end;
                }
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions();
                        CurrPage.SaveRecord;
                    end;
                }
                action("Change Status")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Change Status';
                    Ellipsis = true;
                    Image = ChangeStatus;
                    ToolTip = 'Change the status of one or more payment history lines, for example because a transaction is not accepted by your bank or you would like to cancel the payment yourself. Changing the status will automatically generate the necessary ledger entries. Rejected or cancelled history lines cannot be changed.';

                    trigger OnAction()
                    var
                        PaymentHistLine: Record "Payment History Line";
                    begin
                        PaymentHistLine.SetRange("Our Bank", "Our Bank");
                        PaymentHistLine.SetRange("Run No.", "Run No.");
                        REPORT.RunModal(REPORT::"Paymt. History - Change Status", true, true, PaymentHistLine);
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        "Payment history line".SetRange("Our Bank", "Our Bank");
        "Payment history line".SetRange("Run No.", "Run No.");
        if "Payment history line".FindFirst() then
            CurrencyCode := "Payment history line"."Currency Code";
    end;

    var
        SentProtocol: Record "Export Protocol";
        "Payment history line": Record "Payment History Line";
        CurrencyCode: Code[10];
}

