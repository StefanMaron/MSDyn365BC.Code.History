namespace Microsoft.Sales.Customer;

page 9150 "My Customers"
{
    Caption = 'My Customers';
    PageType = ListPart;
    SourceTable = "My Customer";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer numbers that are displayed in the My Customer Cue on the Role Center.';
                    Width = 4;

                    trigger OnValidate()
                    begin
                        SyncFieldsWithCustomer();
                    end;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    DrillDown = false;
                    Lookup = false;
                    ToolTip = 'Specifies the name of the customer.';
                    Width = 20;
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Phone No.';
                    DrillDown = false;
                    ExtendedDatatype = PhoneNo;
                    Lookup = false;
                    ToolTip = 'Specifies the customer''s phone number.';
                    Width = 8;
                }
                field("Balance (LCY)"; Rec."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment amount that the customer owes for completed sales.';

                    trigger OnDrillDown()
                    begin
                        Customer.OpenCustomerLedgerEntries(false);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Open)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open';
                Image = ViewDetails;
                RunObject = Page "Customer Card";
                RunPageLink = "No." = field("Customer No.");
                RunPageMode = View;
                RunPageView = sorting("No.");
                Scope = Repeater;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SyncFieldsWithCustomer();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(Customer)
    end;

    trigger OnOpenPage()
    begin
        Rec.SetRange("User ID", UserId);
    end;

    protected var
        Customer: Record Customer;

    local procedure SyncFieldsWithCustomer()
    var
        MyCustomer: Record "My Customer";
    begin
        Clear(Customer);

        if Customer.Get(Rec."Customer No.") then
            if (Rec.Name <> Customer.Name) or (Rec."Phone No." <> Customer."Phone No.") then begin
                Rec.Name := Customer.Name;
                Rec."Phone No." := Customer."Phone No.";
                if MyCustomer.Get(Rec."User ID", Rec."Customer No.") then
                    Rec.Modify();
            end;
    end;
}

