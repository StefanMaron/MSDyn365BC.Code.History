namespace Microsoft.Sales.Reminder;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Reports;
using Microsoft.EServices.EDocument;

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
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer number the reminder is for.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the customer the reminder is for.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code of the issued reminder.';
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the total of the remaining amounts on the reminder lines.';
                }
                field("No. Printed"; Rec."No. Printed")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many times the document has been printed.';
                    Visible = false;
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code.';
                    Visible = false;
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city name of the customer the reminder is for.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field(Canceled; Rec.Canceled)
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
                    RunPageLink = Type = const("Issued Reminder"),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("C&ustomer")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&ustomer';
                    Image = Customer;
                    RunObject = Page "Customer List";
                    RunPageLink = "No." = field("Customer No.");
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
                    RunObject = Page "Issued Reminder Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                separator(Action1080000)
                {
                }
                action("Create Electronic Reminder")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Electronic Reminder';
                    Image = CreateDocument;
                    ToolTip = 'Create one or more XML documents that you can send to the customer. You can run the batch job for multiple reminders or you can run it for an individual reminder. The document number is used as the file name. The files are stored at the location that has been specified in the Sales & Receivables Setup window.';

                    trigger OnAction()
                    var
                        IssuedReminderHeader: Record "Issued Reminder Header";
                        ExportEHFReminder: Codeunit "Export EHF Reminder";
                    begin
                        IssuedReminderHeader := Rec;
                        CurrPage.SetSelectionFilter(IssuedReminderHeader);
                        ExportEHFReminder.ExportEFHReminder30(IssuedReminderHeader, IssuedReminderHeader.GetView());
                    end;
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
                ToolTip = 'Prepare to print the document. The report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    IssuedReminderHeader: Record "Issued Reminder Header";
                    IsHandled: Boolean;
                begin
                    IssuedReminderHeader := Rec;
                    OnBeforePrintRecords(Rec, IssuedReminderHeader, IsHandled);
                    if IsHandled then
                        exit;
                    CurrPage.SetSelectionFilter(IssuedReminderHeader);
                    IssuedReminderHeader.PrintRecords(true, false, false);
                end;
            }
            action("Send by &Email")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Send by &Email';
                Image = Email;
                ToolTip = 'Prepare to send the document by email. The Send Email window opens prefilled for the customer where you can add or change information before you send the email.';

                trigger OnAction()
                var
                    IssuedReminderHeader: Record "Issued Reminder Header";
                    IssuedReminderHeader2: Record "Issued Reminder Header";
                    PrevCustomerNo: Code[20];
                    IsHandled: Boolean;
                begin
                    IssuedReminderHeader := Rec;
                    OnBeforeSendRecords(Rec, IssuedReminderHeader, IsHandled);
                    if IsHandled then
                        exit;
                    CurrPage.SetSelectionFilter(IssuedReminderHeader);
                    CurrPage.SetSelectionFilter(IssuedReminderHeader2);

                    PrevCustomerNo := '';
                    IssuedReminderHeader.SetCurrentKey("Customer No.");
                    if IssuedReminderHeader.FindSet() then
                        repeat
                            if IssuedReminderHeader."Customer No." <> PrevCustomerNo then begin
                                IssuedReminderHeader2.SetRange("Customer No.", IssuedReminderHeader."Customer No.");
                                IssuedReminderHeader2.PrintRecords(false, true, false);
                            end;
                            PrevCustomerNo := IssuedReminderHeader."Customer No.";
                        until IssuedReminderHeader.Next() = 0;
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    Rec.Navigate();
                end;
            }
            action(Cancel)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cancel';
                Ellipsis = true;
                Image = Cancel;
                ToolTip = 'Cancel the issued reminder.';

                trigger OnAction()
                var
                    IssuedReminderHeader: Record "Issued Reminder Header";
                begin
                    CurrPage.SetSelectionFilter(IssuedReminderHeader);
                    Rec.RunCancelIssuedReminder(IssuedReminderHeader);
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
                RunObject = Report "Customer - Balance to Date";
                ToolTip = 'View a list with customers'' payment history up until a certain date. You can use the report to extract your total sales income at the close of an accounting period or fiscal year.';
            }
            action("Customer - Detail Trial Bal.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer - Detail Trial Bal.';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Customer - Detail Trial Bal.";
                ToolTip = 'View the balance for customers with balances on a specified date. The report can be used at the close of an accounting period, for example, or for an audit.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Print_Promoted"; "&Print")
                {
                }
                actionref("Send by &Email_Promoted"; "Send by &Email")
                {
                }
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                actionref(Cancel_Promoted; Cancel)
                {
                }
            }
            group(Category_Reminder)
            {
                Caption = 'Reminder';

                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref("C&ustomer_Promoted"; "C&ustomer")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("Customer - Balance to Date_Promoted"; "Customer - Balance to Date")
                {
                }
            }
        }
    }

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(IssuedReminderHeaderRec: Record "Issued Reminder Header"; var IssuedReminderHeaderToPrint: Record "Issued Reminder Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendRecords(IssuedReminderHeaderRec: Record "Issued Reminder Header"; var IssuedReminderHeaderToPrint: Record "Issued Reminder Header"; var IsHandled: Boolean)
    begin
    end;

}

