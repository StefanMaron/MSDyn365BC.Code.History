page 438 "Issued Reminder"
{
    Caption = 'Issued Reminder';
    DeleteAllowed = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Document;
    PromotedActionCategories = 'New,Process,Report,Print/Send,Reminder,Navigate';
    SourceTable = "Issued Reminder Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                Editable = false;
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
                field(Address; Address)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of the customer the reminder is for.';
                }
                field("Address 2"; "Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies additional address information.';
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code.';
                }
                field(City; City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city name of the customer the reminder is for.';
                }
                field(Contact; Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the person you regularly contact when you communicate with the customer the reminder is for.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date that the reminder was issued on.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Pre-Assigned No."; "Pre-Assigned No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the reminder from which the issued reminder was created.';
                }
                field("Reminder Level"; "Reminder Level")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reminder''s level.';
                }
                field("No. Printed"; "No. Printed")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many times the document has been printed.';
                }
                field(Canceled; Canceled)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the issued reminder has been canceled.';
                }
            }
            part(ReminderLines; "Issued Reminder Lines")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                SubPageLink = "Reminder No." = FIELD("No.");
            }
            group(Posting)
            {
                Caption = 'Posting';
                Editable = false;
                field("Reminder Terms Code"; "Reminder Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reminder terms code for the reminder.';
                }
                field("Fin. Charge Terms Code"; "Fin. Charge Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the involved finance charges in case of late payment.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when payment of the amount on the reminder is due.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code of the issued reminder.';

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
            part(Control3; "Customer Ledger Entry FactBox")
            {
                ApplicationArea = Basic, Suite;
                Provider = ReminderLines;
                SubPageLink = "Entry No." = FIELD("Entry No.");
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
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
                action(List)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'List';
                    Image = OpportunitiesList;
                    ToolTip = 'View all issued reminders that exist.';

                    trigger OnAction()
                    begin
                        IssuedReminderHeader.Copy(Rec);
                        if PAGE.RunModal(0, IssuedReminderHeader) = ACTION::LookupOK then
                            Rec := IssuedReminderHeader;
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category5;
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
                PromotedCategory = Category4;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    IsHandled: Boolean;
                begin
                    IssuedReminderHeader := Rec;
                    IsHandled := false;
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
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Prepare to send the document by email. The Send Email window opens prefilled for the customer where you can add or change information before you send the email.';

                trigger OnAction()
                var
                    IsHandled: Boolean;
                begin
                    IssuedReminderHeader := Rec;
                    IsHandled := false;
                    OnBeforeSendRecords(Rec, IssuedReminderHeader, IsHandled);
                    if IsHandled then
                        exit;
                    CurrPage.SetSelectionFilter(IssuedReminderHeader);
                    IssuedReminderHeader.PrintRecords(false, true, false);
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
                ToolTip = 'Cancel the issued reminder.';

                trigger OnAction()
                begin
                    IssuedReminderHeader := Rec;
                    IssuedReminderHeader.SetRecFilter;
                    RunCancelIssuedReminder(IssuedReminderHeader);
                end;
            }
        }
    }

    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        CurrExchRate: Record "Currency Exchange Rate";
        ChangeExchangeRate: Page "Change Exchange Rate";

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(IssuedReminderHeaderRec: Record "Issued Reminder Header"; var IssuedReminderHeaderToPrint: Record "Issued Reminder Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendRecords(IssuedReminderHeaderRec: Record "Issued Reminder Header"; var IssuedReminderHeaderToSend: Record "Issued Reminder Header"; var IsHandled: Boolean)
    begin
    end;
}

