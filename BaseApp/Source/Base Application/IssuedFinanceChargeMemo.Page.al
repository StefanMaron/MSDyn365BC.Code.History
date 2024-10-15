page 450 "Issued Finance Charge Memo"
{
    Caption = 'Issued Finance Charge Memo';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Document;
    PromotedActionCategories = 'New,Process,Report,Print/Send,Memo,Navigate';
    SourceTable = "Issued Fin. Charge Memo Header";

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
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the customer number the finance charge memo is for.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the name of the customer the finance charge memo is for.';
                }
                field(Address; Address)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of the customer the finance charge memo is for.';
                }
                field("Address 2"; "Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies additional address information.';
                }
                field(City; City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city name of the customer the finance charge memo is for.';
                }
                field(County; County)
                {
                    Caption = 'State / ZIP Code';
                    ToolTip = 'Specifies the state or postal code related to the finance charge memo.';
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code.';
                }
                field(Contact; Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the person you regularly contact when you communicate with the customer the finance charge memo is for.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the posting date that the finance charge memo was issued on.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Pre-Assigned No."; "Pre-Assigned No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the finance charge memo.';
                }
                field("No. Printed"; "No. Printed")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many times the document has been printed.';
                }
                field(Canceled; Canceled)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the issued finance charge memo has been canceled.';
                }
            }
            part(FinChrgMemoLines; "Issued Fin. Charge Memo Lines")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Finance Charge Memo No." = FIELD("No.");
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Fin. Charge Terms Code"; "Fin. Charge Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code for the involved finance charges in case of late payment.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date when payment of the finance charge memo is due.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code of the currency that the issued finance charge memo is in.';

                    trigger OnAssistEdit()
                    begin
                        ChangeExchangeRate.SetParameter(
                          "Currency Code",
                          CurrExchRate.ExchangeRate("Posting Date", "Currency Code"),
                          "Posting Date");
                        ChangeExchangeRate.Editable(false);
                        if ChangeExchangeRate.RunModal = ACTION::OK then;
                        Clear(ChangeExchangeRate);
                    end;
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Memo")
            {
                Caption = '&Memo';
                Image = Notes;
                action(List)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'List';
                    Image = OpportunitiesList;
                    ToolTip = 'View all issued finance charges that exist.';

                    trigger OnAction()
                    begin
                        IssuedFinChrgMemoHeader.Copy(Rec);
                        if PAGE.RunModal(0, IssuedFinChrgMemoHeader) = ACTION::LookupOK then
                            Rec := IssuedFinChrgMemoHeader;
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Fin. Charge Comment Sheet";
                    RunPageLink = Type = CONST("Issued Finance Charge Memo"),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("C&ustomer")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&ustomer';
                    Image = Customer;
                    Promoted = true;
                    PromotedCategory = Category6;
                    RunObject = Page "Customer List";
                    RunPageLink = "No." = FIELD("Customer No.");
                    ToolTip = 'Open the card of the customer that the reminder or finance charge applies to. ';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                    end;
                }
                separator(Action6)
                {
                }
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    RunObject = Page "Issued Fin. Charge Memo Stat.";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
            }
        }
        area(processing)
        {
            action("&Print")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Category4;
                ToolTip = 'Prepare to print the document. The report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    CurrPage.SetSelectionFilter(IssuedFinChrgMemoHeader);
                    IssuedFinChrgMemoHeader.PrintRecords(true, false, false);
                end;
            }
            action("Send by &Email")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Send by &Email';
                Image = Email;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Prepare to send the document by email. The Send Email window opens prefilled for the customer where you can add or change information before you send the email.';

                trigger OnAction()
                begin
                    IssuedFinChrgMemoHeader := Rec;
                    CurrPage.SetSelectionFilter(IssuedFinChrgMemoHeader);
                    IssuedFinChrgMemoHeader.PrintRecords(false, true, false);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Navigate';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Category5;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate;
                end;
            }
            action(Cancel)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cancel';
                Ellipsis = true;
                Image = Cancel;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Cancel the issued finance charge memo.';

                trigger OnAction()
                var
                    IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
                begin
                    IssuedFinChargeMemoHeader := Rec;
                    IssuedFinChargeMemoHeader.SetRecFilter;
                    RunCancelIssuedFinChargeMemo(IssuedFinChargeMemoHeader);
                end;
            }
        }
        area(reporting)
        {
            action("Finance Charge Memo Nos.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Finance Charge Memo Nos.';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Finance Charge Memo Nos.";
                ToolTip = 'View or edit the finance charge memo numbers that are set up. ';
            }
            action("Finance Charge Memo")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Finance Charge Memo';
                Image = FinChargeMemo;
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Finance Charge Memo";
                ToolTip = 'Create a new finance charge memo.';
            }
            action("Customer Account Detail")
            {
                Caption = 'Customer Account Detail';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Customer Account Detail";
                ToolTip = 'View the detailed account activity for each customer for any period of time. The report lists all activity with running account balances, or only open items or only closed items with totals of either. The report can also show the application of payments to invoices.';
            }
            action("Open Customer Entries")
            {
                Caption = 'Open Customer Entries';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Open Customer Entries";
                ToolTip = 'View open customer entries. This report lists the open entries for each customer, and shows the age (days overdue) and remaining amount due in the transaction currency for each open entry.';
            }
        }
    }

    var
        IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header";
        CurrExchRate: Record "Currency Exchange Rate";
        ChangeExchangeRate: Page "Change Exchange Rate";
}

