page 1870 "Credit Limit Notification"
{
    Caption = 'Credit Limit Notification';
    DelayedInsert = false;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PromotedActionCategories = 'New,Process,Report,Manage,Create';
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            label(Control4)
            {
                ApplicationArea = Basic, Suite;
                CaptionClass = Heading;
                MultiLine = true;
                ShowCaption = false;
                ToolTip = 'Specifies the main message of the notification.';
            }
            part(CreditLimitDetails; "Credit Limit Details")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("No.");
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Manage")
            {
                Caption = '&Manage';
                action(Customer)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer';
                    Image = Customer;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    RunObject = Page "Customer Card";
                    RunPageLink = "No." = FIELD("No."),
                                  "Date Filter" = FIELD("Date Filter"),
                                  "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
                    RunPageMode = View;
                    ToolTip = 'View or edit detailed information about the customer.';
                }
            }
            group(Create)
            {
                Caption = 'Create';
                action(NewFinanceChargeMemo)
                {
                    AccessByPermission = TableData "Finance Charge Memo Header" = RIM;
                    ApplicationArea = Suite;
                    Caption = 'Finance Charge Memo';
                    Image = FinChargeMemo;
                    Promoted = true;
                    PromotedCategory = New;
                    PromotedOnly = true;
                    RunObject = Page "Finance Charge Memo";
                    RunPageLink = "Customer No." = FIELD("No.");
                    RunPageMode = Create;
                    ToolTip = 'Create a new finance charge memo.';
                }
            }
            group("Report")
            {
                Caption = 'Report';
                action("Report Customer - Balance to Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer - Balance to Date';
                    Image = "Report";
                    Promoted = true;
                    PromotedCategory = "Report";
                    PromotedOnly = true;
                    ToolTip = 'View a list with customers'' payment history up until a certain date. You can use the report to extract your total sales income at the close of an accounting period or fiscal year.';

                    trigger OnAction()
                    var
                        CustomerCard: Page "Customer Card";
                    begin
                        CustomerCard.RunReport(REPORT::"Customer - Balance to Date", "No.");
                    end;
                }
            }
        }
    }

    var
        Heading: Text[250];

    procedure SetHeading(Value: Text[250])
    begin
        Heading := Value;
    end;

    procedure InitializeFromNotificationVar(CreditLimitNotification: Notification)
    var
        Customer: Record Customer;
    begin
        Get(CreditLimitNotification.GetData(Customer.FieldName("No.")));
        SetRange("No.", "No.");

        if GetFilter("Date Filter") = '' then
            SetFilter("Date Filter", '..%1', WorkDate);

        CurrPage.CreditLimitDetails.PAGE.InitializeFromNotificationVar(CreditLimitNotification);
    end;
}

