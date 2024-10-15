page 12180 "Issued Customer Bill Card"
{
    Caption = 'Issued Customer Bill Card';
    DeleteAllowed = true;
    Editable = false;
    PageType = Card;
    SourceTable = "Issued Customer Bill Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the issued bill number.';
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the bank account number of the bank that is managing the customer bills.';
                }
                field("Payment Method Code"; "Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the payment method code for the customer bills that is entered in the Customer Card.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date the bill header was issued.';
                }
                field("List Date"; "List Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the issued customer bill list is created.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the type of the bank receipt that is applied to the customer bill.';
                }
                field("Partner Type"; "Partner Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the issued customer bill is of type person or company.';
                }
            }
            part(BankReceiptsLines; "Subform Issued Cust.Bill Lines")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                SubPageLink = "Customer Bill No." = FIELD("No.");
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code from the transaction entry.';
                }
                field("Report Header"; "Report Header")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a descriptive title for the report header.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1901849007; "Issued Cust. Bill Information")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("No.");
                Visible = true;
            }
            part("File Export Errors"; "Payment Journal Errors Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'File Export Errors';
                Provider = BankReceiptsLines;
                SubPageLink = "Journal Template Name" = CONST(''),
                              "Journal Batch Name" = CONST('12177'),
                              "Journal Line No." = FIELD("Line No."),
                              "Document No." = FIELD("Customer Bill No.");
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
                Image = "Action";
                separator(Action1130008)
                {
                }
            }
            action(PrintIssuedCustBill)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Print the customer bill.';

                trigger OnAction()
                begin
                    SetRange("No.", "No.");
                    REPORT.RunModal(REPORT::"Issued Cust Bills Report", true, false, Rec);
                    SetRange("No.");
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Navigate';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'View the number and type of entries that have the same document number or posting date.';

                trigger OnAction()
                begin
                    Navigate;
                end;
            }
        }
        area(reporting)
        {
            action(ExportIssuedBillToFile)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export Issued Bill to File';
                Image = Export;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Export the document.';

                trigger OnAction()
                begin
                    ExportToFile;
                end;
            }
            action(ExportIssuedBillToFloppyFile)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export Issued Bill to Floppy File';
                Image = Export;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Export the document in the local format.';

                trigger OnAction()
                begin
                    ExportToFloppyFile();
                end;
            }
            action("Issued Cust Bills Report")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Issued Cust Bills Report';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Issued Cust Bills Report";
                ToolTip = 'View a report of issued customer bills.';
            }
            action("Closing Bank Receipts")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Closing Bank Receipts';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Closing Bank Receipts";
                ToolTip = 'View the related closing bank receipts.';
            }
        }
    }
}

