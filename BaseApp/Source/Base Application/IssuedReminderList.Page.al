page 440 "Issued Reminder List"
{
    ApplicationArea = Suite;
    Caption = 'Issued Reminders';
    CardPageID = "Issued Reminder";
    DataCaptionFields = "Customer No.";
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Issued Reminder Header";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer number the reminder is for.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the customer the reminder is for.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code of the issued reminder.';
                }
                field("Remaining Amount"; "Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the total of the remaining amounts on the reminder lines.';
                }
                field("No. Printed"; "No. Printed")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many times the document has been printed.';
                    Visible = false;
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code.';
                    Visible = false;
                }
                field(City; City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city name of the customer the reminder is for.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field(Canceled; Canceled)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the issued reminder has been canceled.';
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
            group("&Reminder")
            {
                Caption = '&Reminder';
                Image = Reminder;
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Reminder Comment Sheet";
                    RunPageLink = Type = CONST("Issued Reminder"),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("C&ustomer")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&ustomer';
                    Image = Customer;
                    RunObject = Page "Customer List";
                    RunPageLink = "No." = FIELD("Customer No.");
                    ToolTip = 'Open the card of the customer that the reminder or finance charge applies to. ';
                }
                separator(Action27)
                {
                }
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Issued Reminder Statistics";
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
                PromotedCategory = Process;
                ToolTip = 'Prepare to print the document. The report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    IssuedReminderHeader: Record "Issued Reminder Header";
                begin
                    IssuedReminderHeader := Rec;
                    OnBeforePrintRecords(Rec, IssuedReminderHeader);
                    CurrPage.SetSelectionFilter(IssuedReminderHeader);
                    IssuedReminderHeader.PrintRecords(true, false, false);
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
                var
                    IssuedReminderHeader: Record "Issued Reminder Header";
                    IssuedReminderHeader2: Record "Issued Reminder Header";
                    PrevCustomerNo: Code[20];
                begin
                    IssuedReminderHeader := Rec;
                    CurrPage.SetSelectionFilter(IssuedReminderHeader);
                    CurrPage.SetSelectionFilter(IssuedReminderHeader2);
                    IssuedReminderHeader.SetCurrentKey("Customer No.");
                    if IssuedReminderHeader.FindSet then
                        repeat
                            if IssuedReminderHeader."Customer No." <> PrevCustomerNo then begin
                                IssuedReminderHeader2.SetRange("Customer No.", IssuedReminderHeader."Customer No.");
                                IssuedReminderHeader2.PrintRecords(false, true, false);
                            end;
                            PrevCustomerNo := IssuedReminderHeader."Customer No.";
                        until IssuedReminderHeader.Next = 0;
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Navigate';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
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
                ToolTip = 'Cancel the issued reminder.';

                trigger OnAction()
                var
                    IssuedReminderHeader: Record "Issued Reminder Header";
                begin
                    CurrPage.SetSelectionFilter(IssuedReminderHeader);
                    RunCancelIssuedReminder(IssuedReminderHeader);
                end;
            }
        }
        area(reporting)
        {
            action("Reminder Nos.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reminder Nos.';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Reminder Nos.";
                ToolTip = 'View or edit the reminder numbers that are set up. ';
            }
            action("Customer - Balance to Date")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer - Balance to Date';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Customer - Balance to Date";
                ToolTip = 'View a list with customers'' payment history up until a certain date. You can use the report to extract your total sales income at the close of an accounting period or fiscal year.';
            }
            action("Customer - Detail Trial Bal.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer - Detail Trial Bal.';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Customer - Detail Trial Bal.";
                ToolTip = 'View the balance for customers with balances on a specified date. The report can be used at the close of an accounting period, for example, or for an audit.';
            }
        }
    }

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(IssuedReminderHeaderRec: Record "Issued Reminder Header"; var IssuedReminderHeaderToPrint: Record "Issued Reminder Header")
    begin
    end;
}

