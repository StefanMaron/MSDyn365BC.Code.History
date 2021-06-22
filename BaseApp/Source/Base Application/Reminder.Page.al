page 434 Reminder
{
    Caption = 'Reminder';
    PageType = Document;
    PromotedActionCategories = 'New,Process,Report,Reminder,Navigate';
    SourceTable = "Reminder Header";

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
                    Visible = DocNoVisible;

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
                    end;
                }
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the number of the customer you want to post a reminder for.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the name of the customer the reminder is for.';
                }
                field(Address; Address)
                {
                    ApplicationArea = Basic, Suite;
                    QuickEntry = false;
                    ToolTip = 'Specifies the address of the customer the reminder is for.';
                }
                field("Address 2"; "Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    QuickEntry = false;
                    ToolTip = 'Specifies additional address information.';
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    QuickEntry = false;
                    ToolTip = 'Specifies the postal code.';
                }
                field(City; City)
                {
                    ApplicationArea = Basic, Suite;
                    QuickEntry = false;
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
                    ToolTip = 'Specifies the date when the reminder should be issued.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Reminder Level"; "Reminder Level")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the reminder''s level.';
                }
                field("Use Header Level"; "Use Header Level")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the condition of the level for the Reminder Level field is applied to all suggested reminder lines.';
                }
                field("Assigned User ID"; "Assigned User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
            }
            part(ReminderLines; "Reminder Lines")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Reminder No." = FIELD("No.");
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Reminder Terms Code"; "Reminder Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies how reminders about late payments are handled for this customer.';
                }
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
                    ToolTip = 'Specifies when payment of the amount on the reminder is due.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the currency code of the reminder.';

                    trigger OnAssistEdit()
                    begin
                        TestField("Posting Date");
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
            part(Control9; "Customer Ledger Entry FactBox")
            {
                ApplicationArea = Basic, Suite;
                Provider = ReminderLines;
                SubPageLink = "Entry No." = FIELD("Entry No.");
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
                action(List)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'List';
                    Image = OpportunitiesList;
                    ToolTip = 'View all reminders that exist.';

                    trigger OnAction()
                    begin
                        ReminderHeader.Copy(Rec);
                        if PAGE.RunModal(0, ReminderHeader) = ACTION::LookupOK then
                            Rec := ReminderHeader;
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Reminder Comment Sheet";
                    RunPageLink = Type = CONST(Reminder),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("C&ustomer")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&ustomer';
                    Image = Customer;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Customer List";
                    RunPageLink = "No." = FIELD("Customer No.");
                    ToolTip = 'Open the card of the customer that the reminder or finance charge applies to. ';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Enabled = "No." <> '';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDocDim;
                        CurrPage.SaveRecord;
                    end;
                }
                separator(Action32)
                {
                }
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "Reminder Statistics";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CreateReminders)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Reminders';
                    Ellipsis = true;
                    Image = CreateReminders;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Create reminders for one or more customers with overdue payments.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Create Reminders");
                    end;
                }
                action(SuggestReminderLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest Reminder Lines';
                    Ellipsis = true;
                    Image = SuggestReminderLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Create reminder lines in existing reminders for any overdue payments based on information in the Reminder window.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(ReminderHeader);
                        REPORT.RunModal(REPORT::"Suggest Reminder Lines", true, false, ReminderHeader);
                    end;
                }
                action(UpdateReminderText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Update Reminder Text';
                    Ellipsis = true;
                    Image = RefreshText;
                    ToolTip = 'Replace the beginning and ending text that has been defined for the related reminder level with those from a different level.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(ReminderHeader);
                        REPORT.RunModal(REPORT::"Update Reminder Text", true, false, ReminderHeader);
                    end;
                }
            }
            group("&Issuing")
            {
                Caption = '&Issuing';
                Image = Add;
                action(TestReport)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';
                    Visible = NOT IsOfficeAddin;

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(ReminderHeader);
                        ReminderHeader.PrintRecords;
                    end;
                }
                action(Issue)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Issue';
                    Ellipsis = true;
                    Image = ReleaseDoc;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'F9';
                    ToolTip = 'Post the specified reminder entries according to your specifications in the Reminder Terms window. This specification determines whether interest and/or additional fees are posted to the customer''s account and the general ledger.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(ReminderHeader);
                        REPORT.RunModal(REPORT::"Issue Reminders", true, true, ReminderHeader);
                    end;
                }
            }
        }
        area(reporting)
        {
            group(Customer)
            {
                Caption = 'Customer';
                Image = "Report";
                action("Report Statement")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statement';
                    Image = "Report";
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Report "Customer Statement";
                    ToolTip = 'View a list of a customer''s transactions for a selected period, for example, to send to the customer at the close of an accounting period. You can choose to have all overdue balances displayed regardless of the period specified, or you can choose to include an aging band.';
                }
                action("Customer Detailed Aging")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer Detailed Aging';
                    Image = "Report";
                    Promoted = false;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = "Report";
                    RunObject = Report "Customer Detailed Aging";
                    ToolTip = 'View a detailed list of each customer''s total payments due, divided into three time periods. The report can be used to decide when to issue reminders, to evaluate a customer''s creditworthiness, or to prepare liquidity analyses.';
                }
                action("Customer - Order Summary")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer - Order Summary';
                    Image = "Report";
                    Promoted = false;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = "Report";
                    RunObject = Report "Customer - Order Summary";
                    ToolTip = 'View the order detail (the quantity not yet shipped) for each customer in three periods of 30 days each, starting from a selected date. There are also columns with orders to be shipped before and after the three periods and a column with the total order detail for each customer. The report can be used to analyze a company''s expected sales volume.';
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
                action("Aged Accounts Receivable")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Aged Accounts Receivable';
                    Image = "Report";
                    Promoted = false;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = "Report";
                    RunObject = Report "Aged Accounts Receivable";
                    ToolTip = 'View an overview of when customer payments are due or overdue, divided into four periods. You must specify the date you want aging calculated from and the length of the period that each column will contain data for.';
                }
                action("Customer - Balance to Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer - Balance to Date';
                    Image = "Report";
                    Promoted = false;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = "Report";
                    RunObject = Report "Customer - Balance to Date";
                    ToolTip = 'View a list with customers'' payment history up until a certain date. You can use the report to extract your total sales income at the close of an accounting period or fiscal year.';
                }
                action("Customer - Trial Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer - Trial Balance';
                    Image = "Report";
                    Promoted = true;
                    PromotedCategory = "Report";
                    RunObject = Report "Customer - Trial Balance";
                    ToolTip = 'View the beginning and ending balance for customers with entries within a specified period. The report can be used to verify that the balance for a customer posting group is equal to the balance on the corresponding general ledger account on a certain date.';
                }
                action("Customer - Payment Receipt")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer - Payment Receipt';
                    Image = "Report";
                    Promoted = false;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = "Report";
                    RunObject = Report "Customer - Payment Receipt";
                    ToolTip = 'View a document showing which customer ledger entries that a payment has been applied to. This report can be used as a payment receipt that you send to the customer.';
                }
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.SaveRecord;
        exit(ConfirmDeletion);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if (not DocNoVisible) and ("No." = '') then begin
            SetCustomerFromFilter;
            if "Customer No." <> '' then
                SetReminderNo();
        end;
    end;

    trigger OnOpenPage()
    var
        OfficeMgt: Codeunit "Office Management";
    begin
        SetDocNoVisible;
        IsOfficeAddin := OfficeMgt.IsAvailable;
    end;

    var
        ReminderHeader: Record "Reminder Header";
        CurrExchRate: Record "Currency Exchange Rate";
        ChangeExchangeRate: Page "Change Exchange Rate";
        DocNoVisible: Boolean;
        IsOfficeAddin: Boolean;

    local procedure SetDocNoVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order",Reminder,FinChMemo;
    begin
        DocNoVisible := DocumentNoVisibility.SalesDocumentNoIsVisible(DocType::Reminder, "No.");
    end;
}

